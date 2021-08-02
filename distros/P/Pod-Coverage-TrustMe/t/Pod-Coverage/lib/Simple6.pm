# an exporter - 3 subs, 1 documented, 2 exportable
package Simple6;
use strict;

require Exporter;
use base 'Exporter';
use vars qw/@EXPORT @EXPORT_OK/;

@EXPORT    = qw(foo);
@EXPORT_OK = qw(foo bar);

sub foo {}
sub bar {}
sub baz {};

1;
__END__

=item bar

this is bar

=cut
