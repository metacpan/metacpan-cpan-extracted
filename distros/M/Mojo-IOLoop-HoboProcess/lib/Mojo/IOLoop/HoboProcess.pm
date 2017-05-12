###############################################################################
## ----------------------------------------------------------------------------
## Like Mojo::IOLoop::Subprocess, spawns subprocesses with MCE::Hobo instead.
##
###############################################################################

package Mojo::IOLoop::HoboProcess;

use strict;
use warnings;

use Mojo::Base -base;

our $VERSION = '0.005';

## no critic (BuiltinFunctions::ProhibitStringyEval)

use Carp 'croak';
use MCE::Hobo;
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Scalar::Util 'weaken';
use Socket qw( PF_UNIX PF_UNSPEC SOCK_STREAM );

BEGIN {
  $ENV{'MOJO_REACTOR'} ||= 'Mojo::Reactor::Poll' if ($^O eq 'MSWin32');

  unless (Mojo::IOLoop->can('hoboprocess')) {
    # Inject Mojo::IOLoop::hoboprocess, no impact to Mojo::IOLoop::subprocess

    eval '
      sub Mojo::IOLoop::hoboprocess {
        my $ioloop = shift;
        my $subprocess = Mojo::IOLoop::HoboProcess->new;

        weaken $subprocess->ioloop(
          ref $ioloop ? $ioloop : $ioloop->singleton
        )->{"ioloop"};

        return $subprocess->run(@_);
      }
    ';
  }
}

has ioloop => sub { Mojo::IOLoop->singleton };
has timeout => 0;

sub exit { my $self = shift->{'hobo'} || MCE::Hobo->self; $self->exit(@_) }

sub pid { shift->{'pid'} }

