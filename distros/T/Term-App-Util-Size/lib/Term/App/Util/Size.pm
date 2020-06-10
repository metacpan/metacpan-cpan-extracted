package Term::App::Util::Size;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-10'; # DATE
our $DIST = 'Term-App-Util-Size'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Determine the sane terminal size (width, height)',
};

my $termw_cache;
my $termh_cache;
sub _get_size_from_Term_Size {
    my $self = shift;

    if (defined $termw_cache) {
        return ($termw_cache, $termh_cache);
    }

    ($termw_cache, $termh_cache) = (0, 0);
    if (eval { require Term::Size; 1 }) {
        ($termw_cache, $termh_cache) = Term::Size::chars(*STDOUT{IO});
    }
    ($termw_cache, $termh_cache);
}

$SPEC{term_width} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine the sane terminal width.

First will observe the COLUMNS environment variable, and use it if defined. Note
that in a Unix shell like bash, COLUMNS and LINES are shell variables and not
environment variables, so they are not inherited by child processes. You usually
set the COLUMNS environment variable when you want to override the terminal
width.

Then, if COLUMNS is not defined, will try to use Perl module <pm:Term::Size> to
determine the terminal size and use the result if succeed.

Third, if the Perl module is not available, will run "tput cols" and use the
output returned by tput if succeed.

Otherwise will use the default value of 80 (79 on Windows; the default command
prompt window is 80x25 but printing one character on rightmost column will cause
the cursor to move to the next line, so we choose 80-1).

_
};
sub term_width {
    my $res = [200, "OK", undef, {}];

    if ($ENV{COLUMNS}) {
        $res->[2] = $ENV{COLUMNS};
        $res->[3]{'func.debug_info'}{term_width_from} = 'COLUMNS env';
        goto RETURN_RES;
    }

    my ($termw, undef) = _get_size_from_Term_Size();
    if ($termw) {
        $res->[2] = $termw;
        $res->[3]{'func.debug_info'}{term_width_from} = 'Term::Size';
        goto RETURN_RES;
    }

    my $tputw = `tput cols`;
    if (!$? && $tputw =~ /\A(\d+)\R?\z/) {
        $res->[2] = $1;
        $res->[3]{'func.debug_info'}{term_width_from} = 'tput cols';
        goto RETURN_RES;
    }

    $res->[2] = $^O =~ /Win/ ? 79 : 80;
    $res->[3]{'func.debug_info'}{term_width_from} = 'default';

  RETURN_RES:
    $res;
}

$SPEC{term_height} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine the sane terminal height.

First will observe the LINES environment variable, and use it if defined. Note
that in a Unix shell like bash, COLUMNS and LINES are shell variables and not
environment variables, so they are not inherited by child processes. You usually
set the LINES environment variable when you want to override the terminal
height.

Then, if LINES is not defined, will try to use the Perl module <pm:Term::Size>
to determine the terminal size and use the result if succeed.

Third, if the Perl module is not available, will run "tput lines" and use the
output returned by tput if succeed.

Otherwise will use the default value of 25.

_
};
sub term_height {
    my $res = [200, "OK", undef, {}];

    if ($ENV{LINES}) {
        $res->[2] = $ENV{LINES};
        $res->[3]{'func.debug_info'}{term_height_from} = 'LINES env';
        goto RETURN_RES;
    }

    my (undef, $termh) = _get_size_from_Term_Size();
    if ($termh) {
        $res->[2] = $termh;
        $res->[3]{'func.debug_info'}{term_height_from} = 'Term::Size';
        goto RETURN_RES;
    }

    my $tputw = `tput lines`;
    if (!$? && $tputw =~ /\A(\d+)\R?\z/) {
        $res->[2] = $1;
        $res->[3]{'func.debug_info'}{term_width_from} = 'tput lines';
        goto RETURN_RES;
    }

    $res->[2] = 25; # sane default
    $res->[3]{'func.debug_info'}{term_height_from} = 'default';

  RETURN_RES:
    $res;
}

1;
# ABSTRACT: Determine the sane terminal size (width, height)

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::App::Util::Size - Determine the sane terminal size (width, height)

=head1 VERSION

This document describes version 0.002 of Term::App::Util::Size (from Perl distribution Term-App-Util-Size), released on 2020-06-10.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 term_height

Usage:

 term_height() -> [status, msg, payload, meta]

Try to determine the sane terminal height.

First will observe the LINES environment variable, and use it if defined. Note
that in a Unix shell like bash, COLUMNS and LINES are shell variables and not
environment variables, so they are not inherited by child processes. You usually
set the LINES environment variable when you want to override the terminal
height.

Then, if LINES is not defined, will try to use the Perl module L<Term::Size>
to determine the terminal size and use the result if succeed.

Third, if the Perl module is not available, will run "tput lines" and use the
output returned by tput if succeed.

Otherwise will use the default value of 25.

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



=head2 term_width

Usage:

 term_width() -> [status, msg, payload, meta]

Try to determine the sane terminal width.

First will observe the COLUMNS environment variable, and use it if defined. Note
that in a Unix shell like bash, COLUMNS and LINES are shell variables and not
environment variables, so they are not inherited by child processes. You usually
set the COLUMNS environment variable when you want to override the terminal
width.

Then, if COLUMNS is not defined, will try to use Perl module L<Term::Size> to
determine the terminal size and use the result if succeed.

Third, if the Perl module is not available, will run "tput cols" and use the
output returned by tput if succeed.

Otherwise will use the default value of 80 (79 on Windows; the default command
prompt window is 80x25 but printing one character on rightmost column will cause
the cursor to move to the next line, so we choose 80-1).

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

=head2 COLUMNS

=head2 LINES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-App-Util-Size>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-App-Util-Size>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-App-Util-Size>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Term::App::Util::*> modules.

L<Term::Size>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
