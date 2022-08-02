use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template
    = Template::Liquid->parse(
         'Given input is {% if input %}Non-zero value{% else %}0{% endif %}');
#
is $template->render(input => 0), 'Given input is 0', 'input => 0';
is $template->render(input => 1), 'Given input is Non-zero value',
    'input => 1';
is $template->render(input => 2), 'Given input is Non-zero value',
    'input => 2';
#
done_testing();
