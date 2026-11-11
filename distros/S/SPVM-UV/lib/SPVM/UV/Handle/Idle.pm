package SPVM::UV::Handle::Idle;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::Idle - Idle Handle for libuv

=head1 Description

C<UV::Handle::Idle> in L<SPVM> represents the idle handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_idle_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::Idle;
  
  my $idle = UV::Handle::Idle->new;

=head1 Fields

=head2 idle_cb

C<has idle_cb : rw L<UV::Callback::Idle|SPVM::UV::Callback::Idle>;>

The callback called when the idle handle is active.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::Idle|SPVM::UV::Handle::Idle> ();>

Creates a new L<UV::Handle::Idle|SPVM::UV::Handle::Idle> object, and returns it.

=head1 Instance Methods

=head2 start

C<method start : void ($cb : L<UV::Callback::Idle|SPVM::UV::Callback::Idle>);>

Starts the idle handle with the callback C<$cb>. 

The callback C<$cb> is stored in L</"idle_cb"> field.

The callback C<$cb> is invoked when the idle handle is active.

This method calls the L<uv_idle_start|https://docs.libuv.org/en/v1.x/idle.html#c.uv_idle_start> function.

Exceptions:

If $cb is not defined, an exception is thrown.

If uv_idle_start fails, an exception is thrown.

=head2 stop

C<method stop : void ();>

Stops the idle handle.

This method calls the L<uv_idle_stop|https://docs.libuv.org/en/v1.x/idle.html#c.uv_idle_stop> function.

Exceptions:

If uv_idle_stop fails, an exception is thrown.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
