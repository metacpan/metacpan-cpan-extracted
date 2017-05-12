package Test::PMCR;
use strict;
use warnings;

use File::Copy;
use File::Find;
use File::Spec::Functions 'abs2rel', 'catdir';
use File::Temp 'tempdir';

sub setup_temp_dir {
    my ($test) = @_;

    my $dir = tempdir(CLEANUP => 1);

    lib->import($dir);

    my $from_base = catdir(qw(t data), $test);
    find(sub {
        return if $_ eq '.';
        if (-d) {
            my $from = abs2rel($File::Find::name, $from_base);
            my $to = catdir($dir, $from);
            mkdir($to) || die "couldn't mkdir: $!";
        }
        else {
            my $from = abs2rel($File::Find::name, $from_base);
            my $to = catdir($dir, $from);
            copy($_, $to) || die "couldn't copy: $!";
        }
    }, $from_base);

    return $dir;
}

1;
