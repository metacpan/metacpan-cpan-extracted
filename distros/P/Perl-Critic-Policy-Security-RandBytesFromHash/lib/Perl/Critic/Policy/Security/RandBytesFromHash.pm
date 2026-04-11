package Perl::Critic::Policy::Security::RandBytesFromHash;

# ABSTRACT: flag common anti-patterns for generating random bytes

use v5.24;
use warnings;

use parent 'Perl::Critic::Policy';

use List::Util qw( any );
use Perl::Critic::Utils qw( :severities :classification :ppi );
use PPI 1.281; # signatures support
use Readonly 2.01;
use Ref::Util qw( is_plain_arrayref );

# RECOMMEND PREREQ: Ref::Util::XS

our $VERSION = 'v0.1.1';

Readonly my $DESC => 'random bytes generated using a hash';
Readonly my $EXPL => 'A hash seeded with poor sources of entropy is still a poor source of entropy, use system entropy instead.';

use experimental qw( signatures );

sub supported_parameters { () }

sub default_severity { $SEVERITY_HIGH }

sub default_themes { return qw( security cpansec ) }

sub applies_to { 'PPI::Token::Word' }

Readonly my $DIGEST_REGEX => qr/\A (
        ( \w+:: )*
        ( md[2456] | sha( 1 | 224 | 256 ) | digest_data | (hex|b64)?digest(_hash)? | join )
        ( _ ( hex | b64u? | base64 | sum | bytes ) )?
        ) \z/anx;

sub violates ( $self, $elem, $ ) {

    if ( $elem =~ $DIGEST_REGEX && ( is_function_call($elem) || is_method_call($elem) ) )
    {

        my @args = parse_arg_list($elem);

        if ( $self->_is_bad_seed_source( \@args ) ) {
            return $self->violation( $DESC, $EXPL, $elem );
        }

    }

    return ();
}

sub _is_bad_seed_source( $self, $elem ) {

    if ( is_plain_arrayref($elem) ) {
        return any { $self->_is_bad_seed_source($_) } $elem->@*;
    }

    return 0 if $elem->isa("PPI::Token::Whitespace");

    return 1
      if $elem =~ /\A ( (CORE::)?rand | (Time::HiRes::)? (time|gettimeofday|localtime|gmtime|clock_gettime) | refaddr ) \z/anx
      && ( is_perl_builtin_with_optional_argument($elem)
        || is_function_call($elem) );

    return 1 if $elem eq '$$' && is_perl_global($elem);

    return 1 if $elem =~ /\A \$ (PID|PROCESS_ID) \z/anx && $elem->isa("PPI::Token::Symbol");

    return 1 if $elem =~ /\A \{ \s* \} \z/x && $elem->isa("PPI::Structure");

    return 1 if $elem =~ /\A \[ \s* \] \z/x && $elem->isa("PPI::Structure");

    if ( $elem->isa("PPI::Structure") ) {
        return any { $self->_is_bad_seed_source($_) } $elem->children
    }
    elsif ( $elem->isa("PPI::Statement") ) {
        return any { $self->_is_bad_seed_source($_) } $elem->children
    }

    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Security::RandBytesFromHash - flag common anti-patterns for generating random bytes

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

In your F<perlcriticrc> file, add

    [Perl::Critic::Policy::Security::RandBytesFromHash]
    severity = 1

=head1 DESCRIPTION

In the previous century, most operating systems didn't provide a good source of random bytes.
So people who needed to generate random strings for things like session ids in cookies needed to work around this.
They used cryptographic hashes around sources of pseudo-random noise, like

     message_digest( rand() + time() + $PID ... )

It seemed good enough. Hashing functions like MD5 or SHA were state-of-the-art and the output looked random.
That was naive, because the seed values were always predicable:

=over

=item *

Perl's built-in C<rand> is seeded by 32-bits and is predicable enough that the seed can be reverse-engineered after a few iterations.

=item *

The C<time> function is predictable, and is leaked by protocols like HTTP.

=item *

The C<$PID> comes from a small pool of value values, and it's common for child processes (such as workers for a web service) to have sequential ids.

=item *

Perl data structures have predictable reference addresses.

=item *

Internal counters have predictable content, as most of the leading digits will not change between invocations.

=back

If an attacker can guess most of the seed, they can guess the generated data (which might be a session id in cookie that grants access to a website).
When you consider cryptanalysis of older algorithms like MD5 or SHA, along with the significant increase and availability of computing power, then this pattern seems to be an elaborate footgun.

Alas, this pattern still shows up in new code, and it remains in some legacy code.

This is a L<Perl::Critic> policy to flag common cases of this.
Anything that looks like the bad sources of randomness outlined above will be flagged.

What can you use instead?  Modules like L<Crypt::URandom>, L<Crypt::SysRandom> or L<Crypt::PRNG>.

=head1 KNOWN ISSUES

This will identify anything that looks like a hash function or method, or a C<join> with insecure sources in the arguments.
A side-effect is that some code will be flagged twice, for example

    md5_sum( join("", rand, time, $$ ) )

=head1 SEE ALSO

L<CPAN Author’s Guide to Random Data for Security|https://security.metacpan.org/docs/guides/random-data-for-security.html>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash>
and may be cloned from L<https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.24 or later.  Future releases may only support Perl versions released in the last ten
years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications that make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
