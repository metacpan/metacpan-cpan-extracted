package POE::Component::RemoteTail;

use strict;
use warnings;
use Debug::STDERR;
use POE;
use POE::Wheel::Run;
use POE::Component::RemoteTail::Job;
use Class::Inspector;
use UNIVERSAL::require;
use Carp;

our $VERSION = '0.01011';

$|++;

sub spawn {
    my $class = shift;
    my $self  = $class->new(@_);

    $self->{alias} ||= "tailer";
    $self->{session_id} =
      POE::Session->create(
        object_states => [ $self => Class::Inspector->methods($class) ], )
      ->ID();

    return $self;
}

sub new {
    my $class = shift;

    return bless {@_}, $class;
}

sub session_id {
    return shift->{session_id};
}

sub job {
    my $self = shift;

    my $job = POE::Component::RemoteTail::Job->new(@_);
    return $job;
}

sub start_tail {
    my ( $self, $kernel, $session, $heap, $arg ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0 ];

    $arg->{postback} and $heap->{postback} = $arg->{postback};
    $arg->{postback_handler}
      and $heap->{postback_handler} = $arg->{postback_handler};
    $kernel->post( $session, "_spawn_child" => $arg->{job} );
}

sub stop_tail {
    my ( $self, $kernel, $session, $heap, $arg ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0 ];
    my $job = $arg->{job};
    debug("STOP:$job->{id}");
    my $wheel = $heap->{wheel}->{ $job->{id} };
    $wheel->kill(9);
    delete $heap->{wheel}->{ $job->{id} };
    delete $heap->{host}->{ $job->{id} };
    undef $job;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $kernel->alias_set( $self->{alias} );
    $kernel->sig( HUP  => "_stop" );
    $kernel->sig( INT  => "_stop" );
    $kernel->sig( QUIT => "_stop" );
    $kernel->sig( TERM => "_stop" );
}

sub _stop {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];
    while ( my ( $whee_id, $wheel ) = each %{ $heap->{wheel} } ) {
        $wheel and $wheel->kill(9);
    }
}

sub _spawn_child {
    my ( $self, $kernel, $session, $heap, $job, $sender ) =
      @_[ OBJECT, KERNEL, SESSION, HEAP, ARG0, SENDER ];

    # prepare ...
    my $class       = $job->{process_class};
    my $host        = $job->{host};
    my $path        = $job->{path};
    my $user        = $job->{user};
    my $ssh_options = $job->{ssh_options};
    my $add_command = $job->{add_command};

    my $command = "ssh -A";
    $command .= ' ' . $ssh_options if $ssh_options;
    $command .= " $user\@$host \"tail -F $path";
    $command .= ' ' . $add_command if $add_command;
    $command .= '"';

    # default Program ( go on a simple unix command )
    my %program = ( Program => $command );

    # use custom class
    if ( my $class = $job->{process_class} ) {
        $class->require or die(@!);
        $class->new();
        %program = ( Program => sub { $class->process_entry($job) }, );
    }

    $SIG{CHLD} = "IGNORE";

    # run wheel
    my $wheel = POE::Wheel::Run->new(
        %program,
        StdioFilter => POE::Filter::Line->new(),
        StdoutEvent => "_got_child_stdout",
        StderrEvent => "_got_child_stderr",
        CloseEvent  => "_got_child_close",
    );

    my $id = $wheel->ID;
    $heap->{wheel}->{$id} = $wheel;
    $heap->{host}->{$id}  = $host;
    $job->{id}            = $id;
}

sub _got_child_stdout {
    my ( $kernel, $session, $heap, $stdout, $wheel_id ) =
      @_[ KERNEL, SESSION, HEAP, ARG0, ARG1 ];
    debug("STDOUT:$stdout");

    my $host = $heap->{host}->{$wheel_id};

    if ( $heap->{postback}
        and ref $heap->{postback} eq 'POE::Session::AnonEvent' )
    {
        $heap->{postback}->( $stdout, $host );
    }
    elsif ( $heap->{postback_handler}->{child_stdout}
        and ref $heap->{postback_handler}->{child_stdout} eq
        'POE::Session::AnonEvent' )
    {
        $heap->{postback_handler}->{child_stdout}->( $stdout, $host );
    }
    else {
        print $stdout, $host, "\n";
    }
}

sub _got_child_stderr {
    my ( $heap, $stderr ) = @_[ HEAP, ARG0 ];
    debug("STDERR:$stderr");
    if ( $heap->{postback_handler}->{child_stderr}
        and ref $heap->{postback_handler}->{child_stderr} eq
        'POE::Session::AnonEvent' )
    {
        $heap->{postback_handler}->{child_stderr}->($stderr);
    }
    else {
        carp("ERROR: $stderr");
    }
}

