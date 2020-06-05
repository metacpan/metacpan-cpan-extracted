package Role::TinyCommons::TermAttr::Color;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-05'; # DATE
our $DIST = 'Role-TinyCommons-TermAttr-Color'; # DIST
our $VERSION = '0.001'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::TermAttr::Software';
with 'Role::TinyCommons::TermAttr::Interactive';

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

sub termattr_use_color {
    my $self = shift;
    if (exists $ENV{NO_COLOR}) {
        $self->{_termattr_debug_info}{use_color_from} = 'NO_COLOR env';
        return 0;
    } elsif (defined $ENV{COLOR}) {
        $self->{_termattr_debug_info}{use_color_from} = 'COLOR env';
        return $ENV{COLOR};
    } elsif (defined $ENV{COLOR_DEPTH}) {
        $self->{_termattr_debug_info}{use_color_from} = 'COLOR_DEPTH env';
        my $val = __parse_color_depth($ENV{COLOR_DEPTH}) //
            $ENV{COLOR_DEPTH};
        return $val ? 1:0;
    } else {
        $self->{_termattr_debug_info}{use_color_from} =
            'interactive + color_deth';
        return $self->termattr_interactive && $self->termattr_color_depth > 0;
    }
}

sub termattr_color_depth {
    my $self = shift;
    my $pval;
    if (defined($ENV{COLOR_DEPTH}) &&
            defined($pval = __parse_color_depth($ENV{COLOR_DEPTH}))) {
        $self->{_termattr_debug_info}{color_depth_from} = 'COLOR_DEPTH env';
        return $pval;
    } elsif (defined($ENV{COLOR}) && $ENV{COLOR} !~ /^(|0|1)$/ &&
                 defined($pval = __parse_color_depth($ENV{COLOR}))) {
        $self->{_termattr_debug_info}{color_depth_from} = 'COLOR env';
        return $pval;
    } elsif (defined(my $cd = $self->termattr_software_info->{color_depth})) {
        $self->{_termattr_debug_info}{color_depth_from} = 'detect_terminal';
        return $cd;
    } else {
        $self->{_termattr_debug_info}{color_depth_from} = 'default';
        return 16;
    }
}

1;
# ABSTRACT: Determine color depth and whether to use color or not

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::TermAttr::Color - Determine color depth and whether to use color or not

=head1 VERSION

This document describes version 0.001 of Role::TinyCommons::TermAttr::Color (from Perl distribution Role-TinyCommons-TermAttr-Color), released on 2020-06-05.

=head1 DESCRIPTION

=head1 PROVIDED METHODS

=head2 termattr_use_color

Try to determine whether colors should be used. First will check NO_COLOR
environment variable: if it exists then we should not use colors. Then check the
COLOR environment variable: if it's false then color should not be used, if it's
true then color should be used. Then check the COLOR_DEPTH environment variable:
if it's true (not 0) then color should be used. Lastly check if running
interactively.

=head2 termattr_color_depth

Try to determine the terminal's color depth.

=head1 ENVIRONMENT

=head2 COLOR

=head2 COLOR_DEPTH

=head2 NO_COLOR

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-TermAttr-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TermAttr-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-TermAttr-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons>

L<Term::App::Role::Attrs>, an earlier project, L<Moo::Role>, and currently more
complete version.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
