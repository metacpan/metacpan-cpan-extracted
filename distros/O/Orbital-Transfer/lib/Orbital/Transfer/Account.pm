use Orbital::Transfer::Common::Setup;
package Orbital::Transfer::Account;
# ABSTRACT: A base class for accounts
$Orbital::Transfer::Account::VERSION = '0.001';
use Moo;
use Orbital::Transfer::Common::Types qw(Str);

has username => (
	is => 'ro',
	isa => Str,
	required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Account - A base class for accounts

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
