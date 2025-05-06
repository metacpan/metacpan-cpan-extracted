#!/usr/bin/env perl
# bin/dev/perl_types_refactor_names_parser.pl
#
# Parser to generate a mapping of old compound type names (suffix-first underscore)
# to new compound type names (prefix-first underscore) by comparing the baseline
# (pre-refactor) and current code in the git repository.
#
use strict;
use warnings;
our $VERSION = 0.107_000;

use Getopt::Long;
use File::Find;
require Term::ReadLine;

sub usage {
    die <<"USAGE";
Usage: $0 [--baseline <commit>] [--interactive] [--help]

Options:
  --baseline <commit>   Git commit or ref representing the pre-refactor baseline
                        (default: 9fb763300058926db240b94179772753f642cd2a)
  --interactive         Prompt interactively for unchanged hot names (default: no prompts)
  --help                Show this help and exit

This script compares the baseline commit to the current working tree and
extracts all compound data type names, generating a mapping from old to new identifiers.
Outputs a Perl data structure.
USAGE
}

# default to non-interactive mode
my $interactive_UI = 0;

# when running in interactive mode, use Term::ReadLine to prompt for UNCHANGED hot names
my $term = Term::ReadLine->new('perl_types_refactor_names_parser', \*STDIN, \*STDOUT);

my %refactor_names_map;  # must declare outside of any control structures
my $baseline = '9fb763300058926db240b94179772753f642cd2a';
GetOptions(
    'baseline=s'   => \$baseline,
    'interactive!' => \$interactive_UI,
    'help|h'       => sub { usage() },
) or usage();

use File::Path qw(make_path remove_tree);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;  # sort Dumper() output, especially for final %refactor_names_map output
$Data::Dumper::Terse = 1;        # don't output $VAR1 names, to avoid problems when re-loading later

