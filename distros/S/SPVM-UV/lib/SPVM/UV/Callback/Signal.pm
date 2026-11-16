package SPVM::UV::Callback::Signal;

1;

=encoding utf8

=head1 Name

SPVM::UV::Callback::Signal - Callback for Signal Handle

=head1 Description

C<UV::Callback::Signal> in L<SPVM> is the interface for the callback passed to L<uv_signal_start|https://docs.libuv.org/en/v1.x/signals.html#c.uv_signal_start>.

=head1 Usage

  use UV::Callback::Signal;

=head1 Interface Methods

=head2 Anonymous method

C<required method : void ($uv_signal : L<UV::Handle::Signal|SPVM::UV::Handle::Signal>, $signum : int);>

The callback method called when the signal is received.

See L<UV::Handle::Signal#start|SPVM::UV::Handle::Signal/"start"> method for usage.

=head1 Repository

L<https://github.com/kimoto/SPVM-UV>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
