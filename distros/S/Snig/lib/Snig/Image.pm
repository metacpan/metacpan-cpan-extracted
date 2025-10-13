use v5.40;
use feature 'class';
no warnings "experimental::class";

class Snig::Image {

    our $VERSION = '1.001'; # VERSION
    # ABSTRACT: Snig Image Class
    # PODNAME: Snig::Image

    use Log::Any qw($log);
    use Imager;
    use Image::ExifTool qw(ImageInfo);
    use File::Copy qw(copy);
    use File::Share qw(dist_file);

    field $file :reader :param;
    field $exif :reader;
    field $mtime :reader;
    field $created :reader;
    field $model :reader;
    field $orientation :reader;

    field $next :reader;
    field $prev :reader;
    field $pos :reader;

    ADJUST {
        $file = path($file) if !ref($file);
        $exif = ImageInfo($file->stringify);
        $mtime = $file->stat->mtime;
        $created = $exif->{'CreateDate'};
        $model = $exif->{'Model'};
        $orientation = $exif->{'Orientation'};
    }

    method set_chain($this_pos, $prev_image, $next_image) {
        $pos = $this_pos;
        $prev = $prev_image;
        $next = $next_image;
    }

    method resize ( $outdir, $thumbnail, $detail, $force = 0 ) {

        copy($file, $outdir->child('orig_'.$file->basename)) unless -e $outdir->child('orig_'.$file->basename);

        my ($img, $w, $h, $format);

        for my $scale ({format=>'thumbnail',size=>$thumbnail},{format=>'preview',size=>$detail}) {

            my $scaled_file_name = $scale->{format}.'_'.$file->basename;
            my $outfile = $outdir->child($scaled_file_name);
            next if ($outfile->is_file && !$force);

            unless ($img) {
                $img = Imager->new(file=>$file->stringify) || die Imager->errstr();
                if ($orientation && $orientation =~ /(\d+) CW/) {
                    my $degrees = $1;
                    my $rotated = $img->rotate(right=>$degrees);
                    $log->debugf("Rotated %s %s degrees right", $file->basename, $degrees);
                    $img = $rotated;
                }
                $w = $img->getwidth;
                $h = $img->getheight;
                $format = $w / $h;
            }

            my $scaled;
            if ($format >= 1) {
                $scaled = $img->scale(xpixels => $scale->{size}) || die "Cannot scale $file: ".$img->errstr;
            }
            else {
                my $scale_h = int($scale->{size}) / 3 * 2; # TODO get proper factor, needs to inspect all image formats in set
                $scaled = $img->scale(ypixels => $scale_h) || die "Cannot scale $file: ".$img->errstr;
            }

            $scaled->write(file=>$outfile, jpgquality=>100);
            $log->debugf("Scaled %s to %s", $file->basename, $outfile);
            local $|=1;
            print '.';
        }

    }

    method url($format) {
        return $format .'_'. $file->basename;
    }

    method html_file {
        my $html = lc($file->basename);
        $html =~s/\.(.*?)$/.html/;
        return $html;
    }

    method write_html_page($tt, $output, $collection) {

        $tt->process(dist_file('Snig','page.tt'), {
            image => $self,
            collection=> {
                name => $collection->name,
                size => scalar $collection->sorted,
            },
            version => Snig->VERSION,
        }, $output->child($self->html_file)->stringify) || die $tt->error;

    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Snig::Image - Snig Image Class

=head1 VERSION

version 1.001

=head1 SYNOPSIS

A single image with EXIF metadata and knowledge of it's place in the collection.

Currently we only handle C<jpg> because that's what I use for my photos.

  my $image = Snig::Image->new( file => 'path/to/image.jpg' );

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
