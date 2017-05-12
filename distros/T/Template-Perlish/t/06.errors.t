# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4; # last test to print

BEGIN {
   use_ok('Template::Perlish');
}

my $tt = Template::Perlish->new();
ok($tt, 'object created');

{
   my $template = <<'END_OF_TEMPLATE';
Dear [% name %],

   we are pleased to present you the following items:
[%
   my $items = $variables{items};
   for my $item (@$items) {%]
   * [% print $item;
   }
<========== unclosed section here

Please consult our complete catalog at [% uris.2.catalog %].

Yours,

   [% director.name %] [% director.surname %].
END_OF_TEMPLATE

   eval { $tt->compile_as_sub($template) };
   like($@, qr{unclosed}, 'unclosed section spotted');
}

{
   my $template = <<'END_OF_TEMPLATE';
Dear [% name %],
[%
   my $whatever "ciao"; # missing an equal sign here?
%]

END_OF_TEMPLATE

   eval { $tt->compile_as_sub($template) };
   like($@, qr{syntax\ error}, 'syntax error spotted');
}


done_testing();
