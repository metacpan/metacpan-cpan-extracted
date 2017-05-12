# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 6; # last test to print

BEGIN {
   use_ok('Template::Perlish');
}

my $tt = Template::Perlish->new();
ok($tt, 'object created');

my $template = <<'END_OF_TEMPLATE';
Dear [% name %],

   we are pleased to present you the following items:
[%
   my $items = $variables{items};
   for my $item (@$items) {%]
   * [% print $item;
   }
%]

Please consult our complete catalog at [% uris.2.catalog %].

Yours,

   [% director.name %] [% director.surname %].
END_OF_TEMPLATE
my $compiled_sub = $tt->compile_as_sub($template);
isa_ok($compiled_sub, 'CODE');

{
   my $result = <<END_OF_TEMPLATE;
Dear Ciccio Riccio,

   we are pleased to present you the following items:

   * ciao
   * a
   * tutti
   * quanti

Please consult our complete catalog at http://whateeeeever/.

Yours,

    Poletti.
END_OF_TEMPLATE
   my $processed = $compiled_sub->({
      name => 'Ciccio Riccio',
      items => [ qw( ciao a tutti quanti ) ],
      uris => [
         'http://whatever/',
         undef,
         {
            catalog => 'http://whateeeeever/',
         }
      ],
      director => { surname => 'Poletti' },
   });
   is($processed, $result, 'simple template with a block');
}

{ 
   my $result = <<END_OF_TEMPLATE;
Dear ,

   we are pleased to present you the following items:

   * ciao
   * a
   * tutti
   * quanti

Please consult our complete catalog at http://whateeeeever/.

Yours,

    Poletti.
END_OF_TEMPLATE
   my $processed = $compiled_sub->({
      name => '',
      items => [ qw( ciao a tutti quanti ) ],
      uris => [
         'http://whatever/',
         undef,
         {
            catalog => 'http://whateeeeever/',
         }
      ],
      director => { surname => 'Poletti' },
   });
   is($processed, $result, 'simple template with a block');
}

$tt->{variables}{name} = 'Topo Anonimo';
{ 
   my $result = <<END_OF_TEMPLATE;
Dear Topo Anonimo,

   we are pleased to present you the following items:

   * ciao
   * a
   * tutti
   * quanti

Please consult our complete catalog at http://whateeeeever/.

Yours,

    Poletti.
END_OF_TEMPLATE
   my $processed = $compiled_sub->({
      items => [ qw( ciao a tutti quanti ) ],
      uris => [
         'http://whatever/',
         undef,
         {
            catalog => 'http://whateeeeever/',
         }
      ],
      director => { surname => 'Poletti' },
   });
   is($processed, $result, 'simple template with a block');
}
