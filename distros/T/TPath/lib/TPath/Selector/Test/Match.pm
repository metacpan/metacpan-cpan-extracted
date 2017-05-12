package TPath::Selector::Test::Match;
$TPath::Selector::Test::Match::VERSION = '1.007';
# ABSTRACT: role for all matching selectors

use Moose::Role;


with 'TPath::Selector::Test';

has rx => ( is => 'ro', isa => 'RegexpRef', required => 1 );

has val => ( is => 'ro', isa => 'Str', required => 1);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::Match - role for all matching selectors

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector::Test>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
