package SVG::Fill;
use 5.008001;
use strict;
use warnings;

use Mojo::DOM;
use Path::Class;
use URI;

our $VERSION = "0.09";

sub new {

    my ( $package, $filename ) = @_;

    my $self = bless {};

    my $file = file($filename);
    my $content = $file->slurp( iomode => '<:encoding(UTF-8)' );

    my $dom = Mojo::DOM->new($content);

    $self->{_dom}  = $dom;
    $self->{_file} = $file;

    return $self;

}

sub convert {

    my ( $self, $filename, $format ) = @_;

    die "Coming soon";

}

sub find_elements {

    my ( $self, $id ) = @_;

    my $dom = $self->{_dom};
    return [ $dom->find( sprintf( 'image[id*="%s"],text[id*="%s"]', $id, $id ) )->each ];
}

sub fill_text {

    my ( $self, $id, $text ) = @_;

    $id = "#" . $id, unless $id =~ /^#/;

    my $dom = $self->{_dom};

    if ( my $element = $dom->at($id) ) {

        if ( $element->tag eq 'text' ) {

            $element->content($text);

        } else {

            warn "$id is a <" . $element->tag . ">, please use only <text>";
        }

    } else {

        warn "Could not found $id";

    }
}

sub fill_image {

    my ( $self, $id, $image ) = @_;

    $id = "#" . $id, unless $id =~ /^#/;

    my $dom = $self->{_dom};

    if ( my $element = $dom->at($id) ) {

        if ( $element->tag eq 'image' ) {

            if ( -e $image ) {

                my $u = URI->new('data:');

                $u->media_type('image/png')     if $image =~ /png$/;
                $u->media_type('image/svg+xml') if $image =~ /svg$/;
                $u->media_type('image/jpeg')    if $image =~ /jpg$/;
                $u->media_type('image/gif')     if $image =~ /gif$/;
                my $content = file($image)->slurp;
                $u->data($content);
                $element->attr( 'xlink:href', $u->as_string );

            } else {

                warn "could not find $image";
            }

        } else {

            warn "$id is a <" . $element->tag . ">, please use only <image> for fill_image";

        }

    } else {

        warn "Could not find $id";
    }

}

sub save {

    my ( $self, $filename ) = @_;
    my $content = $self->{_dom}->to_string;
    defined $filename
      ? file($filename)->spew( iomode => '>:encoding(UTF-8)', $content )
      : $self->{_file}->spew( iomode => '>:encoding(UTF-8)', $content );
}

sub font_fix {

    my $self = shift;

    my $dom = $self->{_dom};

    $dom->find('text')->map(
        sub {

            my $element = $_;

            if ( my $font = $element->attr('font-family') ) {

                # Fix '' escaping by Illustrator
                $font =~ s/^'//g;
                $font =~ s/'$//g;
                
               
                # Remove MT-Variant
                $font =~ s/MT//g;

                # Font-weight as attribute
                $font =~ s/\-bold$/:bold/ig;
             
                $element->attr( 'font-family' => $font );
            }

        }
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

SVG::Fill - use svg file as templates, replace strings and images by id   

=head1 SYNOPSIS

    use SVG::Fill;

    # Open the filename for resue
    my $file = SVG::Fill->new( 'example.svg' );

    # Fill text in to a text field 
    $file->fill_text('#Template_ID', 'New Text');

    # Save image in to an image
    $file->fill_image('#Template_ID', 'file.png');
 
    # Cleanup ugly font-family-Attributes, removes '' written by Adobe Illustrator 
    $file->font_fix;

    # Save the modified svg
    $file->save('output.svg');

=head1 DESCRIPTION

SVG::Fill rewrites svg as template. Elements like text and img could be replaced by id (layer-name in Adobe Illustrator/Inkscape) 

=head1 LICENSE

Copyright (C) Jens Gassmann.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jens Gassmann E<lt>jens.gassmann@atomix.deE<gt>

=cut

