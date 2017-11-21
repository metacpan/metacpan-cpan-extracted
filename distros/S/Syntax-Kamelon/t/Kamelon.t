use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 5;
BEGIN { use_ok('Syntax::Kamelon') };

my $folder = './t';
my $index = "$folder/indexrc";
unlink $index;

my $yashe = Syntax::Kamelon->new(
	xmlfolder => $folder,
	indexfile => $index,
);
ok(defined $yashe, 'Can create Kamelon');

ok($yashe->{INDEXER}->{INDEX}->{'Test'}->{'file'} eq 'test.xml', "Indexing\n");

$yashe->Reset;

$yashe->Syntax('Test');
ok($yashe->Syntax eq 'Test', 'Set a language');

my $thl = $yashe->GetLexer('Test');
ok(defined $thl, 'Create a highlighter');
# use Data::Dumper;
# print Dumper $thl;


unlink $index;


