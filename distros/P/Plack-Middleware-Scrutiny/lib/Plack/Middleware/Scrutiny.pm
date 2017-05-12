package Plack::Middleware::Scrutiny;
our $VERSION = '0.02';

=head1 NAME

Plack::Middleware::Scrutiny - Scrutinize your [psgi] app with an [inline] debugger

=head1 SYNPOSIS

  # This uses AnyEvent, so go with twiggy

  builder {
    enable 'Scrutiny';
    $app;
  };

  # Now pass ?_scrutinize=1 to your app, and you'll get an inline debugger

=head1 DESCRIPTION

THIS IS A PROOF OF CONCEPT, MUCH WORK REMAINS!

Status: Kinda works!

This middleware adds an in-band debugger to your web application. When triggered (via a query string), your C<< $app >> is executed in a forked context under the L<Devel::ebug> debugger. Instead of getting your application output, you get a web-based debugger UI so you can step through your program's execution.

=head1 WHY

I was wondering why people don't use the perl debugger more. I did some very unscientific interviews and came up with the idea that it isn't that people are horribly opposed (though some are), but rather that it just isn't at their fingertips. Unlike Firebug, or even prints to STDERR, firing up the debugger is a bit of complication that doesn't seem worth the effort.

I'm hoping that putting C<< enable 'Scrutiny' >> into your L<Plack::Builder> setup will be worth the effort. Once this is working I'll probably look around for other ways to make this easy (like work on L<CGI::Inspect>).

=head1 HOW

When this middleware is activated, right now by the C<< _scrutinize=1 >> query param, it takes over the request. It forks into a parent and a child. The parent is what will talk to your browser for the debugging session, and the child is where your C<$app> is actually executed. It opens a set of unix pipes to talk back and forth.

From there, the child uses L<Enbugger> to load up L<Devel::ebug::Backend> and gets ready to be debugged. Meanwhile the parent sets up L<Devel::ebug> to talk to the child. I initially did this with L<Debug::Client>, and that worked but I like the concept of L<Devel::ebug> a bit better.

Finally, the parent outputs some HTML back to the browser with the actual UI. Future interactions from the browser are intercepted by the parent and considered commands to the debugger until the C<$app> has completed its execution. Upon completion, the output from C<$app> is finally sent to the browser instead of the debugger UI.

=head1 INTERNAL METHODS

This is documentation for maintainers, not for users.

=cut

use strict;
use warnings;
use parent 'Plack::Middleware';
use IO::Handle;
use Data::Dumper;
use Plack::Request;
use Try::Tiny;
use File::ShareDir;
use Plack::App::File;
use Plack::Util::Accessor qw( files );
use Plack::Util;
use Plack::Middleware::Scrutiny::Util;
use Plack::Middleware::Scrutiny::IOWrap;
use Plack::Middleware::Scrutiny::Child;
#use lib '/home/awwaiid/projects/perl/Devel-ebug/lib';

=head2 $scrutiny->prepare_app

This gets called on middleware instantiation. All we need to do is get our static files set up.

=cut

sub prepare_app {
  my $self = shift;
  my $root = try { File::ShareDir::dist_dir('Plack-Middleware-Scrutiny') }
    || 'share';
  $self->files(Plack::App::File->new(root => $root));
}

=head2 $scrutiny->call($env)

Process a request. Here we split into two modes - either we are already in the debugger and need to display that UI, or we are working on a new request and need to get the parent/child setup going.

Also we might want to serve some static files for the debugger UI.

=cut

sub call {
  my($self, $env) = @_;
  debug parent => "got ->call ($env->{PATH_INFO})";

  # If the URL contains /scrutinize/, then send static files
  if ($env->{PATH_INFO} =~ m!/scrutinize/!) {
    $env->{PATH_INFO} =~ s!.*/scrutinize/!/!;
    return $self->files->call($env);
  }

  # my $q = Plack::Request->new($env);
  # if(!$self->{in_debugger} && !$q->param('_scrutinize')) {
    # debug parent => "Calling original app\n";
    # return $self->{app}->($env);
  # }

  return sub {
    my $respond = shift;
    if($self->{in_debugger}) {
      debug parent => "Already in debugger";
      return $self->in_debugger($env, $respond);
    } else {
      debug parent => "Starting new debugger";
      $self->{in_debugger} = 1;
      return $self->new_request($env, $respond);
    }
  };
}

=head2 $scrutiny->new_request($env, $respond_cb)

This is a new request. After calling out to get the child started, we'll start watching for responses from the child.

=cut

