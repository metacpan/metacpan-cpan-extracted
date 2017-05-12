# Port of http://www.playfuljs.com/demos/raycaster/ (c) Hunter Loftis 
#
# tries Inline::C if it's there, or using pure perl implementation otherwise

use strict;
use warnings;
use POSIX qw(ceil floor);
use Time::HiRes qw(time);
use Prima qw(Application Cairo);
use Prima::MsgBox;
use FindBin qw($Bin);

my ($use_inline_c, $libs);
BEGIN { 
        # find cairo lib for direct linking
        eval "require Inline::C;";
        $use_inline_c = 1 unless $@;
};

my $pi          = atan2(1,0)*2;
my $twopi       = $pi*2;
my ( $x, $y, $direction, $paces ) = (15.3,-1.2,$pi*3,0);
my $weapon      = Prima::Icon->load("$Bin/knife_hand.png")->to_cairo_surface;
my $sky         = Prima::Image->load("$Bin/deathvalley_panorama.jpg")->to_cairo_surface;
my $wall        = Prima::Image->load("$Bin/wall_texture.jpg")->to_cairo_surface;
my $size        = 32;
my @grid        = map {(0.3 > rand) ? 1 : 0} 1..$size*$size;
my $light       = 0;
my $fov         = $pi * 0.4;
my $resolution  = 320;
my $range       = 14;
my $light_range = 5;
my $cast_cache;
my $seconds     = 1;
my $draw_rain   = 1;

my ( $width, $height, $spacing, $scale ) ;

sub rotate { 
    $direction = ($direction + $twopi + shift);
    $direction -= $twopi while $direction > $twopi;
    undef $cast_cache;
}

sub walk 
{
    my $distance = shift;
    my $dx = cos($direction) * $distance;
    my $dy = sin($direction) * $distance;
    $x += $dx if inside($x + $dx, $y) <= 0;
    $y += $dy if inside($x, $y + $dy) <= 0;
    $paces += $distance;
    undef $cast_cache;
}

sub inside
{
    my ( $x, $y ) = map { floor($_) } @_;
    return ($x < 0 or $x > $size - 1 or $y < 0 or $y > $size - 1) ? -1 : $grid[ $y * $size + $x ];
}

# for the sake of ease of transfering data between C code and perl code,
# return a set of RAYSIZE floats that otherwise would be better served as
# set of hashes

use constant {
    X        => 0,
    Y        => 1,
    HEIGHT   => 2,
    DISTANCE => 3,
    SHADING  => 4,
    OFFSET   => 5,
    LENGTH2  => 6,
    RAYSIZE  => 7,
};

sub _rayentry
{
    my %r = @_;
    my @r = (0) x RAYSIZE;
    while ( my ($k,$v) = each %r) {
            $r[$k] = $v;
    }
    return @r;
}

