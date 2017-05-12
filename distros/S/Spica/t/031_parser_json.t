use Test::More;

use Spica::Parser::JSON;

my $json= q|{"id": 1, "name": "perl"}|;

my $parser = Spica::Parser::JSON->new();
my $data = $parser->parse($json);
isa_ok $data => 'HASH';

isa_ok $data => 'HASH';
is $data->{id} => 1;
is $data->{name} => 'perl';

done_testing;
