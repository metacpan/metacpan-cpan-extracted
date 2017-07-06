package RPi::LCD;

use strict;
use warnings;

our $VERSION = '2.3603';

use parent 'WiringPi::API';
use Carp qw(confess);
use RPi::WiringPi::Constant qw(:all);

sub new {
    my $self = bless {}, shift;
    if (! defined $ENV{RPI_PIN_SCHEME}){
        $ENV{RPI_PIN_SCHEME} = RPI_MODE_GPIO;
        $self->setup_gpio;
    }
    return $self;
}
sub init {
    my ($self, %params) = @_;

    my @required_args = qw(
        rows cols bits rs strb
        d0 d1 d2 d3 d4 d5 d6 d7
    );
   
    for (@required_args){
        if (! defined $params{$_}) {
            die "\n'$_' is a required param for ::LCD::lcd_init()\n";
        }
    }

    my $fd = $self->lcd_init(%params);

    $self->_fd($fd);

    return $self->_fd();
}
sub home {
    $_[0]->lcd_home($_[0]->_fd);
}
sub clear {
    $_[0]->lcd_clear($_[0]->_fd);
}
sub display {
    my ($self, $state) = @_;
    $self->lcd_display($self->_fd, $state);
}
sub cursor {
    my ($self, $state) = @_;
    $self->lcd_cursor($self->_fd, $state);
}
sub cursor_blink {
    my ($self, $state) = @_;
    $self->lcd_cursor_blink($self->_fd, $state);
}
sub send_cmd {
    my ($self, $cmd) = @_;
    $self->lcd_send_cmd($self->_fd, $cmd);
}
sub position {
    my ($self, $x, $y) = @_;
    $self->lcd_position($self->_fd, $x, $y);
}
sub char_def {
    my ($self, $index, $data) = @_;
    $self->lcd_char_def($self->_fd, $index, $data);
}

*print_char = \&put_char;

sub put_char {
    my ($self, $data) = @_;
    $self->lcd_put_char($self->_fd, $data);
}

*print = \&puts;

sub puts {
    my ($self, $string) = @_;
    $self->lcd_puts($self->_fd, $string);
}
sub _fd {
    my ($self, $fd) = @_;
    if (defined $fd){
        if ($fd == -1){
            confess "\nMaximum number of LCDs (8) in use. Can't continue...\n" .
                    "Are you instantiating LCD objects within a loop?\n\n";
        }
        $self->{fd} = $fd;
    }
    return $self->{fd}
}
sub __placeholder {} # vim folds

1;
__END__

=head1 NAME

RPi::LCD - Perl interface to Raspberry Pi LCD displays via the GPIO
pins

=head1 SYNOPSIS

    use RPi::LCD;

    my $lcd = RPi::LCD->new;

    my %lcd_args = (
        rows  => 2,     # number of display rows, 2 or 4
        cols  => 16,    # number of display columns 16 or 20
        bits  => 4,     # data width in bits, 4 or 8
        rs    => 1,     # GPIO pin for the LCD RS pin
        strb  => 2,     # GPIO pin for the LCD strobe (E) pin
        d0    => 3,     #
        ...             # d0-d3 GPIO pinout numbers
        d3    => 6,     #
        d4    => 7,     # set d4-d7 to all 0 (zero) if in 4-bit mode
        ...             # otherwise, set them to their respective
        d7    => 11,    # GPIO pins
    );

    # initialize the LCD screen

    $lcd->init(%lcd_args);

    my $perl_ver = '5.24.0';
    my $name = 'stevieb';

    $lcd->home; # row 0, col 0

    $lcd->print("${name}'s RPi, on");

    $lcd->position(0, 1); # row 2

    $lcd->print("Perl $perl_ver...");

=head1 DESCRIPTION

This module acts as an interface to typical 2 or 4 row, 16 or 20 column LCD
screens when connected to a Raspberry Pi.

It is standalone code, but if you access an instance of this class through the
L<RPi::WiringPi> library, we'll ensure safe exit upon a crash.


=head1 METHODS

=head2 new()

Returns a new C<RPi::LCD> object. We check if any RPi::WiringPi setup routines
have been run, and if not, we set up in GPIO pin mode.

=head2 init(%args)

Initializes the LCD library, and returns an integer representing the handle
(file descriptor) of the device. The return is supposed to be constant,
so DON'T change it.

Parameters:

    %args = (
        rows => $num,       # number of rows. eg: 2 or 4
        cols => $num,       # number of columns. eg: 16 or 20
        bits => 4|8,        # width of the interface (4 or 8)
        rs => $pin_num,     # pin number of the LCD's RS pin
        strb => $pin_num,   # pin number of the LCD's strobe (E) pin
        d0 => $pin_num,     # pin number for LCD data pin 1
        ...
        d7 => $pin_num,     # pin number for LCD data pin 8
    );

Mandatory: All entries must have a value. If you're only using four (4) bit
width, C<d4> through C<d7> must be set to C<0>.

NOTE: In 4-bit mode, connect to pins C<d4> - C<d7> on the LCD. These pins act
as C<d0> - C<d3> when not in 8-bit mode.

=head2 home()

Moves the LCD cursor to the home position (top row, leftmost column).

=head2 clear()

Clears the LCD display of all data, and return the cursor to the home position.

=head2 display($state)

Turns the LCD display on and off.

Parameters:

    $state

Mandatory: C<0> to turn the display off, and C<1> for on.

=head2 cursor($state)

Turns the LCD cursor on and off.

Parameters:

    $state

Mandatory: C<0> to turn the cursor off, C<1> for on.

=head2 cursor_blink($state)

Parameters:

    $state

Mandatory: C<0> to stop blinking, C<1> to enable.

=head2 send_cmd($command)

Sends any arbitrary command to the LCD. (I've never tested this!).

Parameters:

    $command

Mandatory: A command to submit to the LCD.

=head2 position($x, $y)

Moves the cursor to the specified position on the LCD display.

Parameters:

    $x

Mandatory: Column position. C<0> is the left-most edge.

    $y

Mandatory: Row position. C<0> is the top row.

=head2 char_def($index, $data)

This allows you to re-define one of the 8 user-definable characters in the
display. The data array is 8 bytes which represent the character from the
top line to the bottom line. Note that the characters are actually 5 x 8, so
only the lower 5 bits are used. The index is from 0 to 7 and you can
subsequently print the character defined using the lcdPutchar() call.

Parameters:

    $index

Mandatory: Index of the display character. Values are C<0-7>.

    $data

Mandatory: See above description.

=head2 put_char($char)

Writes a single ASCII character to the LCD display, at the current cursor
position.

Parameters:

    $char

Mandatory: A single ASCII character.

=head2 print_char($char)

Alias of C<put_char()>.

=head2 puts($string)

Parameters:

    $string

Mandatory: A string to display.

=head2 print($string)

Alias of C<puts()>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
