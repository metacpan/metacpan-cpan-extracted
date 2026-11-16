package SPVM::UV::Callback::FsEvent;



1;

=encoding utf8

=head1 Name

SPVM::UV::Callback::FsEvent - Callback for FsEvent Handle

=head1 Description

C<UV::Callback::FsEvent> in L<SPVM> is the interface for the callback passed to L<uv_fs_event_start|https://docs.libuv.org/en/v1.x/fs_event.html#c.uv_fs_event_start>.

=head1 Usage

  use UV::Callback::FsEvent;

=head1 Details



=head1 Interface Methods

=head2 Anonymous method

C<required method : void ($fs_event : L<UV::Handle::FsEvent|SPVM::UV::Handle::FsEvent>, $filename : string, $events : int, $status : int);>

The callback method called when a file system event occurs.

See L<UV::Handle::FsEvent#start|SPVM::UV::Handle::FsEvent/"start"> method for usage.

=head1 Repository



=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
