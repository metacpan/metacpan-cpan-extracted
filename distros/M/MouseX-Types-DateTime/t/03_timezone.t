use Test::Base;
use t::App;

plan tests => 3*2;

for my $class (qw(Foo Bar)) {
    my $app = $class->new( timezone => 'Asia/Tokyo' );
    isa_ok $app => $class;
    isa_ok $app->timezone => 'DateTime::TimeZone';
    is $app->timezone->name => 'Asia/Tokyo';
}
