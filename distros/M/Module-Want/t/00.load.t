use Test::More tests => 64;
use Test::Carp;

# for search_inc_paths() tests
use File::Temp;
use File::Spec;
use File::Path::Tiny;

BEGIN {
    use_ok('Module::Want');
}

diag("Testing Module::Want $Module::Want::VERSION");

ok( defined &have_mod, 'imports have_mod() ok' );

is( ref( Module::Want::get_ns_regexp() ), 'Regexp', 'get_ns_regexp() returns a regexp' );

ok( have_mod('Module::Want'), 'true on already loaded module' );
ok( have_mod('Module::Want'), 'true on already loaded module' );

ok( !have_mod('lkadjnvlkand::lvknadkjcnakjdnvjka'), 'false on unloadable module' );
ok( !have_mod('lkadjnvlkand::lvknadkjcnakjdnvjka'), 'false on unloadable module' );

does_carp_that_matches(
    sub { ok( !have_mod('1invalid::ns'), 'false on invalid NS' ) },
    qr/Invalid Namespace/,
);

for my $ns (qw( _what Acme Acme::XYZ Acme::ABC::DEF::X::Y::Z Acme::XYZ Acme'ABC::DEF::X::Y::Z Acme::ABC::DEF::X::Y'Z Acme::ABC::DEF'X::Y::Z Acme'ABC'DEF'X'Y'Z )) {
    ok( Module::Want::is_ns($ns), "$ns is an NS" );
}

ok( !Module::Want::is_ns('1Acme'), "staring number is not an NS" );
ok( !Module::Want::is_ns(' Acme'), "space is not an NS" );

ok( Module::Want::get_clean_ns(" \n  You::Can't \n") eq 'You::Can::t', 'get_clean_ns()' );

ok( Module::Want::get_inc_key('_what')                   eq '_what.pm',              'single level' );
ok( Module::Want::get_inc_key('Acme')                    eq 'Acme.pm',               'single level' );
ok( Module::Want::get_inc_key('Acme::XYZ')               eq 'Acme/XYZ.pm',           'two level' );
ok( Module::Want::get_inc_key('Acme::ABC::DEF::X::Y::Z') eq 'Acme/ABC/DEF/X/Y/Z.pm', 'multi level' );
ok( Module::Want::get_inc_key('Acme::XYZ')               eq 'Acme/XYZ.pm',           'two level apaost' );
ok( Module::Want::get_inc_key('Acme\'ABC::DEF::X::Y::Z') eq 'Acme/ABC/DEF/X/Y/Z.pm', 'multi level apost first' );
ok( Module::Want::get_inc_key('Acme::ABC::DEF::X::Y\'Z') eq 'Acme/ABC/DEF/X/Y/Z.pm', 'multi level apost last' );
ok( Module::Want::get_inc_key('Acme::ABC::DEF\'X::Y::Z') eq 'Acme/ABC/DEF/X/Y/Z.pm', 'multi level apost middle' );
ok( Module::Want::get_inc_key('Acme\'ABC\'DEF\'X\'Y\'Z') eq 'Acme/ABC/DEF/X/Y/Z.pm', 'multi level apost all' );

Module::Want->import( 'get_inc_key', 'is_ns' );
ok( defined &get_inc_key, 'can import get_inc_key() ok' );
ok( defined &is_ns,       'can import is_ns() ok' );

Module::Want->import( 'get_relative_path_of_ns', 'normalize_ns' );
ok( defined &get_relative_path_of_ns, 'can import get_relative_path_of_ns() ok' );
ok( defined &normalize_ns,            'can import normalize_ns() ok' );
is( \&get_relative_path_of_ns, \&get_inc_key, 'get_relative_path_of_ns() is the same as get_inc_key()' );
is( \&normalize_ns, \&Module::Want::get_clean_ns, 'get_relative_path_of_ns() is the same as get_inc_key()' );

Module::Want->import('get_inc_path_via_have_mod');
ok( defined &get_inc_path_via_have_mod, 'get_inc_path_via_have_mod() imported ok' );
ok( $INC{'Test/More.pm'},               'Sanity check that test value is set' );
is( get_inc_path_via_have_mod('Test::More'), $INC{'Test/More.pm'}, 'get_inc_path_via_have_mod() returns the INC value' );
is( get_inc_path_via_have_mod('lkadjnvlkand::lvknadkjcnakjdnvjka'), undef, 'get_inc_path_via_have_mod() returns false on unloadable modules' );

Module::Want->import( 'distname2ns', 'ns2distname' );
ok( defined &distname2ns, 'distname2ns() imported ok' );
ok( defined &ns2distname, 'ns2distname() imported ok' );
is( ns2distname('Foo'),                              'Foo',                'ns2distname() one one chunk' );
is( distname2ns('Foo'),                              'Foo',                'distname2ns() one one chunk' );
is( ns2distname('Foo::Bar\'baz::Wop'),               'Foo-Bar-baz-Wop',    'ns2distname() one multi chunk (quote and colon mixed)' );
is( distname2ns('Foo-Bar-baz-Wop'),                  'Foo::Bar::baz::Wop', 'distname2ns() one multi chunk' );
is( ns2distname('This is not a name space.'),        undef,                'ns2distname() one invalid arg' );
is( distname2ns('This is not a distribution name.'), undef,                'distname2ns() one invalid arg' );

