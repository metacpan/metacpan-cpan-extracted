package Test::Command;

use warnings;
use strict;

use Carp qw/ confess /;
use File::Temp qw/ tempfile /;

use base 'Test::Builder::Module';

our @EXPORT = qw(
   exit_value
   exit_is_num
   exit_isnt_num
   exit_cmp_ok
   exit_is_defined
   exit_is_undef

   signal_value
   signal_is_num
   signal_isnt_num
   signal_cmp_ok
   signal_is_defined
   signal_is_undef

   stdout_value
   stdout_file
   stdout_is_eq
   stdout_isnt_eq
   stdout_is_num
   stdout_isnt_num
   stdout_like
   stdout_unlike
   stdout_cmp_ok
   stdout_is_file

   stderr_value
   stderr_file
   stderr_is_eq
   stderr_isnt_eq
   stderr_is_num
   stderr_isnt_num
   stderr_like
   stderr_unlike
   stderr_cmp_ok
   stderr_is_file

   );
                  
=head1 NAME

Test::Command - Test routines for external commands

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Test the exit status, signal, STDOUT or STDERR of an external command.

   use Test::Command tests => 11;

   ## testing exit status

   my $cmd = 'true';

   exit_is_num($cmd, 0);
   exit_cmp_ok($cmd, '<', 10);

   $cmd = 'false';

   exit_isnt_num($cmd, 0);

   ## testing terminating signal 

   $cmd = 'true';

   signal_is_num($cmd, 0);

   ## testing STDOUT

   $cmd         = [qw/ echo out /];  ## run as "system @$cmd"
   my $file_exp = 'echo_stdout.exp';

   stdout_is_eq($cmd, "out\n");
   stdout_isnt_eq($cmd, "out");
   stdout_is_file($cmd, $file_exp);

   ## testing STDERR

   $cmd = 'echo err >&2';

   stderr_like($cmd, /err/);
   stderr_unlike($cmd, /rre/);
   stderr_cmp_ok($cmd, 'eq', "err\n");

   ## run-once-test-many-OO-style
   ## the first test lazily runs command
   ## the second test uses cached results

   my $echo_test = Test::Command->new( cmd => 'echo out' );

   $echo_test->exit_is_num(0);
   $echo_test->signal_is_num(0);
   $echo_test->stdout_is_eq("out\n");

   ## force a re-run of the command

   $echo_test->run;

   ## arbitrary results inspection

   is( $echo_test->exit_value, 0,         'echo exit' );
   is( $echo_test->signal_value, undef,   'echo signal' );
   is( $echo_test->stdout_value, "out\n", 'echo stdout' );
   is( $echo_test->stderr_value, '',      'echo stderr' );
   is( -s $echo_test->stdout_file, 4,     'echo stdout file size' );
   is( -s $echo_test->stderr_file, 0,     'echo stderr file size' );

=head1 DESCRIPTION

C<Test::Command> intends to bridge the gap between the well tested functions and
objects you choose and their usage in your programs. By examining the exit
status, terminating signal, STDOUT and STDERR of your program you can determine
if it is behaving as expected.

This includes testing the various combinations and permutations of options and
arguments as well as the interactions between the various functions and objects
that make up your program.

The various test functions below can accept either a command string or an
array reference for the first argument. If the command is expressed as a
string it is passed to C<system> as is. If the command is expressed as an
array reference it is dereferenced and passed to C<system> as a list. See
'C<perldoc -f system>' for how these may differ.

The final argument for the test functions, C<$name>, is optional. By default the
C<$name> is a concatenation of the test function name, the command string and
the expected value. This construction is generally sufficient for identifying a
failing test, but you may always specify your own C<$name> if desired.

Any of the test functions can be used as instance methods on a C<Test::Command>
object. This is done by dropping the initial C<$cmd> argument and instead using
arrow notation.

