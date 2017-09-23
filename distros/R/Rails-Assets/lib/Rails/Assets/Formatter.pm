package Rails::Assets::Formatter {

  use 5.006;
  use strict;
  use warnings;

  our $VERSION = '0.02';
  use Exporter qw(import);
  our @EXPORT = qw(
    format_asset_elem
    format_referral_elem
    format_template_elem
  );

  sub format_asset_elem {
    my ($asset_file, $ext, $assets_paths) = @_;
    my $asset_name = $asset_file;
    $asset_name =~ s/$_// foreach (@$assets_paths);
    return {
      name => $asset_name,
      full_path => $asset_file,
      ext => $ext,
    };
  }

  sub format_referral_elem {
    my ($asset_name, $ext, $referral) = @_;
    return {
      name => $asset_name,
      referral => $referral,
      ext => $ext,
    };
  }

  sub format_template_elem {
    my ($template_file, $asset_name) = @_;
    return {
      name => $asset_name,
      full_path => $template_file,
    }
  }
}

=head1 NAME

Rails::Assets::Formatter - Formatting Functions for Rails::Assets.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module provide some utility functions for formatting data structures while parsing assets.

    use Rails::Assets::Formatter;

    my $a = format_asset_elem($asset_file, $ext, $assets_paths);
    my $b = format_referral_elem($asset_file, $ext, $referral);
    my $c = format_template_elem($template_file, $asset_name);
    ...

=head1 EXPORT

=head2 format_asset_elem

Takes C<($asset_file, $ext, $assets_paths)> as arguments where :

=over 3

=item * C<$asset_file> is the file name (scalar)

=item * C<$ext> is the file extension (scalar)

=item * C<$assets_paths> is Array reference containing C<$Rails::Assets::ASSETS_DIR> and their subfolders named as C<$assets> keys

=back

Returns the following data structure:

    my $output = {
      name => $asset_name,
      full_path => $asset_file,
      ext => $ext,
    };

=head2 format_referral_elem

Takes three strings C<($asset_file, $ext, $referral)> as arguments and returns the following data structure:

    my $output = {
      name => $asset_name,
      referral => $referral,
      ext => $ext,
    };

=head2 format_template_elem

Takes two strings C<($template_file, $asset_name)> as arguments and returns the following data structure:

    my $output = {
      name => $asset_name,
      full_path => $template_file,
    };

=head1 SUBROUTINES/METHODS

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rails-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rails-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Pull Requests, Issues, Stars and Forks on the project L<github repository|https://github.com/mberlanda/rails-assets-coverage> are welcome!

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rails::Assets::Formatter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mauro Berlanda.

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

1; # End of Rails::Assets::Formatter
