package Rails::Assets::Base {
  use 5.006;
  use strict;
  use warnings;
  use File::Find;

  our $VERSION = '0.02';
  use Exporter qw(import);
  our @EXPORT = qw(
    find_files
    prepare_extensions_refs
    prepare_assets_refs
  );

  sub find_files {
    my $dirs = shift;
    die "Invalid reference provided. Expected ARRAY of directories: $!" unless (scalar @{$dirs} > 0);
    my @found;
    my $wanted = sub { push @found, $File::Find::name if -f };
    find({ wanted => $wanted, no_chdir=> 1}, @$dirs);
    return [sort {"\L$a" cmp "\L$b"} @found];
  }

  sub prepare_extensions_refs {
    my ($extensions) = @_;
    my $extensions_keys = format_extensions_list($extensions);
    my ($assets);
    $assets->{$_} = [()] foreach (@$extensions_keys);
    return $assets;
  }

  sub prepare_assets_refs {
    my ($dirs, $extensions) = @_;
    my $extensions_keys = format_extensions_list($extensions);
    my $assets = prepare_extensions_refs($extensions_keys);
    my ($assets_path, $reversed_ext);
    foreach my $d (@$dirs){
      unless ($d =~ /public/) {
        push @$assets_path, "$d$_/" foreach (qw(fonts javascripts stylesheets));
      }
      push @$assets_path, $d;
    }
    foreach my $key (@$extensions_keys){
      $reversed_ext->{$_} = $key foreach (@{$extensions->{$key}});
    }
    return ($assets, $assets_path, $reversed_ext);
  }

  sub format_extensions_list {
    my ($extensions) = @_;
    return [(sort keys %$extensions)] if (ref($extensions) eq 'HASH');
    return $extensions if(ref($extensions) eq 'ARRAY');
    die "Invalid extension argument provided: $!";
  }

}

=head1 NAME

Rails::Assets::Base - Files Finder and Custom Data Structures for Rails::Assets.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module provide some utilities functions

    use Rails::Assets::Base;

    my $template_hash = prepare_extensions_refs($assets_extensions);
    my ($assets_hash, $assets_paths, $reversed_ext) =
      prepare_assets_refs($assets_directories, $assets_extensions);
    ...

=head1 EXPORT

=head2 prepare_extensions_refs

Uses L<format_extensions_list|"#format_extensions_list"> to find the assets types and returns the following data structure:

    my $expected_extensions_refs = {
      fonts => [()],
      images => [()],
      javascripts => [()],
      stylesheets => [()],
    };

=head2 prepare_assets_refs

Returns C<($assets, $assets_path, $reversed_ext)> where :

=over 3

=item * C<$assets> is an Hash reference as L<prepare_extensions_refs|"#prepare_extensions_refs">

=item * C<$assets_path> is Array reference containing C<$Rails::Assets::ASSETS_DIR> and their subfolders named as C<$assets> keys

=item * C<$reversed_ext> is an Hash reference created reversing key value of C<$assets>

=back

=head2 find_files

Takes an array reference of directories as argument and returns a sorted list of files for all subfolder

=head1 SUBROUTINES/METHODS

=head2 format_extensions_list

This subroutine takes as argument an C<$assets_extensions> reference and returns an array reference of assets types

    my $assets_extensions = {
      fonts => [qw(.ttf)],
      images => [qw(.png)],
      javascripts => [qw(.js)],
      stylesheets => [qw(.css)],
    };

    my $assets_ext = [qw(fonts images javascripts stylesheets)];
    is_deeply(
      Rails::Assets::Base::format_extensions_list($assets_extensions),
      $assets_ext, 'format_extensions_list() works with an HASH reference'
    );
    is_deeply(
      Rails::Assets::Base::format_extensions_list($assets_ext),
      $assets_ext, 'format_extensions_list() works with an ARRAY reference'
    );

    my $invalid_ref = sub { return 1 };
    eval { Rails::Assets::Base::format_extensions_list($invalid_ref) } or my $at = $@;
    like(
      $at, qr/Invalid extension argument provided/,
      'format_extensions_list() dies with a message when invalid reference provided'
    );

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rails-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rails-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Pull Requests, Issues, Stars and Forks on the project L<github repository|https://github.com/mberlanda/rails-assets-coverage> are welcome!

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rails::Assets::Base

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

1; # End of Rails::Assets::Base
