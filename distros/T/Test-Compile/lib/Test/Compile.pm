package Test::Compile;

use warnings;
use strict;

use version; our $VERSION = version->declare("v3.3.3");
use parent 'Exporter';
use Test::Compile::Internal;

my $Test = Test::Compile::Internal->new();

=head1 NAME

Test::Compile - Assert that your Perl files compile OK.

=head1 SYNOPSIS

    use Test::Compile qw();

    my $test = Test::Compile->new();
    $test->all_files_ok();
    $test->done_testing();

=head1 DESCRIPTION

C<Test::Compile> lets you check the whether your perl modules and scripts
compile properly, results are reported in standard C<Test::Simple> fashion.

The basic usage - as shown above, will locate your perl files and test that they
all compile.

Module authors can (and probably should) include the following in a F<t/00-compile.t>
file and have C<Test::Compile> automatically find and check all Perl files
in a module distribution:

    #!perl
    use strict;
    use warnings;
    use Test::Compile qw();
    
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

The constructor, which actually returns a
L<Test::Compile::Internal> object.  This gives you access to all the methods provided by
C<Test::Compile::Internal>, including those listed below.

=cut

sub new {
    my $class = shift;
    return Test::Compile::Internal->new(@_);
}

=item C<all_files_ok(@dirs)>

Looks for perl files and tests them all for compilation errors.

See L<Test::Compile::Internal/all_files_ok(@dirs)> for the full documentation.

=item C<done_testing()>

Declares that you are done testing, no more tests will be run after this point.

=item C<diag(@msgs)>

Prints out the given C<@msgs>. Like print, arguments are simply appended
together.

Output will be indented and marked with a # so as not to interfere with
test output. A newline will be put on the end if there isn't one already.

We encourage using this rather than calling print directly.

=item C<skip($reason)>

Skips the current test, reporting the C<$reason>.

=back

=head1 FUNCTIONS

The use of the following functions is deprecated and strongly discouraged.

Instead, you should use the object oriented interface described in the L</SYNOPSIS>
and in L<Test::Compile::Internal>.

They are automatically exported to your namespace,  which is
no longer considered best practise.  At some stage in the future, this will
stop and you'll have to import them explicitly to keep using them.

The object oriented methods also provide a more consistent interface. 
For example: C<all_pm_files_ok()> calls the C<plan()> function - so you can't call
multiple test functions in the same test file.

=over 4

=item C<all_pm_files_ok(@files)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pm_files_ok(@dirs)> instead.  It's pretty much the
same, except it doesn't call the C<plan()> function.

Checks all the perl module files it can find for compilation errors.

It uses C<all_pm_files(@files)> to find the perl module files.

It also calls the C<plan()> function for you (one test for each module), so
you can't have already called C<plan()>. Unfortunately, this also means
you can't use this function with C<all_pl_files_ok()>.  If this is a problem
you should really be using the object oriented interface.

Returns true if all Perl module files are ok, or false if any fail.

=cut

sub all_pm_files_ok {
    my @files = @_ ? @_ : all_pm_files();
    $Test->plan(tests => scalar @files);
    return $Test->all_pm_files_ok(@files);
}

=item C<all_pl_files_ok(@files)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pl_files_ok(@dirs)> instead.  It's pretty much the
same, except it doesn't call the C<plan()> function.

Checks all the perl script files it can find for compilation errors.

It uses C<all_pl_files(@files)> to find the perl script files.

It also calls the C<plan()> function for you (one test for each script), so
you can't have already called C<plan>. Unfortunately, this also means
you can't use this function with C<all_pm_files_ok()>.  If this is a problem
you should really be using the object oriented interface.

Returns true if all Perl script files are ok, or false if any fail.

=cut

sub all_pl_files_ok {
    my @files = @_ ? @_ : all_pl_files();
    $Test->skip_all("no pl files found") unless @files;
    $Test->plan(tests => scalar @files);
    $Test->all_pl_files_ok(@files);
}

=item C<pm_file_ok($filename, $testname)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pm_files_ok(@dirs)> instead.  It's pretty much the
same, except it won't allow you to specify a test name, and it can handle more than
one file at a time.

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

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pl_files_ok(@dirs)> instead.  It's pretty much the
same, except you can't specify a test name, and it can handle more than one file at a
time.

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

    my $ok = $Test->pl_file_compiles($file);

    $Test->ok($ok, $name);
    $Test->diag("$file does not compile") unless $ok;
    return $ok;
}

=item C<all_pm_files(@dirs)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pm_files(@dirs)> instead.

Returns a list of all the perl module files - that is, files ending in F<.pm>
- in I<@dirs> and in directories below. If no directories are passed, it
defaults to F<blib> if F<blib> exists, or else F<lib> if not. Skips any files
in F<CVS>, F<.svn>, or F<.git> directories.

=cut

sub all_pm_files {
    return $Test->all_pm_files(@_);
}

=item C<all_pl_files(@dirs)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_pl_files(@dirs)> instead.

Returns a list of all the perl script files - that is, any files in C<@dirs> that
either have a F<.pl> extension, or have no extension and have a perl shebang line.

If C<@dirs> is undefined, it searches F<script> if F<script> exists, or else
F<bin> if F<bin> exists.

Skips any files in F<CVS>, F<.svn>, or F<.git> directories.

=cut

sub all_pl_files {
    return $Test->all_pl_files(@_);
}

=item C<all_files_ok(@dirs)>

B<This function is deprecated>.  Please use
L<Test::Compile::Internal/all_files_ok(@dirs)> instead.

Checks all the perl files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pm_files(@dirs)> and L</all_pl_files(@dirs)>.

=back
=cut
sub all_files_ok {
    return $Test->all_files_ok(@_);
}

1;

=head1 AUTHORS

Sagar R. Shah C<< <srshah@cpan.org> >>,
Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>,
Evan Giles, C<< <egiles@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2023 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Compile::Internal> provides the object oriented interface to (and the
inner workings for) the Test::Compile functionality.

L<Test::Strict> provides functions to ensure your perl files compile, with
the added bonus that it will check you have used strict in all your files.

L<Test::LoadAllModules> just handles modules, not script files, but has more
fine-grained control.

=cut
