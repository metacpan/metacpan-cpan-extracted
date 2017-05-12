use strict;

use PPI::Dumper;
use PPI::Document;

my $source = '';
while (<STDIN>)
{
    $source .= $_;
}

my $pdom   = PPI::Document->new(\$source);
my $dumper = PPI::Dumper->new($pdom, 
    locations  => 1,
    whitespace => 0,
);

$dumper->print;
