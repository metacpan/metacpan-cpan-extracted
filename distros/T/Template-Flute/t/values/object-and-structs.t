#!perl

package My::Object;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub method {
    return "Hello from the method";
}

package main;

use strict;
use warnings;
use Test::More tests => 1;
use Template::Flute;

my $spec =<<'SPEC';
<specification>
 <value name="object" field="myobject.method" />
 <value name="struct" field="mystruct.key" />
</specification>
SPEC
  
my $html =<<'EOF';
<html>
  <body>
    <span class="object">Welcome back!</span>
    <span class="struct">Another one</span>
  </body>
</html>
EOF


my $flute = Template::Flute->new(
    specification => $spec,
    template => $html,
    values => {
        myobject => My::Object->new,
        mystruct => { key => "Hello from hash" }
       }
   );

my $out = $flute->process;

is $out, '<html><head></head><body>' .
  '<span class="object">Hello from the method</span>' .
  '<span class="struct">Hello from hash</span></body></html>';
