use 5.10.1;
use strict;
use warnings;
package String::Cushion;

# ABSTRACT: Vertically pad a string
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '1.0000';

1;

use Sub::Exporter::Progressive -setup => {
    exports => [qw/cushion/],
    groups => {
        default => [qw/cushion/],
    },
};

sub cushion($$;$) {
    my $top_cushion = shift;
    my $second = shift;
    my $third = shift;

    my $bottom_cushion = defined $third ? $second : $top_cushion;
    my $string = defined $third ? $third : $second;

    if($top_cushion !~ m{^\d+$} || $bottom_cushion !~ m{^\d+$}) {
        return $string;
    }

    $string =~ s{\A[\h\v]*\v(?=\h*[^\h\v])}{};
    $string =~ s{([^\h\v]\V*)\v[\h\v]*\z}{$1};

    $string = ("\n" x $top_cushion) . $string . ("\n" x $bottom_cushion);

    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

String::Cushion - Vertically pad a string



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<a href="https://travis-ci.org/Csson/p5-String-Cushion"><img src="https://api.travis-ci.org/Csson/p5-String-Cushion.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/String-Cushion-1.0000"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/String-Cushion/1.0000" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=String-Cushion%201.0000"><img src="http://badgedepot.code301.com/badge/cpantesters/String-Cushion/1.0000" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-89.2%-orange.svg" alt="coverage 89.2%" />
</p>

=end html

=head1 VERSION

Version 1.0000, released 2020-04-30.

=head1 SYNOPSIS

    use String::Cushion;


    sub out {
        print cushion 2, 3, q{
            A short
            text
        };
    }

    # is exactly the same as
    sub out {
        print q{

            A short
            text.


        };
    }

=head1 DESCRIPTION

String::Cushion provides C<cushion>, a simple function that removes all leading and trailing lines and lines only consisting of white space or line breaks, and then adds a specified number of leading and trailing new lines (C<\n>).

=head2 METHODS

=head3 cushion $number_of_new_lines, $string

    # "\n        hello\n"
    my $string = cushion 1, q{
        hello
    };

=head3 cushion $number_of_leading_new_lines, $number_of_trailing_new_lines, $string

    # "\n        hello\n\n"
    my $string = cushion 1, 2, q{
        hello
    };

=head1 SEE ALSO

=over 4

=item *

L<String::Stomp>

=item *

L<String::Nudge>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-String-Cushion>

=head1 HOMEPAGE

L<https://metacpan.org/release/String-Cushion>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
