package Perinci::Sub::Property::hide_args;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

our $VERSION = '0.03'; # VERSION

declare_property(
    name => 'hide_args',
    type => 'function',
    schema => ['array' => of => 'str*'],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 9, # before args
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;

            my $v    = $args{new} // $args{value};

            delete $self->{_meta}{args}{$_} for @$v;
        },
    },
);

1;
# ABSTRACT: Hide arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::hide_args - Hide arguments

=head1 VERSION

This document describes version 0.03 of Perinci::Sub::Property::hide_args (from Perl distribution Perinci-Sub-Property-hide_args), released on 2016-05-11.

=head1 SYNOPSIS

 # in function metadata
 hide_args => [qw/arg1 arg2/],

=head1 DESCRIPTION

This property can hide some arguments from function, so they are assumed to not
exist.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-hide_args>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-hide_args>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-hide_args>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
