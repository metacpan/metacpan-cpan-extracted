package Sub::Lambda::Filter;
use strict;
use warnings;
use Filter::Simple;
use Sub::Lambda::Grammar qw/parse/;
use Text::Balanced qw/extract_multiple extract_tagged/;

sub _parens ($) { 
    extract_multiple($_[0],
		     [ sub { extract_tagged($_[0], qr{[(]}, qr{[)]})}]);
}

sub _compile ($) {
    my ($t) = @_;
    my ($T) = ($t =~ /^\s*[(](.*)[)]\s*$/s);

    if ($T) {
	my $x = parse $t;
	return $x if defined($x);	
	return '(' . (join '', map {_compile($_)} _parens $T) . ')';
    } else {
	my @p = _parens $t;
	return $p[0] unless (@p > 1);	
	return join '', map { _compile($_) } @p;
    }
}


FILTER  { $_ = _compile $_ };

1;

__END__

=head1 NAME

Sub::Lambda::Filter - experimental source filtering to compile lambdas

=head1 SYNOPSIS

  use Sub::Filter;

  *plus     = (\a -> \b -> { $a + $b });
  my $minus = (\a -> \b -> { $a - $b });
  *flip     = (\f -> \a -> \b -> f b a);
  *sum      = (\h -t -> { @t ? $h+sum(@t) : ($h || 0) });

  print plus(1)->(2)            . "\n";  # 3  = 1 + 2
  print $minus->(10)->(5)       . "\n";  # 5  = 10 - 5
  print flip($minus)->(10)->(5) . "\n";  # -5 = 5 - 10
  print sum(1,2,3,4)            . "\n";  # 10 = 1+2+3+4

  my $fac = (\f -> \n -> { ($n<1) ? 1 : $n*$f->($n-1) });

  my $Y   = (\m -> (\f -> m (\a -> f f a))
                   (\f -> m (\a -> f f a)));

  print $Y->($fac)->(5) . "\n";  # 120 = 5!

=head1 DESCRIPTION

This experimental module extends Perl syntax with Haskell-style
lambdas. Curried addition can be written as

  (\x -> \y -> {$x + $y})->(1)->(2) # 3

Watch your Perl blocks to have fully balanced parens; also,
unlike Haskell, the following is not curried:

  \a b -> ...

Rather, it can be used like this:

  (\a b -> {$a + $b})->(1, 2)  # 3

=head1 AUTHOR

Anton Tayanovskyy <name.surname@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Anton Tayanovskyy. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Acme::Lambda>, L<Language::Functional>, L<Filter::Simple>, L<Sub::Lambda>


=cut
