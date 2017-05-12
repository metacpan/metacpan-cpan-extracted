#!/usr/local/bin/perl

use lib 'blib/lib';

$| = 1;

use ProLite qw(:core :commands :colors :styles :dingbats :effects);

unless($ARGV[1])
{
	print "usage: sign.pl -f filename\n";
	exit 1;
}

my $s = new ProLite(id=>1, device=>'/dev/ttyS0');

$err = $s->connect();
die "Can't connect to device - $err" if $err;

print "Sending...";

$s->wakeUp();

#$s->setPage(26, RESET, brightYellow, appearL, "...Loading...");
#$s->runPage(26);

$s->setClock();

if($ARGV[0] = '-f')
{
	open F, $ARGV[1] or die "Can't open $ARGV[1]: $!";
	while(<F>)
	{
		$line = $_;
		chomp $line;
		
		print "L: $line\n";
		
		$command = '$s->'.$line.'(' if $line =~ /^\S/;
		push @args, $line if $line =~ /^\s/;

		if($line eq '' and @args)
		{
			$command .= join(',', @args).');';
			print "C: $command\n";
			eval $command;
			print "Error: $@" if $@;
			undef $command;
			undef @args;
		}
	}
	close F
}

print "Done.\n";

sleep 1;

