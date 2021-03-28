# Helper functions to test POD formatters with snippets.
#
# This module is an internal implementation detail of the module test suite.
# It provides some supporting functions to make it easier to write tests.
#
# SPDX-License-Identifier: MIT

package Test::Snippets 1.00;

use 5.012;
use autodie;
use strict;
use warnings;

use Encode qw(decode encode);
use Exporter qw(import);
use File::Spec;
use Perl6::Slurp qw(slurp);
use Test::More;

# Exported functions.
our @EXPORT_OK = qw(list_snippets read_snippet test_snippet);

# The file handle used to capture STDERR while we mess with file descriptors.
my $OLD_STDERR;

# The file name used to capture standard error output.
my $SAVED_STDERR;

# Internal function to clean up the standard error output file.  Leave the
# temporary directory in place, since otherwise we race with other test
# scripts trying to create the temporary directory when running tests in
# parallel.
sub _stderr_cleanup {
    if ($SAVED_STDERR && -e $SAVED_STDERR) {
        unlink($SAVED_STDERR);
    }
    return;
}

# Remove saved standard error on exit, even if we have an abnormal exit.
END {
    _stderr_cleanup();
}

# Internal function to redirect stderr to a file.  Stores the name in
# $SAVED_STDERR.
sub _stderr_save {
    my $tmpdir = File::Spec->catdir('t', 'tmp');
    if (!-d $tmpdir) {
        mkdir($tmpdir, 0777);
    }
    my $path = File::Spec->catfile($tmpdir, "out$$.err");

    ## no critic(InputOutput::RequireBriefOpen)
    open($OLD_STDERR, '>&', \*STDERR);
    open(STDERR,      '>',  $path);
    ## use critic

    $SAVED_STDERR = $path;
    return;
}

# Internal function to restore stderr.
#
# Returns: The contents of the stderr file.
sub _stderr_restore {
    return if !$SAVED_STDERR;
    close(STDERR);
    open(STDERR, '>&', $OLD_STDERR);
    close($OLD_STDERR);
    my $stderr = slurp($SAVED_STDERR);
    _stderr_cleanup();
    return $stderr;
}

# List the snippets available under a path relative to t/data/snippets.  Files
# starting with . or named README.md are ignored.
#
# $path - Relative path to read snippets from, or undef for the top level
#
# Returns: List of names of snippet files under that path
sub list_snippets {
    my ($path) = @_;
    if (defined($path)) {
        $path = File::Spec->catdir('t', 'data', 'snippets', $path);
    } else {
        $path = File::Spec->catdir('t', 'data', 'snippets');
    }
    opendir(my $dir, $path);
    my @snippets = grep { $_ ne 'README.md' && !m{ \A [.] }xms } readdir($dir);
    closedir($dir);
    return @snippets;
}

# Read one test snippet from the provided relative file name and return it.
# For the format, see t/data/snippets/README.
#
# $path - Relative path to read test data from
#
# Returns: Reference to hash of test data with the following keys:
#            name      - Name of the test for status reporting
#            options   - Hash of options
#            input     - The input block of the test data
#            output    - The output block of the test data
#            errors    - Expected errors
#            exception - Text of exception (with file and line stripped)
sub read_snippet {
    my ($path) = @_;
    $path = File::Spec->catfile('t', 'data', 'snippets', $path);
    my %data;

    # Read the sections and store them in the %data hash.
    my ($line, $section);
    open(my $fh, '<', $path);
    while (defined($line = <$fh>)) {
        if ($line =~ m{ \A \s* \[ (\S+) \] \s* \z }xms) {
            $section = $1;
            $data{$section} = q{};
        } elsif ($section) {
            $data{$section} .= $line;
        }
    }
    close($fh);

    # Strip trailing blank lines from all sections.
    for my $section (keys %data) {
        $data{$section} =~ s{ \n\s+ \z }{\n}xms;
    }

    # Clean up the name section by removing newlines and extra space.
    if ($data{name}) {
        $data{name} =~ s{ \A \s+ }{}xms;
        $data{name} =~ s{ \s+ \z }{}xms;
        $data{name} =~ s{ \s+ }{ }xmsg;
    }

    # Turn the options section into a hash.
    if ($data{options}) {
        my @lines = split(m{ \n }xms, $data{options});
        delete $data{options};
        for my $optline (@lines) {
            next if $optline !~ m{ \S }xms;
            my ($option, $value) = split(q{ }, $optline, 2);
            if (defined($value)) {
                chomp($value);
            } else {
                $value = q{};
            }
            $data{options}{$option} = $value;
        }
    }

    # Return the results.
    return \%data;
}

