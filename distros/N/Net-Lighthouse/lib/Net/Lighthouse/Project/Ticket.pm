package Net::Lighthouse::Project::Ticket;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;
extends 'Net::Lighthouse::Base';
# read only attr
has [qw/created_at updated_at milestone_due_on/] => (
    isa => 'Maybe[DateTime]',
    is  => 'ro',
);

has [qw/number priority user_id project_id creator_id attachments_count/] => (
    isa => 'Maybe[Int]',
    is  => 'ro',
);

has [qw/closed /] => (
    isa => 'Bool',
    is  => 'ro',
);

has [
    'raw_data',           'user_name',
    'permalink',          'url',
    'latest_body',        'creator_name',
    'assigned_user_name', 'milestone_title',
  ] => (
    isa => 'Maybe[Str]',
    is  => 'ro',
  );

has 'attachments' => (
    isa        => 'ArrayRef[Net::Lighthouse::Project::Ticket::Attachment]',
    is         => 'ro',
    auto_deref => 1,
);

has 'versions' => (
    isa        => 'ArrayRef[Net::Lighthouse::Project::Ticket::Version]',
    is         => 'ro',
    auto_deref => 1,
);

# read&write attr
has [qw/assigned_user_id milestone_id/] => (
    isa => 'Maybe[Int]',
    is  => 'rw',
);

has [qw/title state tag/] => (
    isa => 'Maybe[Str]',
    is  => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\d+$/ } );
    my $number = shift;
    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/tickets/'
      . $number . '.xml';
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
        if ( $k eq 'versions' ) {
            my $versions = $ref->{versions}{version};
            $versions = [ $versions ] unless ref $versions eq 'ARRAY';
            require Net::Lighthouse::Project::Ticket::Version;
            $ref->{versions} = [
                map {
                    my $v = Net::Lighthouse::Project::Ticket::Version->new;
                    $v->load_from_xml($_)
                  } @$versions
            ];
        }
        elsif ( $k eq 'attachments' ) {
            my @attachments;
            for ( keys %{$ref->{attachments}} ) {
                my $att = $ref->{attachments}{$_};
                next unless ref $att;
                if ( ref $att eq 'ARRAY' ) {
                    push @attachments, @{$att};
                }
                else {
                    push @attachments, $att;
                }
            }
            next unless @attachments;

            require Net::Lighthouse::Project::Ticket::Attachment;
            $ref->{attachments} = [
                map {
                    my $v =
                      Net::Lighthouse::Project::Ticket::Attachment->new(
                        ua => $self->ua );
                    $v->load_from_xml($_)
                  } @attachments
            ];
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
            state => { optional => 1, type => SCALAR },
            assigned_user_id => {
                optional => 1,
                type     => SCALAR | UNDEF,
                regex    => qr/^(\d+|)$/,
            },
            milestone_id => {
                optional => 1,
                type     => SCALAR | UNDEF,
                regex    => qr/^(\d+|)$/,
            },
            tag => { optional => 1, type => SCALAR },
        }
    );
    my %args = @_;

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'ticket', );

    my $ua = $self->ua;

    my $url = $self->base_url . '/projects/' . $self->project_id . '/tickets.xml';

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
            state => { optional => 1, type => SCALAR },
            assigned_user_id => {
                optional => 1,
                type     => SCALAR | UNDEF,
                regex    => qr/^(\d+|)$/,
            },
            milestone_id => {
                optional => 1,
                type     => SCALAR | UNDEF,
                regex    => qr/^(\d+|)$/,
            },
            tag => { optional => 1, type => SCALAR },
        }
    );
    my %args = (
        (
            map { $_ => $self->$_ }
              qw/title body state assigned_user_id milestone_id tag/
        ),
        @_
    );

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'ticket', );

    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/tickets/'
      . $self->number . '.xml';

    my $request = HTTP::Request->new( 'PUT', $url, undef, $xml );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        $self->load( $self->number ); # let's reload
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
      . $self->project_id . '/tickets/'
      . $self->number . '.xml';

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
    validate(
        @_,
        {
            query => { optional => 1, type => SCALAR },
            page  => { optional => 1, type => SCALAR, regex => qr/^\d+$/ },
        }
    );
    my %args = @_;

    my $url =
      $self->base_url . '/projects/' . $self->project_id . '/tickets.xml?';
    if ( $args{query} ) {
        require URI::Escape;
        $url .= 'q=' . URI::Escape::uri_escape( $args{query} ) . '&';
    }
    if ( $args{page} ) {
        $url .= 'page=' . uri_escape( $args{page} );
    }

    my $ua  = $self->ua;
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        my $ts = Net::Lighthouse::Util->read_xml( $res->content )->{tickets}{ticket};
        my @list = map {
            my $t = Net::Lighthouse::Project::Ticket->new(
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/account auth project_id/
            );
            $t->load_from_xml($_);
        } ref $ts eq 'ARRAY' ? @$ts : $ts;
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
      $self->base_url . '/projects/' . $self->project_id . '/tickets/new.xml';
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

Net::Lighthouse::Project::Ticket - Project Ticket

=head1 SYNOPSIS

    use Net::Lighthouse::Project::Ticket;
    my $ticket = Net::Lighthouse::Project::Ticket->new(
        account    => 'sunnavy',
        auth       => { token => '' },
        project_id => 12345
    );
    $ticket->load( 1 );
    print $ticket->state;
    $ticket->delete;

=head1 ATTRIBUTES

=over 4

=item created_at, updated_at, milestone_due_on

ro, Maybe DateTime

=item number, priority, user_id, project_id, creator_id, attachments_count,

ro, Maybe Int

=item closed

ro, Bool

=item raw_data, user_name, permalink, url, latest_body, creator_name, assigned_user_name, milestone_title

ro, Maybe Str

=item attachments

ro, ArrayRef of Net::Lighthouse::Project::Ticket::Attachment

=item versions

ro, ArrayRef of Net::Lighthouse::Project::Ticket::Version

=item assigned_user_id, milestone_id

rw, Maybe Int

=item title, state, tag,

rw, Maybe Str

=back

=head1 INTERFACE

=over 4

=item load( $id ), load_from_xml( $hashref | $xml_string )

load a ticket, return the loaded ticket object

=item create( title => '', body  => '', state => '', assigned_user_id => '', milestone_id => '', tag => '', )

create a ticket, return true if succeeded

=item update( title => '', body  => '', state => '', assigned_user_id => '', milestone_id => '', tag => '', )

update a ticket, return true if succeeded

=item delete

delete a ticket, return true if succeeded

=item list( query => '', page => '' )

return a list of tickets, each isa L<Net::Lighthouse::Project::Ticket>.

NOTE: the ticket in this list doesn't load versions and attachments attrs

=item initial_state

return hashref, carrying the initial_state info

=back

=head1 SEE ALSO

L<http://lighthouseapp.com/api/tickets>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

