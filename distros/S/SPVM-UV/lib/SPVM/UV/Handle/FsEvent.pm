package SPVM::UV::Handle::FsEvent;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::FsEvent - FsEvent Handle for libuv

=head1 Description

C<UV::Handle::FsEvent> in L<SPVM> represents the file system event handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_fs_event_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::FsEvent;
  use UV::Constant;
  
  my $fs_event = UV::Handle::FsEvent->new;
  
  $fs_event->start(method : void ($fs_event_handle : UV::Handle::FsEvent, $filename : string, $events : int, $status : int) {
      # Called when a file system event occurs
  }, ".", UV::Constant->UV_FS_EVENT_RECURSIVE);

=head1 Fields

=head2 fs_event_cb

C<has fs_event_cb : rw L<UV::Callback::FsEvent|SPVM::UV::Callback::FsEvent>;>

The callback called when a file system event occurs.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::FsEvent|SPVM::UV::Handle::FsEvent> ();>

Creates a new L<UV::Handle::FsEvent|SPVM::UV::Handle::FsEvent> object, and returns it.

=head1 Instance Methods

=head2 start

C<method start : void ($cb : L<UV::Callback::FsEvent|SPVM::UV::Callback::FsEvent>, $path : string, $flags : int);>

Starts the file system event handle with the callback C<$cb>, the target path C<$path>, and options C<$flags>. 

The callback C<$cb> is stored in L</"fs_event_cb"> field.

The callback C<$cb> is invoked when a file system event occurs on C<$path>.

This method calls the L<uv_fs_event_start|https://docs.libuv.org/en/v1.x/fs_event.html#c.uv_fs_event_start> function.

Exceptions:

If $cb is not defined, an exception is thrown.

If $path is not defined, an exception is thrown.

If uv_fs_event_start fails, an exception is thrown.

=head2 stop

C<method stop : void ();>

Stops the file system event handle.

This method calls the L<uv_fs_event_stop|https://docs.libuv.org/en/v1.x/fs_event.html#c.uv_fs_event_stop> function.

Exceptions:

If uv_fs_event_stop fails, an exception is thrown.

=head2 getpath

C<method getpath : string ();>

Gets the path being monitored.

This method calls the L<uv_fs_event_getpath|https://docs.libuv.org/en/v1.x/fs_event.html#c.uv_fs_event_getpath> function, and returns the path string.

Exceptions:

If uv_fs_event_getpath fails, an exception is thrown.

=head1 Details



=head1 Interfaces



=head1 Enumerations



=head1 Well Known Child Classes



=head1 See Also

L<UV::Handle|SPVM::UV::Handle>, L<UV::Callback::FsEvent|SPVM::UV::Callback::FsEvent>, L<UV::Constant|SPVM::UV::Constant>

=head1 Repository



=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
