use v5.10.1;
use strict;
use warnings;

package Neo4j::Driver::Plugin::LWP;
# ABSTRACT: Neo4j::Driver plug-in for libwww-perl
$Neo4j::Driver::Plugin::LWP::VERSION = '1.02';

use Neo4j::Driver::Net::HTTP::LWP;

use parent 'Neo4j::Driver::Plugin';
BEGIN { Neo4j::Driver::Plugin->VERSION('0.34') }

sub new { bless {}, shift }

sub register {
	my ($self, $events) = @_;
	$events->add_handler( http_adapter_factory => sub {
		my ($continue, $driver) = @_;
		return Neo4j::Driver::Net::HTTP::LWP->new($driver);
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Plugin::LWP - Neo4j::Driver plug-in for libwww-perl

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Neo4j::Driver::Plugin::LWP;
  use Neo4j::Driver;
  
  $driver = Neo4j::Driver->new;
  $driver->plugin( Neo4j::Driver::Plugin::LWP->new );

=head1 DESCRIPTION

L<Neo4j::Driver::Plugin::LWP> is a L<Neo4j::Driver::Plugin>
that provides an HTTP network adapter, using L<libwww-perl|LWP>
to connect to the Neo4j server via HTTP or HTTPS.

HTTPS connections require L<LWP::Protocol::https> to be installed.

=head1 METHODS

L<Neo4j::Driver::Plugin::LWP> implements the following method.

=head2 new

 $plugin = Neo4j::Driver::Plugin::LWP->new;

Creates a new plug-in instance, which can be passed to
L<Neo4j::Driver/"plugin">.

=head1 EVENTS

L<Neo4j::Driver::Plugin::LWP> registers the following event
handler.

=over

=item C<http_adapter_factory>

Creates a new L<Neo4j::Driver::Net::HTTP::LWP> instance
and returns it.

=back

L<Neo4j::Driver::Plugin::LWP> does not trigger events.

=head1 SEE ALSO

L<Neo4j::Driver::Net::HTTP::LWP>

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