sub run {
  my ($self, $child, $parent) = @_;

  # Start the shared-manager process if not already started
  MCE::Shared->start;

  # Make socketpair or pipe for event notification
  my ($reader, $writer);

  if ($^O eq 'MSWin32') {
    socketpair($reader, $writer, PF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or croak "Can't create socketpair: $!";
  }
  else {
    pipe($reader, $writer) or croak "Can't create pipe: $!";
  }

  $writer->autoflush(1);

  # Child
  my $hobo = MCE::Hobo->create({ posix_exit => 1 }, sub {
    close $reader;

    $self->ioloop->reset;
    $self->{'pid'} = MCE::Hobo->pid;

    my $results = eval { [ $self->$child ] } || [];
    my $error = $@; $error = '' if ($error eq "Hobo exited (0)\n");

    $error = "Hobo ". $self->{'pid'} ." exited abnormally"
      if ($error && $error =~ /^Hobo exited \(\S+\)$/);

    print $writer "done\n";
    close $writer;

    [ $error, @{ $results } ];
  });

  croak "Can't spawn Hobo: $!" unless defined($hobo);
  $self->{'hobo'} = $hobo, $self->{'pid'} = $hobo->pid;

  # Parent
  my $me     = $$;
  my $stream = Mojo::IOLoop::Stream->new($reader);

  $stream->timeout($self->timeout);
  $self->ioloop->stream($stream);

  $stream->on( read => sub {
    my $results = eval { $hobo->join };
    my $error = $hobo->error || shift @{ $results };
    $self->$parent($error, @{ $results });
  });

  $stream->on( timeout => sub {
    $hobo->kill('QUIT');
    eval { $hobo->join };
    $self->$parent( "Hobo ". $self->pid ." timed out", () );
  });

  $stream->on( close => sub {
    return unless $$ == $me;
    unless (exists $hobo->{'JOINED'}) {
      eval { $hobo->join };
      $self->$parent( "Hobo ". $self->{'pid'} ." exited abnormally", () );
    }
  });

  return $self;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=encoding utf8

=head1 NAME

Mojo::IOLoop::HoboProcess - Subprocesses with MCE::Hobo

=head1 VERSION

This document describes Mojo::IOLoop::HoboProcess version 0.005.

=head1 SYNOPSIS

  use feature 'say';
  use Mojo::IOLoop::HoboProcess;

  # Operation that would block the event loop for 5 seconds
  my $subprocess = Mojo::IOLoop::HoboProcess->new;

  $subprocess->run(
    sub {
      my $subprocess = shift;
      sleep 5;
      return '♥', 'Mojolicious';
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say "Subprocess error: $err" and return if $err;
      say "I $results[0] $results[1]!";
    }
  );

  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

Like L<Mojo::IOLoop::Subprocess>, spawns subprocesses with MCE::Hobo instead.

L<Mojo::IOLoop::HoboProcess> allows L<Mojo::IOLoop> to perform computationally
expensive operations in subprocesses, without blocking the event loop.

This module is supported on all platforms where L<MCE::Shared> is supported.

=head1 ATTRIBUTES

L<Mojo::IOLoop::HoboProcess> implements the following attribute.

=head2 timeout

  my $timeout = $subprocess->timeout;
  $subprocess->timeout(300);

Set to a non-zero value to enable timeout. The default is 0.

=head2 ioloop

  my $loop    = $subprocess->ioloop;
  $subprocess = $subprocess->ioloop(Mojo::IOLoop->new);

Event loop object to control, defaults to the global L<Mojo::IOLoop> singleton.

=head1 METHODS

L<Mojo::IOLoop::HoboProcess> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 exit

  sub { $^O eq 'MSWin32' ? shift->exit(0) : exit(0) }, # not recommended
  sub { shift->exit(0) }, # do this instead or call MCE::Hobo->exit(0)

  sub { exit(0) }, # safe on Cygwin and UNIX platforms

Exit a thread (Windows) or process (other platforms).

=head2 pid

  my $pid = $subprocess->pid;

  $$.$tid  Windows (only), includes thread id
  $$       Cygwin and UNIX platforms

Process id of the spawned subprocess if available.

=head2 run

  $subprocess = $subprocess->run( sub {...}, sub {...} );

Execute the first callback in a child process and wait for it to return one or
more values, without blocking L</"ioloop"> in the parent process. Then execute
the second callback in the parent process with the results. The return values
of the first callback and exceptions thrown by it, is serialized automatically
by L<MCE::Hobo>, using L<Sereal> 3.015+ if installed or L<Storable> otherwise.

=head2 hoboprocess

The C<hoboprocess> method is injected into Mojo::IOLoop.

  use Mojo::IOLoop;
  use Mojo::IOLoop::HoboProcess;

  my $subprocess = Mojo::IOLoop->hoboprocess( sub {...}, sub {...} );
  my $subprocess = $loop->hoboprocess( sub {...}, sub {...} );

Build Mojo::IOLoop::HoboProcess object to perform computationally expensive
operations in subprocesses, without blocking the event loop. Callbacks will be
passed along to "run" in Mojo::IOLoop::HoboProcess.

  # Concurrent subprocesses
  my ($fail, $result) = ();

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      Mojo::IOLoop->hoboprocess( sub {1}, $delay->begin );
      Mojo::IOLoop->hoboprocess( sub {2}, $delay->begin );
    },
    sub {
      my ( $delay, $err1, $result1, $err2, $result2 ) = @_;
      $fail = $err1 || $err2;
      $result = [ $result1, $result2 ];
    }
  )->wait;

=head1 EXAMPLES

