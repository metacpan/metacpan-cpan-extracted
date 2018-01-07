use 5.10.1;
use strict;
use warnings;
package String::Stomp;

our $VERSION = '0.0103';
# ABSTRACT: Removes empty leading and trailing lines
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY

use Exporter 'import';
our @EXPORT = qw/stomp/;

sub stomp($) {
    my $string = shift;

    $string =~ s{\A[\h\v]*\v(?=\h*[^\h\v])}{};
    $string =~ s{([^\h\v]\V*)\v[\h\v]*\z}{$1};

    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

String::Stomp - Removes empty leading and trailing lines



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<a href="https://travis-ci.org/Csson/p5-String-Stomp"><img src="https://api.travis-ci.org/Csson/p5-String-Stomp.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/String-Stomp-0.0103"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/String-Stomp/0.0103" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=String-Stomp%200.0103"><img src="http://badgedepot.code301.com/badge/cpantesters/String-Stomp/0.0103" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-100.0%-brightgreen.svg" alt="coverage 100.0%" />
</p>

=end html

=head1 VERSION

Version 0.0103, released 2017-12-31.

=head1 SYNOPSIS

    use String::Stomp;

    sub out {
        print stomp q{
            A short
            text
        };
    }

    # is exactly the same as
    sub out {
        print q{        A short
            text};
    }

=head1 DESCRIPTION

String::Stomp provides C<stomp>, a simple function that removes all leading and trailing lines that only consist of white space or line breaks.

=head2 FUNCTIONS

=head3 stomp $string

    # '        hello'
    my $string = stomp q{
        hello
    };

=head2 MORE EXAMPLES

=head3 Usage with L<qs|Syntax::Feature::Qs>

L<Syntax::Feature::Qs> adds C<qs> and C<qqs> that removes all leading whitespace from all lines in a string:

    # these three packages are equivalent:
    package Example::Stomp {

        use String::Stomp;
        use syntax 'qs';

        sub out {
            print stomp qs{
                This is
                a multi line

                string.
            };
        }
    }
    package Example::Q {

        sub out {
            print q{This is
    a multi line

    string.};
        }
    }
    package Example::HereDoc {

        sub out {

            (my $text = <<"            END") =~ s{^ {12}}{}gm;
                This is
                a multi line

                string.
                END

            $text =~ s{\v\z}{};
            print $text;
        }
    }

=head1 SEE ALSO

=over 4

=item *

L<String::Trim::More>

=item *

L<String::Util>

=item *

L<qs|Syntax::Feature::Qs>

=item *

L<qi|Syntax::Feature::Qi>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-String-Stomp>

=head1 HOMEPAGE

L<https://metacpan.org/release/String-Stomp>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
