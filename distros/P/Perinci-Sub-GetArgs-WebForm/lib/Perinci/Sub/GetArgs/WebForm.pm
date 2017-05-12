package Perinci::Sub::GetArgs::WebForm;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_webform);

our %SPEC;

$SPEC{get_args_from_webform} = {
    v => 1.1,
    summary => 'Get subroutine arguments (%args) from web form',
    args => {
        form => {
            schema => 'hash*',
            req => 1,
            pos => 0,
            description => <<'_',

Either from `Plack::Request`'s `query_parameters()` or `CGI`'s `Vars()`.

_
        },
        meta => {
            schema => ['hash*' => {}],
            description => <<'_',

Actually not required and not currently used.

_
        },
        meta_is_normalized => {
            summary => 'Can be set to 1 if your metadata is normalized, '.
                'to avoid duplicate effort',
            schema => 'bool',
            default => 0,
        },
    },
    # for performance
    args_as => 'array',
    result_naked => 1,
};
sub get_args_from_webform {
    my $form = shift;

    my $args = {};
    for (keys %$form) {
        if (m!/!) {
            my @p = split m!/!, $_;
            next if @p > 10; # hardcode limit
            my $a0 = $args;
            for my $i (0..@p-2) {
                $a0->{$p[$i]} //= {};
                $a0 = $a0->{$p[$i]};
            }
            $a0->{$p[-1]} = $form->{$_};
        } else {
            $args->{$_} = $form->{$_};
        }
    }
    $args;
}

1;
# ABSTRACT: Get subroutine arguments (%args) from web form

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::GetArgs::WebForm - Get subroutine arguments (%args) from web form

=head1 VERSION

This document describes version 0.02 of Perinci::Sub::GetArgs::WebForm (from Perl distribution Perinci-Sub-GetArgs-WebForm), released on 2015-09-04.

=head1 SYNOPSIS

 use Perinci::Sub::GetArgs::WebForm qw(get_args_from_webform);

 my %params = $query->params; # from CGI, or from Plack::Request
 my $args = get_args_from_webform(\%params);

=head1 DESCRIPTION

This module provides get_args_from_webform(). This module is used by, among
others, L<Borang>.

=head1 FUNCTIONS


=head2 get_args_from_webform($form, $meta, $meta_is_normalized) -> any

Get subroutine arguments (%args) from web form.

Arguments ('*' denotes required arguments):

=over 4

=item * B<form>* => I<hash>

Either from C<Plack::Request>'s C<query_parameters()> or C<CGI>'s C<Vars()>.

=item * B<meta> => I<hash>

Actually not required and not currently used.

=item * B<meta_is_normalized> => I<bool> (default: 0)

Can be set to 1 if your metadata is normalized, to avoid duplicate effort.

=back

Return value:  (any)

=head1 SEE ALSO

L<Perinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-GetArgs-WebForm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-GetArgs-WebForm>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-GetArgs-WebForm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