The following is a variation of the synopsis above for demonstrating data
sharing between subprocesses.

  use Mojo::Cache;
  use Mojo::IOLoop::HoboProcess;

  use MCE::Shared;

  # Construct a shared cache and counter variable
  my $cache   = MCE::Shared->share( Mojo::Cache->new( max_keys => 50 ) );
  my $counter = MCE::Shared->scalar(0);

  # Also, construct a shared file handle
  mce_open my $OUT, ">", \*STDOUT or die "$!";

  # Operations that would block the event loop for 3+ seconds
  my $subprocess1 = Mojo::IOLoop::HoboProcess->new;
  my $subprocess2 = Mojo::IOLoop::HoboProcess->new;

  $subprocess1->run(
    sub {
      my $subprocess = shift;
      say $OUT "Subprocess [$$] started";
      $cache->set('key1', 'foo');
      sleep 4;
      my $val = $cache->get('key2');
      return "♥", "Mojolicious lots: $val: " . $counter->incr;
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say $OUT "Subprocess error: $err" and return if $err;
      say $OUT "I $results[0] $results[1]!";
    }
  );

  $subprocess2->run(
    sub {
      my $subprocess = shift;
      say $OUT "Subprocess [$$] started";
      $cache->set('key2', 'baz');
      sleep 3;
      my $val = $cache->get('key1');
      return "♥", "Mojolicious more: $val: " . $counter->incr;
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say $OUT "Subprocess error: $err" and return if $err;
      say $OUT "I $results[0] $results[1]!";
    }
  );

  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

  __END__
  Program output.

  Subprocess [7625] started
  Subprocess [7626] started
  I ♥ Mojolicious more: foo: 1!
  I ♥ Mojolicious lots: baz: 2!

A parallel demonstration for Recurring Monte Carlo Pi Calculation.

  # Original source by Demian Riccardi and Joel Berger.
  # https://gist.github.com/dmr3/e69127ab449bdabd5af7b000c9b5b3b1
  #
  # Parallel demonstration by Mario Roy.

  use Mojolicious::Lite;

  use MCE::Hobo;
  use MCE::Shared;

  any '/' => 'index';

  websocket '/data' => sub {
    my $self = shift;
    my ($pi,$runs,$new_runs) = (0,0,1000000);

    my $timer = Mojo::IOLoop->recurring( 0.1 => sub {
      ($pi,$runs) = calc_pi($pi,$runs,$new_runs);
      $self->send({ json => [$runs,$pi] });
    });

    $self->on( finish => sub {
      Mojo::IOLoop->remove($timer);
    });
  };

  sub gen_data {
    my $x = shift;
    return [ $x, sin( $x + 2*rand() - 2*rand() ) ]
  }

  sub calc_pi {
    my ( $pi, $total_runs, $new_runs ) = @_;

    # use the itr to show how to submit multiples
    my $cnt_pi = MCE::Shared->scalar(
      -1 * ( ( $pi * $total_runs ) / 4 - $total_runs )
    );

    # shared sequence-generator
    my $seq = MCE::Shared->sequence(
      { chunk_size => 10000, bounds_only => 1 },
      1, $new_runs
    );

    # Run
    my $routine = sub {
      while ( my ($beg, $end) = $seq->next ) {
        my ($cnt, $x, $y) = (0);

        foreach ( $beg .. $end ) {
          $x = rand(1);
          $y = rand(1);
          $cnt++ if $x * $x + $y * $y > 1;
        }

        $cnt_pi->incrby($cnt);
      }
    };

    MCE::Hobo->create( $routine ) for ( 1 .. 3 );
    MCE::Hobo->waitall;

    $total_runs += $new_runs;

    $pi = 4 * ( $total_runs - $cnt_pi->get ) / $total_runs;

    return ($pi, $total_runs);
  }

  app->start;

  __DATA__

  @@ index.html.ep
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= title %></title>
    </head>
    <body>
      %= content
    </body>
  <html>

  %= javascript 'https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js'
  %= javascript 'https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.js'

  <div id="plot" style="width:600px;height:300px">
  </div>

  %= javascript begin
    var data = [];
    var plot = $.plot($('#plot'), [ data ]);

    var url = '<%= url_for('data')->to_abs %>';
    var ws = new WebSocket( url );

    ws.onmessage = function(e){
      var point = JSON.parse(e.data);
      data.push(point);
      plot.setData([data]);
      plot.setupGrid();
      plot.draw();
    };
  % end

=head1 ACKNOWLEDGMENTS

L<Mojo::IOLoop::Subprocess> and L<Mojo::IOLoop::Subprocess::Sereal>
were used as templates in the making of this module.

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Mario E. Roy

Mojo::IOLoop::HoboProcess is released under the same license as Perl.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>

L<MCE::Shared>

=cut

