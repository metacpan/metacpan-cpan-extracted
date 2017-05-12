# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 7; # last test to print

BEGIN {
   use_ok('Template::Perlish', 'render');
}

{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.

Not even a variable.
END_OF_TEMPLATE
   my $processed = render($template);
   is($processed, $template, 'simple template');
}
{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.

Not even a variable.
END_OF_TEMPLATE
   my $processed = render($template);
   is($processed, $template, 'simple template, again');
}
{
   my $template = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
[% 
   print "ciao";
%]
At least a block
END_OF_TEMPLATE
   my $result = <<END_OF_TEMPLATE;
This is a simple template with nothing really interesting.
ciao
At least a block
END_OF_TEMPLATE
   my $processed = render($template);
   is($processed, $result, 'simple template with a block');
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
   my $processed = render($template, {ciao => 'a tutti'});
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
   my $processed = render($template,);
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
   my $processed = render($template,);
   is($processed, $result, 'simple template with a Perl expression');
}
