package PerlIO::via::ANSIColor;

use strict;
use warnings;
require Term::ANSIColor;

our $VERSION = '0.05';
my $color = 'red';
my $reset = Term::ANSIColor::color('reset');

sub import {
    my( $class, %param ) = @_;
    $class->$_( $param{$_} ) foreach keys %param;
}

sub color {
    my $self      = shift;
    my $new_color = shift;
    if ( defined $new_color ) {
        eval { Term::ANSIColor::color($new_color) };
        $color = $new_color unless $@;
    }
    return $color;
}

sub paint {
    my $self      = shift;
    my $fh        = shift;
    my $new_color = shift;
    return unless $fh;
    $self->color($new_color) if $new_color;
    binmode $fh, ':via(ANSIColor)';
}

sub PUSHED {
    bless { color => Term::ANSIColor::color($color) }, $_[0];
}

sub FILL {
    my $color = $_[0]->{color};
    if ( defined( my $line = readline( $_[1] ) ) ) {
        return $color . $line . $reset;
    }
    undef;
}

sub WRITE {
    my $color = $_[0]->{color};
    my $str   = $_[1];
    if ($str =~ /\n$/ ) {
        chomp $str;
        print { $_[2] } $color . $str . $reset . "\n" or return -1;
    }
    else {
        print { $_[2] } $color . $_[1] . $reset or return -1;
    }
    length $_[1];
}

1;

__END__

=head1 NAME

PerlIO::via::ANSIColor - PerlIO layer for Term::ANSIColor


=head1 VERSION

This document describes PerlIO::via::ANSIColor version 0.0.3


=head1 SYNOPSIS

    use PerlIO::via::ANSIColor;
    PerlIO::via::ANSIColor->color('green');

    open my $fh, '<:via(ANSIColor)', 'filein';

=head1 DESCRIPTION

This module implements a PerlIO layer that adds color to the text
using Term::ANSIColor.

=head1 METHODS

=head2 color

    PerlIO::via::ANSIColor->color('green');

    use PerlIO::via::ANSIColor color => 'reverse green';

Change or retrieve a color to add.
This takes same arguments as Term::ANSIColor::color().

=head2 paint

    PerlIO::via::ANSIColor->paint(STDOUT);

    PerlIO::via::ANSIColor->paint( STDOUT, 'underscore yellow' );

This does

    binmode $fh, ':via(ANSIColor)';

If new color is specified, try to change color before binmode.

=head2 PUSHED

    PerlIO::via::ANSIColor->PUSHED()

=head2 FILL

    PerlIO::via::ANSIColor->FILL()

=head1 EXAMPLES

Here are some examples.

=head2 Adds reverse green color to STDERR

    use PerlIO::via::ANSIColor color => 'reverse green';
    binmode STDERR, ':via(ANSIColor)';

    warn "this outputs is colored\n";

=head2 Print text from 'filein' with bule color

    use PerlIO::via::ANSIColor color => 'blue';
    open my $fh, '<:via(ANSIColor)', 'filein';
    print while <$fh>;

=head2 Multiple filehandles

    use PerlIO::via::ANSIColor;

    PerlIO::via::ANSIColor->color('reverse red');
    open my $redfh, ">&STDOUT" or die $!;
    binmode $redfh, ':via(ANSIColor)';

    PerlIO::via::ANSIColor->color('reverse blue');
    open my $bluefh, ">&STDOUT" or die $!;
    binmode $bluefh, ':via(ANSIColor)';

    print $redfh  "this color is reverse red\n";
    print $bluefh "this color is reverse blue\n";


=head1 DEPENDENCIES

This module requires Term::ANSIColor.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perlio-via-ansicolor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<PerlIO::via>
L<Term::ANSIColor>

=head1 AUTHOR

Masanori Hara  C<< <massa.hara at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, Masanori Hara C<< <massa.hara at gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
