#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2021 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Client::via::sshexec 0.16;

use v5.14;
use warnings;

sub connect
{
   my $client = shift;
   my ( $uri, %args ) = @_;

   my @sshargs;
   push @sshargs, "-4" if $args{family} and $args{family} eq "inet4";
   push @sshargs, "-6" if $args{family} and $args{family} eq "inet6";

   my $host  = $uri->authority;

   my $path  = $uri->path;
   # Path will start with a leading /; we need to trim that
   $path =~ s{^/}{};

   my $query = $uri->query;
   defined $query or $query = "";
   # $query will contain args to exec - split them on +
   my @argv = split( m/\+/, $query );

   return $client->connect_exec( [ "ssh", @sshargs, $host, $path, @argv ] );
}

0x55AA;
