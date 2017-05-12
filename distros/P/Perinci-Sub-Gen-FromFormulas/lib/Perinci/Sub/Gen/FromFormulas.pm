package Perinci::Sub::Gen::FromFormulas;

our $DATE = '2017-03-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_funcs_from_formulas);

our %SPEC;

sub _itemize {
    if (@_ < 1) { return '' }
    elsif (@_ == 1) { return $_[0] }
    elsif (@_ == 2) { return "$_[0] and $_[1]" }
    else { return join(", ", @_[0..$#_-1]).", and ".$_[-1] }
}

sub _to_funcname {
    my $name = shift;
    $name =~ s/[^A-Za-z0-9_]+/_/g;
    lc($name);
}

sub _parse_formula {
    my ($fml, $symbols) = @_;
    my $res = {};
    $fml =~ s/\A([A-Za-z]\w*)\s*=\s*//
        or die "Syntax error in formula '$fml', must be in the form of 'SYM = ...'";
    $res->{y_var} = $1;
    $symbols->{ $1 } or die "Dependent variable $1 is an undefined symbol";
    my %seen;
    while ($fml =~ /([A-Za-z]\w*)(?=\b)(?!\()/g) {
        next if $seen{$1}++;
        $symbols->{ $1 } or die "Independent variable $1 is an undefined symbol";
        push @{ $res->{x_vars} }, $1;
    }
    $res->{x_vars} && @{$res->{x_vars}}
        or die "No independent variables found in formula '$fml'";
    (my $perl_src = $fml) =~ s/([A-Za-z]\w*)(?=\b)(?!\()/\$args{$1}/g;
    $res->{perl_src} = $perl_src;
    $res;
}

$SPEC{gen_funcs_from_formulas} = {
    v => 1.1,
    summary => 'Generate functions from formulas',
    description => <<'_',

This routine helps make creating function (and accompanying Rinci metadata) from
formula less tedious.

_
    args => {
        package => {
            summary => "Generated function's package, e.g. `My::Package`",
            schema => 'str*',
            description => <<'_',

This is needed mostly for installing the function. You usually don't need to
supply this if you set `install` to false.

If not specified, caller's package will be used by default.

_
        },
        install => {
            summary => 'Whether to install generated functions (and metadata)',
            schema  => ['bool*'],
            default => 1,
            description => <<'_',

By default, generated functions will be installed to the specified (or caller's)
package, as well as its generated metadata into %SPEC. Set this argument to
false to skip installing.

_
        },
        symbols => {
            schema => 'hash*',
            req => 1,
        },
        formulas => {
            schema => ['array*', min_len=>1],
            req => 1,
        },

    }, # args
    result => {
        summary => 'A hash of function names and function coderef and metadata',
        schema => 'hash*',
        description => <<'_',
_
    },
    examples => [
        {
            args => {
                symbols => {
                    pv => {
                        caption => 'present value',
                        schema => 'float*',
                    },
                    fv => {
                        caption => 'future value',
                        schema => 'float*',
                    },
                    r => {
                        caption => 'return rate',
                        summary => 'Return rate (e.g. 0.06 or 6%)',
                        schema => 'float*',
                    },
                    n => {
                        caption => 'periods',
                        summary => 'Number of periods',
                        schema => 'float*',
                    },
                },
                formulas => [
                    {
                        formula => 'fv = pv*(1+r)**n',
                    },
                    {
                        formula => 'pv = fv/(1+r)**n',
                    },
                    {
                        formula => 'r = (fv/pv)**(1/n) - 1',
                    },
                    {
                        formula => 'n = log(fv/pv) / log(1+r)',
                    },
                ],
                prefix => 'calc_fv_',
            },
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub gen_funcs_from_formulas {
    my %args = @_;

    my @caller = caller();
    my $package = $args{package} // $caller[0];
    my $symbols = $args{symbols};

    my %res;
    for my $fmlspec (@{ $args{formulas} }) {
        my ($funcname, $src, $code, $meta);
        my $fmlparse = _parse_formula($fmlspec->{formula}, $symbols);
        $funcname = $fmlspec->{name} //
            _to_funcname(
                ($args{prefix} // '') .
                    $symbols->{ $fmlparse->{y_var} }{caption});
        $src  = "sub {\n";
        $src .= '    my %args = @_;'."\n";
        $src .= '    return '.$fmlparse->{perl_src}.";\n";
        $src .= "}\n";
        $code = eval $src;
        die "Error in generating code for $funcname: $@" if $@;
        my $meta_args = {};
        my $pos = 0;
        for my $var (@{ $fmlparse->{x_vars} }) {
            my $argspec = {
                summary => $symbols->{$var}{summary} //
                    $symbols->{$var}{caption},
                schema => $symbols->{$var}{schema},
                req => 1,
                pos => $pos++,
            };
            $meta_args->{$var} = $argspec;
        }
        $meta = {
            v => 1.1,
            summary => $fmlspec->{summary} //
                "Calculate ".$symbols->{ $fmlparse->{y_var} }{caption}." ($fmlparse->{y_var}) ".
                "from "._itemize(map { $symbols->{$_}{caption}." ($_)" }
                                 @{ $fmlparse->{x_vars} }),
            description => "Formula is:\n\n    $fmlspec->{formula}\n\n",
            args => $meta_args,
            result_naked => 1,
            (examples => $fmlspec->{examples}) x !!defined($fmlspec->{examples}),
        };
        if ($args{install} // 1) {
            no strict 'refs';
            no warnings;
            my $fqname = "$package\::$funcname";
            *{ $fqname } = $code;
            ${ "$package\::SPEC" }{$funcname} = $meta;
        }
        $res{$funcname} = {
            code => $code,
            meta => $meta,
            src  => $src,
        };
    }

    [200, "OK", \%res];
}

1;
# ABSTRACT: Generate functions from formulas

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Gen::FromFormulas - Generate functions from formulas

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::Gen::FromFormulas (from Perl distribution Perinci-Sub-Gen-FromFormulas), released on 2017-03-14.

=head1 FUNCTIONS


=head2 gen_funcs_from_formulas

Usage:

 gen_funcs_from_formulas(%args) -> [status, msg, result, meta]

Generate functions from formulas.

Examples:

=over

=item * Example #1:

 gen_funcs_from_formulas(
 formulas => [
                 { formula => "fv = pv*(1+r)**n" },
                 { formula => "pv = fv/(1+r)**n" },
                 { formula => "r = (fv/pv)**(1/n) - 1" },
                 { formula => "n = log(fv/pv) / log(1+r)" },
               ],
   symbols  => {
                 n  => {
                         summary => "Number of periods",
                         schema  => "float*",
                         caption => "periods",
                       },
                 r  => {
                         caption => "return rate",
                         summary => "Return rate (e.g. 0.06 or 6%)",
                         schema  => "float*",
                       },
                 fv => { schema => "float*", caption => "future value" },
                 pv => { schema => "float*", caption => "present value" },
               },
   prefix   => "calc_fv_"
 );

=back

This routine helps make creating function (and accompanying Rinci metadata) from
formula less tedious.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<formulas>* => I<array>

=item * B<install> => I<bool> (default: 1)

Whether to install generated functions (and metadata).

By default, generated functions will be installed to the specified (or caller's)
package, as well as its generated metadata into %SPEC. Set this argument to
false to skip installing.

=item * B<package> => I<str>

Generated function's package, e.g. `My::Package`.

This is needed mostly for installing the function. You usually don't need to
supply this if you set C<install> to false.

If not specified, caller's package will be used by default.

=item * B<symbols>* => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A hash of function names and function coderef and metadata (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Gen-FromFormulas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Gen-FromFormulas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Gen-FromFormulas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>

Other function generators: L<Perinci::Sub::Gen::AccessTable>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
