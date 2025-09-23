use Test::More;

use lib 't/lib';

use Object;

my $obj = Object->new({
  title => 'title',
  type => 'object',
  desc => 'description of the object',
  url => 'https://example.com/object/',
  image => 'https://example.com/object.png',
});

ok $obj;

my @tests = ({
  method => 'title_tag',
  tag    => 'title',
  attrs  => [],
  text   => 'title',
}, {
  method => 'canonical_tag',
  tag    => 'link',
  attrs  => [qw(
    rel="canonical"
    href="https://example.com/object/"
  )],
}, {
  method => 'og_title_tag',
  tag    => 'meta',
  attrs  => [qw(
    property="og:title"
    content="title"
  )],
}, {
  method => 'og_type_tag',
  tag    => 'meta',
  attrs  => [qw(
    property="og:type"
    content="object"
  )],
}, {
  method => 'twitter_card_tag',
  tag    => 'meta',
  attrs  => [qw( 
    name="twitter:card"
    content="summary_large_image"
  )],
}, {
  method => 'twitter_title_tag',
  tag    => 'meta',
  attrs  => [qw(
    name="twitter:title"
    content="title"
  )],
});

for (@tests) {
  next unless $_->{tag};
  my $method = $_->{method};
  my $html   = $obj->$method;

  like $html, qr[^<$_->{tag}], "Tag <$_->{tag}> is correct";
  if (exists $_->{text} and $_->{text}) {
    like $html, qr[>$_->{text}<], qq[Text "$_->{text}" is correct];
  }
  for my $attr (@{ $_->{attrs} }) {
    like $html, qr[$attr], qq[Attribute '$attr' is correct];
  }
}

diag $obj->tags;

done_testing;
