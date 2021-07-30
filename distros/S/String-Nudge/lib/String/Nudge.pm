use 5.10.0;
use strict;
use warnings;

package String::Nudge;

# ABSTRACT: Indents all lines in a multi-line string
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '1.0002';

use Exporter 'import';
our @EXPORT = qw/nudge/;

sub nudge ($;$) {
    my $first = shift;
    my $second = shift;

    my $indent = 4;
    my $string;

    if(defined $second) {
        if(int $first eq $first && int $first >= 0) {
            $indent = int $first;
            $string = $second;
        }
        else {
            warnings::warn(numeric => q{first argument to nudge not an integer >= 0.});
            $string = $second;
        }
    }
    else {
        $string = $first;

    }
    my $nudgement = ' ' x $indent;

    $string =~ s{^(?=\V)}{$nudgement}gms;
    $string =~ s{^\h*$}{}gms;
    return $string;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

String::Nudge - Indents all lines in a multi-line string



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<img src="https://img.shields.io/badge/coverage-100.0%25-brightgreen.svg" alt="coverage 100.0%" />
<a href="https://github.com/Csson/p5-String-Nudge/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-String-Nudge/makefile-test" alt="Build status at Github" /></a>
</p>

=end html

=head1 VERSION

Version 1.0002, released 2021-07-29.

=head1 SYNOPSIS

    use String::Nudge;

    sub out {
        print nudge q{
            A long
            text.
        };
    }

    # is exactly the same as
    sub out {
        print q{
                A long
                text.
    };
    }

=head1 DESCRIPTION

String::Nudge provides C<nudge>, a simple function that indents all lines in a multi line string.

=head2 METHODS

=head3 nudge $string

    # '    hello'
    my $string = nudge 'hello';

=head3 nudge $number_of_spaces, $string

    # '        hello'
    my $string = nudge 8, 'hello';

If C<$number_of_spaces> is not given (or isn't an integer >= 0) its default value is C<4>.

Every line in C<$string> is indented by C<$number_of_spaces>. Lines only consisting of white space is trimmed (but not removed).

=head2 MORE EXAMPLES

=head3 Usage with L<qi|Syntax::Feature::Qi>

L<Syntax::Feature::Qi> adds C<qi> and C<qqi> that removes the same amount of leading whitespace as the first (significant) line has from all lines in a string:

    # these three packages are equivalent:
    package Example::Nudge {

        use String::Nudge;
        use syntax 'qi';

        sub out {
            print nudge qi{
                sub funcname {
                    print 'stuff';
                }
            };
        }
    }
    package Example::Q {

        sub out {
            print q{
        sub funcname {
            print 'stuff';
        }
    };
        }
    }
    package Example::HereDoc {

        sub out {

            (my $text = <<"        END") =~ s{^ {8}}{}gm;
                sub funcname {
                    print 'stuff';
                }
            END

            print $text;
        }
    }

=head3 Usage with L<qs|Syntax::Feature::Qs>

L<Syntax::Feature::Qs> adds C<qs> and C<qqs> that removes all leading whitespace from all lines in a string:

    # these three packages are equivalent:
    package Example::Nudge {

        use String::Nudge;
        use syntax 'qs';

        sub out {
            print nudge qs{
                This is
                a multi line

                string.
            };
        }
    }
    package Example::Q {

        sub out {
            print q{
        This is
        a multi line

        string.
    };
        }
    }
    package Example::HereDoc {

        sub out {

            (my $text = <<"        END") =~ s{^ {8}}{}gm;
                This is
                a multi line

                string.
            END

            print $text;
        }
    }

=head1 SEE ALSO

=over 4

=item *

L<Indent::String>

=item *

L<String::Indent>

=item *

L<qi|Syntax::Feature::Qi>

=item *

L<qs|Syntax::Feature::Qs>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-String-Nudge>

=head1 HOMEPAGE

L<https://metacpan.org/release/String-Nudge>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
