package Test::BDD::Cucumber::Harness::Nagios::Result;

use Moose;

our $VERSION = '1.002'; # VERSION
# ABSTRACT: extended result with nagios specifics

extends 'Test::BDD::Cucumber::Model::Result';

has 'nagios_code' => ( 'is' => 'ro', isa => 'Int', required => 1 );

has '+result' => ( lazy => 1, default => 'undefined' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Cucumber::Harness::Nagios::Result - extended result with nagios specifics

=head1 VERSION

version 1.002

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
