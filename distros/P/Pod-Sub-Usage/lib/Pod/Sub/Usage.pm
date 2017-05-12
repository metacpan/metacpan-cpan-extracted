package Pod::Sub::Usage;

use 5.006;
use strict;
use warnings;

$Pod::Sub::Usage::VERSION = '0.010000';

use Exporter 'import';
our @EXPORT_OK = qw( sub2usage pod_text);
our %EXPORT_TAGS = ( all => [@EXPORT_OK], );

=head1 NAME

Pod::Sub::Usage - Module to print sub documentaion from pod!

=head1 VERSION

Version 0.010000

=head1 SYNOPSIS

    use Pod::Sub::Usage qw/sub2usage/;

    # print header from 'your_sub' in current package
    sub2usage('your_sub');

    # same here
    sub2usage('your_sub', __PACKAGE__);

    # print header from 'your_sub' in some other package
    sub2usage('your_sub', 'Use::Some::Package' );

=head1 EXPORT

Nothing is exported by default. You can ask for specific subroutines (described below) or ask for all subroutines at once: 

    use Pod::Sub::Usage qw/sub2usage/;
     
    # or
     
    use Pod::Sub::Usage qw/all/;

=head1 SUBROUTINES/METHODS

=head2 sub2usage

Print out the header information by given sub.

=cut

sub sub2usage {
    my ( $sub, $package ) = @_;
    die q~You have to say the sub if you want to know something about it!~ if !$sub;
    require Module::Locate;
    my $file = Module::Locate::locate( $package ||= ( caller(0) )[0] ) // ( caller(0) )[1];
    my $string = pod_text( $file, $package, $sub );
    print $string;
}

=head2 pod_text

Returns the string from pod

=cut

sub pod_text {
    my ( $file, $package, $sub ) = @_;
    open( my $fh, '<:encoding(UTF-8)', $file ) or die "Could not open file '$file' $!";
    my $rex_start_head = qr/^=head\d ($sub|$package::$sub)/;
    my $found          = 0;
    my $sub_header     = '';
    while ( my $row = <$fh> ) {
        last if ( $row =~ /^=cut/ && $found );
        if ( $row =~ /$rex_start_head/ ) {
            $found = 1;
            next;
        }
        if ($found) {
            chomp $row;
            $row =~ s/^=head\d\s+//;
            $sub_header .= "$row\n";
        }
    }
    die qq~Couldn't find $sub in file $file. $!~ if !$found;
    return $sub_header;
}

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-sub-usage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Sub-Usage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Sub::Usage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Sub-Usage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Sub-Usage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Sub-Usage>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-Sub-Usage/>

=back

=head1 SEE ALSO
 
This package was partly inspired by on L<Pod::Usage> by Marek Rouchal.


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Pod::Sub::Usage
