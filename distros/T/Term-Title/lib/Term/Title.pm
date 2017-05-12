package Term::Title;
use strict;
use warnings;
# ABSTRACT: Portable API to set the terminal titlebar
our $VERSION = '0.08'; # VERSION

use Exporter;
our @ISA       = 'Exporter';
our @EXPORT_OK = qw/set_titlebar set_tab_title/;

# encodings by terminal type -- except for mswin32 get matched as regex
# against $ENV{TERM}
# code ref gets title and text to print
my %terminal = (
    'xterm|rxvt' => {
        pre  => "\033]2;",
        post => "\007",
    },
    'screen' => {
        pre  => "\ek",
        post => "\e\\",
    },
    'mswin32' => sub {
        my ( $title, @optional ) = @_;
        my $c = Win32::Console->new();
        $c->Title($title);
        print STDOUT @optional, "\n";
    },
);

my %terminal_tabs = (
    'iterm2' => {
        is_supported => sub {
            $ENV{TERM_PROGRAM} and $ENV{TERM_PROGRAM} eq 'iTerm.app';
        },
        pre  => "\033]1;",
        post => "\007",
    },
);

sub _set {
    my ( $type_cb, $types, $title, @optional ) = @_;
    $title = q{ } unless defined $title;
    my $type = $type_cb->();

    if ($type) {
        if ( ref $types->{$type} eq 'CODE' ) {
            $types->{$type}->( $title, @optional );
        }
        elsif ( ref $types->{$type} eq 'HASH' ) {
            print STDOUT $types->{$type}{pre}, $title, $types->{$type}{post}, @optional, "\n";
        }
    }
    elsif (@optional) {
        print STDOUT @optional, "\n";
    }
    return;
}

sub set_titlebar { _set( \&_is_supported, \%terminal, @_ ) }

sub set_tab_title { _set( \&_is_supported_tabs, \%terminal_tabs, @_ ) }

sub _is_supported {
    if ( lc($^O) eq 'mswin32' ) {
        return 'mswin32' if eval { require Win32::Console };
    }
    else {
        return unless $ENV{TERM};
        for my $k ( keys %terminal ) {
            return $k if $ENV{TERM} =~ /^(?:$k)/;
        }
    }
    return;
}

sub _is_supported_tabs {
    for my $k ( keys %terminal_tabs ) {
        return $k if $terminal_tabs{$k}{is_supported}->();
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Title - Portable API to set the terminal titlebar

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Term::Title 'set_titlebar', 'set_tab_title';

    set_titlebar("This goes into the title");

    set_titlebar("Title", "And also print this to the terminal");

    set_tab_title("This goes into the tab title");

    set_tab_title("Tab Title", "And also print this to the terminal");

=head1 DESCRIPTION

Term::Title provides an abstraction for setting the titlebar or the tab title
across different types of terminals.  For *nix terminals, it prints the
appropriate escape sequences to set the terminal or tab title based on the
value of C<$ENV{TERM}>.  On Windows, it uses L<Win32::Console> to set the
title directly.

Currently, changing the titlebar is supported in these terminals:

=over 4

=item *

xterm

=item *

rxvt

=item *

screen

=item *

iTerm2.app

=item *

Win32 console

=back

The terminals that support changing the tab title include:

=over 4

=item *

iTerm2.app

=back

=head1 USAGE

=head2 set_titlebar

    set_titlebar( $title, @optional_text );

Sets the titlebar to C<$title> or clears the titlebar if C<$title> is 
undefined.   

On terminals that require printing escape codes to the terminal, a newline
character is also printed to the terminal.  If C< @optional_text > is given, it
will be printed to the terminal prior to the newline.  Thus, to keep terminal
output cleaner, use C<set_titlebar()> in place of a C<print()> statement to
set the titlebar and print at the same time.

If the terminal is not supported, set_titlebar silently continues, printing
C<@optional_text> if any.

=head2 set_tab_title

    set_tab_title( $title, @optional_text );

Has the exact same semantics as the L</set_titlebar> but changes the tab title.

=head1 SEE ALSO

=over 4

=item *

L<Win32::Console>

=item *

L<http://www.ibiblio.org/pub/Linux/docs/HOWTO/Xterm-Title>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Term-Title/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Term-Title>

  git clone https://github.com/dagolden/Term-Title.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Pedro Melo <melo@simplicidade.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
