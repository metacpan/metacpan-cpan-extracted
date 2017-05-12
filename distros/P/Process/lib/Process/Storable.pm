package Process::Storable;

use 5.00503;
use strict;
use Storable              ();
use IO::Handle            ();
use IO::String            ();
use Scalar::Util          ();
use Params::Util          ();
use Process::Serializable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.30';
	@ISA     = 'Process::Serializable';

	# Hack IO::String to be a real IO::Handle
	unless ( IO::String->isa('IO::Handle') ) {
		@IO::String::ISA = qw{IO::Handle IO::Seekable};
	}
}

sub serialize {
	my $self = shift;

	# Serialize to a named file (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		return Storable::lock_nstore($self, shift);
	}

	# Serialize to a string (via a handle)
	if ( Params::Util::_SCALAR0($_[0]) ) {
		my $string = shift;
		$$string   = 'pst0' . Storable::nfreeze($self);
		return 1;
	}

	# Serialize to a generic handle
	if ( defined fileno($_[0]) ) {
		local $/ = undef;
		return Storable::nstore_fd($self, shift);
	}

	# Serialize to an IO::Handle object
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		my $string   = Storable::nfreeze($self);
		my $iohandle = shift;
		$iohandle->print( 'pst0' )  or return undef;
		$iohandle->print( $string ) or return undef;
		return 1;
	}

	# We don't support anything else
	undef;
}

sub deserialize {
	my $class = shift;
	my $self  = $class->_deserialize(@_);

	# Integrity check
	Params::Util::_INSTANCE($self, $class) or return undef;

	$self;
}

sub _deserialize {
	my $class = shift;

	# Serialize from a named file (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		return Storable::lock_retrieve(shift);
	}

	# Serialize from a string (via a handle)
	if ( Params::Util::_SCALAR0($_[0]) ) {
		my $string = shift;

		# Remove the magic header if it exists
		if ( substr($$string, 0, 4) eq 'pst0' ) {
			substr($$string, 0, 4, '');
		}

		return Storable::thaw($$string);
	}

	# Serialize from a generic handle
	if ( defined fileno($_[0]) ) {
		return Storable::retrieve_fd(shift);
	}

	# Serialize from an IO::Handle object
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		local $/   = undef;
		my $string = $_[0]->getline;

		# Remove the magic header if it exists
		if ( substr($string, 0, 4) eq 'pst0' ) {
			substr($string, 0, 4, '');
		}

		return Storable::thaw($string);
	}

	# We don't support anything else
	undef;
}

1;

__END__

=pod

=head1 NAME

Process::Storable - Storable-based implementation of Process::Serializable

=head1 SYNOPSIS

Create your package...

  package MyStorable;
  
  use base qw{Process::Storable Process};
  
  sub prepare { ... }
  sub run     { ... }
  
  1;

And then use it...

  use MyStorable;
  
  my $process = MyStorable->new( ... );
  $process->serialize( 'filename.dat' );
  
  # and so on...

=head1 DESCRIPTION

C<Process::Storable> provides an implementation of the
L<Process::Serializable> role using the standard L<Storable> module
from the Perl core. It is not itself a subclass of L<Process> so you
will need to inherit from both L<Process> (or a subclass) and
L<Process::Storable> if you want to make use of it.

Objects that inherit from C<Process::Storable> must follow the C<new>,
C<prepare>, C<run> rules of L<Process::Serializable>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
