package Test::Compile;

use warnings;
use strict;

use version; our $VERSION = qv("v2.1.1");
use parent 'Exporter';
use UNIVERSAL::require;
use Test::Compile::Internal;

my $Test = Test::Compile::Internal->new();

=head1 NAME

Test::Compile - Check whether Perl files compile correctly.

=head1 SYNOPSIS

    use Test::Compile;

    # The OO way (recommended)
    my $test = Test::Compile->new();
    $test->all_files_ok();
    $test->done_testing();

    # The procedural way (deprecated)
    use Test::Compile qw( all_pm_files_ok );
    all_pm_files_ok();

=head1 DESCRIPTION

C<Test::Compile> lets you check the whether your perl modules and scripts
compile properly, and report its results in standard C<Test::Simple> fashion.

The basic usage - as shown above, will locate your perl files and test that they
all compile.

Module authors can (and probably should) include the following in a F<t/00-compile.t>
file and have C<Test::Compile> automatically find and check all Perl files
in a module distribution:

    #!perl
    use strict;
    use warnings;
    use Test::Compile;
    my $test = Test::Compile->new();
    $test->all_files_ok();
    $test->done_testing();

=cut

our @EXPORT = qw(
    pm_file_ok
    pl_file_ok

    all_pm_files_ok
    all_pl_files_ok

    all_pm_files
    all_pl_files
);
our @EXPORT_OK = qw(
    pm_file_ok
    pl_file_ok

    all_files_ok
    all_pm_files_ok
    all_pl_files_ok

    all_pm_files
    all_pl_files
);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

=head1 METHODS

=over 4

=item C<new()>

A basic constructor, nothing special except that it returns a
L<Test::Compile::Internal> object.

=cut

sub new {
    my $class = shift;
    return Test::Compile::Internal->new(@_);
}

=item C<all_files_ok(@dirs)>

Checks all the perl files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pm_files(@dirs)> and L</all_pl_files(@dirs)>.

=item C<all_pm_files(@dirs)>

Returns a list of all the perl module files - that is any files ending in F<.pm>
in C<@dirs> and in directories below. If C<@dirs> is undefined, it
searches F<blib> if F<blib> exists, or else F<lib>.

Skips any files in C<CVS>, C<.svn>, or C<.git> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.

=item C<all_pl_files(@dirs)>

Returns a list of all the perl script files - that is, any files in C<@dirs> that
either have a F<.pl> extension, or have no extension and have a perl shebang line.

If C<@dirs> is undefined, it searches F<script> if F<script> exists, or else
F<bin> if F<bin> exists.

Skips any files in C<CVS>, C<.svn>, or C<.git> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.

=item C<pl_file_compiles($file)>

Returns true if C<$file> compiles as a perl script.

=item C<pm_file_compiles($file)>

Returns true if C<$file> compiles as a perl module.

=item C<verbose($verbose)>

An accessor to get/set the verbose flag.  If C<verbose> is set, you can get some
extra diagnostics when compilation fails.

Verbose is set on by default.

=back

=head2 Test Methods

C<Test::Compile::Internal> encapsulates a C<Test::Builder> object, and provides
access to some of its methods.

=over 4

=item C<done_testing()>

Declares that you are done testing, no more tests will be run after this point.

=item C<ok($test, $name)>

Your basic test. Pass if C<$test> is true, fail if C<$test> is false. Just
like C<Test::Simple>'s C<ok()>.

=item C<plan($count)>

Defines how many tests you plan to run.

=item C<diag(@msgs)>

Prints out the given C<@msgs>. Like print, arguments are simply appended
together.

Output will be indented and marked with a # so as not to interfere with
test output. A newline will be put on the end if there isn't one already.

We encourage using this rather than calling print directly.

=item C<skip($reason)>

Skips the current test, reporting the C<$reason>.

=item C<skip_all($reason)>

Skips all the tests, using the given C<$reason>. Exits immediately with 0.

=back

=head1 FUNCTIONS

The use of the following functions is deprecated and strongly discouraged.

They are automatically exported to your namespace,  which is
no longer considered best practise.  At some stage in the future, this will
stop and you'll have to import them explicitly.

Even then, you really should use the object oriented methods as they provide
a more consistent interface.  For example: C<all_pm_files_ok()> calls the
C<plan()> function - so you can't call multiple test functions in the same test file.

You should definately use the object oriented interface described in the L</SYNOPSIS>
and in L<Test::Compile::Internal> instead of calling these functions.

=over 4

=item C<all_pm_files_ok(@files)>

Checks all the perl module files it can find for compilation errors.

It uses C<all_pm_files(@files)> to find the perl module files.

It also calls the C<plan()> function for you (one test for each module), so
you can't have already called C<plan()>. Unfortunately, this also means
you can't use this function with C<all_pl_files_ok()>.  If this is a problem
you should really be using the object oriented interface.

Returns true if all Perl module files are ok, or false if any fail.

