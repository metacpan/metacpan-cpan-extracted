package Syntax::Feature::Qwa;

use 5.010;
use strict;

BEGIN {
	$Syntax::Feature::Qwa::AUTHORITY = 'cpan:TOBYINK';
	$Syntax::Feature::Qwa::VERSION   = '0.002';
}

use Devel::Declare          0.006007    ();
use Devel::Declare::Context::Simple 0 ();
use B::Hooks::EndOfScope    0.09;
use Sub::Install            0.925       qw( install_sub );
use namespace::clean 0;
 
my @NewOps  = qw(qwa qwh qwk);
my %QuoteOp = (
	qwa  => q{  [%s] },
	qwh  => q{ +{%s} },
	qwk  => q{ do { my $i = 0; +{ map { $_=>++$i } %s } } },
	);

sub import
{
	my ($class) = @_;
	my $caller  = caller(0);
	@_ = ($class, 'into', $caller);
	goto \&install;
}

sub install
{
	my ($class, %args) = @_;
	
	my $target = $args{into};
	Devel::Declare->setup_for($target => {
		map {
			my $name = $_;
			($name => {
				const => sub {
					my $ctx = Devel::Declare::Context::Simple->new;
					$ctx->init(@_);
					return $class->_transform($name, $ctx);
				},
			})
		} @NewOps
	});
	for my $name (@NewOps) {
		install_sub {
			into => $target,
			as   => $name,
			code => $class->_run_callback($name),
		}
	}
	on_scope_end {
		namespace::clean->clean_subroutines($target, @NewOps);
	};
	return 1;
}

sub _run_callback { sub($){shift} }
 
sub _transform
{
	my ($class, $name, $ctx) = @_;
	
	$ctx->skip_declarator;
	my $length = Devel::Declare::toke_scan_str($ctx->offset);
	my $string = Devel::Declare::get_lex_stuff;
	Devel::Declare::clear_lex_stuff;
	my $linestr = $ctx->get_linestr;
	my $quoted = substr $linestr, $ctx->offset, $length;
	my $spaced = '';
	$quoted =~ m{^(\s*)}sm;
	$spaced = $1;
	my $new = sprintf $QuoteOp{$name}, join q[],
		q[qw],
		$spaced,
		substr($quoted, length($spaced), 1),
		$string,
		substr($quoted, -1, 1);
	substr($linestr, $ctx->offset, $length) = $new;
	$ctx->set_linestr($linestr);
#	my $s = $ctx->get_linestr;
#	warn ">>> $s\n";
	return 1;
}

__PACKAGE__
__END__

=head1 NAME

Syntax::Feature::Qwa - qwa(), qwh() and qwk() quote-like operators to create arrayrefs and hashrefs

=head1 SYNOPSIS

 use syntax qw/qwa/;
 use Data::Dumper;
 
 print Dumper qwa(foo bar baz quux);
 
 # [
 #   'foo',
 #   'bar',
 #   'baz',
 #   'quux',
 # ]

 print Dumper qwh(foo bar baz quux);
 
 # {
 #   'foo' => 'bar',
 #   'baz' => 'quux',
 # }

 print Dumper qwk(foo bar baz quux);
 
 # {
 #   'foo'  => 1,
 #   'bar'  => 2,
 #   'baz'  => 3,
 #   'quux' => 4,
 # }

=head1 DESCRIPTION

Perl's word list operator (C<< qw() >>) is really nice. It allows you to
build simple lists without needing much punctuation. But it's quite common
to see it wrapped by additional punctuation in the form of:

  my $array = [qw(foo bar baz)];

It would be quite nice to have a version of the word list operator which
returned an arrayref instead of a list. That's where this module comes in.
It provides a "word list arrayref" operator:

  my $array = qwa(foo bar baz);

It also provides companion "word list hashref" and "word list hashref keys"
operators.

=head2 Use with syntax.pm

This module is intended to be used with the L<syntax> module. This allows
you to switch on multiple syntax extensions in one line:

 use syntax 'ql', 'qwa', 'io';

=head2 Use without syntax.pm

It is also possible to use this module without syntax.pm:

 use Syntax::Feature::Qwa;

=head1 EQUIVALENTS

If you want to rewrite code using this module to remove its dependency on it,
or if you just want to better understand how it works, here are some
equivalents between this module's operators, and how they'd be expressed
without this module.

=head2 qwa()

 my $arrayref = qwa(Foo Bar Baz);
 
 my $arrayref = [ qw(Foo Bar Bar) ];

=head2 qwh()

 my $hashref  = qwh(Foo Bar Baz);
 
 my $hashref  = +{ qw(Foo Bar Bar) };

=head2 qwk()

 my $hashref  = qwk(Foo Bar Baz);
 
 my $hashref  = +{ do { my $i = 0; map { $_, ++$i } qw(Foo Bar Bar) } };

=head1 EXAMPLES

=head2 Hashref keys as lookup tables

 # Create a lookup table
 my $days = qwk(Mon Tue Wed Thu Fri Sat Sun);
 
 # The task is to sort these into their weekly order
 my @list = qw(Fri Tue Wed);
 
 # Easy!
 my @sorted_list = sort { $days->{$a} <=> $days->{$b} } @list;

=head2 Hashref keys for smart matching

 my $admins = qwk(alice bob carol);
 my $login  = get_current_user();
 
 if ($login ~~ $admins)
 {
   ...
 }

=head2 Arrayrefs for smart matching

The example above also works using arrayrefs. For smaller lists, arrayrefs
might be faster; for larger lists hashrefs probably will be.

 my $admins = qwa(alice bob carol);
 my $login  = get_current_user();
 
 if ($login ~~ $admins)
 {
   ...
 }

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Syntax-Feature-Qwa>.

=head1 SEE ALSO

L<syntax>,
L<Syntax::Feature::Ql>,
L<PerlX::QuoteOperator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