All of the following C<exit_is_num> calls are equivalent.

   exit_is_num('true', 0);
   exit_is_num('true', 0, 'exit_is_num: true, 0');
   exit_is_num(['true'], 0);
   exit_is_num(['true'], 0, 'exit_is_num: true, 0');

   my $cmd = Test::Command->new( cmd => 'true' );

   exit_is_num($cmd, 0);
   exit_is_num($cmd, 0, 'exit_is_num: true, 0');
   $cmd->exit_is_num(0);
   $cmd->exit_is_num(0, 'exit_is_num: true, 0');

   $cmd = Test::Command->new( cmd => ['true'] );

   exit_is_num($cmd, 0);
   exit_is_num($cmd, 0, 'exit_is_num: true, 0');
   $cmd->exit_is_num(0);
   $cmd->exit_is_num(0, 'exit_is_num: true, 0');

=head1 EXPORT

All of the test functions mentioned below are exported by default.

=head1 METHODS

=head2 new

   my $test_cmd_obj = Test::Command->new( cmd => $cmd )

This constructor creates and returns a C<Test::Command> object. Use this to test
multiple aspects of a single command execution while avoiding repeatedly running
commands which are slow or resource intensive.

The C<cmd> parameter can accept either a string or an array reference for its
value. The value is dereferenced if necessary and passed directly to the
C<system> builtin.

=cut

sub new
   {
   my ($class, @args) = @_;

   my $self = bless { @args }, $class;

   return $self;

   }

=head2 run

   $test_cmd_obj->run;

This instance method forces the execution of the command specified by the
invocant.

You only need to call this when you wish to re-run a command since the first
test method invoked will lazily execute the command if necessary. However, if
the state of your inputs has changed and you wish to re-run the command, you may
do so by invoking this method at any point between your tests.

=cut

sub run
   {
   my ($self) = @_;

   my $run_info = _run_cmd( $self->{'cmd'} );

   $self->{'result'}{'exit_status'} = $run_info->{'exit_status'};
   $self->{'result'}{'term_signal'} = $run_info->{'term_signal'};
   $self->{'result'}{'stdout_file'} = $run_info->{'stdout_file'};
   $self->{'result'}{'stderr_file'} = $run_info->{'stderr_file'};

   return $self;

   }

=head1 FUNCTIONS

=cut

## private helper functions

sub _slurp
   {
   my ($file_name) = @_;
   defined $file_name or confess '$file_name is undefined';
   open my $fh, '<', $file_name or confess "$file_name: $!";
   my $text = do { local $/ = undef; <$fh> };
   close $fh or confess "failed to close $file_name: $!";
   return $text;
   }

sub _diff_column
   {
   my ($line_1, $line_2) = @_;

   my $diff_column;

   my $defined_args = grep defined($_), $line_1, $line_2;

   if (1 == $defined_args)
      {
      $diff_column = 1;
      }
   elsif (2 == $defined_args)
      {

      my $max_length =
         ( sort { $b <=> $a } map length($_),  $line_1, $line_2 )[0];

      for my $position ( 1 .. $max_length )
         {

         my $char_line_1 = substr $line_1, $position - 1, 1;
         my $char_line_2 = substr $line_2, $position - 1, 1;

         if ($char_line_1 ne $char_line_2)
            {
            $diff_column = $position;
            last;
            }

         }

      }

   return $diff_column;

   }

sub _compare_files
   {
   my ($got_file, $exp_file) = @_;

   defined $got_file or confess '$got_file is undefined';
   defined $exp_file or confess '$exp_file is undefined';

   open my $got_fh, '<', $got_file or confess "$got_file: $!";
   open my $exp_fh, '<', $exp_file or confess "$exp_file: $!";

   my $ok = 1;
   my $diff_line;
   my $diff_column;
   my $got_line;
   my $exp_line;
   my $col_mark;

   CHECK_LINE:
      {
      $got_line = <$got_fh>;
      $exp_line = <$exp_fh>;

      last CHECK_LINE if ! defined $got_line &&
                         ! defined $exp_line;

      $diff_line++;

      $ok = defined $got_line &&
            defined $exp_line &&
            $got_line eq $exp_line;

      if (! $ok)
         {
         $diff_column = _diff_column($got_line, $exp_line);
         $col_mark  = ' ' x ( $diff_column - 1 );
         $col_mark .= '^';
         last CHECK_LINE;
         }

      redo CHECK_LINE;

      };

   close $got_fh or confess "failed to close 'got' handle: $!";
   close $exp_fh or confess "failed to close 'exp' handle: $!";

   return $ok, $diff_line, $got_line, $exp_line, $col_mark;
   }

