#!/usr/bin/perl -w

###################################################################
# Copyright 2000-02 Riad Wahby <rsw@jfet.org> All rights reserved #
# This program is free software.  You may redistribute it and/or  #
# modify it under the same terms as Perl itself.                  #
###################################################################

sub callback;
sub callbacksi;

# these are used to translate the status info
# coming from the server.  See man page for more
# info
%com1 = (' ' => '',
	 ''  => '',
	 'A' => 'on AOL');
%com2 = (' ' => '',
	 ''  => '',
	 'A' => 'Oscar Admin',
	 'U' => 'Oscar Unconfirmed',
	 'O' => 'Oscar Normal');
%com3 = ("\0" => '',
	 ''  => '',
	 ' ' => '',
	 'U' => 'Unavailable');

use Net::AOLIM;

print "Enter username: ";
chomp ($username = <>);

print "Enter password: ";
chomp ($password = <>);

$foo = Net::AOLIM->new("username" => $username, 
		       "password" => $password,
		       "callback" => \&callback,
		       "allow_srv_settings" => 0,
		       "login_timeout" => 2 );

print $foo->{'aim_agent'}, "\n";

$foo->add_buddies("friends", $username);

$foo->ui_add_fh(\*STDIN, \&callbacksi);

$oldfh=select(STDIN);$|=1;select($oldfh);

unless (defined($foo->signon))
{
    die "Error number was: $IM_ERR";
}

while (1)
{
    last unless defined($foo->ui_dataget(undef));
}

