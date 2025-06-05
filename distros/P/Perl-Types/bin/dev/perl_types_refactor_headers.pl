#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

my $current_file_count = 0;
my @perl_files;
find(sub {
    return unless -f;

    # select files whose name contains .pm or .pl
    if ($_ =~ /\.(?:pm|pl)/) {
        push @perl_files, $File::Find::name;
    }
}, 't/lib');

for my $file (@perl_files) {
    $current_file_count++;
    print "\nProcessing file #$current_file_count: $file\n";
    open my $fh, '<', $file or do {
        print "  Cannot open file: $!\n";
        next;
    };
    my @lines = <$fh>;
    close $fh;

    my $modified = 0;
    for (my $i = 0; $i <= $#lines; ) {
        if ($lines[$i] =~ /^\s*($|#)/) { $i++; next }
        if ($lines[$i] =~ /^\s*use\s+(?:Perl::Types|perltypes)\s*;/) {
            print "  Found old-style header at line " . ($i+1) . "\n";
            splice @lines, $i, 1;
            $modified = 1;
            my $ver_i;
            for my $j ($i .. $#lines) {
                if ($lines[$j] =~ /^\s*our\s+\$VERSION\b/) { $ver_i = $j; last }
            }
            my $insert_idx;
            for my $j ($i .. ($ver_i // $#lines)) {
                if ($lines[$j] =~ /^\s*use\s+warnings\s*;/) {
                    $insert_idx = $j + 1;
                    last;
                }
            }
            $insert_idx //= $i;
            splice @lines, $insert_idx, 0, "use types;\n";
            print "    Inserted 'use types;' at line " . ($insert_idx+1) . "\n";
            $i = ($ver_i // $insert_idx) + 1;
            next;
        }
        elsif ($lines[$i] =~ /^\s*package\b/) {
            print "  Found new-style header at line " . ($i+1) . "\n";
            my $ver_i;
            for my $j ($i+1 .. $#lines) {
                if ($lines[$j] =~ /^\s*our\s+\$VERSION\b/) { $ver_i = $j; last }
            }
            unless (defined $ver_i) {
                print "    No version line after package at line " . ($i+1) . ", skipping header\n";
                $i++;
                next;
            }
            my $found_type = 0;
            for my $j ($i+1 .. $ver_i-1) {
                if ($lines[$j] =~ /^\s*use\s+(?:Perl::Types|perltypes)\s*;/) {
                    print "    Normalizing type use at line " . ($j+1) . " to 'use types;'\n";
                    $lines[$j] = "use types;\n";
                    $modified = 1;
                    $found_type = 1;
                }
                elsif ($lines[$j] =~ /^\s*use\s+types\s*;/) {
                    $found_type = 1;
                }
            }
            unless ($found_type) {
                print "    Unrecognized header: no type use before version in block starting at line " . ($i+1) . "\n";
            }
            $i = $ver_i + 1;
            next;
        }
        else {
            $i++;
        }
    }
    if ($modified) {
        open my $out, '>', $file or do {
            print "  Cannot write file: $!\n";
            next;
        };
        print $out @lines;
        close $out;
        print "  File modified and saved.\n";
    } else {
        print "  No changes needed.\n";
    }

    # limit to the first few files for debugging
#    if ($current_file_count >= 10) {
#        die 'TMP DEBUG';
#    }
}
