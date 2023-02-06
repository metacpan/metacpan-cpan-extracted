# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # tests => 3; # last test to print
use Template::Perlish 'render';

{
   my $template = <<END_OF_TEMPLATE;

variable<[% foo %]>
missing<[% galook %]>
function<[%= baz() %]>
function2<[%= galook(7) %]>
missing-function<[%= eval { missing() } or 'missing!' %]>

END_OF_TEMPLATE
   my $processed = render(
      $template,
      {foo => 'bar'},    # variables
      {                  # options
         functions => {
            baz    => sub { return 42 },
            galook => sub { "Hello-$_[0]!" },
         },
      },
   );
   is(Template::Perlish->can('baz'),
      undef, 'no function baz defined (prior to call to template)');
   like($processed, qr{(?mxs: variable<bar> )}, 'variable');
   like($processed, qr{(?mxs: missing<> )},     'missing variable');
   like($processed, qr{(?mxs: function<42> )},  'function call');
   like(
      $processed,
      qr{(?mxs: function2<Hello-7!> )},
      'other function call'
   );
   like(
      $processed,
      qr{(?mxs: missing-function<missing!> )},
      'call to missing function'
   );
   is(Template::Perlish->can('baz'),
      undef, 'no function baz defined (post to call to template)');
}

done_testing();
