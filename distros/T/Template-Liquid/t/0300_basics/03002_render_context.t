use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template = Template::Liquid->parse('{{foo}}');
$template->{context}
    = Template::Liquid::Context->new(assigns => {foo => 'bar'});
is $template->render(), 'bar', 'We can set up a pre-existing context';
is $template->render(foo => 'override'), 'override',
    '... and directly passed arguments override that';
is $template->render(), 'bar', "... and we don't overwrite stuff permanently";
$template = Template::Liquid->parse('{{foo}}');
is $template->render(foo => 'without context'), 'without context',
    '... and not having a context still works as expected';
done_testing();
