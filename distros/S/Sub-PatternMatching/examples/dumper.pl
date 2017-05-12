use strict;
use warnings;
use Sub::PatternMatching;
use Params::Validate qw/:all/;

my $simple_dumper;
$simple_dumper = patternmatch(
  [{ type => HASHREF }] => 
    sub {
           "HASH {\n"
           . join(",\n", map {
                               "$_: "
                               . $simple_dumper->($_[0]{$_})
                         } keys %{$_[0]}
                 )
           . "\n}"
    },
  [{ type => ARRAYREF }] => 
    sub {
           "ARRAY [\n"
           . join(",\n",
                   map { $simple_dumper->($_) } @{$_[0]}
                 )
           . "\n]"
    },
  [{ type => SCALAR }] => sub {"SCALAR ($_[0])"},
);

print $simple_dumper->(
    # Your data structure here!
    [{foo => 'bar'}, 'a', [1..3]]
);


