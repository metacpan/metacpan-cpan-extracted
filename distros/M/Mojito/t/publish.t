use strictures 1;
use Test::More;
use WWW::Mechanize;
use Mojito::Page::Publish;
use Mojito;
use 5.010;
use utf8;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

my $pub = Mojito::Page::Publish->new(
    target_page => 'hunter/mi-test',
    content     => 'Visca el Barça'
);
ok( $pub->publish, 'Publish' );
my $mojito = Mojito->new;
my $params = {
    id              => '4db1d6dd82f1c8e636000000',
    target_base_url => 'http://suryahunter.com/wiki/',
    name            => 'hunter/test-post',
    user            => $pub->user,
    password        => $pub->password,

};
my $result = $mojito->publish_page($params);
is($result->{redirect_url}, 'http://suryahunter.com/wiki/hunter/test-post', 'Redirect URL');

done_testing();
