#!/usr/bin/env perl

# Graph the Halstead relative complexity of the git revisions of tracked perl files.
# The files are given relative to your repository directory ($base below).
# Examples:
# perl git-halstead difficulty /home/you/repos/ Relative-dir-to-$base/lib/Some/Module.pm
# perl git-halstead effort     /home/you/repos/ Relative-dir-to-$base/lib/Some/Module.pm Another/Package.pm # etc.

use strict;
use warnings;

use File::Slurper qw(read_text);
use Capture::Tiny qw(capture);
use Chart::Lines ();
use Path::Tiny qw(path); # TODO consolidate these three:
use File::Spec qw(catdir splitdir);
use File::Basename qw(fileparse);
use File::Temp ();
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Perl-Metrics-Halstead);
use Perl::Metrics::Halstead ();
use Try::Tiny qw(try catch);

my $metric = shift; # difficulty, effort, volume, etc
my $base   = shift || "$ENV{HOME}/sandbox/";
my @files  = @ARGV;

die "Usage: perl $0 metric /your/repos/ path/to/file.pl another/Module.pm some/test.t ...\n"
    unless $metric && $base && @files;

my $dir = path('.')->absolute; # where are we?

my $w = 900;
my $h = 600;
my $chart = Chart::Lines->new($w, $h);

$chart->set(
    title        => 'Git Revision Halstead Complexity',
    x_label      => 'Revisions',
    y_label      => ucfirst $metric,
    include_zero => 'false',
    precision    => 2,
    skip_x_ticks => 40,
    brush_size   => 2,
    pt_size      => 4,
    y_grid_lines => 'true',
);

my @dataset;
my @labels;

@files = glob $files[0] if $files[0] =~ /\*/;

for my $file (@files) {
    my ($name, $path, $suffix) = fileparse($file, qw(.pl .pm .t));

    my @parts = File::Spec->splitdir($path);
    my $first = $parts[0];
    $path =~ s/^$first\///;

    chdir File::Spec->catdir($base, $first) or die "Can't chdir: $!";

    # get all the commit hashes
    my $commits = qx{ git log --pretty=format:"%H" };

    my @halstead; # score array

    my $i = 0; # loop counter

    for my $commit (split /\n/, $commits) {
        $i++;

        my ($stdout, $stderr) = capture {
            system('git', 'show', "$commit:$path$name$suffix");
        };
        next if $stderr =~ /^fatal:/;

        my $tmp = File::Temp->new;
        print $tmp "$stdout\n";

        my $halstead;
        try {
            # compute the complexity for this revision
            $halstead = Perl::Metrics::Halstead->new(file => $tmp->filename);
        }
        catch {
            warn "$i. ERROR: $_";
        };

        if ($halstead) {
            my $x = $halstead->dump->{$metric};
            warn "$i. $metric: $x\n";
            push @halstead, $x;
        }
    }

    # reverse because commits are last to first by date
    push @dataset, [ reverse @halstead ];
    push @labels, $first;
}

# go back to where we started
chdir $dir;

die "Something went wrong\n" unless @{ $dataset[0] };

# find the number of x-axis datapoints
my $max = 0;
for my $data (@dataset) {
    my $x = @$data;
    $max = $x if $x > $max;
}

# add the number of revisions
$chart->add_dataset(1 .. $max);
# add the computed data
for my $data (@dataset) {
    # pad the end of the array with zeros if needed
    if (@$data < $max) {
        push @$data, (0) x ($max - @$data);
    }
    $chart->add_dataset(@$data);
}

$chart->set(legend_labels => \@labels);

$chart->png("$0.png");
