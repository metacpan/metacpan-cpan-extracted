#!/usr/bin/perl

package Prompt::ReadKey::Util;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT = qw(_deref _get_arg _get_arg_or_default);

sub _deref ($) {
	return unless @_;

	my $ret = shift;

	if ( wantarray and (ref($ret)||'') eq 'ARRAY' ) {
		return @$ret;
	} else {
		return $ret;
	}
}

sub _get_arg ($\%) {
	my ( $name, $args ) = @_;
	return unless exists $args->{$name};
	_deref( $args->{$name} );
}

sub _get_arg_or_default {
	my ( $self, $name, %args ) = @_;

	if ( exists $args{$name} ) {
		_get_arg($name, %args);
	} else {
		my $method = ( ( $name =~ m/^(?: prompt | options )$/x ) ? "default_$name" : $name );
		if ( $self->can($method) ) {
			return _deref($self->$method());
		}
	}
}

__PACKAGE__

__END__
