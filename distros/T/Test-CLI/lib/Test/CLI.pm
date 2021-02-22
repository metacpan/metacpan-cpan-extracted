package Test::CLI;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Command::Template qw< command_runner >;
use Test2::API 'context';

use Exporter 'import';
our @EXPORT_OK = qw< tc test_cli >;

# functional interface
sub test_cli (@command) { __PACKAGE__->new(@command) }
{
   no strict 'refs';
   *tc = *test_cli;
}

# constructor, accessors, and commodity functions
sub new ($pack, @cmd) { bless {runner => command_runner(@cmd)}, $pack }
sub run ($self, @args) { return $self->runner->run(@args)->success }
sub runner ($self)       { return $self->{runner} }
sub last_run ($self)     { return $self->runner->last_run }
sub last_command ($self) { return $self->last_run->command_as_string }

sub verbose ($self, @new) {
   return $self->{verbose} unless @new;
   $self->{verbose} = $new[0];
   return $self;
}
sub _message ($self, $pref) { $pref . ' ' . $self->last_command }

# test interface
sub run_ok ($self, $bindopts = {}, $message = undef) {
   $self->run($bindopts->%*);
   $self->ok($message);
}

sub run_failure_ok ($self, $bindopts = {}, $message = undef) {
   $self->run($bindopts->%*);
   $self->failure_ok($message);
}

sub dump_diag ($self) {
   require Data::Dumper;
   local $Data::Dumper::Indent = 1;
   my $c = context();
   $c->diag(Data::Dumper::Dumper({$self->last_run->%*}));
   $c->release;
   return $self;
} ## end sub dump_diag ($self)

sub ok ($self, $message = undef) {
   my $outcome = $self->last_run->success;
   my $c       = context();
   $c->ok($outcome, $message // $self->last_command);
   $c->release;
   $self->dump_diag if (!$outcome) && $self->verbose;
   return $self;
} ## end sub ok

sub failure_ok ($self, $message = undef) {
   my $outcome = $self->last_run->failure;
   my $c       = context();
   $c->ok($outcome, $message // $self->_message('(failure on)'));
   $c->release;
   $self->dump_diag if (!$outcome) && $self->verbose;
   return $self;
} ## end sub failure_ok

sub _ok ($self, $outcome, $errormsg, $message) {
   my $c = context();
   $c->ok($outcome, $message);
   $c->diag($errormsg) if $errormsg && !$outcome;
   $c->release;
   $self->dump_diag if (!$outcome) && $self->verbose;
   return $self;
} ## end sub _ok

for my $case (
   [
      'exit code',
      qw<
        exit_code
        exit_code_ok exit_code_failure_ok
        exit_code_is exit_code_isnt
        >
   ],
   [
      'signal',
      qw<
        signal
        signal_ok signal_failure_ok
        signal_is signal_isnt
        >
   ],
   [
      'timeout',
      qw<
        timeout
        in_time_ok timed_out_ok
        timeout_is timeout_isnt
        >
   ],
  )
{
   my ($name, $method, $ok, $not_ok, $is, $isnt) = $case->@*;
   no strict 'refs';

   *{$ok} = sub ($self, $message = undef) { $self->$is(0, $message) };

   *{$not_ok} = sub ($self, $msg = undef) { $self->$isnt(0, $msg) };

   *{$is} = sub ($self, $exp, $message = undef) {
      my $got = $self->last_run->$method;
      return $self->_ok(
         $got == $exp,
         "$name: got $got, expected $exp",
         $message // $self->_message("($name is $exp on)"),
      );
   };

   *{$isnt} = sub ($self, $nexp, $message = undef) {
      my $got = $self->last_run->$method;
      return $self->_ok(
         $got != $nexp,
         "$name: did not expect $nexp",
         $message // $self->_message("($name is not $nexp on)"),
      );
   };
} ## end for my $case (['exit code'...])

for my $case (
   [qw< stdout stdout stdout_is stdout_isnt stdout_like stdout_unlike >],
   [qw< stderr stderr stderr_is stderr_isnt stderr_like stderr_unlike >],
   [qw< merged merged merged_is merged_isnt merged_like merged_unlike >],
  )
{
   my ($name, $method, $is, $isnt, $like, $unlike) = $case->@*;
   no strict 'refs';

   *{$is} = sub ($self, $exp, $message = undef) {
      my $got = $self->last_run->$method;
      return $self->_ok(
         $got eq $exp,
         "$name: got <$got>, expected <$exp>",
         $message // $self->_message("($name is <$exp> on)"),
      );
   };

   *{$isnt} = sub ($self, $nexp, $message = undef) {
      my $got = $self->last_run->$method;
      return $self->_ok(
         $got ne $nexp,
         "$name: did not expect <$nexp>",
         $message // $self->_message("($name is not <$nexp> on)"),
      );
   };

   *{$like} = sub ($self, $regex, $message = undef) {
      my $got     = $self->last_run->$method;
      my $outcome = $got =~ m{$regex};
      return $self->_ok(
         $outcome,
         "$name: did not match $regex",
         $message // $self->_message("($name match $regex on)"),
      );
   };

   *{$unlike} = sub ($self, $regex, $message = undef) {
      my $got     = $self->last_run->$method;
      my $outcome = $got !~ m{$regex};
      return $self->_ok(
         $outcome,
         "$name: unepected match of $regex",
         $message // $self->_message("($name does not match $regex on)"),
      );
   };
} ## end for my $case ([...])

1;
