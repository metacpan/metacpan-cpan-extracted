#!perl -w
use strict;
use Test::More tests => 15;
use lib qw(t/lib);
use Siesta::Test 'init_db';
use Siesta::List;

my $DB    = join(' ', @Siesta::Config::STORAGE);
my $CF    = "t/config";
my @NACHO = ($^X, qw( -Iblib/lib -Iblib/arch bin/nacho -f ), $CF, '-d', $DB );

system @NACHO, qw( create-member jay@front-of.quick-stop );
is( $?, 0, "added jay" );

system @NACHO, qw( create-member bob@front-of.quick-stop );
is( $?, 0, "added Silent Bob" );

system @NACHO, qw( create-member dante@quick-stop );
is( $?, 0, "added Dante" );

system @NACHO, qw( create-member randal@rst-video );
is( $?, 0, "added Randal" );

is_deeply( [ sort map { $_->email } Siesta::Member->retrieve_all ],
           [ qw( bob@front-of.quick-stop
                 dante@quick-stop
                 jay@front-of.quick-stop
                 randal@rst-video
                ) ],
           "confirm with class::dbi" );

system @NACHO, qw( create-list dealers
                     jay@front-of.quick-stop
                     dealers@front-of.quick-stop
                     dealers-bounce@front-of.quick-stop );
is( $?, 0, "created dealers" );


system @NACHO, qw( set-plugins dealers post Archive Send );
is( $?, 0, "set plugins" );

system @NACHO, qw( add-member dealers
                     jay@front-of.quick-stop
                     bob@front-of.quick-stop );
is( $?, 0, "add bob and jay to dealers" );

my $list = Siesta::List->load( 'dealers' );
ok( $list, "c::dbi, load" );
is_deeply( [ sort map { $_->email } $list->members ],
           [ qw( bob@front-of.quick-stop
                 jay@front-of.quick-stop
                ) ] );
is_deeply( [ map { $_->name } $list->plugins ],
           [ qw( Archive Send ) ], "default set of plugins" );



system @NACHO, qw( remove-member dealers
                     jay@front-of.quick-stop );
is( $?, 0, "removed jay" );
is_deeply( [ sort map { $_->email } $list->members ],
           [ qw( bob@front-of.quick-stop
                ) ], "checked remove"  );


system @NACHO, qw( set-plugins dealers post SimpleSig MembersOnly Send );
is( $?, 0, "set the plugins" );

is_deeply( [ map { $_->name } $list->plugins ],
           [ qw( SimpleSig MembersOnly Send ) ], "specified set of plugins" );

