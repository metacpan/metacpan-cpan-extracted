use v5.10;
use strict;
use warnings;

package Neo4j::Error::Server;
# ABSTRACT: Neo4j exception thrown by the Neo4j server
$Neo4j::Error::Server::VERSION = '0.02';

use parent 'Neo4j::Error';

use List::Util 1.33 qw(all);


sub source { 'Server' }


sub message {
	my ($self) = @_;
	
	# Decode "strict" Jolt format if necessary
	$self->{message} = $self->{message}{U} if ref $self->{message} eq 'HASH';
	
	return $self->{message} // '';
}


sub code {
	my ($self) = @_;
	
	# Decode "strict" Jolt format if necessary
	$self->{code} = $self->{code}{U} if ref $self->{code} eq 'HASH';
	
	return $self->{code} if defined $self->{code};
	
	my @parts = (
		'Neo',
		$self->{classification},
		$self->{category},
		$self->{title},
	);
	return '' unless all { defined } @parts;
	return $self->{code} = join '.', @parts;
}


sub _parse_code {
	my ($self, $part) = @_;
	
	return '' unless defined $self->{code};
	my @parts = $self->code =~ m/^Neo\.([^\.]+)\.([^\.]+)\.(.+)$/i;
	return '' unless @parts;
	
	$self->{classification} = $parts[0];
	$self->{category}       = $parts[1];
	$self->{title}          = $parts[2];
	return $self->{$part};
}


sub classification {
	my ($self) = @_;
	
	return $self->{classification} // $self->_parse_code('classification');
}


sub category {
	my ($self) = @_;
	
	return $self->{category} // $self->_parse_code('category');
}


sub title {
	my ($self) = @_;
	
	return $self->{title} // $self->_parse_code('title');
}


sub is_retryable {
	my ($self) = @_;
	
	return $self->classification eq 'TransientError';
}


1;
