#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use LWP::Simple;
use ExtUtils::MakeMaker qw(prompt);

my $version = shift @ARGV or die "Usage: release.pl version";

my $workdir  = "$ENV{HOME}/pmsetup";
my $checkout = "String-Diff-$version";

chdir $workdir;

if (-e $checkout) {
    die "$workdir/$checkout exists. Remove it first";
}

system("svk co //mirror/public/String-Diff/trunk $checkout");
sleep(2);

if (-e $checkout) {
    chdir $checkout;

    rewrite_version("lib/String/Diff.pm", $version);

    system("perl Makefile.PL --skip");
    system("make manifest");

    check_version("Changes", $version);

    if (!system("make disttest")) {
        system("svk ci -m 'packaging $version'");
        system("svk cp -m 'tag release $version' //mirror/public/String-Diff/trunk //mirror/public/String-Diff/tags/release-$version");
        system("make dist");
        if (prompt("upload to CPAN?: [yN]", 'n') =~ /[yY]/) {
            system("cpan-upload -verbose String-Diff-$version.tar.gz");
        } else {
            rename "String-Diff-$version.tar.gz", "../String-Diff-$version.tar.gz";
        }
    } else {
        warn "make disttest failed. Don't upload";
    }

    chdir "..";
    system("svk co --detach $checkout");
}

rmtree("$workdir/$checkout");

sub rewrite_version {
    my($file, $version) = @_;

    open my $fh, $file or die "$file: $!";
    my $content = join '', <$fh>;
    close $fh;

    $content =~ s/^our \$VERSION = .*?;$/our \$VERSION = '$version';/m;

    open my $out, ">", "lib/String/Diff.pm";
    print $out $content;
    close $out;
}

sub check_version {
    my($file, $version) = @_;

    open my $fh, $file or die "$file: $!";
    while (<$fh>) {
        /^\Q$version\E / and return 1;
    }

    die "$file doesn't contain log for $version";
}
