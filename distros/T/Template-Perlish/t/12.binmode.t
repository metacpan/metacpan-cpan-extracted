# vim: filetype=perl :
use strict;
use warnings;

use Test::More;

BEGIN {
   use_ok('Template::Perlish');
}

{
   my $tt = Template::Perlish->new;
   my $template = '« whatever »';
   my $expanded = $tt->process($template);
   is $expanded, "\x{ab} whatever \x{bb}",
      'expansion mangles template with auto-utf8';
}

{
   my $tt = Template::Perlish->new(utf8 => 0);
   my $template = '« whatever »';
   my $expanded = $tt->process($template);
   is $expanded, $template,
      'expansion keeps template without auto-utf8';
}

{
   my $tt = Template::Perlish->new(binmode => ':raw');
   my $template = '« whatever »';
   my $expanded = $tt->process($template);
   is $expanded, $template,
      'expansion keeps template with raw binmode';
}

done_testing();
