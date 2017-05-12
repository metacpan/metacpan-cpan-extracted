package Net::Lighthouse::Project::Changeset;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;
extends 'Net::Lighthouse::Base';
# read only attr

has [qw/project_id user_id/] => (
    isa => 'Int',
    is  => 'ro',
);

has 'body_html' => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

# read&write attr
has 'changed_at' => (
    isa => 'DateTime',
    is  => 'rw',
);

has 'changes' => (
    isa        => 'ArrayRef',
    is         => 'rw',
    auto_deref => 1,
);

has [qw/body title revision/] => (
    isa => 'Maybe[Str]',
    is  => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\d+$/ } );
    my $revision = shift;
    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/changesets/'
      . $revision . '.xml';
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
    my $ref = Net::Lighthouse::Util->translate_from_xml( shift );

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

sub create {
    my $self = shift;
    validate(
        @_,
        {
            revision   => { type => SCALAR },
            body       => { type => SCALAR },
            title      => { type => SCALAR },
            changes    => { type => SCALAR },
            changed_at => { type => SCALAR },
        }
    );
    my %args = @_;

    my $xml =
      Net::Lighthouse::Util->translate_to_xml( \%args, root => 'changeset', );

    my $ua = $self->ua;

    my $url = $self->base_url . '/projects/' . $self->project_id . '/changesets.xml';

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

sub delete {
    my $self = shift;
    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id . '/changesets/'
      . $self->revision . '.xml';

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
      $self->base_url . '/projects/' . $self->project_id . '/changesets.xml';
    my $ua  = $self->ua;
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        my $cs =
          Net::Lighthouse::Util->read_xml( $res->content )->{changesets}{changeset};
        my @list = map {
            my $t = Net::Lighthouse::Project::Changeset->new(
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/account auth project_id/
            );
            $t->load_from_xml($_);
        } ref $cs eq 'ARRAY' ? @$cs : $cs;
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
      $self->base_url . '/projects/' . $self->project_id . '/changesets/new.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        return Net::Lighthouse::Util->translate_from_xml( $res->content );
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

Net::Lighthouse::Project::Changeset - Project Changeset

=head1 SYNOPSIS

    use Net::Lighthouse::Project::Changeset;
    my $changeset = Net::Lighthouse::Project:;Changeset->new(
        account    => 'sunnavy',
        auth       => { token => '' },
        project_id => 12345,
    );
    $changeset->load( 1 );
    print $changeset->title;
    $changeset->delete;

=head1 ATTRIBUTES

=over 4

=item project_id user_id

ro, Int

=item body_html

ro, Maybe Str

=item changed_at

rw, DateTime

=item changes

rw, ArrayRef

=item body, title, revision

rw, Maybe Str

=back

=head1 INTERFACE

=over 4

=item load( $revision ), load_from_xml( $hashref | $xml_string )

load a changeset, return the loaded changeset object

=item create( revision => '', body => '', title => '', changes => '', changed_at => '', )

create a changeset, return true if succeeded

=item delete

delete the changeset, return true if succeeded

=item list

return a list of changesets, each isa L<Net::Lighthouse::Project::Changeset>.

=item initial_state

return hashref, carrying the initial_state info

=back

=head1 SEE ALSO

L<http://lighthouseapp.com/api/changesets>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

