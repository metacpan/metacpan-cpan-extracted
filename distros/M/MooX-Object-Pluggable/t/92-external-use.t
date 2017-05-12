use Modern::Perl;
use lib "t/lib";
use Test::More;
use MyPackage -load_plugins => ['Hello'];

my $obj = MyPackage->new;
can_ok($obj, "load_plugins");
can_ok($obj, 'hello');
done_testing;