# Test a formatter on a particular POD snippet.  This does all the work of
# loading the snippet, creating the formatter, running it, and checking the
# results, and reports those results with Test::More.
#
# $class       - Class name of the formatter, as a string
# $snippet     - Path to the snippet file defining the test
# $options_ref - Hash of options with the following keys:
#   encoding - Expect the output to be in this non-standard encoding
sub test_snippet {
    my ($class, $snippet, $options_ref) = @_;
    my $data_ref = read_snippet($snippet);

    # Determine the encoding to expect for the output portion of the snippet.
    my $encoding;
    if (defined($options_ref)) {
        $encoding = $options_ref->{encoding};
    }
    $encoding ||= 'UTF-8';

    # Create the formatter object.
    my $parser = $class->new(%{ $data_ref->{options} }, name => 'TEST');
    isa_ok($parser, $class, 'Parser object');

    # Save stderr to a temporary file and then run the parser, storing the
    # output into a Perl variable.
    my $errors = _stderr_save();
    my $got;
    $parser->output_string(\$got);
    eval { $parser->parse_string_document($data_ref->{input}) };
    my $exception = $@;
    my $stderr    = _stderr_restore();

    # Strip any trailing blank lines.
    $got =~ s{ \n\s+ \z }{\n}xms;

    # Check the output, errors, and any exception.
    is($got, $data_ref->{output}, "$data_ref->{name}: output");
    if ($data_ref->{errors} || $stderr) {
        is($stderr, $data_ref->{errors} || q{}, "$data_ref->{name}: errors");
    }
    if ($data_ref->{exception} || $exception) {
        if ($data_ref->{exception} && $exception) {
            $exception =~ s{ [ ] at [ ] .* }{\n}xms;
        }
        is($exception, $data_ref->{exception}, "$data_ref->{name}: exception");
    }
    return;
}

1;
__END__

=for stopwords
Allbery podlators PerlIO UTF-8 formatter FH whitespace

=head1 NAME

Test::Snippets - Helper functions to test POD formatters with snippets

=head1 SYNOPSIS

    use Test::Snippets qw(list_snippets test_snippet);

    for my $snippet (list_snippets()) {
        test_snippet('Pod::Thread', $snippet);
    }

=head1 DESCRIPTION

This module collects various utility functions that are useful for writing
test cases for a POD formatter.  It is not intended to be, and probably isn't,
useful outside of the test suite for a module.

=head1 FUNCTIONS

None of these functions are imported by default.  The ones used by a script
should be explicitly imported.

=over 4

=item list_snippets([PATH])

Return a list of all snippet files in the given PATH, which should be relative
to F<t/data/snippets>.  PATH may be omitted to use the F<t/data/snippets>
directory.  A file named F<README.md> in that directory will be ignored, as
are files starting with a period (C<.>).

=item read_snippet(PATH)

Read one test snippet from the provided relative file name and return it.  The
path should be relative to F<t/data/snippets>.  For the format, see
F<t/data/snippets/README>.

The result will be a hash with the following keys:

=over 4

=item name

The name of the test, for reporting purposes.

=item options

A hash of any options to values, if any options were specified.

=item input

Input POD to try formatting.

=item output

The expected output.

=item errors

Expected errors from the POD formatter.

=item exception

An expected exception from the POD formatter, with the file and line
information stripped from the end of the exception.

=back

=item test_snippet(CLASS, SNIPPET[, OPTIONS])

Test a formatter on a particular POD snippet.  This does all the work of
loading the snippet, creating the formatter by instantiating CLASS, running
it, and checking the results.  Results are reported with Test::More.

OPTIONS, if present, is a reference to a hash of options.  Currently, only
one key is supported: C<encoding>, which, if set, specifies the encoding of
the output portion of the snippet.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016, 2018-2021 Russ Allbery <rra@cpan.org>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
