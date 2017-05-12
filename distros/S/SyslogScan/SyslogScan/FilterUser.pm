package SyslogScan::FilterUser;

$VERSION = 0.20;
sub Version { $VERSION };

use strict;

sub new
{
    my $type = shift;
    my $selfPattern = shift || '.*';
    my $otherPattern = shift || '.*';

    my $self = [$selfPattern,
		$otherPattern];

    bless($self,$type);
}

sub matchesFilter
{
    my $self = shift;
    my $selfUserName = shift;
    my $otherUserName = shift;

    return 0 if $selfUserName !~ /$$self[0]/i;
    return 0 if $otherUserName !~ /$$self[1]/i;
    return 1;
}

1;
