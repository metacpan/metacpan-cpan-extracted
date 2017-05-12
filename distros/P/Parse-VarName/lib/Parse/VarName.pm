package Parse::VarName;

our $DATE = '2016-06-14'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(split_varname_words);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Routines to parse variable name',
};

# cannot be put inside sub, warning "Variable %s will not stay shared"
my @res;

$SPEC{split_varname_words} = {
    v => 1.1,
    summary => 'Split words found in variable name',
    description => <<'_',

Try to split words found in a variable name, e.g. mTime -> [m, Time], foo1Bar ->
[foo, 1, Bar], Foo::barBaz::Qux2 -> [Foo, bar, Baz, Qux, 2].

_
    args => {
        varname => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        include_sep => {
            summary => 'Whether to include non-alphanum separator in result',
            description => <<'_',

For example, under include_sep=true, Foo::barBaz::Qux2 -> [Foo, ::, bar, Baz,
::, Qux, 2].

_
            schema => [bool => {default=>0}],
        },
    },
    result_naked => 1,
};
sub split_varname_words {
    my %args = @_;
    my $v = $args{varname} or return [400, "Please specify varname"];

    #no warnings;
    @res = ();
    $v =~ m!\A(?:
                (
                    [A-Z][A-Z]+ |
                    [A-Z][a-z]+ |
                    [a-z]+ |
                    [0-9]+ |
                    [^A-Za-z0-9]+
                )
                (?{ push @res, $1 })
            )+\z!sxg
                or return [];
    unless ($args{include_sep}) {
        @res = grep {/[A-Za-z0-9]/} @res;
    }

    \@res;
}

1;
# ABSTRACT: Routines to parse variable name

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::VarName - Routines to parse variable name

=head1 VERSION

This document describes version 0.03 of Parse::VarName (from Perl distribution Parse-VarName), released on 2016-06-14.

=head1 FUNCTIONS


=head2 split_varname_words(%args) -> any

Split words found in variable name.

Try to split words found in a variable name, e.g. mTime -> [m, Time], foo1Bar ->
[foo, 1, Bar], Foo::barBaz::Qux2 -> [Foo, bar, Baz, Qux, 2].

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<include_sep> => I<bool> (default: 0)

Whether to include non-alphanum separator in result.

For example, under include_sep=true, Foo::barBaz::Qux2 -> [Foo, ::, bar, Baz,
::, Qux, 2].

=item * B<varname>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-VarName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-VarName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-VarName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
