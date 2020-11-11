use Modern::Perl;
package Orbital::Transfer::Repo;
# ABSTRACT: Represent the top level of a code base repo
$Orbital::Transfer::Repo::VERSION = '0.001';
use Mu;

use Orbital::Transfer::Common::Setup;
use Orbital::Transfer::Common::Types qw(AbsDir);

has directory => (
	is => 'ro',
	required => 1,
	coerce => 1,
	isa => AbsDir,
);

has [ qw(config platform) ] => (
	is => 'ro',
	required => 1,
);

lazy runner => method() {
	$self->platform->runner;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Repo - Represent the top level of a code base repo

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
