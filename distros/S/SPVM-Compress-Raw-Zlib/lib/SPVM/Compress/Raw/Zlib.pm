package SPVM::Compress::Raw::Zlib;

our $VERSION = "0.004";

1;

=encoding utf8

=head1 Name

SPVM::Compress::Raw::Zlib - Low-Level Interface to zlib compression library

=head1 Description

Compress::Raw::Zlib class in L<SPVM> provides a Perl interface to the I<zlib>
compression libraries.

=head1 Classes

=over 2

=item * L<Compress::Raw::Zlib::Deflate|SPVM::Compress::Raw::Zlib::Deflate>

=item * L<Compress::Raw::Zlib::Inflate|SPVM::Compress::Raw::Zlib::Inflate>

=item * L<Compress::Raw::Zlib::Constant|SPVM::Compress::Raw::Zlib::Constant>

=back

=head1 Class Methods

=head2 gzip

C<static method gzip : void ($input : string, $output_ref : string[], $options : object[] = undef);>

Compresses $input and outputs to $output_ref->[0] with the option $options.

C<AppendOutput> and C<WindowBits> options are set appropriately.

=head2 gunzip

C<static method gunzip : void ($input : string, $output_ref : string[], $options : object[] = undef);>

Uncompresses $input and outputs to $output_ref->[0] with the option $options.

C<AppendOutput> and C<WindowBits> options are set appropriately.

=head1 Repository

L<SPVM::Compress::Raw::Zlib - Github|https://github.com/yuki-kimoto/SPVM-Compress-Raw-Zlib>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

