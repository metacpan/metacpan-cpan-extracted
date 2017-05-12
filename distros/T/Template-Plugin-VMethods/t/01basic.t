#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec::Functions;
use lib catdir($FindBin::Bin, "mylib");
use Test::More tests => 12;

############
# really basic

# does the installation work?
is tt('[% USE ReverseVMethod; foo = "foo"; foo.reverse %]'),
  "oof",
  "installed";

# did we remember the old value
like tt('[% foo = "foo"; foo.reverse %]'),
  '/ARRAY/',
  "restored";

############
# with an existing value

# this done to shut up the 'used only once' warning;
if ($Template::Stash::SCALAR_OPS) {}
$Template::Stash::SCALAR_OPS->{reverse} = sub { 'reverse this!' };

# does the installation work?
is tt('[% USE ReverseVMethod; foo = "foo"; foo.reverse %]'), 
  "oof",
  "installed w/existing";

# did we remember the old value
is tt('[% foo = "foo"; foo.reverse %]'),
  "reverse this!",
  "restored w/existing";

############
# with subroutines

is tt('[% USE DoubleVMethod; foo = "foo"; foo.double %]'),
  "foofoo",
  "subroutine version 1/2";

is tt('[% USE DoubleVMethod; foo = ["foo", "bar"];
       foo.double.0; "+";
       foo.double.1; "+";
       foo.double.2; "+";
       foo.double.3;
%]'),
  "foo+bar+foo+bar",
  "subroutine version 2/2";

############
# what happens if we use it twice?

# does the installation work?
is tt(q{[% USE ReverseVMethod;
           USE ReverseVMethod;
           foo = "foo"; 
           foo.reverse %]}),
  "oof",
  "twice installed";

# did we remember the old value
is tt('[% foo = "foo"; foo.reverse %]'),
  "reverse this!",
  "twice restored";

############
# nicely degraded

is tt(q{[% USE ReverseVMethod;
               foo = "foo";
               foo.reverse;
               INCLUDE thingy;
               foo.reverse %]}),
      "oofoofFOOoof",
      'works with includes okay';

###########
# install forever

eval q{use Template::Plugin::ReverseVMethod 'install';

is tt('[% foo = "foo"; foo.reverse %]'),
  "oof",
  "always installed";

};

###########
# in another class

is tt(q{[% USE GoSplat;
               foo = "foo";
               GoSplat.gosplat(foo); %]}),
      "fsplatosplato",
      'other class stuff';

is tt(q{[% USE GoSplatVMethod;
               foo = "foo";
               foo.gosplat; %]}),
      "fsplatosplato",
      'other class stuff pt 2';


##################################################################

sub tt
{
  my $string = shift;
  use Template;
  my $tt = Template->new(INCLUDE_PATH => catdir($FindBin::Bin,"include"));
  my $output;
  $tt->process(\$string, {}, \$output)
    or die "Problem with tt: " . $tt->error;
  return $output;
}
