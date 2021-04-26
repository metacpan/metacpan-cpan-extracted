package Myriad::Transport::PostgreSQL;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;
use Object::Pad;

class Myriad::Transport::PostgreSQL extends IO::Async::Notifier;

use Future::AsyncAwait;
use Syntax::Keyword::Try;

use Database::Async;
use Database::Async::Engine::PostgreSQL;

use Log::Any qw($log);

has $dbh;

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

