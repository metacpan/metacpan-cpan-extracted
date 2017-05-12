use 5.014;
use strict;
use warnings;

package Switcheroo;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';
our @EXPORT    = qw( switch );
our @EXPORT_OK = qw( match );
our @ISA       = qw( Exporter::Tiny );

use Exporter::Tiny qw( );
use match::simple qw( match );
use PadWalker qw( peek_my set_closed_over );
use Parse::Keyword { switch => \&_parse_switch };

sub import
{
	my $pkg = caller;
	eval qq[ package $pkg; our \$a; our \$b; ];
	goto \&Exporter::Tiny::import;
}

sub switch
{
	my ($pkg, $expr, $comparator, $cases, $default) = @_;
	
	my @args = @_ = do {
		package # replaces Devel::Caller::caller_args(1)
		DB; my @x = caller(1); our @args;
	};
	
	my $pad = peek_my(1);
	my $var = defined($expr)
		? do {
			set_closed_over($expr, $pad);
			$expr->(@args);
		}
		: $_;
	Internals::SvREADONLY($var, 1);
	local *_ = \$var;
	
	my $match = \&match::simple::match;
	if ($comparator)
	{
		$match = sub {
			no strict 'refs';
			local *{"$pkg\::a"} = \ $_[0];
			local *{"$pkg\::b"} = \ $_[1];
			$comparator->(@args);
		};
	}
	
	CASE: for my $case ( @$cases )
	{
		my ($type, $condition, $block) = @$case;
		
		my $matched = 0;
		if ($type eq 'block')
		{
			set_closed_over($condition, $pad);
			$matched = !!$condition->(@args);
		}
		else
		{
			TERM: for my $termexpr (@$condition)
			{
				set_closed_over($termexpr, $pad);
				my $term = $termexpr->(@args);
				$match->($var, $term) ? (++$matched && last TERM) : next TERM;
			}
		}
		
		set_closed_over($block, $pad);
		goto $block if $matched;
	}
	
	if ($default)
	{
		set_closed_over($default, $pad);
		goto $default;
	}
	return;
}

sub _parse_switch
{
	my ($expr, $comparator, @cases, $default);
	my $is_statement = 1;
	
	lex_read_space;
	
	if (lex_peek eq '(')
	{
		lex_read(1);
		lex_read_space;
		$expr = parse_fullexpr;
		lex_read_space;
		die "syntax error; expected close parenthesis" unless lex_peek eq ')';
		lex_read(1);
		lex_read_space;
	}
	
	if (lex_peek(4) eq 'mode')
	{
		lex_read(4);
		lex_read_space;
		die "syntax error; expected open parenthesis" unless lex_peek eq '(';
		lex_read(1);
		lex_read_space;
		$comparator = parse_fullexpr;
		lex_read_space;
		die "syntax error; expected close parenthesis" unless lex_peek eq ')';
		lex_read(1);
		lex_read_space;
	}
	
	if (lex_peek(2) eq 'do')
	{
		lex_read(2);
		lex_read_space;
		$is_statement = 0;
	}
	
	die "syntax error; expected block" unless lex_peek eq '{';
	lex_read(1);
	lex_read_space;
	
	while ( lex_peek(4) eq 'case' )
	{
		lex_read(4);
		push @cases, _parse_case();
		lex_read_space;
	}
	
	if ( lex_peek(7) eq 'default' )
	{
		lex_read(7);
		lex_read_space;
		if (lex_peek eq ':')
		{
			lex_read(1);
			lex_read_space;
		}
		$default = _parse_consequence();
		lex_read_space;
	}
	
	die "syntax error; expected end of switch block" unless lex_peek eq '}';
	lex_read(1);
	
	my $pkg = compiling_package;
	
	return (
		sub { ($pkg, $expr, $comparator, \@cases, $default) },
		$is_statement,
	);
}

sub _munge_term
{
	if (lex_peek(1) eq '/')
	{
		lex_stuff('qr');
	}
	elsif (lex_peek(2) =~ /m\W/)
	{
		lex_read(1);
		lex_stuff('qr');
	}
}

sub _parse_case
{
	my ($expr, $type);
	lex_read_space;
	
	if (lex_peek eq '(')
	{
		lex_read(1);
		$type = 'term';
		$expr = _parse_list_of_terms(\&_munge_term);
		lex_read_space;
		die "syntax error; expected close parenthesis" unless lex_peek eq ')';
		lex_read(1);
		lex_read_space;
	}
	
	elsif (lex_peek eq '{')
	{
		$type = 'block';
		$expr = parse_block;
		lex_read_space;
	}
	
	else
	{
		$type = 'simple-term';
		$expr = _parse_list_of_terms(\&_munge_term);
		lex_read_space;
	}
	
	die "syntax error; expected colon" unless lex_peek eq ':';
	lex_read(1);
	lex_read_space;
	
	my $block = _parse_consequence();
	return [ $type, $expr, $block ];
}

sub _parse_list_of_terms
{
	my $munge = shift;
	
	my @expr;
	lex_read_space;
	$munge->() if $munge;
	push @expr, parse_termexpr;
	lex_read_space;
	
	while (lex_peek eq ',')
	{
		lex_read(1);
		lex_read_space;
		$munge->() if $munge;
		push @expr, parse_termexpr;
		lex_read_space;
	}
	
	return \@expr;
}

