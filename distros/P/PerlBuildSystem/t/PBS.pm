#!/usr/bin/env perl

=head1 C<t::PBS>

=cut

package t::PBS;

use strict;
use warnings;

use vars qw(@ISA $_exe $_path_separator);

@ISA = qw(Test::Cmd);

use Test::More;
use Test::Cmd;
use Test::Cmd::Common;
use File::Copy::Recursive qw(rcopy);

BEGIN {
	$_exe = $Test::Cmd::Common::_exe;
	$_path_separator = $^O eq "MSWin32" ? ';' : ':';
}

=begin private

=over

=item _inc_level

Used internally to make output from failing tests correct.

It increases the caller level so C<Test::Builder> prints the line when the
call was made to to the method in C<t::Pbs> as the line of failing
test, not the line in C<t::Pbs> where the C<Test::More> testing
condition was stated.

=back

=end private

=cut

sub _inc_level {
    Test::More->builder->level(Test::More->builder->level + 1);
}

=begin private

=over

=item _dec_level

The counterpart of _inc_level.

=back

=end private

=cut

sub _dec_level {
    Test::More->builder->level(Test::More->builder->level - 1);
}

my $start_cwd_global = Cwd::cwd;
my $full_pbs_path_global = $start_cwd_global . '/blib/script/pbs.pl';
unless (-e $full_pbs_path_global) {
    $full_pbs_path_global = '/usr/bin/env pbs';
}

my $flags_global = '--no_warp';
my $warp_mode_global = 'off' ;

=over

=item get_global_warp_mode

Returns the global warp mode. This method is static and can be used without an object.

=back

=cut

sub get_global_warp_mode {
    return $warp_mode_global;
}

=over

=item set_global_warp_mode

Sets the global warp mode. This method is static and can be used without an object.

=back

=cut

sub set_global_warp_mode
{
	$warp_mode_global = shift;
	if ($warp_mode_global eq 'off')
	{
		$flags_global = '--no_warp' ;
	}
	else
	{
		$flags_global = "--warp $warp_mode_global" ;
	}
}

=over

=item new

Constructor. Accepts the same arguments as the constructor in the base
class, with the exception of C<prog> and C<workdir>. C<prog> is set to
pbs, and C<workdir> is set to create a new temporary directory. First,
pbs is searched for as F<./blib/script/pbs.pl>, and if not found there,
as C</usr/bin/env pbs>. If the process is running under
C<Devel::Cover> and C<Test::Harness>, the sub Perl processes is started
with C<Devel::Cover> too, with the coverage data base path set to
F<./cover_db>. After all the preciding, the current directory is
changed to the temporary directory.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    if ($ENV{HARNESS_PERL_SWITCHES}) {
	if ($ENV{HARNESS_PERL_SWITCHES} eq '-MDevel::Cover') {
	    $ENV{'PERL5OPT'} = '-MDevel::Cover=-db,' .
	        $start_cwd_global .
		'/cover_db,-select,PBS';
	}
    }
    my $test = $class->SUPER::new(prog => $full_pbs_path_global,
				  workdir => '',
				  @_);
#    die if $test;
#    die if chdir($test->workdir);
	chdir($test->workdir);

    bless($test, $class);
}

=over

=item write

The same as in the base class, but an exception is
thrown on error.

=back

=cut

sub write {
    my $ret = shift->SUPER::write(@_);
    die unless $ret;
}

=over

=item write_pbsfile

The same as L<write>, but the file name is set to F<Pbsfile.pl>.

=back

=cut

sub write_pbsfile {
    shift->write('Pbsfile.pl', @_);
}

=over

=item command_line_flags

Sets/returns the current command line flags used when calling pbs.

=back

=cut

sub command_line_flags {
    my ($self, $flags) = @_;
    if ($flags) {
	$self->{'flags'} = $flags;
    }
    return $self->{'flags'};
}

=over

=item build_dir

Sets/returns the build directory.

=back

=cut

sub build_dir {
    my ($self, $build_dir) = @_;
    if (defined $build_dir) {
	$self->{'build_dir'} = $build_dir;
    }
    return $self->{'build_dir'};
}

=over

=item target

Sets/returns the target.

=back

=cut

sub target {
    my ($self, $target) = @_;
    if (defined $target) {
	$self->{'target'} = $target;
    }
    return $self->{'target'};
}

=over

=item get_target_with_path