sub cast_perl
{
    my ($x, $y, $angle, $range) = @_;
    my $sin    = sin($angle);
    my $cos    = cos($angle);
    my $sincos = $sin / $cos;
    my $cossin = $cos / $sin;

    my @rays = _rayentry(X,$x,Y,$y,HEIGHT,-1);

    while (1) {
        my $r = @rays - RAYSIZE;

        my ( @stepx, @stepy );
        if ( $cos != 0 ) {
            my ( $x, $y ) = ($rays[$r + X], $rays[$r + Y]);
            my $dx = ($cos > 0) ? int($x + 1) - $x : ceil($x - 1) - $x;
            my $dy = $dx * $sincos;
            @stepx = _rayentry( X, $x + $dx, Y, $y + $dy, LENGTH2, $dx*$dx + $dy*$dy );
        } else {
            @stepx = _rayentry( LENGTH2, 0 + 'Inf' );
        }
        
        if ( $sin != 0 ) {
            my ( $x, $y ) = ($rays[$r + Y], $rays[$r + X]);
            my $dx = ($sin > 0) ? int($x + 1) - $x : ceil($x - 1) - $x;
            my $dy = $dx * $cossin;
            @stepy = _rayentry( Y, $x + $dx, X, $y + $dy, LENGTH2, $dx*$dx + $dy*$dy );
        } else {
            @stepy = _rayentry( LENGTH2, 0 + 'Inf' );
        }

        my ( $nextstep, $shiftx, $shifty, $distance, $offset ) = 
            ($stepx[LENGTH2] < $stepy[LENGTH2]) ?
                (\@stepx, 1, 0, $rays[$r + DISTANCE], $stepx[Y]) :
                (\@stepy, 0, 1, $rays[$r + DISTANCE], $stepy[X]);
        
        my ( $x, $y ) = map { floor($_) } (
            $nextstep->[X] - (( $cos < 0 ) ? $shiftx : 0), 
            $nextstep->[Y] - (( $sin < 0 ) ? $shifty : 0)
        );
        $nextstep->[HEIGHT]   = ($x < 0 or $x > $size - 1 or $y < 0 or $y > $size - 1) ? -1 : $y * $size + $x; 
        $nextstep->[DISTANCE] = $distance + sqrt($nextstep->[LENGTH2]);
        $nextstep->[SHADING]  = $shiftx ? ( $cos < 0 ? 2 : 0 ) : ( $sin < 0 ? 2 : 1 );
        $nextstep->[OFFSET]   = $offset - int($offset);
                    
        last if $nextstep->[DISTANCE] > $range;
        push @rays, @$nextstep;
    };
    return \@rays;
}

if ( $use_inline_c ) {
        my $caster = <<'CASTER';
#define X         0
#define Y         1
#define HEIGHT    2
#define DISTANCE  3
#define SHADING   4
#define OFFSET    5
#define LENGTH2   6
#define RAYSIZE   7

#define MAXSIZE   1024

#include <math.h>
#include <string.h>

SV*
cast_c(float x, float y, float angle, float range, int mapsize)
{
        float rays[MAXSIZE * RAYSIZE];
        float *curr = rays;
        int   size = 0;
        float asin = sin(angle);
        float acos = cos(angle);
        float sincos = asin / acos;
        float cossin = acos / asin;

        memset(rays, 0, sizeof(rays));
        rays[X] = x;
        rays[Y] = y;
        rays[HEIGHT] = -1;
        rays[DISTANCE] = 0;
        size++;
        curr += RAYSIZE;

        while (1) {
                float *r = rays + (size-1) * RAYSIZE;
                float stepx[RAYSIZE], stepy[RAYSIZE];
                float *nextstep, shiftx, shifty, distance, offset;
                if ( acos != 0.0 ) {
                        float x = r[X];
                        float y = r[Y];
                        float dx = (acos > 0.0) ? floor(x + 1.0) - x : ceil(x - 1.0) - x;
                        float dy = dx * sincos;
                        stepx[X] = x + dx;
                        stepx[Y] = y + dy;
                        stepx[LENGTH2] = dx * dx + dy * dy;
                } else {
                        stepx[LENGTH2] = 1e37;
                }
                if ( asin != 0.0 ) {
                        float x = r[Y];
                        float y = r[X];
                        float dx = (asin > 0.0) ? floor(x + 1.0) - x : ceil(x - 1.0) - x;
                        float dy = dx * cossin;
                        stepy[Y] = x + dx;
                        stepy[X] = y + dy;
                        stepy[LENGTH2] = dx * dx + dy * dy;
                } else {
                        stepy[LENGTH2] = 1e37;
                }

                if ( stepx[LENGTH2] < stepy[LENGTH2]) {
                        nextstep = stepx;
                        shiftx   = 1.0;
                        shifty   = 0.0;
                        distance = r[DISTANCE];
                        offset   = stepx[Y];
                } else {
                        nextstep = stepy;
                        shiftx   = 0.0;
                        shifty   = 1.0;
                        distance = r[DISTANCE];
                        offset   = stepy[X];
                }

                x = floor( nextstep[X] - ((acos < 0.0) ? shiftx : 0.0 ));
                y = floor( nextstep[Y] - ((asin < 0.0) ? shifty : 0.0 ));
                nextstep[HEIGHT]   = (x < 0 || x >= mapsize || y < 0 || y >= mapsize) ? -1 : y * mapsize + x;
                nextstep[DISTANCE] = distance + sqrt(nextstep[LENGTH2]);
                nextstep[SHADING]  = shiftx ? ( acos < 0.0 ? 2.0 : 0.0 ) : ( asin < 0.0 ? 2.0 : 1.0 );
                nextstep[OFFSET]   = offset - floor(offset);

                if ( nextstep[DISTANCE] > range ) break;
                memcpy( curr, nextstep, sizeof(float) * RAYSIZE );
                if ( ++size > MAXSIZE ) break;
                curr += RAYSIZE;
        }

        return newSVpv((const char *) rays, sizeof(float) * RAYSIZE * size);
}

CASTER
        print "Found Inline::C, compiling optimizing version...\n";
        eval "use Inline C => '$caster'";
        die $@ if $@;
}

