use Modern::Perl;
package Orbital::Transfer::Runnable;
# ABSTRACT: Base for runnable command
$Orbital::Transfer::Runnable::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use Orbital::Transfer::Common::Types qw(ArrayRef Str InstanceOf Bool);
use Types::TypeTiny qw(StringLike);

use Orbital::Transfer::EnvironmentVariables;

use MooX::Role::CloneSet qw();
with qw(MooX::Role::CloneSet);

has command => (
	is => 'ro',
	isa => ArrayRef[StringLike],
	coerce => 1,
	required => 1,
);

has environment => (
	is => 'ro',
	isa => InstanceOf['Orbital::Transfer::EnvironmentVariables'],
	default => sub { Orbital::Transfer::EnvironmentVariables->new },
);

has admin_privilege => (
	is => 'ro',
	isa => Bool,
	default => sub { 0 },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Runnable - Base for runnable command

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
