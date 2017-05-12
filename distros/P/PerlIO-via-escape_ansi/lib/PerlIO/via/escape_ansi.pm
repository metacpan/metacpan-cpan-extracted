package PerlIO::via::escape_ansi;

require 5.008;
use strict;
use warnings;
use XSLoader;


{
    no strict "vars";
    $VERSION = "0.01";
    XSLoader::load(__PACKAGE__, $VERSION);
}


sub import {
    my ($class, @args) = @_;

    if (grep { $_ eq "-as_function" } @args) {
        no strict "vars";
        require Exporter;
        @ISA    = qw< Exporter >;
        @EXPORT = qw< escape_non_printable_chars >;
        $class->export_to_level(1);
    }
}


#
# PerlIO methods
# --------------

sub PUSHED {
    my ($class, $mode) = @_;
    return bless {}, $class;
}

sub FILL {
    my ($self, $fh) = @_;
    my $line = <$fh>;
    return undef unless defined $line;
    return escape_non_printable_chars ($line);
}


"true value on strike"

__END__

=head1 NAME

PerlIO::via::escape_ansi - PerlIO layer to escape ANSI sequences

=head1 VERSION

This is the documentation of C<PerlIO::via::escape_ansi> version 0.01


=head1 SYNOPSIS

    # used as a PerlIO layer
    use PerlIO::via::escape_ansi;
    open my $fh, "<:via(escape_ansi)", $file or die $!;
    print <$fh>;

    # used as a function
    use PerlIO::via::escape_ansi -as_function;
    print escape_non_printable_chars($unsure_data);


=head1 DESCRIPTION

This module is a proof of concept and a very simple PerlIO layer for
escaping non-printable characters, in order to prevent from shell attacks
with ANSI sequences. The internal function can also be directly called.

B<Note:> This is an experimental module, most probably with bugs and
memory leaks, used as a prototype for the true module, C<PerlIO::escape_ansi>
which will be written using the XS API of PerlIO.


=head2 Examples

=over

=item *

a sequence for making the text brighter or bold:

    "\e[1mbold text"

becomes

    "<ESC>[1mbold text"

=item *

a sequence for setting the terminal title:

    "\e]0;OH HAI\a"

becomes

    "<ESC>]0;OH HAI<BEL>"

=item *

a sequence that clears the screen, sets the cursor at a given position
and prints a red blinking text:

    "\a\e[2J\e[2;5m\e[1;31mI CAN HAS UR PWNY\n\e[2;25m\e[22;30m\e[3q"

becomes

    "<BEL><ESC>[2J<ESC>[2;5m<ESC>[1;31mI CAN HAS UR PWNY<LF><ESC>[2;25m<ESC>[22;30m<ESC>[3q"

=back


=head1 EXPORT

No functions is exported by default, but you can import the 
C<escape_non_printable_chars()> by calling the module with the argument
C<-as_function>:

    use PerlIO::via::escape_ansi -as_function;


=head1 FUNCTIONS

=head2 escape_non_printable_chars()

Direct call (minus the Perl and XS wrappers) to the internal C function
that does the real work.


=head1 ACKNOWLEDGEMENT

Mark Overmeer, who suggested that such a module should be written
(see RT-CPAN #41174).


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests
to C<bug-perlio-escape_ansi at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/Dist/Display.html?Queue=PerlIO-escape_ansi>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PerlIO::escape_ansi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Dist/Display.html?Queue=PerlIO-escape_ansi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PerlIO-escape_ansi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PerlIO-escape_ansi>

=item * Search CPAN

L<http://search.cpan.org/dist/PerlIO-escape_ansi>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 SE<eacute>bastien Aperghis-Tramoni

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
