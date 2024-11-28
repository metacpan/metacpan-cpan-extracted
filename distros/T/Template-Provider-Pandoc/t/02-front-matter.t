use strict;
use warnings;
use Template;
use Template::Provider::Pandoc;
use FindBin '$Bin';

use Test::More;

# Easy way to bail out if the pandoc executable isn't installed
use Pandoc;
plan skip_all => "pandoc isn't installed; this module won't work"
  unless pandoc;

my $results = {
  strip    => 'My name is Dave',
  no_strip => "---\nfront_matter: 1\n---\nMy name is Dave",
};

my $tests = [{
  name => 'strip',
  params => { STRIP_FRONT_MATTER => 1 },
}, {
  name => 'no_strip',
  params => { STRIP_FRONT_MATTER => 0 },
}];

foreach my $test (@$tests) {
  my $provider = Template::Provider::Pandoc->new(
    INCLUDE_PATH => "$Bin/templates",
    %{ $test->{params} },
  );
  my $tt = Template->new(
    LOAD_TEMPLATES => $provider,
  );

  my $vars = { author => 'Dave' };

  is(process_template($tt, 'front-matter.txt', $vars),
   $results->{$test->{name}},
   "'$test->{name}' test using front-matter.md should return $test->{name}");
}

done_testing();

sub process_template {
  my ($tt, $template, $vars) = @_;

  my $out;
  $tt->process($template, $vars, \$out);
  return $out;
}
