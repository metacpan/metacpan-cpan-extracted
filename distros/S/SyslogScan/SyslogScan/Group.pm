package SyslogScan::Group;

$VERSION = 0.20;
sub Version { $VERSION };

use SyslogScan::Summary;
use SyslogScan::Usage;
use strict;

sub new
{
    my $type = shift;
    
    my $self = { byAddress => {},
		 groupUsage => new SyslogScan::Usage() };
    bless ($self,$type);
    return $self;
}

sub registerUsage
{
    my $self = shift;
    my $address = shift;
    my $usage = shift;

    my $byAddress = $$self{byAddress};
    
    $$self{groupUsage} -> addUsage($usage);
    $$byAddress{$address} = $usage -> deepCopy();
}

sub dump
{
    my $self = shift;
    my $retString;

    my $byAddress = $$self{byAddress};
    
    $retString .= $$self{groupUsage} -> dump();

    my $address;
    foreach $address (sort keys %$byAddress)
    {
	$retString .= "$address:\n";
	$retString .= $$byAddress{$address} -> dump();
    }
    return $retString;
}

1;

__END__

See L<SyslogScan::ByGroup> for documentation.