sub cast { 
   $use_inline_c ?
      [unpack('f*', cast_c(@_))] :
      cast_perl(@_)
   ;
}

sub update
{
    if ( $light > 0 ) {
        my $l = $light - 10 * $seconds;
        $light = ($l < 0) ? 0 : $l;
    } elsif ( rand() * 5 < $seconds ) {
        $light = 2;
    }
}

sub draw_sky
{
    my ($cr) = @_;
    my $w = $width * $twopi / $fov;
    my $left = -$w * $direction / $twopi;
    $cr->save;

    $cr->scale( $w / $sky->get_width, $height / $sky->get_height);
    $cr->set_source_surface( $sky, int($left * $sky->get_width / $w + .5), 0 );
    $cr->paint;
    if ( $left < $w - $width ) {
        $cr->set_source_surface( $sky, int(($left + $w) * $sky->get_width / $w + .5), 0 );
        $cr->paint;
    }
    $cr->restore;

    if ($light > 0) {
        $cr->set_source_rgba(1,1,1,$light*0.1);
        $cr->rectangle(0,$height/2, $width,$height/2);
        $cr->fill;
    }
}

sub draw_columns
{
    my $cr = shift;
    for ( my $column = 0; $column < $resolution; $column++) {
        my $angle = $fov * ( $column / $resolution - 0.5 );
        my $ray   = $cast_cache->[$column] //= cast($x, $y, $direction + $angle, $range, $size);
        draw_column($column, $ray, cos($angle), $cr);
    }
}

sub draw_column
{
    my ($column, $rays, $cos_angle, $cr ) = @_;
    my $left = int( $column * $spacing );
    my $width = ceil( $spacing );
    my $hit = HEIGHT;
    $hit += RAYSIZE while $hit < @$rays && ( $rays->[$hit] < 0 || $grid[$rays->[$hit]] == 0 );
    $hit = ($hit - HEIGHT)/RAYSIZE;
    my @lines;
    my $wall_width  = $wall->get_width;
    my $wall_height = $wall->get_height;
    for ( my $s = @$rays - RAYSIZE; $s >= 0; $s -= RAYSIZE) {
        my $step         = $s/RAYSIZE;
        my $rain_drops   = $step * (rand() ** 3);
        my $cos_distance = $cos_angle * $rays->[$s + DISTANCE];
        my $bottom       = ($rain_drops > 0) ? $height / 2 * (1 + 1 / $cos_distance) : 0;
        my $rain_height  = ($rain_drops > 0) ? 0.1 * $height / $cos_distance         : 0;
        my $rain_top     = $bottom + $rain_height;
        if ( $step == $hit && $cos_distance) {
            my $texturex = int( $wall_width * $rays->[$s + OFFSET]);
            my $wproj_height = $height * $grid[$rays->[$s + HEIGHT]] / $cos_distance;
            my $wproj_top   = $bottom + $wproj_height;
            $cr->save;
            my $m = Cairo::Matrix->init_translate($texturex, 0);
            $m->scale(1/$width,$wall_height/$wproj_height);
            my $p = Cairo::SurfacePattern->create($wall);
            $p->set_matrix($m);
            $p->set_extend('pad');
            $cr->save;
            $cr->translate($left,$height - $wproj_top + $wproj_height);
            $cr->new_path;
            $cr->rectangle(0,0,$width,$wproj_height);
            $cr->clip;
            $cr->set_source($p);
            $cr->paint;
            $cr->restore;

            my $alpha = ($rays->[$s + DISTANCE] + $rays->[$s + SHADING]) / $light_range - $light;
            $alpha = 0 if $alpha < 0;
            $cr->set_source_rgba(0,0,0,$alpha);
            $cr->rectangle($left, $height - $wproj_top + $wproj_height, $width - 0, $wproj_height);
            $cr->fill;
        }
        
        $cr->set_source_rgba(1,1,1,0.15);
        while ( $draw_rain && --$rain_drops > 0 ) {
            my $top = rand() * $rain_top ;
            $cr->rectangle($left, $top, 1, $rain_height);
        }
        $cr->fill;
    }

}

