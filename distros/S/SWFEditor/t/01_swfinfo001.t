use t::Utils;
use Test::More;
use SWFEditor;

note('swf_info() test');

my $expect = <<"EXPECT";
magic=FWS  version=4  file_length=2704
 rect=(0, 0)-(240, 240) (f_size=14)
frame_rate=8.0  frame_count=40
[0] tag=SetBackgroundColor(9)  length=3
[1] tag=ShowFrame(1)
[2] tag=JPEGTables(8)
    jpeg_data_size=0
[3] tag=DefineBitsJPEG(6)  length=2133
    image_id=1  jpeg_data_size=2131
        (width, height)=(108, 80)
        SOI(0xD8): len=0
        APP0(0xE0): len=14
        DQT(0xDB): len=65
        DQT(0xDB): len=65
        SOF0(0xC0): len=15
        DHT(0xC4): len=25
        DHT(0xC4): len=61
        DHT(0xC4): len=24
        DHT(0xC4): len=42
        SOS(0xDA): len=1782
        EOI(0xD9): len=0
[4] tag=DefineShape(2)  length=51
    shape_id=2
    rect=(-49, -28)-(57, 52) (f_size=12)
    fill_style_array->count=2
    [1] type=0x41
            fill_style_bitmap
            bitmap_ref=65535
            scale=(0.997,1.004):bits=22  (has_rotate=no)
            translate=(0.00,0.00):bits=0
    [2] type=0x41
            fill_style_bitmap
            bitmap_ref=1
            scale=(0.997,1.004):bits=22  (has_rotate=no)
            translate=(-49.00,-28.00):bits=11
    line_style_array->count=0
    fill_bits_count=2  line_bits_count=0
    shape_record [0]  setup
        shape_has_{new_styles,line_styles, fill_style1, fill_style0, move_to}={0,0,1,0,1}
        shape_move_x=57.65  shape_move_y=52.30
        shape_fill_style1=2
    shape_record [1]  edge
        shape_edge_type=1  (shape_coord_size=11+2)
        shape_(x,y)=(-49.00,52.30)
    shape_record [2]  edge
        shape_edge_type=1  (shape_coord_size=10+2)
        shape_(x,y)=(-49.00,-28.00)
    shape_record [3]  edge
        shape_edge_type=1  (shape_coord_size=11+2)
        shape_(x,y)=(57.65,-28.00)
    shape_record [4]  edge
        shape_edge_type=1  (shape_coord_size=10+2)
        shape_(x,y)=(57.65,52.30)
    shape_record [5]  end
        end_of_shape
[5] tag=PlaceObject2(26)  length=9
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,1,0)
    character_id=2
    (has_scale=no)  (has_rotate=no)
    translate=(67.00,46.00):bits=12
[6] tag=ShowFrame(1)
[7] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(77.90,46.60):bits=12
[8] tag=ShowFrame(1)
[9] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(88.75,47.20):bits=12
[10] tag=ShowFrame(1)
[11] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(99.65,47.80):bits=12
[12] tag=ShowFrame(1)
[13] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(110.50,48.40):bits=13
[14] tag=ShowFrame(1)
[15] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(121.40,49.00):bits=13
[16] tag=ShowFrame(1)
[17] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(132.25,49.60):bits=13
[18] tag=ShowFrame(1)
[19] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(143.15,50.20):bits=13
[20] tag=ShowFrame(1)
[21] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,50.80):bits=13
[22] tag=ShowFrame(1)
[23] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,60.70):bits=13
[24] tag=ShowFrame(1)
[25] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,70.60):bits=13
[26] tag=ShowFrame(1)
[27] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,80.50):bits=13
[28] tag=ShowFrame(1)
[29] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,90.40):bits=13
[30] tag=ShowFrame(1)
[31] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,100.30):bits=13
[32] tag=ShowFrame(1)
[33] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,110.20):bits=13
[34] tag=ShowFrame(1)
[35] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,120.10):bits=13
[36] tag=ShowFrame(1)
[37] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,130.00):bits=13
[38] tag=ShowFrame(1)
[39] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,139.90):bits=13
[40] tag=ShowFrame(1)
[41] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(154.00,149.80):bits=13
[42] tag=ShowFrame(1)
[43] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(145.40,149.80):bits=13
[44] tag=ShowFrame(1)
[45] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(136.80,149.80):bits=13
[46] tag=ShowFrame(1)
[47] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(128.20,149.80):bits=13
[48] tag=ShowFrame(1)
[49] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(119.60,149.80):bits=13
[50] tag=ShowFrame(1)
[51] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(111.00,149.80):bits=13
[52] tag=ShowFrame(1)
[53] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(102.40,149.80):bits=13
[54] tag=ShowFrame(1)
[55] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(93.80,149.80):bits=13
[56] tag=ShowFrame(1)
[57] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(85.20,149.80):bits=13
[58] tag=ShowFrame(1)
[59] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(76.60,149.80):bits=13
[60] tag=ShowFrame(1)
[61] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,149.80):bits=13
[62] tag=ShowFrame(1)
[63] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,139.80):bits=13
[64] tag=ShowFrame(1)
[65] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,129.80):bits=13
[66] tag=ShowFrame(1)
[67] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,119.80):bits=13
[68] tag=ShowFrame(1)
[69] tag=PlaceObject2(26)  length=8
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,109.80):bits=13
[70] tag=ShowFrame(1)
[71] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,99.80):bits=12
[72] tag=ShowFrame(1)
[73] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,89.80):bits=12
[74] tag=ShowFrame(1)
[75] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,79.80):bits=12
[76] tag=ShowFrame(1)
[77] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,69.80):bits=12
[78] tag=ShowFrame(1)
[79] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,59.80):bits=12
[80] tag=ShowFrame(1)
[81] tag=DoAction(12)  length=7
    action_record =
        action list:
        Goto Frame len=2
        Play
        End
[82] tag=PlaceObject2(26)  length=7
    (clipact,clipdepth,name,ratio,coltrans,mat,cid,move)=(0,0,0,0,0,1,0,1)
    (has_scale=no)  (has_rotate=no)
    translate=(68.00,49.80):bits=12
[83] tag=ShowFrame(1)
[84] tag=End(0)
EXPECT

SKIP: {
    eval { require Capture::Tiny };
    skip 'Capture::Tiny not installed', 1 if ($@);
    tests {
        my $d1    = get_file_contents('/resource/saitama.swf');
        my $swfed = SWFEditor->new();
        $swfed->input(\$d1);
        my $got = Capture::Tiny::capture(sub{
            $swfed->swf_info();
        });
        is($got, $expect, 'swfinfo001.phpt');
    };
}

SKIP: {
    eval { require Capture::Tiny };
    skip 'Capture::Tiny not installed', 1 if ($@);
    tests {
        my $d1    = get_file_path('/resource/saitama.swf');
        my $swfed = SWFEditor->new();
        $swfed->input($d1);
        my $got = Capture::Tiny::capture(sub{
            $swfed->swf_info();
        });
        is($got, $expect, 'swfinfo001.phpt');
    };
}

done_testing();
