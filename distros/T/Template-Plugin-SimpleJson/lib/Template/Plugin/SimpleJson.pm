package Template::Plugin::SimpleJson;

use 5.006;
use strict;

our $VERSION = '0.01';

use Template::Plugin;
use base qw( Template::Plugin );
use JSON;

sub load {
	my $class = shift;
	my $context = shift;
	return $class;
}

sub new {
	my $class   = shift;
	my $context = shift;
	my $self = bless {
			'_CONTEXT' => $context,
			}, $class;
	return $self;
}

sub  fromJson{
	my $self = shift;
	my $jsonText = shift;
	return from_json($jsonText);
}

sub  toJson{
	my $self = shift;
	my $o = shift;
	return to_json($o);
}

1;

__END__

=head1 NAME

Template::Plugin::SimpleJson - Simple JSON methods for Template Toolkit

=head1 SYNOPSIS

  [% USE SimpleJson %]

  [% scalar = SimpleJson.fromJson(json_text) %]
  [% text = SimpleJson.toJson(scalar) %]

=head1 DESCRIPTION

This module implements some methods to manipulate json string, using L<JSON|JSON> module

=head1 METHODS

=head2 fromJson

Converts a json string to a perl scalar

=head2 toJson

Converts a perl scalar to a json string

=head1 AUTHOR

Fabio Masini E<lt>fabio.masini@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Fabio Masini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
