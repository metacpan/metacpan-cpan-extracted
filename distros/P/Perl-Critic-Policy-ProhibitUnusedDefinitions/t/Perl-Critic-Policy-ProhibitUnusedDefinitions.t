#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/Perl-Critic-Policy-ProhibitUnusedDefinitions.t - which definitions it calls
unused, which it does not, and where it looks to decide

=head1 DESCRIPTION

Every case is a small distribution written to a temporary directory, because
the question this policy answers is about a distribution rather than a file.
Each one gets a directory of its own, and so an index of its own.

The second list matters as much as the first.  A policy that reports what is
plainly in use gets switched off.

=cut

use Test::More;
use Test::NoWarnings;
use File::Temp         qw{tempdir};
use File::Path         qw{make_path};
use File::Basename     qw{dirname};
use Test::MockModule   qw{strict};
use IO::Compress::Gzip ();

use FindBin::libs;

use Perl::Critic ();

use_ok('Perl::Critic::Policy::ProhibitUnusedDefinitions');

# The index on disk goes somewhere of its own, never into the cache of whoever
# runs the tests.
$ENV{XDG_CACHE_HOME} = tempdir( CLEANUP => 1 );

# -profile => q{} so Perl::Critic does not find this dist's own .perlcriticrc
# and run every policy in it against the fixtures.
sub critic {
    my ($profile) = @_;
    return Perl::Critic->new(
        -profile         => $profile // q{},
        '-single-policy' => 'ProhibitUnusedDefinitions',
        -severity        => 1,
    );
}

# A fresh distribution with these files in it.  A dist.ini is added unless the
# case says undef, to be found as the root.
sub dist {
    my (%files) = @_;

    my $root = tempdir( CLEANUP => 1 );
    %files = ( 'dist.ini' => "name = Fixture\n", %files );
    foreach my $name ( grep { defined $files{$_} } keys %files ) {
        make_path( dirname("$root/$name") );
        dist_file( $root, $name, $files{$name} );
    }
    return $root;
}

sub dist_file {
    my ( $root, $name, $content ) = @_;
    open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
    print {$fh} $content;
    close($fh) or die "$root/$name: $!";
    return;
}

