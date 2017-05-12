
use strict;
use warnings;

package PortageXS::Colors;
BEGIN {
  $PortageXS::Colors::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::Colors::VERSION = '0.3.1';
}

# ABSTRACT: Colour formatting / translation for Gentoo

use Moo 1.000008;


my %colors;

sub _has_color {
    my ( $name, $colorname ) = @_;
    has(
        'color_' . $name,
        is      => rwp =>,
        lazy    => 1,
        builder => sub {
            require Term::ANSIColor;
            Term::ANSIColor::color($colorname);
        }
    );
    $colors{$name} = $colorname;
}
my %task_colors;

sub _has_task_color {
    my ( $name, $colorname ) = @_;
    has(
        'task_color_' . $name,
        is      => rwp =>,
        lazy    => 1,
        builder => sub { $colorname }
    );
    $task_colors{$name} = $colorname;
}


_has_color YELLOW     => 'bold yellow';
_has_color GREEN      => 'green';
_has_color LIGHTGREEN => 'bold green';


_has_color WHITE => 'bold white';
_has_color CYAN  => 'bold cyan';
_has_color RED   => 'bold red';


_has_color BLUE  => 'bold blue';
_has_color RESET => 'reset';


_has_task_color ok   => LIGHTGREEN =>;
_has_task_color err  => RED        =>;
_has_task_color info => YELLOW     =>;


sub getColor {
    my ( $self, $color ) = @_;
    if ( not exists $colors{$color} ) {
        die "No such color $color";
    }
    my $method = "color_$color";
    return $self->$method();
}


sub getTaskColor {
    my ( $self, $task ) = @_;
    if ( not exists $task_colors{$task} ) {
        die "No such task $task";
    }
    my $method = "task_color_$task";
    return $self->$method();
}


sub printColor {
    my ( $self, $color ) = @_;
    return print $self->getColor($color);
}


sub setPrintColor {
    my ( $self, $color ) = @_;
    return print $self->getColor($color);
}


sub printTaskColor {
    my ( $self, $task ) = @_;
    return $self->printColor( $self->getTaskColor($task) );
}


sub disableColors {
    my ($self) = @_;
    for my $color ( keys %colors ) {
        my $setter = "_set_color_$color";
        $self->$setter('');
    }
}


sub restoreColors {
    my ( $self, ) = @_;
    for my $color ( keys %colors ) {
        my $setter = "_set_color_$color";
        require Term::ANSIColor;
        $self->$setter( Term::ANSIColor::color( $colors{$color} ) );
    }

}


sub messageColored {
    my ( $self, $color, @message ) = @_;
    return sprintf ' %s* %s%s', $self->getColor($color), $self->color_RESET,
      join '', @message;
}


sub printColored {
    my ( $self, $color, $message ) = @_;
    return print $self->messageColored( $color, $message );
}


sub messageTaskColored {
    my ( $self, $task, $message ) = @_;
    return $self->messageColored( $self->getTaskColor($task), $message );
}


sub printTaskColored {
    my ( $self, $task, $message ) = @_;
    return print $self->messageTaskColored( $task, $message );
}


sub print_ok {
    my ( $self, $message ) = @_;
    return $self->printTaskColored( 'ok', $message );
}


sub print_err {
    my ( $self, $message ) = @_;
    return $self->printTaskColored( 'err', $message );
}


sub print_info {
    my ( $self, $message ) = @_;
    return $self->printTaskColored( 'info', $message );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::Colors - Colour formatting / translation for Gentoo

=head1 VERSION

version 0.3.1

=head1 METHODS

=head2 C<getColor>

    my $colorCode = $colors->getColor('YELLOW');

=head2 C<getTaskColor>

    my $color = $colors->getTaskColor('ok');
    my $colorCode = $colors->getColor($color);

=head2 C<printColor>

Emit a color code, turning on that colour for all future printing

    $colors->printColor('RED');
    print "this is red"

=head2 C<setPrintColor>

Emit a color code, turning on that colour for all future printing

    $colors->setPrintColor('RED');
    print "this is red"

=head2 C<printTaskColor>

Emit a color code for a given task type, turning on that colour for all future printing

    $colors->printTaskColor('ok');
    print "this is green"

=head2 C<disableColors>

Replace all colours with empty strings.

    $colors->disableColors;

=head2 C<restoreColors>

Restores factory color settings

    $colors->restoreColors;

=head2 C<messageColored>

Formats a string to Gentoo message styling

    my $message = $color->messageColored( 'RED' , "Hello World" )

    $message eq " <RED ON>*<RESET> Hello World"

=head2 C<printColored>

Its C<messageColored>, but prints to STDOUT

    $color->printColored( 'RED' , "Hello World" )

=head2 C<messageTaskColored>

As with C<messageColored>, but takes a task name instead of a color

    my $message = $color->messageTaskColored( 'ok' , "Hello World" )

    $message eq " <GREEN ON>*<RESET> Hello World"

=head2 C<printTaskColored>

Its C<messageTaskColored>, but prints to STDOUT

    $colors->printTaskColored( 'ok' , "Hello World" )

=head2 C<print_ok>

Its C<printTaskColored>, but shorter and 'ok' is implied

    $colors->printTaskColored( 'ok', $message );
    $colors->print_ok( $message ); # Easy

=head2 C<print_err>

Its C<printTaskColored>, but shorter and 'err' is implied

    $colors->printTaskColored( 'err', $message );
    $colors->print_err( $message ); # Easy

=head2 C<print_info>

Its C<printTaskColored>, but shorter and 'info' is implied

    $colors->printTaskColored( 'info', $message );
    $colors->print_err( $message ); # Easy

=head1 ATTRIBUTES

=head2 C<color_YELLOW>

=head2 C<color_GREEN>

=head2 C<color_LIGHTGREEN>

=head2 C<color_WHITE>

=head2 C<color_CYAN>

=head2 C<color_RED>

=head2 C<color_BLUE>

=head2 C<color_RESET>

=head2 task_color_ok

=head2 task_color_err

=head2 task_color_info

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::Colors",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
