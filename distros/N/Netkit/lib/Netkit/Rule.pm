package Rule;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my %params = @_;
	
	my $self = bless {
		table => $params{table},
		chain => $params{chain},
		stateful => $params{stateful},
		proto => $params{proto},
		dst => $params{dst},
		src => $params{src},
		dport => $params{dport},
		sport => $params{sport},
		action => $params{action},
		to_dst => $params{to_dst},
		to_src => $params{to_src},
		policy => $params{policy},
	}, $class;

	return $self;
}

sub dump {
	my $class = shift;
	
	print "iptables ";
	
	print "-t $class->{table} " if defined($class->{table});
	print "-A $class->{chain} " if defined($class->{chain});
	print "-m state --state NEW " if defined($class->{stateful});
	print "-p $class->{proto} " if defined($class->{proto});
	print "-d $class->{dst} " if defined($class->{dst});
	print "-s $class->{src} " if defined($class->{src});
	print "--dport $class->{dport} " if defined($class->{dport});
	print "--sport $class->{sport} " if defined($class->{sport});
	print "-j $class->{action} " if defined($class->{action});
	print "--to-destination $class->{to_dst} " if defined($class->{to_dst});
	print "--to-source $class->{to_src} " if defined($class->{to_src});
	print "--policy $class->{policy} " if defined($class->{policy});
	
	print "\n";
}

1;
