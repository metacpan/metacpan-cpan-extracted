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
  html => '<p>My name is Dave</p>',
  text => 'My name is Dave',
};

my $tests = [{
  name => 'default',
  params => {},
  expected => {
    md => 'html',
    tt => 'text',
  }
}, {
  name => 'all',
  params => { EXTENSIONS => { '*' => 'markdown' } },
  expected => {
    md => 'html',
    tt => 'html',
  }
}, {
  name => 'tt',
  params => { EXTENSIONS => { tt => 'markdown', md => undef } },
  expected => {
    md => 'text',
    tt => 'html',
  }
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

  for (qw[md tt]) {
    is(process_template($tt, "basic.$_", $vars),
     $results->{$test->{expected}{$_}},
     "'$test->{name}' test using basic.$_ should return $test->{expected}{$_}");
  }
}

done_testing();

sub process_template {
  my ($tt, $template, $vars) = @_;

  my $out;
  $tt->process($template, $vars, \$out);
  return $out;
}
