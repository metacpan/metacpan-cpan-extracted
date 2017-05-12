use 5.008003;
use strict;
use warnings;

package RT::Extension::SkipQuotes;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::SkipQuotes - helps to collapse overquoted emails

=head1 SYNOPSYS

	Set(@Plugins, qw(RT::Extension::SkipQuotes));

=head1 DESCRIPTION

This extension intended to collapse overquoted emails which often happens in corporate environments. Extension adds a javascript to a ticket display page, so action is taken on client's side.

=cut

# code here

=head1 AUTHOR

Vitaly Tskhovrebov E<lt>vitaly@tskhovrebov.ruE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;

