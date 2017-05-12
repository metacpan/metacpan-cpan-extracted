
use OS::Package::System;
use DateTime::Format::DateManip;
use Test::More;

use_ok('OS::Package::Plugin::Solaris::SVR4');
use_ok('OS::Package::Maintainer');
use_ok('OS::Package::Application');

my $author   = 'Test User';
my $nickname = 'tuser';
my $email    = 'tuser@testco.com';
my $phone    = '555-333-2222';
my $company  = 'Test Co.';

my $maintainer = OS::Package::Maintainer->new(
    author   => $author,
    nickname => $nickname,
    email    => $email,
    phone    => $phone,
    company  => $company
);

my $app = OS::Package::Application->new(
    name    => 'test package',
    version => '1.0.0'
);

my $cfg = {
    name        => 'testpackage',
    user        => 'root',
    group       => 'root',
    prefix      => '/opt/sf',
    category    => 'application',
    description => 'test application',
    maintainer  => $maintainer,
    application => $app
};

my $system = OS::Package::System->new;
my $pkg    = OS::Package::Plugin::Solaris::SVR4->new($cfg);

foreach my $key ( keys %{$cfg} ) {
    is( $pkg->$key, $cfg->{$key} );
}

isa_ok( $pkg, 'OS::Package' );

ok( DateTime::Format::DateManip->parse_datetime( $pkg->pstamp ),
    'pstamp is a valid date' );

can_ok( $pkg, 'create' );

my $package_file = sprintf( 'testpackage-1.0.0-%s-%s.pkg',
    $system->os, $system->type );

is( $pkg->pkgfile, $package_file,
    'package filename correctly generated without a build_id' );

$cfg->{build_id} = qw{12345};

my $pkg2 = OS::Package::Plugin::Solaris::SVR4->new($cfg);

my $package_file = sprintf( 'testpackage-1.0.0-b12345-%s-%s.pkg',
    $system->os, $system->type );

is( $pkg2->pkgfile, $package_file,
    'package filename correctly generated when a build_id is defined' );

done_testing;
