package Term::Form::ReadLine;

use warnings;
use strict;
use 5.10.0;

our $VERSION = '0.543';
use Exporter 'import';
our @EXPORT_OK = qw( read_line );

use parent qw( Term::Form );

use Carp       qw( croak );

use Term::Choose::ValidateOptions qw( validate_options );


my $Plugin;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Term::Choose::Win32;
        require Win32::Console::ANSI;
        $Plugin = 'Term::Choose::Win32';
    }
    else {
        require Term::Choose::Linux;
        $Plugin = 'Term::Choose::Linux';
    }
}


sub new {
    my $class = shift;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        my $caller = 'new';
        validate_options( _valid_options(), $opt, $caller );
        for my $key ( keys %$opt ) {
            $instance_defaults->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    my $self = bless $instance_defaults, $class;
    $self->{backup_instance_defaults} = { %$instance_defaults };
    $self->{plugin} = $Plugin->new();
    return $self;
}


sub _valid_options {
    return {
        codepage_mapping => '[ 0 1 ]',
        show_context     => '[ 0 1 ]',
        clear_screen     => '[ 0 1 2 ]',
        color            => '[ 0 1 2 ]',
        hide_cursor      => '[ 0 1 2 ]',       # hide_cursor == 2 # documentation
        no_echo          => '[ 0 1 2 ]',
        page             => '[ 0 1 2 ]',       # undocumented
        default          => 'Str',
        footer           => 'Str',             # undocumented
        info             => 'Str',
    };
}


sub _defaults {
    return {
        clear_screen       => 0,
        codepage_mapping   => 0,
        color              => 0,
        default            => '',
        footer             => '',
        hide_cursor        => 1,
        info               => '',
        no_echo            => 0,
        page               => 1,
        show_context       => 0,
    };
}


sub read_line {
    if ( ref $_[0] eq __PACKAGE__ ) {
        croak "\"read_line\" is a function. The method is called \"readline\"";
    }
    my $ob = __PACKAGE__->new();
    delete $ob->{backup_instance_defaults};
    return $ob->readline( @_ );
}



1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Term::Form::ReadLine - Read a line from STDIN.

=head1 VERSION

Version 0.543

=cut

=head1 SYNOPSIS

    # Object-oriented interface:

    use Term::Form::ReadLine;

    my $new = Term::Form::ReadLine->new();

    my $line = $new->readline( 'Prompt: ', { default => 'abc' } );

    # Functional interface:

    use Term::Form::ReadLine qw( read_line );

    my $line = read_line( 'Prompt: ', { default => 'abc' } );

=head1 DESCRIPTION

C<readline> reads a line from STDIN. As soon as C<Return> is pressed C<readline> returns the read string without the
newline character - so no C<chomp> is required.

The output is removed after leaving the method, so the user can decide what remains on the screen.

=head2 Keys

C<BackSpace> or C<Ctrl-H>: Delete the character behind the cursor.

C<Delete> or C<Ctrl-D>: Delete  the  character at point.

C<Ctrl-U>: Delete the text backward from the cursor to the beginning of the line.

C<Ctrl-K>: Delete the text from the cursor to the end of the line.

C<Right-Arrow> or C<Ctrl-F>: Move forward a character.

C<Left-Arrow> or C<Ctrl-B>: Move back a character.

C<Home> or C<Ctrl-A>: Move to the start of the line.

C<End> or C<Ctrl-E>: Move to the end of the line.

C<Up-Arrow> or C<Ctrl-R>: Move back 10 characters.

C<Down-Arrow> or C<Ctrl-S>: Move forward 10 characters.

C<Ctrl-X>: If the input puffer is not empty, the input puffer is cleared, else C<Ctrl-X> returns nothing (undef).

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::Form::ReadLine> object.

    my $new = Term::Form::ReadLine->new();

To set the different options it can be passed a reference to a hash as an optional argument.

=head2 readline

C<readline> reads a line from STDIN.

    $line = $new->readline( $prompt, \%options );

The fist argument is the prompt string.

The optional second argument is the default string (see option I<default>) if it is not a reference. If the second
argument is a hash-reference, the hash is used to set the different options. The keys/options are

=head3 clear_screen

If enabled, the screen is cleared before the output.

0 - clears from the current position to the end of screen

1 - clears the entire screen

2 - if I<show_context> is disabled, clears only the current (readline) row. If I<show_context> is enabled behaves like
I<clear_screen> where set to 0.

default: C<0>

=head3 codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose> but one can enable it by setting this option.

Setting this option to C<1> enables the codepage mapping offered by L<Win32::Console::ANSI>.

0 - disable automatic codepage mapping (default)

1 - keep automatic codepage mapping

default: C<0>

=head3 color

Enables the support for color and text formatting escape sequences for the prompt string and the I<info> text.

0 - off

1 - on

default: C<0>

=head3 default

Set a initial value of input.

=head3 hide_cursor

0 - disabled

1 - enabled

default: C<1>

=head3 info

Expects as is value a string. If set, the string is printed on top of the output of C<readline>.

=head3 no_echo

0 - the input is echoed on the screen.

1 - "C<*>" are displayed instead of the characters.

2 - no output is shown apart from the prompt string.

default: C<0>

=head3 show_context

Display the input that does not fit into the "readline" before or after the "readline".

0 - disable I<show_context>

1 - enable I<show_context>

default: C<0>

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.10.0 or greater.

=head2 Terminal

It is required a terminal which uses a monospaced font.

Unless the OS is MSWin32 the terminal has to understand ANSI escape sequences.

=head2 Encoding layer

It is required to use appropriate I/O encoding layers. If the encoding layer for STDIN doesn't match the terminal's
character set, C<readline> will break if a non ascii character is entered.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Form::ReadLine

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright 2022-2022 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
