use Test::More;

use Spica::Parser::XML;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<attr>
    <id>1</id>
    <name>perl</name>
</attr>
};

my $parser = Spica::Parser::XML->new();
my $data = $parser->parse($xml);
isa_ok $data => 'HASH';

is $data->{id} => 1;
is $data->{name} => 'perl';

done_testing;
