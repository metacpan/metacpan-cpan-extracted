package PerlX::QuoteOperator::Inescapable;

use 5.010001;
use strict;
use warnings;
no warnings qw( void once uninitialized );

BEGIN {
	$PerlX::QuoteOperator::Inescapable::AUTHORITY = 'cpan:TOBYINK';
	$PerlX::QuoteOperator::Inescapable::VERSION   = '0.002';
}

use Carp qw/croak/;
use Devel::Declare;
use Data::OptList;
use Sub::Install qw/install_sub/;

use parent qw/Devel::Declare::Context::Simple/;

sub import
{
	my $caller = caller;
	my $self   = shift;
	
	@_ = 'Q' unless @_;
	my $optlist = Data::OptList::mkopt(\@_);
	
	for my $opt ( @$optlist )
	{
		my ($declarator, $callback) = @$opt;
		$callback //= sub ($) { +shift };
		$callback = delete $callback->{'-with'} if ref $callback eq 'HASH';
		
		$self = $self->new unless ref $self;
		Devel::Declare->setup_for(
			$caller,
			{ $declarator => { const => sub { $self->_parser(@_) } } }
		);
		
		install_sub {
			into    => $caller,
			as      => $declarator,
			code    => $callback,
		};
	}
}

sub unimport
{
	$^H{(__PACKAGE__)} = undef;
}

sub _parser
{
	my $self = shift;
	$self->init(@_);
	
	$self->skip_declarator;
	$self->skipspace;
	
	my $linestr = $self->get_linestr;
	
	my $remaining = substr($linestr, $self->offset);
	my $starter   = substr($remaining, 0, 1);
	my $ender     = $self->_ender($starter);
	
	my $ending    = index($remaining, $ender, 1);
	croak "Unterminated inescapable quoted string found: '$remaining'" if $ending < 0;
	
	substr($remaining, 0, $ending+1) = sprintf("('%s')", $self->_quote(substr $remaining, 1, $ending-1));
	substr($linestr, $self->offset)  = $remaining;
	
	$self->set_linestr($linestr);
}

sub _ender
{
	my ($self, $str) = @_;
	{
		'('    => ')',
		'{'    => '}',
		'['    => ']',
		'<'    => '>',
	}->{$str} // $str;
}

sub _quote
{
	my ($self, $str) = @_;
	$str =~ s{([\\\'])}{\\$1}g;
	return $str;
}

__FILE__
__END__

=encoding utf8

=head1 NAME

PerlX::QuoteOperator::Inescapable - a quote-like operator with no string escapes

=head1 SYNOPSIS

	use PerlX::QuoteOperator::Inescapable;
	
	my $var1 = q(Hello World);   # standard Perl quote-like operator
	my $var2 = Q(Hello World);   # this works the same
	
	my $var3 = q(Hello\\World);  # string includes a backslash
	my $var4 = Q(Hello\\World);  # string includes two backslashes!

=head1 DESCRIPTION

PerlX::QuoteOperator::Inescapable introduces a quote-like operator like
C<< q(...) >> but that supports B<< no string escapes >>! All characters
quoted are treated literally.

Like other quote-like operators, standard left/right bracket pairs are
supported; but unlike other quote-like operators, you cannot nest balanced
pairs of brackets:

	Q(Hello (Earth) World);   # no!

By default, a single quote-like operator is defined, C<< Q >>. You
can define alternative ones:

	use Path::Class;
	use PerlX::QuoteOperator::Inescapable
		Q => (),   # default Q operator
		F => sub ($) { Path::Class::File->new(@_) },
		D => sub ($) { Path::Class::Dir->new(@_) },
	;
	
	my $fonts = D!\\Server1\Marketing\Fonts!;

=head1 CAVEATS

The current implementation is limited to single-line literals. The
quote-like operator, starting delimiter and ending delimiter must all
appear on the same line of source code.

=head1 BUGS

The hash symbol (#) can not be used as a quote delimiter. ☹

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-QuoteOperator-Inescapable>.

=head1 SEE ALSO

L<PerlX::QuoteOperator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

