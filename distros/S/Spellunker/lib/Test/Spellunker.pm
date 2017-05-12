package Test::Spellunker;
use strict;
use warnings;
use 5.008001;

use Spellunker::Pod;

use parent qw(Exporter);

use version; our $VERSION = version->declare("v0.4.0");

use Test::Builder;
use File::Spec;

our $SPELLUNKER = Spellunker::Pod->new();

our @EXPORT = qw(
  pod_file_spelling_ok
  all_pod_files_spelling_ok
  add_stopwords
  load_dictionary
);

my $TEST = Test::Builder->new();

sub all_pod_files_spelling_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @files = all_pod_files(@_);

    $TEST->plan(tests => scalar @files);

    my $ok = 1;
    for my $file (@files) {
        pod_file_spelling_ok($file) or undef $ok;
    }
    return $ok;
}

sub _starting_points {
    return 'blib' if -d 'blib';
    return grep -d, qw(bin lib script);
}

sub all_pod_files {
    my @queue = @_ ? @_ : _starting_points();
    my @pod;

    while (@queue) {
        my $file = shift @queue;

        # recurse into subdirectories
        if (-d $file) {
            opendir(my $dirhandle, $file) or next;
            my @newfiles = readdir($dirhandle);
            closedir $dirhandle;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }

        # add the file if it meets our criteria
        if (-f $file) {
            next unless _is_perl($file);
            push @pod, $file;
        }
    }

    return @pod;
}

sub _is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|lx|m|od)$/;
    return 1 if $file =~ /\.t$/;

    open my $handle, '<', $file or return;
    my $first = <$handle>;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return 0;
}

sub pod_file_spelling_ok {
    my $file = shift;
    my $name = shift || "POD spelling for $file";

    if ( !-r $file ) {
        $TEST->ok( 0, $name );
        $TEST->diag("$file does not exist or is unreadable");
        return;
    }

    my @err = $SPELLUNKER->check_file($file);

    my $ok = @err == 0;
    $TEST->ok($ok, "$name");
    if (!$ok) {
        my $msg = "Errors:\n";
        for (@err) {
            my ($lineno, $line, $errs) = @$_;
            for my $err (@$errs) {
                $msg .= "    $lineno: $err\n";
            }
        }
        $TEST->diag($msg);
    }

    return $ok;
}

sub add_stopwords {
    $SPELLUNKER->add_stopwords(@_);
}

sub load_dictionary {
    $SPELLUNKER->load_dictionary(@_);
}


1;
__END__

=for stopwords pl plx pm spellchecker dirs ll spellcheck

=head1 NAME

Test::Spellunker - check for spelling errors in POD files

=head1 SYNOPSIS

    use Test::Spellunker;
    all_pod_files_spelling_ok();

=head1 FUNCTIONS

=over 4

=item all_pod_files_spelling_ok( [@files/@directories] )

Checks all the files for POD spelling. It gathers all_pod_files() on
each file/directory, and declares a "plan" in Test::More for you (one
test for each file), so you must not call "plan" yourself.

If @files is empty, the function finds all POD files in the blib
directory; or the lib, bin and scripts directories if blib does not exist.
A POD file is one that ends with .pod, .pl, .plx, or .pm; or any file
where the first line looks like a perl shebang line.

If you're testing a distribution, just create a t/pod-spell.t with the
code in the "SYNOPSIS".

Returns true if every POD file has correct spelling, or false if any of
them fail.  This function will show any spelling errors as diagnostics.

=item pod_file_spelling_ok( $filename[, $testname ] )

"pod_file_spelling_ok" will test that the given POD file has no
spelling errors.

When it fails, "pod_file_spelling_ok" will show any spelling errors as
diagnostics.

The optional second argument is the name of the test.  If it is
omitted, "pod_file_spelling_ok" chooses a default test name "POD
spelling for $filename".

=item all_pod_files( [@dirs] )

Returns a list of all the Perl files in each directory and its
subdirectories, recursively. If no directories are passed, it defaults
to blib if blib exists, or else lib if not. Skips any files in CVS or
.svn directories.


A Perl file is:

   Any file that ends in .PL, .pl, .plx, .pm, .pod or .t.
   Any file that has a first line with a shebang and "perl" on it.

Furthermore, files for which the filter set by "set_pod_file_filter"
return false are skipped. By default, this filter passes everything
through.

The order of the files returned is machine-dependent.  If you want them
sorted, you'll have to sort them yourself.

=item add_stopwords(@words)

Add words that should be skipped by the spellcheck. Note that
Pod::Spell already skips words believed to be code, such as everything
in verbatim (indented) blocks and code marked up with ""..."", as well
as some common Perl jargon.

=item load_dictionary($filename_or_fh)

Load stopwords from C<$filename_or_fh>. You may want to use it as C<< load_dictionary(\*DATA) >>.

=back

=head1 HOW DO I ADD FILE SPECIFIC STOPWORDS?

You can put it by following style POD annotation.

    __END__

    =for stopwords foo bar

    =head1 NAME

    ...

=head1 THANKS TO

Inspired from L<Test::Spelling>. And most of document was taken from L<Test::Spelling>.