sub _got_child_close {
    my ( $heap, $wheel_id ) = @_[ HEAP, ARG0 ];
    delete $heap->{wheel}->{$wheel_id};
    my $host = $heap->{host}->{$wheel_id};
    debug("CLOSE:$host");
    if ( $heap->{postback_handler}->{child_close}
        and ref $heap->{postback_handler}->{child_close} eq
        'POE::Session::AnonEvent' )
    {
        $heap->{postback_handler}->{child_close}->($host);
    }
    else {
        carp("connection was closed by $host:");
    }
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail - tail to remote server's access_log on ssh connection.

=head1 SYNOPSIS

  use POE;
  use POE::Component::RemoteTail;
  
  my ( $host, $path, $user ) = @target_host_info;
  
  # spawn component
  my $tailer = POE::Component::RemoteTail->spawn();
  
  # create job
  my $job = $tailer->job(
      host          => $host,
      path          => $path,
      user          => $user,
      ssh_options   => $ssh_options, # see POE::Component::RemoteTail::Job
      add_command   => $add_command, # see POE::Component::RemoteTail::Job
  );
  
  # prepare the postback subroutine at main POE session
  POE::Session->create(
      inline_states => {
          _start => sub {
              my ( $kernel, $session ) = @_[ KERNEL, SESSION ];
              # create postback_handler
              my $postback_handler = {
                  child_stdout => $session->postback("child_stdout"),
                  child_stderr => $session->postback("child_stderr"),
                  child_close  => $session->postback("child_close"),
              }; 
              # post to execute
              $kernel->post( tailer => start_tail => { 
                  job => $job, postback_handler => $postback_handler } );
          },
  
          # return to here
          child_stdout => sub {
              my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
              my $log  = $data->[0];
              my $host = $data->[1];
              ... do something ...;
          },
          child_stderr => sub {
              my $data          = $_[ARG1];
              my $error_message = $data->[0];
              ... do something ...;
          }
          child_close => sub {
              my $data        = $_[ARG1];
              my $closed_host = $data->[0];
              ... do something ...;
          }
      },
  );
  
  POE::Kernel->run();


=head1 DESCRIPTION

POE::Component::RemoteTail provides some loop events that tailing access_log on remote host.
It replaces "ssh -A user@host tail -F access_log" by the same function.
( 'tail -F' is same as 'tail --follow=name --retry') 


This moduel does not allow 'PasswordAuthentication'. 
Use RSA or DSA keys, or you must write your Custom Engine with this module.
( ex. POE::Component::RemoteTail::CustomEngine::NetSSHPerl.pm )


=head1 EXAMPLE

Unless you prepare the 'postback_handler', PoCo::RemoteTail outputs child process's STDOUT, STDERR and closed host name.

  use POE::Component::RemoteTail;
  
  my $tailer = POE::Component::RemoteTail->spawn();
  my $job = $tailer->job( host => $host, path => $path, user => $user );
  POE::Session->create(
      inlines_states => {
          _start => sub {
              $kernel->post($tailer->session_id, "start_tail" => {job => $job}); 
          },
      }
  );
  POE::Kernel->run();


It can tail several servers at the same time.

  use POE::Component::RemoteTail;
  
  my $tailer = POE::Component::RemoteTail->spawn(alias => $alias);

  my $job_1 = $tailer->job( host => $host1, path => $path, user => $user );
  my $job_2 = $tailer->job( host => $host2, path => $path, user => $user );

  POE::Session->create(
      inlines_states => {
          _start => sub {
              my $postback_handler = {
                  child_stdout => $session->postback("child_stdout"),
                  child_stderr => $session->postback("child_stderr"),
                  child_close  => $session->postback("child_close"),
              }; 
              $kernel->post($alias, "start_tail" => {job => $job_1, postback_handler => $postback_handler }); 
              $kernel->post($alias, "start_tail" => {job => $job_2, postback_handler => $postback_handler }); 
              $kernel->delay_add("stop_tail", 10, [ $job_1 ]);
              $kernel->delay_add("stop_tail", 20, [ $job_1 ]);
          },
          child_stdout => sub {
              my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
              my $log  = $data->[0];
              my $host = $data->[1];
              ... do something ...;
          },
          child_stderr => sub {
              my $data          = $_[ARG1];
              my $error_message = $data->[0];
              ... do something ...;
          }
          child_close => sub {
              my $data        = $_[ARG1];
              my $closed_host = $data->[0];
              ... do something ...;
          stop_tail => sub {
              my ( $kernel, $session, $arg ) = @_[ KERNEL, SESSION, ARG0 ];
              my $target_job = $arg->[0];
              $kernel->post( $alias, "stop_tail" => {job => $target_job});
          },
      },
  );
  POE::Kernel->run();


=head1 METHOD

=head2 spawn()

=head2 job()

=head2 start_tail()

=head2 stop_tail()

=head2 session_id()

=head2 debug()

=head2 new()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
