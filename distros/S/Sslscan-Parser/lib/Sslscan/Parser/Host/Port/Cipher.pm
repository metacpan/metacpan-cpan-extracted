# $sslversion: Cipher.pm 18 2008-05-05 23:55:18Z jabra $
package Sslscan::Parser::Host::Port::Cipher;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @status : Field : Arg(status) : Get(status);
    my @sslversion : Field : Arg(sslversion) : Get(sslversion);
    my @bits : Field : Arg(bits) : Get(bits);
    my @cipher : Field : Arg(cipher) : Get(cipher);
}
1;
