#!/usr/bin/perl

use warnings;
use strict;

use Data::Dump qw(dump);
use Time::HiRes;
use Getopt::Long;
use Term::ReadLine;
use lib 'lib';
use Printer::EVOLIS::Parallel;

my $port = '/dev/usb/lp0';
my $debug = 0;

GetOptions(
	'debug+' => \$debug,
	'port=s' => \$port,
) || die $!;

warn "# port $port debug $debug\n";

my $parallel = Printer::EVOLIS::Parallel->new( $port );
$Printer::EVOLIS::Parallel::debug = $debug;
sub cmd { $parallel->command( "\e$_[0]\r" ) . "\n"; }

my $term = Term::ReadLine->new('EVOLIS');
my $OUT = $term->OUT || \*STDOUT;

#select($OUT); $|=1;



my @help;
{
	open(my $fh, '<', 'docs/commands.txt');
	@help = <$fh>;
	warn "# help for ", $#help + 1, " comands, grep with /search_string\n";
}

print $OUT "Printer model ", cmd('Rtp');
print $OUT "Printer s/no  ", cmd('Rsn');
print $OUT "Kit head no   ", cmd('Rkn');
print $OUT "Firmware      ", cmd('Rfv');
print $OUT "Mac address   ", cmd('Rmac');
print $OUT "IP address    ", cmd('Rip');

print $OUT "\nCounters:\n";
print $OUT "- printed panels: ",cmd('Rco;p');
print $OUT "- inserted cards: ",cmd('Rco;c');
print $OUT "- avg.clean freq: ",cmd('Rco;a');
print $OUT "- max.clean freq: ",cmd('Rco;m');
print $OUT "- clean number:   ",cmd('Rco;n');
print $OUT "- this ribbon:    ",cmd('Rco;l');
print $OUT "- $_ FIXME ",cmd("Rco;$_") foreach (qw/b e f i k r s/);

while ( defined ( $_ = $term->readline('command> ')) ) {
	chomp;

	if ( m{^/(.*)} ) {
		print $OUT $_ foreach grep { m{$1}i } @help;
		next;
	}

	my $send = "\e$_\r";

	my $response = $parallel->command( $send );

	$term->addhistory($_) if $response;

	print $OUT "<answer ",dump($response),"\n";

}