{
    Module::Want->import('search_inc_paths');
    ok( defined &search_inc_paths, 'search_inc_paths() imported ok' );

    my $n = 'Foo::Bar';

    my $dir = File::Temp->newdir();
    local @INC = ();
    my @ins;
    my @pms;

    for my $p (qw(a b c/d e/f/g b/Foo e/f/g/Foo)) {
        my $path = File::Spec->catdir( $dir, split( m{/}, $p ) );

        File::Path::Tiny::mk($path) || die "Could not setup test dir “$path”: $!";

        if ( $path =~ m/Foo$/ ) {
            my $pm = File::Spec->catfile( $path, 'Bar.pm' );

            open my $fh, '>', $pm or die "Could not write “$pm”: $!";
            print {$fh} '1;';
            close $fh;

            my @parts = File::Spec->splitdir($path);
            pop @parts;
            my $path_minus_foo = File::Spec->catdir(@parts);

            push @ins, $path_minus_foo;
            push @pms, $pm;
        }
        else {
            push @INC, $path;    # even though b/Foo woudl get b created we loop through b as well as b/Foo so b is added but b/Foo is not
        }
    }

    my $first = search_inc_paths($n);
    is( $first, $ins[0], 'search_inc_paths() scalar context' );
    my @all = search_inc_paths($n);
    is_deeply( \@all, \@ins, 'search_inc_paths() array context' );

    my $abs_first = search_inc_paths( $n, 1 );
    is( $abs_first, $pms[0], 'search_inc_paths() scalar context w/ abspath boolean' );
    my @abs_all = search_inc_paths( $n, 1 );
    is_deeply( \@abs_all, \@pms, 'search_inc_paths() array context w/ abspath boolean' );
}

is_deeply(
    [
        Module::Want::get_all_use_require_in_text(
            q{
use No::White::Space::U;
   use Some::White::Space::U;
require No::White::Space::R;
  require Some::White::Space::R;
# use commentd::out;
    }
        )
    ],
    [qw(No::White::Space::U Some::White::Space::U No::White::Space::R Some::White::Space::R)],
    'get_all_use_require_in_text() beggining a line',
);

is_deeply(
    [
        Module::Want::get_all_use_require_in_text(
            q{
print 1;use No::White::Space::U;
print 1;   use Some::White::Space::U;
print 1;require No::White::Space::R;
print 1;  require Some::White::Space::R;
# use commentd::out;
    }
        )
    ],
    [qw(No::White::Space::U Some::White::Space::U No::White::Space::R Some::White::Space::R)],
    'get_all_use_require_in_text() midline expression',
);

is_deeply(
    [
        Module::Want::get_all_use_require_in_text(
            q{
use One;print 1;require Two; print 2; use Three;
require Four;print 1;use Five; print 2; require Six;
    }
        )
    ],
    [qw(One Two Three Four Five Six)],
    'get_all_use_require_in_text() multi line',
);

is_deeply(
    [ Module::Want::get_all_use_require_in_text(q{use SemiColon; use SemiColon::Space ; use NoImport (); use Import::qw qw(a b c); use Import::paren (a b c); use Import::quote ''; }) ],
    [qw(SemiColon SemiColon::Space NoImport Import::qw Import::paren Import::quote)],
    'get_all_use_require_in_text() import args'
);

is_deeply(
    [
        Module::Want::get_all_use_require_in_text(
            q{
eval("use Eval::Paren::String::U;");eval("require Eval::Paren::String::R;");
eval "use Eval::Quote::String::U;";eval "require Eval::Quote::String::R;";
eval 'use Eval::Single::String::U;';eval 'require Eval::Single::String::R;';
eval {use Eval::Block::U; };eval { require Eval::Block::R; };
    }
        )
    ],
    [qw(Eval::Paren::String::U Eval::Paren::String::R Eval::Quote::String::U Eval::Quote::String::R Eval::Single::String::U Eval::Single::String::R Eval::Block::U Eval::Block::R)],
    'get_all_use_require_in_text() evals'
);

is_deeply(
    [
        Module::Want::get_all_use_require_in_text(
            q{
 use
    Last::Line::U;
 require
    Last::Line::R;
    }
        )
    ],
    [qw(Last::Line::U Last::Line::R )],
    'get_all_use_require_in_text() multi line statemnt'
);

SKIP: {
    skip 'We are not in dev testing mode', 5 if !defined $Module::Want::DevTesting || !$Module::Want::DevTesting;

    is_deeply(
        [ Module::Want::_get_debugs_refs() ],
        [
            {
                'Module::Want'                      => 1,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 0,
            },
            {
                'Module::Want'                      => 1,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 1,
            },
        ],
        'cache and tries are as expected'
    );

    ok( have_mod( 'Module::Want', 1 ), 'true on already loaded module' );
    ok( !have_mod( 'lkadjnvlkand::lvknadkjcnakjdnvjka', 1 ), 'false on unloadable module' );

    is_deeply(
        [ Module::Want::_get_debugs_refs() ],
        [
            {
                'Module::Want'                      => 1,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 0,
            },
            {
                'Module::Want'                      => 2,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 2,
            },
        ],
        'cache and tries are as expected'
    );

    Module::Want->import( "kcskcsm", "get_inc_key", "have_mod", "qsdch", "is_ns" );
    is_deeply(
        [ Module::Want::_get_debugs_refs() ],
        [
            {
                'Module::Want'                      => 1,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 0,
                'kcskcsm'                           => 0,
                'qsdch'                             => 0,
            },
            {
                'Module::Want'                      => 2,
                'lkadjnvlkand::lvknadkjcnakjdnvjka' => 2,
                'kcskcsm'                           => 1,
                'qsdch'                             => 1,
            },
        ],
        'import(X,Y,Z) calls have_mod(NAME) and does not try to import functions'
    );

}
