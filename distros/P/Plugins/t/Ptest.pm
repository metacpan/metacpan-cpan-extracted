
package t::Ptest;

use strict;
use warnings;
use Test::More;
use Plugins::SimpleConfig;

our @ISA = qw(Plugins::Plugin);

my %config_items = (
	name		=> 'foobar',
	c1		=> 'xxy',
	c2		=> '38x',
	hasplugins	=> 0,
	configfile	=> '',
);

sub config_prefix { return 'ptest' };

sub parse_config_line { simple_config_line(\%config_items, @_); }

sub new 
{
	my $self = simple_new(\%config_items, @_); 

	$self->{api}->register($self, apinormal => \&getval);
	$self->{api}->register($self, apifirst => \&getval);
	$self->{api}->register($self, apicombine => \&getval);
	$self->{api}->register($self, apiarray => \&getval);
	$self->{api}->register($self, apitest => \&getval);

	return $self;
}

sub nameis
{
	my ($self, $name) = @_;
	return 0 unless $name eq $self->{name};
	ok(1, "nameis $name");
	return 1;
}

sub getval
{
	my ($self, $field) = @_;
	return $self->{$field};
}

sub preconfig
{
	my ($self, $cf) = @_;
	return unless $self->{hasplugins};

	my $config = $self->{configfile} || $cf;

	$self->{myapi} = Plugins::API->new;

        $self->{myapi}->api(
		apifoo		=> {},
	);
	$self->{myapi}->autoregister($self);
	$self->{myapi}->register(undef, parentapi => sub { return $self->{api} });

	$self->{plugins} = new Plugins context => $self->{context};
	$self->{plugins}->readconfig($config, self => $self);

	$self->{plugins}->api($self->{myapi});
	$self->{myapi}->plugins($self->{plugins});

	$self->{plugins}->initialize();
	$self->{plugins}->invoke('preconfig', $config);

}

1;
