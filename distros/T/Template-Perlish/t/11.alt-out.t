# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 15; # last test to print

BEGIN {
   use_ok('Template::Perlish');
}

my $tt = Template::Perlish->new(stdout => 0);
ok($tt, 'object created');
can_ok($tt, qw( process compile compile_as_sub ),);
is($tt->{start}, '[%', 'block starter default');
is($tt->{stop},  '%]', 'stop default');

{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.

Not even a variable.
END_OF_TEMPLATE
   my $processed = $tt->process($template);
   is($processed, $template, 'simple template');
}
{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.

Not even a variable.
END_OF_TEMPLATE
   my $processed = $tt->process($template);
   is($processed, $template, 'simple template, again');
}
{
   local *STDOUT;
   my $buffer = '';
   open STDOUT, '>', \$buffer or die "open(): $!";
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
[% 
   print "ciao";
%]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.

At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template);
   is($processed, $result, 'simple template with a block')
      or diag("\n\n" . $tt->compile($template)->{code_text});

   close STDOUT;
   is($buffer, 'ciao', 'some text went out to real STDOUT');
}
{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
[% ciao %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
a tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template, {ciao => 'a tutti'});
   is($processed, $result, 'simple template with a variable');
}
{
   my $template = <<'END_OF_TEMPLATE';
[% my $ciao = "a tutti"; %]This is a simple template with nothing really interesting.
[%= $ciao %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
a tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template,);
   is($processed, $result, 'simple template with a Perl scalar variable');
}
{
   my $template = <<'END_OF_TEMPLATE';
This is a simple template with nothing really interesting.
[%= my @ciao = 'tutti'; "a $ciao[0]"; %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
a tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template,);
   is($processed, $result, 'simple template with a Perl expression');
}
{
   my $template = <<'END_OF_TEMPLATE';
This is a simple template with nothing really interesting.
[% ciao.'some thing.for\ "$you'."al\"o\\ha" %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
a tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template, {
         ciao => {
            'some thing.for\ "$you' => {
               'al"o\ha' => 'a tutti'
            }
         }
   });
   is($processed, $result, 'simple template with a complex variable');
}
{
   my $template = <<'END_OF_TEMPLATE';
This is a simple template with nothing really interesting.
[%= V 'ciao.a.tutti'; %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
a tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template, {
         ciao => {
            'a' => {
               'tutti' => 'a tutti'
            }
         }
   });
   is($processed, $result, 'simple template with a complex variable via V');
}
{
   my $template = <<'END_OF_TEMPLATE';
This is a simple template with nothing really interesting.
[%= join '-', A 'ciao.a.tutti'; %]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
ciao-a-tutti
At least a block
END_OF_TEMPLATE
   my $processed = $tt->process($template, {
         ciao => {
            'a' => {
               'tutti' => [qw< ciao a tutti >],
            }
         }
   });
   is($processed, $result, 'simple template with a complex variable via A');
}

done_testing();
