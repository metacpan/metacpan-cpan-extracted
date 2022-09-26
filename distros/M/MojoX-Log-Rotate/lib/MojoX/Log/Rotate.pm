package MojoX::Log::Rotate;
$MojoX::Log::Rotate::VERSION = '1.222670';
# ABSTRACT: Makes mojolicious log file rotation easy
use Mojo::Base 'Mojo::Log', -signatures;
use Mojo::File;

has 'need_rotate_cb';
has 'rotate_cb';
has last_rotate => sub ($s) { $s->path && -f $s->path ? (stat $s->path)[10] : time() };
has frequency => 60 * 60 * 24; #every day

#for threading supports
has '_thread';
has '_queue';

sub new ($class, %params)  {
  my %p = map  { $_ => delete $params{$_} } 
          grep { exists $params{$_} } 
          qw(frequency how when threaded on_rotate);
  my $self = $class->SUPER::new(%params);

  $self->frequency($p{frequency}) if exists $p{frequency};
  $self->rotate_cb($p{how} // \&default_rotation_cb);
  $self->need_rotate_cb($p{when} // \&default_need_rotation_cb);
  $self->on(rotate => $p{on_rotate}) if exists $p{on_rotate};

  if($p{threaded}) {
    #force calculation of initial last_rotate;
    $self->last_rotate;
    $self->initialize_thread_support;
  }
  else{
    #inject our message subscrition on the top
    my $subscribers = $self->subscribers('message');
    $self->unsubscribe('message');
    $self->on(message => \&on_message_handler);
    $self->on(message => $_) for @$subscribers;
  }


  $self;
}

sub on_message_handler ($self, $level, @args) {
  my $cb_when = $self->need_rotate_cb;
  my $cb_how  = $self->rotate_cb;
  if($cb_when && $cb_how) {
    if(my $when_res = $cb_when->($self)) {
      $self->last_rotate( time() );
      my $how_res = $cb_how->($self, $when_res);
      $self->emit('rotate' => { how => $how_res, when => $when_res });
    }
  }
}

# must returns a false value when there is no need to rotate, or a true value.
# the returns value will be passed to the rotate_cb so that you can share data between callback.
sub default_need_rotation_cb ($self) {
  return unless $self->path;  
  if(time - $self->last_rotate > $self->frequency ) {
    my $last_rotate = $self->last_rotate;
    return { last_rotate => $last_rotate };
  }
  return;
}

sub default_rotation_cb ($self, $when_res) {
  my $res = { }; #nothing to rotate
  if(my $handle = $self->handle) {
    if(-f $self->path) {
      my ($y, $m, $d, $h, $mi, $s) =  (localtime)[5, 4, 3, 2, 1, 0];
      my $suffix = sprintf("_%04d%02d%02d_%02d%02d%02d", $y+1900, $m+1, $d, $h, $mi, $s);
      my $new_name = $self->path =~ s/(\.[^.]+)$/$suffix$1/r;
      $handle->flush;
      $handle->close;
      Mojo::File->new($self->path)->move_to($new_name)
        or die "MojoX::Log::Rotation failed to move " . $self->path . " into $new_name : $!";
      $res = { rotated_file => $new_name };
    }
  }
  $self->handle(Mojo::File->new($self->path)->open('>>'));
  return $res;
}

sub initialize_thread_support ($self) {#may not works well with multiple loggers...
  eval 'use threads; use Thread::Queue; use Mojo::Util';
  my $q = Thread::Queue->new;
  my $appender = \&Mojo::Log::append;
  my $thlog = threads->create(sub {
      while(defined(my $job = $q->dequeue)) {
        $appender->($self, $job->{msg});
        on_message_handler($self, '', '');
      }
  });
  Mojo::Util::monkey_patch('Mojo::Log', 'append', sub {
      my ($self, $msg) = @_;
      $q->enqueue({type => 'msg', msg => $msg});
  });
  $self->_queue($q);
  $self->_thread($thlog);
}

sub stop ($self) {
  $self->_queue->end;
  $self->_thread->join;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MojoX::Log::Rotate - Makes mojolicious log file rotation easy

=head1 VERSION

version 1.222670

=head1 SYNOPSIS

  use MojoX::Log::Rotate;
  my $log = MojoX::Log::Rotate->new( path => 'test.log', frequency => 3600 );
  $app->log($log); #replace the application logger

  # implement a custom rotation behaviour
  my $log = MojoX::Log::Rotate->new( path => 'test.log', how => \&how_to, when => \&when_to);

  sub when_to ($log) {
    # rotate log every 1Mb
    if($log->handle->tell > 1_000_000) {
      return {
        size => $log->handle->tell
      }
    }
    return 0;
  }

  sub how_to ($log, $when_res) {
    # implement your custom log rotation here, or just let's use the default callback
    # you don't even need to specify "how" parameter in the "new"> constructor.
    $log->default_rotation_cb($when_res);
  }

=head1 DESCRIPTION

L<MojoX::Log::Rotate> is a simple extension to L<Mojo::Log> that make file log rotation easy.
The default rotation handlers rotate log file based on a "frequency" parameter. It does not create empty rotated file.

=head1 NAME

MojoX::Log::Rotate - Easy log rotation for Mojolicious

=head1 EVENTS

L<MojoX::Log::Rotate> inherites all events from L<Mojo::Log> and can emit the following one.

=head2 rotate

  $log->on(rotate => sub ($log, $params) {
    $log->info("log file $params->{how}{rotated_file} created");
  });

=head1 ATTRIBUTES

L<MojoX::Log::Rotate> implements the following attributes.

=head2 need_rotate_cb

  my $cb = $log->need_rotate_cb;
  $log->need_rotate_cb(sub ($log){ ... });

A callback called on message event, if it returns a true value the L</"rotate_cb"> will be called with the return value.
It's role is provide the rules to trigger a log rotation.

=head2 rotate_cb

  my $cb = $log->rotate_cb;
  $log->rotate_cb(sub ($log, $need_rotate_result){ ... });

It's role is to provide the log rotation mechanism.
It receives at second argument the value returned by L</"need_rotate_cb">.

=head2 last_rotate

  my $last = $log->last_rotate;
  $log->last_rotate( time );

With the default behaviour it represent the last time a rotation was done.

=head2 frequency

  my $frequency = $log->frequency;
  #set log rotation frequency to 1 hour
  $log->frequency(3600); 

The frequency used in the default behaviour to rotate log, exprimed in seconds.

=head1 METHODS

L<MojoX::Log::Rotate> inherits all methods from L<Mojo::Log> and implements the following new one.

=head2 new

  my $log = MojoX::Log::Rotate->new;
  my $log = MojoX::Log::Rotate->new(path => 'app.log');

  my $log = MojoX::Log::Rotate->new(frequency => 3600);

  my $log = MojoX::Log::Rotate->new(when => sub($log){...}, how => sub($log,$r){...});

The constructor inherits from L<Mojo::Log> constructor and accepts the following additional parameters. 

=head3 when

  Specify the L</"need_rotate_cb"> attribute callback.

=head3 how

  Specify the L</"rotate_cb"> attribute callback.

=head3 frequency

  Set the L</"frequency"> attribute.

=head3 threaded

  Initialize a main thread to centralize mesage and patch L<Mojo::Log/"append"> to redirect
messages into a L<Threaded::Queue> object.

=head3 on_rotate

  Allow to register the C<rotate> event just before create the thread that will process messages.

=head2 stop

  Stop the internal queue and call L<threads/"join"> the main thread.

=head1 DEFAULT BEHAVIOUR

The default behaviour is to rotate the log file based on the node creation time attribute (stat() 10th returned value)
of the filename returned by L<Mojo::Log/"path">. It append the suffix pattern _YYYYMMDD_hhmmss just before the extension.

=head1 LIMITATION

Does not works with call to L<Mojo::Log/"append"> method or any direct access to the underlying file handle.
In C<threaded> mode you cannot register additonal message to the logger, that must be done just before cloning the logger objet in the thread that will process messages.

=head1 SEE ALSO

L<Mojo::Log>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Nicolas Georges xlat@cpan.org ( see fork https://github.com/xlat/mojox-log-rotate)

=head1 COPYRIGHT

Copyright 2022, Nicolas Georges.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except when otherwise stated in writing the copyright holders and/or other parties provide the software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if such holder or other party has been advised of the possibility of such damages.

=cut

=head1 AUTHOR

Nicolas Georges <xlat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Nicolas Georges.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
