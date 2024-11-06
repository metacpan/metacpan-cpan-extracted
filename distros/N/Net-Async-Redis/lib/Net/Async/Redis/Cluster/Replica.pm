package Net::Async::Redis::Cluster::Replica;
use Object::Pad;
class Net::Async::Redis::Cluster::Replica;

our $VERSION = '6.004'; # VERSION

use Scalar::Util qw(refaddr);
use Future::AsyncAwait;
use Log::Any qw($log);

use overload
    '""' => sub { 'NaRedis::Cluster::Replica[id=' . shift->id . ']' },
    '0+' => sub { refaddr(shift) },
    bool => sub { 1 },
    fallback => 1;

field $id:param:reader;
field $host:param:reader;
field $port:param:reader;

method host_port { join ':', $host, $port }

1;
__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2024. Licensed under the same terms as Perl itself.

