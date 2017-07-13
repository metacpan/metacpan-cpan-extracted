package Perl::Stripper;

our $DATE = '2017-07-11'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use Log::ger;

use PPI;
use Moo;
use experimental 'smartmatch';

has maintain_linum      => (is => 'rw', default => sub { 1 });
has strip_comment       => (is => 'rw', default => sub { 1 });
has strip_pod           => (is => 'rw', default => sub { 1 });
has strip_ws            => (is => 'rw', default => sub { 1 });
has strip_log           => (is => 'rw', default => sub { 0 });
has stripped_log_levels => (is => 'rw', default => sub { [qw/debug trace/] });

sub _strip_el_content {
    my ($self, $el) = @_;

    my $ct;
    if ($self->maintain_linum) {
        $ct = $el->content;
        my $num_nl = () = $ct =~ /\R/g;
        $ct = "\n" x $num_nl;
    } else {
        $ct = "";
    }
    $el->set_content($ct);
}

sub _strip_node_content {
    my ($self, $node) = @_;

    my $ct;
    if ($self->maintain_linum) {
        $ct = $node->content;
        my $num_nl = () = $ct =~ /\R/g;
        $ct = "\n" x $num_nl;
    } else {
        $ct = "";
    }
    $node->prune(sub{1});
    $node->add_element(PPI::Token::Whitespace->new($ct)) if $ct;
}

sub strip {
    my ($self, $perl) = @_;

    my @ll   = @{ $self->stripped_log_levels };
    my @llf  = map {$_."f"} @ll;
    my @isll = map {"is_$_"} @ll;

    my $doc = PPI::Document->new(\$perl);
    my $res = $doc->find(
        sub {
            my ($top, $el) = @_;

            if ($self->strip_comment && $el->isa('PPI::Token::Comment')) {
                # don't strip shebang line
                if ($el->content =~ /^#!/) {
                    my $loc = $el->location;
                    return if $loc->[0] == 1 && $loc->[1] == 1;
                }
                if (ref($self->strip_comment) eq 'CODE') {
                    $self->strip_comment->($el);
                } else {
                    $self->_strip_el_content($el);
                }
            }

            if ($self->strip_pod && $el->isa('PPI::Token::Pod')) {
                if (ref($self->strip_pod) eq 'CODE') {
                    $self->strip_pod->($el);
                } else {
                    $self->_strip_el_content($el);
                }
            }

            if ($self->strip_log) {
                my $match;
                if ($el->isa('PPI::Statement')) {
                    # matching '$log->trace(...);'
                    my $c0 = $el->child(0);
                    if ($c0->content eq '$log') {
                        my $c1 = $c0->snext_sibling;
                        if ($c1->content eq '->') {
                            my $c2 = $c1->snext_sibling;
                            my $c2c = $c2->content;
                            if ($c2c ~~ @ll || $c2c ~~ @llf) {
                                $match++;
                            }
                        }
                    }
                }
                if ($el->isa('PPI::Statement')) {
                    # matching 'log_trace(...);'
                    my $c0 = $el->child(0);
                    if (grep { $c0->content eq "log_$_" } @ll) {
                        $match++;
                    }
                }
                if ($el->isa('PPI::Statement::Compound')) {
                    # matching 'if ($log->is_trace) { ... }' or 'if (log_is_trace()) { ... }'
                    my $c0 = $el->child(0);
                    if ($c0->content eq 'if') {
                        my $cond = $c0->snext_sibling;
                        if ($cond->isa('PPI::Structure::Condition')) {
                            my $expr = $cond->child(0);
                            if ($expr->isa('PPI::Statement::Expression')) {
                                my $c0 = $expr->child(0);
                                if ($c0->content eq '$log') {
                                    my $c1 = $c0->snext_sibling;
                                    if ($c1->content eq '->') {
                                        my $c2 = $c1->snext_sibling;
                                        my $c2c = $c2->content;
                                        if ($c2c ~~ @isll) {
                                            $match++;
                                        }
                                    }
                                } elsif (grep {$c0->content eq "log_is_$_"} @ll) {
                                    $match++;
                                }
                            }
                        }
                    }
                }

                if ($match) {
                    if (ref($self->strip_log) eq 'CODE') {
                        $self->strip_log->($el);
                    } else {
                        $self->_strip_node_content($el);
                    }
                }
            }

            0;
        }
    );
    die "BUG: find() dies: $@!" unless defined($res);

    $doc->serialize;
}

1;
# ABSTRACT: Yet another PPI-based Perl source code stripper

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Stripper - Yet another PPI-based Perl source code stripper

=head1 VERSION

This document describes version 0.10 of Perl::Stripper (from Perl distribution Perl-Stripper), released on 2017-07-11.