sub new_request {
  my ($self, $env, $respond) = @_;

  $self->start_child;

  # If the child says anything, we'll deal with it
  $self->{child_watcher} = AnyEvent->io(
    fh => $self->{from_child},
    poll => 'r',
    cb => sub {
      debug parent => "waiting for response";
      my ($cmd, $val) = $self->receive('from_child');

      if($cmd eq 'response') {
        debug parent => "got response: " . Dumper($val);
        $self->{response} = $val;
        # We're done, kill watcher
        delete $self->{child_watcher};
        #return $val;

      } elsif( $cmd eq 'read' ) {
        my ($len, $offset) = @$val;
        my $buf;
        my $read_retval = $env->{'psgi.input'}->read($buf, $len, $offset);
        $self->send( to_child => read_result => [$buf, $read_retval], 1 );

      } elsif( $cmd eq 'seek' ) {
        my ($position, $whence) = @$val;
        my $buf;
        my $seek_retval = $env->{'psgi.input'}->seek($position, $whence);
        $self->send( to_child => read_result => [$seek_retval], 1);
      }
    }
  );
  
  debug parent => "fixing env";
  my $env_trimmed = {%$env}; # shallow copy
  delete $env_trimmed->{'psgi.input'};
  delete $env_trimmed->{'psgix.io'};
  delete $env_trimmed->{'psgi.errors'};

  # We're doing InlineMode, so let's slurp the input
  my $q = Plack::Request->new($env);
  my $input = $q->content;
  $env_trimmed->{'psgix.input_string'} = $input;

  # Get the child running
  debug parent => "sending fixed env";
  $self->send( to_child => request => $env_trimmed );
  # sleep 1; # Give the client a second to get started

  debug parent => "Creating debug client";
  require Devel::ebug;
  $self->{debug_client} = Devel::ebug->new;

  debug parent => "trying to connect to child debugger";
  $self->{debug_client}->attach(4011, 'bukifra');
  debug parent => "connected!";
  debug parent => "Telling child via debugger to run";
  $self->{debug_client}->run();

  # This will give the child handler a chance to receive a response from the
  # child, if any
  # sleep 1;
  debug parent => "Setting up idle UI handler";
  $self->{idle} = AnyEvent->idle(
    cb => sub { $self->in_debugger($env, $respond) }
  );
}

sub in_debugger {
  my ($self, $env, $respond) = @_;
  my $q = Plack::Request->new($env);

  # Child has completed? If so just give that back
  # sleep 5;
  debug parent => "Looking for response";
  if($self->{response}) {
    debug parent => "got response, sending to browser";
    $self->{in_debugger} = 0;
    delete $self->{idle};
    return $respond->($self->{response});
  }

  my $cmd = $q->param('cmd') || 'codeline';
  my $out;
  debug parent => "sending $cmd to debugger";
  $out = $self->{debug_client}->$cmd;

  $self->{idle} = AnyEvent->idle( cb => sub {
  debug parent => "getting codelines from debugger";
  $out = $self->show_codelines(30);

  my @trace = $self->{debug_client}->stack_trace_human;
  my $stacktrace = join "\n", @trace;
  $stacktrace = Plack::Util::encode_html($stacktrace);

  my $pad_txt = '';
  my $pad = $self->{debug_client}->pad_human;
  foreach my $k (sort keys %$pad) {
    my $v = $pad->{$k};
    $pad_txt .= "  $k = $v;\n";
  }
  $pad_txt = Plack::Util::encode_html($pad_txt);

  $self->{eval_txt} ||= '';
  my ($stdout, $stderr) = $self->{debug_client}->output;
  $self->{eval_txt} .= $stdout;
  # $self->{eval_txt} .= $stderr;
  if($q->param('eval')) {
    my $v = $self->{debug_client}->eval( $q->param('eval') );
    $v = Dumper($v);
    $self->{eval_txt} .= $v;
  }
  my $eval_txt = Plack::Util::encode_html( $self->{eval_txt} );
  
  # Child has completed? If so just give that back
  if($self->{response}) {
    debug parent => "got response, sending to browser";
    $self->{in_debugger} = 0;
    delete $self->{debug_client};
    delete $self->{idle};
    return $respond->($self->{response});
  }

  my $line = $self->{debug_client}->line;
  my $subroutine = $self->{debug_client}->subroutine;
  my $package = $self->{debug_client}->package;

  delete $self->{idle};
  return $respond->([
    200,
    ['Content-type' => 'text/html'],
    [qq|
      <html>
        <head>
          <link rel="stylesheet" type="text/css" href="/scrutinize/scrutinize.css" />
          <script type="text/javascript" src="/scrutinize/jquery.js"></script>
          <script type="text/javascript" src="/scrutinize/jquery.cookie.js"></script>
          <script type="text/javascript" src="/scrutinize/splitter.js"></script>
          <script type="text/javascript">
            \$(function(){
              \$('#MySplitter').splitter({
                splitVertical: true,
                outline: true,
                resizeTo: window,
                cookie: 'mysplitter',
                sizeLeft: true
              });
            });
          </script>
        </head>
        <body>
          <h1>Scrutiny!</h1>
          <div id="controls">
            <a href="?cmd=step">Step In</a>
            <a href="?cmd=next">Step Over</a>
            <a href="?cmd=return">Return</a>
            <a href="?cmd=run">Run</a>
          </div>
          <div id=MySplitter>
            <div>
              <h2>Code</h2>
              $package\::$subroutine ($line)
              <div class="perlCode">$out</div>
              <h2>REPL</h2>
              <pre>$eval_txt</pre>
              &gt; <form id=evalform method=GET action="/"><input id=eval type=text name=eval></form>
            </div>
            <div>
              <h2>Vars</h2>
              <pre>$pad_txt</pre>
            <h2>Stack Trace</h2>
            <pre>$stacktrace</pre>
            </div>
          </div>
        </body>
      </html>
    |]
  ]);

  });
}

