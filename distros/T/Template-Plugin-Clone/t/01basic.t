#!/usr/bin/perl

use strict;

use Test::More tests => 3;

is tt(q{[% foo = "fred";
           bar = Clone.clone(foo);
           bar %]}),
   'fred', 'scalar';

is tt(q{[% foo = [ 1, 2, 3, 4];
           bar = Clone.clone(foo);
           foo.2 = 'wrong';
           bar.2 %]}),
   '3', 'list';

is tt(q{[% foo = { fred => 'wilma', barney => 'betty' };
           bar = Clone.clone(foo);
           foo.fred = 'judy';  # george is going to be annoyed
           bar.fred %]}),
   'wilma', 'hash';

##########################################################################

use File::Spec::Functions;

sub tt
{
  my $string = shift;
  use Template;
  $string = '[% USE Clone %]' . $string;
  my $tt = Template->new(INCLUDE_PATH => catdir($FindBin::Bin,"include"));
  my $output;
  $tt->process(\$string, {}, \$output)
    or die "Problem with tt: " . $tt->error;
  return $output;
}
