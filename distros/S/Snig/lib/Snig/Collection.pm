use v5.40;
use feature 'class';
no warnings "experimental::class";

class Snig::Collection {

    our $VERSION = '1.001'; # VERSION
    # ABSTRACT: Snig Collection Class
    # PODNAME: Snig::Collection

    use Path::Tiny qw(path);
    use Log::Any qw($log);
    use Template;
    use File::Copy qw(copy);
    use File::Share qw(dist_file);

    field $sort_by :reader :param = 'created'; # TODO
    field $input :reader :param;
    field $name :reader :param;

    field %images;
    field @sorted :reader;
    field $zip_size;

    field $tt;

    ADJUST {
        $input = path($input) if !ref($input);
        $tt = Template->new(ABSOLUTE=>1, WRAPPER=>dist_file('Snig','wrapper.tt'));

        for my $file ( $self->input->children ) {
            next unless $file->basename =~ /\.jpe?g$/i; # TODO allow other image types?
            $log->debugf("Reading image %s", $file->basename);
            my $image = Snig::Image->new(file => $file);
            $images{$file->basename} = $image;
        }

        @sorted = map { $_->[1] }
            sort { $a->[0] cmp $b->[0] }
            map { [ $_->$sort_by, $_ ] }
            values %images;

        while (my ($i, $image) = each @sorted) {
            my $prev = $i-1;
            my $next = $i == $#sorted ? 0 : $i+1;
            $image->set_chain($i+1, $sorted[$prev], $sorted[$next]);
        }

    }

    method resize_images($output, $th_size, $detail_size, $force = 0) {
        $log->infof("Resizing %i images", scalar @sorted);
        for my $img (@sorted) {
            $img->resize($output, $th_size, $detail_size, $force);
        }
        print "\n";
    }

    method write_html_pages( $output ) {
        $log->infof("Writing %i html pages", scalar @sorted);
        for my $img (@sorted) {
            $img->write_html_page($tt, $output, $self);
        }
    }

    method write_index( $output, $force_zip = 0 ) {
        my $zip_file = $self->zip_file($output);
        $log->infof("Generating zip archive %s and index", $zip_file);
        copy(dist_file('Snig','snig.css'), $output);

        if (!$zip_file->is_file || $force_zip ) {
            system('zip', '-r', $zip_file->stringify, $input->stringify);
        }

        $tt->process(dist_file('Snig','index.tt'), {
            collection=> {
                name => $name,
                images => \@sorted,
                zip_file => $zip_file->basename,
                zip_size => $zip_file->size_human( {format => "si"} ),
            },
            version => Snig->VERSION,
        }, $output->child('index.html')->stringify) || die $tt->error;
    }

    method zip_file($output) {
        my $dir = lc($output->basename);
        return $output->child($dir.'.zip');
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Snig::Collection - Snig Collection Class

=head1 VERSION

version 1.001

=head1 SYNOPSIS

A collection of images which should be turned into a HTML gallery.

  my $collection = Snig::Collection->new(input => $input, sort_by => $sort_by, name => $name);
  $collection->resize_images($output, $th_size, $detail_size);
  $collection->write_html_pages($output);
  $collection->write_index($output);

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
