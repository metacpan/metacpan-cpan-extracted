package Perinci::Examples::Config;

our $DATE = '2018-01-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

# package metadata
$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples related to config files',
};

$SPEC{config_info} = {
    v => 1.1,
    summary => 'Show config file information',
    args => {
        arg_int1  => {schema=>'int*'},
        arg_int2  => {schema=>'int*'},
        arg_str1  => {schema=>'str*'},
        arg_str2  => {schema=>'str*'},
        arg_hash1 => {schema=>'hash*'},
    },
};
sub config_info {
    my %args = @_;

    my $cmdline = delete($args{-cmdline});

    my $r = delete($args{-cmdline_r})
        or return [412, "I am not passed -cmdline_r, please set ".
                   "Perinci::CmdLine's attribute: pass_cmdline_object"];

    [200, "OK", {
        args              => \%args,
        read_config       => $r->{read_config},
        read_config_files => $r->{read_config_files},
        config            => $r->{config},
        config_paths      => $r->{config_paths},
        config_profile    => $r->{config_profile},
    }];
}

1;
# ABSTRACT: Examples related to config files

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Config - Examples related to config files

=head1 VERSION

This document describes version 0.001 of Perinci::Examples::Config (from Perl distribution Perinci-Examples-Config), released on 2018-01-15.

=head1 FUNCTIONS


=head2 config_info

Usage:

 config_info(%args) -> [status, msg, result, meta]

Show config file information.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg_hash1> => I<hash>

=item * B<arg_int1> => I<int>

=item * B<arg_int2> => I<int>

=item * B<arg_str1> => I<str>

=item * B<arg_str2> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples-Config>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples-Config>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples-Config>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
