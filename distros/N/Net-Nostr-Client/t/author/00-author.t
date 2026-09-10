#!/usr/bin/perl

use strictures 2;

use lib 'lib';
use lib '../Net-Nostr-Core/lib';

use Test2::V0 -no_srand => 1;
use Archive::Tar ();
use Config qw(%Config);
use CPAN::Meta::Requirements ();
use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use JSON::PP ();
use Module::CoreList ();
use Test::Pod;
use Test::Pod::Coverage;

my $dist        = 'Net-Nostr-Client';
my $main_module = 'lib/Net/Nostr/Client.pm';
my @expected_modules = qw(lib/Net/Nostr/Client.pm lib/Net/Nostr/GroupDiscovery.pm);
my @expected_tests   = qw(t/*.t t/nip/*.t);

subtest 'distribution layout' => sub {
    ok(-e 'Makefile.PL', "$dist has Makefile.PL");
    ok(!-e 'cpanfile', "$dist does not have cpanfile");
    ok(!-e 'README.md', "$dist does not have README.md");
    ok(-e 'Changes', "$dist has Changes");

    ok(-e $_, "$dist ships $_") for @expected_modules;
};

subtest 'distribution version is self-consistent' => sub {
    my $source = _slurp($main_module);
    my ($version) = $source =~ /^our \$VERSION = '([^']+)';/m;
    ok(defined $version, "$dist declares a \$VERSION") or return;

    my $changes = _slurp('Changes');
    my $released_changes = $changes;
    $released_changes =~ s/\AUnreleased\b.*?(?=^\S)//ms;
    my ($top) = $released_changes =~ /\A(\S+)\s+\d{4}-\d{2}-\d{2}/;
    ok(defined $top, "$dist Changes has a dated release entry after any Unreleased section") or return;
    is($version, $top, "$dist \$VERSION ($version) matches its latest Changes entry ($top)");

    like($version, qr/\A1\./, "$dist keeps its 1.x version line");
    unlike($changes, qr/^2\.\d+/m, "$dist Changes does not carry Net-Nostr 2.x release entries");
};

subtest 'configured dependencies require compatible Net::Nostr components' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    _copy_file('Makefile.PL', "$tmp/Makefile.PL");
    _copy_version_from_file($tmp);
    my ($output, $exit) = _run_in_dir($tmp, sub {
        my $output = `$^X Makefile.PL 2>&1`;
        return ($output, $? >> 8);
    });
    is($exit, 0, 'Makefile.PL exits cleanly') or diag $output;
    _check_component_requirements(JSON::PP::decode_json(_slurp("$tmp/MYMETA.json")));
};

subtest 'Makefile.PL is dependency source of truth' => sub {
    ok(!-e 'cpanfile', "$dist has no cpanfile");

    if (-e 'MANIFEST.SKIP') {
        my $manifest_skip = _slurp('MANIFEST.SKIP');
        unlike($manifest_skip, qr/cpanfile/, "$dist MANIFEST.SKIP does not allow cpanfile");
        unlike($manifest_skip, qr/README\\\.md|README\.md/, "$dist MANIFEST.SKIP does not allow README.md");
    } else {
        pass("$dist release archive does not ship MANIFEST.SKIP");
    }
};

subtest 'Makefile.PL test target excludes author tests' => sub {
    _test_makefile_test_target(@expected_tests);
};

subtest 'dist metadata does not list modules core in Perl 5.16' => sub {
    _test_dist_metadata_core_prereqs();
};

subtest 'top-level module POD links related distributions' => sub {
    my $source = _slurp($main_module);
    like($source, qr/L<Net::Nostr>/, 'Client POD links to Net::Nostr');
    like($source, qr/L<Net::Nostr::Core>/, 'Client POD links to Net::Nostr::Core');
    like($source, qr/L<Net::Nostr::Relay>/, 'Client POD links to Net::Nostr::Relay');
};

subtest 'pod syntax' => sub {
    all_pod_files_ok(_pod_files());
};

subtest 'pod coverage' => sub {
    my @modules = _modules();
    pod_coverage_ok($_) for sort @modules;
    done_testing;
};

subtest 'named argument normalization is the only constructor arg pattern' => sub {
    _check_constructor_patterns();
};

subtest 'constructor POD documents accepted argument forms' => sub {
    my @checks;
    my @files = _module_files();

    for my $file (sort @files) {
        my $source = _slurp($file);

        push @checks, [$file, 'new']
            if $source =~ /^=head2 new$/m;
        while ($source =~ /^=head2 (new_\w+)$/mg) {
            push @checks, [$file, $1];
        }
    }

    _check_constructor_pod(@checks);
};

done_testing;

sub _test_makefile_test_target {
    my @expected = @_;
    my $tmp = tempdir(CLEANUP => 1);

    _copy_file('Makefile.PL', "$tmp/Makefile.PL");
    _copy_version_from_file($tmp);
    make_path("$tmp/t/author");
    _write_test("$tmp/t/top.t");
    _write_test("$tmp/t/author/pod.t");

    my ($output, $exit) = _run_in_dir($tmp, sub {
        my $output = `$^X Makefile.PL 2>&1`;
        return ($output, $? >> 8);
    });

    is($exit, 0, 'Makefile.PL exits cleanly') or diag $output;

    open my $fh, '<', "$tmp/Makefile" or die "open generated Makefile: $!";
    my $makefile = do { local $/; <$fh> };
    close $fh;

    my ($test_files) = $makefile =~ /^TEST_FILES\s*=\s*(.+)$/m;
    ok(defined $test_files, 'TEST_FILES is defined');

    for my $pattern (@expected) {
        my $quoted = quotemeta $pattern;
        like($test_files, qr/(?:^|\s)$quoted(?:\s|$)/, "$pattern included");
    }

    unlike(
        $test_files,
        qr/(?:^|\s)(?:t\/author\/\*\.t|t\/author\/pod\.t|t\/\*\/\*\.t)(?:\s|$)/,
        'author tests are excluded'
    );
}

sub _test_dist_metadata_core_prereqs {
    my $tmp = tempdir(CLEANUP => 1);

    _copy_file('Makefile.PL', "$tmp/Makefile.PL");
    _copy_version_from_file($tmp);

    my (
        $output, $exit, $manifest_output, $manifest_exit,
        $dist_output, $dist_exit, $tarball_count, @core_prereqs
    ) = _run_in_dir($tmp, sub {
        my $output = `$^X Makefile.PL 2>&1`;
        my $exit = $? >> 8;

        my $make = $Config{make} || 'make';
        my $manifest_output = `$make manifest 2>&1`;
        my $manifest_exit = $? >> 8;

        my $dist_output = `$make dist 2>&1`;
        my $dist_exit = $? >> 8;

        my @tarballs = glob('*.tar.gz');
        my @core_prereqs = @tarballs ? _core_prereqs_in_tarball($tarballs[0]) : ();
        return (
            $output, $exit, $manifest_output, $manifest_exit,
            $dist_output, $dist_exit, scalar @tarballs, @core_prereqs
        );
    });

    is($exit, 0, 'Makefile.PL exits cleanly') or diag $output;
    is($manifest_exit, 0, 'make manifest exits cleanly') or diag $manifest_output;
    is($dist_exit, 0, 'make dist exits cleanly') or diag $dist_output;
    is($tarball_count, 1, 'one tarball created');
    is(\@core_prereqs, [], 'META.json has no Perl 5.16 core module prereqs')
        or diag join "\n", @core_prereqs;
}

sub _copy_version_from_file {
    my ($tmp) = @_;

    my $source = _slurp('Makefile.PL');
    my ($version_from) = $source =~ /VERSION_FROM\s*=>\s*'([^']+)'/;
    die "Makefile.PL missing VERSION_FROM" unless defined $version_from;

    my $dst_dir = "$tmp/$version_from";
    $dst_dir =~ s{/[^/]+\z}{};
    make_path($dst_dir);
    _copy_file($version_from, "$tmp/$version_from");
}

sub _copy_file {
    my ($src, $dst) = @_;
    my $dir = $dst;
    $dir =~ s{/[^/]+\z}{};
    make_path($dir) unless -d $dir;
    copy($src, $dst) or die "copy $src to $dst: $!";
}

sub _write_test {
    my ($path) = @_;
    open my $tfh, '>', $path or die "open $path: $!";
    print {$tfh} "use strictures 2;\nuse Test2::V0 -no_srand => 1;\nok 1;\ndone_testing;\n";
    close $tfh;
}

sub _run_in_dir {
    my ($dir, $code) = @_;
    my $cwd = getcwd();
    chdir $dir or die "chdir $dir: $!";

    my @result;
    my $ok = eval {
        @result = $code->();
        1;
    };
    my $error = $@;

    chdir $cwd or die "chdir $cwd: $!";
    die $error unless $ok;
    return @result;
}

sub _core_prereqs_in_tarball {
    my ($tarball) = @_;
    my $tar = Archive::Tar->new;
    $tar->read($tarball, 1) or die "read $tarball: " . $tar->error;
    my ($meta_file) = grep { m{^[^/]+/META\.json\z} } $tar->list_files;
    die "$tarball missing META.json" unless defined $meta_file;

    my $meta = JSON::PP::decode_json($tar->get_content($meta_file));
    _check_component_requirements($meta);
    my @core_prereqs;
    for my $phase (sort keys %{ $meta->{prereqs} || {} }) {
        for my $relationship (sort keys %{ $meta->{prereqs}{$phase} || {} }) {
            my $modules = $meta->{prereqs}{$phase}{$relationship};
            for my $module (sort keys %$modules) {
                next if $module eq 'perl';
                next unless _is_core_in_perl_516($module);
                push @core_prereqs, "$phase.$relationship:$module";
            }
        }
    }
    return @core_prereqs;
}

sub _check_component_requirements {
    my ($meta) = @_;
    my $requires = $meta->{prereqs}{runtime}{requires};
    my $requirements = CPAN::Meta::Requirements->from_string_hash($requires);
    for my $module (qw(Net::Nostr::Core)) {
        ok(exists $requires->{$module}, "$module is required");
        ok(!$requirements->accepts_module($module, '1.001002'), "$module rejects July components");
        ok(!$requirements->accepts_module($module, '1.001999'), "$module requires the September API");
        ok($requirements->accepts_module($module, '1.002000'), "$module accepts the new release");
        ok($requirements->accepts_module($module, '1.003000'), "$module permits later compatible releases");
    }
}

sub _is_core_in_perl_516 {
    my ($module) = @_;
    my $perl_516_core = $Module::CoreList::version{5.016}
        or die "Module::CoreList missing Perl 5.16 data";
    return exists $perl_516_core->{$module};
}

sub _pod_files {
    my @files;
    find(
        sub {
            return unless -f $_ && /\.p(?:m|od)\z/;
            push @files, $File::Find::name;
        },
        'lib',
    );
    return @files;
}

sub _modules {
    my @modules;
    for my $file (_pod_files()) {
        next unless $file =~ m{^lib/(.+)\.pm\z};
        my $module = $1;
        $module =~ s{/}{::}g;
        push @modules, $module;
    }
    return @modules;
}

sub _module_files {
    my @files;
    find(
        sub {
            return unless -f $_ && /\.pm\z/;
            push @files, $File::Find::name;
        },
        'lib',
    );
    return @files;
}

sub _check_constructor_patterns {
    my @violations;
    my @files = _module_files();
    for my $file (sort @files) {
        my $source = _slurp($file);

        push @violations, "$file uses bless { \@_ }" if $source =~ /bless\s+\{\s*\@_\s*\}/;
        push @violations, "$file uses my %args = \@_" if $source =~ /my\s+%args\s*=\s*\@_/;
        push @violations, "$file destructures %args directly" if $source =~ /my\s+\([^)]*%args[^)]*\)\s*=\s*\@_/;
        push @violations, "$file destructures (%args) directly" if $source =~ /my\s+\(%args\)\s*=\s*\@_/;
        push @violations, "$file references public ConstructorArgs"
            if $source =~ /Net::Nostr::ConstructorArgs\b/;
    }

    is(\@violations, [], 'constructors and named-arg methods use the shared normalizer');
}

sub _check_constructor_pod {
    my @checks = @_;

    my @violations;
    for my $check (@checks) {
        my ($file, $heading) = @$check;
        my $source = _slurp($file);

        my ($section) = $source =~ /^=head2 \Q$heading\E\n(.*?)(?=^=head[12]\b|\z)/ms;
        push @violations, "$file POD missing =head2 $heading" unless defined $section;
        next unless defined $section;

        push @violations, "$file =head2 $heading does not document flat list/hashref arguments"
            unless $section =~ /flat list or a single hash\s+reference/;
    }

    is(\@violations, [], 'constructor POD documents flat list and hashref forms');
}

sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;
    return $source;
}
