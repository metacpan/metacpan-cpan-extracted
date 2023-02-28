package Machine;

use strict;
use warnings;

use List::Util qw(any);


sub new {
	my $class = shift;
	
	my %params = @_;
	
	my $name = $params{name};
	my @interfaces = @{ $params{interfaces} // [] };
	my @routes = @{ $params{routes} // [] };
	my @attachments = @{ $params{attachments} // [] };
	my @rules = @{ $params{rules} // []};

	my $self = bless {
		name => $name,
		interfaces => \@interfaces,
		conf_buffer => $params{extra_conf} // '',
		startup_buffer => $params{extra} // '',
		routes => \@routes,
		attachments => \@attachments,
		rules => \@rules,
	}, $class;

	return $self;
}

sub ips {
	my $class = shift;

	return map {
		my $ip = $_->{ip};
		$ip =~ s/\/\d+$//g;
		return $ip;
	} @{$class->{interfaces}};
}

sub rule {
	my $class = shift;
	
	my ($rule) = @_;
	
	push @{$class->{rules}}, $rule;
}

sub extra {
	my $class = shift;
	
	my %params = @_;
	
	$class->{startup_buffer} .= "\n######### $params{header} #########\n\n" if(defined $params{header});
	
	$class->{startup_buffer} .= "\n" . $params{data} . "\n";
}

sub dump_startup {
	my $class = shift;
	
	for (@{$class->{interfaces}}){
		$_->dump;
	}
	
	for (@{$class->{routes}}){
		$_->dump;
	}
	
	if (any {$_->{stateful}} @{$class->{rules}}) { # Add stateful rules if any of the rules has stateful=1
		print "\niptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT \n\n";
	}
	
	for (grep {defined($_->{vlan})} @{$class->{attachments}}) {
		my $vlan = $_->{vlan};
		
		print 'bridge vlan add vid ' . $vlan->{vid} . ' ';
		
		if(! $_->{tagged}){
			print 'pvid untagged ';
		}
		
		print "dev eth$_->{eth}\n";
	}
	
	for (@{$class->{rules}}){
		$_->dump;
	}
	
	print $class->{startup_buffer}, "\n";
}

sub dump_conf {
	my $class = shift;
			
	for (grep {defined($_->{lan})} @{$class->{attachments}}) {
		my $lan = $_->{lan};
		
		print $class->{name}, '[', $_->{eth} . "]=$lan->{name}\n";
	}
		
	print $class->{conf_buffer}, "\n";
}

1;
