package Net::Launchpad::Model::Base;
BEGIN {
  $Net::Launchpad::Model::Base::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Model::Base::VERSION = '2.101';
# ABSTRACT: base class

use Moose;
use namespace::autoclean;
use Function::Parameters;


has result => (is => 'rw', isa => 'HashRef');


has lpc => (is => 'ro', isa => 'Net::Launchpad::Client');

has ns => (is => 'rw');

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Base - base class

=head1 VERSION

version 2.101

=head1 ATTRIBUTES

=head2 result

Result of query

=head2 lpc

L<Net::Launchpad::Client>

=head2 ns

Namespace for search queries against collections

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