sub _parse_consequence
{
	my ($expr, $type);
	lex_read_space;
	
	my $block = (lex_peek eq '{') ? parse_block() : parse_fullstmt();
	lex_read_space;
	(lex_read(1), lex_read_space) while lex_peek eq ';';
	
	return $block;
}


1;

__END__

=pod

=encoding utf-8

=for stopwords fallthrough non-whitespace

=head1 NAME

Switcheroo - yet another switch statement for Perl

=head1 SYNOPSIS

   my $day_type;
   
   switch ($day) {
      case 0, 6:  $day_type = "weekend";
      default:    $day_type = "weekday";
   }

=head1 STATUS

Experimental.

No backwards compatibility between releases is guaranteed. Both the
surface syntax and the internals of the module are liable to change
at my whim.

=head1 DESCRIPTION

This module provides Perl with a switch statement. It's more reliable than
the L<Switch> module (which is broken on recent versions of Perl anyway),
less confusing than C<< use feature 'switch' >>, and more powerful than
L<Switch::Plain> (though Switch::Plain is significantly faster).

Switcheroo uses the Perl keyword API, which was introduced in Perl 5.14,
so this module does not work on older releases of Perl.

The basic grammar of the switch statement is as follows:

   switch ( TEST ) {
      case EXPR1: STATEMENT1;
      case EXPR2: STATEMENT2;
      default:    STATEMENT3;
   }

TEST is evaluated in scalar context. Each expression EXPR1, EXPR2, etc
is evaluated in list context. If TEST matches any of the expression,
then the statement following it is executed. Matching is performed by
L<match::simple>, which is a simplified version of the Perl smart match
operator. If no match is successful, then the C<default> statement is
executed.

C<switch> is whole statement, so does not need to be followed by a
semicolon.

Within the switch block, C<< $_ >> is a read-only alias to the TEST
value.

That's the basics taken care of, but there are several variations...

=head2 Implicit test

If the test is omitted, then C<< $_ >> is tested:

   my $day_type;
   
   $_ = $day;
   switch {
      case 0, 6:  $day_type = "weekend";
      default:    $day_type = "weekday";
   }

=head2 Expression blocks

If C<case> is followed by a C<< { >> character, this is I<not> interpreted
as the start of an anonymous hashref, but as a block. Matching via 
L<match::simple> is not attempted; instead the block is evaluated as
a boolean.

   switch ($number) {
      case 0:           say "zero";
      case { $_ % 2 }:  say "an odd number";
      default:          say "an even number";
   }

=head2 Regexp Expressions

If this module encounters:

   switch ($foo) { case /foo/: say "foo" }

Don't worry; we know you meant C<< qr/foo/ >> and not C<< m/foo/ >>.

=head2 Statement blocks

If the first non-whitespace character is C<< { >>, the statement is treated
as a block rather than a single statement:

   switch ($number) {
      case 0: {
         say "zero";
      }
      case { $_ % 2 }: {
         say "an odd number";
      }
      default: {
         say "an even number";
      }
   }

=head2 Comparison expression

Above I said that matching is performed by L<match::simple>. That was a lie.
L<match::simple> is just the default. You can provide your own expression
for matching:

   switch ($number) mode ($a > $b) {
      case 1000:   say "greater than 1000";
      case 100:    say "greater than 100";
      case 10:     say "greater than 10";
      case 1:      say "greater than 1";
   }

C<< $a >> is the TERM and C<< $b >> is the EXPR. These are the same special
package variables used by C<sort> and by C<reduce> from L<List::Util>.

=head2 Switch expressions

Although C<switch> acts as a full statement usually, it can be used as part
of an expression if the keyword C<do> appears before the block:

   my $day_type = switch ($day) do {
      case 0, 6:  "weekend";
      default:    "weekday";
   };

=head2 Fallthrough

There's no fallthrough.

=begin trustme

=item switch

=end trustme

=head2 C<< match($x, $y) >>

This module can also re-export the C<match> function from L<match::simple>,
but not by default.

   use Switcheroo qw( match switch );

=head1 HINTS

Switcheroo intentionally works nicely with L<Types::Standard> and other
L<Type::Tiny>-based type libraries:

   use Switcheroo;
   use Types::Standard -types;
   
   switch ($value) {
      case Int:       say "it's an integer";
      case ArrayRef:  say "it's an array ref";
      case HashRef:   say "it's a hash ref";
   }

It also plays well with L<Smart::Match>:

   use Switcheroo;
   use Smart::Match qw( range at_least );
   
   switch ($value) {
      case range(0, 10):    say "small";
      case range(11, 100):  say "medium";
      case at_least(101):   say "large";
   }

This is all thanks to L<match::simple> which respects the overloaded
C<< ~~ >> operator.

=head1 CAVEATS

Internally a lot of parts of code are passed around as coderefs, so
certain things might not work how you'd expect inside C<switch>:

=over

=item * 

C<caller>

=item * 

C<return>

=item * 

C<< @_ >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Switcheroo>.

=head1 SEE ALSO

L<perlsyn/Switch Statements>, L<Switch>, L<Switch::Plain>.

L<http://en.wikipedia.org/wiki/The_Burning_(Seinfeld)>.

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