sub _build_name
   {
   my ($name, $cmd, @args) = @_;

   if (defined $name)
      {
      return $name;
      }

   defined $cmd or confess '$cmd is undefined';

   if ( ref $cmd && UNIVERSAL::isa($cmd, 'Test::Command') ) 
      {
      $cmd = $cmd->{'cmd'};
      }

   if (ref $cmd eq 'ARRAY')
      {
      $cmd = join ' ', @{ $cmd };
      }

   ## remove any leading package information from the subroutine name
   (my $test_sub = (caller 1)[3]) =~ s/.*:://;
   return "$test_sub: " . join ', ', $cmd, @args;
   }

sub _get_result
   {
   my ($cmd) = @_;

   defined $cmd or confess '$cmd is undefined';

   if ( ref $cmd && UNIVERSAL::isa($cmd, 'Test::Command') ) 
      {

      ## run the command if needed
      if ( ! $cmd->{'result'} )
         {
         $cmd->run;
         }

      return $cmd->{'result'};
      }
   else
      {
      return _run_cmd(@_);
      }

   }

sub _run_cmd
   {
   my ($cmd) = @_;

   ## do as much as we can before redirecting STDOUT and STDERR, we want
   ## to avoid getting our peanut butter in their chocolate

   defined $cmd or confess '$cmd is undefined';

   if ( ! ref $cmd )
      {
      $cmd = [ $cmd ];
      }

   ## save copies of STDOUT and STDERR
   open my $saved_stdout, '>&STDOUT' or confess 'Cannot duplicate STDOUT';
   open my $saved_stderr, '>&STDERR' or confess 'Cannot duplicate STDERR';

   ## create tempfiles for capturing STDOUT and STDERR
   my ($temp_stdout_fh, $temp_stdout_file) = tempfile(UNLINK => 1);
   my ($temp_stderr_fh, $temp_stderr_file) = tempfile(UNLINK => 1);

   ## close and reopen STDOUT and STDERR to temp files
   close STDOUT or confess "failed to close STDOUT: $!";
   close STDERR or confess "failed to close STDERR: $!";
   open STDOUT, '>&' . fileno $temp_stdout_fh or confess 'Cannot duplicate temporary STDOUT';
   open STDERR, '>&' . fileno $temp_stderr_fh or confess 'Cannot duplicate temporary STDERR';

   ## run the command
   system(@{ $cmd });
   
   my $system_return = defined ${^CHILD_ERROR_NATIVE} ? ${^CHILD_ERROR_NATIVE} : $?; 
   
   my $exit_status;
   my $term_signal;

   my $wait_status = $system_return & 127;
   if ($wait_status)
      {
      $exit_status = undef;
      $term_signal = $wait_status;
      }
   else
      {
      $exit_status = $system_return >> 8;
      $term_signal = undef;
      }

   ## close and restore STDOUT and STDERR to original handles
   close STDOUT or confess "failed to close STDOUT: $!";
   close STDERR or confess "failed to close STDERR: $!";
   open STDOUT, '>&' . fileno $saved_stdout or confess 'Cannot restore STDOUT';
   open STDERR, '>&' . fileno $saved_stderr or confess 'Cannot restore STDERR';

   return { exit_status => $exit_status,
            term_signal => $term_signal,
            stdout_file => $temp_stdout_file,
            stderr_file => $temp_stderr_file };

   }

=head2 Testing Exit Status

The test routines below compare against the exit status of the executed
command right shifted by 8 (that is, C<$? E<gt>E<gt> 8>).

=head3 exit_value

   exit_value($cmd)

Return the exit status of the command. Useful for performing arbitrary tests
not covered by this module.

=cut

sub exit_value
   {
   my ($cmd) = @_;

   my $result = _get_result($cmd);
   
   return $result->{'exit_status'};
   }

=head3 exit_is_num

   exit_is_num($cmd, $exp_num, $name)

If the exit status of the command is numerically equal to the expected number,
this passes. Otherwise it fails.

=cut

sub exit_is_num
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);
   
   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_num($result->{'exit_status'}, $exp, $name);
   }

