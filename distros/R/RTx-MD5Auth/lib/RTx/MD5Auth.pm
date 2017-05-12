# $File: //member/autrijus/.vimrc $ $Author: autrijus $
# $Revision: #14 $ $Change: 4137 $ $DateTime: 2003/02/08 11:41:59 $

package RTx::MD5Auth;
$RTx::MD5Auth::VERSION = '0.01';

1;

=head1 NAME

RTx::MD5Auth - Secure login over an unsecure http channel

=head1 DESCRIPTION

I've came across Atom's choice of using WSSE profile as the
authentication mechanism, and think that it's very well suited
to RT's REST layer:

    http://www.xml.com/lpt/a/2003/12/17/dive.html

It solves the frequent need of avoiding password sniffing over
a non-SSL channel.

After discussion with Abhijit and Jesse, I've settled for
passing C<auth_digest>, C<auth_nonce> and C<auth_created> as
request arguments, and implemented a Javascript-based login
in the WebUI.

=cut
