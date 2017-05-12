package Moonshine::Util;

use strict;
use warnings;

use String::Trim::More;
use String::Elide::Parts 'elide';
use Exporter::Shiny; 
use HTML::Valid::Tagset ':all';

our @EXPORT = (qw/prepend_str append_str join_class/);

our @EXPORT_OK = (qw/left_trim_ws right_trim_ws trim_ws trim_ws_lines trim_blank_ws_lines ellipsis
elide append_str prepend_str join_class assert_valid_html5_tag valid_attributes_for_tag/); 

our %EXPORT_TAGS = (
    base => \@EXPORT,
    all  => \@EXPORT_OK,
);

=head1 NAME

Moonshine::Util - Utils

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

=head1 EXPORT

    use Moonshine::Util "trim_blank_ws_lines" => { -as => "tbwl" };

=head1 SUBROUTINES/METHODS

=head2 assert_valid_html5_tag

    assert_valid_html5_tag('span');

=cut

sub assert_valid_html5_tag {
    return $isHTML5{$_[0]} ? 1 : 0;
}

=head2 valid_attributes_for_tag 
    
    valid_attributes_for_tag('a');
    valid_attributes_for_tag('a', standard => 'html5')
    
Returns an array reference containing all valid attributes for the specified html tag.

=cut

sub valid_attributes_for_tag {
    return attributes(@_);
}

=head2 left_trim_ws
    
    left_trim_ws($string)

=cut

sub left_trim_ws {
    return String::Trim::More::ltrim(@_);
}

=head2 right_trim_ws

    right_trim_ws($string)

=cut

sub right_trim_ws {
    return String::Trim::More::rtrim(@_);
}

=head2 trim_ws

    trim_ws($string)

=cut

sub trim_ws {
    return String::Trim::More::trim(@_);
}

=head2 trim_ws_lines

    trim_ws_line($multi_line_str);

=cut

sub trim_ws_lines {
    return String::Trim::More::trim_lines(@_);
}

=head2 trim_blank_ws_lines

    trim_ws_line($multi_line_str);

=cut

sub trim_blank_ws_lines {
    return String::Trim::More::trim_blank_lines(@_);
}

=head2 ellipsis

    ellipsis($str);

=cut

sub ellipsis {
    return String::Trim::More::ellipsis(@_);
}

=head2 prepend_str

    prepend_str($str_exists, $str_might_not);

=cut

sub prepend_str {
    return defined $_[1] ? sprintf '%s %s', $_[1], $_[0] : $_[0];
}

=head2 append_str

    append_str($str_exists, $str_might_not);

=cut

sub append_str {
    return defined $_[1] ? sprintf '%s %s', $_[0], $_[1] : $_[0];
}

=head2 join_class

    join_class($class_exists, $class_might_not);

=cut

sub join_class {
    defined $_[0] && defined $_[1] and return sprintf '%s%s', $_[0], $_[1];
    return undef;
}

=head2 elide
    
    elide($text, 16, { truncate => 'left', marker => '...' })

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moonshine-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Moonshine-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Moonshine::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Moonshine-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Moonshine-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Moonshine-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/Moonshine-Util/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

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

1; # End of Moonshine::Util
