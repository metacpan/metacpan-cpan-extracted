#!/usr/bin/env perl
use strict;
use warnings;
use Template;
use Template::Provider::Markdown::Pandoc;
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
  params => { EXTENSION => undef },
  expected => {
    md => 'html',
    tt => 'html',
  }
}, {
  name => 'tt',
  params => { EXTENSION => 'tt' },
  expected => {
    md => 'text',
    tt => 'html',
  }
}];

foreach my $test (@$tests) {
  my $provider = Template::Provider::Markdown::Pandoc->new(
    INCLUDE_PATH => "$Bin/../t/templates",
    %{ $test->{params} },
  );
  my $tt = Template->new(
    LOAD_TEMPLATES => $provider,
  );

  my $vars = { author => 'Dave' };
  is(process_template($tt, 'basic.md',$vars),
     $results->{$test->{expected}{md}},
     "'$test->{name}' test using basic.md should return $test->{expected}{md}");
  is(process_template($tt, 'basic.tt', $vars),
     $results->{$test->{expected}{tt}},
     "'$test->{name}' test using basic.tt should return $test->{expected}{tt}");
}

done_testing();

sub process_template {
  my ($tt, $template, $vars) = @_;

  my $out;
  $tt->process($template, $vars, \$out);
  return $out;
}
