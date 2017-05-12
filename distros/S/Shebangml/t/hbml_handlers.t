#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Shebangml;

{
  package Shebangml::Handler::baz;
  sub foo ($$) {'foo'};
  sub foot ($$) {'foot'};
  sub idname ($$) {
    my $self = shift;
    my ($atts) = @_;
    return($atts->get('id') . '#' . $atts->get('name'));
  }
  sub quote ($$) {
    my $self = shift;
    my ($atts, $str) = @_;
    my $q = $atts->get('quote');
    return($q . $str . $q);
  }
  sub whatever (;$$) {
    my $self = shift;
    return('</x>') unless(@_);
    my ($atts, $str) = @_;
    return('<x' . ($atts ? $atts->as_string : '') .
      (@_ == 2 ? (defined($str) ? '>'.$str.'</x>' : ' />') : '>')
    )
  }
}

my $string = '';
open(my $fh, '>', \$string) or die;
my $hbml = Shebangml->new(out_fh => $fh);
sub parse ($) {
  my ($in) = @_;
  $string = ''; open($fh, '>', \$string) or die;
  $hbml->process(\$in);
  return($string);
}

$hbml->add_handler('baz');

is parse '.x.baz.foo[]',
         'foo';

is parse '.x.baz.foot[]',
         'foot';

is parse '.x.baz.idname[=1 :2]',
         '1#2';

is parse '.x.baz.idname[@x =n :q]',
         'n#q';

is parse '.x.baz.quote[quote=YYY]{{{ blah bah blah }}}',
         'YYY blah bah blah YYY';

is parse '.x.baz.whatever{blah bah blah}',
         '<x>blah bah blah</x>';

is parse '.x.baz.whatever[foo=bar]{blah bah blah}',
         '<x foo="bar">blah bah blah</x>';

is parse '.x.baz.whatever[foo=bar]',
         '<x foo="bar" />';

is parse '.x.baz.whatever[]',
         '<x />';

is parse '.x.baz.whatever{}',
         '<x></x>';

is parse '.x.baz.whatever{{{}}}',
         '<x></x>';

is parse '.x.baz.whatever{{{qqq}}}',
         '<x>qqq</x>';

# vim:ts=2:sw=2:et:sta