my $codelines;
sub show_codelines {
  my ($self, $list_lines_count) = @_;
  debug parent => "building html for codelines";
  my $ebug = $self->{debug_client};

  my $line_count = int($list_lines_count / 2);

  debug parent => "about to get codelines for file";
  eval {
  if (not exists $codelines->{$ebug->filename}) {
    $codelines->{$ebug->filename} = [$ebug->codelines];
  }
  };
  debug parent => "err - $@";
  debug parent => "got codelines for file";
  return unless $codelines->{$ebug->filename};

  my @span = ($ebug->line-$line_count .. $ebug->line+$line_count);
  @span = grep { $_ > 0 } @span;
  my @codelines = @{$codelines->{$ebug->filename}};
  my @break_points = $ebug->break_points();
  my %break_points;
  $break_points{$_}++ foreach @break_points;
  my $out = '';
  debug parent => "building each line for codelines";
  foreach my $s (@span) {
    my $line_out = '';
    my $codeline = $codelines[$s -1 ];
    $codeline = Plack::Util::encode_html($codeline);
    next unless defined $codeline;
    if ($s == $ebug->line) {
      $line_out .= "*";
    } elsif ($break_points{$s}) {
      $line_out .= "b";
    } else {
      $line_out .= " ";
    }
    $line_out .= "$s:$codeline\n";
    # $line_out =~ s/(.{1,80})/$1\n/gs;
    $line_out = "<span class=codeline>$line_out</span>";
    if($s == $ebug->line) {
      $line_out = "<span class='curline'>$line_out</span>"
    }
    $out .= $line_out;
  }
  debug parent => "Returning codelines as html";
  return $out;
}

sub start_child {
  my ($self) = @_;

  my ($to_child,  $from_child);
  my ($to_parent, $from_parent);

  pipe($from_child,  $to_parent);
  pipe($from_parent, $to_child);

  $to_child->autoflush(1);
  $to_parent->autoflush(1);

  my $pid = fork();
  if(!$pid) {
    # child
    my $child = Plack::Middleware::Scrutiny::Child->new(
      to_parent   => $to_parent,
      from_parent => $from_parent,
      to_child   => $to_child,
      from_child => $from_child,
      app         => $self->{app},
    );
    $child->manage_child;
    exit;

  } else {
    # parent
    debug parent => "saving child pid $pid";
    $self->{child_pid} = $pid;
    $self->{to_child}    = $to_child;
    $self->{to_parent}   = $to_parent;
    $self->{from_child}    = $from_child;
    $self->{from_parent}   = $from_parent;
  }
}


=head1 BUGS

TONS I'm sure :)

This is still just a sketch.

One thing that I've found annoying is that 'step' doesn't actually seem to step over things. Along the same lines, this doesn't walk over the $app the way I expect/want.

=head1 TODO

There are a TON of ways this could be taken, especially since this is just a proof-of-concept so far. Some things are probably needed pretty soon, such as session based debugging (right now ALL new requests go to the debugger).

One significant thing that I'd like to do is to provide a more advanced separate window mode. In this mode you could explore code and set breakpoints (including on the path/query), and get a list of sessions that are currently awaiting your debugging. Selecting one would enter you into a debugging session. Handy for AJAXy stuff I think.

=head1 SEE ALSO

Code is on github: L<http://github.com/awwaiid/Scrutiny>

Other fun stuff: L<Plack::Middleware>, L<Plack::Middleware::Debug>, L<Plack::Middleware::InteractiveDebugger>, L<Devel::ebug>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2011 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

1;

