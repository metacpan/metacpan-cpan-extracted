package Regexp::MultiLanguage::Perl;

use base qw(Regexp::MultiLanguage::BaseDialect);
use strict;
use warnings;

=head1 NAME

Regexp::MultiLanguage::Perl - Perl dialect for Regexp::MultiLanguage.

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

This module should not be used directly.  Please read the documentation
for L<Regexp::MultiLanguage>

=cut

sub wrap {
	my ($this, $code) = @_;
	my $ret = '';
	if ( defined( $this->{'package'} ) ) {
		$ret .= 'package ' . $this->{'package'} . ";\n\n";
	}
	$ret .= $code . "\n1;\n";
}

sub match_regex {
	my ($this, $regex) = @_;
	
	return '($_[0] =~ ' . $regex . ')';
}

sub comment_start {
	return '#';
}

sub make_function {
	my ($this,$name,$expr) = @_;
	my $prefix = $this->{'prefix'};
	return "sub $prefix$name { $expr }\n";
}

sub function_call {
	my ($this,$name) = @_;
	my $prefix = $this->{'prefix'};
	return "$prefix$name(\$_[0])";
}

=head1 AUTHOR

Robby Walker, robwalker@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robby Walker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;