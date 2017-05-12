package String::Replace::Safe;
our $VERSION = '0.02';
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util 'reftype', 'blessed';
use List::MoreUtils 'natatime';
use Carp;

our @EXPORT_OK = ('replace', 'unreplace');
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ] );

# There is a lot of code duplication between String::Replace and
# String::Replace::Safe, but I don't see a simple way to reduce it without
# adding a additionnal indirection level.

sub __prepare_replace {
	my %param;
	if (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'ARRAY') {
		croak 'The replace list must have an even number of element' if @{$_[0]} & 1;
		%param = @{$_[0]};
	} else {
		croak 'The replace list must have an even number of element' if @_ & 1;
		%param = @_;
	}
	
	my @repl;
	for my $k (keys %param) {
		push @repl, "\Q$k\E";
	}
	my $regexp = '('.(join '|', @repl).')';

	return { regexp => qr/$regexp/, replace => \%param };
}


sub __prepare_unreplace {
	my %param;
	if (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'ARRAY') {
		croak 'The replace list must have an even number of element' if @{$_[0]} & 1;
		%param = @{$_[0]};
	} else {
		croak 'The replace list must have an even number of element' if @_ & 1;
		%param = @_;
	}
	
	my %rparam;
	while (my ($k, $val) = each %param) {
		my @lv = (ref $val && reftype $val eq 'ARRAY') ? @{$val} : $val;
		for my $v (@lv) {
			$rparam{$v} = $k;
		}
	}

	return __prepare_replace(%rparam);
}

# This function is the same for replace and unreplace.
sub __execute_replace {
	my ($str, $repl) = @_;
	
	$str =~ s/$repl->{regexp}/$repl->{replace}{$1}/ge;
	#return $str =~ s/$repl->{regexp}/$repl->{replace}{$1}/gre; require v5.14

	return $str;
}

sub __execute_replace_in {
	my (undef, $repl) = @_;

	$_[0] =~ s/$repl->{regexp}/$repl->{replace}{$1}/ge;

	return;
}

sub new {
	my ($class, @param) = @_;
	
	my $self = __prepare_replace(@param);

	return bless $self, $class;
}

sub new_unreplace {
	my ($class, @param) = @_;
	
	my $self = __prepare_unreplace(@param);

	return bless $self, $class;
}


sub __replace_method {
	my $repl = shift;
	
	if (wantarray) {
		return map { __execute_replace($_, $repl) } @_;
	} elsif (defined wantarray) {
		return @_ ? __execute_replace($_[0], $repl) : undef;
	} else {
		__execute_replace_in($_, $repl) for @_;
		return;
	}
}

sub __replace_fun {
	my ($str, @list) = @_;

	return __execute_replace($str, __prepare_replace(@list))
}

sub __unreplace_fun {
	my ($str, @list) = @_;

	return __execute_replace($str, __prepare_unreplace(@list))
}

sub replace {
	croak 'Missing argument to '.__PACKAGE__.'::replace' unless @_;

	if (blessed($_[0]) && $_[0]->isa(__PACKAGE__)) {
		return &__replace_method;
	} else {
		return &__replace_fun;
	}
}

sub unreplace {
	croak 'Missing argument to '.__PACKAGE__.'::unreplace' unless @_;

	if (blessed($_[0]) && $_[0]->isa(__PACKAGE__)) {
		return &__replace_method;
	} else {
		return &__unreplace_fun;
	}
}

=cut

1;


=encoding utf-8

=head1 NAME

String::Replace::Safe - Performs arbitrary replacement in strings, safely

=head1 SYNOPSIS

  use String::Replace::Safe ':all';
  
  print replace('hello name', 'name' => 'world');
  print unreplace('hello world', {'name' => 'world'});
  
  my $r = String::Replace::Safe->new('name' => 'world');
  print $r->replace('hello world');

=head1 DESCRIPTION

C<String::Replace::Safe> is a safe version of the C<L<String::Replace>> library.
That is that this version does not depend on the order of evaluation of the
argument to its function. This version is also consistently slower than the I<unsafe>
version (by a factor of approximately 50%).

Apart from that, the interface of the safe version is exactly the same (both
functionnal and object oriented) as the interface of the C<L<String::Replace>>
library. Hence the absence of documentation here.

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-replace@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Replace>.

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.02 (January 2013)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




