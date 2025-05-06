#!/usr/bin/env perl
# bin/dev/perl_types_refactor_names.pl
# Apply refactor name mappings to input files, producing -MAPPED copies
use strict;
use warnings;
use File::Find;
use File::Basename;
use File::Spec;

# Step 1: collect input files and directories
my @inputs = @ARGV;
unless (@inputs) {
    die "ERROR: NO INPUT FILES\n";
}
my @files;
for my $input (@inputs) {
    if (-d $input) {
        find(sub { push @files, $File::Find::name if -f }, $input);
    } elsif (-f $input) {
        push @files, $input;
    } else {
        warn "ERROR: FILE DOES NOT EXIST: $input\n";
    }
}
@files = do { my %seen; grep { !$seen{$_}++ } @files };

# Step 2: load refactor names map
my %refactor_names_map;
{
    # require the generated map module
    use lib '.';
    require 'bin/dev/perl_types_refactor_names_map.pm';
    if (not defined $Perl::Types::RefactorNamesMap::refactor_names_map) {
        die '$Perl::Types::RefactorNamesMap::refactor_names_map is not defined, dying';
    }
    %refactor_names_map = %{ $Perl::Types::RefactorNamesMap::refactor_names_map };
}
# prepare reverse-allowed and mapped trackers
my %refactor_names_map_reversable;
my %refactor_names_mapped;
for my $sfx (keys %refactor_names_map) {
    $refactor_names_map_reversable{$sfx} = {};
    $refactor_names_mapped{$sfx} = {};
}

# Step 3: detect reversible mappings
my $broken = 0;
for my $sfx (keys %refactor_names_map) {
    for my $old (keys %{ $refactor_names_map{$sfx} }) {
        my $new = $refactor_names_map{$sfx}{$old};
        if (exists $refactor_names_map{$sfx}{$new}) {
            if ($refactor_names_map{$sfx}{$new} eq $old) {
                print "REVERSABLE MAPPING FOUND [$sfx] $old <-> $new\n";
                $refactor_names_map_reversable{$sfx}{$old} = $new;
                $refactor_names_map_reversable{$sfx}{$new} = $old;
            } else {
                print "ERROR: BROKEN REVERSE MAPPING [$sfx] $old->$new, reverse maps to $refactor_names_map{$sfx}{$new}\n";
                $broken = 1;
            }
        }
    }
}
if ($broken) {
    die "ERROR: BROKEN REVERSE MAPPINGS FOUND; please fix map and retry\n";
}

# Step 4: apply mappings to each file
my %file_changes;
for my $file (@files) {
    unless (-e $file) {
        warn "ERROR: FILE DOES NOT EXIST: $file\n";
        next;
    }
    unless (-r $file) {
        warn "ERROR: FILE IS NOT READABLE: $file\n";
        next;
    }
    # determine suffix and map to map suffix
    my ($suffix) = $file =~ /\.([^.]+)$/;
    my $map_sfx = $suffix;
    if ($suffix =~ /^(pl|pmc|t)$/) {
        $map_sfx = 'pm';
    }
    unless (exists $refactor_names_map{$map_sfx}) {
        warn "ERROR: FILE SUFFIX UNKNOWN: $file\n";
        next;
    }
    # read file
    open my $in, '<', $file or next;
    my @lines = <$in>;
    close $in;
    my $modified = 0;
    $refactor_names_mapped{$map_sfx}{$file} = {};
    # sort keys by length desc
    my @keys = sort { length($b) <=> length($a) } keys %{ $refactor_names_map{$map_sfx} };
    for my $old (@keys) {
        my $new = $refactor_names_map{$map_sfx}{$old};
        # find occurrences (whole hot names only)
        my @occurs;
        for my $i (0 .. $#lines) {
            while ($lines[$i] =~ /(?<![A-Za-z0-9_:])\Q$old\E(?![A-Za-z0-9_:])/g) {
                my $idx = $-[0];
                push @occurs, [$i, $idx];
            }
        }
        next unless @occurs;
        # reversible prompt
        if (exists $refactor_names_map_reversable{$map_sfx}{$old}) {
            print "REVERSABLE HOT NAME [$file] $old -> $new found at ",
                  join(', ', map { '('.($_->[0]+1).', '.$_->[1].')' } @occurs), "\n";
            print "Proceed with this mapping? (y/n) ";
            chomp(my $ans = <STDIN>);
            if (lc($ans) ne 'y') {
                print "SKIPPING $old\n";
                next;
            }
        }
        # apply replacements
        for my $occ (@occurs) {
            my ($ln, $ch) = @$occ;
            my $key = "$ln,$ch";
            if ($refactor_names_mapped{$map_sfx}{$file}{$key}) {
                print "RE-MATCHED HOT NAME, SKIPPING [$file] line ", $ln+1, " col $ch for $old\n";
                next;
            }
            substr($lines[$ln], $ch, length($old)) = $new;
            $refactor_names_mapped{$map_sfx}{$file}{$key} = 1;
            $modified = 1;
        }
    }
    # write mapped file
    if ($modified) {
        my ($name, $dir, $ext) = fileparse($file, qr/\.[^.]*$/);
        my $newfile = File::Spec->catfile($dir, $name . '-MAPPED' . $ext);
        open my $out, '>', $newfile or die "Cannot write '$newfile': $!";
        print $out @lines;
        close $out;
        $file_changes{$file} = $newfile;
    } else {
        $file_changes{$file} = undef;
    }
}

# Step 5: final report
for my $orig (sort keys %file_changes) {
    my $mapped = $file_changes{$orig};
    if ($mapped) {
        print "File $orig modified; diff:\n";
        system('diff', '-u', $orig, $mapped);
    } else {
        print "File $orig not modified.\n";
    }
}
exit 0;