Returns the target with path relative the temporary directory.

=back

=cut

sub get_target_with_path {
    my $self = shift;
    return $self->catfile($self->{'build_dir'}, $self->{'target'});
}

=over

=item build

Calls pbs with the appropriate command line arguments. If the keyword
argument C<targets> is given, the current target is not used, and
instead is this argument appended to the command line. Forwards all
given arguments to C<run> in the base class.

=back

=cut

sub build {
    my $self = shift;
    my %args = @_;
    my $flags = $self->{'flags'};
    $flags = '' unless $flags;
    my $build_dir = $self->{'build_dir'};
    if ($build_dir) {
	$build_dir = "--build_directory $build_dir";
    } else {
	$build_dir = '';
    }
    my $target = $args{'targets'};
    $target = $self->{'target'} unless $target;
    $target = '' unless $target;
    $self->SUPER::run(@_, args => "$flags $flags_global $build_dir $target");
}

=over

=item build_test

The same as build but also fails a test if the exit code from pbs is
signalling an error.

=back

=cut

sub build_test {
    my $self = shift;
    $self->build(@_);
    _inc_level;
    is($?, 0, 'Build successful');
    _dec_level;
}

=over

=item build_test_fail

The same as build but also fails a test if the exit code from pbs is
signalling success.

=back

=cut

sub build_test_fail {
    my $self = shift;
    $self->build(@_);
    _inc_level;
    isnt($?, 0, 'Build failed');
    _dec_level;
}

=over

=item run

Runs the program given as argument. The path to the program is
assumed relative the temporary directory.

=back

=cut

sub run {
    my ($self, $prog) = @_;
    $self->SUPER::run(prog => $self->catfile($self->here, $prog));
}

=over

=item run_target

Runs the current target file.

=back

=cut

sub run_target {
    my $self = shift;
    $self->run($self->get_target_with_path);
}

=over

=item run_target_test

Runs the target and tests if the standard output from the target
is equal to the keyword argument C<stdout>.

=back

=cut

sub run_target_test {
    my $self = shift;
    my %args = @_;
    $self->run_target;
    if (defined $args{'stdout'}) {
	_inc_level;
	is($self->stdout, $args{'stdout'}, 'Output from target when run');
	_dec_level;
    }
}

=over

=item test_up_to_date

Calls pbs, and fails a test if something were built.

=back

=cut

sub test_up_to_date {
    my $self = shift;
    _inc_level;
    $self->build_test(targets => $self->{'target'});
    my $up_to_date = 'Warp: Up to date.$|Nothing to build.$';
    my $stdout = $self->stdout;
    like($stdout, qr/$up_to_date/m, 'Up to date');
    _dec_level;
}

=over

=item test_file_exist

Fails a test if the file given as argument does not exist.

=back

=cut

sub test_file_exist {
    my ($self, $file) = @_;
    _inc_level;
    ok(-e $file, 'File exists');
    _dec_level;
}

=over

=item test_file_exist_in_build_dir

Fails a test if the file given as argument does not exist. The path to
the file is assumed relative the build directory.

=back

=cut

sub test_file_exist_in_build_dir {
    my ($self, $file) = @_;
    _inc_level;
    $self->test_file_exist($self->catfile($self->build_dir, $file));
    _dec_level;
}

=over

=item test_file_not_exist

The opposite to L<test_file_exist>.

=back

=cut

sub test_file_not_exist {
    my ($self, $file) = @_;
    _inc_level;
    ok(! -e $file, 'File does not exist');
    _dec_level;
}

=over

=item test_file_not_exist_in_build_dir

The opposite to L<test_file_exist_in_build_dir>.

=back

=cut

sub test_file_not_exist_in_build_dir {
    my ($self, $file) = @_;
    _inc_level;
    $self->test_file_not_exist($self->catfile($self->build_dir, $file));
    _dec_level;
}

=over

=item remove_file_from_build_dir

Deletes the file given as argument. Raises an exception if unsuccessful.
The path to the file is assumed relative the build directory.

=back

=cut

# Removes a file from the build directory
sub remove_file_from_build_dir {
    my ($self, $file) = @_;
    unlink($self->catfile($self->build_dir, $file)) == 1 || die;
}

=over

=item test_file_contents

Fails a test if the contents of the file given as the first argument
does not match the second argument. Raises an exception if the file
cannot be read.

=back

