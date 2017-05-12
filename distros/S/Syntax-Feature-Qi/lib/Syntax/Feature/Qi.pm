use 5.10.0;
use strict;
use warnings;

package Syntax::Feature::Qi;

# ABSTRACT: Remove the same indendation from all lines in a string
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '1.0000';

use Devel::Declare();
use B::Hooks::EndOfScope;
use Sub::Install qw/install_sub/;
use Devel::Declare::Context::Simple;
use namespace::clean;

my %quote_op = qw(qi q qqi qq);
my @new_ops = keys %quote_op;

sub install {
    my $class = shift;
    my %args = @_;

    my $target = $args{'into'};

    Devel::Declare->setup_for($target => {
        map {
            my $name = $_;
            ($name => {
                const => sub {
                    my $context = Devel::Declare::Context::Simple->new;
                    $context->init(@_);
                    return $class->_transform($name, $context);
                },
            });
        } @new_ops
    });
    foreach my $name (@new_ops) {
        install_sub {
            into => $target,
            as => $name,
            code => $class->_run_callback,
        };
    }
    on_scope_end {
        namespace::clean->clean_subroutines($target, @new_ops);
    };
    return 1;
}

sub _run_callback {

    return sub ($) {
        my $string = shift;
        return $string if $string =~ m{\A\s*\Z}ms;

        my $remove_indent = $string =~ m{\A(\h*)\S}      ? $1
                          : $string =~ m{\A\s*\n(\h*)\S} ? $1
                          :                                ''
                          ;
        $string =~ s{^$remove_indent}{}gms;
        return $string;
    };
}

sub _transform {
    my $class = shift;
    my $name = shift;
    my $ctx = shift;

    $ctx->skip_declarator;
    my $length = Devel::Declare::toke_scan_str($ctx->offset);
    my $string = Devel::Declare::get_lex_stuff;
    Devel::Declare::clear_lex_stuff;
    my $linestr = $ctx->get_linestr;
    my $quoted = substr $linestr, $ctx->offset, $length;
    my $spaced = '';
    $quoted =~ m{^(\s*)}sm;
    $spaced = $1;
    my $new = sprintf '(%s)', join '',
        $quote_op{$name},
        $spaced,
        substr($quoted, length($spaced), 1),
        $string,
        substr($quoted, -1, 1);
    substr($linestr, $ctx->offset, $length) = $new;
    $ctx->set_linestr($linestr);
    return 1;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Syntax::Feature::Qi - Remove the same indendation from all lines in a string



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Syntax-Feature-Qi"><img src="https://api.travis-ci.org/Csson/p5-Syntax-Feature-Qi.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Syntax-Feature-Qi-1.0000"><img src="https://badgedepot.code301.com/badge/kwalitee/Syntax-Feature-Qi/1.0000" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Syntax-Feature-Qi%201.0000"><img src="https://badgedepot.code301.com/badge/cpantesters/Syntax-Feature-Qi/1.0000" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-97.4%-yellow.svg" alt="coverage 97.4%" />
</p>

=end html

=head1 VERSION

Version 1.0000, released 2016-04-16.

=head1 SYNOPSIS

    use syntax 'qi';

    say qi{
        This is a sub routine:
        sub printme {
            print shift;
        }
    };

    # is exactly the same as

    say qi{
    This is a sub routine:
    sub printme {
        print shift;
    }
    };

=head1 DESCRIPTION

This is a syntax extension to be used with L<syntax>.

It provides two quote-like operators, C<qi> and C<qqi>. They are drop-in replacements for C<q> and C<qq>, respectively.

They work like this: First they find the first line in the string with a non-white space character. It saves the
white space from the beginning of that line up to that character, and then it tries to remove the exact same whitespace from
all other lines in the string.

=head1 SEE ALSO

=over 4

=item *

L<Syntax::Feature::Ql> (which served as a base for this)

=item *

L<Syntax::Feature::Qs>

=item *

L<String::Nudge>

=item *

L<syntax>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Syntax-Feature-Qi>

=head1 HOMEPAGE

L<https://metacpan.org/release/Syntax-Feature-Qi>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
