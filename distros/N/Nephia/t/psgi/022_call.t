use strict;
use Test::More;
use Test::WWW::Mechanize::PSGI;

{
    package 
        Oreore;
    use Nephia;
    my $code = Nephia->call('C::Root#foo');
    app {
        $code->(@_);
    };
};

{
    package
        Oreore::C::Root;
    sub foo {
        my $c = shift;
        my $id = $c->param('id');
        [200, [], ["id = $id"]];
    }
};

my $mech = Test::WWW::Mechanize::PSGI->new(app => Oreore->run);

$mech->get_ok('/?id=224');
# $mech->content_is( 'id = 224' );

ok 1;

done_testing;
