use 5.10.0;
use strict;
use warnings;

package Syntax::Feature::Qs;

# ABSTRACT: Trim leading whitespace from all lines in a string
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '1.0000';

use Devel::Declare();
use B::Hooks::EndOfScope;
use Sub::Install qw/install_sub/;

use Devel::Declare::Context::Simple;

use namespace::clean;

my %quote_op = qw(qs q qqs qq);
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
        $string =~ s{^\h+|\h+$}{}gms;
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

Syntax::Feature::Qs - Trim leading whitespace from all lines in a string



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Syntax-Feature-Qs"><img src="https://api.travis-ci.org/Csson/p5-Syntax-Feature-Qs.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Syntax-Feature-Qs-1.0000"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Syntax-Feature-Qs/1.0000" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Syntax-Feature-Qs%201.0000"><img src="http://badgedepot.code301.com/badge/cpantesters/Syntax-Feature-Qs/1.0000" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-98.6%-yellow.svg" alt="coverage 98.6%" />
</p>

=end html

=head1 VERSION

Version 1.0000, released 2017-02-12.

=head1 SYNOPSIS

    use syntax 'qs';

    say qs{
        Multi line
        string
    };

    # is exactly the same as

    say q{
    Multi line
    string
    };

=head1 DESCRIPTION

This is a syntax extension to be used with L<syntax>.

It provides two quote-like operators, C<qs> and C<qqs>. They are drop-in replacements for C<q> and C<qq>, respectively.

Their purpose is to automatically trim leading and trailing horizontal whitespace on every line. They do not remove empty lines.

=head1 SEE ALSO

=over 4

=item *

L<Syntax::Feature::Ql> (which served as a base for this)

=item *

L<Syntax::Feature::Qi>

=item *

L<String::Nudge>

=item *

L<syntax>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Syntax-Feature-Qs>

=head1 HOMEPAGE

L<https://metacpan.org/release/Syntax-Feature-Qs>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
