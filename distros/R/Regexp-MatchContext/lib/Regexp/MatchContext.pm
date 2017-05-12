package Regexp::MatchContext;

use version; $VERSION = qv('0.0.2');

use warnings;
# use strict;
use Carp;

my $matchcontents;
$matchcontents = qr{ (?:
                        (?> [^()]* )
                        (?>
                            [(] (?{$matchcontents}) [)]
                        )*
                     )*
                 }x;

sub import {
    use overload;

    my $vars  = grep {/\A (?: -vars | -all ) \z/x} @_;
    my $subs  = !$vars || grep {/\A (?: -subs | -all ) \z/x} @_;

    overload::constant
        qr => sub {
            my ($raw) = @_;
            $raw =~ s{ \(\?
                       <
                         ([^\W\d]\w*)
                       >
                       ($matchcontents)
                       \)
                     }
                     { push @vars, "undef\$$1;"; "($2)(?{eval'\$$1=\$^N'})" }gex
                and $raw =~ s/$/|(??{@vars'(?!)'})/;
            $raw =~ s/\(\?p\)/(?{\$Regexp::MatchContext::target_ref=\\\$_})/g
                or $raw =~ s/\A/(?{\$Regexp::MatchContext::target_ref=undef})/;
            return $raw;
        };

    my $caller = caller;
    no warnings 'once';
    for my $name (qw(PREMATCH MATCH POSTMATCH)) {
        tie ${$name}, "Regexp::MatchContext::$name";
        if ($vars) {
            *{$caller.'::'.$name} = \${$name};
        }
        if ($subs) {
            *{$caller.'::'.$name} = sub :lvalue { ${$name} };
        }
    }
}

sub _cant_assign {
    my ($varname) = @_;
    require Carp;
    @CARP_NOT = qw(
        Regexp::MatchContext::PREMATCH
        Regexp::MatchContext::MATCH
        Regexp::MatchContext::POSTMATCH
    );
    Carp::croak
        "Can't assign to $varname because the preceding match didn't set it.\n",
        "(Did you forget to include a (?p) in your regex?)\n",
        "Died";
}

package Regexp::MatchContext::PREMATCH;
use Tie::Scalar;
use base 'Tie::StdScalar';

sub FETCH {
    return undef unless defined ${$Regexp::MatchContext::target_ref};
    return substr ${$Regexp::MatchContext::target_ref}, 0, $-[0];
}

sub STORE {
    my ($self, $newval) = @_;
    Regexp::MatchContext::_cant_assign('$PREMATCH')
        unless defined ${$Regexp::MatchContext::target_ref};
    my $oldlen = length substr ${$Regexp::MatchContext::target_ref}, 0, $-[0], $newval;
    my $delta = length($newval) - $oldlen;
    *- = [map { $_ + $delta } @-];
    *+ = [map { $_ + $delta } @+];
}



package Regexp::MatchContext::MATCH;
use Tie::Scalar;
use base 'Tie::StdScalar';

sub FETCH {
    return undef unless defined ${$Regexp::MatchContext::target_ref};
    return substr ${$Regexp::MatchContext::target_ref}, $-[0], $+[0]-$-[0];
}

sub STORE {
    my ($self, $newval) = @_;
    Regexp::MatchContext::_cant_assign('$MATCH')
        unless defined ${$Regexp::MatchContext::target_ref};
    my $oldlen = length substr ${$Regexp::MatchContext::target_ref}, $-[0], $+[0]-$-[0], $newval;
    my $delta = length($newval) - $oldlen;
    *- = [$-[0] ];
    *+ = [$+[0] + $delta];
}



package Regexp::MatchContext::POSTMATCH;
use Tie::Scalar;
use base 'Tie::StdScalar';

sub FETCH {
    return undef unless defined ${$Regexp::MatchContext::target_ref};
    return substr ${$Regexp::MatchContext::target_ref}, $+[0];
}

