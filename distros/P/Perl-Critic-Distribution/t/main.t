#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/main.t - one parse per file for every collector, and a cache that holds
what each collector returned

=cut

use Test::More;
use Test::Fatal qw{exception};
use File::Path  qw{make_path};
use File::Temp  qw{tempdir};
use File::Slurper::Temp();
use Cpanel::JSON::XS();
use IO::Compress::Gzip();
use IO::Uncompress::Gunzip();
use Scalar::Util();

use Perl::Critic::Distribution;

my $D = 'Perl::Critic::Distribution';

# A distribution of its own, with a file in each place that is read and one in
# a place that is not.
sub dist {
    my $root = tempdir( CLEANUP => 1 );
    make_path( map { "$root/$_" } qw{bin lib/Some t xt templates} );
    write_file( "$root/dist.ini",          "name = Some\n" );
    write_file( "$root/bin/run",           "#!/usr/bin/perl\nSome::go();\n" );
    write_file( "$root/lib/Some.pm",       "package Some;\nsub go { 1 }\n1;\n" );
    write_file( "$root/lib/Some/Thing.pm", "package Some::Thing;\nsub it { 1 }\n1;\n" );
    write_file( "$root/t/a.t",             "use Some;\nSome::go();\n" );
    write_file( "$root/xt/b.t",            "use Some;\n" );
    write_file( "$root/templates/x.pl",    "1;\n" );
    return Cwd::abs_path($root);
}

sub write_file {
    my ( $path, $text ) = @_;
    File::Slurper::Temp::write_text( $path, $text );
    return;
}

# A collector that counts its calls, and notes the document it was handed.
sub counter {
    my ( $name, %opts ) = @_;
    my %seen = ( calls => 0, docs => {} );
    $D->register(
        name    => $name,
        version => $opts{version} // 1,
        collect => sub {
            my ( $ppi, $file, $area ) = @_;
            $seen{calls}++;
            $seen{docs}{$file} = Scalar::Util::refaddr($ppi);
            return { area => $area, subs => [ map { $_->name } @{ $ppi->find('PPI::Statement::Sub') || [] } ] };
        },
    );
    return \%seen;
}

subtest 'register' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    like(
        exception {
            $D->register( collect => sub { } )
        },
        qr/needs[ ]a[ ]name/xs,
        'a collector needs a name'
    );
    like( exception { $D->register( name => 'x', collect => 'no' ) }, qr/code[ ]reference/xs, 'and collect, as code' );
    is( $D->register( name => 'x', collect => sub { } ), 'x', 'and returns its name' );
};

subtest 'root_of and for_file' => sub {
    local %Perl::Critic::Distribution::FOR;
    my $root = dist();

    is_deeply( [ $D->root_of("$root/lib/Some/Thing.pm") ], [ $root, 'lib' ], 'a module is in lib' );
    is_deeply( [ $D->root_of("$root/bin/run") ],           [ $root, 'bin' ], 'a program in bin' );
    is_deeply( [ $D->root_of("$root/t/a.t") ],             [ $root, 't' ],   'a test in t' );
    is_deeply( [ $D->root_of("$root/templates/x.pl") ],    [],               'and a file in no part that is read is in none' );
    is_deeply( [ $D->root_of(undef) ],                     [],               'nor is source with no file name' );

    make_path("$root/t/lib");
    write_file( "$root/t/lib/Helper.pm", "package Helper;\n1;\n" );
    is_deeply( [ $D->root_of("$root/t/lib/Helper.pm") ], [ $root, 't' ], 'a module under t/lib is in t, because the nearest root decides' );

    my $loose = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
    make_path("$loose/lib");
    write_file( "$loose/lib/Loose.pm", "package Loose;\n1;\n" );
    is_deeply( [ $D->root_of("$loose/lib/Loose.pm") ], [ $loose, 'lib' ], 'with no root marker, the directory that holds lib' );

    my $dist = $D->for_file( "$root/lib/Some.pm", cache_dir => undef );
    is( $dist->root,                                         $root, 'for_file finds the root' );
    is( $D->for_file( "$root/bin/run", cache_dir => undef ), $dist, 'and returns the same object for another file of it' );
    isnt( $D->for_file( "$root/bin/run", cache_dir => tempdir( CLEANUP => 1 ) ), $dist, 'but not for another cache' );
    is( $D->for_file( "$root/templates/x.pl", cache_dir => undef ), undef, 'and nothing for a file in no part that is read' );
};

