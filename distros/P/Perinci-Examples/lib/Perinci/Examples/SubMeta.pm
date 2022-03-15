package Perinci::Examples::SubMeta;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.822'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Test argument submetadata',
    description => <<'_',

Argument submetadata is introduced in Rinci 1.1.55, mainly to support (complex)
form. With this, you can submit a complex form (one that has subforms) to a
function. The function will receive the form submission as a nested data
structure.

To add an argument submetadata, you specify a hash argument with a `meta`
property, or an array argument with `element_meta` property. The value of the
property is another Rinci function metadata.

_
};

$SPEC{register_student} = {
    v => 1.1,
    summary => 'Register a student to a class',
    description => <<'_',

This example function registers a student to a class. You specify the student's
name, gender, and age, as well as the desired class to register to. You can only
register one student at a time.

Actually, this function just returns its arguments.

_
    args => {
        class => {
            summary => 'Desired class',
            schema => ['str*', in=>[
                'Cooking 101', 'Auto A', 'Auto B', 'Sewing', 'Singing',
                'Advanced Singing']],
        },
        student => {
            schema => 'hash*',
            meta => {
                v => 1.1,
                args => {
                    name => {
                        schema=>'str*',
                        req=>1,
                        pos=>0,
                    },
                    gender => {
                        schema=>['str*', in=>[qw/M F/]],
                        req=>1,
                    },
                    age => {
                        schema=>['int*', min=>4, max=>200],
                    },
                },
            },
            tags => ['student'],
        },
        note => {
            schema=>'str*',
            req=>1,
        },
    },
};
sub register_student {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

$SPEC{register_donors} = {
    v => 1.1,
    summary => 'Register donor(s)',
    description => <<'_',

This example function registers one or more blood donors. For each donor, you
need to specify at least the name, gender, age, and blood type.

In the command-line, you can specify them as follow:

    % register-donors --date 2014-10-11 \
        --donor-name Ujang --donor-age 31 --donor-male --donor-t A \
        --donor-name Ita   --donor-age 25 --donor-F    --donor-t O \
          --donor-note Tentative \
        --donor-name Eep   --donor-age 37 --donor-male --donor-t B

Actually, this function just returns its arguments. This function demonstrates
argument element submetadata.

_
    args => {
        date => {
            summary => 'Planned donation date',
            schema => ['date*'],
            req => 1,
        },
        donor => {
            schema => ['array*', min_len=>1],
            req => 1,
            element_meta => {
                v => 1.1,
                args => {
                    name => {
                        schema=>'str*',
                        req=>1,
                        pos=>0,
                    },
                    gender => {
                        schema=>['str*', in=>[qw/M F/]],
                        req=>1,
                        pos=>1,
                        cmdline_aliases=>{
                            M      => {is_flag=>1, code=>sub { $_[0]{gender} = 'M'}},
                            male   => {is_flag=>1, code=>sub { $_[0]{gender} = 'M'}},
                            F      => {is_flag=>1, code=>sub { $_[0]{gender} = 'F'}},
                            female => {is_flag=>1, code=>sub { $_[0]{gender} = 'F'}},
                        },
                    },
                    age => {
                        schema=>['int*', min=>17, max=>65],
                        req=>1,
                        pos=>2,
                        cmdline_aliases=>{a=>{}},
                    },
                    blood_type => {
                        schema=>['str*', in=>[qw/A B O AB/]],
                        req=>1,
                        pos=>3,
                        cmdline_aliases=>{t=>{}},
                    },
                    note => {
                        schema=>'str*',
                        req=>1,
                    },
                },
            },
            tags => ['Donor data'],
        },
    },
};
sub register_donors {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

1;
# ABSTRACT: Test argument submetadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::SubMeta - Test argument submetadata

=head1 VERSION

This document describes version 0.822 of Perinci::Examples::SubMeta (from Perl distribution Perinci-Examples), released on 2022-03-08.

=head1 DESCRIPTION


Argument submetadata is introduced in Rinci 1.1.55, mainly to support (complex)
form. With this, you can submit a complex form (one that has subforms) to a
function. The function will receive the form submission as a nested data
structure.

To add an argument submetadata, you specify a hash argument with a C<meta>
property, or an array argument with C<element_meta> property. The value of the
property is another Rinci function metadata.

=head1 FUNCTIONS


=head2 register_donors

Usage:

 register_donors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Register donor(s).

This example function registers one or more blood donors. For each donor, you
need to specify at least the name, gender, age, and blood type.

In the command-line, you can specify them as follow:

 % register-donors --date 2014-10-11 \
     --donor-name Ujang --donor-age 31 --donor-male --donor-t A \
     --donor-name Ita   --donor-age 25 --donor-F    --donor-t O \
       --donor-note Tentative \
     --donor-name Eep   --donor-age 37 --donor-male --donor-t B

Actually, this function just returns its arguments. This function demonstrates
argument element submetadata.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

Planned donation date.

=item * B<donor>* => I<array>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 register_student

Usage:

 register_student(%args) -> [$status_code, $reason, $payload, \%result_meta]

Register a student to a class.

This example function registers a student to a class. You specify the student's
name, gender, and age, as well as the desired class to register to. You can only
register one student at a time.

Actually, this function just returns its arguments.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<str>

Desired class.

=item * B<note>* => I<str>

=item * B<student> => I<hash>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