=cut

sub test_file_contents {
    my ($self, $file, $expected) = @_;
    open(FILE, $file) || die;
    my @lines = <FILE>;
    _inc_level;
    is("@lines", $expected, 'File content matches');
    _dec_level;
}

=over

=item test_file_contents_regex

Fails a test if the contents of the file given as the first argument
does not match the second argument, interpreted as a regular
expression. Raises an exception if the file cannot be read.

=back

=cut

sub test_file_contents_regex {
    my ($self, $file, $regexp) = @_;
    open(FILE, $file) || die;
    my @lines = <FILE>;
    _inc_level;
    like("@lines", $regexp, 'File content matches regexp');
    _dec_level;
}

=over

=item test_target_contents

Fails a test if the contents of the target file does not match the
argument. Raises an exception if the target file cannot be read.

=back

=cut

sub test_target_contents {
    my ($self, $expected) = @_;
    _inc_level;
    $self->test_file_contents($self->get_target_with_path, $expected);
    _dec_level;
}

=over

=item test_node_was_rebuilt

Fails a test if the file given as argument was not built/rebuilt in the
last run of pbs. This method assumes that a post-pbs script is given to
pbs in the flags, which prints the names of the files built/rebuilt on
standard output, one filename on each line.

=back

=cut

sub test_node_was_rebuilt {
    my ($self, $file) = @_;
    _inc_level;
    my $stdout = $self->stdout;
    like($stdout, qr|Rebuild node \Q$file\E\n|, 'Node was rebuilt');
    _dec_level;
}

=over

=item test_node_was_not_rebuilt

The opposite to L<test_node_was_rebuilt>.

=back

=cut

sub test_node_was_not_rebuilt {
    my ($self, $file) = @_;
    _inc_level;
    my $stdout = $self->stdout;
    unlike($stdout, qr|Rebuild node \Q$file\E\n|, 'Node was not rebuilt');
    _dec_level;
}

=over

=item dump_stdout_stderr

Dump stdout, stderr.

=back

=cut

sub dump_stdout_stderr {
	my ($self) = @_;

	print <<_EOF_;

**********************************************************
stdout:
@{[$self->stdout]}

stderr:
@{[$self->stderr]}

**********************************************************

_EOF_
}

=over

=item catfile_pbs

Concatenate one or more directory names and a filename to form a complete
path ending with a filename. This is the same as catfile, but this sub
uses slashes as path separators, for use in PBS-files.

=back

=cut

sub catfile_pbs {
	my ($self, @directories_and_filename) = @_;
    return join('/', @directories_and_filename);
}

=over

=item here_pbs

Returns the absolute path name of the current working directory.
This is the same as here, but this sub uses slashes as path separators,
for use in PBS-files.

=back

=cut

sub here_pbs {
    return Cwd::getcwd();
}

=over

=item generate_test_snapshot_and_exit

Copies the temporary directory to /tmp/pbs_test_snapshot and stops the tests.
Use this to manually debug a test case.

=back

=cut

sub generate_test_snapshot_and_exit {
    my $self = shift;
	my $here = $self->here;
    use File::Copy::Recursive qw(rcopy);
	rcopy($here, "/tmp/pbs_test_snapshot");
    print "!!! Generating snapshot to /tmp/pbs_test_snapshot and exiting !!!\n";
    exit;
}

=over

=item start_cwd

Returns the absolute path name of the directory that was the
current working directory at the start.

=back

=cut

sub start_cwd {
    return $start_cwd_global;
}

=over

=item setup_test_data

Copies all files and directories (recursively) from a source directory to the
current directory. The source directory is a specified subdirectory of the
't/setup_data' subdirectory of the start directory.

=back

=cut

sub setup_test_data {
	my ($self, $source_dir) = @_;
	
	rcopy($self->catdir($self->start_cwd, 't', 'setup_data', $source_dir), $self->here);
}

=over

=item setup_test_data_file

Copies a single file from a source directory to the current directory. The
source directory is a specified subdirectory of the 't/setup_data'
subdirectory of the start directory.

=back

=cut

sub setup_test_data_file {
	my ($self,
		$source_dir,
		$src,
		$dst) = @_;
	
	$dst = $src unless $dst;
	
	rcopy($self->catfile($self->start_cwd, 't', 'setup_data', $source_dir, $src),
		$self->catfile($self->here, $dst));
}



1;
