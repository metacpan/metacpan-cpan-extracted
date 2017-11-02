package Term::ANSIColor::Conditional;

## no critic (Modules::ProhibitAutomaticExportation)

our $DATE = '2017-10-28'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
use Term::ANSIColor (); # XXX color() & colored() still imported?
no warnings 'redefine';


our $COLOR;

my @own_routines = qw(color colored);

BEGIN {
    my %done;

    our @EXPORT      = @Term::ANSIColor::EXPORT;
    our @EXPORT_OK   = @Term::ANSIColor::EXPORT_OK;
    our %EXPORT_TAGS = @Term::ANSIColor::EXPORT_TAGS;

    for my $sym (@EXPORT, @EXPORT_OK) {
        next if grep { $sym eq $_ } @own_routines;
        next if $done{$sym}++;
        *{$sym} = \&{"Term::ANSIColor::$sym"};
    }
    for my $tag (keys %EXPORT_TAGS) {
        for my $sym (@{ $EXPORT_TAGS{$tag} }) {
            next if grep { $sym eq $_ } @own_routines;
            next if $done{$sym}++;
            *{$sym} = \&{"Term::ANSIColor::$sym"};
        }
    }
}

sub _color_enabled {
    return $COLOR if defined $COLOR;
    return $ENV{COLOR} if defined $ENV{COLOR};
    return (-t STDOUT);
}

# provide our own color()
sub color {
    return "" unless _color_enabled();
    goto &Term::ANSIColor::color;
}

# provide our own colored()
sub colored {
    return $_[1] unless _color_enabled();
    goto &Term::ANSIColor::colored;
}

1;
# ABSTRACT: Colorize text only if color is enabled

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::ANSIColor::Conditional - Colorize text only if color is enabled

=head1 VERSION

This document describes version 0.001 of Term::ANSIColor::Conditional (from Perl distribution Term-ANSIColor-Conditional), released on 2017-10-28.

=head1 SYNOPSIS

Use as you would L<Term::ANSIColor>.

=head1 DESCRIPTION

This module is a wrapper for L<Term::ANSIColor>. If color is enabled then
everything is the same as Term::ANSIColor. If color is disabled, then C<color()>
will emit empty string and C<colored()> will not colorize input text.

How to determine "color is enabled":

=over

=item * If package variable C<$Term::ANSIColor::Conditional::COLOR> is defined, use that.

=item * Otherwise, check if C<COLOR> environment variable is defined and use that.

=item * Otherwise, check if (-t STDOUT) is true (interactive terminal). If yes, color is enabled.

=item * Otherwise, color is disabled.

=back

=for Pod::Coverage ^(.+)$

=head1 VARIABLES

=head2 $COLOR => bool

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-ANSIColor-Conditional>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-ANSIColor-Conditional>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-ANSIColor-Conditional>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::ANSIColor>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
