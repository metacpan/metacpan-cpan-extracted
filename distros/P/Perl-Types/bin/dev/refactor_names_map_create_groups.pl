#!/usr/bin/env perl
# bin/dev/group_refactor_names_map.pl - Annotate refactor names map with group comments
use strict;
use warnings;
my ($infile, $outfile) = @ARGV;
die "Usage: $0 <input_map.pm> <output_grouped_map.pm>\n" unless $infile && $outfile;
open my $in, '<', $infile or die "Cannot open '$infile': $!";
open my $out, '>', $outfile or die "Cannot write '$outfile': $!";
my $suffix;
my $last_group = '';
while (my $line = <$in>) {
    # detect suffix section start
    if ($line =~ /^\s*'([^']+)'\s*=>\s*{\s*$/) {
        print $out $line;
        $suffix = $1;
        $last_group = '';
        my ($indent) = $line =~ /^(\s*)'/;
        print $out $indent . "# ${suffix}_mappings: hot-name mappings for '$suffix' files\n";
        next;
    }
    # detect mapping line
    if (defined $suffix && $line =~ /^(\s*)'([^']+)'\s*=>/) {
        my ($indent, $key) = ($1, $2);
        my $group_id;
        my $desc;
        if ($key =~ /^[A-Z]+?\d{2}$/) { # error codes
            $group_id = "error_codes_${suffix}";
            $desc     = "C++ error code constants";
        } elsif ($key =~ /^XS_pack_/) {
            $group_id = "xs_pack_${suffix}";
            $desc     = "XS 'pack' interface functions";
        } elsif ($key =~ /^XS_unpack_/) {
            $group_id = "xs_unpack_${suffix}";
            $desc     = "XS 'unpack' interface functions";
        } elsif ($key =~ /^_/) {
            $group_id = "internal_${suffix}";
            $desc     = "Internal naming pattern mappings";
        } elsif ($key =~ /^gsl_matrix_to_/) {
            $group_id = "gsl_matrix_${suffix}";
            $desc     = "GSL matrix conversion functions";
        } elsif ($key =~ /^input_/) {
            $group_id = "input_${suffix}";
            $desc     = "Input parameter naming mappings";
        } elsif ($key =~ /^integer_/) {
            $group_id = "integer_${suffix}";
            $desc     = "Integer type function mappings";
        } elsif ($key =~ /^number_/) {
            $group_id = "number_${suffix}";
            $desc     = "Number type function mappings";
        } elsif ($key =~ /^object_/) {
            $group_id = "object_${suffix}";
            $desc     = "Object type function mappings";
        } elsif ($key =~ /^scalar/) {
            $group_id = "scalar_${suffix}";
            $desc     = "Scalar type function mappings";
        } elsif ($key =~ /^string_/) {
            $group_id = "string_${suffix}";
            $desc     = "String type function mappings";
        } elsif ($key =~ /_CHECK/) {
            $group_id = "check_${suffix}";
            $desc     = "Type-checking functions";
        } elsif ($key =~ /_to_string/) {
            $group_id = "to_string_${suffix}";
            $desc     = "to_string functions";
        } elsif ($key =~ /_typetest/) {
            $group_id = "typetest_${suffix}";
            $desc     = "Type-testing functions";
        } else {
            $group_id = "other_${suffix}";
            $desc     = "Miscellaneous hot name mappings";
        }
        if ($group_id ne $last_group) {
            print $out $indent . "# $group_id: $desc\n";
            $last_group = $group_id;
        }
    }
    print $out $line;
}
close $in;
close $out;
exit 0;