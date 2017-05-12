package Test::BDD::Infrastructure::Config::Augeas;

use Moose;

# ABSTRACT: configuration class for Test::BDD::Infrastructure
our $VERSION = '1.005'; # VERSION

use Config::Augeas;

has 'root' => ( is => 'ro', isa => 'Str', default => '/' );

has '_aug' => (
	is => 'ro', isa => 'Config::Augeas', lazy => 1,
	default => sub {
		my $self = shift;
		return Config::Augeas->new(
			root => $self->root,
		);
	},
	handles => {
		'get' => 'get',
		'get_node' => 'match',
	},
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Config::Augeas - configuration class for Test::BDD::Infrastructure

=head1 VERSION

version 1.005

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
