#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Milestone 1: prove the keyword plugin is wired correctly.
#
# `pipe` is a Perl core builtin (CORE::pipe READHANDLE,WRITEHANDLE), so:
#  - Outside `use Pipe::Declare` the token resolves to CORE::pipe and
#    behaves like the file-descriptor primitive. We test that fact by
#    showing CORE::pipe is callable; this also proves our plugin has
#    NOT intercepted the token in this scope.
#  - Inside `use Pipe::Declare` the token is intercepted at parse time
#    and routed to our stub parser, which croaks with the marker
#    message. (Milestone 2 replaces the stub.)

# Outside the pragma: CORE::pipe still works.
{
    my $r = eval { pipe(my $rh, my $wh) };
    ok( defined $r, 'CORE::pipe is reachable outside the pragma scope' )
        or diag $@;
}

# Inside the pragma: the keyword plugin intercepts `pipe { ... }`.
# `pipe { 42 }` is intercepted but is a no-step pipe, which the parser
# rejects with a specific message - that's all we need to prove the
# plugin reached our parser.
{
    my $ok = eval q{
        use Pipe::Declare;
        pipe { 42 };
        1;
    };
    my $err = $@;
    ok( !$ok, 'pipe inside the pragma scope is intercepted' );
    like( $err, qr/pipe:\s*a pipe \{ \} block must contain at least one/,
          'real parser fires - keyword plugin is wired to pd_parse_pipe' );
}

# The pragma is lexical: an explicit `no Pipe::Declare` inside a nested
# scope must restore the builtin behaviour even while the outer scope
# still has `use Pipe::Declare` active.
{
    my $ok = eval q{
        use Pipe::Declare;
        {
            no Pipe::Declare;
            pipe(my $rh, my $wh);   # CORE::pipe again, takes two args
            1;
        }
    };
    ok( $ok, 'no Pipe::Declare in an inner scope restores CORE::pipe' )
        or diag $@;
}

done_testing;
