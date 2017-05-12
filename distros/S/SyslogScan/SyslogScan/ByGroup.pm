package SyslogScan::ByGroup;

$VERSION = 0.20;
sub Version { $VERSION };

use SyslogScan::Group;
use SyslogScan::Summary;
use SyslogScan::Delivery;
use strict;

# Given an e-mail address, tries to return the internet domain name of
# the host.  Probably not a very reliable routine.
my $pDefaultGroupingSubroutine = sub {
    my $address = shift;

    $address =~ s/^\<(.+)\>$/$1/;
    if ($address =~ /^[^\@\!]+\@([^\@\!]+\.)?([^\.\@\!]+\.[^\.\@\!]+)$/)
    {
	return $2;
    }
    if ($address !~ /[\@\!]/)
    {
	return 'localhost';
    }
    return 'unknown';
};

sub new
{
    my $type = shift;
    my $summary = shift;
    my $pGroupingSubroutine = shift || $pDefaultGroupingSubroutine;
    
    my $self = {};
    bless ($self,$type);

    my $address;
    foreach $address (keys %$summary)
    {
	my $group = &$pGroupingSubroutine($address);
	next unless defined($group);
	
	if (! defined $$self{$group})
	{
	    $$self{$group} = new SyslogScan::Group();
	}

	$$self{$group} -> registerUsage($address,$$summary{$address});
    }

    return $self;
}

sub createSummary
{
    my $self = shift;

    my $summary = new SyslogScan::Summary();
    
    my $groupName;
    foreach $groupName (keys %$self)
    {
	my $group = $$self{$groupName};
	$$summary{$groupName} = $$group{groupUsage} -> deepCopy();
    }
    return $summary;
}

sub dump
{
    my $self = shift;

    my $retString;

    my $group;
    foreach $group (sort keys %$self)
    {
	$retString .= "$group TOTAL:\n";
	$retString .= $$self{$group} -> dump();
	$retString .= "\n";
    }
    return $retString;
}

__END__

=head1 NAME

SyslogScan::ByGroup -- Organizes a Summary of mail statistics into
Groups of related e-mail users

=head1 SYNOPSIS

    # $summary is a SyslogScan::Summary object

    # default is to organize by internet host
    my $byGroup = new SyslogScan::ByGroup($summary);
    print $byGroup -> dump();

    # group by whether users use 'jupiter' or 'satellife' as
    # their machine name, and discard users who use neither

    my $pointerToGroupingRoutine = sub {
	my $address = shift;

        return 'jupiter' if $address =~ /jupiter.healthnet.org$/;
	return 'satellife' if $address =~ /satellife.healthnet.org$/;

	# ignore all others
	return undef;
    }

    my $groupByMachine = new SyslogScan::ByGroup($summary,
						 $pointerToGroupingRoutine);
    print $groupByMachine -> dump();

    # Extract a SyslogScan::Group object
    my $jupiterGroup = $$groupByMachine{jupiter};
    print $jupiterGroup -> dump();

    # Extract a SyslogScan::Summary object
    my $summaryOfJupiter = $jupiterGroup{byAddress};
    print $summaryOfJupiter -> dump();
    
    # Create a summary by group, rather than a summary by address
    my $summaryByMachine = $groupByMachine -> createSummary();

=head1 DESCRIPTION

A SyslogScan::ByGroup object is a hash table of SyslogScan::Group
objects, each indexed by the group name as returned by the sorting
algorithm fed to 'new'.

A SyslogScan::Group is a hash table with two members: 'byAddress',
which is a SyslogScan::Summary of each address which is a member of
the Group, and 'groupUsage', which is a SyslogScan::Usage object
containing the total usage of the group.

=head1 AUTHOR and COPYRIGHT

The author (Rolf Harold Nelson) can currently be e-mailed as
rolf@usa.healthnet.org.

This code is Copyright (C) SatelLife, Inc. 1996.  All rights reserved.
This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

In no event shall SatelLife be liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of
the use of this software and its documentation (including, but not
limited to, lost profits) even if the authors have been advised of the
possibility of such damage.

=head1 SEE ALSO

L<SyslogScan::Summary>, L<SyslogScan::Usage>