subtest 'every collector, one parse per file' => sub {
    local %Perl::Critic::Distribution::FOR;
    local %Perl::Critic::Distribution::COLLECTORS;
    my $root = dist();
    my $one  = counter('one');
    my $two  = counter('two');

    my $dist = $D->for_file( "$root/lib/Some.pm", cache_dir => undef );
    my $got  = $dist->collected('one');

    is_deeply( [ sort keys %$got ],         [ map { "$root/$_" } qw{bin/run lib/Some.pm lib/Some/Thing.pm t/a.t xt/b.t} ], 'each Perl file of bin, lib, t and xt' );
    is_deeply( $got->{"$root/lib/Some.pm"}, { area => 'lib', subs => ['go'] },                                             'with what the collector returned, given its area' );
    is( $one->{calls}, 5, 'the collector ran once per file' );
    is( $two->{calls}, 5, 'and so did the other one, in the same walk' );
    is_deeply( $two->{docs}, $one->{docs}, 'handed the same document, so each file was parsed once' );

    $dist->collected('two');
    $dist->collected('one');
    is( $one->{calls} + $two->{calls}, 10,    'and asking again parses nothing' );
    is( $dist->area_of("$root/t/a.t"), 't',   'area_of says where a file is' );
    is( $dist->area_of('/bogus'),      undef, 'and nothing for a file it did not read' );

    like( exception { $dist->collected('nobody') }, qr/No[ ]collector/xs, 'a name nobody registered dies' );

    my $late = counter('late');
    is_deeply( $dist->collected('late')->{"$root/bin/run"}{subs}, [], 'a collector registered after the walk is filled in' );
    is( $late->{calls},                5,  'on every file' );
    is( $one->{calls} + $two->{calls}, 10, 'without running the others again' );
};

subtest 'the cache on disk' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    my $root  = dist();
    my $cache = tempdir( CLEANUP => 1 );
    my $one   = counter('one');
    counter('two');

    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
    }
    my ($written) = glob("$cache/*.json.gz");
    ok( $written, 'the first process writes the cache' );

    # A new process is an empty %FOR.
    my $first = $one->{calls};
    {
        local %Perl::Critic::Distribution::FOR;
        my $got = $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
        is( $one->{calls}, $first, 'the next process parses nothing' );
        is_deeply( $got->{"$root/lib/Some/Thing.pm"}{subs}, ['it'], 'and has what was collected' );
    }

    write_file( "$root/lib/Some/Thing.pm", "package Some::Thing;\nsub it { 1 }\nsub more { 2 }\n1;\n" );
    {
        local %Perl::Critic::Distribution::FOR;
        my $got = $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
        is( $one->{calls}, $first + 1, 'a file that changed is parsed again, alone' );
        is_deeply( $got->{"$root/lib/Some/Thing.pm"}{subs}, [qw{it more}], 'and its new data is there' );
    }

    my $before_one = $one->{calls};
    counter( 'two', version => 2 );
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('two');
        is( $one->{calls}, $before_one, 'a new version of one collector does not run the others' );
    }

    unlink "$root/xt/b.t";
    {
        local %Perl::Critic::Distribution::FOR;
        my $got = $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
        ok( !exists $got->{"$root/xt/b.t"}, 'a file that is gone drops out' );
    }

    my $none = tempdir( CLEANUP => 1 );
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => undef )->collected('one');
    }
    is_deeply( [ glob("$none/*") ], [], 'with no cache_dir, nothing is written' );
};

subtest 'the data of a collector that is not registered is kept' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    my $root  = dist();
    my $cache = tempdir( CLEANUP => 1 );
    my $one   = counter('one');
    counter('two');
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
    }

    # The next process has only two, and then one comes back.
    delete $Perl::Critic::Distribution::COLLECTORS{one};
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('two');
    }
    my $calls = $one->{calls};
    counter('one');
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
    }
    is( $one->{calls}, $calls, 'so a process that registers it again parses nothing' );
};