=head3 exit_isnt_num

   exit_isnt_num($cmd, $unexp_num, $name)

If the exit status of the command is B<not> numerically equal to the given
number, this passes. Otherwise it fails.

=cut

sub exit_isnt_num
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_num($result->{'exit_status'}, $not_exp, $name);
   }

=head3 exit_cmp_ok

   exit_cmp_ok($cmd, $op, $operand, $name)

If the exit status of the command is compared with the given operand using
the given operator, and that operation returns true, this passes. Otherwise
it fails.

=cut

sub exit_cmp_ok
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->cmp_ok($result->{'exit_status'}, $op, $exp, $name);
   }

=head3 exit_is_defined

   exit_is_defined($cmd, $name)

If the exit status of the command is defined, this passes. Otherwise it
fails. A defined exit status indicates that the command exited normally
by calling exit() or running off the end of the program.

=cut

sub exit_is_defined
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->ok(defined $result->{'exit_status'}, $name);
   }

=head3 exit_is_undef

   exit_is_undef($cmd, $name)

If the exit status of the command is not defined, this passes. Otherwise it
fails. An undefined exit status indicates that the command likely exited
due to a signal.

=cut

sub exit_is_undef
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->ok(! defined $result->{'exit_status'}, $name);
   }

=head2 Testing Terminating Signal

The test routines below compare against the lower 8 bits of the exit status
of the executed command.

=head3 signal_value

   signal_value($cmd)

Return the signal code of the command. Useful for performing arbitrary tests
not covered by this module.

=cut

sub signal_value
   {
   my ($cmd) = @_;

   my $result = _get_result($cmd);
   
   return $result->{'term_signal'};
   }

=head3 signal_is_num

   signal_is_num($cmd, $exp_num, $name)

If the terminating signal of the command is numerically equal to the expected number,
this passes. Otherwise it fails.

=cut

sub signal_is_num
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);
   
   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_num($result->{'term_signal'}, $exp, $name);
   }

=head3 signal_isnt_num

   signal_isnt_num($cmd, $unexp_num, $name)

If the terminating signal of the command is B<not> numerically equal to the given
number, this passes. Otherwise it fails.

=cut

sub signal_isnt_num
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_num($result->{'term_signal'}, $not_exp, $name);
   }

=head3 signal_cmp_ok

   signal_cmp_ok($cmd, $op, $operand, $name)

If the terminating signal of the command is compared with the given operand
using the given operator, and that operation returns true, this passes. Otherwise
it fails.

=cut

sub signal_cmp_ok
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->cmp_ok($result->{'term_signal'}, $op, $exp, $name);
   }

=head3 signal_is_defined

   signal_is_defined($cmd, $name)

If the terminating signal of the command is defined, this passes. Otherwise it
fails. A defined signal indicates that the command likely exited due to a
signal.

=cut

sub signal_is_defined
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->ok(defined $result->{'term_signal'}, $name);
   }

=head3 signal_is_undef

   signal_is_undef($cmd, $name)

If the terminating signal of the command is not defined, this passes.
Otherwise it fails. An undefined signal indicates that the command exited
normally by calling exit() or running off the end of the program.

=cut

sub signal_is_undef
   {
   my ($cmd, $name) = @_;

   my $result = _get_result($cmd);

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->ok(! defined $result->{'term_signal'}, $name);
   }

=head2 Testing STDOUT

Except where specified, the test routines below treat STDOUT as a single slurped
string.

=head3 stdout_value

   stdout_value($cmd)

Return the STDOUT of the command. Useful for performing arbitrary tests
not covered by this module.

=cut

sub stdout_value
   {
   my ($cmd) = @_;

   my $result      = _get_result($cmd);
   my $stdout_text = _slurp($result->{'stdout_file'});
   
   return $stdout_text;
   }

=head3 stdout_file

   stdout_file($cmd)

Return the file name containing the STDOUT of the command. Useful for
performing arbitrary tests not covered by this module.

=cut

sub stdout_file
   {
   my ($cmd) = @_;

   my $result = _get_result($cmd);

   return $result->{'stdout_file'};
   }

