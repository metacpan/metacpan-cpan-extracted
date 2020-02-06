use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template
    = Template::Liquid->parse(
    '{% case condition %}{% when 0 %}hit 0{% when 1 %}hit 1{% when 2 or 3 %}hit 2 or 3{% else %}none{% endcase %}'
    );
#
is $template->render(condition => 0), 'hit 0',      'condition => 0';
is $template->render(condition => 2), 'hit 2 or 3', 'condition => 2';
is $template->render(condition => 3), 'hit 2 or 3', 'condition => 3';
is $template->render(condition => 4), 'none',       'condition => 4';
#
done_testing();
