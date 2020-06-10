package Term::App::Role::Attrs;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-08'; # DATE
our $DIST = 'Term-App-Roles'; # DIST
our $VERSION = '0.031'; # VERSION

use 5.010001;
use Moo::Role;

# temporary
my $dt_cache;
sub detect_terminal {
    my $self = shift;

    if (!$dt_cache) {
        require Term::Detect::Software;
        $dt_cache = Term::Detect::Software::detect_terminal_cached();
        #use Data::Dump; dd $dt_cache;
    }
    $dt_cache;
}

has interactive => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Term::App::Util::Interactive;

        my $self = shift;

        my $res = Term::App::Util::Interactive::term_app_is_interactive();
        $self->{_termattr_debug_info} //= {};
        $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
            for keys %{ $res->[3]{'func.debug_info'} };
        $res->[2];
    },
);

has use_color => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Term::App::Util::Color;

        my $self = shift;

        my $res = Term::App::Util::Color::term_app_should_use_color();
        $self->{_termattr_debug_info} //= {};
        $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
            for keys %{ $res->[3]{'func.debug_info'} };
        $res->[2];
    },
    trigger => sub {
        require Term::App::Util::Color;

        my ($self, $val) = @_;
        return if !defined($val) || $val =~ /\A(|1|0)\z/;
        my $pval = Term::App::Util::Color::__parse_color_depth($val);
        $self->{color_depth} = $pval if defined $pval;
    },
);

has color_depth => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Term::App::Util::Color;

        my $self = shift;

        my $res = Term::App::Util::Color::term_app_color_depth();
        $self->{_termattr_debug_info} //= {};
        $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
            for keys %{ $res->[3]{'func.debug_info'} };
        $res->[2];
    },
    trigger => sub {
        require Term::App::Util::Color;

        my ($self, $val) = @_;
        if (defined(my $pval = Term::App::Util::Color::__parse_color_depth($val))) {
            $self->{color_depth} = $val = $pval;
        }
        if ($val) {
            $self->{use_color} = 1;
        } else {
            $self->{use_color} = 0;
        }
    },
);

has use_box_chars => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        if (defined $ENV{BOX_CHARS}) {
            $self->{_termattr_debug_info}{use_box_chars_from} =
                'BOX_CHARS env';
            return $ENV{BOX_CHARS};
        } elsif (!$self->interactive) {
            # most pager including 'less -R' does not support interpreting
            # boxchar escape codes.
            $self->{_termattr_debug_info}{use_box_chars_from} =
                '(not) interactive';
            return 0;
        } elsif (defined(my $bc = $self->detect_terminal->{box_chars})) {
            $self->{_termattr_debug_info}{use_box_chars_from} =
                'detect_terminal';
            return $bc;
        } else {
            $self->{_termattr_debug_info}{use_box_chars_from} =
                'hardcoded default';
            return 0;
        }
    },
);

has use_utf8 => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        if (defined $ENV{UTF8}) {
            $self->{_termattr_debug_info}{use_utf8_from} =
                'UTF8 env';
            return $ENV{UTF8};
        } elsif (defined(my $termuni = $self->detect_terminal->{unicode})) {
            $self->{_termattr_debug_info}{use_utf8_from} =
                'detect_terminal + LANG/LANGUAGE env must include "utf8"';
            return $termuni &&
                (($ENV{LANG} || $ENV{LANGUAGE} || "") =~ /utf-?8/i ? 1:0);
        } else {
            $self->{_termattr_debug_info}{use_utf8_from} =
                'hardcoded default';
            return 0;
        }
    },
);

has _termattr_debug_info => (is => 'rw', default=>sub{ {} });

has term_width => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Term::App::Util::Size;

        my $self = shift;

        my $res = Term::App::Util::Size::term_width();
        $self->{_termattr_debug_info} //= {};
        $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
            for keys %{ $res->[3]{'func.debug_info'} };
        $res->[2];
    },
);

has term_height => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Term::App::Util::Size;

        my $self = shift;

        my $res = Term::App::Util::Size::term_height();
        $self->{_termattr_debug_info} //= {};
        $self->{_termattr_debug_info}{$_} = $res->[3]{'func.debug_info'}{$_}
            for keys %{ $res->[3]{'func.debug_info'} };
        $res->[2];
    },
);

1;
# ABSTRACT: Role for terminal-related attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::App::Role::Attrs - Role for terminal-related attributes

=head1 VERSION

This document describes version 0.031 of Term::App::Role::Attrs (from Perl distribution Term-App-Roles), released on 2020-06-08.

=head1 DESCRIPTION

This role gives several options to turn on/off terminal-oriented features like
whether to use UTF8 characters, whether to use colors, and color depth. Defaults
are set from environment variables or by detecting terminal
software/capabilities.

=head1 ATTRIBUTES

=head2 use_utf8 => BOOL (default: from env, or detected from terminal)

The default is retrieved from environment: if C<UTF8> is set, it is used.
Otherwise, the default is on if terminal emulator software supports Unicode
I<and> language (LANG/LANGUAGE) setting has /utf-?8/i in it.

=head2 use_box_chars => BOOL (default: from env, or detected from OS)

Default is 0 for Windows.

=head2 interactive => BOOL (default: from env, or detected from terminal)

=head2 use_color => BOOL (default: from env, or detected from terminal)

For convenience, this attribute is "linked" with C<color_depth>. Setting
C<use_color> will also set C<color_depth> when the value is not ''/1/0 and
matches color depth pattern. For example, setting C<use_color> to 256 or '8bit'
will also set C<color_depth> to 256.

=head2 color_depth => INT (or STR, default: from env, or detected from terminal)

Get/set color depth. When setting, you can use string like '8 bit' or '24b' and
it will be converted to 256 (2**8) or 16777216 (2**24).

For convenience, this attribute is "linked" with C<use_color>. Setting
C<color_depth> to non-zero value will enable C<use_color>, while setting it to 0
will disable C<use_color>.

=head2 term_width => INT (default: from env, or detected from terminal)

=head2 term_height => INT (default: from env, or detected from terminal)

=head1 METHODS

=head2 detect_terminal() => HASH

Call L<Term::Detect::Software>'s C<detect_terminal_cached>.

=head1 ENVIRONMENT

=over

=item * UTF8 => BOOL

Can be used to set C<use_utf8>.

=item * INTERACTIVE => BOOL

Can be used to set C<interactive>.

=item * NO_COLOR

Can be used to disable color. Takes precedence over C<COLOR>.

For more information, see L<https://no-color.org>.

=item * COLOR => BOOL (or INT or STR)

Can be used to set C<use_color>. Can also be used to set C<color_depth> (if
C<COLOR_DEPTH> is not defined).

=item * COLOR_DEPTH => INT (or STR)

Can be used to set C<color_depth>. Can also be used to enable/disable
C<use_color>.

=item * BOX_CHARS => BOOL

Can be used to set C<use_box_chars>.

=item * COLUMNS => INT

Can be used to set C<term_width>.

=item * LINES => INT

Can be used to set C<term_height>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-App-Roles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-App-Roles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-App-Roles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