=head3 stdout_is_eq

   stdout_is_eq($cmd, $exp_string, $name)

If the STDOUT of the command is equal (compared using C<eq>) to the expected
string, then this passes. Otherwise it fails.

=cut

sub stdout_is_eq
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_eq($stdout_text, $exp, $name);
   }

=head3 stdout_isnt_eq

   stdout_isnt_eq($cmd, $unexp_string, $name)

If the STDOUT of the command is B<not> equal (compared using C<eq>) to the
given string, this passes. Otherwise it fails.

=cut

sub stdout_isnt_eq
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_eq($stdout_text, $not_exp, $name);
   }

=head3 stdout_is_num

   stdout_is_num($cmd, $exp_num, $name)

If the STDOUT of the command is equal (compared using C<==>) to the expected
number, then this passes. Otherwise it fails.

=cut

sub stdout_is_num
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_num($stdout_text, $exp, $name);
   }

=head3 stdout_isnt_num

   stdout_isnt_num($cmd, $unexp_num, $name)

If the STDOUT of the command is B<not> equal (compared using C<==>) to the
given number, this passes. Otherwise it fails.

=cut

sub stdout_isnt_num
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_num($stdout_text, $not_exp, $name);
   }

=head3 stdout_like

   stdout_like($cmd, $exp_regex, $name)

If the STDOUT of the command matches the expected regular expression,
this passes. Otherwise it fails.

=cut

sub stdout_like
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->like($stdout_text, $exp, $name);
   }

=head3 stdout_unlike

   stdout_unlike($cmd, $unexp_regex, $name)

If the STDOUT of the command does B<not> match the given regular
expression, this passes. Otherwise it fails.

=cut

sub stdout_unlike
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->unlike($stdout_text, $exp, $name);
   }

=head3 stdout_cmp_ok

   stdout_cmp_ok($cmd, $op, $operand, $name)

If the STDOUT of the command is compared with the given operand using
the given operator, and that operation returns true, this passes. Otherwise
it fails.

=cut

sub stdout_cmp_ok
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stdout_text = _slurp($result->{'stdout_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->cmp_ok($stdout_text, $op, $exp, $name);
   }

=head3 stdout_is_file

   stdout_is_file($cmd, $exp_file, $name)

If the STDOUT of the command is equal (compared using C<eq>) to the contents of
the given file, then this passes. Otherwise it fails. Note that this comparison
is performed line by line, rather than slurping the entire file.

=cut

sub stdout_is_file
   {
   my ($cmd, $exp_file, $name) = @_;

   my $result = _get_result($cmd);

   my ($ok, $diff_start, $got_line, $exp_line, $col_mark) =
      _compare_files($result->{'stdout_file'}, $exp_file);

   $name = _build_name($name, @_);

   my $is_ok = __PACKAGE__->builder->ok($ok, $name);

   if (! $is_ok)
      {
      chomp( $got_line, $exp_line );
      __PACKAGE__->builder->diag(<<EOD);
STDOUT differs from $exp_file starting at line $diff_start.
got: $got_line
exp: $exp_line
     $col_mark
EOD
      }

   return $is_ok;
   }

=head2 Testing STDERR

Except where specified, the test routines below treat STDERR as a single slurped
string.

=head3 stderr_value

   stderr_value($cmd)

Return the STDERR of the command. Useful for performing arbitrary tests
not covered by this module.

=cut

sub stderr_value
   {
   my ($cmd) = @_;

   my $result      = _get_result($cmd);
   my $stderr_text = _slurp($result->{'stderr_file'});
   
   return $stderr_text;
   }

=head3 stderr_file

   stderr_file($cmd)

Return the file name containing the STDERR of the command. Useful for
performing arbitrary tests not covered by this module.

=cut

sub stderr_file
   {
   my ($cmd) = @_;

   my $result = _get_result($cmd);

   return $result->{'stderr_file'};
   }

=head3 stderr_is_eq

   stderr_is_eq($cmd, $exp_string, $name)

If the STDERR of the command is equal (compared using C<eq>) to the expected
string, then this passes. Otherwise it fails.

=cut

sub stderr_is_eq
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_eq($stderr_text, $exp, $name);
   }

