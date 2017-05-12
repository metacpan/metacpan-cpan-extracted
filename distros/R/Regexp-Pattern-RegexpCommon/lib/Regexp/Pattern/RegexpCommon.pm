package Regexp::Pattern::RegexpCommon;

our $DATE = '2016-12-31'; # DATE
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;

our %RE = (
    pattern => {
        summary => 'Retrieve pattern from Regexp::Common',
        gen_args => {
            pattern => {
                schema => ['array*', of=>'str*'],
                req => 1,
            },
        },
        gen => sub {
            my %args = @_;

            my $pat = $args{pattern};
            require Regexp::Common;
            Regexp::Common->import;
            my $RE = \%{ __PACKAGE__ . "::RE" };
            my @pat = @$pat;
            my $res = $RE;
            while (@pat) {
                if ($pat[0] =~ /^-/) {
                    $res = $res->{ $pat[0] => $pat[1] };
                    shift @pat;
                    shift @pat;
                } else {
                    $res = $res->{ $pat[0] };
                    shift @pat;
                }
            }
            qr/$res/;
        },
    },
);

1;
# ABSTRACT: Regexps from Regexp::Common

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::RegexpCommon - Regexps from Regexp::Common

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::RegexpCommon (from Perl distribution Regexp-Pattern-RegexpCommon), released on 2016-12-31.

=head1 SYNOPSIS

 use Regexp::Pattern;

 my $re = re('RegexpCommon::pattern', pattern => ['num', 'real']);

=head1 DESCRIPTION

This is a bridge module between L<Regexp::Common> and L<Regexp::Pattern>. It
allows you to use Regexp::Common regexps from Regexp::Pattern. Apart from being
a proof of concept, normally this module should not be of any practical use.

=head1 PATTERNS

=over

=item * pattern

Retrieve pattern from Regexp::Common.

This is a dynamic pattern which will be generated on-demand.

The following arguments are available to customize the generated pattern:

=over

=item * pattern

=back



=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-RegexpCommon>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-RegexpCommon>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-RegexpCommon>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Common::RegexpPattern>, the counterpart.

L<Regexp::Common>

L<Regexp::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
