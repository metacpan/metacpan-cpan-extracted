package PITA::Guest::Driver;

use 5.008;
use strict;
use Carp         ();
use File::Temp   ();
use File::Remove ();
use Params::Util ();
use PITA::XML    ();

our $VERSION = '0.60';





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Were we passed the guest object
	unless ( Params::Util::_INSTANCE($self->guest, 'PITA::XML::Guest') ) {
		Carp::croak('Missing or invalid guest');
	}

	# Get ourselves a fresh tmp directory
	unless ( $self->injector_dir ) {
		$self->{injector_dir} = File::Temp::tempdir();
	}
	unless ( -d $self->injector_dir and -w _ ) {
		die("Temporary directory " . $self->injector_dir . " is not writable");
	}
	$self->{pid} = $$;

	$self;
}

sub guest {
	$_[0]->{guest};
}

sub injector_dir {
	$_[0]->{injector_dir};
}





#####################################################################
# PITA::Guest::Driver Main Methods

sub ping {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'ping'");
}

sub discover {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'discover'");
}

sub test {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'test'");
}





#####################################################################
# Support Methods

# Is the param a fully resolved request
# To be usable, it needs an identifier and an absolute filename path
# that can be verified to exist.
# Returns the request or undef if not usable.
sub _REQUEST {
	my $self    = shift;
	my $request = Params::Util::_INSTANCE(shift, 'PITA::XML::Request')          or return undef;
	$request->id                                                  or return undef;
	File::Spec->file_name_is_absolute( $request->file->filename ) or return undef;
	-f $request->file->filename                                   or return undef;
	$request;
}

sub DESTROY {
	# Delete the temp dirs, ignoring errors
	if (
		$_[0]->{pid} == $$
		and
		$_[0]->{injector_dir}
		and
		-d $_[0]->{injector_dir}
	) {
		File::Remove::remove( \1, $_[0]->{injector_dir} );
		delete $_[0]->{injector_dir};
	}
}

1;

__END__

=pod

=head1 NAME

PITA::Guest::Driver - Abstract base for all PITA Guest driver classes

=head1 DESCRIPTION

This class provides a small amount of functionality, and is primarily
used to by drivers is a superclass so that all driver classes can be
reliably identified correctly.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
