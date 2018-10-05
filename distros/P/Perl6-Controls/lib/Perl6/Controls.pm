package Perl6::Controls;

use 5.012; use warnings;

our $VERSION = '0.000007';


use Keyword::Declare;

sub import {

    # Rewire the 'for' loop (but we need to handle existing usages first)...

    keyword for {{{ foreach }}}

    keytype OptIter is /(?:my|our|state)\s*\$\w+/;

    keyword for (OptIter $iter = '', '(', '^', Int $max, ')') {{{ for <{$iter}> (0..<{$max-1}>) }}}

    keyword for (ParenthesesList $list, '->', CommaList $parameters, Block $code_block)
                :desc(enhanced for loop)
    {{{
        {
            state $__acc__ = [];
            foreach my $__nary__  <{ $list =~ s{\)\Z}{,\\\$__acc__)}; $list }>
            {
                if (!ref($__nary__) || $__nary__ != \$__acc__) {
                    push @{$__acc__}, $__nary__;
                    next if @{$__acc__} <= <{ $parameters =~ tr/,// }>;
                }
                next if !@{$__acc__};
                my ( <{"$parameters"}> ) = @{$__acc__};
                @{$__acc__} = ();

                <{substr $code_block, 1, -1}>
            }
        }
    }}}


    # Perl 6 infinite loop...
    keyword loop (Block $loop_block)  {{{
        foreach (;;) <{$loop_block}>
    }}}


    # Perl 6 while loop...
    keyword while (List $condition, Block $loop_block)  {{{
        foreach (;<{$condition}>;) <{$loop_block}>
    }}}

    keyword while (List $condition, '->', ScalarVar $parameter, Block $loop_block)  {{{
        foreach (;my <{$parameter}> = <{$condition}>;) <{$loop_block}>
    }}}


    # Perl 6 repeat...while and variants...

    keyword repeat ('while', List $while_condition, Block $code_block) :desc(repeat loop)  {{{
        foreach(;;) <{substr($code_block,0,-2)}>; last if !(<{$while_condition}>); }
    }}}

    keyword repeat ('until', List $until_condition, Block $code_block) {{{
        foreach(;;) <{substr($code_block,0,-2)}>; last if <{$until_condition}>; }
    }}}

    keyword repeat (Block $code_block,
                    /while|until/ $while_or_until,
                    Expr $condition) {
        my $not = $while_or_until eq 'while' ? q{!} : q{};
        qq{ foreach (;;) { do $code_block; last if $not ($condition); } };
    }


    # Special Perl 6 phasers within loops...

    keytype Etc is / (?: (?&PerlOWS) (?&PerlStatement) )* (?&PerlOWS) \} /x;

    keyword LEAVE (Block $code_block) :desc(LEAVE block) {
        state $leave_var = '__LEAVE__00000000000000000000000001';
        return qq{use Scope::Upper; Scope::Upper::reap $code_block;};
    }

    keyword FIRST (Block $code_block) :then(Etc $rest_of_block) :desc(FIRST block) {
        state $FIRST_ID = 'FIRST000000'; $FIRST_ID++;
        qq{
            if (!(our \$$FIRST_ID)++) $code_block
            $rest_of_block;
            {our \$$FIRST_ID = 0}
        };
    }

    keyword NEXT (Block $code_block) :then(Etc $rest_of_block) :desc(NEXT block) {
        state $NEXT_ID = 'NEXT000000'; $NEXT_ID++;
        chop $rest_of_block;
        qq{
            my \$$NEXT_ID = sub $code_block;
            $rest_of_block;
            \$$NEXT_ID->();
            \}
        };
    }

    keyword LAST (Block $code_block) :then(Etc $rest_of_block) :desc(LAST block) {
        state $LAST_ID = 'LAST000000'; $LAST_ID++;
        qq{
            our \$$LAST_ID = sub $code_block;
            $rest_of_block;
            {our \$$LAST_ID->();}
        };
    }

    # try and CATCH...

    keytype CatchParam is / \( (?&PerlOWS) (?&PerlVariableScalar) (?&PerlOWS) \) /x;

    keyword CATCH (CatchParam $param = '($P6C____EXCEPTION)', Block $block) :desc(CATCH phaser) {{{
        BEGIN { eval'$P6C____CATCH=$P6C____CATCH;1' // die q{Can't specify CATCH block outside a try};              }
        BEGIN { die q{Can't specify two CATCH blocks inside a single try} if defined $P6C____CATCH;          }
        BEGIN { $P6C____CATCH = sub { use experimentals; my <{$param}> = @_; given (<{$param}>) <{$block}> } }
    }}}

    keyword try (Block $block) {{{
        { my $P6C____CATCH; eval { <{$block}> 1 } // do{ my $error = $@; $P6C____CATCH && $P6C____CATCH->($error) }; }
    }}}


    # Feed statement...

    keytype FeedArg is / (?&PerlExpression) (?&PerlOWS) ==> /xs;

    keyword feed (FeedArg @from, Expr $to) {

        my @list = map { 
            m{\A ( (?&PerlVariable) | (?&PerlVariableDeclaration) ) \Z  $PPR::GRAMMAR }xms
                ? "($1) = "
                : $_
        }
        ($to, reverse map { substr($_,0,-4) } @from);

        while (@list > 1) {
            my ($func, $data) = splice(@list, -2);
            push @list, "($func $data)";
        }

        return $list[0];
    }
}

1; # Magic true value required at end of module
__END__


=head1 NAME

Perl6::Controls - Add Perl 6 control structures as Perl 5 keywords


=head1 VERSION

This document describes Perl6::Controls version 0.000007


=head1 SYNOPSIS

    use Perl6::Controls;

    try {
        CATCH { warn 'No more animals :-(' }

        loop {
            my @animals;

            repeat while (!@animals) {
                say 'Enter animals: ';
                scalar readline // die
                    ==> split /\s+/,
                    ==> grep {exists $group_of{$_} }
                    ==> @animals;
            }

            for (%group_of{@animals}) -> $animal, $group {
                FIRST { say "\n(" }
                say " '$animal' => '$group',";
                LAST  { say ")\n" }
            }
        }
    }


=head1 DESCRIPTION

This module steals some of the most useful control structures
provided by Perl 6 and retrofits them to Perl 5, via the
extensible keyword mechanism.


=head1 INTERFACE

=head2 C<< loop {...} >>

The C<loop> loop is simply an infinite loop:

    loop {
        say 'Are we there yet?';
        sleep 60;
    }

Note that this module does not implement the extended Perl 6
C<loop (INIT; COND; INCR) {...}> syntax, as that is
already covered by Perl 5's builtin C<for>.


=head2 C<< for (LIST) -> $VAR1, $VAR2, $ETC {...} >>

The module adds an additional syntax for C<for> loops,
which allows one or more (lexical) iterator variables
to be specified in the Perl 6 way: after the list.

That is, instead of:

    for my $pet ('cat', 'dog', 'fish') {
        say "Can I have a $pet?";
    }

you can write:

    for ('cat', 'dog', 'fish') -> $pet {
        say "Can I have a $pet?";
    }

The real advantage of the Perl 6 syntax is that you can specify two or
more iterator variables for the same loop, in which case the loop will
iterate its list N-at-a-time. For example:

    for (%pet_prices) -> $pet, $price {
        say "A $pet costs $price";
    }

Note that, unlike in Perl 6, the list to be iterated still
requires parentheses around it.

Under Perl v5.22 and later, you can specify the variables after
the arrow with a leading reference, in which case the corresponding
values are aliased to that variable (see L<perlref/"Assigning to References">).

Note that the relevant experimental features must be activated to use this.


For example:

    use experimental qw< refaliasing declared_refs>;

    for (%hash_of_arrays) -> $key, \@array {
        # Print the contents of each hash entry...
        say "$key has $_" foreach @array;

        # Append an element to each nested array...
        push @array, 42;s
    }


=head2 C<< while (COND) -> $VAR {...} >>

The module also adds a similar new syntax for C<while> loops,
allowing them to test their condition and assign it to
a lexically scoped variable using the "arrow" syntax.

That is, instead of:

    while (my $input = readline) {
        process( $input );
    }

You can write:

    while (readline) -> $input {
        process( $input );
    }

Note that, unlike the modified C<for> syntax, this modified
C<while> only allows a single variable after the arrow.


=head2 C<< repeat while (COND) {...} >>

=head2 C<< repeat until (COND) {...} >>

=head2 C<< repeat {...} while COND >>

=head2 C<< repeat {...} until COND >>

The Perl 5 C<do...while> and C<do...until> constructs are not proper
loops (they're quantified C<do> statements). This means, for example,
that you can't use C<next>, C<last>, or C<redo> to control them.

The Perl 6 C<repeat> constructs are genuine "iterate-then-test" loops,
and also allow the condition to be specified either after or before the
block.

Therefore, instead of:

    do {
        print 'Next value: ';
        $value = get_data() // last;  # Oops!
    }
    while ($value !~ /^\d+$/);

or equivalently:

    do {
        print 'Next value: ';
        $value = get_data() // last;  # Oops!
    }
    until ($value =~ /^\d+$/);

you can write any of the following:

    repeat {
        print 'Next value: ';
        $value = get_data() // last;  # Works as expected
    }
    while ($value !~ /^\d+$/);

    repeat {
        print 'Next value: ';
        $value = get_data() // last;  # Works as expected
    }
    until ($value =~ /^\d+$/);

    repeat while ($value !~ /^\d+$/) {
        print 'Next value: ';
        $value = get_data() // last;  # Works as expected
    }

    repeat until ($value =~ /^\d+$/) {
        print 'Next value: ';
        $value = get_data() // last;  # Works as expected
    }


=head2 C<< FIRST {...} >>

=head2 C<< NEXT  {...} >>

=head2 C<< LAST  {...} >>

These special blocks can only be placed in a loop block,
and will execute at different points in each execution
of the surrounding loop.

The C<FIRST> block is executed only on the first iteration of the
surrounding loop. The C<NEXT> block iterates at the end of every
iteration of the surrounding loop. The C<LAST> block executes only after
the final iteration of the surrounding loop.

For example, instead of:

    if (@list) {
        print '(';
        for my $elem (@list) {
            print $elem;
            print ',';
        }
        print ')';
    }

you could write:

    for my $elem (@list) {
        FIRST { print '('; }
        print $elem;
        NEXT  { print ','; }
        LAST  { print ')'; }
    }

or (because the order and position in which the special blocks are
declared does not affect when they are called):

    for my $elem (@list) {
        FIRST { print '('; }
        NEXT  { print ','; }
        LAST  { print ')'; }

        print $elem;
    }

=head2 C<< LEAVE  {...} >>

A C<LEAVE> block is executed whenever control exits the surrounding
block, either by falling out the bottom, or via a C<return>, or C<next>,
or C<last>, or C<redo>, or C<goto>, or C<die>.


=head2 C<< try { ... CATCH {...} ... } >>

The C<try> block is more or less equivalent to a Perl 5 C<eval>, except
that it is a proper block, so it doesn't return a value, but it also
doesn't require a semicolon after it. The C<try> intercepts and neutralizes
any exception called within its block.

The C<CATCH> block specifies an alternative response when the surrounding
C<try> intercepts an exception. It may be specified with a parameter,
to which the intercepted exception is then assigned. The C<CATCH> block also
acts like a C<given>, so the exception is always aliased to C<$_>, and 
the block may contain C<when> and C<default> statements as well.

For example:

    try {
        $data = acquire_data();  # May throw exception

        CATCH ($err) {
            when (/bad data/) { warn 'Ignoring bad data' }
            when (/no data/)  { exit -1;  }
            default           { die $err; } # Rethrow unknown exception
        }
    }

Note that the C<CATCH> block is always optional within a C<try>,
and may be placed anywhere within the C<try> block.


=head2 C<< feed EXPR ==> EXPR ==> ... ==> EXPR ; >>

This simulates the Perl 6 feed operator (C<< ==> >>).

Due to limitations in the Perl 5 extension mechanism, the
keyword C<feed> is required at the start of the feed
sequence.

Each expression can be a Perl list operator or n-ary function or a
simple variable or variable declaration. Any simple variable appearing
in the sequence is assigned to (in list context). Anything else has
the result of the preceding expression in the pipeline appended to
its trailing argument list.

For example:

    feed readline() ==> my @input ==> sort ==> join ':', ==> $result;

is equivalent to:

    ($result) = join ':',
                         sort
                             (my @input) =
                                          readline;

Note that the C<join> step must end in a comma, so that appending
the sorted input to it will create a syntactically correct expression.


=head1 DIAGNOSTICS

=over

=item C<< Can't specify CATCH block outside a try >>

The syntax for Perl 6 C<try> blocks requires the C<CATCH> block to be
placed inside the C<try> block (so that it has access to any lexical
variables declared in the C<try>).

You declared a C<CATCH> block outside of any C<try>, which means that
block could never be invoked. Either add a C<try> block around the
source of potential errors that you are trying to catch, or remove
the C<CATCH>.


=item C<< Can't specify two CATCH blocks inside a single try >>

C<try> blocks have a single slot for their C<CATCH> callback, and
it's already full, because you already specified another C<CATCH>
block earlier in the same C<try> block.

Consolidate the code in the two blocks into a single block.
(Remember, it doesn't matter where in the C<try> you place the
C<CATCH>.)

=back


=head1 CONFIGURATION AND ENVIRONMENT

Perl6::Controls requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.14 and the Keyword::Declare module.


=head1 INCOMPATIBILITIES

Due to a problem with regex parsing in Perl v5.20, code
using this module with compile absurdly slowly under that
version of the interpreter. There is no such problem
with any other version of Perl from v5.14 onwards.


=head1 BUGS AND LIMITATIONS

Because the blocks of C<FIRST>, C<LAST>, C<NEXT>, and C<CATCH>
are converted to subroutines, any call to C<return> within
one of these blocks will terminate the block, but not the
surrounding subroutine.

Unlike in Perl 6, the C<FIRST> phaser does not execute I<before>
the first iteration, but rather only during the first iteration.
This means that if you want it to execute at the start of the first
iteration, you need to place it at the start of the iterated block.

The underlying keyword rewriting mechanism (or perhaps the
Keyword::Simple API) seems to have a bug when it comes to keywords
that are also postfix quantifiers. This means that code using this
module cannot also use postfix C<for> or C<while>. It can, however,
still use postfix C<foreach> or C<until>.


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl6-controls@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
