use lib '.';
use t::Helper;

my $cwd = t::Helper->cwd;
my $t   = t::Helper->t(args => '');
my $c   = $t->app->build_controller;

test_tag('foo.js', 'script', src => '/asset/foo.123.js');
test_tag('foo.css', 'link', href => '/asset/foo.456.css', rel => 'stylesheet');

eval { $c->asset('bar.js') };
like $@, qr{Unknown asset name "bar\.js"}, 'asset bar.js';

done_testing;

sub test_tag {
  my ($asset_name, $tag_name, %attrs) = @_;
  my $bs = $c->asset($asset_name);
  ok $bs->isa('Mojo::ByteStream'), "got Mojo::ByteStream for $asset_name";
  my $dom = Mojo::DOM->new($bs)->at('link, script');
  is $dom->tag, $tag_name, "got tag $tag_name for $asset_name";
  is $dom->{$_}, $attrs{$_}, "got attr $_ for $asset_name" for keys %attrs;
}
