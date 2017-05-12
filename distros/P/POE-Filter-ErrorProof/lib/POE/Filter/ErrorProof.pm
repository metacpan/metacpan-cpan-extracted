package POE::Filter::ErrorProof;

use 5.000;
use strict;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(POE::Filter);

sub new {
	my ($type, $filter, $errorsock) = @_;
	if(!defined($filter)) {
		$filter = new POE::Filter::Stream;
	}

	my $outputErrors;
	if(!defined($errorsock)) {
		$outputErrors = 0;
	} elsif(ref($errorsock) eq "GLOB") {
		$outputErrors = 1;
	} elsif(ref($errorsock) eq "POE::Wheel::ReadWrite") {
		$outputErrors = 2;
	} elsif($errorsock == 1) {
		$outputErrors = 1;
		$errorsock = \*STDERR;
	}

	$type = ref($type) if ref($type);
	my $self = {
		filter => $filter,
		outputErrors => $outputErrors,
		errorsock => $errorsock,
		output => sub {
			my $self = shift; my $error = shift;
			my $oe = $self->{outputErrors};
			if($oe == 1) {
				my $sock = $self->{errorsock};
				print $sock $error;
			} elsif($oe == 2) {
				$self->{errorsock}->put($error);
			}
		},
	};
	bless $self, $type;
	return $self;
}

sub clone {
	my ($self) = @_;
	my $filter;
	eval {
		if($self->{filter}->can('clone')) {
			$filter = $self->{filter}->clone();
		} else {
			$filter = $self->{filter};
		}
	};
	if($@) {
		$self->{output}->($self, $@);
		return undef;
	}
	my $clone = {
		filter => $filter,
	};
	bless $clone, ref $self;
	return $clone;
}

sub DESTROY {
	my ($self) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->DESTROY() if($self->{filter}->can('DESTROY'));
	};
	if($@) {
		$self->{output}->($self, $@);
		return undef;
	}
	return $outp;
}

sub reset {
	my ($self) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->reset() if($self->{filter}->can('reset'));
	};
	if($@) {
		$self->{output}->($self, $@);
		return undef;
	}
	return $outp;
}

sub get_one_start {
	my ($self, $stream) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->get_one_start($stream);
	};
	if($@) {
		$self->{output}->($self, $@);
		return undef;
	}
	return $outp;
}

sub get_one {
	my ($self) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->get_one();
	};
	if($@) {
		$self->{output}->($self, $@);
		return [];
	}
	return $outp;
}

sub put {
	my ($self, $chunks) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->put();
	};
	if($@) {
		$self->{output}->($self, $@);
		return [];
	}
	return $outp;
}

sub get_pending {
	my ($self) = @_;
	my $outp;
	eval {
		$outp = $self->{filter}->get_pending();
	};
	if($@) {
		$self->{output}->($self, $@);
		return undef;
	}
	return $outp;
}



1;
__END__
=head1 NAME

POE::Filter::ErrorProof - POE::Filter wrapper around 'dangerous' Filters

=head1 SYNOPSIS

  use POE::Filter::ErrorProof;
  my $wheel = POE::Wheel::ReadWrite->new(
  	Filter	=> POE::Filter::ErrorProof->new(POE::Filter::Something->new()),
  );

=head1 DESCRIPTION

This module is a wrapper around other POE::Filters. I made this module when I noticed POE::Filter::XML would die() when non-XML input was given to it. The author of the module wasn't there, so I had to bring up a solution.
You can use this module if you use a POE::Filter that might die if something bad happens. This Filter does nothing more than giving through the input in eval blocks.

=head1 THE NEW METHOD

   POE::Filter::ErrorProof->new(); # Create a POE::Filter::ErrorProof with a POE::Filter::Stream in it
   POE::Filter::ErrorProof->new(POE::Filter::XML->new()); # Do the same but with a POE::Filter::XML
   POE::Filter::ErrorProof->new(POE::Filter::XML->new(), 1); # Do the same, but output errors on STDERR
   POE::Filter::ErrorProof->new(POE::Filter::XML->new(), $socket); # Do the same, but output errors on this socket
   $wheel = POE::Wheel::ReadWrite->new( .... );
   POE::Filter::ErrorProof->new(POE::Filter::XML->new(), $wheel); # Output errors to this wheel

=head1 AUTHOR

Sjors Gielen, E<lt>sjorsgielen@gmail.comE<gt>

=cut
