#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Shebangml;

my @data = (
  just_id =>   ['=id'], [id => id => 'id="id"'],
  just_name => [':name'], [name => name => 'name="name"'],
  id_name   => ['=i :n'], [id => i => name => n => 'id="i" name="n"'],
  name_id   => [':n =i'], [name => n => id => i => 'name="n" id="i"'],
  name_id2  => [':n', '=i'],
    [name => n => id => i => 'name="n" id="i"'],
  spaces    => ['a="1 2"'], [a => '1 2' => 'a="1 2"'],
  spaces2   => ['a="1 2" b="3 4"'],
    [a => '1 2' => b => '3 4' => 'a="1 2" b="3 4"'],
  spaces2   => [qq(a="1 2"\n b="3 4")],
    [a => '1 2' => b => '3 4' => qq(a="1 2" b="3 4")],
  name_id   => [qq(\n:n\n   =i)],
    [name => n => id => i => qq(name="n" id="i")],
  bareword  => ['a=foo/bar.baz::stuff32'],
    [a => 'foo/bar.baz::stuff32' => 'a="foo/bar.baz::stuff32"'],
  TODO => 'quote escaping',
    quote_string => ['this="thing \"with quotes\""'],
      ['this="thing %20with quotes%20"'], # TODO read xml spec
);

{
my $n = -1;
sub get () {$data[++$n]};
}

while(my $name = get) {
  ((my $todo), $name) = (get, get) if($name eq 'TODO');
  my ($in, $exp) = (get, get);
  local $TODO = $todo if($todo);
  my $string = pop(@$exp);
  my $atts = Shebangml->atts(@$in);
  is($atts->as_string, ' ' . $string, "$name as_string");
  is_deeply([$atts->atts], $exp, $name);
}

# vim:ts=2:sw=2:et:sta
