use strict;
use warnings;
use Test::More;
use FindBin;
use Plift;


my $plift = Plift->new( paths => ["$FindBin::Bin/templates"] );

my $tpl = $plift->template('remove');

$tpl->set({
    is_authenticated => 1,
});

my $doc = $tpl->render;

is $doc->find('li')->size, 1;
is $doc->find('li')->as_html, '<li>Username</li>';
is $doc->find('[data-remove-if]')->size, 0;
is $doc->find('[data-remove-unless]')->size, 0;


done_testing;
