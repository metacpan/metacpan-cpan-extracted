use strictures 2;

use FindBin;
use Module::CoreList ();
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $minimum_perl = '5.016';
my $root = _repo_root();

for my $file (
    "$root/dist/Net-Blossom/cpanfile",
    "$root/dist/Net-Blossom-Server/cpanfile",
) {
    ok(!-e $file, "$file does not exist; Makefile.PL is the dependency source of truth");
}

for my $file (
    "$root/dist/Net-Blossom/Makefile.PL",
    "$root/dist/Net-Blossom-Server/Makefile.PL",
) {
    for my $module (_dependency_modules($file)) {
        next if $module eq 'perl';

        ok(
            !exists $Module::CoreList::version{$minimum_perl}{$module},
            "$file dependency $module is not core in Perl $minimum_perl",
        );
    }
}

my %net_blossom_deps = map { $_ => 1 } _dependency_modules("$root/dist/Net-Blossom/Makefile.PL");
ok($net_blossom_deps{'Net::Nostr::Core'}, 'Net-Blossom depends on Net::Nostr::Core');
ok($net_blossom_deps{'JSON'}, 'Net-Blossom depends on JSON');

for my $module (qw(
    Net::Nostr
    Net::Nostr::Client
    Net::Nostr::Event
    Net::Nostr::Relay
)) {
    ok(!$net_blossom_deps{$module}, "Net-Blossom does not depend on $module");
}

for my $module (
    [qw(JSON PP)],
    [qw(JSON XS)],
    [qw(Cpanel JSON XS)],
    [qw(JSON MaybeXS)],
) {
    my $name = join '::', @$module;
    my @files = _files_containing($root, qr/\b\Q$name\E\b/);
    is_deeply(\@files, [], "$name is not used; use JSON () instead");
}

done_testing;

sub _dependency_modules {
    my ($file) = @_;

    open my $fh, '<', $file
        or die "Unable to read $file: $!";

    my @modules;
    my $makefile_prereq;

    while (my $line = <$fh>) {
        if ($line =~ /^\s*(CONFIGURE_REQUIRES|PREREQ_PM|TEST_REQUIRES|BUILD_REQUIRES)\s*=>\s*\{\s*$/) {
            $makefile_prereq = 1;
            next;
        }

        if ($makefile_prereq) {
            if ($line =~ /^\s*\},?\s*$/) {
                $makefile_prereq = 0;
                next;
            }

            push @modules, $1
                if $line =~ /^\s*'([^']+)'\s*=>/;

            next;
        }

        push @modules, $1
            if $line =~ /^\s*'([A-Za-z0-9_:]+)'\s*=>/;
    }

    return @modules;
}

sub _repo_root {
    my $dir = $FindBin::Bin;
    while (1) {
        return $dir if -d "$dir/.git";

        my $parent = "$dir/..";
        last if $parent eq $dir;
        $dir = $parent;
    }

    die "Unable to find repository root from $FindBin::Bin";
}

sub _files_containing {
    my ($root, $pattern) = @_;
    my @files;
    _walk_files($root, sub {
        my ($file) = @_;
        return unless $file =~ m{\A\Q$root\E/(?:dist/[^/]+/(?:lib|t|xt)/.*\.(?:pm|t)|dist/[^/]+/Makefile\.PL)\z};

        open my $fh, '<', $file
            or die "Unable to read $file: $!";
        while (my $line = <$fh>) {
            if ($line =~ $pattern) {
                push @files, $file;
                last;
            }
        }
    });

    return sort map { s{\A\Q$root\E/}{}r } @files;
}

sub _walk_files {
    my ($dir, $callback) = @_;

    opendir my $dh, $dir
        or die "Unable to read directory $dir: $!";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        my $path = "$dir/$entry";
        next if $path =~ m{/(?:\.git|local|devel|blossom|blib)\z};

        if (-d $path) {
            _walk_files($path, $callback);
        } elsif (-f $path) {
            $callback->($path);
        }
    }
}