sub callback
{
    my $type = shift @_;

    if ($type eq 'NICK')
    {
	$username = $_[0];
    }
    elsif ($type eq 'IM_IN')
    {
	if (($_[1] eq 't') || ($_[1] eq 'T'))
	{
	    print "\e[1;33mAuto Response \e[0m";
	}
	print "From:\e[1;31m $_[0]\e[0m  : $_[2]\n--\n";
    }
    elsif ($type eq 'UPDATE_BUDDY')
    {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($_[3]);
	my $timestr = sprintf("%.2i:%.2i:%.2i", $hour , $min , $sec) . " " . sprintf("%.2i/%.2i/%.4i", $mon + 1, $mday, $year + 1900);
	my ($c1, $c2, $c3) = split(//, $_[5]);
	my $commentstr = join(' ', $com1{$c1}, $com2{$c2}, $com3{$c3});
	print "Buddy \e[1;31m$_[0]\e[0m update: Online=$_[1] : Evil=$_[2] : Signon time=$timestr : Idle time=$_[4] : Comments=$commentstr :: $_[5]\n--\n";
    }
    elsif ($type eq 'ERROR')
    {
	$ERR_ARG = $_[1];
	$ERROR = "$Net::AOLIM::ERROR_MSGS{$_[0]}";
	$ERROR =~ s/\$ERR_ARG/$ERR_ARG/g;
	
	print "\e[1;35mERROR!\e[0m : $_[0]: $ERROR\n--\n";
    }
    elsif ($type eq 'EVILED')
    {
	$_[1] ||= 'anonymous';
	print "\e[1;4;37mEviled\e[0m by $_[1].  New evil is $_[0].\n--\n";
    }
    else
    {
	print $type, "\n", join("\n", @_), "\n";
	return 0;
    }
}

sub callbacksi
{
    my $recv_buffer;

    unless (defined (sysread *STDIN, $recv_buffer, 65535))
    {
	die "Couldn't read STDIN!";
    }

    if ($recv_buffer =~ /^\/(.+?)\s/)
    {
	$command = $1;

	if ($command =~ /im/i)
	{
	    my ($command, $message);
	    ($command, $touser, $message) = split(' ', $recv_buffer, 3);
	    $foo->toc_send_im($foo->norm_uname($touser), $message, 0);
	}
	elsif ($command =~ /evil/i)
	{
	    my ($command, @evils) = split(' ', $recv_buffer);

	    if ($evils[0] =~ /^[01]$/)
	    {
		$anon = shift @evils;
	    }
	    else
	    {
		$anon = 0;
	    }

	    foreach $evil (@evils)
	    {
		$foo->toc_evil($evil,$anon);
	    }
	}
	elsif ($command =~ /permitall/i)
	{
	    $foo->add_im_permit_all;
	}
	elsif ($command =~ /blockall/i)
	{
	    $foo->add_im_deny_all;
	}
	elsif ($command =~ /blocks/i)
	{
	    my @blocklist = $foo->current_denies;

	    print "Deny list: ", join(' ', @blocklist), "\n";
	}
	elsif ($command =~ /permits/i)
	{
	    my @permitlist = $foo->current_permits;

	    print "Permit list: ", join(' ', @permitlist), "\n";
	}
	elsif ($command =~ /block/i)
	{
	    my ($command, @blocklist) = split(' ', $recv_buffer);
	    my (@addblocks, @removeblocks);

	    foreach $block (@blocklist)
	    {
		if ($block =~ /^\+(.*)$/)
		{
		    push @addblocks, $1;
		}
		elsif ($block =~ /^-(.*)$/)
		{
		    push @removeblocks, $1;
		}
		else
		{
		    push @addblocks, $block;
		}
	    }

	    if (scalar @addblocks)
	    {
		print "Adding Blocks ", join(' ', @addblocks), "\n";
		
		$foo->add_im_deny(@addblocks);
	    }

	    if (scalar @removeblocks)
	    {
		my @denylist;
		my %temp = ();

		print "Removing Blocks ", join(' ', @removeblocks), "\n";
		
		@denylist = $foo->current_denies;
		
		map {$temp{$_} = 1;} @denylist;
		map {delete $temp{$_};} @removeblocks;

		@denylist = keys %temp;

		$foo->add_im_deny_all;
		
		$foo->add_im_deny(@denylist);
	    }
	}
	elsif ($command =~ /permit/i)
	{
	    my ($command, @permitlist) = split(' ', $recv_buffer);
	    my (@addpermits, @removepermits);

	    foreach $permit (@permitlist)
	    {
		if ($permit =~ /^\+(.*)$/)
		{
		    push @addpermits, $1;
		}
		elsif ($permit =~ /^-(.*)$/)
		{
		    push @removepermits, $1;
		}
		else
		{
		    push @addpermits, $permit;
		}
	    }

	    if (scalar @addpermits)
	    {
		print "Adding Permits ", join(' ', @addpermits), "\n";

		$foo->add_im_permit(@addpermits);
	    }
	    
	    if (scalar @removepermits)
	    {
		my @permitlist;
		my %temp = ();

		print "Removing Permits ", join(' ', @removepermits), "\n";
		
		@permitlist = $foo->current_permits;

		map {$temp{$_} = 1;} @permitlist;
		map {delete $temp{$_};} @removepermits;

		@permitlist = keys %temp;

		$foo->add_im_deny_all;

		$foo->add_im_permit(@permitlist);
	    }
	}
	elsif ($command =~ /buddy/i)
	{
	    my ($command, @buddies) = split(' ', $recv_buffer);
	    my (@addbuddies, @removebuddies);
	    
	    foreach $buddy (@buddies)
	    {
		if ($buddy =~ /^\+(.*)$/)
		{
		    push @addbuddies, $1;
		}
		elsif ($buddy =~ /^-(.*)$/)
		{
		    push @removebuddies, $1;
		}
		else
		{
		    push @addbuddies, $buddy;
		}
	    }

	    if (scalar @removebuddies)
	    {
		print "Removing buddies ", join(' ', @removebuddies), "\n";
		
		$foo->remove_online_buddies(@removebuddies);
	    }

	    if (scalar @addbuddies)
	    {
		unless ($group)
		{
		    print "Please set the group into which to add buddies first with the /group command!\n";
		    return;
		}
		
		print "Adding buddies ", join(' ', @addbuddies), " to group $group\n";

		$foo->add_online_buddies($group, @addbuddies);
	    }
	}
	elsif ($command =~ /buddies/i)
	{
	    my %buddyhash;

	    $foo->current_buddies(\%buddyhash);

	    foreach $key (keys %buddyhash)
	    {
		print "g $key\n";
		foreach $buddy (@{$buddyhash{$key}})
		{
		    print "b $buddy\n";
		}
	    }
	}
	elsif ($command =~ /group/i)
	{
	    ($command, $group) = split(' ', $recv_buffer, 2);
	    chomp $group;
	}
	elsif (($command =~ /quit/i) || ($command =~ /exit/i))
	{
	    print "Really exit [y/N]: ";
	    $answer = <STDIN>;
	    
	    if ($answer =~ /^y/i)
	    {
		exit;
	    }
	    else
	    {
		print "Whew!  I got nervous there for a second :-)\n";
	    }
	}
    }
    else
    {
# we assume everything else is just an IM to the last person we IMed
	$foo->toc_send_im($touser, $recv_buffer);
    }
}
