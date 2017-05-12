package Perlmazing::Engine::Exporter;
use strict;
use warnings;
use Carp;
our $VERSION = '1.2810';
my $package = __PACKAGE__;
my $imports;

sub import {
	my $self = shift;
	my @call = caller 0;
	my $pack = $call[0];
	no strict 'refs';
	if ($self eq $package) {
		my $in_isa = grep { /^\Q$package\E$/ } @{"${pack}::ISA"};
		unshift (@{"${pack}::ISA"}, __PACKAGE__) unless $in_isa;
	} else {
		if (my @call = caller 1) {
			$pack = $call[0] if $call[3] eq "${self}::import";
		}
		return if $imports->{$pack}->{$self};
		for my $i (@{"${self}::EXPORT"}) {
			$package->export($self, $i, $pack);
		}
		$imports->{$pack}->{$self}++;
	}
}

sub export {
	my $self = shift;
	my ($from, $symbol, $to) = (shift, shift, shift);
	my $sigil = '&';
	$symbol =~ s/^(\&|\$|\%|\@|\*)/$sigil = $1; ''/e;
	croak "Unknown symbol type for expression '$symbol' in EXPORT" if $symbol =~ /^\W/;
	no strict 'refs';
	no warnings 'once';
	if ($sigil eq '&') {
		if (not defined *{"${from}::$symbol"}{CODE}) {
			eval "sub ${from}::$symbol";
			croak "Cannot create symbol for sub ${from}::$symbol: $@" if $@;
		}
		if (defined *{"${to}::$symbol"}{CODE}) {
			croak "Cannot define symbol &${to}::$symbol: symbol is already defined under the same namespace and name";
		} else {
			*{"${to}::$symbol"} = *{"${from}::$symbol"}{CODE};
		}
	} elsif ($sigil eq '$') {
		if (not defined *{"${from}::$symbol"}{SCALAR}) {
			${"${from}::$symbol"} = undef;
		}
		*{"${to}::$symbol"} = *{"${from}::$symbol"}{SCALAR};
	} elsif ($sigil eq '@') {
		if (not defined *{"${from}::$symbol"}{ARRAY}) {
			@{"${from}::$symbol"} = ();
		}
		*{"${to}::$symbol"} = *{"${from}::$symbol"}{ARRAY};
	} elsif ($sigil eq '%') {
		if (not defined *{"${from}::$symbol"}{HASH}) {
			%{"${from}::$symbol"} = ();
		}
		*{"${to}::$symbol"} = *{"${from}::$symbol"}{HASH};
	} elsif ($sigil eq '*') {
		*{"${to}::$symbol"} = *{"${from}::$symbol"};
	} else {
		croak "I don't know how to handle '$symbol' in EXPORT";
	}
}

1;