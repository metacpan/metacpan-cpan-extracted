use Orbital::Transfer::Common::Setup;
package Orbital::Transfer::Service::Role::DocumentRetrievable;
# ABSTRACT: Role to retrieve documents
$Orbital::Transfer::Service::Role::DocumentRetrievable::VERSION = '0.001';
use Moo::Role;
use Orbital::Transfer::Common::Types qw(Str);

method retrieve( (Str) $identifier ) {
	...
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Service::Role::DocumentRetrievable - Role to retrieve documents

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
