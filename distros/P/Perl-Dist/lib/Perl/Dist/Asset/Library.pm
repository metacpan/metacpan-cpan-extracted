package Perl::Dist::Asset::Library;

=pod

=head1 NAME

Perl::Dist::Asset::Library - "C Library" asset for a Win32 Perl

=head1 SYNOPSIS

  my $library = Perl::Dist::Asset::Library->new(
      name       => 'zlib',
      url        => 'http://strawberryperl.com/packages/zlib-1.2.3.win32.zip',
      unpack_to  => 'zlib',
      build_a    => {
          'dll'    => 'zlib-1.2.3.win32/bin/zlib1.dll',
          'def'    => 'zlib-1.2.3.win32/bin/zlib1.def',
          'a'      => 'zlib-1.2.3.win32/lib/zlib1.a',
      },
      install_to => {
          'zlib-1.2.3.win32/bin'     => 'c/bin',
          'zlib-1.2.3.win32/lib'     => 'c/lib',
          'zlib-1.2.3.win32/include' => 'c/include',
      },
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::Library> is a data class that provides encapsulation
and error checking for a "C library" to be installed in a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::Inno> C<install_library>
method (and other things that call it).

B<Perl::Dist::Asset::Library> is similar to L<Perl::Dist::Asset::Binary>,
in that it captures a name, source URL, and paths for where to install
files.

It also takes a few more pieces of information to support certain more
esoteric functions unique to C library builds.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

use strict;
use Carp              ();
use Params::Util      qw{ _STRING _HASH };
use Perl::Dist::Asset ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.16';
	@ISA     = 'Perl::Dist::Asset';
}

use Object::Tiny qw{
	name
	license
	unpack_to
	build_a
	install_to
};





#####################################################################
# Constructor

=pod

=head2 new

TO BE COMPLETED

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	$self->{unpack_to} = '' unless defined $self->unpack_to;

	# Check params
	unless ( _STRING($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}
	unless ( ! defined $self->license or _HASH($self->license) ) {
		Carp::croak("Missing or invalid license param");
	}
	unless ( defined $self->unpack_to and ! ref $self->unpack_to ) {
		Carp::croak("Missing or invalid unpack_to param");
	}
	unless ( _STRING($self->install_to) or _HASH($self->install_to) ) {
		Carp::croak("Missing or invalid install_to param");
	}
	unless ( _HASH($self->build_a) ) {
		Carp::croak("Missing or invalid build_a param");
	}

	return $self;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
