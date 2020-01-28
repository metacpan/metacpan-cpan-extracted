use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template = Template::Liquid->parse('{{community.magnatude.catchphrase}}');
is $template->render(community => Glendale->new()), 'Pop, pop!', 'getter';
done_testing();

package Glendale;

sub new {
    bless {students => [Magnatude->new({catchphrase => 'Pop, pop!'})]}, pop;
}
sub magnatude { shift->{students}[0] }

package Magnatude;
sub new         { bless pop, pop }
sub catchphrase { shift->{catchphrase} }
