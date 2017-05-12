package Process::Probe;

=pod

=head1 NAME

Process::Probe - Process to test if any named classes are installed

=head1 SYNOPSIS

  my $probe = Process::Probe->new( qw{
      My::Process
      CPAN::Module::Process
      Something::Else
  } );
  
  $probe->run;
  
  # Lists of classes
  my @yep   = $probe->available;
  my @nope  = $probe->unavailable;
  my @maybe = $probe->unknown;
  
  # Test for single class with any of the above
  if ( $probe->available('My::Process') ) {
      print "My::Process is available\n";
  }

=head1 DESCRIPTION

B<Process::Probe> is a simple and standardised class available that is
available with the core L<Process> distribution. It is used to probe
a host to determine whether or not the remote host has certain process
classes installed.

By default, the object will search through the system's include path to
find the .pm files that match the particular classes.

Typical examples of using the default functionality could include
executing a B<Process::Probe> object via a SSH login on a remote host
to determine which of a set of desired classes exist on the remote host.

The probe will ONLY check for the existance of classes that are in the
unknown state at the time the C<run> method is called.

In scenarios where the requestor does not have direct execution rights
on the remote host, and the request is being marshalled via a server
process, this allows security code on the server to preset forbidden
classes to no before the probe is run, or to otherwise manipulate the
"answer" to the "question" that B<Process::Probe> represents. 

No functionality is provided to query ALL the C<Process>-compatible
classes on a remote host. This is intentional. It prevents very
disk-intensive scans, protects remote host against hostile requests,
and prevents the use of these objects en-mass as a denial of service.

=cut

use 5.00503;
use strict;
use File::Spec           ();
use List::Util           ();
use Params::Util         ();
use Process::Delegatable ();
use Process              ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.30';
	@ISA     = qw{
		Process::Delegatable
		Process
	};
}

sub new {
	my $class = shift;

	# Create the object
	my $self = bless {
		modules => { },
	}, $class;

	# Add the modules to test for
	while ( @_ ) {
		my $module = shift;
		unless ( Params::Util::_CLASS($module) ) {
			return undef;
		}
		$self->{modules}->{$module} = undef;
	}

	return $self;
}

sub run {
	my $self = shift;
	my $hash = $self->{modules};
	foreach my $key ( sort keys %$hash ) {
		$hash->{$key} = 0;
		my @path = split /::/, $key;		
		foreach my $dir ( @INC ) {
			next if ref $dir;
			next unless -f File::Spec->catfile($dir, @path) . '.pm';
			$hash->{$key} = 1;
			last;
		}
	}
	return 1;
}

sub available {
	my $self = shift;
	my $hash = $self->{modules};
	if ( @_ ) {
		return !! (
			$hash->{$_[0]}
		);
	} else {
		return grep {
			$hash->{$_}
		} sort keys %$hash;
	}
}

sub unavailable {
	my $self = shift;
	my $hash = $self->{modules};
	if ( @_ ) {
		return !! (
			defined $hash->{$_[0]}
			and
			not $hash->{$_[0]}
		);
	} else {
		return grep {
			defined $hash->{$_} and not $hash->{$_}
		} sort keys %$hash;
	}
}

sub unknown {
	my $self = shift;
	my $hash = $self->{modules};
	if ( @_ ) {
		return !! (
			not defined $hash->{$_[0]}
		);
	} else {
		return grep {
			not defined $hash->{$_}
		} sort keys %$hash;
	}
}

1;

=pod

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
