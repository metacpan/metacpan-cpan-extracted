BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

use SWF::Element;
use SWF::File;
use SWF::Parser;

$loaded=1;

eval{
    $new = SWF::File->new('test.swf', Version=>6);
};
print "not " if $@;
print "ok 1\n";

eval {
    $new->FrameSize(0, 0, 6400, 4800);
    $new->FrameRate(20);
    $new->compress;
};
print "not " if $@;
print "ok 2\n";

eval {
  SWF::Element::Tag::SetBackgroundColor->new(
    BackgroundColor => [
        Red => 255,
        Green => 255,
        Blue => 255,
    ]
)->pack($new);

  SWF::Element::Tag::DefineShape3->new(
    ShapeID => 1,
    ShapeBounds => [
        Xmin => -1373,
        Ymin => -1273,
        Xmax => 1313,
        Ymax => 1333,
    ],
    Shapes => [
        FillStyles => [
            [
                FillStyleType => 0,
                Color => [
                    Red => 255,
                    Green => 0,
                    Blue => 0,
                    Alpha => 255,
                  ]
            ]
        ],
        ShapeRecords => [
            [
                MoveDeltaX => -30,
                MoveDeltaY => -1240,
                FillStyle0 => 1,
            ],
            [
                ControlDeltaX => 542,
                ControlDeltaY => 0,
                AnchorDeltaX => 384,
                AnchorDeltaY => 372,
            ],
            [
                ControlDeltaX => 384,
                ControlDeltaY => 372,
                AnchorDeltaX => 0,
                AnchorDeltaY => 526,
            ],
	    [
                ControlDeltaX => 0,
                ControlDeltaY => 526,
                AnchorDeltaX => -384,
                AnchorDeltaY => 372,
            ],
            [
                ControlDeltaX => -384,
                ControlDeltaY => 372,
                AnchorDeltaX => -542,
                AnchorDeltaY => 0,
            ],
	    [
                ControlDeltaX => -542,
                ControlDeltaY => 0,
                AnchorDeltaX => -384,
                AnchorDeltaY => -372,
            ],
            [
                ControlDeltaX => -384,
                ControlDeltaY => -372,
                AnchorDeltaX => 0,
                AnchorDeltaY => -526,
            ],
            [
                ControlDeltaX => 0,
                ControlDeltaY => -526,
                AnchorDeltaX => 384,
                AnchorDeltaY => -372,
            ],
            [
                ControlDeltaX => 384,
                ControlDeltaY => -372,
                AnchorDeltaX => 542,
                AnchorDeltaY => 0,
            ],
        ],
    ],
)->pack($new);

  SWF::Element::Tag::FrameLabel->new(
    Name => 'TEST SWF',
)->pack($new);

  SWF::Element::Tag::PlaceObject2->new(
    Flags => 6,
    Depth => 2,
    CharacterID => 1,
    Matrix => [
        ScaleX => 1,
        ScaleY => 1,
        RotateSkew0 => 0,
        RotateSkew1 => 0,
        TranslateX => 3200,
        TranslateY => 2400,
    ],
)->pack($new);
  SWF::Element::Tag::ShowFrame->new(
)->pack($new);
  SWF::Element::Tag::End->new(
)->pack($new);

    $new->close;
};

print "not " if $@;
print "ok 3\n";

eval {
    $p = SWF::Parser->new( 'header-callback' =>\&header, 'tag-callback' =>\&tag );
};
print "not " if $@;
print "ok 4\n";

$tagtest=6;
$labelf=0;
$p->parse_file('test.swf');

print "not " unless $labelf;
print "ok $tagtest\n";

unlink 'test.swf';

sub header {
    my ($self, $signature, $version, $length, $xmin, $ymin, $xmax, $ymax, $framerate, $framecount ) = @_;

    print "not " if $signature ne 'CWS' or $version != 6 or $framerate != 20;
    print "ok 5\n";
}

sub tag {
    my ($self, $tagno, $length, $datastream ) = @_;

    my $element=SWF::Element::Tag->new(Tag=>$tagno, Length=>$length);
    eval {
	$element->unpack($datastream);
    };
    print "not " if ($@);
    print "ok $tagtest\n";
    $tagtest++;
    $labelf=1 if (ref($element) =~/FrameLabel/ and $element->Name eq 'TEST SWF');
}
