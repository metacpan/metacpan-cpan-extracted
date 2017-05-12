package Sub::Quotelike;

use strict;
use warnings;
use Filter::Simple;
use Text::Balanced qw/extract_quotelike/;

our $VERSION = 0.03;
our %qq_subs = ();

FILTER {
    while (s/(\bsub\s+(\w+)\s*)\((["'])\3?\)/$1(\$)/) {
	if (exists $qq_subs{$2} && $qq_subs{$2} ne $3) {
	    die "Prototype mismatch: $2 ($3) vs $2 ($qq_subs{$2})";
	}
	$qq_subs{$2} = $3;
    }
    for my $s (keys %qq_subs) {
	my $qq = $qq_subs{$s} eq q(") ? 'qq' : 'q';
	s/\bsub\s+$s\b/sub __qUoTeLiKe_$s/g;
	s/{\s*(["']?)$s\1\s*}/{__qUoTeLiKe_$s}/g;
	s/(?<![\$\@%&*])\b$s\b(?!\s*=>)/__qUoTeLiKe_$s($qq/g;
	while (/__qUoTeLiKe_$s\((?=q)/g) {
	    my $savepos = pos;
	    () = extract_quotelike($_);
	    s/\G/)/;
	    pos() = $savepos;
	}
    }
    s/__qUoTeLiKe_//g;
};

1;

__END__

=head1 NAME

Sub::Quotelike - Allow to define quotelike functions

=head1 SYNOPSIS

    use Sub::Quotelike;

    sub myq (') {
	my $s = shift;
	# Do something with $s...
	return $s;
    }

    sub myqq (") {
	my $s = shift;
	# Do something with $s...
	return $s;
    }

    print myq/abc def/;
    print myqq{abc $def @ghi\n};

    no Sub::Quotelike; # disallows quotelike functions
		       # in the remaining code

=head1 DESCRIPTION

This module allows to define quotelike functions, that mimic the
syntax of the builtin operators C<q()>, C<qq()>, C<qw()>, etc.

To define a quotelike function that interpolates quoted text, use
the new C<(")> prototype. For non-interpolating functions, use C<(')>.
That's all.

To be polite with some indenters and syntax highlighters, the prototypes
C<('')> and C<("")> are accepted as synonyms for C<(')> and C<("")>.

=head1 TIPS

This module is a source filter. This means that its use is perhaps less
straightforward than other modules.

Suppose you want to define a quotelike function in one of your modules
and export it. Here's how to do it, this example using the classic rot13
function :

    package Rot13;
    use strict;
    use warnings;
    use Exporter;
    use Sub::Quotelike;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(&qq_rot13);
    sub qq_rot13 (") {
	my $str = shift;
	$str =~ tr/a-zA-Z/n-za-mN-ZA-M/;
	return $str;
    }
    sub import {
	TEQF->export_to_level(1,@_);
	goto &Sub::Quotelike::import;
    }
    1;

This custom C<import> method does two things : it exports the
C<qq_rot13> symbol (see L<Exporter>, that defines the function
C<export_to_level>), and it calls C<Sub::Quotelike::import> in the same
stack frame. With this trick, when you do C<use Rot13> in one of your
programs, the source filter is automagically enabled.

=head1 BUGS

This module has bugs !!

It uses Filter::Simple internally. As I don't want to reimplement the
perl tokenizer today, this means that it only performs some heuristic
substitutions on the perl source code, to replace quotelike function
calls by something more meaningful to plain perl 5.

Basically, if you have a quotelike function C<foo>, you'll be able to
use without pain the variables $foo, @foo, and %foo, and to use
&foo(...) if you want to bypass the quotelike syntax. 'foo' quoted by a
fat comma (as in C<foo =E<gt> 1>) and as a bare hash key (C<$hash{foo}>)
also works. But you'll have problems if you write a literal word 'foo'
in your code at other places (like in C<print "xxx foo yyy">).

So my advice is to use meaningful names, unlikely to clash, for your
quotelike functions : e.g. names that begin with 'q_' or 'qq_'. Disable
also the source filter in parts of your programs where it can cause
problems.

=head1 AUTHOR

Copyright (c) 2001,2002 Rafael Garcia-Suarez. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
