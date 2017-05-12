#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo::Core;

use strict;
use warnings;

our $VERSION = '0.22';

# Load the actual code into Socket::GetAddrInfo
package # hide from indexer
  Socket::GetAddrInfo;

BEGIN { die '$Socket::GetAddrInfo::NO_CORE is set' if our $NO_CORE }

use Socket 1.93;
defined &Socket::NIx_NOHOST or die "Core Socket is missing NIx_NOHOST";

our @EXPORT_OK = qw(
   getaddrinfo
   getnameinfo
);

push @EXPORT_OK, grep { m/^AI_|^NI(?:x)?_|^EAI_/ } @Socket::EXPORT_OK;

Socket->import( @EXPORT_OK );

0x55AA;
