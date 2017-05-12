package Prophet::UUIDGenerator;
{
  $Prophet::UUIDGenerator::VERSION = '0.751';
}

# ABSTRACT: Creates v4 & v5 UUIDs.

use Any::Moose;
use MIME::Base64::URLSafe;
use UUID::Tiny ':std';


# uuid_scheme: 1 - v1 and v3 uuids.
#              2 - v4 and v5 uuids.
has uuid_scheme => (
    isa => 'Int',
    is  => 'rw'
);


sub create_str {
    my $self = shift;
    if ( $self->uuid_scheme == 1 ) {
        return create_uuid_as_string(UUID_V1);
    } elsif ( $self->uuid_scheme == 2 ) {
        return create_uuid_as_string(UUID_V4);
    }
}


sub create_string_from_url {
    my $self = shift;
    my $url  = shift;
    local $!;
    if ( $self->uuid_scheme == 1 ) {

        # Yes, DNS, not URL. We screwed up when we first defined it
        # and it can't be safely changed once defined.
        create_uuid_as_string( UUID_V3, UUID_NS_DNS, $url );
    } elsif ( $self->uuid_scheme == 2 ) {
        create_uuid_as_string( UUID_V5, UUID_NS_URL, $url );
    }
}

sub from_string {
    my $self = shift;
    my $str  = shift;
    return string_to_uuid($str);
}

sub to_string {
    my $self = shift;
    my $uuid = shift;
    return uuid_to_string($uuid);
}

sub from_safe_b64 {
    my $self = shift;
    my $uuid = shift;
    return urlsafe_b64decode($uuid);
}

sub to_safe_b64 {
    my $self = shift;
    my $uuid = shift;
    return urlsafe_b64encode( $self->from_string($uuid) );
}

sub version {
    my $self = shift;
    my $uuid = shift;
    return version_of_uuid($uuid);
}

sub set_uuid_scheme {
    my $self = shift;
    my $uuid = shift;

    if ( $self->version($uuid) <= 3 ) {
        $self->uuid_scheme(1);
    } else {
        $self->uuid_scheme(2);
    }
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::UUIDGenerator - Creates v4 & v5 UUIDs.

=head1 VERSION

version 0.751

=head1 DESCRIPTION

Creates UUIDs using L<UUID::Tiny>.  Initially, it created v1 and v3 UUIDs; the
new UUID scheme creates v4 and v5 UUIDs, instead.

=head1 ATTRIBUTES

=head2 uuid_scheme

Gets or sets the UUID scheme; if 1, then creates v1 and v3 UUIDs (for backward
compatibility with earlier versions of Prophet).  If 2, it creates v4 and v5
UUIDs.

=head1 METHODS

=head2 create_str

Creates and returns v1 or v4 UUIDs, depending on L</uuid_scheme>.

=head2 create_string_from_url URL

Creates and returns v3 or v5 UUIDs for the given C<URL>, depending on
L</uuid_scheme>.

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