sub found {
    my ( $root, $file, $critic ) = @_;
    return [ map { $_->description() } ( $critic // critic() )->critique("$root/$file") ];
}

sub sub_unused    { return "Sub $_[0] is never called from bin/ or lib/" }
sub global_unused { return "Global $_[0] is never used in bin/, lib/, t/ or xt/" }
sub const_unused  { return "Constant $_[0] is never used in bin/, lib/, t/ or xt/" }

my $FOO_BAR = "package Foo;\nsub bar { 1 }\n1;\n";

subtest 'what it reports' => sub {
    my @cases = (
        [ 'a sub nothing calls', { 'lib/Foo.pm' => $FOO_BAR }, 'lib/Foo.pm', [ sub_unused('Foo::bar') ] ],
        [
            'a sub only a test calls',
            { 'lib/Foo.pm' => $FOO_BAR, 't/foo.t' => "use Foo;\nFoo::bar();\n", 'xt/foo.t' => "Foo->bar;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a sub that only calls itself',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { return bar() }\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a method that only calls itself',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { my \$s = shift; return \$s->bar }\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a sub with the same name in another package, called qualified',
            { 'lib/Foo.pm' => $FOO_BAR, 'lib/Baz.pm' => "package Baz;\nsub bar { 1 }\nBaz::bar();\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a sub with the same name in another package, called unqualified',
            { 'lib/Foo.pm' => $FOO_BAR, 'lib/Baz.pm' => "package Baz;\nsub bar { 1 }\nbar();\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a call after a package block has ended',
            { 'lib/Foo.pm' => "package Foo {\n    sub bar { 1 }\n}\nbar();\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a string that spells the name',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nmy \$c = __PACKAGE__->can('bar');\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a hash key that spells the name',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nmy \$y = \$h{ bar };\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a string that spells the name inside an interpolated expression',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nprint \"\@{[ 'bar' ]}\";\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a string that spells the name as a braced variable',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nprint \"\${bar} \@{bar}\";\n1;\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a method call escaped inside a string',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint \"\\\@{[ \$obj->bar ]}\";\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a method call inside a string that does not interpolate',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint '\@{[ \$obj->bar ]}';\n" },
            'lib/Foo.pm', [ sub_unused('Foo::bar') ],
        ],
        [
            'a sub in a script nothing calls',
            { 'bin/tool' => "#!/usr/bin/env perl\nsub usage { 1 }\n" },
            'bin/tool', [ sub_unused('main::usage') ],
        ],
        [
            'a global nothing reads',
            { 'lib/Foo.pm' => "package Foo;\nour \$x = 1;\n1;\n" },
            'lib/Foo.pm', [ global_unused('$Foo::x') ],
        ],
        [
            'each unused global in one our',
            { 'lib/Foo.pm' => "package Foo;\nour ( \$x, \@y, \%z );\nmy \$n = \@y;\n1;\n" },
            'lib/Foo.pm', [ global_unused('$Foo::x'), global_unused('%Foo::z') ],
        ],
        [
            'a constant nothing names',
            { 'lib/Foo.pm' => "package Foo;\nuse constant PI => 3;\n1;\n" },
            'lib/Foo.pm', [ const_unused('Foo::PI') ],
        ],
        [
            'the unused one of a constant list',
            { 'lib/Foo.pm' => "package Foo;\nuse constant { A => 1, B => 2 };\nmy \$x = A;\n1;\n" },
            'lib/Foo.pm', [ const_unused('Foo::B') ],
        ],
    );

    foreach my $case (@cases) {
        my ( $name, $files, $file, $expected ) = @$case;
        is_deeply( found( dist(%$files), $file ), $expected, $name );
    }
};

subtest 'what it deliberately says nothing about' => sub {
    my @cases = (
        [
            'a sub another module calls',
            { 'lib/Foo.pm' => $FOO_BAR, 'lib/Baz.pm' => "package Baz;\nFoo::bar();\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub a script calls, the script having no extension',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nuse Foo;\nFoo::bar();\n" },
            'lib/Foo.pm',
        ],
        [ 'a sub its own package calls', { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nbar();\n1;\n" }, 'lib/Foo.pm' ],
        [
            'a sub the same package calls from another file',
            { 'lib/Foo.pm' => $FOO_BAR, 'lib/Foo/More.pm' => "package Foo;\nbar();\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a method',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nFoo->new->bar;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called through SUPER',
            { 'lib/Foo.pm' => $FOO_BAR, 'lib/Kid.pm' => "package Kid;\nsub baz { \$_[0]->SUPER::bar() }\n1;\n" },
            'lib/Foo.pm',
        ],
        [ 'a sub called with &', { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\n&bar;\n1;\n" }, 'lib/Foo.pm' ],
        [
            'a sub taken by reference',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nmy \$code = \\&bar;\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub reached through its glob',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nmy \$code = *bar{CODE};\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a fully qualified method',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\n\$obj->Foo::bar;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a method inside a hash subscript',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nmy \$y = \$h{ \$obj->bar };\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a method inside an array subscript',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nmy \$y = \$a[ Foo->bar ];\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a method inside a heredoc',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint <<\"END\";\n\@{[ \$obj->bar ]}\nEND\n" },
            'lib/Foo.pm',
        ],
        [
            'a sub called as a method inside a string, through a scalar reference',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint \"\${\\ \$obj->bar }\";\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub called as a method inside a block inside a string',
            { 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint \"\@{[ map { \$_->bar } \@x ]}\";\n" },
            'lib/Foo.pm',
        ],
        [
            'a sub called inside a string by its own package',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nprint \"\@{[ bar() ]}\";\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a sub exported by another package on its behalf',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\npackage main;\npush \@Foo::EXPORT_OK, 'bar';\n1;\n" },
            'lib/Foo.pm',
        ],
        [
            'a sub in a script the script calls',
            { 'bin/tool' => "#!/usr/bin/env perl\nsub usage { 1 }\nusage();\n" }, 'bin/tool',
        ],
        [
            'a global only a test reads',
            { 'lib/Foo.pm' => "package Foo;\nour \$x = 1;\n1;\n", 't/foo.t' => "local \$Foo::x = 2;\n" }, 'lib/Foo.pm',
        ],
        [
            'a global only an author test reads',
            { 'lib/Foo.pm' => "package Foo;\nour \$x = 1;\n1;\n", 'xt/foo.t' => "print \$Foo::x;\n" }, 'lib/Foo.pm',
        ],
        [
            'a global read inside a string',
            { 'lib/Foo.pm' => "package Foo;\nour \$x = 1;\n1;\n", 't/foo.t' => qq{print "\$Foo::x\\n";\n} },
            'lib/Foo.pm',
        ],
        [
            'a global read inside a heredoc',
            { 'lib/Foo.pm' => "package Foo;\nour \$x = 1;\nprint <<\"END\";\n\$x\nEND\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'an array read by element',
            { 'lib/Foo.pm' => "package Foo;\nour \@x = (1);\nmy \$y = \$x[0];\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'an array read by its last index',
            { 'lib/Foo.pm' => "package Foo;\nour \@x = (1);\nmy \$y = \$#x;\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a hash read by key',
            { 'lib/Foo.pm' => "package Foo;\nour \%h = ( a => 1 );\nmy \$y = \$h{a};\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a hash read by key inside a string',
            { 'lib/Foo.pm' => "package Foo;\nour \%h = ( a => 1 );\nprint \"\$h{a}\";\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a hash read by slice inside a string',
            { 'lib/Foo.pm' => "package Foo;\nour \%h = ( a => 1 );\nprint \"\@h{'a'}\";\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a constant whose name is quoted',
            { 'lib/Foo.pm' => "package Foo;\nuse constant 'PI' => 3;\nmy \$x = PI;\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a constant only a test names',
            { 'lib/Foo.pm' => "package Foo;\nuse constant PI => 3;\n1;\n", 't/foo.t' => "my \$x = Foo::PI;\n" },
            'lib/Foo.pm',
        ],
        [
            'a constant named as a method',
            { 'lib/Foo.pm' => "package Foo;\nuse constant PI => 3;\nmy \$x = __PACKAGE__->PI;\n1;\n" }, 'lib/Foo.pm',
        ],
        [
            'a constant another constant names',
            { 'lib/Foo.pm' => "package Foo;\nuse constant A => 1;\nuse constant B => A + 1;\nmy \$x = B;\n1;\n" },
            'lib/Foo.pm',
        ],
        [
            'anything exported',
            {
                'lib/Foo.pm' => "package Foo;\nuse parent 'Exporter';\nour \@EXPORT_OK = qw{bar \$x};\n" . "our \@EXPORT = ('baz');\nour \$x = 1;\nsub bar { 1 }\nsub baz { 1 }\n1;\n",
            },
            'lib/Foo.pm',
        ],
        [
            'anything in an export tag',
            { 'lib/Foo.pm' => "package Foo;\nour \%EXPORT_TAGS = ( all => [qw{bar}] );\nsub bar { 1 }\n1;\n" },
            'lib/Foo.pm',
        ],
        [
            'what perl calls or reads for you',
            {
                'lib/Foo.pm' => "package Foo;\nour \$VERSION = 1;\nour \@ISA = ();\n" . "sub DESTROY { 1 }\nsub BUILD { 1 }\nsub import { 1 }\nsub FETCH { 1 }\n1;\n",
            },
            'lib/Foo.pm',
        ],
        [ 'a forward declaration', { 'lib/Foo.pm' => "package Foo;\nsub bar;\n1;\n" }, 'lib/Foo.pm' ],
        [
            'a helper defined in a test',
            { 't/foo.t' => "sub helper { 1 }\nour \$x = 1;\n", 't/lib/Helper.pm' => "package Helper;\nsub h { 1 }\n1;\n" },
            't/foo.t',
        ],
        [
            'a helper in a test library',
            { 't/lib/Helper.pm' => "package Helper;\nsub h { 1 }\n1;\n" }, 't/lib/Helper.pm',
        ],
        [
            'a file outside bin/ and lib/',
            { 'Makefile.PL' => "sub MY::postamble { 1 }\n" }, 'Makefile.PL',
        ],
        [
            'no dist.ini, and the root found from lib/ instead',
            { 'dist.ini' => undef, 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nFoo::bar();\n" },
            'lib/Foo.pm',
        ],
        [
            'an explicit no critic',
            { 'lib/Foo.pm' => "package Foo;\nsub bar { 1 }    ## no critic (ProhibitUnusedDefinitions)\n1;\n" },
            'lib/Foo.pm',
        ],
    );

    foreach my $case (@cases) {
        my ( $name, $files, $file ) = @$case;
        is_deeply( found( dist(%$files), $file ), [], $name );
    }

    is( scalar critic()->critique( \$FOO_BAR ), 0, 'source with no file name belongs to no distribution' );
};

subtest 'more names can be allowed, and are added to the defaults' => sub {
    my $root = dist(
        'lib/Foo.pm' => "package Foo;\nsub bar { 1 }\nsub qux { 1 }\nsub DESTROY { 1 }\n" . "our \$x = 1;\nour \$y = 1;\nour \$VERSION = 1;\n1;\n",
    );

    my $critic = critic( \"[ProhibitUnusedDefinitions]\nallow_subs = bar\nallow_globals = \$Foo::x\n" );
    is_deeply(
        found( $root, 'lib/Foo.pm', $critic ),
        [ sub_unused('Foo::qux'), global_unused('$Foo::y') ],
        'a bare sub name and a qualified global are exempt; DESTROY and $VERSION still are'
    );

    $critic = critic( \"[ProhibitUnusedDefinitions]\nallow_subs = Foo::qux\nallow_globals = \$y\n" );
    is_deeply(
        found( $root, 'lib/Foo.pm', $critic ),
        [ sub_unused('Foo::bar'), global_unused('$Foo::x') ],
        'and the other way about: a qualified sub and a bare global'
    );
};

subtest 'code in a string that PPI cannot parse is skipped, not fatal' => sub {

    my $root = dist( 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nprint \"\@{[ \$obj->bar ]}\";\n" );

    # Built first, because building a Perl::Critic builds every installed
    # policy, and some of those parse source from a scalar reference too.
    my $critic = critic();

    # Only a scalar reference is refused, which is how the policy hands PPI the
    # code inside a string.  Files, the one being critiqued included, still parse.
    my $new = PPI::Document->can('new');
    my $ppi = Test::MockModule->new('PPI::Document');
    $ppi->redefine( new => sub { return ref $_[1] eq 'SCALAR' ? undef : $new->(@_) } );

    is_deeply( found( $root, 'lib/Foo.pm', $critic ), [ sub_unused('Foo::bar') ], 'the call it could not read is not a use' );
};

subtest 'the distribution is read once' => sub {
    my $root = dist( 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nFoo::bar();\n" );
    is_deeply( found( $root, 'lib/Foo.pm' ), [], 'called from the script' );

    # Take the call away.  A new Perl::Critic, but the same distribution, so the
    # same index -- which still has the call in it.
    dist_file( $root, 'bin/tool', "#!/usr/bin/env perl\n" );
    is_deeply( found( $root, 'lib/Foo.pm' ), [], 'the index built the first time is the one used' );

    my $fresh = dist( 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\n" );
    is_deeply( found( $fresh, 'lib/Foo.pm' ), [ sub_unused('Foo::bar') ], 'while another distribution gets its own' );
};

# --- The index on disk ---------------------------------------------------
# A new process is an empty %INDEX_FOR, so emptying it is how these start a new
# run.  _parse is what reads a file, so counting its calls counts the files that
# a run read again.

sub profile {
    my (%set) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    dist_file( $dir, 'perlcriticrc', join( q{}, "[ProhibitUnusedDefinitions]\n", map { "$_ = $set{$_}\n" } sort keys %set ) );
    return "$dir/perlcriticrc";
}

# What a new run finds for $file, which files it parsed to find it, and how
# many uses it resolved.
sub new_run {
    my ( $root, $file, $profile ) = @_;

    local %Perl::Critic::Policy::ProhibitUnusedDefinitions::INDEX_FOR;
    my @parsed;
    my $resolved = 0;
    my $parse    = Perl::Critic::Policy::ProhibitUnusedDefinitions->can('_parse');
    my $resolve  = Perl::Critic::Policy::ProhibitUnusedDefinitions->can('_resolve');
    my $mock     = Test::MockModule->new('Perl::Critic::Policy::ProhibitUnusedDefinitions');
    $mock->redefine( _parse   => sub { push @parsed, $_[0] =~ s{\A\Q$root\E/}{}r; return $parse->(@_) } );
    $mock->redefine( _resolve => sub { $resolved++;                               return $resolve->(@_) } );

    my $found = found( $root, $file, critic($profile) );
    return ( $found, [ sort @parsed ], $resolved );
}

subtest 'the index is kept on disk, and only what changed is read again' => sub {
    my $cache   = tempdir( CLEANUP => 1 );
    my $profile = profile( cache_dir => $cache );
    my $root    = dist( 'lib/Foo.pm' => $FOO_BAR, 'lib/Baz.pm' => "package Baz;\n1;\n", 'bin/tool' => "#!/usr/bin/env perl\nFoo::bar();\n" );

    my ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
    is_deeply( $found,  [],                                   'called from the script' );
    is_deeply( $parsed, [qw{bin/tool lib/Baz.pm lib/Foo.pm}], 'the first run reads every file' );
    my ($written) = glob("$cache/*.json.gz");
    ok( $written, 'and writes the index to cache_dir' );
    open( my $gzfh, '<:raw', $written // '/bogus' ) or die "no cache in $cache";
    read( $gzfh, my $magic, 2 );
    is( $magic, "\x1f\x8b", 'compressed with gzip' );

    ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
    is_deeply( $found,  [], 'a second run finds the same' );
    is_deeply( $parsed, [], 'without reading any file again' );

    dist_file( $root, 'bin/tool', "#!/usr/bin/env perl\n" );
    ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
    is_deeply( $parsed, [qw{bin/tool}],             'a changed file is read again, and only that one' );
    is_deeply( $found,  [ sub_unused('Foo::bar') ], 'and what changed in it counts' );

    dist_file( $root, 'bin/other', "#!/usr/bin/env perl\nFoo::bar();\n" );
    ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
    is_deeply( $parsed, [qw{bin/other}], 'a new file is read' );
    is_deeply( $found,  [],              'and counts' );

    unlink "$root/bin/other" or die "$root/bin/other: $!";
    ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
    is_deeply( $parsed, [],                         'a deleted file is not read' );
    is_deeply( $found,  [ sub_unused('Foo::bar') ], 'and no longer counts' );
};

subtest 'uses are resolved again only when they can mean something new' => sub {
    my $profile = profile( cache_dir => tempdir( CLEANUP => 1 ) );
    my $root    = dist(
        'lib/Foo.pm' => "package Foo;\nsub run { helper(); return 1 }\n1;\n",
        'bin/tool'   => "#!/usr/bin/env perl\nFoo::run();\nFoo::run();\n",
    );

    my ( $found, $parsed, $resolved ) = new_run( $root, 'lib/Foo.pm', $profile );
    ok( $resolved, 'the first run resolves every use' );
    my $all = $resolved;

    ( $found, $parsed, $resolved ) = new_run( $root, 'lib/Foo.pm', $profile );
    is( $resolved, 0, 'a run with nothing changed resolves none' );

    # A change that defines nothing new: only the changed file is resolved.
    dist_file( $root, 'bin/tool', "#!/usr/bin/env perl\nFoo::run();\n" );
    ( $found, $parsed, $resolved ) = new_run( $root, 'lib/Foo.pm', $profile );
    ok( $resolved > 0 && $resolved < $all, "a changed body resolves its own uses and no others ($resolved of $all)" );

    # helper() in lib/Foo.pm meant nothing, because nothing defined Foo::helper.
    # Now a new file does, and the untouched call means it.
    make_path("$root/lib/Foo");
    dist_file( $root, 'lib/Foo/More.pm', "package Foo;\nsub helper { 1 }\n1;\n" );
    ( $found, $parsed, $resolved ) = new_run( $root, 'lib/Foo/More.pm', $profile );
    is_deeply( $parsed, [qw{lib/Foo/More.pm}], 'a new definition reads only its own file' );
    is_deeply( $found,  [],                    'but an unchanged call that now means it counts' );
};

subtest 'a cache that cannot be used is rebuilt, not trusted' => sub {
    my $cache   = tempdir( CLEANUP => 1 );
    my $profile = profile( cache_dir => $cache );
    my $root    = dist( 'lib/Foo.pm' => $FOO_BAR, 'bin/tool' => "#!/usr/bin/env perl\nFoo::bar();\n" );
    new_run( $root, 'lib/Foo.pm', $profile );
    my ($file) = glob("$cache/*.json.gz");

    # The last three are compressed, so that what fails is the check of what is
    # inside rather than the decompression.
    foreach my $case (
        [ 'a cache that is not gzip',        "\x1f\x8b not gzip",                                                    0 ],
        [ 'a cache that does not parse',     "{ not json",                                                           1 ],
        [ 'a cache from another version',    '{"key":"0/bogus","files":{}}',                                         1 ],
        [ 'a cache with an entry cut short', '{"key":"KEY","files":{"' . "$root/bin/tool" . '":{"stamp":"STAMP"}}}', 1 ],
    ) {
        my ( $name, $content, $compress ) = @$case;
        my $key   = Perl::Critic::Policy::ProhibitUnusedDefinitions::_cache_key();
        my $stamp = Perl::Critic::Policy::ProhibitUnusedDefinitions::_stamp("$root/bin/tool");
        $content =~ s/KEY/$key/;
        $content =~ s/STAMP/$stamp/;
        IO::Compress::Gzip::gzip( \( my $plain = $content ) => \$content ) if $compress;
        dist_file( $cache, ( $file =~ s{\A\Q$cache\E/}{}r ), $content );

        my ( $found, $parsed ) = new_run( $root, 'lib/Foo.pm', $profile );
        ok( scalar( grep { $_ eq 'bin/tool' } @$parsed ), "$name: the file is read again" );
        is_deeply( $found, [], "$name: and the result is right" );
    }
};

subtest 'a write removes the caches of roots that are gone, and nothing else' => sub {
    my $cache   = tempdir( CLEANUP => 1 );
    my $profile = profile( cache_dir => $cache );

    my $gone = dist( 'lib/Foo.pm' => $FOO_BAR );
    new_run( $gone, 'lib/Foo.pm', $profile );
    my ($gone_cache) = glob("$cache/*.json.gz");
    File::Path::remove_tree($gone);

    my $kept = dist( 'lib/Foo.pm' => $FOO_BAR );
    new_run( $kept, 'lib/Foo.pm', $profile );
    my ($kept_cache) = grep { $_ ne $gone_cache } glob("$cache/*.json.gz");

    # A cache from before the cache was compressed, and a file that is not one
    # of this policy's.
    dist_file( $cache, ( 'a' x 40 ) . '.json', '{}' );
    dist_file( $cache, 'notes.txt',            'mine' );

    my $third = dist( 'lib/Foo.pm' => $FOO_BAR );
    new_run( $third, 'lib/Foo.pm', $profile );

    ok( !-e $gone_cache,                        'the cache of a root that is gone is removed' );
    ok( -e $kept_cache,                         'the cache of a root that is there is kept' );
    ok( !-e "$cache/" . ( 'a' x 40 ) . '.json', 'a cache from before compression is removed' );
    ok( -e "$cache/notes.txt",                  'a file that is not a cache is left alone' );
};

subtest 'the cache can be turned off, and a cache_dir that cannot be written costs nothing' => sub {
    my $root = dist( 'lib/Foo.pm' => $FOO_BAR );

    my $off = tempdir( CLEANUP => 1 );
    my ($found) = new_run( $root, 'lib/Foo.pm', profile( cache => 0, cache_dir => $off ) );
    is_deeply( $found, [ sub_unused('Foo::bar') ], 'with cache = 0 it still reports' );
    ok( !glob("$off/*"), 'and writes nothing' );

    # A cache_dir below a plain file cannot be made.
    my $blocked = tempdir( CLEANUP => 1 );
    dist_file( $blocked, 'file', q{} );
    ($found) = new_run( $root, 'lib/Foo.pm', profile( cache_dir => "$blocked/file/cache" ) );
    is_deeply( $found, [ sub_unused('Foo::bar') ], 'with a cache_dir that cannot be made it still reports, and warns of nothing' );
};

Test::NoWarnings::had_no_warnings();

done_testing;
