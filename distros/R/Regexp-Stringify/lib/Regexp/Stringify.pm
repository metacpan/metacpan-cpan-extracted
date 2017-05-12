package Regexp::Stringify;

our $DATE = '2016-10-29'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use re qw(regexp_pattern);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(stringify_regexp);

our %SPEC;

$SPEC{stringify_regexp} = {
    v => 1.1,
    summary => 'Stringify a Regexp object',
    description => <<'_',

This routine is an alternative to Perl's default stringification of Regexp
object (i.e.:`"$re"`) and has some features/options, e.g.: producing regexp
string that is compatible with certain perl versions.

If given a string (or other non-Regexp object), will return it as-is.

_
    args => {
        regexp => {
            schema => 're*',
            req => 1,
            pos => 0,
        },
        plver => {
            summary => 'Target perl version',
            schema => 'str*',
            description => <<'_',

Try to produce a regexp object compatible with a certain perl version (should at
least be >= 5.10).

For example, in perl 5.14 regex stringification changes, e.g. `qr/hlagh/i` would
previously be stringified as `(?i-xsm:hlagh)`, but now it's stringified as
`(?^i:hlagh)`. If you set `plver` to 5.10 or 5.12, then this routine will
still produce the former. It will also ignore regexp modifiers that are
introduced in newer perls.

Note that not all regexp objects are translatable to older perls, e.g. if they
contain constructs not known to older perls like `(?^...)` before perl 5.14.

_
        },
        with_qr => {
            schema  => 'bool',
            description => <<'_',

If you set this to 1, then `qr/a/i` will be stringified as `'qr/a/i'` instead as
`'(?^i:a)'`. The resulting string can then be eval-ed to recreate the Regexp
object.

_
        },
    },
    result_naked => 1,
    result => {
        schema => 'str*',
    },
};
sub stringify_regexp {
    my %args = @_;

    my $re = $args{regexp};
    return $re unless ref($re) eq 'Regexp';
    my $plver = $args{plver} // $^V;

    my ($pat, $mod) = regexp_pattern($re);

    my $ge_5140 = version->parse($plver) >= version->parse('5.14.0');
    unless ($ge_5140) {
        $mod =~ s/[adlu]//g;
    }

    if ($args{with_qr}) {
        return "qr($pat)$mod";
    } else {
        if ($ge_5140) {
            return "(^$mod:$pat)";
        } else {
            return "(?:(?$mod-)$pat)";
        }
    }
}

1;
# ABSTRACT: Stringify a Regexp object

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Stringify - Stringify a Regexp object

=head1 VERSION

This document describes version 0.06 of Regexp::Stringify (from Perl distribution Regexp-Stringify), released on 2016-10-29.

=head1 SYNOPSIS

Assuming this runs on Perl 5.14 or newer.

 use Regexp::Stringify qw(stringify_regexp);
 $str = stringify_regexp(regexp=>qr/a/i);                       # '(^i:a)'
 $str = stringify_regexp(regexp=>qr/a/i, with_qr=>1);           # 'qr(a)i'
 $str = stringify_regexp(regexp=>qr/a/i, plver=>5.010);         # '(?:(?i-)a)'
 $str = stringify_regexp(regexp=>qr/a/ui, plver=>5.010);        # '(?:(?i-)a)'

=head1 FUNCTIONS


=head2 stringify_regexp(%args) -> str

Stringify a Regexp object.

This routine is an alternative to Perl's default stringification of Regexp
object (i.e.:C<"$re">) and has some features/options, e.g.: producing regexp
string that is compatible with certain perl versions.

If given a string (or other non-Regexp object), will return it as-is.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<plver> => I<str>

Target perl version.

Try to produce a regexp object compatible with a certain perl version (should at
least be >= 5.10).

For example, in perl 5.14 regex stringification changes, e.g. C<qr/hlagh/i> would
previously be stringified as C<(?i-xsm:hlagh)>, but now it's stringified as
C<(?^i:hlagh)>. If you set C<plver> to 5.10 or 5.12, then this routine will
still produce the former. It will also ignore regexp modifiers that are
introduced in newer perls.

Note that not all regexp objects are translatable to older perls, e.g. if they
contain constructs not known to older perls like C<(?^...)> before perl 5.14.

=item * B<regexp>* => I<re>

=item * B<with_qr> => I<bool>

If you set this to 1, then C<qr/a/i> will be stringified as C<'qr/a/i'> instead as
C<'(?^i:a)'>. The resulting string can then be eval-ed to recreate the Regexp
object.

=back

Return value:  (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Stringify>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Stringify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Stringify>

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
