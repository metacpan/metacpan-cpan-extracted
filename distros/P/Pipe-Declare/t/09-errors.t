#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Milestone 6: every parser failure must give a specific, helpful error
# message - not just a generic "syntax error".

sub compile_fails {
    my ($code, $rx, $label) = @_;
    my $ok = eval "use Pipe::Declare; $code; 1";
    my $err = $@;
    ok( !$ok, "$label: compilation fails" );
    like( $err, $rx, "$label: error message matches /$rx/" );
}

# --- empty pipe (no '|>' at all) ------------------------------------------

compile_fails(
    'my $r = pipe { 1 };',
    qr/pipe:\s*a pipe \{ \} block must contain at least one '\|>' step/,
    'empty pipe',
);

# --- missing '{' after the keyword ----------------------------------------

compile_fails(
    'my $r = pipe 1;',
    qr/pipe:\s*expected '\{' after 'pipe'/,
    'no opening brace',
);

# --- '|>' with no step ----------------------------------------------------

compile_fails(
    'my $r = pipe { 1 |> };',
    qr/pipe:\s*expected a step/,
    '|> followed by closing brace',
);

# --- ';' mid-pipeline (more than one statement) --------------------------

compile_fails(
    'my $r = pipe { 1 |> sub { $_[0] }; 2 |> sub { $_[0] } };',
    qr/pipe:\s*a pipe \{ \} block must contain exactly one pipeline expression/,
    'two pipelines separated by ;',
);

# --- '|' without '>' ------------------------------------------------------

compile_fails(
    'my $r = pipe { 1 | sub { $_[0] } };',
    qr/pipe:\s*expected '\|>'/,
    'bare | without > between steps',
);

# --- head: leading token that is none of the supported head shapes -------

compile_fails(
    'my $r = pipe { ! |> sub { $_[0] } };',
    qr/pipe:/,
    'unsupported head token croaks with a pipe: message',
);

# --- '\' followed by non-'&' --------------------------------------------

compile_fails(
    'my $r = pipe { 1 |> \\$x };',
    qr/pipe:\s*expected '&' after/,
    'backslash followed by non-&',
);

# --- 'sub' without a following block -----------------------------------

compile_fails(
    'my $r = pipe { 1 |> sub bareword };',
    qr/pipe:\s*expected '\{' after 'sub'/,
    'sub without { errors',
);

# --- '->' followed by something that is none of method/key/idx ---------

compile_fails(
    'my $r = pipe { 0 |> -> + 1 };',
    qr/pipe:\s*expected method name/,
    '-> with neither name nor { nor [',
);

done_testing;
