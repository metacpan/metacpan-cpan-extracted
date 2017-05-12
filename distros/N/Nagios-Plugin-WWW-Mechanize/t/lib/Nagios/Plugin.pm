package Nagios::Plugin;
# Dummy package to find out what is being called

sub new {
	my $class = shift;
	my $new = {};
	$new->{options} = \@_;
	$new->{perfdata} = [];
	bless $new, $class;
}

sub nagios_exit {
	my $self = shift;
	$self->{nagios_exit} = { code => $_[0], message => $_[1] };
}

sub add_perfdata {
	my $self = shift;
	push @{$self->{perfdata}}, { @_ };
}

1;