=head3 stderr_isnt_eq

   stderr_isnt_eq($cmd, $unexp_string, $name)

If the STDERR of the command is B<not> equal (compared using C<eq>) to the
given string, this passes. Otherwise it fails.

=cut

sub stderr_isnt_eq
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_eq($stderr_text, $not_exp, $name);
   }

=head3 stderr_is_num

   stderr_is_num($cmd, $exp_num, $name)

If the STDERR of the command is equal (compared using C<==>) to the expected
number, then this passes. Otherwise it fails.

=cut

sub stderr_is_num
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->is_num($stderr_text, $exp, $name);
   }

=head3 stderr_isnt_num

   stderr_isnt_num($cmd, $unexp_num, $name)

If the STDERR of the command is B<not> equal (compared using C<==>) to the
given number, this passes. Otherwise it fails.

=cut

sub stderr_isnt_num
   {
   my ($cmd, $not_exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->isnt_num($stderr_text, $not_exp, $name);
   }

=head3 stderr_like

   stderr_like($cmd, $exp_regex, $name)

If the STDERR of the command matches the expected regular expression,
this passes. Otherwise it fails.

=cut

sub stderr_like
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->like($stderr_text, $exp, $name);
   }

=head3 stderr_unlike

   stderr_unlike($cmd, $unexp_regex, $name)

If the STDERR of the command does B<not> match the given regular
expression, this passes. Otherwise it fails.

=cut

sub stderr_unlike
   {
   my ($cmd, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->unlike($stderr_text, $exp, $name);
   }

=head3 stderr_cmp_ok

   stderr_cmp_ok($cmd, $op, $operand, $name)

If the STDERR of the command is compared with the given operand using
the given operator, and that operation returns true, this passes. Otherwise
it fails.

=cut

sub stderr_cmp_ok
   {
   my ($cmd, $op, $exp, $name) = @_;

   my $result = _get_result($cmd);

   my $stderr_text = _slurp($result->{'stderr_file'});

   $name = _build_name($name, @_);

   return __PACKAGE__->builder->cmp_ok($stderr_text, $op, $exp, $name);
   }

=head3 stderr_is_file

   stderr_is_file($cmd, $exp_file, $name)

If the STDERR of the command is equal (compared using C<eq>) to the contents of
the given file, then this passes. Otherwise it fails. Note that this comparison
is performed line by line, rather than slurping the entire file.

=cut

sub stderr_is_file
   {
   my ($cmd, $exp_file, $name) = @_;

   my $result = _get_result($cmd);

   my ($ok, $diff_start, $got_line, $exp_line, $col_mark) =
      _compare_files($result->{'stderr_file'}, $exp_file);

   $name = _build_name($name, @_);

   my $is_ok = __PACKAGE__->builder->ok($ok, $name);

   if (! $is_ok)
      {
      chomp( $got_line, $exp_line );
      __PACKAGE__->builder->diag(<<EOD);
STDERR differs from $exp_file starting at line $diff_start.
got: $got_line
exp: $exp_line
     $col_mark
EOD
      }

   return $is_ok;
   }

=head1 AUTHOR

Daniel B. Boorstein, C<< <danboo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-command at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Command>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Command

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Command>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Command>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Command>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Command>

=back

=head1 ACKNOWLEDGEMENTS

Test::Builder by Michael Schwern allowed me to focus on the specifics related to
testing system commands by making it easy to produce proper test output.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Daniel B. Boorstein, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DEVELOPMENT IDEAS

=over 3

=item * create a tool that produces test scripts given a list of commands to run

=item * optionally save the temp files with STDOUT and STDERR for user debugging

=item * if user defines all options and sample arguments to basic command

=over 3

=item * create tool to enumerate all possible means of calling program

=item * allow testing with randomized/permuted/collapsed opts and args

=back

=item * potential test functions:

=over 3

=item * time_lt($cmd, $seconds)

=item * time_gt($cmd, $seconds)

=item * stdout_line_custom($cmd, \&code)

=item * stderr_line_custom($cmd, \&code)

=back

=back

=head1 SEE ALSO

L<Test::Builder> provides the testing methods used in this module.

L<Test::Builder::Module> is the superclass of this module.

=cut

1;
