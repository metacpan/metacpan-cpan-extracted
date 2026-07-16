use strictures 2;

use File::Find ();
use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

eval 'use Pod::Coverage 0.23; 1'
    or plan skip_all => 'Pod::Coverage 0.23 is required for author tests';

use lib "$FindBin::Bin/../lib";

my $lib = "$FindBin::Bin/../lib";
my @modules = _pod_modules($lib);

plan skip_all => 'No POD-bearing modules to check'
    unless @modules;

for my $module (@modules) {
    my $coverage = Pod::Coverage->new(
        package => $module,
        private => [qr/\A_/],
    );
    my $result = $coverage->coverage;

    ok(!defined($result) || $result == 1, "$module POD coverage");
    diag "$module undocumented methods: " . join(', ', $coverage->uncovered)
        if defined($result) && $result < 1;
}

done_testing;

sub _pod_modules {
    my ($lib) = @_;
    my @modules;

    File::Find::find({
        wanted => sub {
            return unless -f $_ && /\.pm\z/;
            return unless _has_pod($File::Find::name);

            my $module = $File::Find::name;
            $module =~ s{\A\Q$lib\E/}{};
            $module =~ s{/}{::}g;
            $module =~ s{\.pm\z}{};
            push @modules, $module;
        },
        no_chdir => 1,
    }, $lib);

    return sort @modules;
}

sub _has_pod {
    my ($file) = @_;

    open my $fh, '<', $file
        or die "Unable to read $file: $!";
    while (my $line = <$fh>) {
        return 1 if $line =~ /^=\w/;
    }

    return 0;
}
