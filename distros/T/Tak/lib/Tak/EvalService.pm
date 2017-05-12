package Tak::EvalService;

use Eval::WithLexicals;
use Data::Dumper::Concise;
use Capture::Tiny qw(capture);
use Moo;

with 'Tak::Role::Service';

has 'eval_withlexicals' => (is => 'lazy');

has 'service_client' => (is => 'ro', predicate => 'has_service_client');

sub _build_eval_withlexicals {
  my ($self) = @_;
  Eval::WithLexicals->new(
    $self->has_service_client
      ? (lexicals => { '$client' => \($self->service_client) })
      : ()
  );
}

sub handle_eval {
  my ($self, $perl) = @_;
  unless ($perl) {
    die [ mistake => eval_input => "No code supplied" ];
  }
  if (my $ref = ref($perl)) {
    die [ mistake => eval_input => "Code was a ${ref} reference" ];
  }
  my ($ok, @ret);
  my ($stdout, $stderr);
  if (eval {
    ($stdout, $stderr) = capture {
      @ret = $self->eval_withlexicals->eval($perl);
    };
    1
  }) {
    $ok = 1;
  } else {
    ($ok, @ret) = (0, $@);
  }
  my $dumped_ret;
  unless (eval { $dumped_ret = Dumper(@ret); 1 }) {
    $dumped_ret = "Error dumping ${\($ok ? 'result' : 'exception')}: $@";
    $ok = 0;
  }
  return {
    stdout => $stdout, stderr => $stderr,
    ($ok ? 'return' : 'exception') => $dumped_ret
  };
}

1;
