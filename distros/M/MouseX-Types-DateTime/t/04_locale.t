use Test::Base;
use t::App;

plan tests => 4*2;

for my $class (qw(Foo Bar)) {
    my $app = $class->new( locale => 'ja_JP' );
    isa_ok $app => $class;
    isa_ok $app->locale => 'DateTime::Locale::ja_JP';
    is $app->locale->id => 'ja_JP';
    is $app->locale->language_id => 'ja';
}
