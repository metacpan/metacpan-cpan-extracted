package Test::TusResponse;
use v5.24;
use Carp;
use English qw< -no_match_vars >;
use experimental qw< signatures >;
use Data::Dumper;

use Test::Builder;
my $Tester = Test::Builder->new;

use Exporter qw< import >;
our @EXPORT = qw< tus_call tus_response >;

sub tus_call ($tus, $method_name, @args) {
   my $method = $tus->can($method_name)
      or $Tester->BAIL_OUT("unknown _call method $method_name");
   my $response;
   eval { $response = $tus->$method(@args) }
      or $Tester->BAIL_OUT("error calling $method_name: $EVAL_ERROR");
   return tus_response($response);
}

sub tus_response ($response, $prefix) {
   return bless {
      response => $response,
      prefix   => $prefix,
   }, __PACKAGE__;
}

sub _msg ($self, $rest) {
   return $self->{prefix} . ': ' . $rest;
}

sub __printable ($comparison, @items) {
   return map { $_ // '*UNDEF*' } @items if $comparison eq 'is_num';
   return map { defined($_) ? qq{'$_'} : '*UNDEF*' } @items;
}

sub _compare ($self, $comparison, $exp, $got) {
   my $caller = (caller(1))[3] =~ s{\A.*::}{}rmxs;
   my ($pexp, $pgot) = __printable($comparison, $exp, $got);
   my $msg = $self->_msg("$caller($pexp)");
   my $ok = $Tester->$comparison($got, $exp, $msg);
   return $self;
}

sub body_is ($self, $expected, $description = undef) {
   $self->_compare(is_eq => $expected, $self->{response}->body);
}

sub status_is ($self, $expected, $description = undef) {
   $self->_compare(is_num => $expected, $self->{response}->status);
}

sub header_is ($self, $name, $expected, $description = undef) {
   $self->_compare(is_eq => $expected,
      $self->{response}->headers->{$name} // undef);
}

sub no_exception ($self) {
   my $exception = $self->{response}->exception;
   my $msg = $self->_msg('no_exception');
   my $ok = $Tester->ok((! defined($exception)), $msg);
   if (! $ok) {
      local $Data::Dumper::Indent = 1;
      $Tester->diag('got exception: ' . Dumper($exception));
   }
   return $self;
}

sub exception_like ($self, $rx) {
   my $exception = $self->{response}->exception;
   my $ok = defined($exception)
      && eval { $exception->isa('Ouch') }
      && $exception->message =~ m{$rx};
   my $msg = $self->_msg("exception like $rx");
   $Tester->ok($ok, $self->_msg("exception like $rx"))
      or $Tester->diag($msg . Dumper($exception));
   return $self;
};

1;
