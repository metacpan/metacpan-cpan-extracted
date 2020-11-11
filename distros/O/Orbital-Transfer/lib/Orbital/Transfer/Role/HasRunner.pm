use Modern::Perl;
package Orbital::Transfer::Role::HasRunner;
# ABSTRACT: Role that requires runner
$Orbital::Transfer::Role::HasRunner::VERSION = '0.001';
use Mu::Role;

has runner => (
	is => 'ro',
	required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Role::HasRunner - Role that requires runner

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
