package Net::Lighthouse::Project::Message;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;
extends 'Net::Lighthouse::Base';
# read only attr
has [qw/created_at updated_at/] => (
    isa => 'Maybe[DateTime]',
    is  => 'ro',
);

has [
    qw/id user_id parent_id comments_count project_id
      all_attachments_count attachments_count/
  ] => (
    isa => 'Maybe[Int]',
    is  => 'ro',
  );

has [ 'body_html', 'user_name', 'permalink', 'url', ] => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

has 'comments' => (
    isa        => 'ArrayRef[Net::Lighthouse::Project::Message]',
    is         => 'ro',
    auto_deref => 1,
);

# read&write attr
has [qw/title body/] => (
    isa => 'Maybe[Str]',
    is  => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\d+$/ } );
    my $id = shift;
    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/messages/'
      . $id . '.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub load_from_xml {
    my $self = shift;
    my $ref = $self->_translate_from_xml( shift );

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

sub _translate_from_xml {
    my $self = shift;
    my $ref = Net::Lighthouse::Util->translate_from_xml( shift );
    for my $k ( keys %$ref ) {
        if ( $k eq 'comments' ) {
            # if has parent_id, then it's comment, comment can't have comments
            if ( $ref->{parent_id} ) {
                delete $ref->{comments};
                next;
            }

            if ( $ref->{comments} ) {
                my $comments = $ref->{comments}{comment};
                $ref->{comments} = [
                    map {
                        my $v = Net::Lighthouse::Project::Message->new;
                        $v->load_from_xml($_)
                      } @$comments
                ];
            }
            else {
                $ref->{comments} = [];
            }
        }
    }
    return $ref;
}

sub create {
    my $self = shift;
    validate(
        @_,
        {
            title => { type     => SCALAR },
            body  => { type     => SCALAR },
        }
    );
    my %args = @_;

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'message', );
    my $ua = $self->ua;

    my $url = $self->base_url . '/projects/' . $self->project_id . '/messages.xml';

    my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
        return 1;
    }
    else {
        die "try to POST $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub create_comment {
    my $self = shift;
    validate(
        @_,
        {
            body  => { type     => SCALAR },
        }
    );
    my %args = @_;

    # TODO doc says <message>, but it's wrong, should be <comment>
    # see also http://help.lighthouseapp.com/discussions/api-developers/121-create-message-comment-bug

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'comment', );

    my $ua = $self->ua;

    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id
      . '/messages/'
      . $self->id
      . '/comments.xml';

    my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
    my $res = $ua->request( $request );

    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
        return 1;
    }
    else {
        die "try to POST $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub update {
    my $self = shift;
    validate(
        @_,
        {
            title => { optional => 1, type     => SCALAR },
            body  => { optional => 1, type     => SCALAR },
        }
    );
    my %args = ( ( map { $_ => $self->$_ } qw/title body/ ), @_ );

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'message', );

    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/messages/'
      . $self->id . '.xml';

    my $request = HTTP::Request->new( 'PUT', $url, undef, $xml );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        $self->load( $self->id ); # let's reload
        return 1;
    }
    else {
        die "try to PUT $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub delete {
    my $self = shift;
    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/messages/'
      . $self->id . '.xml';

    my $request = HTTP::Request->new( 'DELETE', $url );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        return 1;
    }
    else {
        die "try to DELETE $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub list {
    my $self = shift;
    my $url =
      $self->base_url . '/projects/' . $self->project_id . '/messages.xml';

    my $ua  = $self->ua;
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        my $ms = Net::Lighthouse::Util->read_xml( $res->content )->{messages}{message};
        my @list = map {
            my $t = Net::Lighthouse::Project::Message->new(
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/account auth project_id/
            );
            $t->load_from_xml($_);
        } ref $ms eq 'ARRAY' ? @$ms : $ms;
        return wantarray ? @list : \@list;
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }

}

sub initial_state {
    my $self = shift;
    my $ua = $self->ua;
    my $url =
      $self->base_url . '/projects/' . $self->project_id . '/messages/new.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        return $self->_translate_from_xml( $res->content );
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

1;

__END__

=head1 NAME

Net::Lighthouse::Project::Message - Project Message

=head1 SYNOPSIS

    use Net::Lighthouse::Project::Message;
    my $message = Net::Lighthouse::Project::Message->new(
        account    => 'sunnavy',
        auth       => { token => '' },
        project_id => 12345,
    );
    $message->load( 1 );
    print $message->title;
    $message->delete;

=head1 ATTRIBUTES

=over 4

=item created_at, updated_at

ro, Maybe DateTime

=item id, user_id, parent_id, comments_count, project_id, all_attachments_count, attachments_count

ro, Maybe Int

=item body_html, user_name, permalink, url

ro, Maybe Str

=item comments

ro, ArrayRef of Net::Lighthouse::Project::Message

=item title body

rw, Maybe Str

=back

=head1 INTERFACE

=over 4

=item load( $id ), load_from_xml( $hashref | $xml_string )

load a message, return the loaded message object

=item create( title => '', body => '' );

create a message, return true if succeeded

=item create_comment( body => '' );

create a comment, return true if succeeded

=item update( title => '', body => '' );

update a message, return true if succeeded

=item delete

delete the message, return true if succeeded

=item list

return a list of messages, each isa L<Net::Lighthouse::Project::Message>.

=item initial_state

return hashref, carrying the initial_state info

=back

=head1 SEE ALSO

L<http://lighthouseapp.com/api/messages>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

