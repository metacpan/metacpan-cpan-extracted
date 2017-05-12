use v5.14.0;
use warnings;

package OS::Package;

# ABSTRACT: OS Package Management System
our $VERSION = '0.2.7'; # VERSION

use Moo;
use Path::Tiny;
use OS::Package::System;
use Types::Standard qw( Str ArrayRef InstanceOf );

with qw(
    OS::Package::Role::Clean
    OS::Package::Role::Build
    OS::Package::Role::Prune
);

has [qw/name description prefix/] =>
    ( is => 'rw', isa => Str, required => 1 );

has [qw/config install build_id/] => ( is => 'rw', isa => Str );

has [qw/prune_dirs prune_files/] => ( is => 'rw', isa => ArrayRef );

has artifact => ( is => 'rw', isa => InstanceOf ['OS::Package::Artifact'] );

has application => (
    is       => 'rw',
    isa      => InstanceOf ['OS::Package::Application'],
    required => 1
);

has system => (
    is       => 'rw',
    isa      => InstanceOf ['OS::Package::System'],
    default  => sub { return OS::Package::System->new; },
    required => 1
);

has maintainer => (
    is       => 'rw',
    isa      => InstanceOf ['OS::Package::Maintainer'],
    required => 1
);

has fakeroot => (
    is       => 'rw',
    isa      => InstanceOf ['Path::Tiny'],
    required => 1,
    default  => sub { return Path::Tiny->tempdir }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package - OS Package Management System

=head1 VERSION

version 0.2.7

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CHANGES

=head2 Version 0.2.7 (2015-06-23)

=over 4

=item *

Add repository directory option

=back

=head2 Version 0.2.6 (2014-09-29)

=over 4

=item *

Fix log entry

=back

=head2 Version 0.2.5 (2014-09-28)

=over 4

=item *

POD update

=back

=head2 Version 0.2.4 (2014-09-28)

=over 4

=item *

Fix sprintf error in SVR4 plugin [GH-2]

=item *

Add missing dependency

=back

=head2 Version 0.2.3 (2014-09-27)

=over 4

=item *

POD updates

=back

=head2 Version 0.2.2 (2014-09-27)

=over 4

=item *

update email address

=back

=head2 Version 0.2.1 (2014-09-27)

=over 4

=item *

Add github metadata

=back

=head2 Version 0.2.0 (2014-09-27)

=over 4

=item *

Add build tag option

=item *

Add init command

=item *

ospkg configuration stored in ~/.ospkg by default

=back

=head2 Version 0.1.0 (2014-09-11)

=over 4

=item *

Initial Release

=back

=cut
