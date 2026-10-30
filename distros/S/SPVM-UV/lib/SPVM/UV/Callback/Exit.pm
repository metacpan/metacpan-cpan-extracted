package SPVM::UV::Callback::Exit;



1;

=encoding utf8

=head1 Name

SPVM::UV::Callback::Exit - Callback for Process Exit

=head1 Description

C<UV::Callback::Exit> in L<SPVM> is the interface for the callback passed to L<uv_spawn|https://docs.libuv.org/en/v1.x/process.html#c.uv_spawn>.

=head1 Usage

  use UV::Callback::Exit;

=head1 Interface Methods

=head2 Anonymous method

C<required method : void ($uv_process : L<UV::Handle::Process|SPVM::UV::Handle::Process>, $exit_status : long, $term_signal : int);>

The callback method called when the process has exited.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
