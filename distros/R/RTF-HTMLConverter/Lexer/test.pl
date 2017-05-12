use strict;
use Test::More tests => 2;
use RTF::Lexer;

open my $fh, "< test.rtf" or die "Can't open test.rtf: $!!\n";
my $count = 0;
my $parser = RTF::Lexer->new(in => $fh);
ok(ref($parser));
my $token;
do {
  $token = $parser->get_token();
} until $parser->is_stop_token($token) || $count++ > 10000;
close $fh;
is($count, 1114);

