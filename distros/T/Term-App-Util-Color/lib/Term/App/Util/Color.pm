package Term::App::Util::Color;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-13'; # DATE
our $DIST = 'Term-App-Util-Color'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;

# return undef if fail to parse
sub __parse_color_depth {
    my $val = shift;
    if ($val =~ /\A\d+\z/) {
        return $val;
    } elsif ($val =~ /\A(\d+)[ _-]?(?:bit|b)\z/) {
        return 2**$val;
    } else {
        # IDEA: parse 'high color', 'true color'?
        return undef;
    }
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Determine color depth and whether to use color or not',
};

$SPEC{term_app_should_use_color} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine whether colors should be used. First will check NO_COLOR
environment variable and return false if it exists. Otherwise will check the
COLOR environment variable and use it if it's defined. Otherwise will check the
COLOR_DEPTH environment variable and if defined will use color when color depth
is > 0. Otherwise will check if script is running interactively and when it is
then will use color. Otherwise will not use color.

_
};
sub term_app_should_use_color {
    my $res = [200, "OK", undef, {}];

    if (exists $ENV{NO_COLOR}) {
        $res->[2] = 0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'NO_COLOR env';
        goto RETURN_RES;
    } elsif (defined $ENV{COLOR}) {
        $res->[2] = $ENV{COLOR};
        $res->[3]{'func.debug_info'}{use_color_from} = 'COLOR env';
    } elsif (defined $ENV{COLOR_DEPTH}) {
        my $val = __parse_color_depth($ENV{COLOR_DEPTH}) // $ENV{COLOR_DEPTH};
        $res->[2] = $val ? 1:0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'COLOR_DEPTH env';
        goto RETURN_RES;
    } else {
        require Term::App::Util::Interactive;
        my $interactive_res = Term::App::Util::Interactive::term_app_is_interactive();
        my $color_depth_res = term_app_color_depth();
        $res->[2] = $interactive_res->[2] && $color_depth_res->[2] > 0 ? 1:0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'interactive + color_deth > 0';
        goto RETURN_RES;
    }

  RETURN_RES:
    $res;
}

$SPEC{term_app_color_depth} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine the suitable color depth to use.

Will first check COLORTERM environment variable to see if its value is
`truecolor`; if yes then depth is 2**24 (24 bit).

Then will check COLOR_DEPTH environment variable and use that if defined.

Otherwise will check COLOR environment variable and use that as color depth if
defined and the value looks like color depth (e.g. `256` or `24bit`).

Otherwise will try to detect terminal emulation software and use the highest
supported color depth of that terminal software.

Otherwise will default to 16.

_

};
sub term_app_color_depth {
    my $res = [200, "OK", undef, {}];

    my $val;
    if (defined $ENV{COLORTERM} &&
            $ENV{COLOR_TERM} eq 'truecolor') {
        $res->[2] = 2**24;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'COLORTERM env';
    } elsif (defined($ENV{COLOR_DEPTH}) &&
            defined($val = __parse_color_depth($ENV{COLOR_DEPTH}))) {
        $res->[2] = $val;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'COLOR_DEPTH env';
        goto RETURN_RES;
    } elsif (defined($ENV{COLOR}) && $ENV{COLOR} !~ /^(|0|1)$/ &&
                 defined($val = __parse_color_depth($ENV{COLOR}))) {
        $res->[2] = $val;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'COLOR env';
        goto RETURN_RES;
    } elsif (defined(my $software_info = do {
        require Term::Detect::Software;
        Term::Detect::Software::detect_terminal_cached(); })) {
        $res->[2] = $software_info->{color_depth};
        $res->[3]{'func.debug_info'}{color_depth_from} = 'detect_terminal';
        goto RETURN_RES;
    } else {
        $res->[2] = 16;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'default';
        goto RETURN_RES;
    }

  RETURN_RES:
    $res;
}

1;
# ABSTRACT: Determine color depth and whether to use color or not

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::App::Util::Color - Determine color depth and whether to use color or not

=head1 VERSION

This document describes version 0.002 of Term::App::Util::Color (from Perl distribution Term-App-Util-Color), released on 2021-03-13.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 term_app_color_depth

Usage:

 term_app_color_depth() -> [status, msg, payload, meta]

Try to determine the suitable color depth to use.

Will first check COLORTERM environment variable to see if its value is
C<truecolor>; if yes then depth is 2**24 (24 bit).

Then will check COLOR_DEPTH environment variable and use that if defined.

Otherwise will check COLOR environment variable and use that as color depth if
defined and the value looks like color depth (e.g. C<256> or C<24bit>).

Otherwise will try to detect terminal emulation software and use the highest
supported color depth of that terminal software.

Otherwise will default to 16.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 term_app_should_use_color

Usage:

 term_app_should_use_color() -> [status, msg, payload, meta]

Try to determine whether colors should be used. First will check NO_COLOR
environment variable and return false if it exists. Otherwise will check the
COLOR environment variable and use it if it's defined. Otherwise will check the
COLOR_DEPTH environment variable and if defined will use color when color depth
is > 0. Otherwise will check if script is running interactively and when it is
then will use color. Otherwise will not use color.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 COLOR

=head2 COLOR_DEPTH

=head2 COLORTERM

=head2 NO_COLOR

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-App-Util-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-App-Util-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Term-App-Util-Color/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Term::App::Util::*> modules.

L<Term::Detect::Software>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
