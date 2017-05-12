package TestUtil;

use strict;
use ServiceNow::SOAP;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(config getProp isGUID getTimestamp today);

our $config;

sub config {
    foreach my $configfile (
            '.test.config', 
            't/.test.config',
            'test.config', 
            't/test.config') {
        next unless -f $configfile;
        do $configfile;
        return $config;
    }
    return $config;
};

sub getProp {
    my $name = shift;
    return $config->{$name};
}

sub getInstance {
    return $config->{instance};
}

sub getUsername {
    return $config->{username};
}

sub getSession {
    my %opt = @_;
    $opt{trace} = 1 unless defined $opt{trace};
    my $instance = $config->{instance};
    my $user = $config->{username};
    my $pass = $config->{password};
    return ServiceNow($instance, $user, $pass, %opt);
}

sub isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

sub getTimestamp {
    return timestamp();
}

sub timestamp {
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
	my $timestamp = 
		10000000000 * (1900 + $year) + 
		100000000 * (1 + $mon) + 
		1000000 * $mday + 
		10000 * $hour + 
		100 * $min + 
		$sec;
	return $timestamp;
}

sub today {
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime;
    return sprintf("%04d-%02d-%02d", 1900 + $year, 1 + $mon, $mday);
}

sub lorem {
    my $lorem = <<zzz;
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur efficitur mi nisl, in consectetur tellus pellentesque eu. Aliquam ante purus, consectetur sed laoreet ut, viverra a ligula. 

Nunc congue eros eros, vel egestas urna aliquet sed. Duis euismod tristique nunc, id feugiat lorem mattis id. Etiam sodales congue enim gravida accumsan. Duis vel justo fermentum, laoreet nulla vel, convallis arcu. Aenean ac ex tincidunt, fermentum felis at, condimentum velit.
zzz
    return $lorem;
}

1;
