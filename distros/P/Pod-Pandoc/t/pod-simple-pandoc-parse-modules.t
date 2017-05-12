use strict;
use Test::More;
use Pod::Simple::Pandoc;
use Test::Output;

my $modules;

stderr_is {
    $modules = Pod::Simple::Pandoc->parse_modules('t/examples');
} "t/examples/Foo.pm NAME does not match module\n".
  "t/examples/Pandoc skipped for t/examples/Pandoc.pod\n",
  "parse_modules";

is_deeply [ keys %$modules ], ['Pandoc'], 'module name from file';

done_testing;
