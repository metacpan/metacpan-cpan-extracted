package Mojolicious::Plugin::Airbrake;

use 5.010001;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use Data::Dumper;

our $VERSION = '0.01';

has 'api_key';
has 'airbrake_base_url' => 'https://airbrake.io/api/v3/projects/';
has 'ua' => sub { Mojo::UserAgent->new() };
has 'project_id';
has 'pending' => sub { {} };
has 'include_session' => 1;
has 'debug' => 0;

has url => sub {
  my $self = shift;

  return $self->airbrake_base_url . $self->project_id . '/notices?key=' . $self->api_key;
};

has user_id_sub_ref => sub {
  return sub {
    return 'n/a';
  }
};

sub register {
  my ($self, $app, $conf) = (@_);
  $conf ||= {};
  $self->{$_} = $conf->{$_} for keys %$conf;

  $self->_hook_after_dispatch($app);
  $self->_hook_on_message($app);

}

sub _hook_after_dispatch {
  my $self = shift;
  my $app = shift;

  $app->hook(after_dispatch => sub {
    my $c = shift;

    if (my $ex = $c->stash('exception')) {
      # Mark this exception as handled. We don't delete it from $pending
      # because if the same exception is logged several times within a
      # 2-second period, we want the logger to ignore it.
      $self->pending->{$ex} = 0 if defined $self->pending->{$ex};
      $self->notify($ex, $app, $c);
    }

  });

}

sub _hook_on_message {
  my $self = shift;
  my $app = shift;

  $app->log->on(message => sub {
      my ($log, $level, $ex) = @_;
      if ($level eq 'error') {
        $ex = Mojo::Exception->new($ex) unless ref $ex;
   
        # This exception is already pending
        return if defined $self->pending->{$ex};
   
        $self->pending->{$ex} = 1;
   
        # Wait 2 seconds before we handle it; if the exception happened in
        # a request we want the after_dispatch-hook to handle it instead.
        Mojo::IOLoop->timer(2 => sub {
          $self->notify($ex, $app) if delete $self->pending->{$ex};
        });
      }

  });
}

sub notify {
  my ($self, $ex, $app, $c) = @_;

  my $call_back = sub { };

  if($self->debug) {
    $call_back = sub { 
      print STDERR "Debug airbrake callback: " . Dumper(\@_);
    };
  }


  my $tx = $self->ua->post($self->url => json => $self->_json_content($ex, $app, $c), $call_back );



}

sub _json_content {
  my $self = shift;
  my $ex = shift;
  my $app = shift;
  my $c = shift;

  my $json = {
    notifier => {
      name => 'Mojolicious::Plugin::Airbrake',
      version => $VERSION,
      url => 'https://github.com/jontaylor/Mojolicious-Plugin-Airbrake'
    }
  };

  $json->{errors} = [{
    type => ref $ex,
    message => $ex->message,
    backtrace => [],
  }];

  foreach my $frame (@{$ex->frames}) {
    my ($package, $file, $line, $subroutine) = @$frame;
    push @{$json->{errors}->[0]->{backtrace}}, {
      file => $file, line => $line, function => $subroutine
    };
  }

  $json->{context} = {
    environment => $app->mode,
    rootDirectory => $app->home
  };

  if($c) {

    $json->{url} = $c->req->url->to_abs;
    $json->{component} = ref $c;
    $json->{action} = $c->stash('action');
    $json->{userId} = $self->user_id_sub_ref->($c);

    $json->{environment} = { map { $_ => "".$c->req->headers->header($_) } (@{$c->req->headers->names}) };
    $json->{params} = { map { $_ => string_dump($c->param($_))  } ($c->param) };
    $json->{session} = { map { $_ => string_dump($c->session($_))  } (keys %{$c->session}) } if $self->include_session;
  }

  return $json;

}

sub string_dump {
  my $obj = shift;
  ref $obj ? Dumper($obj) : $obj;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mojolicious::Plugin::Airbrake

=head1 SYNOPSIS

  $self->plugin('Airbrake' => {
    api_key => "yourapikey",
    project_id => "ID from airbrake for the project"
  });

=head1 DESCRIPTION

Submit application errors to Airbrake.io

=head2 EXPORT

None by default.



=head1 SEE ALSO

Please see this PasteBin entry: http://pastebin.com/uaCS5q9w

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@stackhaus.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
