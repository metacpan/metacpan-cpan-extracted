package Mixin::Event::Dispatch::Bus;
$Mixin::Event::Dispatch::Bus::VERSION = '2.000';
use strict;
use warnings;

use parent qw(Mixin::Event::Dispatch);
use constant EVENT_DISPATCH_ON_FALLBACK => 0;

=encoding utf8

=head1 NAME

Mixin::Event::Dispatch::Bus - a message bus

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 {
  package Some::Class;
  sub bus { shift->{bus} ||= Mixin::Event::Dispatch::Bus->new }
 }
 my $obj = bless {}, 'Some::Class';
 $obj->bus->subscribe_to_event(
  something => sub { my ($ev) = @_; warn "something!" }
 );
 $obj->bus->invoke_event('something');

=head1 DESCRIPTION

This class uses L<Mixin::Event::Dispatch> to provide
a message bus - instantiate this and call the usual
methods to deal with events:

=over 4

=item * L<Mixin::Event::Dispatch/subscribe_to_event>

=item * L<Mixin::Event::Dispatch/invoke_event>

=back

This allows several classes to share a common
message bus, or to avoid polluting a class with
event-related methods.

=cut

sub new { my $class = shift; bless { @_ }, $class }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
