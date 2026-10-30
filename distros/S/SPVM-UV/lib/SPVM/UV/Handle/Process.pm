package SPVM::UV::Handle::Process;

use strict;
use warnings;

1;

=encoding utf8

=head1 Name

L<SPVM::UV::Handle::Process|SPVM::UV::Handle::Process> - libuv Process Handle

=head1 Description

C<UV::Handle::Process> class in L<SPVM> represents a process handle in L<libuv|https://libuv.org/>. See L<uv_process_t|https://docs.libuv.org/en/v1.x/process.html#c.uv_process_t>.

=head1 Usage

  use UV::Handle::Process;

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Fields

=head2 exit_cb

C<has exit_cb : L<UV::Callback::Exit|SPVM::UV::Callback::Exit>;>

The exit callback associated with this process handle.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::Process|SPVM::UV::Handle::Process> ();>

Creates a new L<libuv process handle|https://docs.libuv.org/en/v1.x/process.html#c.uv_process_t>.

=head1 Instance Methods

=head2 pid

C<method pid : int ();>

Gets the process ID (PID). See L<uv_process_t#pid|https://docs.libuv.org/en/v1.x/process.html#c.uv_process_t>.

=head2 kill

C<method kill : int ($signum : int);>

Sends a signal to the process. See L<uv_process_kill|https://docs.libuv.org/en/v1.x/process.html#c.uv_process_kill>.

=head2 DESTROY

C<method DESTROY : void ();>

Destroys the process handle and releases its resources.

=head1 Repository

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
