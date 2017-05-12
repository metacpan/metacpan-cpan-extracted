use strictures 1;
use Test::More;
use Mojito::Page;

my $pager = Mojito::Page->new( page => '<section>Full of Love</section>', base_url => '/note/' );
isa_ok($pager, 'Mojito::Page');
my $page_struct = $pager->page_structure;
is(ref($page_struct), 'HASH', 'page struct is a HashRef');
isa_ok($pager->render, 'Mojito::Page::Render');
is($pager->render->base_url, '/note/', 'base_url in render object delegate');

done_testing();