sub STORE {
    my ($self, $newval) = @_;
    Regexp::MatchContext::_cant_assign('$POSTMATCH')
        unless defined ${$Regexp::MatchContext::target_ref};
    substr(${$Regexp::MatchContext::target_ref}, $+[0]) = $newval;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Regexp::MatchContext - Replace (and improve) $MATCH, $PREMATCH, and $POSTMATCH


=head1 VERSION

This document describes Regexp::MatchContext version 0.0.2


=head1 SYNOPSIS

    use Regexp::MatchContext -vars;

    $str = m/(?p) \d+ /;

    print "Before:  $PREMATCH\n";
    print "Matched: $MATCH\n";
    print "After:   $POSTMATCH\n";

    $MATCH = 2 * $MATCH;      # substitute into original $str

  
=head1 DESCRIPTION

The English.pm module provides named aliases for Perl's built-in C<$`>,
C<$&> and C<$'> variables: C<$PREMATCH>, C<$MATCH>, and C<$POSTMATCH>.
Unfortunately, those aliases suffer the same problems as their
originals: they degrade the performance of every single regex in your
program, even if you're only using them to get information about a
single match.

This module also provides C<$PREMATCH>, C<$MATCH>, and C<$POSTMATCH>,
but in a way that only impacts the performance of matches that you
specify. That is, these three variables are only set if the most
recently matched regex contained the special (non-standard) meta-
flag: C<(?p)>.

That is:

    use Regexp::MatchContext -vars;

    $str = 'foobarbaz';

    $str =~ /(?p) foo /x;

    # $PREMATCH contains 'foo'
    # $MATCH contains 'bar'
    # $POSTMATCH contains 'baz'

    $str =~ / foo /x;

    # $PREMATCH, $MATCH, and $POSTMATCH all undef

The C<(?p)> marker can be placed anywhere within the regex and, except for
setting the three context variables on a successful match, is otherwise
totally ignored.

=head1 Lvalue match variables

Unlike the match variables provided in standard Perl, all three match
variables provided by Regexp::MatchContext are actually aliases into the
original string that the preceding regex matched. So assigning to any of these
variables, changes the original string.

This means that, instead of:

    $str =~ s/ foo /bar/;

you could write:

    $str =~ m/ foo (?p)/;

    $MATCH = 'bar';

Or remove everything before a match:

    $str =~ m/ foo (?p)/;

    $PREMATCH = q{};


=head2 Match subroutines

If you load the module with the argument C<-subs> instead of C<-vars>,
then instead of exporting the variables C<$PREMATCH>, C<$MATCH>, and
C<$POSTMATCH>, it exports three subroutines: C<PREMATCH()>, C<MATCH()>,
and C<POSTMATCH()>. The subroutines are provided for those who prefer
not to use package variables in their code.

Calling any of these subroutines returns the same value that the corresponding
variable would have yielded:

    use Regexp::MatchContext -subs;

    $str = 'foobarbaz';

    $str =~ /(?p) foo /x;

    # PREMATCH() returns 'foo'
    # MATCH() returns 'bar'
    # POSTMATCH() returns 'baz'

    $str =~ / foo /x;

    # PREMATCH(), MATCH(), and POSTMATCH() all return undef

The three subroutines are also declared C<:lvalue>, so that calls to them can
be assigned to, which causes the corresponding part of the matched string to
be changed (just as assignments to the equivalent variables does). For
example:

    $str =~ m/ foo (?p)/;

    MATCH() = 'bar';

    PREMATCH() = q{};


=head1 DIAGNOSTICS

=over

=item Can't assign to %s because the preceding match didn't set it.

You tried to assign back via one of the capture variables, but the preceding
regex didn't capture anything, so the assignment would do no good. Did you
forget to put a C<(?p)> in your regex?

=back


=head1 CONFIGURATION AND ENVIRONMENT

Regexp::MatchContext requires no configuration files or environment variables.


=head1 DEPENDENCIES

Depends on the Tie::StdScalar and version modules.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-regexp-matchcontext@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


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