# Flush per-hunk records into flat pairs, handling CREATED/DELETED.
sub _flush_records {
    my ($records_ref, $pairs_ref, $suffix, $diff_path) = @_;
    for my $rec (@$records_ref) {
        my $old_names = $rec->{old} || [];
        my $new_names = $rec->{new} || [];
        # Deleted: minus-only
        if (@$old_names && !@$new_names) {
            for my $o (@$old_names) {
                print STDERR "DELETED hot name '$o' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  OLD LINE: $rec->{old_line}";
                print STDERR "  SKIPPING UNSAFELY\n\n";
            }
            next;
        }
        # Created: plus-only
        if (@$new_names && !@$old_names) {
            for my $n (@$new_names) {
                print STDERR "CREATED hot name '$n' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  NEW LINE: $rec->{new_line}";
                print STDERR "  SKIPPING UNSAFELY\n\n";
            }
            next;
        }
        # One-to-one mapping: strict only for C++ (.cpp/.h) suffixes
        if (@$old_names == @$new_names) {
            if ($suffix eq 'cpp' or $suffix eq 'h') {
                # strict context check: remove diff markers and hot names
                my ($ol, $nl) = ($rec->{old_line}, $rec->{new_line});
                $ol =~ s/^[-+]//; $nl =~ s/^[-+]//;
                chomp $ol; chomp $nl;
                for my $i (0 .. $#$old_names) {
                    my $o_pat = quotemeta $old_names->[$i];
                    my $n_pat = quotemeta $new_names->[$i];
                    $ol =~ s/\b$o_pat\b//g;
                    $nl =~ s/\b$n_pat\b//g;
                }
                $ol =~ s/\s+/ /g; $ol =~ s/^\s+|\s+$//g;
                $nl =~ s/\s+/ /g; $nl =~ s/^\s+|\s+$//g;
                if ($ol ne $nl) {
                    # contexts differ: record deletion+creation, skip pairing
                    for my $o (@$old_names) {
                        print STDERR "DELETED hot name '$o' under suffix '$suffix' in diff '$diff_path':\n";
                        print STDERR "  OLD LINE: $rec->{old_line}";
                        print STDERR "  SKIPPING UNSAFELY\n\n";
                    }
                    for my $n (@$new_names) {
                        print STDERR "CREATED hot name '$n' under suffix '$suffix' in diff '$diff_path':\n";
                        print STDERR "  NEW LINE: $rec->{new_line}";
                        print STDERR "  SKIPPING UNSAFELY\n\n";
                    }
                    next;
                }
                # contexts match: emit rename pairs
                for my $i (0 .. $#$old_names) {
                    push @$pairs_ref, {
                        old       => $old_names->[$i],
                        new       => $new_names->[$i],
                        old_line  => $rec->{old_line},
                        new_line  => $rec->{new_line},
                        diff_file => $rec->{diff_file},
                        suffix    => $rec->{suffix},
                    };
                }
            }
            else {
                # for non-C++ files, accept any equal-length mapping
                for my $i (0 .. $#$old_names) {
                    push @$pairs_ref, {
                        old       => $old_names->[$i],
                        new       => $new_names->[$i],
                        old_line  => $rec->{old_line},
                        new_line  => $rec->{new_line},
                        diff_file => $rec->{diff_file},
                        suffix    => $rec->{suffix},
                    };
                }
            }
        }
        else {
            warn "SKIPPING MISMATCHED LINE for kind=$rec->{kind}: "
               . scalar(@$old_names) . " old vs " . scalar(@$new_names) . " new\n"
               . "  OLD LINE: " . ($rec->{old_line}//'')
               . "  NEW LINE: " . ($rec->{new_line}//'') . "\n";
        }
    }
    @$records_ref = ();
}

# recursively find all files under lib/Perl/Structure
my @files_unsorted;
find(
    sub { push @files_unsorted, $File::Find::name if -f and $File::Find::name =~ m{^lib/Perl/Structure/} },
    'lib/Perl/Structure'
);

my @files = sort @files_unsorted;
# global accumulator of all hot-name pairs across files for conflict origin lookup
my @all_pairs;
#print 'have @files = ', Dumper(\@files), "\n";

my $outroot = "bin/dev/perl_types_refactor_names/$baseline";
# remove any existing baseline snapshot to avoid stale or partial data
if (-d $outroot) {
    remove_tree($outroot) or die "Cannot remove old snapshot directory '$outroot': $!";
}

# hot strings
my @hot_strings = qw(
    AV
    HV
    RV
    av
    hv
    rv
    Sv
    arrayref
    array
    hashref
    hash
    unordered_map
    umap
    vector
);
my $hot_strings_joined = join('|', @hot_strings);
my $hot_strings_re = qr/(?:$hot_strings_joined)/;
#print Dumper($hot_strings_re);

# these hot names are symmetric and thus should not change
my @symmetric_hot_names = qw(
    input_avref_avref
    input_hvref_hvref
    output_avref_avref
    output_hvref_hvref
    input_vector_vector
    output_vector_vector
);

# false-positive matches to ignore (non-hot names),
# including 1-D names which do not require any reversals or double-colons
my @not_hot_names = qw(
    std::vector
    std::unordered_map
    SvRV
    newSVrv
    newAV
    newHV
    newRV_inc
    newRV_noinc
    AVRVHE
    arrays
    hashes
    new_array
    new_hash
    temp_array
    temp_av
    input_av
    input_hv
    input_avref
    input_hvref
    input_umap
    input_vector
    output_av
    output_hv
    output_avref
    output_hvref
    output_umap
    output_vector
    av_len
    av_fetch
    av_push
    hv_fetch
    hv_iterinit
    hv_iternext
    hv_iterval
    hv_iterkeysv
    hv_store
    hashentry_CHECK
    hashentry_CHECKTRACE
    have
    reserve
);

# hard-coded hot names to override parser misses (suffix => { old => new, ... })
my %hot_names_hard_coded = (
    'cpp' => {
        'XS_unpack_integer_hashref_arrayref' => 'XS_unpack_arrayref_hashref_integer',
        'XS_unpack_number_hashref_arrayref'  => 'XS_unpack_arrayref_hashref_number',
        'XS_unpack_string_hashref_arrayref'  => 'XS_unpack_arrayref_hashref_string',
    },
    'h' => {
        'XS_unpack_integer_hashref_arrayref' => 'XS_unpack_arrayref_hashref_integer',
        'XS_unpack_number_hashref_arrayref'  => 'XS_unpack_arrayref_hashref_number',
        'XS_unpack_string_hashref_arrayref'  => 'XS_unpack_arrayref_hashref_string',
    },
);

# hot-name typos: exact minus diff-line (no trailing newline) => [[typo, correction], [typo, correction], ...]
my %hot_name_typos = (
    # DEV NOTE: must use q!...! as quotations due to both double & single quotes present in CHECKTRACE strings

    # these XS_unpack lines in the file `lib/Perl/Structure/Array/SubTypes2D.h`
    # originally had `input_avref_avref` instead of `input_avref_hvref`
    '-integer_hashref_arrayref XS_unpack_integer_hashref_arrayref(SV* input_avref_avref);' =>
        [['input_avref_avref', 'input_avref_hvref']],
    '-number_hashref_arrayref XS_unpack_number_hashref_arrayref(SV* input_avref_avref);'  =>
        [['input_avref_avref', 'input_avref_hvref']],
    '-string_hashref_arrayref XS_unpack_string_hashref_arrayref(SV* input_avref_avref);'  =>
        [['input_avref_avref', 'input_avref_hvref']],

    # these number type-checking lines in the file `lib/Perl/Structure/Hash/SubTypes2D.cpp`
    # originally had `EIVAVRVHE00` instead of `ENVAVRVHE00`
    '-        if (possible_number_arrayref_hashentry == NULL) { croak("\nERROR EIVAVRVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber_arrayref_hashentry value expected but undefined/null value found,\ncroaking"); }' =>
        [['EIVAVRVHE00', 'EHVRVAVRVNVHE00']],
    q!-        if (possible_number_arrayref_hashentry == NULL) { croak("\nERROR EIVAVRVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber_arrayref_hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }! =>
        [['EIVAVRVHE00', 'EHVRVAVRVNVHE00']],

    # these number type-checking lines in the file `lib/Perl/Structure/Hash/SubTypes2D.cpp`
    # originally had `EPVAVRVHE00` instead of `ENVAVRVHE00`
    '-        if (possible_string_arrayref_hashentry == NULL) { croak("\nERROR EIVAVRVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring_arrayref_hashentry value expected but undefined/null value found,\ncroaking"); }' =>
        [['EIVAVRVHE00', 'EHVRVAVRVPVHE00']],
    q!-        if (possible_string_arrayref_hashentry == NULL) { croak("\nERROR EIVAVRVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring_arrayref_hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }! =>
        [['EIVAVRVHE00', 'EHVRVAVRVPVHE00']],

    # these XS_pack lines in the file `lib/Perl/Structure/Hash/SubTypes2D.h`
    # originally had `input_vector_unordered_map` instead of `input_unordered_map_unordered_map`
    '-void XS_pack_integer_hashref_hashref(SV* output_hvref_hvref, integer_hashref_hashref input_vector_unordered_map);' =>
        [['input_vector_unordered_map', 'input_umap_umap']],
    '-void XS_pack_number_hashref_hashref(SV* output_hvref_hvref, number_hashref_hashref input_vector_unordered_map);' =>
        [['input_vector_unordered_map', 'input_umap_umap']],
    '-void XS_pack_string_hashref_hashref(SV* output_hvref_hvref, string_hashref_hashref input_vector_unordered_map);' =>
        [['input_vector_unordered_map', 'input_umap_umap']],

    # these integer type-checking lines in the file `lib/Perl/Structure/Array/SubTypes1D.cpp`
    # originally had `*integer_hashref*` instead of `*integer_arrayref*`
    '-//      integer_CHECKTRACE(*input_av_element, (char*)((string)"*input_av_element at index " + to_string(i)).c_str(), "XS_unpack_integer_hashref()");' =>
        [['XS_unpack_integer_hashref', 'XS_unpack_arrayref_integer']],
    '-//      integer_CHECKTRACE(*input_av_element, (char*)((string)"*input_av_element at index " + to_string(i)).c_str(), "integer_hashref_to_string()");' =>
        [['integer_hashref_to_string', 'arrayref_integer_to_string']],

    # this comment line in the file `lib/Perl/Structure/Hash/SubTypes2D.pm`
    # originall had `*_arrayref_hashref_typetest*` instead of `TYPE_arrayref_hashref_typetestX`
    '-# for *_CHECK*() used in *_arrayref_hashref_typetest*()' =>
        [['_arrayref_hashref_typetest', 'hashref_arrayref_TYPE_typetestX']],

    # this comment in the file `Perl/Structure/Array/SubTypes1D.pm`
    # originally had `*_arrayref_typetest1` instead of `TYPE_arrayref_typetest1`;
    # DEV NOTE: there is a trailing space on the old line, must include below to match correctly!
    '-use Perl::Type::Integer;  # for integer_CHECKTRACE(), used in *_arrayref_typetest1() ' =>
        [['_arrayref_typetest1', 'arrayref_TYPE_typetest1']],

    # this comment line in the file `lib/Perl/Structure/Array/SubTypes2D.pm`
    # originally had `*_arrayref_arrayref` and `*_hashref_arrayref`
    # instead of `TYPE_arrayref_arrayref` & `TYPE_hashref_arrayref`
    '-# START HERE: implement integer_arrayref_arrayref_CHECK*() & integer_arrayref_arrayref_to_string() & integer_arrayref_arrayref_typetest*() as in Hash/SubTypes.pm, then *_arrayref_arrayref, then *_hashref_arrayref' =>
        [['_arrayref_arrayref', 'arrayref_arrayref_TYPE'],
         ['_hashref_arrayref', 'arrayref_hashref_TYPE']],

    # this comment in the file `Perl/Structure/Hash/SubTypes1D.pm`
    # originally had `*_hashref_typetest1` instead of `TYPE_hashref_typetest1`;
    '-use Perl::Type::Integer;  # for integer_CHECKTRACE(), used in *_hashref_typetest1()' =>
        [['_hashref_typetest1', 'hashref_TYPE_typetest1']],
);  # end %hot_name_typos

for my $file (@files) {
    # determine file suffix
    my ($suffix) = $file =~ /\.([^\.]+)$/;  # must have parentheses around $suffix to avoid wrong values

    # determine output path under baseline snapshot
    my $baseline_path = "$outroot/$file";
    my ($baseline_dir) = $baseline_path =~ m{^(.+)/[^/]+$};
    make_path($baseline_dir);

    # save baseline version
    open my $baseline_filehandle_in, '-|', "git show $baseline:$file" or next;
    open my $baseline_filehandle_out, '>', $baseline_path or die $!;
    print $baseline_filehandle_out $_ while <$baseline_filehandle_in>;
    close $baseline_filehandle_out;
    close $baseline_filehandle_in;

    # generate unified diff between baseline and current file
    my $diff_path = "$baseline_path.diff";
    open my $diff_filehandle_out, '>', $diff_path
        or die "Cannot open '$diff_path' for writing: $!";
    # run diff as external command, capturing its output
    open my $diff_filehandle_in, '-|', 'diff', '-u', $baseline_path, $file
        or warn "Failed to exec diff on '$baseline_path' vs '$file': $!" and next;
    while (my $line = <$diff_filehandle_in>) {
        print $diff_filehandle_out $line;
    }
    close $diff_filehandle_in;
    close $diff_filehandle_out;
    # parse diff for hot names into per-line records
    open my $diff_path_filehandle_in, '<', $diff_path or next;
    my @records;
    my @pairs;
    while (my $line = <$diff_path_filehandle_in>) {
        # hunk boundary: flush previous hunk's records
        if ($line =~ /^@@/) {
            _flush_records(\@records, \@pairs, $suffix, $diff_path);
            next;
        }
        # only consider removed ('-') or added ('+') lines
        my $sign = substr($line, 0, 1);
        next unless $sign eq '-' or $sign eq '+';
        my $content = substr($line, 1);
        # DO NOT skip commented code changes; there are still lots of hot strings inside comments!
#        next if $content =~ /^\s*#/;
        # find all hot names (full user-defined identifiers) and select those containing any hot substring
        my @found_hot_names;
        while ($content =~ /\b([A-Za-z_:][A-Za-z0-9_:]*)\b/g) {
            my $possible_hot_name = $1;
            # a hot name must contain a hot string plus other characters,
            # but not be in @not_hot_names or @symmetric_hot_names
            next unless $possible_hot_name =~ /$hot_strings_re/;  # require one hot string to match
            next if grep { $_ eq $possible_hot_name } @hot_strings;  # require more chars than just hot string
            next if grep { $_ eq $possible_hot_name } @symmetric_hot_names;  # skip symmetric hot names
            next if grep { $_ eq $possible_hot_name } @not_hot_names;  # disallow forbidden non-hot names
            push @found_hot_names, $possible_hot_name;
        }
        next unless @found_hot_names;
        # determine change kind to group records by type
        my $kind = do {
            if    ($content =~ /^\s*typedef\b/)       { 'typedef' }
            elsif ($content =~ /\bXS_unpack_/)        { 'xs_unpack' }
            elsif ($content =~ /\bXS_pack_/)          { 'xs_pack' }
            elsif ($content =~ /_to_string\b/)        { 'to_string' }
            elsif ($content =~ /_typetest/)           { 'typetest' }
            elsif ($content =~ /_CHECK(?:TRACE)?\b/)   { 'check' }
            else                                        { 'other' }
        };
        # debug: show extracted hot names and classification
        print STDERR "DEBUG: diff line ($sign) kind='$kind' content: $content";
        print STDERR "DEBUG: extracted hot names: (" . join(", ", @found_hot_names) . ")\n";
        # group minus/plus lines with FIFO pairing inside each hunk
        if ($sign eq '-') {
            # record deletion-only entry
            push @records, {
                kind      => $kind,
                old       => [@found_hot_names],
                old_line  => $line,
                diff_file => $diff_path,
                suffix    => $suffix,
            };
        } else {
            # FIFO pairing: match to first unmatched deletion of same kind
            if (my ($record) = grep { $_->{kind} eq $kind && !exists $_->{new} } @records) {
                $record->{new}      = [@found_hot_names];
                $record->{new_line} = $line;
            } else {
                # record creation-only entry
                push @records, {
                    kind      => $kind,
                    old       => [],
                    old_line  => undef,
                    new       => [@found_hot_names],
                    new_line  => $line,
                    diff_file => $diff_path,
                    suffix    => $suffix,
                };
            }
        }
    }
    close $diff_path_filehandle_in;

    # flush any remaining records from last hunk
    _flush_records(\@records, \@pairs, $suffix, $diff_path);

    # collect this file's valid pairs for cross-file conflict tracking
    push @all_pairs, @pairs;

    # align old/new pairs and populate refactor_names_map
    ENTRY: for my $entry (@pairs) {
        # TYPO: skip known one-off hot-name corrections
        (my $line = $entry->{old_line}) =~ s/\n\z//;
        if (my $pairs = $hot_name_typos{$line}) {
            for my $pair (@$pairs) {
                my ($typo, $correct) = @$pair;
                if ($entry->{old} eq $typo && $entry->{new} eq $correct) {
                    print STDERR "TYPO detected hot name '$typo' under suffix '$suffix' in diff '$entry->{diff_file}':\n";
                    print STDERR "  OLD LINE: $entry->{old_line}";
                    print STDERR "  NEW LINE: $entry->{new_line}";
                    print STDERR "  HOT NAME: $typo\n";
                    print STDERR "  SKIPPING SAFELY\n\n";
                    next ENTRY;
                }
            }
        }
        next unless defined $entry->{old};
        my $old_name = $entry->{old};
        my $new_name = $entry->{new};
        # first encounter, hot name mapping does not yet exist
        if (! exists $refactor_names_map{$suffix}{$old_name}) {
            # new hot name mapping found, store it
            if ($old_name ne $new_name) {
                print STDERR "Matched hot name '$old_name' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  OLD LINE: $entry->{old_line}";
                print STDERR "  NEW LINE: $entry->{new_line}";
                print STDERR "  OLD NAME: $old_name\n";
                print STDERR "  NEW NAME: $new_name\n\n";
                $refactor_names_map{$suffix}{$old_name} = $new_name;
            }
            # unchanged hot name found, prompt or skip
            else {
                print STDERR "UNCHANGED hot name '$old_name' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  OLD LINE: $entry->{old_line}";
                print STDERR "  NEW LINE: $entry->{new_line}";
                print STDERR "  OLD NAME: $old_name\n";

                # if interactive UI, prompt for a new hot name and store it
                if ($interactive_UI) {
                    # use Term::ReadLine to prompt with default
                    my $prompt = "  NEW NAME? ";
                    $new_name = $term->readline($prompt, $old_name);
                    print STDERR "\n";
                    $refactor_names_map{$suffix}{$old_name} = $new_name;
                }
                # non-interactive UI, no way to know what this hot name should map to, no choice but to skip it
                else {
                    print STDERR "  NEW NAME UNKNOWN, SKIPPING UNSAFELY\n\n";
                }
            }
        }
        # subsequent encounters, hot name mapping already exists
        else {
            my $new_existing = $refactor_names_map{$suffix}{$old_name};
            # retrieve the first new_line associated with the existing mapping
            # only consider pairs with both old and new defined to avoid warnings
            my ($orig_pair) = grep {
                defined($_->{old}) && defined($_->{new})
                && $_->{suffix}  eq $suffix
                && $_->{old}     eq $old_name
                && $_->{new}     eq $new_existing
            } @all_pairs;
            my $new_existing_line = $orig_pair ? $orig_pair->{new_line} : '';
            chomp $new_existing_line;
            # capture original old line for conflict comparison
            my $old_existing_line = $orig_pair ? $orig_pair->{old_line} : '';
            chomp $old_existing_line;
            # record diff file paths for original and current mappings
            my $old_diff_path = $orig_pair && $orig_pair->{diff_file} ? $orig_pair->{diff_file} : '';
            my $new_diff_path = $entry->{diff_file};

            # detect hot names that should be changed but aren't yet;
            # already have this hot name mapping, can safely skip with no action required
            if ($new_name eq $old_name) {
                print STDERR "CHANGEABLE hot name '$old_name' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  OLD LINE:  $entry->{old_line}";
                print STDERR "  NEW LINE1: $new_existing_line\n";
                print STDERR "  NEW LINE2: $entry->{new_line}";
                print STDERR "  OLD NAME:  $old_name\n";
                print STDERR "  NEW NAME1: $new_existing\n";
                print STDERR "  NEW NAME2: $new_name\n";
                print STDERR "  SKIPPING SAFELY\n\n";
            }
            # detect conflicts that have one old hot name with multiple new hot names
            elsif ($refactor_names_map{$suffix}{$old_name} ne $new_name) {
                print STDERR "CONFLICTED hot name '$old_name' under suffix '$suffix':\n";
                print STDERR "  OLD DIFF:  $old_diff_path\n";
                print STDERR "  NEW DIFF:  $new_diff_path\n";
                print STDERR "  OLD LINE1: $old_existing_line\n";
                print STDERR "  NEW LINE1: $new_existing_line\n";
                print STDERR "  OLD LINE2: $entry->{old_line}";
                print STDERR "  NEW LINE2: $entry->{new_line}";
                print STDERR "  OLD NAME:  $old_name\n";
                print STDERR "  NEW NAME1: $new_existing\n";
                print STDERR "  NEW NAME2: $new_name\n";
                # if non-interactive UI, default to keeping existing (first) new name
                # by simply not updating %refactor_names_map
                if (not $interactive_UI) {
                    print STDERR "  NEW NAME:  $new_existing  [ KEEPING EXISTING NEW NAME1]\n";
                    print STDERR "  NEW NAME CONFLICT, SKIPPING UNSAFELY\n\n";
                }
                # if interactive UI, prompt for which of the two hot names to use
                else {
                    print STDERR "  NEW NAME?  ";
                    chomp(my $chosen = <STDIN>);
                    print STDERR "\n";
                    $refactor_names_map{$suffix}{$old_name} = $chosen;
                }
            }
            # exact repeat of existing hot name mapping, can safely skip with no action required
            else {
                print STDERR "Re-matched hot name '$old_name' under suffix '$suffix' in diff '$diff_path':\n";
                print STDERR "  OLD LINE: $entry->{old_line}";
                print STDERR "  NEW LINE: $entry->{new_line}";
                print STDERR "  OLD NAME: $old_name\n";
                print STDERR "  NEW NAME: $new_name\n";
                print STDERR "  SKIPPING SAFELY\n\n";
            }
        }
    }
}

# merge in hard-coded hot-name mappings after parsing all diffs
for my $suffix (keys %hot_names_hard_coded) {
    for my $old_name (keys %{ $hot_names_hard_coded{$suffix} }) {
        my $new_name = $hot_names_hard_coded{$suffix}{$old_name};
        if (exists $refactor_names_map{$suffix}{$old_name}) {
            print STDERR "HARD-CODED CLOBBER hot name '$old_name' under suffix '$suffix':\n";
            print STDERR "  OLD NAME:  $old_name\n";
            print STDERR "  NEW NAME1: $refactor_names_map{$suffix}{$old_name}  (existing)\n";
            print STDERR "  NEW NAME2: $new_name  (hard-coded)\n";
        }
        $refactor_names_map{$suffix}{$old_name} = $new_name;
    }
}

# dump to Perl module
my $mapfile = 'bin/dev/perl_types_refactor_names_map.pm';
open my $map_filehandle_out, '>', $mapfile or die $!;
print $map_filehandle_out 'package Perl::Types::RefactorNamesMap;', "\n",
           'use strict; use warnings;', "\n",
           'our $refactor_names_map = ';
print $map_filehandle_out Dumper(\%refactor_names_map);
print $map_filehandle_out ";\n1;\n";
close $map_filehandle_out;

exit 0;