sub draw_weapon 
{
    my ( $cr ) = @_;
    my $bobx = cos($paces * 2) * $scale * 6;
    my $boby = sin($paces * 4) * $scale * 6;
    my $left = $width * 0.66 + $bobx;
    my $top  = $height * 0.6 + $boby;
    my $m = Cairo::Matrix->init_identity;
    $m->scale($scale, $scale);
    $cr->transform($m); 
    $cr->set_source_surface($weapon, $left/$scale, $top/$scale);
    $cr->paint;
}


sub set_resolution($)
{
    $spacing *= $resolution;
    $resolution = shift;
    $spacing /= $resolution;
    undef $cast_cache;
}
      

my $last_time = time;
my $w = Prima::MainWindow->new(
    text => 'Cairo raycaster',
    menuItems => [
        [ '~Options' => [
            [ '~Resolution' => [
                [ '40'  => sub { set_resolution 40 } ],
                [ '80'  => sub { set_resolution 80 } ],
                [ '160' => sub { set_resolution 160 } ],
                [ '320' => sub { set_resolution 320 } ],
                [ '640' => sub { set_resolution 640 } ],
            ]],
            ['*rain' => 'R~ain' => sub { $draw_rain = shift->menu->toggle(shift) } ],
        ]],
        [],
        ['About' => sub {
                message_box("Raycaster", "Port of http://www.playfuljs.com/demos/raycaster/ by Hunter Loftis", mb::Information);
        }],
    ],

    onSize   => sub {
        my ( $self, $ox, $oy, $x, $y ) = @_;
        $width = $x;
        $height = $y;
        $spacing = $width / $resolution;
        $scale  = ( $width + $height ) / 1200;
    },
    onKeyDown => sub {
        my ( $self, $code, $key, $mod ) = @_;
           if ( $key == kb::Left  ) { rotate(-$pi*$seconds); } 
        elsif ( $key == kb::Right ) { rotate($pi*$seconds);  }
        elsif ( $key == kb::Up    ) { walk(3*$seconds);      } 
        elsif ( $key == kb::Down  ) { walk(-3*$seconds);     }
    },
    onPaint => sub {
        my ( $self, $canvas ) = @_;
        my $sf = Cairo::ImageSurface->create('rgb24', $canvas->size);
        my $cr = Cairo::Context->create($sf);
        my $matrix = Cairo::Matrix->init(
                1,      0, 
                0, -1, 
                0, $canvas->height
        );
        $cr->transform($matrix);
        update();
        draw_sky($cr);
        draw_columns($cr);
        draw_weapon($cr);

        my $f = $canvas->cairo_context;
        $f->set_source_surface($sf,0,0);
        $f->paint;


        my $t = time;
        $canvas->color(cl::White);
        $seconds = $t - $last_time;
        $canvas->text_out(sprintf("%.1d fps", 1/$seconds),0,0);
        $last_time = $t;
    },
);


$w->insert(Timer => 
    onTick => sub { $w->repaint },
    timeout => 50,
)->start;

run Prima;
