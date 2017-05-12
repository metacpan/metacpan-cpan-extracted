use Test;
use strict;

BEGIN { plan tests => 15 }

use SWF::Builder;
use SWF::Parser;

ok(1);

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 400], BackgroundColor => 'ffffff');

ok($m->FrameRate, 15);

my $mc = $m->new_movie_clip;

my $font;
ok(eval{$font = $mc->new_font('t/test.ttf'); 'ok'}, 'ok');

my $text = $mc->new_static_text
    ->font($font)
    ->size(20)
    ->color('ffffffaa')
    ->text('abcd')
    ;

my ($x1, $y1, $x2, $y2) = $text->get_bbox;
my $ti = $text->place;

ok($mc->{_frame_list}[0][0]{_parent}{_obj}, $text);

$ti->moveto(-($x1+$x2)/2, -($y1+$y2)/2);
$x1-=10;
$y1-=10;
$x2+=10;
$y2+=10;

my $gr = $mc->new_gradient;
$gr->add_color(   0 => '000000',
		255 => 'ff0000',
		);
my $gm = $gr->matrix;

my $border = $mc->new_shape
    ->fillstyle($gr, 'linear', $gm)
    ->linestyle(1, '000000')
    ->box($x1, $y1, $x2, $y2);

$gm->fit_to_rect(longer => ($x1,$y1,$x2,$y2))->rotate(60);
my $bi = $border->place(below=>$ti)->moveto(-($x1+$x2)/2, -($y1+$y2)/2);
my $mci = $mc->place;
$mci->moveto(200,200);
$mci->on('EnterFrame')->r_rotate(5);

ok(eval{$m->save('test.swf'); 'ok'}, 'ok');

my $p = SWF::Parser->new('header-callback' => sub{ok($_[1], 'FWS')}, 'tag-callback' => \&tag);

my @tags;

$p->parse_file('test.swf');

sub tag {
    my ($self, $tag, $length, $stream)=@_;
    my $t = SWF::Element::Tag->new(Tag=>$tag);
    my ($tagname) = $t->tag_name;

    ok(eval{$t->unpack($stream); 'ok'}, 'ok');
    push @tags, $tagname;
}

ok(join("\n", sort(@tags),''), <<TAGS);
DefineFont2
DefineShape2
DefineSprite
DefineText2
End
PlaceObject2
SetBackgroundColor
ShowFrame
TAGS

unlink('test.swf');