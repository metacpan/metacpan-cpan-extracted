#!/usr/bin/perl -w
use strict;

use OpenGL::Modern qw(GL_FLOAT);
use OpenGL::Array;

# Sample/Test app for OpenGL::Array functions
# by Bob "grafman" Free <grafman@graphcomp.com>
# http://graphcomp.com/opengl

use Time::HiRes qw( gettimeofday );


use constant PROGRAM_TITLE => "OpenGL::ARRAY Test App";

my @verts =
(
  -1.0, -1.3, -1.0,
  1.0, -1.3, -1.0,
  1.0, -1.3,  1.0,
  -1.0, -1.3,  1.0,

  -1.0,  1.3, -1.0,
  -1.0,  1.3,  1.0,
  1.0,  1.3,  1.0,
  1.0,  1.3, -1.0,

  -1.0, -1.0, -1.3,
  -1.0,  1.0, -1.3,
  1.0,  1.0, -1.3,
  1.0, -1.0, -1.3,

  1.3, -1.0, -1.0,
  1.3,  1.0, -1.0,
  1.3,  1.0,  1.0,
  1.3, -1.0,  1.0,

  -1.0, -1.0,  1.3,
  1.0, -1.0,  1.3,
  1.0,  1.0,  1.3,
  -1.0,  1.0,  1.3,

  -1.3, -1.0, -1.0,
  -1.3, -1.0,  1.0,
  -1.3,  1.0,  1.0,
  -1.3,  1.0, -1.0
);
@verts =
(
  0.0, 0.1, 0.2,
  1.0, 1.1, 1.2,
  2.0, 2.1, 2.2,
  3.0, 3.1, 3.2,

  10.0, 10.1, 10.2,
  11.0, 11.1, 11.2,
  12.0, 12.1, 12.2,
  13.0, 13.1, 13.2,

  20.0, 20.1, 20.2,
  21.0, 21.1, 21.2,
  22.0, 22.1, 22.2,
  13.0, 23.1, 23.2,

  30.0, 30.1, 30.2,
  31.0, 31.1, 31.2,
  32.0, 32.1, 32.2,
  33.0, 33.1, 33.2,

  40.0, 40.1, 40.2,
  41.0, 41.1, 41.2,
  42.0, 42.1, 42.2,
  43.0, 43.1, 43.2,

  50.0, 50.1, 50.2,
  51.0, 51.1, 51.2,
  52.0, 52.1, 52.2,
  53.0, 53.1, 53.2
);

my @xform =
(
  1.0, 0.0, 0.0, 1.0,
  0.0, 3.0, 0.0, 0.0,
  0.0, 0.0, 2.0, 1.0,
  0.0, 0.0, 0.0, 1.0
);
my $xform = OpenGL::Array->new_list(GL_FLOAT,@xform);

# Tests
my $loops = 2;
my $vertices = 4;
my $print_verts = $vertices < 5;

my($i,$start,$secs);
print "Initial data:\n";
print "Loops: $loops, Vertices: $vertices\n";
my $verts = init_verts($vertices);
print_verts($verts,$vertices) if ($print_verts);

$start = gettimeofday();
for ($i=0;$i<$loops;$i++)
{
  $verts->calc('1,+','3,*','2,*,1,+');
}
$secs = (gettimeofday()-$start)/$loops;
my $vps_calc = int($vertices/$secs);
print "Calc VPS: $vps_calc\n";
print_verts($verts,$vertices) if ($print_verts);


$verts = init_verts($vertices);
$start = gettimeofday();
for ($i=0;$i<$loops;$i++)
{
  $verts->affine($xform);
}
$secs = (gettimeofday()-$start)/$loops;
my $vps_gpu = int($vertices/$secs);
print "Affine VPS:  $vps_gpu\n";
print_verts($verts,$vertices) if ($print_verts);


sub init_verts
{
  my($count) = @_;

  my @verts = ();
  for (my $i=0;$i<$count;$i++)
  {
    push(@verts,"$i.0","$i.1","$i.2");
  }

  my $verts = OpenGL::Array->new_list(GL_FLOAT,@verts);
  die "new_list failed to return an OGA\n" if (!$verts);
  return $verts;
}

sub print_verts
{
  my($verts,$vertices) = @_;
  my $len = $vertices * 3;
  for(my $i=0;$i<$len;$i+=3)
  {
    my($x,$y,$z) = $verts->retrieve($i,3);
    printf("%8.3f,%8.3f,%8.3f\n",$x,$y,$z);
  }
  print "\n";
}


__END__
