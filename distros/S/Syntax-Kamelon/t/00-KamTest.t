package KamelonEmulator;

use strict;
use warnings;

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
	my $self = {
		DATA => ''
	};
   bless ($self, $class);
}

sub Format {
	my $self = shift;
	return $self->{DATA};
}

sub Parse {
	my $self = shift;
	$self->{DATA} = $self->{DATA} . shift;
}


package main;

use strict;
use warnings;
use lib 't/testlib';


use Test::More tests => 2;

BEGIN { use_ok('KamTest') };
use KamTest qw(InitWorkFolder PreText PostText TestParse WriteCleanUp);

my $kam = new KamelonEmulator;

my $workfolder = 't/KamTest';
InitWorkFolder($workfolder);
PreText("***");
PostText("***");

my $samplefile = 'samplefile.txt';
my $outfile = 'output.txt';
ok((TestParse($kam, $samplefile, $outfile) eq 1), 'Parsing');

WriteCleanUp;
