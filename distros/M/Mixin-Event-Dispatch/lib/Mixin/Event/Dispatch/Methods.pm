package Mixin::Event::Dispatch::Methods;
$Mixin::Event::Dispatch::Methods::VERSION = '2.000';
use strict;
use warnings;

use parent qw(Exporter);

=head1 NAME

Mixin::Event::Dispatch::Methods - importer class for applying L<Mixin::Event::Dispatch> methods without inheritance

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 package Role::WithEvents;
 use Moo::Role;
 use Mixin::Event::Dispatch::Methods qw(:all);

 package Some::Class;
 use Moo;
 with 'Role::WithEvents';

=head1 DESCRIPTION

Provides the following L<Exporter> tags:

=head2 :all

Imports all known methods. Probably a good default if this is being applied to
a specific role class. The methods imported may change in future, use :v2 if
you want to limit to a specific list that will never change.

=head2 :v2

Supports the methods provided by the 2.000 API.

=over 4

=item * L<Mixin::Event::Dispatch/invoke_event>

=item *	L<Mixin::Event::Dispatch/subscribe_to_event>

=item *	L<Mixin::Event::Dispatch/unsubscribe_from_event>

=item *	L<Mixin::Event::Dispatch/add_handler_for_event>

=item *	L<Mixin::Event::Dispatch/event_handlers>

=item *	L<Mixin::Event::Dispatch/clear_event_handlers>

=back

=head2 :basic

Imports only the bare minimum methods for subscribing/unsubscribing.

=over 4

=item * L<Mixin::Event::Dispatch/invoke_event>

=item *	L<Mixin::Event::Dispatch/subscribe_to_event>

=item *	L<Mixin::Event::Dispatch/unsubscribe_from_event>

=item *	L<Mixin::Event::Dispatch/event_handlers>

=back

=cut

use Mixin::Event::Dispatch;

my @functions = qw(
	invoke_event
	subscribe_to_event
	unsubscribe_from_event
	add_handler_for_event
	event_handlers
	clear_event_handlers
);

our @EXPORT;

our @EXPORT_OK = @functions;

our %EXPORT_TAGS = (
	all   => [ @functions ],
	v2    => [ @functions ],
	basic => [ qw(invoke_event subscribe_to_event unsubscribe_from_event event_handlers) ],
);

{
	no strict 'refs';
	*$_ = *{'Mixin::Event::Dispatch::' . $_ } for @functions;
}

1;

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015, based on code originally part of L<EntityModel>.
Licensed under the same terms as Perl itself.
