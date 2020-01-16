#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Client::via::sshexec;

use strict;
use warnings;

our $VERSION = '0.15';

sub connect
{
   my $client = shift;
   my ( $uri ) = @_;

   my $host  = $uri->authority;

   my $path  = $uri->path;
   # Path will start with a leading /; we need to trim that
   $path =~ s{^/}{};

   my $query = $uri->query;
   defined $query or $query = "";
   # $query will contain args to exec - split them on +
   my @argv = split( m/\+/, $query );

   return $client->connect_exec( [ "ssh", $host, $path, @argv ] );
}

0x55AA;
