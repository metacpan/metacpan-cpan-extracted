use Test::More;
use OS::Package::Maintainer;

my $author = 'Test User';
my $nickname =  'tuser';
my $email = 'tuser@testco.com';
my $phone = '555-333-2222';
my $company = 'Test Co.';

my $maintainer = OS::Package::Maintainer->new(
    author     => $author,
    nickname => $nickname,
    email    => $email,
    phone    => $phone,
    company  => $company
);

isa_ok( $maintainer, 'OS::Package::Maintainer' );

is( $maintainer->author,     $author );
is( $maintainer->nickname, $nickname );
is( $maintainer->email,    $email );
is( $maintainer->phone,    $phone );
is( $maintainer->company,  $company );

done_testing;
