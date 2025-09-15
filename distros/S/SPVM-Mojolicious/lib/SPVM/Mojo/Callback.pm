package SPVM::Mojo::Callback;



1;

=head1 Name

SPVM::Mojo::Callback - Callback for Mojo::EventEmitter

=head1 Description

Mojo::Callback interface in L<SPVM> is the callback for L<Mojo::EventEmitter|SPVM::Mojo::EventEmitter> class.

=head1 Usage

  interface Mojo::Callback;

=head1 Interface Methods

C<required method : void ($that : object, $arg1 : object = undef, $arg2 : object = undef, $arg3 : object = undef);>

A callback executed by L<Mojo::EventEmitter#emit|SPVM::Mojo::EventEmitter/"emit"> method.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

