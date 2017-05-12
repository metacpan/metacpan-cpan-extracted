package Test::BDD::Infrastructure::Config::Facter;

use Moose;

# ABSTRACT: configuration class for Test::BDD::Infrastructure
our $VERSION = '1.005'; # VERSION

extends 'Test::BDD::Infrastructure::Config::Hash';

use IPC::Run;
use JSON;

has 'command' => ( is => 'ro', isa => 'ArrayRef[Str]',
	default => sub { [ 'facter', '--json' ] },
);

has 'config' => ( is => 'rw', lazy => 1, isa => 'HashRef',
	default => sub {
		my $self = shift;
		my ( $in, $out, $err );
		IPC::Run::run($self->command, \$in, \$out, \$err )
			or die("error running facter: $err");
		my $data = from_json( $out );
		return( $data );
	},
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Config::Facter - configuration class for Test::BDD::Infrastructure

=head1 VERSION

version 1.005

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
