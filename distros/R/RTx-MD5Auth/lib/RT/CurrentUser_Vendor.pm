# $File: //member/autrijus/.vimrc $ $Author: autrijus $
# $Revision: #14 $ $Change: 4137 $ $DateTime: 2003/02/08 11:41:59 $

no warnings 'redefine';

=head2 Authenticate

Takes $password, $created and $nonce, and returns a boolean value
representing whether the authentication succeeded.

If both $nonce and $created are specified, treat $password as:

    md5_base64(md5_base64($real_password) . $created . $nonce)

and validate it, where $created is in unix timestamp format, and
$nonce is a random string no longer than 32 bytes.

Otherwise, simply pass $password to IsPassword().

=cut

sub Authenticate { 
    my ($self, $password, $created, $nonce) = @_;

    return $self->IsPassword($password)
        unless $password and $created and abs($created - time) < 3600 and $nonce;

    my $server_pass = $self->UserObj->__Value('Password') or return;

    require Digest::MD5;
    return ($password eq Digest::MD5::md5_base64($server_pass . $created . $nonce));
}

1;
