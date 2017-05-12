#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo::XS;

use strict;
use warnings;

our $VERSION = '0.22';

# Load the actual code into Socket::GetAddrInfo
package # hide from indexer
  Socket::GetAddrInfo;

our @EXPORT_OK = qw(
   getaddrinfo
   getnameinfo
);

die '$Socket::GetAddrInfo::NO_XS is set' if our $NO_XS;

require XSLoader;
XSLoader::load( __PACKAGE__, $Socket::GetAddrInfo::XS::VERSION );

0x55AA;