# The key that this version of the module writes, read back from a cache it
# wrote, so that a case can be a current cache with one thing wrong in it.
sub key_in {
    my ($gz) = @_;
    IO::Uncompress::Gunzip::gunzip( $gz => \my $json ) or die "$gz: $IO::Uncompress::Gunzip::GunzipError";
    return Cpanel::JSON::XS->new->decode($json)->{key};
}

subtest 'a cache that cannot be used is ignored' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    my $root  = dist();
    my $cache = tempdir( CLEANUP => 1 );
    my $one   = counter('one');
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
    }
    my ($file) = glob("$cache/*.json.gz");

    # The magic number of gzip, and then no gzip.
    my $not_gzip = chr(0x1f) . chr(0x8b) . ' not gzip';

    # A current cache in which one file has a stamp and nothing else.
    my $entry = '{"key":"' . key_in($file) . '","files":{"' . "$root/lib/Some.pm" . '":{"stamp":"' . $D->stamp("$root/lib/Some.pm") . '"}}}';
    foreach my $case (
        [ 'that is not gzip',        $not_gzip,                      0, 5 ],
        [ 'that is not JSON',        '{ not json',                   1, 5 ],
        [ 'from another version',    '{"key":"0/bogus","files":{}}', 1, 5 ],
        [ 'with an entry cut short', $entry,                         1, 5 ],
    ) {
        my ( $label, $bytes, $compress, $parses ) = @$case;
        if ($compress) {
            IO::Compress::Gzip::gzip( \$bytes => \my $gz );
            $bytes = $gz;
        }
        File::Slurper::Temp::write_binary( $file, $bytes );

        my $calls = $one->{calls};
        local %Perl::Critic::Distribution::FOR;
        my $got = $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->collected('one');
        is( $one->{calls} - $calls, $parses, "a cache $label is not trusted" );
        is_deeply( $got->{"$root/lib/Some.pm"}{subs}, ['go'], 'and the data is right' );
    }
};

subtest 'stash and keep' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    my $root  = dist();
    my $cache = tempdir( CLEANUP => 1 );
    counter('one');
    {
        local %Perl::Critic::Distribution::FOR;
        my $dist = $D->for_file( "$root/lib/Some.pm", cache_dir => $cache );
        is( $dist->stash('one'), undef, 'nothing is kept at first' );
        ok( $dist->keep( one => { worked => 'out' } ), 'keep writes the cache' );
        is_deeply( $dist->stash('one'), { worked => 'out' }, 'and the stash has it' );
        like( $dist->stamp_of("$root/lib/Some.pm"), qr/\A\d+:\d+:\d+:/xs, 'stamp_of gives the stamp the file was read with' );
    }
    {
        local %Perl::Critic::Distribution::FOR;
        is_deeply( $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->stash('one'), { worked => 'out' }, 'the next process reads it' );
    }
    counter( 'one', version => 2 );
    {
        local %Perl::Critic::Distribution::FOR;
        is( $D->for_file( "$root/lib/Some.pm", cache_dir => $cache )->stash('one'), undef, 'and another version of the collector does not' );
    }
};

subtest 'the cache of a root that is gone is removed' => sub {
    local %Perl::Critic::Distribution::COLLECTORS;
    my $cache = tempdir( CLEANUP => 1 );
    counter('one');

    my $gone = dist();
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$gone/lib/Some.pm", cache_dir => $cache )->collected('one');
    }
    my ($gone_cache) = glob("$cache/*.json.gz");
    File::Path::remove_tree($gone);

    write_file( "$cache/notes.txt", 'mine' );

    my $kept = dist();
    {
        local %Perl::Critic::Distribution::FOR;
        $D->for_file( "$kept/lib/Some.pm", cache_dir => $cache )->collected('one');
    }
    ok( !-e $gone_cache,       'the next write removes it' );
    ok( -e "$cache/notes.txt", 'and leaves alone a file that is not a cache' );
    is( scalar( () = glob("$cache/*.json.gz") ), 1, 'and keeps the one whose root is there' );
};

done_testing();
