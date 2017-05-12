package Tak::Role::ScriptActions;

use Moo::Role;
no warnings::illegalproto;

sub every_exec (stream|s) {
  my ($self, $remotes, $options, @command) = @_;

  my @requests;

  $_->ensure(command_service => 'Tak::CommandService') for @$remotes;

  foreach my $remote (@$remotes) {
    if ($options->{stream}) {
      my $stdout = $self->stdout;
      my $host = $remote->host;
      push @requests, $remote->start(
        {
          on_result => sub { $self->print_exec_result($remote, @_) },
          on_progress => sub {
            $stdout->print($host.' '.$_[0].': '.$_[1]);
            $stdout->print("\n") unless $_[1] =~ /\n\Z/;
          }
        },
        command_service => stream_exec => \@command
      );
    } else {
      push @requests, $remote->start(
        { on_result => sub { $self->print_exec_result($remote, @_) } },
        command_service => exec => \@command
      );
    }
  }
  Tak->await_all(@requests);
}

sub print_exec_result {
  my ($self, $remote, $result) = @_;

  my $res = eval { $result->get }
    or do {
      $self->stderr->print("Host ${\$remote->host}: Error: $@\n");
      return;
    };

  my $code = $res->{exit_code};
  $self->stdout->print(
    "Host ${\$remote->host}: ".($code ? "NOT OK ${code}" : "OK")."\n"
  );
  if ($res->{stderr}) {
    $self->stdout->print("Stderr:\n${\$res->{stderr}}\n");
  }
  if ($res->{stdout}) {
    $self->stdout->print("Stdout:\n${\$res->{stdout}}\n");
  }
}

sub each_repl (I=s@;m=s@;M=s@) {
  my ($self, $remote, $options) = @_;
  require Tak::REPL;
  require B;
  $remote->ensure(
    eval_service => 'Tak::EvalService',
    expose => { service_client => [] },
  );
  foreach my $lib (@{$options->{'I'}||[]}) {
    $remote->do(eval_service => eval => "lib->import(${\B::perlstring($lib)})");
  }
  foreach my $module (@{$options->{'m'}||[]}) {
    $remote->do(eval_service => eval => "use ${module} ()");
  }
  foreach my $spec (@{$options->{'M'}||[]}) {
    my ($module, $import) = split('=', $spec);
    my $extra = '';
    if ($import) {
      $extra = ' '.join(', ', map B::perlstring($_), split(',',$import));
    }
    $remote->do(eval_service => eval => "use ${module}${extra}");
  }
  Tak::REPL->new(client => $remote->curry('eval_service'))->run;
}

1;
