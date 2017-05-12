# NAME

Perl::Critic::Policy::CompileTime - Provide Perl::Critic support for hunting
down compile-time side effects

# SUMMARY

Perl::Critic::Policy::CompileTime and PPIx::PerlCompiler: A dynamic duo for
finding abberant code with bad compile-time side effects!

# SYNOPSIS

    ~$ cat ~/.perlcriticrc
    include = CompileTime

# DESCRIPTION

Perl::Critic::Policy::CompileTime is a Perl::Critic module which allows one to
quickly find code in a large codebase or installation which may not run the way
one expects when compiled by the Perl compiler, B::C.  With the help of the
underlying code in PPIx::PerlCompiler, it does so by performing some rudimentary
pattern matching against statements and subexpressions in specific instances.

## FEATURES

PPIx::PerlCompiler provides the ability to check compile time code blocks,
BEGIN, UNITCHECK, and CHECK, for code that may likely have system-wide side
effects, or may perform I/O that may invalidate dependent state of compiled
binaries when they run.

Perl::Critic::Policy::CompileTime issues severity level 40 advisories regarding
the aforementioned features in Perl code.  To use this module with Perl::Critic,
simply add something like the following to your .perlcriticrc file:

    include = CompileTime

# SEE ALSO

- [Perl::Critic](https://metacpan.org/pod/Perl::Critic)

# AUTHOR

Xan Tronix <xan@cpan.org>