Module authors can include the following in a F<t/00_compile.t> file
and have C<Test::Compile> automatically find and check all Perl module files
in a module distribution:

    #!perl -w
    use strict;
    use warnings;
    use Test::More;
    eval "use Test::Compile";
    Test::More->builder->BAIL_OUT(
        "Test::Compile required for testing compilation") if $@;
    my $test = Test::Compile->new();
    $test->all_pm_files_ok();
    $test->done_testing();

=cut

sub all_pm_files_ok {
    my @files = @_ ? @_ : all_pm_files();
    $Test->plan(tests => scalar @files);
    my $ok = 1;
    for (@files) {
        pm_file_ok($_) or undef $ok;
    }
    $ok;
}

=item C<all_pl_files_ok(@files)>

Checks all the perl script files it can find for compilation errors.

It uses C<all_pl_files(@files)> to find the perl script files.

It also calls the C<plan()> function for you (one test for each script), so
you can't have already called C<plan>. Unfortunately, this also means
you can't use this function with C<all_pm_files_ok()>.  If this is a problem
you should really be using the object oriented interface.

Returns true if all Perl script files are ok, or false if any fail.

Module authors can include the following in a F<t/00_compile_scripts.t> file
and have C<Test::Compile> automatically find and check all Perl script files
in a module distribution:

    #!perl -w
    use strict;
    use warnings;
    use Test::More;
    eval "use Test::Compile";
    plan skip_all => "Test::Compile required for testing compilation"
      if $@;
    my $test = Test::Compile->new();
    $test->all_pl_files_ok();
    $test->done_testing();

=cut

sub all_pl_files_ok {
    my @files = @_ ? @_ : all_pl_files();
    $Test->skip_all("no pl files found") unless @files;
    $Test->plan(tests => scalar @files);
    my $ok = 1;
    for (@files) {
        pl_file_ok($_) or undef $ok;
    }
    $ok;
}

=item C<pm_file_ok($filename, $testname)>

C<pm_file_ok()> will okay the test if $filename compiles as a perl module.

The optional second argument C<$testname> is the name of the test. If it is
omitted, C<pm_file_ok()> chooses a default test name C<Compile test for
$filename>.

=cut
sub pm_file_ok {
    my ($file, $name) = @_;

    $name ||= "Compile test for $file";

    my $ok = $Test->pm_file_compiles($file);

    $Test->ok($ok, $name);
    $Test->diag("$file does not compile") unless $ok;
    return $ok;
}

=item C<pl_file_ok($filename, $testname)>

C<pl_file_ok()> will okay the test if $filename compiles as a perl script. You
need to give the path to the script relative to this distribution's base
directory. So if you put your scripts in a 'top-level' directory called script
the argument would be C<script/filename>.

The optional second argument C<$testname> is the name of the test. If it is
omitted, C<pl_file_ok()> chooses a default test name C<Compile test for
$filename>.
=cut

sub pl_file_ok {
    my ($file, $name) = @_;

    $name ||= "Compile test for $file";

    # don't "use Devel::CheckOS" because Test::Compile is included by
    # Module::Install::StandardTests, and we don't want to have to ship
    # Devel::CheckOS with M::I::T as well.
    if (Devel::CheckOS->require) {

        # Exclude VMS because $^X doesn't work. In general perl is a symlink to
        # perlx.y.z but VMS stores symlinks differently...
        unless (Devel::CheckOS::os_is('OSFeatures::POSIXShellRedirection')
            and Devel::CheckOS::os_isnt('VMS')) {
            $Test->skip('Test not compatible with your OS');
            return;
        }
    }

    my $ok = $Test->pl_file_compiles($file);

    $Test->ok($ok, $name);
    $Test->diag("$file does not compile") unless $ok;
    return $ok;
}

=item C<all_pm_files(@dirs)>

Returns a list of all the perl module files - that is, files ending in F<.pm>
- in I<@dirs> and in directories below. If no directories are passed, it
defaults to F<blib> if F<blib> exists, or else F<lib> if not. Skips any files
in C<CVS> or C<.svn> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.

=cut

sub all_pm_files {
    return $Test->all_pm_files(@_);
}

=item C<all_pl_files(@dirs)>

Returns a list of all the perl script files - that is, any files in C<@dirs> that
either have a F<.pl> extension, or have no extension and have a perl shebang line.

If C<@dirs> is undefined, it searches F<script> if F<script> exists, or else
F<bin> if F<bin> exists.

Skips any files in C<CVS> or C<.svn> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.

=cut

sub all_pl_files {
    return $Test->all_pl_files(@_);
}

=item C<all_files_ok(@dirs)>

Checks all the perl files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pm_files(@dirs)> and L</all_pl_files(@dirs)>.

=back
=cut
sub all_files_ok {
    return $Test->all_files_ok(@_);
}

sub _verbose {
    return $Test->verbose(@_);
}

1;

=head1 AUTHORS

Sagar R. Shah C<< <srshah@cpan.org> >>,
Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>,
Evan Giles, C<< <egiles@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2019 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Compile::Internal> provides the object oriented interface to (and the
inner workings for) the Test::Compile functionality.

L<Test::Strict> provides functions to ensure your perl files compile, with
added bonus that it will check you have used strict in all your files.
L<Test::LoadAllModules> just handles modules, not script files, but has more
fine-grained control.


=cut
