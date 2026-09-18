package SPVM::UV;

our $VERSION = "0.003";

1;

=encoding utf8

=head1 Name

SPVM::UV - libuv Binding

=head1 Description

UV class in L<SPVM> is a L<libuv|https://libuv.org/> binding.

=head1 Usage

  use UV::Loop;
  use UV::Constant as UV_C;
  
  my $uv_loop = UV::Loop->new;
  
  # Do someting
  
  $uv_loop->run(UV_C->UV_RUN_DEFAULT);
  
Timer:

  use UV::Handle::Timer;
  
  my $timeout_msec = 3_000;
  my $uv_timer = UV::Handle::Timer->new;
  $uv_loop->timer_init($uv_timer);
  my $timer_cb = method : void ($uv_timer : UV::Handle::Timer) {
    
    # Do something
    
    $uv_timer->close;
  };
  $uv_timer->start($timer_cb, $timeout_msec);

Socket IO:

  use UV::Handle::Poll;
  
  my $uv_poll = UV::Handle::Poll->new;
  $uv_loop->poll_init($uv_poll, $fd);
  my $poll_cb = method : void ($uv_poll : UV::Handle::Poll, $status : int, $events : int) {
    
    # Do something
    
    $poll_cb->close;
  };
  
  my $events = UV_C->UV_READABLE | UV_C->UV_WRITABLE;
  $uv_poll->start($poll_cb, $events);

=head1 Class Methods

=head2 strerror

C<static method strerror : string ($status : int);>

Gets human-readable description for an error code by calling L<uv_strerror_r|https://docs.libuv.org/en/v1.x/errors.html#c.uv_strerror_r>, and returns it as a string.

=head1 Modules

=over 2

=item * L<UV::Loop|SPVM::UV::Loop>

=item * L<UV::Constant|SPVM::UV::Constant>

=item * L<UV::Handle|SPVM::UV::Handle>

=item * L<UV::Handle::Idle|SPVM::UV::Handle::Idle>

=item * L<UV::Handle::Pipe|SPVM::UV::Handle::Pipe>

=item * L<UV::Handle::Async|SPVM::UV::Handle::Async>

=item * L<UV::Handle::Stream|SPVM::UV::Handle::Stream>

=item * L<UV::Handle::Timer|SPVM::UV::Handle::Timer>

=item * L<UV::Handle::Poll|SPVM::UV::Handle::Poll>

=item * L<UV::Request|SPVM::UV::Request>

=item * L<UV::Request::Write|SPVM::UV::Request::Write>

=item * L<UV::Callback::Write|SPVM::UV::Callback::Write>

=item * L<UV::Callback::Idle|SPVM::UV::Callback::Idle>

=item * L<UV::Callback::Async|SPVM::UV::Callback::Async>

=item * L<UV::Callback::Read|SPVM::UV::Callback::Read>

=item * L<UV::Callback::Close|SPVM::UV::Callback::Close>

=item * L<UV::Callback::Timer|SPVM::UV::Callback::Timer>

=item * L<UV::Callback::Poll|SPVM::UV::Callback::Poll>

=back

=head1 Repository

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License

