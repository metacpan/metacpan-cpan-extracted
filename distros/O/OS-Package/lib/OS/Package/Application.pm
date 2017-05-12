use v5.14.0;
use warnings;

package OS::Package::Application;

# ABSTRACT: OS::Package::Application object.
our $VERSION = '0.2.7'; # VERSION

use Moo;
use Types::Standard qw( Str InstanceOf );

has [qw/name version/] => ( is => 'rw', isa => Str, required => 1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Application - OS::Package::Application object.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 name

The name of the application.

=head2 version

The version of the application.

=head2 fakeroot

The location on the local file system where build is staged prior to packaging.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
