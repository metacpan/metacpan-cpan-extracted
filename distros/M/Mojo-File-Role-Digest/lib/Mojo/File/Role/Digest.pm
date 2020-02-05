package Mojo::File::Role::Digest;
use Mojo::Base -strict, -role, -signatures;

our $VERSION = '0.04';

requires 'open';

use Carp 'croak';
use Digest::MD5;
use Digest::SHA;

use constant SUPPORTS_QX =>
  !!(eval { require Digest::QuickXor; Digest::QuickXor->VERSION('0.03'); 1 });

# methods

sub md5_sum ($self) {
  return $self->_calcdigest(Digest::MD5->new);
}

sub quickxor_hash ($self) {
  croak 'Digest::QuickXor not available!' unless SUPPORTS_QX;
  return $self->_calcdigest(Digest::QuickXor->new, 'b64digest');
}

sub sha1_sum ($self) {
  return $self->_calcdigest(Digest::SHA->new(1));
}

sub sha256_sum ($self) {
  return $self->_calcdigest(Digest::SHA->new(256));
}

# internal methods

sub _calcdigest ($self, $module, $fn = 'hexdigest') {
  return -f $self ? $module->addfile($self->open('<'))->$fn : '';
}

1;

=encoding utf8

=head1 NAME

Mojo::File::Role::Digest - A role for Mojo::File to calculate digests

=head1 SYNOPSIS

    # single file
    use Mojo::File 'path';
    my $file = path($path)->with_roles('+Digest');

    # modified file class
    use Mojo::File;
    my $class = Mojo::File->with_roles('+Digest');
    my $file = $class->new($path);

    $file->md5_sum;
    $file->quickxor_hash;  # requires Digest::QuickXor
    $file->sha1_sum;
    $file->sha256_sum;

=head1 DESCRIPTION

L<Mojo::File::Role::Digest> is a role for L<Mojo::File> to calculate MD5, SHA1, SHA256, and QuickXor digests.

If the path isn't an existing file, all methods return an empty string C<''>.

=head1 APPLY ROLE

    use Mojo::File 'path';

    my $file             = path($path);
    my $file_with_digest = $file->with_roles('+Digest');

Apply to a single L<Mojo::File> object. See L<Mojo::Base/with_roles>.

    use Mojo::File;
    my $class = Mojo::File->with_roles('+Digest');

    my $file1 = $class->new($path1);
    my $file2 = $class->new($path2);

Create a modified file class with applied digest role.

=head1 METHODS

=head2 md5_sum

    $string = $file->md5_sum;

Returns the MD5 sum of the file in hexadecimal form. See L<Digest::MD5/hexdigest>.

=head2 quickxor_hash

    $string = $file->quickxor_hash;

Returns the base64 encoded QuickXorHash of the file. See L<Digest::QuickXor/b64digest>.
Requires L<Digest::QuickXor> 0.03 or higher.

=head2 sha1_sum

    $string = $file->sha1_sum;

Returns the SHA1 sum of the file in hexadecimal form. See L<Digest::SHA/hexdigest>.

=head2 sha256_sum

    $string = $file->sha256_sum;

Returns the SHA256 sum of the file in hexadecimal form. See L<Digest::SHA/hexdigest>.

=head1 AUTHOR & COPYRIGHT

© 2019–2020 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::File>, L<Mojo::Base>, L<Role::Tiny>, L<Digest::MD5>, L<Digest::QuickXor>, L<Digest::SHA>.

=cut
