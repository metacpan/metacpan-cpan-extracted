#!/usr/bin/env perl
# bin/dev/perl_types_refactor_cpp_namespaces.pl
# Refactor C++ type names from underscore style to namespace:: style and update typemap.perl

use strict;
use warnings;
use File::Find;
use File::Spec;
use File::Basename;
use File::Copy qw(copy);

# Step 1: load mapping from generated refactor map
require 'bin/dev/perl_types_refactor_names_map.pm';
my $mapref = $Perl::Types::RefactorNamesMap::refactor_names_map;
# Merge cpp and h sections into one map for C++ refactoring
my %map = (
    %{ $mapref->{cpp}  // {} },
    %{ $mapref->{h}    // {} },
);

# Build typemap symbol mapping: old_name => new_name with '::' => '__'
my %typemap_map = map {
    my $old = $_;
    my $new = $map{$old};
    $new =~ s/::/__/g;
    ($old => $new);
} keys %map;

# Step 2: collect files to process
my @files;
# C++ sources (.cpp, .h)
find(sub { push @files, $File::Find::name if -f && /\.(?:cpp|h)$/ }, 'lib/Perl/Structure');
# typemap file
push @files, 'lib/typemap.perl' if -f 'lib/typemap.perl';

die "No files found to refactor\n" unless @files;

for my $file (@files) {
    # read entire file
    open my $in, '<', $file or warn "Cannot open $file: $!" and next;
    local $/;
    my $text = <$in>;
    close $in;
    my $orig = $text;

    if ($file =~ /\.(?:cpp|h)$/) {
        # apply C++ type name mapping
        for my $old (sort { length($b) <=> length($a) } keys %map) {
            my $new = $map{$old};
            $text =~ s{(?<![A-Za-z0-9_:])\Q$old\E(?![A-Za-z0-9_:])}{$new}g;
        }
    }
    elsif ($file eq 'lib/typemap.perl') {
        # apply typemap symbol mapping
        for my $old (sort { length($b) <=> length($a) } keys %typemap_map) {
            my $new = $typemap_map{$old};
            $text =~ s{(?<![A-Za-z0-9_])\Q$old\E(?![A-Za-z0-9_])}{$new}g;
        }
    }

    # write back if changed
    if ($text ne $orig) {
        # backup original
        copy($file, "$file.bak") or warn "Failed to backup $file: $!";
        open my $out, '>', $file or die "Cannot write $file: $!";
        print $out $text;
        close $out;
        print "Refactored $file\n";
    }
    else {
        print "No changes in $file\n";
    }
}

print "C++ namespace refactoring complete.\n";
exit 0;