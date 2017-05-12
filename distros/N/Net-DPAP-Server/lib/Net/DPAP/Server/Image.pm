package Net::DPAP::Server::Image;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use File::Basename qw( basename );
use Image::Info;
use Image::Imlib2;
use Perl6::Slurp;
use File::Temp;

__PACKAGE__->mk_accessors(qw(
      file
      dmap_itemid dmap_itemname dmap_itemkind dmap_containeritemid

      dpap_imagefilename dpap_aspectratio dpap_imagefilesize dpap_creationdate
));

sub new_from_file {
    my $class = shift;
    my $file = shift;
    my $self = $class->new({ file => $file });
    #print "Adding $file\n";

    my @stat = stat $file;
    my $info = Image::Info::image_info( $file );
    $self->file( $file );
    $self->dmap_itemid( $stat[1] ); # the inode should be good enough
    $self->dmap_containeritemid( 0+$self );

    $self->dpap_imagefilename( basename $file );
    $self->dpap_aspectratio( $info->{width} / $info->{height} );
    $self->dpap_imagefilesize( $stat[7] );
    $self->dpap_creationdate( $stat[10] );
    $self->dmap_itemname( basename $file, qw( .jpeg .jpg ) );
    $self->dmap_itemkind( 3 );

    return $self;
}

sub dpap_hires {
    my $self = shift;
    scalar slurp $self->file;
}

sub dpap_thumb {
    my $self = shift;
    my $image = Image::Imlib2->load( $self->file );
    my $thumbnail = $image->create_scaled_image( 240, 0 );
    $thumbnail->image_set_format("jpeg");
    my $file = File::Temp->new;
    $thumbnail->save( $file->filename );
    return scalar slurp $file->filename;
}


1;
