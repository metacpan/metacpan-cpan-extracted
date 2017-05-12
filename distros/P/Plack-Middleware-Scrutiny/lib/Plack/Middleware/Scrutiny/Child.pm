package Plack::Middleware::Scrutiny::Child;

use strict;
use warnings;
use Plack::Middleware::Scrutiny::IOWrap;
use Plack::Middleware::Scrutiny::Util;
use IO::String;

sub new { my $class = shift; bless { @_ }, $class }

sub manage_child {
  my ($self) = @_;

  debug child => "waiting for env";
  my ($cmd, $env) = $self->receive('from_parent');

  # If we weren't given an input stream, we gotta proxy-wrap for it.
  # Otherwise let's take the whole input and turn it into a handle.
  if($env->{'psgix.input_string'} ) {
    my $input = IO::String->new($env->{'psgix.input_string'});
    $env->{'psgi.input'} = $input;
  } else {
    my $input = Plack::Middleware::Scrutiny::IOWrap->new( manager => $self );
    $env->{'psgi.input'} = $input;
  }

  debug child => "Loading ebug";
  $ENV{SECRET} = 'bukifra';
  require Enbugger;
  Enbugger->load_debugger('ebug');
  debug child => "Initial stop";
  Enbugger->stop; # Wait for connection and 'run'
  debug child => "Initial run";

  my $q = Plack::Request->new($env);
  debug child => "Checking for immediate break condition";
  if($q->param('_scrutinize')) {
    debug child => "stopping...";
    Enbugger->stop if $q->param('_scrutinize');
  }

  debug child => "Running \$app";
  my $response = $self->{app}->($env);
  debug child => "sending response" => $response;

  $self->send(to_parent => response => $response);
  debug child => "response sent, stopping";
  Enbugger->stop;
  debug child => "existing at last";
  exit;
}

# Until a new Enbugger is released, we'll just fix up the ebug loader
use Enbugger::ebug;

package Enbugger::ebug;
use parent 'Enbugger';
no warnings 'redefine';

sub _load_debugger {
  my ( $class ) = @_;
  $class->_compile_with_nextstate();
  require Devel::ebug::Backend;
  $class->_compile_with_dbstate();
  $class->init_debugger;
  return;
}

sub _stop {
  $DB::signal = 1;
  return;
}

# Back to our regular namespace
package Plack::Middleware::Scrutiny::Child;

1;

