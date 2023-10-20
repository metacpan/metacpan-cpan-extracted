use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template
    = Template::Liquid->parse('{%if 10 < 10%}less{%else%}gte{%endif%}');
is $template->render(), 'gte';
$template
    = Template::Liquid->parse('{%if balance < 10%}less{%else%}gte{%endif%}');
is $template->render(balance => 10), 'gte';
is $template->render(balance => 0),  'less';
is $template->render(balance => 11), 'gte';
#
done_testing();
