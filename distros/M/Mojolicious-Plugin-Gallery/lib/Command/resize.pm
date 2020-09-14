package Command::resize;
use Mojo::Base 'Mojolicious::Command';
use Mojo::File 'path';
use YAML::XS;
use DDP;

use File::Basename;
use GD;

use constant DEBUG => $ENV{PI_DEBUG} || 0;

has description => "Resize photos for gallery\n";
has usage       => "usage: $0\n";

sub run {
  my ($self) = @_;

  my $config = $self->app->config->{gallery};
  my $main_path = $config->{main_path};

  my $path = path $main_path;

  my $galleries = $path->list({dir => 1});
  for my $gallery ($galleries->each) {
    my $meta_source = $gallery->list->first(qr/yml/)->slurp;
    die 'meta is undef' unless $meta_source;
    my $meta = Load $meta_source;
    next if $meta->{skip};
    my $gallery_path = $gallery->to_string;

    my $photos = $gallery->list->grep(qr/jpg|png|JPG|PNG/);
    for my $photo ($photos->each) {
      my $file_path = $photo->to_string;

      _resize($file_path, $config->{sizes}, "$gallery_path");
      unlink $file_path;
      say "Done $file_path";
    }
  }
}

sub _resize {
  my ($file, $sizes, $imgDir) = @_;
  # https://github.com/davepagurek/Image-Resizer

  if (!$imgDir) {
    my ($a, $b, $c) = fileparse($file);
    $imgDir = $b;
  }

  if (!-d $imgDir) {
    mkdir $imgDir or die "Unable to create $imgDir";
  }

  if ($file && -e $file) {
    my $name = "img";
    my $mime = "jpg";
    if ($file =~ /[\/\\]*([a-zA-Z0-9-_ ]*)\.([a-z]+)$/i) {
      $name = $1;
      $mime = $2;
    }

    my $img;
    if (lc($mime) eq "jpg" || lc($mime) eq "jpeg") {
      $img = GD::Image->newFromJpeg($file);
    } elsif (lc($mime) eq "png") {
      $img = GD::Image->newFromPng($file);
    } else {
      die "Unsupported file format: $mime";
    }

    my ($w,$h) = $img->getBounds(); # find dimensions

    for my $size (keys %$sizes) {
      my $imgDirSize = "$imgDir/$size";
      if (!-d $imgDirSize) {
        mkdir $imgDirSize or die "Unable to create $imgDirSize";
      }
      my $newimg;
      if ($sizes->{$size}->{crop}) {
        my ($cut,$xcut,$ycut);
        if ($w>$h){
          $cut=$h;
          $xcut=(($w-$h)/2);
          $ycut=0;
        }
        if ($w<$h){
          $cut=$w;
          $xcut=0;
          $ycut=(($h-$w)/2);
        }
        $newimg = new GD::Image($sizes->{$size}->{width}, $sizes->{$size}->{height}, 1);
        $newimg->copyResampled($img,0,0,$xcut,$ycut,$sizes->{$size}->{width}, $sizes->{$size}->{height},$cut,$cut);
      } else {
        my $gd;
        if ($w>$h) {
          $newimg = new GD::Image($sizes->{$size}->{width}, (($h/$w)*$sizes->{$size}->{width}), 1);
          $newimg->copyResampled($img,0,0,0,0,$sizes->{$size}->{width}, (($h/$w)*$sizes->{$size}->{width}),$w,$h);
        } else {
          $newimg = new GD::Image(($w/$h)*$sizes->{$size}->{height}, ($sizes->{$size}->{height}), 1);
          $newimg->copyResampled($img,0,0,0,0,($w/$h)*$sizes->{$size}->{height}, ($sizes->{$size}->{height}),$w,$h);
        }
      }

      open(my $thumbFile, ">", "$imgDirSize/$name.jpg") or die "Cannot open $imgDirSize/$name.jpg: $!";
      binmode $thumbFile;
      print $thumbFile $newimg->jpeg($sizes->{$size}->{quality});
      close $thumbFile;
    }
  } else {
    die "Can't find file $file\n";
  }
}

1;
