package Rails::Assets::Processor {

  use 5.006;
  use strict;
  use warnings;

  our $VERSION = '0.02';

  use Exporter qw(import);
  our @EXPORT = qw(
    process_asset_file
    process_template_file
    process_scss_file
    process_map_file
  );

  use Rails::Assets::Formatter qw(
    format_asset_elem
    format_referral_elem
    format_template_elem
  );

  sub process_asset_file {
    my ($filename, $reversed_ext, $assets_hash, $assets_paths) = @_;
    my ($ext) =  $filename =~ /(\.[a-zA-Z0-9]+)$/;
    my $type = $reversed_ext->{$ext} || 'unknown';

    if ($type ne 'unknown'){
      my $elem = format_asset_elem($filename, $ext, $assets_paths);
      push @{$assets_hash->{$type}}, $elem;
    } else {
      print "Found unknown type: $ext ($filename)" . "\n" if $ENV{VERBOSE};
    }
  }

  sub process_template_file {
    my ($filename, $template_hash, $template_extensions) = @_;
    my ($ext) =  $filename =~ /(\.[a-zA-Z0-9]+)$/;
    if (grep /$ext/, @$template_extensions){

      open FILE, $_;
      while (my $line=<FILE>){
        my @stylesheet_tags = $line =~ /stylesheet_link_tag\s*\(*\s*['"](.+?)['"]\s*\)*/g;
        my @javascript_tags = $line =~ /javascript_include_tag\s*\(*\s*['"](.+)['"]\s*\)*/g;
        my @image_tags = $line =~ /asset_path\s*\(*\s*['"](.+?)['"]\s*\)*/g;

        push @{$template_hash->{stylesheets}}, $_ foreach (map {format_template_elem($filename, $_)} @stylesheet_tags);
        push @{$template_hash->{javascripts}}, $_ foreach (map {format_template_elem($filename, $_)} @javascript_tags);
        push @{$template_hash->{images}}, $_ foreach (map {format_template_elem($filename, $_)} @image_tags);
      }
    } else {
      print "Found unknown type: $ext ($filename)" . "\n" if $ENV{VERBOSE};
    }
  }

  sub process_scss_file {
    my ($filename, $reversed_ext, $scss_hash) = @_;
    open FILE, $filename;
    while (my $line=<FILE>){
      my @assets_tags = $line =~ /asset\-url\s*\(*\s*['"](.+?)['"]\s*\)*/g;
      foreach my $asset (@assets_tags){
        my $clean_name = $asset;
        $clean_name =~ s/([\?#].*)//;
        my ($ext) =  $clean_name =~ /(\.[a-zA-Z0-9]+)$/;
        my $type = $reversed_ext->{$ext} || 'unknown';
        if ($type ne 'unknown'){
          my $elem = format_referral_elem($clean_name, $ext, $filename);
          push @{$scss_hash->{$type}}, $elem;
        } else {
          print "Found unknown type: $ext ($filename)" . "\n" if $ENV{VERBOSE};
        }
      };
    }
  }

  sub process_map_file {
    my ($filename, $reversed_ext, $map_hash) = @_;
    open FILE, $_;
    while (my $line=<FILE>){
      my @assets_tags = $line =~ /sourceMappingURL=(.+\.map?)/;
      foreach my $asset (@assets_tags){
        my $clean_name = $asset;
        $clean_name =~ s/([\?#].*)//;
        my ($ext) =  $clean_name =~ /(\.[a-zA-Z0-9]+)$/;
        my $type = $reversed_ext->{$ext} || 'unknown';
        if ($type ne 'unknown'){
          my $elem = format_referral_elem($clean_name, $ext, $filename);
          push @{$map_hash->{$type}}, $elem;
        } else {
          print "Found unknown type: $ext ($filename)"  . "\n" if $ENV{VERBOSE};
        }
      };
    }
  }
}

=head1 NAME

Rails::Assets::Processor - Processing Functions for Rails::Assets

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module contains some functions for processing data references.

    use Rails::Assets::Processor;

    process_template_file($_, $template_hash, $template_extensions) foreach @{find_files($template_directories)};
    process_asset_file($_, $reversed_ext, $assets_hash, $assets_paths) foreach @{find_files($assets_directories)};

    my $scss_files = [grep { $_->{ext} eq '.scss' } @{$assets_hash->{stylesheets}}];
    my $js_files = [grep { $_->{ext} eq '.js' } @{$assets_hash->{javascripts}}];

    process_scss_file($_, $reversed_ext, $scss_hash) foreach map {$_->{full_path}} @{$scss_files};
    process_map_file($_, , $reversed_ext, $map_hash) foreach map {$_->{full_path}} @{$js_files};
    ...

=head1 EXPORT

=head2 process_asset_file

This function find the file extension, assign a file type based on C<$reversed_ext> and pushed a formatted element into C<<< @{$assets_hash->{$type}} >>>

=head2 process_template_file

This function parse template files, extract the references to assets, find the file extension, assign a file type based on C<$reversed_ext> and pushed a formatted element into C<<< @{$template_hash->{$type}} >>>

=head2 process_scss_file

This function parse scss files, extract the references to assets, find the file extension, assign a file type based on C<$reversed_ext> and pushed a formatted element into C<<< @{$scss_hash->{$type}} >>>

=head2 process_map_file

This function parse javascript files, extract the references to .js.map files, assign a file type based on C<$reversed_ext> and pushed a formatted element into C<<< @{$map_hash->{$type}} >>>


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

    perldoc Rails::Assets::Processor

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

1; # End of Rails::Assets::Processor
