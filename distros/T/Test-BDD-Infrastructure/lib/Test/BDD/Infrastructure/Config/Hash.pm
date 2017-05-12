package Test::BDD::Infrastructure::Config::Hash;

use Moose;

# ABSTRACT: configuration class for Test::BDD::Infrastructure
our $VERSION = '1.005'; # VERSION

has 'config' => ( is => 'rw', isa => 'HashRef', required => 1 );

sub _get_hash_node {
	my $hash = shift;
	my @path = @_;
	my $cur = $hash;

	if( ! defined $hash ) { return; }

	while( my $element = shift @path ) {
		if( defined $cur->{$element}
	       			&& ref $cur->{$element} eq 'HASH' ) {
			$cur = $cur->{$element};
		} else { return; }
	}

	return $cur;
}

sub _get_hash_value {
	my $hash = shift;
	my $key = pop;
	my @path = @_;

	my $cur = _get_hash_node( $hash, @path );

	if( defined $cur
			&& defined $cur->{$key}
			&& ! ref($cur->{$key}) ) {
		return $cur->{$key};
	}
	return;
}

sub _parse_path {
	my ( $self, $path ) = @_;
	$path =~ s/^\///;
	return( split('/', $path) );
}

sub get_node {
	my ( $self, $path ) = @_;
	my $node;
	if( $node = _get_hash_node( $self->config, $self->_parse_path( $path ) ) ) {
		return $node;
	}
	return;
}

sub get {
	my ( $self, $path ) = @_;
	my $value;

	if( $value = _get_hash_value( $self->config, $self->_parse_path( $path ) ) ) {
		return $value;
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Config::Hash - configuration class for Test::BDD::Infrastructure

=head1 VERSION

version 1.005

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