=head1 SYNOPSIS

 use Perl::Stripper;

 my $stripper = Perl::Stripper->new(
     #maintain_linum => 1, # the default, keep line numbers unchanged
     #strip_ws       => 1, # the default, strip extra whitespace
     #strip_comment  => 1, # the default
     #strip_pod      => 1, # the default
     strip_log       => 1, # default is 0, strip Log::Any log statements
 );
 $stripped = $stripper->strip($perl);

=head1 DESCRIPTION

This module is yet another PPI-based Perl source code stripper. Its focus is on
costumization and stripping meaningful information from source code.

=head1 ATTRIBUTES

=head2 maintain_linum => BOOL (default: 1)

If set to true, stripper will try to maintain line numbers so they do not change
between the unstripped and the stripped version. This is useful for debugging.

Respected by other settings.

=head2 strip_ws => BOOL (default: 1)

Strip extra whitespace, like indentation, padding, even non-significant
newlines. Under C<maintain_linum>, will not strip newlines.

Not yet implemented.

=head2 strip_comment => BOOL (default: 1) | CODE

If set to true, will strip comments. Under C<maintain_linum> will replace
comment lines with blank lines.

Shebang line (e.g. C<#!/usr/bin/perl>, located at the beginning of script) will
not be stripped.

Can also be set to a coderef. Code will be given the PPI comment token object
and expected to modify the object (e.g. using C<set_content()> method). See
L<PPI::Token::Comment> for more details. Some usage ideas: translate comment,
replace comment with gibberish, etc.

=head2 strip_log => BOOL (default: 1)

If set to true, will strip log statements. Useful for removing debugging
information. Currently supports L<Log::Any> and L<Log::ger> and only looks for
the following statements:

 $log->LEVEL(...);
 $log->LEVELf(...);
 log_LEVEL(...);
 if ($log->is_LEVEL) { ... }
 if (log_is_LEVEL()) { ... }

Not all methods are stripped. See C<stripped_log_levels>.

Can also be set to a coderef. Code will be given the L<PPI::Statement> object
and expected to modify it.

These are currently not stripped:

 if (something && $log->is_LEVEL) { ... }

=head2 stripped_log_levels => ARRAY_OF_STR (default: ['debug', 'trace'])

Log levels to strip. By default, only C<debug> and C<trace> are stripped. Levels
C<info> and up are considered important for users (instead of for developers
only).

=head2 strip_pod => BOOL (default: 1)

If set to true, will strip POD. Under C<maintain_linum> will replace POD with
blank lines.

Can also be set to a coderef. Code will be given the PPI POD token object and
expected to modify the object (e.g. using C<set_content()> method). See
L<PPI::Token::Pod> for more details.Some usage ideas: translate POD, convert POD
to Markdown, replace POD with gibberish, etc.

=head1 METHODS

=head2 new(%attrs) => OBJ

Constructor.

=head2 $stripper->strip($perl) => STR

Strip Perl source code. Return the stripped source code.

=head1 FAQ

=head2 What is the use of this module?

This module can be used to remove debugging information (logging statements,
conditional code) from source code.

This module can also be employed as part of source code protection strategy. In
theory you cannot hide source code you deploy to users/clients, but you can
reduce the usefulness of the deployed source code by removing information such
as comments and POD (documentation), or by mangling subroutine/variable names
(removing meaningful original subroutine/variable names).

For compressing source code (reducing source code size), you can try
L<Perl::Squish> or L<Perl::Strip>.

=head2 But isn't hiding/protecting source code immoral/unethical/ungrateful?

Discussing hiding/protecting source code in general is really beyond the scope
of this module's documentation. Please consult elsewhere.

=head2 How about obfuscating by encoding Perl code?

For example, changing:

 foo();
 bar();

into:

 $src = base64_decode(...); # optionally multiple rounds
 eval $src;

This does not really remove meaningful parts of a source code, so I am not very
interested in this approach. You can send a patch if you want.

=head2 How about changing string into hexadecimal characters? How about ...?

Other examples similar in spirit would be adding extra parentheses to
expressions, changing constant numbers into mathematical expressions.

Again, this does not I<remove> meaningful parts of a source code (instead, they
just transform stuffs). The effect can be reversed trivially using L<Perl::Tidy>
or L<B::Deparse>. So I am not very interested in doing this, but you can send a
patch if you want.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Stripper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Stripper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Stripper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

There are at least two approaches when analyzing/modifying/producing Perl code:
L<B>-based and L<PPI>-based. In general, B-based modules are orders of magnitude
faster than PPI-based ones, but each approach has its strengths and weaknesses.

L<B::Deparse> - strips comments and extra newlines

L<B::Deobfuscate> - like B::Deparse, but can also rename variables. Despite its
name, if applied to a "normal" Perl code, the effect is obfuscation because it
removes the original names (and meaning) of variables.

L<Perl::Strip> - PPI-based, focus on compression.

L<Perl::Squish> - PPI-based, focus on compression.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
