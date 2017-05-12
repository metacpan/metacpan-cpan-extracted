use strict;

use Perlipse::SourceParser;

my $source = '';
while (<STDIN>)
{
    $source .= $_;
}

my $parser = Perlipse::SourceParser->new;
my $ast = $parser->parse(source => $source);

$ast->toXml;
