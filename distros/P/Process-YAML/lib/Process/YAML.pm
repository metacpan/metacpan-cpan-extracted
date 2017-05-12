package Process::YAML;

# Process that is compatible with Storable after new, and after run.

use 5.005;
use strict;
use base 'Process::Serializable';
use Fcntl qw/:flock/;
use YAML::Syck   ();
use IO::Handle   ();
use IO::File     ();
use IO::String   ();
use Scalar::Util ();
use Params::Util qw/_INSTANCE/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}

BEGIN {
	unless ( IO::String->isa('IO::Handle') ) {
		push @IO::String::ISA, 'IO::Handle';
	}
	unless ( IO::String->isa('IO::Seekable') ) {
		push @IO::String::ISA, 'IO::Seekable';
	}
}

sub serialize {
	my $self = shift;

	# Serialize to a string (via a handle)
	if ( Params::Util::_SCALAR0($_[0]) ) {
		my $handle = IO::String->new($_[0]);
		return print $handle YAML::Syck::Dump($self);
	}

	# Serialize to a generic handle
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') or fileno($_[0]) ) {
		my $handle = $_[0];
		return print $handle YAML::Syck::Dump($self);
	}

	# Serialize to a file name (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		my $fh;
		my $mode = '+<';
		if ( not -e $_[0] ) {
			$mode = '+>';
		}
		if ( not open($fh, $mode, $_[0]) ) {
			return undef;
		}
		if ( not flock($fh, LOCK_EX) ) {
			return undef;
		}
		if ( not truncate($fh, 0) ) {
			return undef;
		}
		if ( not print $fh YAML::Syck::Dump($self) ) {
			return undef;
		}
		if ( not close $fh ) {
			return undef;
		}
		return 1;
	}

	# We don't support anything else
	undef;
}

sub deserialize {
	my $class = shift;

	# Deserialize from a string
	if ( Params::Util::_SCALAR0($_[0]) ) {
		return YAML::Syck::Load(${$_[0]});
	}

	# Deserialize from a generic handle
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') or fileno($_[0]) ) {
		my $handle = $_[0];
		return YAML::Syck::Load(join '', <$handle>);
	}

	# Deserialize from a file name (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		my $fh;
		if ( not open($fh, '<', $_[0]) ) {
			return undef;
		}
		if ( not flock($fh, LOCK_SH) ) {
			return undef;
		}
		return YAML::Syck::Load(join '', <$fh>);
	}

	# We don't support anything else
	undef;
}

1;

__END__

=pod

=head1 NAME

Process::YAML - The Process::Serializable role implemented by YAML

=head1 SYNOPSIS

  package MyYAMLProcess;
  
  use base 'Process::YAML',
           'Process';
  
  sub prepare {
      ...
  }
  
  sub run {
      ...
  }
  
  1;

=head1 DESCRIPTION

C<Process::YAML> provides an implementation of the
L<Process::Serializable> role using the L<YAML::Syck> module from CPAN.
It is not itself a subclass of L<Process> so you
will need to inherit from both.

Objects that inherit from C<Process::YAML> must follow the C<new>,
C<prepare>, C<run> rules of L<Process::Serializable>.

L<YAML::Syck> was chosen over L<YAML> because L<YAML::Syck> is much faster.
Furthermore, L<YAML> uses L<Spiffy> which I could not get to play well with
the inheritance scheme of the L<Process> framework at the time (Spiffy 0.26).
By now, Brian Ingerson has released a fixed version of Spiffy (0.27), so
C<YAML> 0.52 and higher is compatible with Process::YAML.

=head2 METHODS

Using this class as an additional base class for your
C<Process> based classes will add two methods to your class as defined
by the L<Process::Serializable> documentation. Please refer to that module
for a description of the interface.

=over 2

=item serialize

=item deserialize

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process-YAML>

For other issues, contact the author.

=head1 AUTHOR

Steffen Mueller E<lt>modules at steffen-mueller dot netE<gt>, L<http://steffen-mueller.net/>

=head1 COPYRIGHT

Copyright 2006 Steffen Mueller. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
