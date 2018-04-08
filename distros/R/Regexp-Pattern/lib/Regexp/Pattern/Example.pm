package Regexp::Pattern::Example;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.2.3'; # VERSION

# BEGIN_BLOCK: def

our %RE = (
    # the minimum spec
    re1 => { pat => qr/\d{3}-\d{4}/ },

    # more complete spec
    re2 => {
        summary => 'This is regexp for blah',
        description => <<'_',

A longer description.

_
        pat => qr/.../,
        tags => ['A','B'],
    },

    # dynamic (regexp generator)
    re3 => {
        summary => 'This is a regexp for blah blah',
        description => <<'_',

...

_
        gen => sub {
            my %args = @_;
            my $variant = $args{variant} || 'A';
            if ($variant eq 'A') {
                return qr/\d{3}-\d{3}/;
            } else { # B
                return qr/\d{3}-\d{2}-\d{5}/;
            }
        },
        gen_args => {
            variant => {
                summary => 'Choose variant',
                schema => ['str*', in=>['A','B']],
                default => 'A',
                req => 1,
            },
        },
        tags => ['B','C'],
    },
);

# END_BLOCK: def

1;
# ABSTRACT: An example Regexp::Pattern::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Example - An example Regexp::Pattern::* module

=head1 VERSION

This document describes version 0.2.3 of Regexp::Pattern::Example (from Perl distribution Regexp-Pattern), released on 2018-04-03.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Example::re1");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * re1

=item * re2

This is regexp for blah.

A longer description.


=item * re3

This is a regexp for blah blah.

...


This is a dynamic pattern which will be generated on-demand.

The following arguments are available to customize the generated pattern:

=over

=item * variant

Choose variant.

=back



=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
