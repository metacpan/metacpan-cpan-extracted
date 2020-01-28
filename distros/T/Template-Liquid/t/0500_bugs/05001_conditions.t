use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template = Template::Liquid->parse(
                      '{%if phrase eq "Win"%}Yes!{%else%}Oh, no...{%endif%}');
is $template->render(phrase => 'Win'),  'Yes!',      'Win eq Win';
is $template->render(phrase => 'Nope'), 'Oh, no...', 'Nope eq Win';
#
$template = Template::Liquid->parse(
                      '{%if phrase ne "Win"%}Yes!{%else%}Oh, no...{%endif%}');
is $template->render(phrase => 'Win'),  'Oh, no...', 'Win ne Win';
is $template->render(phrase => 'Haha'), 'Yes!',      'Haha ne Win';
#
$template = Template::Liquid->parse(
                            '{%if number lt 5%}lower{%else%}higher{%endif%}');
is $template->render(number => 3),  'lower',  '3 lt 5';
is $template->render(number => 30), 'higher', '30 lt 5';
#
$template = Template::Liquid->parse(
                            '{%if number gt 5%}higher{%else%}lower{%endif%}');
is $template->render(number => 3),  'lower',  '3 gt 5';
is $template->render(number => 30), 'higher', '30 gt 5';
#
done_testing();
