package PostScript::MailLabels::BasicData;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );

$VERSION = '1.30';

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

	$self->{FONTS}   = {}; # font metrics
	$self->{PAPER}   = []; # paper size names
	$self->{HEIGHT}  = {}; # paper heights in points
	$self->{WIDTH}   = {}; # paper widths in points
	$self->{POSTNET} = []; # Postscript definition for PostNet font
	$self->{DYMO}    = {}; # Avery (tm) label descriptions
	$self->{AVERY}   = {}; # Avery (tm) label descriptions
		 # layout=>[paper-size,[list of product codes], description,
		 #          number per sheet, left-offset, top-offset, width, height,
		 #			x_gap, y_gap ]
		 #			distances measured in points

    bless $self, $class;

	$self->initialize;

     return $self;
}

sub initialize {

	#	Load the data on various fonts into hashes

	my $self = shift;


	font_metrics($self);  # initialize font hash

	Calibrate($self);	# initialize Calibration code

	TestPage($self);	# initialize TestPage code

	PostNetPreamble($self);	# initialize PostNET code

		# Some standard paper sizes

	@{$self->{PAPER}} = qw( Letter Legal Ledger Tabloid A0 A1 A2 A3 A4 A5 A6 A7 A8
                 A9 B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 Envelope10 Envelope9 Envelope6_3_4
		 EnvelopeC5
                 EnvelopeDL Folio Executive Userdefined
                 Dymo-11351 Dymo-11352 Dymo-11353 Dymo-11354 Dymo-11355 Dymo-11356 
                 Dymo-14681 Dymo-30252 Dymo-30253 Dymo-30256 Dymo-30258 Dymo-30277 
                 Dymo-30299 Dymo-30320 Dymo-30321 Dymo-30323 Dymo-30324 Dymo-30325 
                 Dymo-30326 Dymo-30327 Dymo-30330 Dymo-30332 Dymo-30333 Dymo-30334 
                 Dymo-30335 Dymo-30336 Dymo-30337 Dymo-30339 Dymo-30345 Dymo-30346 
                 Dymo-30347 Dymo-30348 Dymo-30364 Dymo-30365 Dymo-30370 Dymo-30373 
                 Dymo-30374 Dymo-30376 Dymo-30383 Dymo-30384 Dymo-30387 Dymo-30854 
                 Dymo-30856 Dymo-30857 Dymo-30886 Dymo-99010 Dymo-99012 Dymo-99014 
                 Dymo-99015 Dymo-99016 Dymo-99017 Dymo-99018 Dymo-99019 

                 );

	# Dimensions of standard papers in points (1/72 inches)

	%{$self->{WIDTH}} = (  Letter => 612,     Legal => 612,
               Ledger => 1224,    Tabloid => 792,
               A0 => 2384,        A1 => 1684,
               A2 => 1191,        A3 => 842,
               A4 => 595,         A5 => 420,
               A6 => 297,         A7 => 210,
               A8 => 148,         A9 => 105,
               B0 => 2920,        B1 => 2064,
               B2 => 1460,        B3 => 1032,
               B4 => 729,         B5 => 516,
               B6 => 363,         B7 => 258,
               B8 => 181,         B9 => 127, 
               B10 => 91,         Envelope10 => 297,
	       Envelope9 => 279,  Envelope6_3_4 => 261,
               EnvelopeC5 => 461, EnvelopeDL => 312,
               Folio => 595,      Executive => 522,
               Userdefined => 0,
			 'Dymo-11351' => 64,
			 'Dymo-11352' => 154,
			 'Dymo-11353' => 72,
			 'Dymo-11354' => 90,
			 'Dymo-11355' => 144,
			 'Dymo-11356' => 252,
			 'Dymo-14681' => 188,
			 'Dymo-30252' => 252,
			 'Dymo-30253' => 252,
			 'Dymo-30256' => 288,
			 'Dymo-30258' => 198,
			 'Dymo-30277' => 248,
			 'Dymo-30299' => 64,
			 'Dymo-30320' => 252,
			 'Dymo-30321' => 252,
			 'Dymo-30323' => 286,
			 'Dymo-30324' => 198,
			 'Dymo-30325' => 424,
			 'Dymo-30326' => 221,
			 'Dymo-30327' => 248,
			 'Dymo-30330' => 144,
			 'Dymo-30332' => 72,
			 'Dymo-30333' => 72,
			 'Dymo-30334' => 90,
			 'Dymo-30335' => 86,
			 'Dymo-30336' => 154,
			 'Dymo-30337' => 252,
			 'Dymo-30339' => 203,
			 'Dymo-30345' => 180,
			 'Dymo-30346' => 136,
			 'Dymo-30347' => 108,
			 'Dymo-30348' => 90,
			 'Dymo-30364' => 288,
			 'Dymo-30365' => 252,
			 'Dymo-30370' => 169,
			 'Dymo-30373' => 144,
			 'Dymo-30374' => 252,
			 'Dymo-30376' => 144,
			 'Dymo-30383' => 504,
			 'Dymo-30384' => 540,
			 'Dymo-30387' => 756,
			 'Dymo-30854' => 188,
			 'Dymo-30856' => 292,
			 'Dymo-30857' => 288,
			 'Dymo-30886' => 126,
			 'Dymo-99010' => 252,
			 'Dymo-99012' => 252,
			 'Dymo-99014' => 286,
			 'Dymo-99015' => 198,
			 'Dymo-99016' => 221,
			 'Dymo-99017' => 144,
			 'Dymo-99018' => 539,
			 'Dymo-99019' => 539,
            );
	%{$self->{HEIGHT}} = ( Letter => 792,  Legal => 1008,
               Ledger => 792,  Tabloid => 1224,
               A0 => 3370,        A1 => 2384,
               A2 => 1684,        A3 => 1191,
               A4 => 842,         A5 => 595,
               A6 => 420,         A7 => 297,
               A8 => 210,         A9 => 148,
               B0 => 4127,        B1 => 2920,
               B2 => 2064,        B3 => 1460,
               B4 => 1032,        B5 => 729,
               B6 => 516,         B7 => 363,
               B8 => 258,         B9 => 181, 
               B10 => 127,        Envelope10 => 684,
	       Envelope9 => 639,  Envelope6_3_4 => 468,
               EnvelopeC5 => 648, EnvelopeDL => 624,
               Folio => 935,      Executive => 756,
               Userdefined => 0,
			 'Dymo-11351' => 154,
			 'Dymo-11352' => 72,
			 'Dymo-11353' => 72,
			 'Dymo-11354' => 162,
			 'Dymo-11355' => 54,
			 'Dymo-11356' => 118,
			 'Dymo-14681' => 167,
			 'Dymo-30252' => 79,
			 'Dymo-30253' => 167,
			 'Dymo-30256' => 167,
			 'Dymo-30258' => 154,
			 'Dymo-30277' => 82,
			 'Dymo-30299' => 154,
			 'Dymo-30320' => 79,
			 'Dymo-30321' => 102,
			 'Dymo-30323' => 154,
			 'Dymo-30324' => 154,
			 'Dymo-30325' => 54,
			 'Dymo-30326' => 131,
			 'Dymo-30327' => 57,
			 'Dymo-30330' => 54,
			 'Dymo-30332' => 72,
			 'Dymo-30333' => 72,
			 'Dymo-30334' => 162,
			 'Dymo-30335' => 73,
			 'Dymo-30336' => 72,
			 'Dymo-30337' => 118,
			 'Dymo-30339' => 54,
			 'Dymo-30345' => 54,
			 'Dymo-30346' => 36,
			 'Dymo-30347' => 72,
			 'Dymo-30348' => 65,
			 'Dymo-30364' => 167,
			 'Dymo-30365' => 168,
			 'Dymo-30370' => 144,
			 'Dymo-30373' => 71,
			 'Dymo-30374' => 144,
			 'Dymo-30376' => 80,
			 'Dymo-30383' => 162,
			 'Dymo-30384' => 167,
			 'Dymo-30387' => 167,
			 'Dymo-30854' => 167,
			 'Dymo-30856' => 176,
			 'Dymo-30857' => 167,
			 'Dymo-30886' => 112,
			 'Dymo-99010' => 79,
			 'Dymo-99012' => 102,
			 'Dymo-99014' => 154,
			 'Dymo-99015' => 154,
			 'Dymo-99016' => 139,
			 'Dymo-99017' => 36,
			 'Dymo-99018' => 108,
			 'Dymo-99019' => 167,

    );

 # layout=>[paper-size,[list of product codes], description,
 #          number per sheet, left-offset, top-offset, width, height,
 #			x_gap, y_gap ]
 #			distances measured in points
 # Aug 2004 updated using data from http://www.worldlabel.com
	%{$self->{AVERY}} = (
			'5096' => ['Letter',[qw/5096/], 'diskette', 9,
					9, 36, 198, 198, 0, 18,
			],
			'5160' => ['Letter',[qw/5160 8250 8560 8660/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5161' => ['Letter',[qw/5161/], 'address', 20,
					11.2464, 36, 288, 72, 11.2464, 0,
			],
			'5162' => ['Letter',[qw/5162 8252 8662/], 'address', 14,
					11.2536, 63, 285.7536, 101.2536, 13.5, 0,
			],
			'5163' => ['Letter',[qw/5163 8253 8663/], 'special', 10,
					13.5, 36, 288, 144, 9, 0,
			],
			'5164' => ['Letter',[qw/5164 8254/], 'shipping', 6,
					10.656, 36, 288, 239.76, 14.6232, 0,
			],
			'5165' => ['Letter',[qw/5165 8255 8665/], 'full sheet', 1,
					0, 0, 612, 792, 0, 0,
			],
			'5167' => ['Letter',[qw/5167 8257 8667/], 'return address', 80,
					21.3768, 36, 126, 36, 21.7512, 0,
			],
			'5190' => ['Letter',[qw/5190/], 'diskette', 15,
					13.5, 18, 192.024, 144, 4.5, 12.0744,
			],
			'5193' => ['Letter',[qw/5193/], 'special', 24,
					29.2536, 38.2536, 117, 117, 28.1232, 2.7,
			],
			'5194' => ['Letter',[qw/5194/], 'special', 12,
					29.2536, 39.3696, 176.6232, 176.6232, 18, 2.2536,
			],
			'5195' => ['Letter',[qw/5195/], 'special', 6,
					46.1232, 34.8768, 238.5, 238.5, 42.7536, 3.3768,
			],
			'5196' => ['Letter',[qw/5196/], 'diskette', 9,
					9, 36, 198, 198, 0, 18,
			],
			'5197' => ['Letter',[qw/5197/], 'special', 12,
					11.8152, 72, 288, 108, 12.3768, 0,
			],
			'5198' => ['Letter',[qw/5198/], 'audio cassette', 12,
					36, 38.2464, 252, 119.2464, 36, 0,
			],
			'5199-F' => ['Letter',[qw/5199-F/], 'VHS Face', 10,
					76.5, 65.2464, 220.5, 132.3, 18, 0,
			],
			'5199-S' => ['Letter',[qw/5199-S/], 'VHS spine', 15,
					95.6232, 33.7536, 420.7536, 48.2976, 0, 0,
			],
			'5260' => ['Letter',[qw/5260/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5261' => ['Letter',[qw/5261/], 'address', 20,
					11.2464, 36, 288, 72, 11.2464, 0,
			],
			'5262' => ['Letter',[qw/5262/], 'address', 14,
					11.2536, 63, 285.7536, 101.2536, 13.5, 0,
			],
			'5263' => ['Letter',[qw/5263/], 'shipping', 10,
					13.5, 36, 288, 144, 9, 0,
			],
			'5264' => ['Letter',[qw/5264/], 'shipping', 6,
					10.656, 36, 288, 239.76, 14.6232, 0,
			],
			'5265' => ['Letter',[qw/5265/], 'full sheet', 1,
					0, 0, 612, 792, 0, 0,
			],
	        '5266' => ['Letter', [qw/8066 8166 8366/], 'file folder', 30,
			            36, 36, 247.5, 49.5, 39.384, 0,
			 ],
			'5267' => ['Letter',[qw/5267/], 'return address', 80,
					21.3768, 36, 126, 36, 21.7512, 0,
			],
			'5293' => ['Letter',[qw/5293/], 'special', 24,
					29.2536, 38.2536, 117, 117, 28.1232, 2.7,
			],
			'5294' => ['Letter',[qw/5294/], 'special', 12,
					29.2536, 39.3696, 176.6232, 176.6232, 18, 2.2536,
			],
			'5295' => ['Letter',[qw/5295/], 'special', 6,
					46.1232, 34.8768, 238.5, 238.5, 42.7536, 3.3768,
			],
	        '5395' => ['Letter', [qw/8395/], 'name badge', 8,
			            undef, undef, undef, undef, undef, undef,
			 ],
	        '5526' => ['Letter', [qw/5526/], 'shipping label', 2,
			            0.0, 0.0, 612.0, 396.0, 0.0, 0.0,
			 ],
			'5663' => ['Letter',[qw/5663/], 'address', 10,
					0, 36, 306, 144, 0, 0,
			],
			'5667' => ['Letter',[qw/5667/], 'return address', 80,
					21.3768, 36, 126, 36, 21.7512, 0,
			],
			'5824' => ['Letter',[qw/5824/], 'CD-Rom', 2,
					144, 36, 324, 324, 0, 72,
			],
			'5896' => ['Letter',[qw/5896/], 'diskette', 9,
					9, 36, 198, 198, 0, 18,
			],
			'5960' => ['Letter',[qw/5960/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5961' => ['Letter',[qw/5961/], 'address', 20,
					11.2464, 36, 288, 72, 11.2464, 0,
			],
			'5962' => ['Letter',[qw/5962/], 'address', 14,
					11.2536, 63, 285.7536, 101.2536, 13.5, 0,
			],
			'5963' => ['Letter',[qw/5963/], 'special', 10,
					13.5, 36, 288, 144, 9, 0,
			],
			'5970' => ['Letter',[qw/5970/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5971' => ['Letter',[qw/5971/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5972' => ['Letter',[qw/5972/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5979' => ['Letter',[qw/5979/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'5980' => ['Letter',[qw/5980/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
	        '6490' => ['Letter', [qw/8096/], '3 1/2 inch diskette, non-wrap', 15,
			            undef, undef, undef, undef, undef, undef,
			 ],
			'8160' => ['Letter',[qw/8160/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'8161' => ['Letter',[qw/8161/], 'address', 20,
					11.2464, 36, 288, 72, 11.2464, 0,
			],
			'8162' => ['Letter',[qw/8162/], 'address', 14,
					11.2536, 63, 285.7536, 101.2536, 13.5, 0,
			],
			'8163' => ['Letter',[qw/8163/], 'special', 10,
					13.5, 36, 288, 144, 9, 0,
			],
			'8164' => ['Letter',[qw/8164/], 'shipping', 6,
					10.656, 36, 288, 239.76, 14.6232, 0,
			],
			'8165' => ['Letter',[qw/8165/], 'full sheet', 1,
					0, 0, 612, 792, 0, 0,
			],
			'8167' => ['Letter',[qw/8167 8667/], 'return address', 80,
					21.3768, 36, 126, 36, 21.7512, 0,
			],
			'8196' => ['Letter',[qw/8196/], 'diskette', 9,
					9, 36, 198, 198, 0, 18,
			],
			'8460' => ['Letter',[qw/8460/], 'address', 30,
					13.5, 36, 189, 72, 9, 0,
			],
			'8462' => ['Letter',[qw/8462/], 'address', 14,
					11.2536, 63, 285.7536, 101.2536, 13.5, 0,
			],
			'8463' => ['Letter',[qw/8463/], 'shipping', 10,
					13.5, 36, 288, 144, 9, 0,
			],
 			'8923' => ['Letter', [ 8923 ], 'shipping', 10, 
                    13.5, 36, 288, 144, 27, 0,
 			]
	);
	
	
	# extracted from the CUPS drivers supplied by Dymo
	# follow the links for the downloads and SDK
	# https://global.dymo.com:443/enUS/RNW/RNW.html
	%{$self->{DYMO}} = (
			'11351' => [ 'Dymo-11351', [qw/11351/], 'Jewelry Label', 1,
					0, 0, 64, 154, 0, 0
					],
			'11352' => [ 'Dymo-11352', [qw/11352/], 'Return Address Int', 1,
					0, 0, 154, 72, 0, 0
					],
			'11353' => [ 'Dymo-11353', [qw/11353/], 'Multi-Purpose', 1,
					0, 0, 72, 72, 0, 0
					],
			'11354' => [ 'Dymo-11354', [qw/11354/], 'Multi-Purpose', 1,
					0, 0, 90, 162, 0, 0
					],
			'11355' => [ 'Dymo-11355', [qw/11355/], 'Multi-Purpose', 1,
					0, 0, 144, 54, 0, 0
					],
			'11356' => [ 'Dymo-11356', [qw/11356/], 'White Name badge', 1,
					0, 0, 252, 118, 0, 0
					],
			'14681' => [ 'Dymo-14681', [qw/14681/], 'CD/DVD Label', 1,
					0, 0, 188, 167, 0, 0
					],
			'30252' => [ 'Dymo-30252', [qw/30252/], 'Address', 1,
					0, 0, 252, 79, 0, 0
					],
			'30253' => [ 'Dymo-30253', [qw/30253/], 'Address (2 up)', 1,
					0, 0, 252, 167, 0, 0
					],
			'30256' => [ 'Dymo-30256', [qw/30256/], 'Shipping', 1,
					0, 0, 288, 167, 0, 0
					],
			'30258' => [ 'Dymo-30258', [qw/30258/], 'Diskette', 1,
					0, 0, 198, 154, 0, 0
					],
			'30277' => [ 'Dymo-30277', [qw/30277/], 'File Folder (2 up)', 1,
					0, 0, 248, 82, 0, 0
					],
			'30299' => [ 'Dymo-30299', [qw/30299/], 'Jewelry Label (2 up)', 1,
					0, 0, 64, 154, 0, 0
					],
			'30320' => [ 'Dymo-30320', [qw/30320/], 'Address', 1,
					0, 0, 252, 79, 0, 0
					],
			'30321' => [ 'Dymo-30321', [qw/30321/], 'Large Address', 1,
					0, 0, 252, 102, 0, 0
					],
			'30323' => [ 'Dymo-30323', [qw/30323/], 'Shipping', 1,
					0, 0, 286, 154, 0, 0
					],
			'30324' => [ 'Dymo-30324', [qw/30324/], 'Diskette', 1,
					0, 0, 198, 154, 0, 0
					],
			'30325' => [ 'Dymo-30325', [qw/30325/], 'Video Spine', 1,
					0, 0, 424, 54, 0, 0
					],
			'30326' => [ 'Dymo-30326', [qw/30326/], 'Video Top', 1,
					0, 0, 221, 131, 0, 0
					],
			'30327' => [ 'Dymo-30327', [qw/30327/], 'File Folder', 1,
					0, 0, 248, 57, 0, 0
					],
			'30330' => [ 'Dymo-30330', [qw/30330/], 'Return Address', 1,
					0, 0, 144, 54, 0, 0
					],
			'30332' => [ 'Dymo-30332', [qw/30332/], '1 in x 1 in', 1,
					0, 0, 72, 72, 0, 0
					],
			'30333' => [ 'Dymo-30333', [qw/30333/], '1/2 in x 1 in (2 up)', 1,
					0, 0, 72, 72, 0, 0
					],
			'30334' => [ 'Dymo-30334', [qw/30334/], '2-1/4 in x 1-1/4 in', 1,
					0, 0, 90, 162, 0, 0
					],
			'30335' => [ 'Dymo-30335', [qw/30335/], '1/2 in x 1/2 in (4 up)', 1,
					0, 0, 86, 73, 0, 0
					],
			'30336' => [ 'Dymo-30336', [qw/30336/], '1 in x 2-1/8 in', 1,
					0, 0, 154, 72, 0, 0
					],
			'30337' => [ 'Dymo-30337', [qw/30337/], 'Audio Cassette', 1,
					0, 0, 252, 118, 0, 0
					],
			'30339' => [ 'Dymo-30339', [qw/30339/], '8mm Video (2 up)', 1,
					0, 0, 203, 54, 0, 0
					],
			'30345' => [ 'Dymo-30345', [qw/30345/], '3/4 in x 2-1/2 in', 1,
					0, 0, 180, 54, 0, 0
					],
			'30346' => [ 'Dymo-30346', [qw/30346/], '1/2 in x 1-7/8 in', 1,
					0, 0, 136, 36, 0, 0
					],
			'30347' => [ 'Dymo-30347', [qw/30347/], '1 in x 1-1/2 in', 1,
					0, 0, 108, 72, 0, 0
					],
			'30348' => [ 'Dymo-30348', [qw/30348/], '9/10 in x 1-1/4 in', 1,
					0, 0, 90, 65, 0, 0
					],
			'30364' => [ 'Dymo-30364', [qw/30364/], 'Name Badge Label', 1,
					0, 0, 288, 167, 0, 0
					],
			'30365' => [ 'Dymo-30365', [qw/30365/], 'Name Badge Card', 1,
					0, 0, 252, 168, 0, 0
					],
			'30370' => [ 'Dymo-30370', [qw/30370/], 'Zip Disk', 1,
					0, 0, 169, 144, 0, 0
					],
			'30373' => [ 'Dymo-30373', [qw/30373/], 'Price Tag Label', 1,
					0, 0, 144, 71, 0, 0
					],
			'30374' => [ 'Dymo-30374', [qw/30374/], 'Appointment Card', 1,
					0, 0, 252, 144, 0, 0
					],
			'30376' => [ 'Dymo-30376', [qw/30376/], 'Hanging File Insert', 1,
					0, 0, 144, 80, 0, 0
					],
			'30383' => [ 'Dymo-30383', [qw/30383/], 'PC Postage 3-Part', 1,
					0, 0, 504, 162, 0, 0
					],
			'30384' => [ 'Dymo-30384', [qw/30384/], 'PC Postage 2-Part', 1,
					0, 0, 540, 167, 0, 0
					],
			'30387' => [ 'Dymo-30387', [qw/30387/], 'PC Postage EPS', 1,
					0, 0, 756, 167, 0, 0
					],
			'30854' => [ 'Dymo-30854', [qw/30854/], 'CD Label', 1,
					0, 0, 188, 167, 0, 0
					],
			'30856' => [ 'Dymo-30856', [qw/30856/], 'Badge Card Label', 1,
					0, 0, 292, 176, 0, 0
					],
			'30857' => [ 'Dymo-30857', [qw/30857/], 'Badge Label', 1,
					0, 0, 288, 167, 0, 0
					],
			'30886' => [ 'Dymo-30886', [qw/30886/], 'CD Label', 1,
					0, 0, 126, 112, 0, 0
					],
			'99010' => [ 'Dymo-99010', [qw/99010/], 'Standard Address', 1,
					0, 0, 252, 79, 0, 0
					],
			'99012' => [ 'Dymo-99012', [qw/99012/], 'Large Address', 1,
					0, 0, 252, 102, 0, 0
					],
			'99014' => [ 'Dymo-99014', [qw/99014/], 'Shipping', 1,
					0, 0, 286, 154, 0, 0
					],
			'99015' => [ 'Dymo-99015', [qw/99015/], 'Diskette', 1,
					0, 0, 198, 154, 0, 0
					],
			'99016' => [ 'Dymo-99016', [qw/99016/], 'Video Top', 1,
					0, 0, 221, 139, 0, 0
					],
			'99017' => [ 'Dymo-99017', [qw/99017/], 'Suspension File', 1,
					0, 0, 144, 36, 0, 0
					],
			'99018' => [ 'Dymo-99018', [qw/99018/], 'Small Lever Arch', 1,
					0, 0, 539, 108, 0, 0
					],
			'99019' => [ 'Dymo-99019', [qw/99019/], 'Large Lever Arch', 1,
					0, 0, 539, 167, 0, 0
					],
		);
	
}

sub Calibrate {
	my $self = shift;

	my $calibrate = <<'CALIBRATE';
%!PS

% This code copyright 1999, Alan Jackson, alan@ajackson.org and is
% protected under the Open Source license. Code may be copied and
% modified so long as attribution to the original author is
% maintained.

% fields to replace are xcenter, ycenter (center of page in points)
% inc (either 0.1 inch or 0.1 cm in units of points)
% numx and numy : number of time to loop for x and y axes
% and pagesize

%	set the pagesize in points here
%pagesize%
gsave
%translate%

/fontsize 15 def
/Helvetica findfont fontsize scalefont setfont

%	draw x and y rules for calibration
%   ycenter will be 5.5*72 for Letter paper (8.5x11)
%	inc will be 7.2 for units = english, and 2.83465 for units = metric
/makerule { 0 %ycenter% moveto % left edge, center page
            /label (1) def
			/indx 0 def
            1 1 %numx% {
				1 1 4 {
					pop % clear index from stack
					%inc% 0 rlineto
					0 4 rlineto
					0 -4 rmoveto
				} for
				%inc% 0 rlineto
				0 6 rlineto
				0 -6 rmoveto
				1 1 4 {
					pop % clear index from stack
					%inc% 0 rlineto
					0 4 rlineto
					0 -4 rmoveto
				} for
				%inc% 0 rlineto
				0 8 rlineto
				0 4 rmoveto
				label show
				label stringwidth pop -1 mul 0 rmoveto
				/indx indx 1 add def % increment indx
				/label indx 1 add 3 string cvs def % increment label
				0 -21 rlineto
				0 9 rmoveto
			} for
            %xcenter% 0 moveto % bottom edge, center page
            /label (1) def
			/indx 0 def
			1 1 %numy% {
				1 1 4 { % minor ticks
					pop % clear index from stack
					0 %inc% rlineto
					4 0 rlineto
					-4 0 rmoveto
				} for
				0 %inc% rlineto
				6 0 rlineto
				-6 0 rmoveto
				1 1 4 {
					pop % clear index from stack
					0 %inc% rlineto
					4 0 rlineto
					-4 0 rmoveto
				} for
				0 %inc% rlineto
				8 0 rlineto
				4 0 rmoveto
				label show
				label stringwidth pop -1 mul 0 rmoveto
				/indx indx 1 add def % increment indx
				/label indx 1 add 3 string cvs def % increment label
				-20 0 rlineto
				8 0 rmoveto
			} for
			stroke
          } def

makerule % calibrate
		  
showpage
grestore
%------------- end of Calibrate definition
CALIBRATE

	$self->{CALIBRATE} = $calibrate;

	return ;
}

sub TestPage {
	my $self = shift;

	my $testpage = <<'TESTPAGE';
%!PS

% This code copyright 1999, Alan Jackson, alan@ajackson.org and is
% protected under the Open Source license. Code may be copied and
% modified so long as attribution to the original author is
% maintained.

% fields to replace are many :
% paperwidth, paperheight, boxwidth, boxheight, xgap, ygap, rows,
% cols, by (beginning y coord)
% xadjust, yadjust, and the 4 non-printing border widths,
% lbor, rbor, tbor, bbor
% and pagesize

%	set the pagesize in points here
%pagesize%
gsave
%translate%

% nominal measurements
/paperwidth %paperwidth% def % total width of paper
/paperheight %paperheight% def % total height of paper
/boxwidth %boxwidth% def  % label width
/boxheight %boxheight% def  % label height
/xgap %xgap% def % x gap between labels
/ygap %ygap% def % y gap between labels
/rows %rows% def % rows of labels on each page
/cols %cols% def % columns of labels on each page
/by %by% def % gap between top of first label and top of page

% adjustments
/xadjust %xadjust% def % adjustment if paper not x centered 
/yadjust %yadjust% def % adjustment if paper not y centered
/lbor %lbor% def % left border
/rbor paperwidth %rbor% sub def % right border coordinate
/tbor %tbor% def % top border
/bbor %bbor% def % bottom border

/lbor lbor xadjust sub store
/rbor rbor xadjust sub store

% calculated values
/bx paperwidth cols 1 sub xgap mul boxwidth cols mul add sub 2 div store % begin x

/fontsize 15 def
/Helvetica findfont fontsize scalefont setfont
1 setlinewidth

/prtnum { 3 string cvs show} def % diagnostic routine to print a number

% printable area vertically 
% if not enough room, adjust number of rows...
/rowmsg false def % print message about missing row?
rows boxheight mul by add paperheight bbor sub gt {
	/rows rows 1 sub store /rowmsg true def} if

%	draw a box
/makebox { 
           width 0            rlineto
		   gsave
		   adj_r {[5] 0 setdash} if
		   0 -1 boxheight mul rlineto stroke
		   grestore
		   0 -1 boxheight mul rmoveto
		   -1 width mul 0     rlineto
		   gsave
		   adj_l {[5] 0 setdash} if
		   0 boxheight        rlineto stroke
		   grestore
		   0 boxheight        rmoveto
		   closepath
		   stroke
         } def

/y paperheight by sub yadjust sub def % initial y position
/x bx def

% print messages about xadjust and yadjust
gsave
	2 setlinewidth
	x y moveto
	20 -20 rmoveto
	(Slide test sheet right) show
	x y moveto
	20 -40 rmoveto
	(x-adjust positive) show
	x y moveto
	20 -60 rmoveto
	60 0 rlineto 
		gsave
		-10 -5 rlineto 0 10 rlineto 10 -5 rlineto closepath fill
		grestore
	stroke

	x y moveto
	20 -20 rmoveto
	boxwidth 0 rmoveto
	gsave (Slide test sheet down) show 
	20 0 rmoveto
	0 -60 rlineto
	gsave
		-5 10 rlineto 10 0 rlineto -5 -10 rlineto closepath fill
	grestore
	stroke
	grestore
	0 -20 rmoveto
	gsave (y-adjust positive) show grestore
grestore

/boxes  { 1 1 rows {
             /x bx store
			 0 y moveto
             1 1 cols {
				/adj_l false def % was left box edge adjusted?
				/adj_r false def % was right box edge adjusted?
			    x lbor lt {/adj_l true def} if % set adjusted start x flag
				/sx x store
				adj_l {/sx lbor store} if
			    %/sx x lbor lt lbor x ifelse store % set adjusted start x
				/x x boxwidth add store
			    x rbor gt {/adj_r true def} if % set adjusted start x flag
				/ex x store
				adj_r {/se rbor store} if
				%/ex x rbor gt rbor x ifelse store % set adjusted end x
				/x x xgap add store
				/width ex sx sub store
				sx xadjust add y moveto
				makebox
			 } for
			 /y y boxheight sub ygap sub store
          } for
        } def

boxes

%	If I had to delete the bottom row, plop out a message now
rowmsg {
	paperwidth 5 div y boxheight 2 div sub moveto
	/fontsize 20 def
	/Helvetica findfont fontsize scalefont setfont
	(Bottom gap too large, last row cannot be printed) show
} if
showpage
grestore
%------------- end of TestPage definition
TESTPAGE

	$self->{TESTPAGE} = $testpage;

	return ;
}


sub PostNetPreamble {
	my $self = shift;

	my $postnet = <<'POSTNET';
% --------- This preamble which defines the PostNet barcode font is
%			entirely the work of James Cloos, and is included under
%			under the GNU General Public License - AKJ
% Copyright 1998 James H. Cloos, Jr. <cloos@jhcloos.com>
% 
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%%CreationDate: Wed Oct 21 17:00:00 1998
%%VMusage: 10288 22058
%%EndComments
13 dict begin
/FontInfo 10 dict dup begin
 /version (001.001) readonly def
 /FullName (PostNetJHC) readonly def
 /FamilyName (PostNetJHC) readonly def
 /Weight (Regular) readonly def
 /isFixedPitch false def
 /ItalicAngle 0 def
 /UnderlinePosition -100 def
 /UnderlineThickness 50 def
 /em 1000 def
 /Notice (Copyright 1998 James H. Cloos, Jr <cloos@jhcloos.com>. All rights reserved. This font comes with ABSOLUTELY NO WARRANTY. See http://www.gnu.org/copyleft/gpl.html for licensing details.) readonly def
 /URI (http://www.jhcloos.com/fonts/PostNetJHC/) readonly def
end readonly def
/FontName /PostNetJHC def
/Encoding 256 array
0 1 255 {1 index exch /.notdef put} for
dup 0 /Bit0 put
dup 1 /Bit1 put
dup 32 /space put
dup 48 /zero put
dup 49 /one put
dup 50 /two put
dup 51 /three put
dup 52 /four put
dup 53 /five put
dup 54 /six put
dup 55 /seven put
dup 56 /eight put
dup 57 /nine put
dup 64 /Bit0 put
dup 65 /Bit1 put
dup 73 /Bit1 put
dup 105 /Bit0 put
dup 108 /Bit1 put
dup 128 /Bit0 put
dup 129 /Bit1 put
readonly def
/PaintType 0 def
/FontType 1 def
/FontMatrix [0.001 0 0 0.001 0 0]  def
/FontBBox{75 0 1275 750}readonly def
%/UniqueID 4868163 def
currentdict end
currentfile eexec
D9D66F633B846A989B9974B0179FC6CC445BC38EFAFB1C60E150200B01283902
00956D5A3FA23F12B16BBE726CDB04BF5C3735C6A64EE4C726FB54193D2A9178
E8BEF86C2BD24D424E6F696123E4F6B02776289A94EC1C898CC54AACE563FBA3
DC4DF816B0BA01BECB15E83218E249909F17D372F6251AABF785B0F4F205FDEA
43B9815AA797DCBEAF168FF712ED9DCED6F0522E45460115556BBCA903296950
BD100179EFCA89CA764A610025380564661B0AE777B69B493B722AF87CA817B6
9B8ADE842CC66B8A2726B5E5983F6D6ED8227B8DACE73A6A0A1CE8CA437622DA
CE3673351FFE7AE87701DFB60BBF975D35490B82009434EBDFFA7020C63DB421
82C13809DE9604371ACBF26A53FDE357FA677206425B6FA0305F5A618CC86CE8
2C3071982E7305DFC160A58A4B0DE6D8A193C6E5216B21AFA42C0512FF5FA6C1
917259929A01B41B0165094E7D5A2F7A5A783A3D9170BF001B478FC28061CE2E
CC092EFBF740B69F81A070F74FDEFB84DD55D05668D7597476FA3742646CAFAE
116A8A31A19A5E70C4C2F1ED2F77B75562F3D48655CD461D48D3321A7B10FF68
B51966B8A2375CD1F10905AA45E9D75E7E726E057588B3DBCAF9707DA409E3A1
87B24F60F5B1F657C5655F42A78E4050C5D3848CEB00249B0515992442DC91A8
8D3FE1D0C0217C0585511F65105098EF2D52D9EEC7D8E2D80FA8AED8C2040DE5
F957131A39536951EFB522944E2DF3D5883B269ECDC990DE319638F33921836F
65E8D41801AE7DBAC1C61FF6680220518E4939CA9CFA646B8B2A96A5F77403C2
B2748756A957684E72F780029AEFB80C63EB982891241245ADAD5B9102F1A07E
B20AA2BD613BA11A3EFA25147C33C1362DE3BF8FC843DB6185280FA0E4816AD2
7E3F078A7CD8AFDF1B5B6E702264617CCB4471576CEBB5CE6CE82C3071892ABF
F6539908B0D1067748E7BC0BC4375AC8E398BD48099B7E1146009F94A3A874B8
CCE062FEF0B00AB3F47CDF9711889A829C23FAF4D8EF7C5006A95C47B02238A8
B7904D05AADA96DC48BBDC7718085EDA095425937519D129EC18921B9CBA591A
60F606DED42A871F64D678E122558CB70037E3DE179FF4C5DD9DD0683AB1E3F4
09951F2615040D45E022D7575AC3577306EDF5D20D3A4CE1BEAE331C85FABFD6
926C01F1FDB6B6761D0A0D241C7F1B1969E4B8602E43F27044510746B64A0123
ECA0060488E8C971CB071B322EB6E8FC6D5145978F709A77F13B5B6DE52808E2
4E882FD49B7066378FA5B1F1F84174BAEF8D2C98185EF0240A26213BBDA38A3A
8C13D52838CA82C2AE6ECC77D8A4F609E2AC0CFFF6D60934950634AFA6E51DFD
64F382402A876DAB67D6E2FB25599C0B43AB6AF85CD5E73A009A9C8F56A984A4
660FFF7E410F08E697FB1DF003506431C5103BDC2148F3882EE8F3FEC301966B
204A76216540DA4D03F83E01E1DCAA4F310CD0C57E74F388F7CC5DFA8FD3520D
29229A03479E037EBC482A527D6BE25D96514D3D606078C9B69A2368F220DEAA
E14C77A045B55FCDC2B6EE53D13940A4A198B93208070E94D32BF8D6E12C8B5C
0035D23CE18B8B511467538DBCB51089301C9DF636A3D8C60935F0A4222555AC
FFBDA6E29262C710D38F7CE8D3E6FD657420CD720FF4CF6C723AB0E38DF87B51
2E9B8764BC316378C7CB29A682625A940A0D160AAA1A4499C3CAC253C70946C4
4F87285646991C13
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
cleartomark
%------------- end of PostNet definition
POSTNET

	$self->{POSTNET} = $postnet;

	return ;
}

# ****************************************************************
sub font_metrics {
	#	Most of this code was pulled from the PostScript::Metrics
	#   module by Shawn Wallace

    my $self = shift;
	%{$self->{FONTS}} = (
'AvantGarde-Demi' => [
280, 280, 360, 560, 560, 860, 680, 280, 380, 380, 440, 600, 280, 420, 280, 
460, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 560, 740, 740, 580, 780, 700, 520, 480, 840, 680, 280, 480, 620, 440, 
900, 740, 840, 560, 840, 580, 520, 420, 640, 700, 900, 680, 620, 500, 320, 
640, 320, 600, 500, 280, 660, 660, 640, 660, 640, 280, 660, 600, 240, 260, 
580, 240, 940, 600, 640, 660, 660, 320, 440, 300, 600, 560, 800, 560, 580, 
460, 340, 600, 340, 600, 
],
'AvantGarde-DemiOblique' => [
280, 280, 360, 560, 560, 860, 680, 280, 380, 380, 440, 600, 280, 420, 280, 
460, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 560, 740, 740, 580, 780, 700, 520, 480, 840, 680, 280, 480, 620, 440, 
900, 740, 840, 560, 840, 580, 520, 420, 640, 700, 900, 680, 620, 500, 320, 
640, 320, 600, 500, 280, 660, 660, 640, 660, 640, 280, 660, 600, 240, 260, 
580, 240, 940, 600, 640, 660, 660, 320, 440, 300, 600, 560, 800, 560, 580, 
460, 340, 600, 340, 600, 
],
'AvantGarde-Book' => [
277, 295, 309, 554, 554, 775, 757, 351, 369, 369, 425, 606, 277, 332, 277, 
437, 554, 554, 554, 554, 554, 554, 554, 554, 554, 554, 277, 277, 606, 606, 
606, 591, 867, 740, 574, 813, 744, 536, 485, 872, 683, 226, 482, 591, 462, 
919, 740, 869, 592, 871, 607, 498, 426, 655, 702, 960, 609, 592, 480, 351, 
605, 351, 606, 500, 351, 683, 682, 647, 685, 650, 314, 673, 610, 200, 203, 
502, 200, 938, 610, 655, 682, 682, 301, 388, 339, 608, 554, 831, 480, 536, 
425, 351, 672, 351, 606, 
],
'AvantGarde-BookOblique' => [
277, 295, 309, 554, 554, 775, 757, 351, 369, 369, 425, 606, 277, 332, 277, 
437, 554, 554, 554, 554, 554, 554, 554, 554, 554, 554, 277, 277, 606, 606, 
606, 591, 867, 740, 574, 813, 744, 536, 485, 872, 683, 226, 482, 591, 462, 
919, 740, 869, 592, 871, 607, 498, 426, 655, 702, 960, 609, 592, 480, 351, 
605, 351, 606, 500, 351, 683, 682, 647, 685, 650, 314, 673, 610, 200, 203, 
502, 200, 938, 610, 655, 682, 682, 301, 388, 339, 608, 554, 831, 480, 536, 
425, 351, 672, 351, 606, 
],
'Bookman-Demi' => [
340, 360, 420, 660, 660, 940, 800, 320, 320, 320, 460, 600, 340, 360, 340, 
600, 660, 660, 660, 660, 660, 660, 660, 660, 660, 660, 340, 340, 600, 600, 
600, 660, 820, 720, 720, 740, 780, 720, 680, 780, 820, 400, 640, 800, 640, 
940, 740, 800, 660, 800, 780, 660, 700, 740, 720, 940, 780, 700, 640, 300, 
600, 300, 600, 500, 320, 580, 600, 580, 640, 580, 380, 580, 680, 360, 340, 
660, 340, 1000, 680, 620, 640, 620, 460, 520, 460, 660, 600, 800, 600, 620, 
560, 320, 600, 320, 600, 
],
'Bookman-DemiItalic' => [
340, 320, 380, 680, 680, 880, 980, 320, 260, 260, 460, 600, 340, 280, 340, 
360, 680, 680, 680, 680, 680, 680, 680, 680, 680, 680, 340, 340, 620, 600, 
620, 620, 780, 720, 720, 700, 760, 720, 660, 760, 800, 380, 620, 780, 640, 
860, 740, 760, 640, 760, 740, 700, 700, 740, 660, 1000, 740, 660, 680, 260, 
580, 260, 620, 500, 320, 680, 600, 560, 680, 560, 420, 620, 700, 380, 320, 
700, 380, 960, 680, 600, 660, 620, 500, 540, 440, 680, 540, 860, 620, 600, 
560, 300, 620, 300, 620, 
],
'Bookman-Light' => [
320, 300, 380, 620, 620, 900, 800, 220, 300, 300, 440, 600, 320, 400, 320, 
600, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 320, 320, 600, 600, 
600, 540, 820, 680, 740, 740, 800, 720, 640, 800, 800, 340, 600, 720, 600, 
920, 740, 800, 620, 820, 720, 660, 620, 780, 700, 960, 720, 640, 640, 300, 
600, 300, 600, 500, 220, 580, 620, 520, 620, 520, 320, 540, 660, 300, 300, 
620, 300, 940, 660, 560, 620, 580, 440, 520, 380, 680, 520, 780, 560, 540, 
480, 280, 600, 280, 600, 
],
'Bookman-LightItalic' => [
300, 320, 360, 620, 620, 800, 820, 280, 280, 280, 440, 600, 300, 320, 300, 
600, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 300, 300, 600, 600, 
600, 540, 780, 700, 720, 720, 740, 680, 620, 760, 800, 320, 560, 720, 580, 
860, 720, 760, 600, 780, 700, 640, 600, 720, 680, 960, 700, 660, 580, 260, 
600, 260, 600, 500, 280, 620, 600, 480, 640, 540, 340, 560, 620, 280, 280, 
600, 280, 880, 620, 540, 600, 560, 400, 540, 340, 620, 540, 880, 540, 600, 
520, 360, 600, 380, 600, 
],
'Courier-Bold' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'Courier-BoldOblique' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'Courier' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'Courier-Oblique' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'Helvetica-Bold' => [
278, 333, 474, 556, 556, 889, 722, 278, 333, 333, 389, 584, 278, 333, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 
584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 
278, 333, 584, 556, 278, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 
556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 
500, 389, 280, 389, 584, 
],
'Helvetica-Narrow-Bold' => [
228, 273, 389, 456, 456, 729, 592, 228, 273, 273, 319, 479, 228, 273, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 273, 273, 479, 479, 
479, 501, 800, 592, 592, 592, 592, 547, 501, 638, 592, 228, 456, 592, 501, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 273, 
228, 273, 479, 456, 228, 456, 501, 456, 501, 456, 273, 501, 501, 228, 228, 
456, 228, 729, 501, 501, 501, 501, 319, 456, 273, 501, 456, 638, 456, 456, 
410, 319, 230, 319, 479, 
],
'Helvetica-BoldOblique' => [
278, 333, 474, 556, 556, 889, 722, 278, 333, 333, 389, 584, 278, 333, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 
584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 
278, 333, 584, 556, 278, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 
556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 
500, 389, 280, 389, 584, 
],
'Helvetica-Narrow-BoldOblique' => [
228, 273, 389, 456, 456, 729, 592, 228, 273, 273, 319, 479, 228, 273, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 273, 273, 479, 479, 
479, 501, 800, 592, 592, 592, 592, 547, 501, 638, 592, 228, 456, 592, 501, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 273, 
228, 273, 479, 456, 228, 456, 501, 456, 501, 456, 273, 501, 501, 228, 228, 
456, 228, 729, 501, 501, 501, 501, 319, 456, 273, 501, 456, 638, 456, 456, 
410, 319, 230, 319, 479, 
],
'Helvetica' => [
278, 278, 355, 556, 556, 889, 667, 222, 333, 333, 389, 584, 278, 333, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 
584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 
278, 278, 469, 556, 222, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 
500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 
500, 334, 260, 334, 584, 
],
'Helvetica-Narrow' => [
228, 228, 291, 456, 456, 729, 547, 182, 273, 273, 319, 479, 228, 273, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 228, 228, 479, 479, 
479, 456, 832, 547, 547, 592, 592, 547, 501, 638, 592, 228, 410, 547, 456, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 228, 
228, 228, 385, 456, 182, 456, 456, 410, 456, 456, 228, 456, 456, 182, 182, 
410, 182, 683, 456, 456, 456, 456, 273, 410, 228, 456, 410, 592, 410, 410, 
410, 274, 213, 274, 479, 
],
'Helvetica-Oblique' => [
278, 278, 355, 556, 556, 889, 667, 222, 333, 333, 389, 584, 278, 333, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 
584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 
278, 278, 469, 556, 222, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 
500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 
500, 334, 260, 334, 584, 
],
'Helvetica-Narrow-Oblique' => [
228, 228, 291, 456, 456, 729, 547, 182, 273, 273, 319, 479, 228, 273, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 228, 228, 479, 479, 
479, 456, 832, 547, 547, 592, 592, 547, 501, 638, 592, 228, 410, 547, 456, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 228, 
228, 228, 385, 456, 182, 456, 456, 410, 456, 456, 228, 456, 456, 182, 182, 
410, 182, 683, 456, 456, 456, 456, 273, 410, 228, 456, 410, 592, 410, 410, 
410, 274, 213, 274, 479, 
],
'Hershey-Script-Simplex-Oblique' => [
500, 321, 571, 679, 679, 786, 857, 321, 464, 464, 536, 857, 321, 857,
286, 714, 679, 679, 679, 679, 679, 679, 679, 679, 679, 679, 321, 321,
786, 857, 786, 679, 893, 643, 750, 643, 750, 643, 643, 750, 786, 536,
464, 786, 607, 1107, 786, 679, 821, 714, 821, 643, 607, 786, 750, 929,
786, 750, 679, 429, 200, 429, 500, 500, 321, 500, 429, 321, 500, 286,
214, 464, 464, 179, 179, 429, 214, 821, 571, 429, 464, 464, 393, 321,
250, 464, 464, 679, 500, 464, 429, 429, 214, 429, 786,
],
'NewCenturySchlbk-Bold' => [
287, 296, 333, 574, 574, 833, 852, 241, 389, 389, 500, 606, 278, 333, 278, 
278, 574, 574, 574, 574, 574, 574, 574, 574, 574, 574, 278, 278, 606, 606, 
606, 500, 747, 759, 778, 778, 833, 759, 722, 833, 870, 444, 648, 815, 722, 
981, 833, 833, 759, 833, 815, 667, 722, 833, 759, 981, 722, 722, 667, 389, 
606, 389, 606, 500, 241, 611, 648, 556, 667, 574, 389, 611, 685, 370, 352, 
667, 352, 963, 685, 611, 667, 648, 519, 500, 426, 685, 611, 889, 611, 611, 
537, 389, 606, 389, 606, 
],
'NewCenturySchlbk-BoldItalic' => [
287, 333, 400, 574, 574, 889, 889, 259, 407, 407, 500, 606, 287, 333, 287, 
278, 574, 574, 574, 574, 574, 574, 574, 574, 574, 574, 287, 287, 606, 606, 
606, 481, 747, 741, 759, 759, 833, 741, 704, 815, 870, 444, 667, 778, 704, 
944, 852, 833, 741, 833, 796, 685, 722, 833, 741, 944, 741, 704, 704, 407, 
606, 407, 606, 500, 259, 667, 611, 537, 667, 519, 389, 611, 685, 389, 370, 
648, 389, 944, 685, 574, 648, 630, 519, 481, 407, 685, 556, 833, 574, 519, 
519, 407, 606, 407, 606, 
],
'NewCenturySchlbk-Roman' => [
278, 296, 389, 556, 556, 833, 815, 204, 333, 333, 500, 606, 278, 333, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 606, 606, 
606, 444, 737, 722, 722, 722, 778, 722, 667, 778, 833, 407, 556, 778, 667, 
944, 815, 778, 667, 778, 722, 630, 667, 815, 722, 981, 704, 704, 611, 333, 
606, 333, 606, 500, 204, 556, 556, 444, 574, 500, 333, 537, 611, 315, 296, 
593, 315, 889, 611, 500, 574, 556, 444, 463, 389, 611, 537, 778, 537, 537, 
481, 333, 606, 333, 606, 
],
'NewCenturySchlbk-Italic' => [
278, 333, 400, 556, 556, 833, 852, 204, 333, 333, 500, 606, 278, 333, 278, 
606, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 606, 606, 
606, 444, 747, 704, 722, 722, 778, 722, 667, 778, 833, 407, 611, 741, 667, 
944, 815, 778, 667, 778, 741, 667, 685, 815, 704, 926, 704, 685, 667, 333, 
606, 333, 606, 500, 204, 574, 556, 444, 611, 444, 333, 537, 611, 333, 315, 
556, 333, 889, 611, 500, 574, 556, 444, 444, 352, 611, 519, 778, 500, 500, 
463, 333, 606, 333, 606, 
],
'Palatino-Bold' => [
250, 278, 402, 500, 500, 889, 833, 278, 333, 333, 444, 606, 250, 333, 250, 
296, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 747, 778, 667, 722, 833, 611, 556, 833, 833, 389, 389, 778, 611, 
1000, 833, 833, 611, 833, 722, 611, 667, 778, 778, 1000, 667, 667, 667, 333, 
606, 333, 606, 500, 278, 500, 611, 444, 611, 500, 389, 556, 611, 333, 333, 
611, 333, 889, 611, 556, 611, 611, 389, 444, 333, 611, 556, 833, 500, 556, 
500, 310, 606, 310, 606, 
],
'Palatino-BoldItalic' => [
250, 333, 500, 500, 500, 889, 833, 278, 333, 333, 444, 606, 250, 389, 250, 
315, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 833, 722, 667, 685, 778, 611, 556, 778, 778, 389, 389, 722, 611, 
944, 778, 833, 667, 833, 722, 556, 611, 778, 667, 1000, 722, 611, 667, 333, 
606, 333, 606, 500, 278, 556, 537, 444, 556, 444, 333, 500, 556, 333, 333, 
556, 333, 833, 556, 556, 556, 537, 389, 444, 389, 556, 556, 833, 500, 556, 
500, 333, 606, 333, 606, 
],
'Palatino-Roman' => [
250, 278, 371, 500, 500, 840, 778, 278, 333, 333, 389, 606, 250, 333, 250, 
606, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 747, 778, 611, 709, 774, 611, 556, 763, 832, 337, 333, 726, 611, 
946, 831, 786, 604, 786, 668, 525, 613, 778, 722, 1000, 667, 667, 667, 333, 
606, 333, 606, 500, 278, 500, 553, 444, 611, 479, 333, 556, 582, 291, 234, 
556, 291, 883, 582, 546, 601, 560, 395, 424, 326, 603, 565, 834, 516, 556, 
500, 333, 606, 333, 606, 
],
'Palatino-Italic' => [
250, 333, 500, 500, 500, 889, 778, 278, 333, 333, 389, 606, 250, 333, 250, 
296, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 500, 747, 722, 611, 667, 778, 611, 556, 722, 778, 333, 333, 667, 556, 
944, 778, 778, 611, 778, 667, 556, 611, 778, 722, 944, 722, 667, 667, 333, 
606, 333, 606, 500, 278, 444, 463, 407, 500, 389, 278, 500, 500, 278, 278, 
444, 278, 778, 556, 444, 500, 463, 389, 389, 333, 556, 500, 722, 500, 500, 
444, 333, 606, 333, 606, 
],
'Symbol' => [
250, 333, 713, 500, 549, 833, 778, 439, 333, 333, 500, 549, 250, 549, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 
549, 444, 549, 722, 667, 722, 612, 611, 763, 603, 722, 333, 631, 722, 686, 
889, 722, 722, 768, 741, 556, 592, 611, 690, 439, 768, 645, 795, 611, 333, 
863, 333, 658, 500, 500, 631, 549, 549, 494, 439, 521, 411, 603, 329, 603, 
549, 549, 576, 521, 549, 549, 521, 549, 603, 439, 576, 713, 686, 493, 686, 
494, 480, 200, 480, 549, 
],
'Times-Bold' => [
250, 333, 555, 500, 500, 1000, 833, 333, 333, 333, 500, 570, 250, 333, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 
570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 
944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 
278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 
556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 
444, 394, 220, 394, 520, 
],
'Times-BoldItalic' => [
250, 389, 555, 500, 500, 833, 778, 333, 333, 333, 500, 570, 250, 333, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 
570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 
889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 
278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 
500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 
389, 348, 220, 348, 570, 
],
'Times-Roman' => [
250, 333, 408, 500, 500, 833, 778, 333, 333, 333, 500, 564, 250, 333, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 
564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 
889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 
278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 
500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 
444, 480, 200, 480, 541, 
],
'Times-Italic' => [
250, 333, 420, 500, 500, 833, 778, 333, 333, 333, 500, 675, 250, 333, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 
675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 
833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 
278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 
444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 
389, 400, 275, 400, 541, 
],
'Utopia-Bold' => [
210, 278, 473, 560, 560, 887, 748, 252, 365, 365, 442, 600, 280, 392, 280, 
378, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 456, 833, 644, 683, 689, 777, 629, 593, 726, 807, 384, 386, 707, 585, 
918, 739, 768, 650, 768, 684, 561, 624, 786, 645, 933, 634, 617, 614, 335, 
379, 335, 600, 500, 252, 544, 605, 494, 605, 519, 342, 533, 631, 316, 316, 
582, 309, 948, 638, 585, 615, 597, 440, 446, 370, 629, 520, 774, 522, 524, 
483, 365, 284, 365, 600, 
],
'Utopia-BoldItalic' => [
210, 285, 455, 560, 560, 896, 752, 246, 350, 350, 500, 600, 280, 392, 280, 
260, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 454, 828, 634, 680, 672, 774, 622, 585, 726, 800, 386, 388, 688, 586, 
921, 741, 761, 660, 761, 681, 551, 616, 776, 630, 920, 630, 622, 618, 350, 
460, 350, 600, 500, 246, 596, 586, 456, 609, 476, 348, 522, 629, 339, 333, 
570, 327, 914, 635, 562, 606, 584, 440, 417, 359, 634, 518, 795, 516, 489, 
466, 340, 265, 340, 600, 
],
'Utopia-Regular' => [
225, 242, 458, 530, 530, 838, 706, 278, 350, 350, 412, 570, 265, 392, 265, 
460, 530, 530, 530, 530, 530, 530, 530, 530, 530, 530, 265, 265, 570, 570, 
570, 389, 793, 635, 646, 684, 779, 606, 580, 734, 798, 349, 350, 658, 568, 
944, 780, 762, 600, 762, 644, 541, 621, 791, 634, 940, 624, 588, 610, 330, 
460, 330, 570, 500, 278, 523, 598, 496, 598, 514, 319, 520, 607, 291, 280, 
524, 279, 923, 619, 577, 608, 591, 389, 436, 344, 606, 504, 768, 486, 506, 
480, 340, 228, 340, 570, 
],
'Utopia-Italic' => [
225, 240, 402, 530, 530, 826, 725, 216, 350, 350, 412, 570, 265, 392, 265, 
270, 530, 530, 530, 530, 530, 530, 530, 530, 530, 530, 265, 265, 570, 570, 
570, 425, 794, 624, 632, 661, 763, 596, 571, 709, 775, 345, 352, 650, 565, 
920, 763, 753, 614, 753, 640, 533, 606, 794, 637, 946, 632, 591, 622, 330, 
390, 330, 570, 500, 216, 561, 559, 441, 587, 453, 315, 499, 607, 317, 309, 
545, 306, 912, 618, 537, 590, 559, 402, 389, 341, 618, 510, 785, 516, 468, 
468, 340, 270, 340, 570, 
],
'ZapfChancery-MediumItalic' => [
220, 280, 220, 440, 440, 680, 780, 240, 260, 220, 420, 520, 220, 280, 220, 
340, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 260, 240, 520, 520, 
520, 380, 700, 620, 600, 520, 700, 620, 580, 620, 680, 380, 400, 660, 580, 
840, 700, 600, 540, 600, 600, 460, 500, 740, 640, 880, 560, 560, 620, 240, 
480, 320, 520, 500, 240, 420, 420, 340, 440, 340, 320, 400, 440, 240, 220, 
440, 240, 620, 460, 400, 440, 400, 300, 320, 320, 460, 440, 680, 420, 400, 
440, 240, 520, 240, 520, 
],
'ZapfDingbats' => [
278, 974, 961, 974, 980, 719, 789, 790, 791, 690, 960, 939, 549, 855, 911, 
933, 911, 945, 974, 755, 846, 762, 761, 571, 677, 763, 760, 759, 754, 494, 
552, 537, 577, 692, 786, 788, 788, 790, 793, 794, 816, 823, 789, 841, 823, 
833, 816, 831, 923, 744, 723, 749, 790, 792, 695, 776, 768, 792, 759, 707, 
708, 682, 701, 826, 815, 789, 789, 707, 687, 696, 689, 786, 787, 713, 791, 
785, 791, 873, 761, 762, 762, 759, 759, 892, 892, 788, 784, 438, 138, 277, 
415, 392, 392, 668, 668, 
],


'NimbusSanL-Regu' => [
278, 278, 355, 556, 556, 889, 667, 221, 333, 333, 389, 584, 278, 584, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 
584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 
278, 278, 469, 556, 222, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 
500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 
500, 334, 260, 334, 584, 
],
'NimbusSanL-Bold' => [
278, 333, 474, 556, 556, 889, 722, 278, 333, 333, 389, 584, 278, 584, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 
584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 
278, 333, 584, 556, 278, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 
556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 
500, 389, 280, 389, 584, 
],
'NimbusSanL-ReguItal' => [
278, 278, 355, 556, 556, 889, 667, 222, 333, 333, 389, 584, 278, 584, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 
584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 
278, 278, 469, 556, 222, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 
500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 
500, 334, 260, 334, 584, 
],
'NimbusSanL-BoldItal' => [
278, 333, 474, 556, 556, 889, 722, 278, 333, 333, 389, 584, 278, 584, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 
584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 
833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 
278, 333, 584, 556, 278, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 
556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 
500, 389, 280, 389, 584, 
],
'URWGothicL-Book' => [
277, 295, 309, 554, 554, 775, 757, 351, 369, 369, 425, 606, 277, 606, 277, 
437, 554, 554, 554, 554, 554, 554, 554, 554, 554, 554, 277, 277, 606, 606, 
606, 591, 867, 740, 574, 813, 744, 536, 485, 872, 683, 226, 482, 591, 462, 
919, 740, 869, 592, 871, 607, 498, 426, 655, 702, 960, 609, 592, 480, 351, 
605, 351, 606, 500, 351, 683, 682, 647, 685, 650, 314, 673, 610, 200, 203, 
502, 200, 938, 610, 655, 682, 682, 301, 388, 339, 608, 554, 831, 480, 536, 
425, 351, 672, 351, 606, 
],
'NimbusSanL-ReguCond' => [
228, 228, 291, 456, 456, 729, 547, 182, 273, 273, 319, 479, 228, 479, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 228, 228, 479, 479, 
479, 456, 832, 547, 547, 592, 592, 547, 501, 638, 592, 228, 410, 547, 456, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 228, 
228, 228, 385, 456, 182, 456, 456, 410, 456, 456, 228, 456, 456, 182, 182, 
410, 182, 683, 456, 456, 456, 456, 273, 410, 228, 456, 410, 592, 410, 410, 
410, 274, 213, 274, 479, 
],
'URWGothicL-Demi' => [
280, 280, 360, 560, 560, 860, 680, 280, 380, 380, 440, 600, 280, 600, 280, 
460, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 560, 740, 740, 580, 780, 700, 520, 480, 840, 680, 280, 480, 620, 440, 
900, 740, 840, 560, 840, 580, 520, 420, 640, 700, 900, 680, 620, 500, 320, 
640, 320, 600, 500, 280, 660, 660, 640, 660, 640, 280, 660, 600, 240, 260, 
580, 240, 940, 600, 640, 660, 660, 320, 440, 300, 600, 560, 800, 560, 580, 
460, 340, 600, 340, 600, 
],
'NimbusSanL-BoldCond' => [
228, 273, 389, 456, 456, 729, 592, 228, 273, 273, 319, 479, 228, 479, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 273, 273, 479, 479, 
479, 501, 800, 592, 592, 592, 592, 547, 501, 638, 592, 228, 456, 592, 501, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 273, 
228, 273, 479, 456, 228, 456, 501, 456, 501, 456, 273, 501, 501, 228, 228, 
456, 228, 729, 501, 501, 501, 501, 319, 456, 273, 501, 456, 638, 456, 456, 
410, 319, 230, 319, 479, 
],
'URWGothicL-BookObli' => [
277, 295, 309, 554, 554, 775, 757, 351, 369, 369, 425, 606, 277, 606, 277, 
437, 554, 554, 554, 554, 554, 554, 554, 554, 554, 554, 277, 277, 606, 606, 
606, 591, 867, 740, 574, 813, 744, 536, 485, 872, 683, 226, 482, 591, 462, 
919, 740, 869, 592, 871, 607, 498, 426, 655, 702, 960, 609, 592, 480, 351, 
605, 351, 606, 500, 351, 683, 682, 647, 685, 650, 314, 673, 610, 200, 203, 
502, 200, 938, 610, 655, 682, 682, 301, 388, 339, 608, 554, 831, 480, 536, 
425, 351, 672, 351, 606, 
],
'NimbusSanL-ReguCondItal' => [
228, 228, 291, 456, 456, 729, 547, 182, 273, 273, 319, 479, 228, 479, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 228, 228, 479, 479, 
479, 456, 832, 547, 547, 592, 592, 547, 501, 638, 592, 228, 410, 547, 456, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 228, 
228, 228, 385, 456, 182, 456, 456, 410, 456, 456, 228, 456, 456, 182, 182, 
410, 182, 683, 456, 456, 456, 456, 273, 410, 228, 456, 410, 592, 410, 410, 
410, 274, 213, 274, 479, 
],
'URWGothicL-DemiObli' => [
280, 280, 360, 560, 560, 860, 680, 280, 380, 380, 440, 600, 280, 600, 280, 
460, 560, 560, 560, 560, 560, 560, 560, 560, 560, 560, 280, 280, 600, 600, 
600, 560, 740, 740, 580, 780, 700, 520, 480, 840, 680, 280, 480, 620, 440, 
900, 740, 840, 560, 840, 580, 520, 420, 640, 700, 900, 680, 620, 500, 320, 
640, 320, 600, 500, 280, 660, 660, 640, 660, 640, 280, 660, 600, 240, 260, 
580, 240, 940, 600, 640, 660, 660, 320, 440, 300, 600, 560, 800, 560, 580, 
460, 340, 600, 340, 600, 
],
'NimbusSanL-BoldCondItal' => [
228, 273, 389, 456, 456, 729, 592, 228, 273, 273, 319, 479, 228, 479, 228, 
228, 456, 456, 456, 456, 456, 456, 456, 456, 456, 456, 273, 273, 479, 479, 
479, 501, 800, 592, 592, 592, 592, 547, 501, 638, 592, 228, 456, 592, 501, 
683, 592, 638, 547, 638, 592, 547, 501, 592, 547, 774, 547, 547, 501, 273, 
228, 273, 479, 456, 228, 456, 501, 456, 501, 456, 273, 501, 501, 228, 228, 
456, 228, 729, 501, 501, 501, 501, 319, 456, 273, 501, 456, 638, 456, 456, 
410, 319, 230, 319, 479, 
],
'URWBookmanL-Ligh' => [
320, 300, 380, 620, 620, 900, 800, 220, 300, 300, 440, 600, 320, 600, 320, 
600, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 320, 320, 600, 600, 
600, 540, 820, 680, 740, 740, 800, 720, 640, 800, 800, 340, 600, 720, 600, 
920, 740, 800, 620, 820, 720, 660, 620, 780, 700, 960, 720, 640, 640, 300, 
600, 300, 600, 500, 220, 580, 620, 520, 620, 520, 320, 540, 660, 300, 300, 
620, 300, 940, 660, 560, 620, 580, 440, 520, 380, 680, 520, 780, 560, 540, 
480, 280, 600, 280, 600, 
],
'NimbusRomNo9L-Regu' => [
250, 333, 408, 500, 500, 833, 778, 333, 333, 333, 500, 564, 250, 564, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 
564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 
889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 
278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 
500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 
444, 480, 200, 480, 541, 
],
'URWBookmanL-DemiBold' => [
340, 360, 420, 660, 660, 940, 800, 320, 320, 320, 460, 600, 340, 600, 340, 
600, 660, 660, 660, 660, 660, 660, 660, 660, 660, 660, 340, 340, 600, 600, 
600, 660, 820, 720, 720, 740, 780, 720, 680, 780, 820, 400, 640, 800, 640, 
940, 740, 800, 660, 800, 780, 660, 700, 740, 720, 940, 780, 700, 640, 300, 
600, 300, 600, 500, 320, 580, 600, 580, 640, 580, 380, 580, 680, 360, 340, 
660, 340, 1000, 680, 620, 640, 620, 460, 520, 460, 660, 600, 800, 600, 620, 
560, 320, 600, 320, 600, 
],
'NimbusRomNo9L-Medi' => [
250, 333, 555, 500, 500, 1000, 833, 333, 333, 333, 500, 570, 250, 570, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 
570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 
944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 
278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 
556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 
444, 394, 220, 394, 520, 
],
'URWBookmanL-LighItal' => [
300, 320, 360, 620, 620, 800, 820, 280, 280, 280, 440, 600, 300, 600, 300, 
600, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 300, 300, 600, 600, 
600, 540, 780, 700, 720, 720, 740, 680, 620, 760, 800, 320, 560, 720, 580, 
860, 720, 760, 600, 780, 700, 640, 600, 720, 680, 960, 700, 660, 580, 260, 
600, 260, 600, 500, 280, 620, 600, 480, 640, 540, 340, 560, 620, 280, 280, 
600, 280, 880, 620, 540, 600, 560, 400, 540, 340, 620, 540, 880, 540, 600, 
520, 360, 600, 380, 600, 
],
'NimbusRomNo9L-ReguItal' => [
250, 333, 420, 500, 500, 833, 778, 333, 333, 333, 500, 675, 250, 675, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 
675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 
833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 
278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 
444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 
389, 400, 275, 400, 541, 
],
'URWBookmanL-DemiBoldItal' => [
340, 320, 380, 680, 680, 880, 980, 320, 260, 260, 460, 600, 340, 600, 340, 
360, 680, 680, 680, 680, 680, 680, 680, 680, 680, 680, 340, 340, 620, 600, 
620, 620, 780, 720, 720, 700, 760, 720, 660, 760, 800, 380, 620, 780, 640, 
860, 740, 760, 640, 760, 740, 700, 700, 740, 660, 1000, 740, 660, 680, 260, 
580, 260, 620, 500, 320, 680, 600, 560, 680, 560, 420, 620, 700, 380, 320, 
700, 380, 960, 680, 600, 660, 620, 500, 540, 440, 680, 540, 860, 620, 600, 
560, 300, 620, 300, 620, 
],
'NimbusRomNo9L-MediItal' => [
250, 389, 555, 500, 500, 833, 778, 333, 333, 333, 500, 570, 250, 606, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 
570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 
889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 
278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 
500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 
389, 348, 220, 348, 570, 
],
'CharterBT-Bold' => [
291, 340, 339, 736, 581, 888, 741, 255, 428, 428, 500, 833, 289, 833, 289, 
491, 581, 581, 581, 581, 581, 581, 581, 581, 581, 581, 340, 340, 833, 833, 
833, 487, 917, 651, 628, 638, 716, 596, 552, 710, 760, 354, 465, 650, 543, 
883, 727, 752, 587, 752, 671, 568, 603, 705, 635, 946, 637, 610, 592, 443, 
491, 443, 1000, 500, 255, 544, 577, 476, 596, 524, 341, 551, 597, 305, 297, 
553, 304, 892, 605, 577, 591, 575, 421, 447, 358, 600, 513, 799, 531, 515, 
495, 493, 500, 493, 833, 
],
'NimbusMonL-Regu' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'CharterBT-BoldItalic' => [
293, 340, 339, 751, 586, 898, 730, 261, 420, 420, 500, 833, 292, 833, 294, 
481, 586, 586, 586, 586, 586, 586, 586, 586, 586, 586, 346, 346, 833, 833, 
833, 492, 936, 634, 628, 625, 702, 581, 539, 693, 747, 353, 474, 653, 529, 
894, 712, 729, 581, 729, 645, 553, 584, 701, 617, 921, 608, 586, 572, 449, 
481, 449, 1000, 500, 261, 572, 556, 437, 579, 464, 325, 517, 595, 318, 297, 
559, 307, 883, 600, 550, 565, 562, 449, 403, 366, 599, 492, 768, 510, 494, 
465, 487, 500, 487, 833, 
],
'NimbusMonL-Bold' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'CharterBT-Roman' => [
278, 338, 331, 745, 556, 852, 704, 201, 417, 417, 500, 833, 278, 833, 278, 
481, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 319, 319, 833, 833, 
833, 486, 942, 639, 604, 632, 693, 576, 537, 694, 738, 324, 444, 611, 520, 
866, 713, 731, 558, 731, 646, 556, 597, 694, 618, 928, 600, 586, 586, 421, 
481, 421, 1000, 500, 201, 507, 539, 446, 565, 491, 321, 523, 564, 280, 266, 
517, 282, 843, 568, 539, 551, 531, 382, 400, 334, 569, 494, 771, 503, 495, 
468, 486, 500, 486, 833, 
],
'CharterBT-Italic' => [
278, 338, 331, 745, 556, 852, 704, 201, 419, 419, 500, 833, 278, 833, 278, 
481, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 319, 319, 833, 833, 
833, 486, 942, 606, 588, 604, 671, 546, 509, 664, 712, 312, 447, 625, 498, 
839, 683, 708, 542, 708, 602, 537, 565, 664, 590, 898, 569, 562, 556, 421, 
481, 421, 1000, 500, 201, 525, 507, 394, 523, 424, 292, 481, 551, 287, 269, 
514, 275, 815, 556, 502, 516, 512, 398, 370, 333, 553, 454, 713, 477, 475, 
440, 486, 500, 486, 833, 
],
'NimbusMonL-ReguObli' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'CenturySchL-Roma' => [
278, 296, 389, 556, 556, 833, 815, 204, 333, 333, 500, 606, 278, 606, 278, 
278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 606, 606, 
606, 444, 737, 722, 722, 722, 778, 722, 667, 778, 833, 407, 556, 778, 667, 
944, 815, 778, 667, 778, 722, 630, 667, 815, 722, 981, 704, 704, 611, 333, 
606, 333, 606, 500, 204, 556, 556, 444, 574, 500, 333, 537, 611, 315, 296, 
593, 315, 889, 611, 500, 574, 556, 444, 463, 389, 611, 537, 778, 537, 537, 
481, 333, 606, 333, 606, 
],
'NimbusMonL-BoldObli' => [
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 
600, 600, 600, 600, 600, 
],
'CenturySchL-Bold' => [
287, 296, 333, 574, 574, 833, 852, 241, 389, 389, 500, 606, 278, 606, 278, 
278, 574, 574, 574, 574, 574, 574, 574, 574, 574, 574, 278, 278, 606, 606, 
606, 500, 747, 759, 778, 778, 833, 759, 722, 833, 870, 444, 648, 815, 722, 
981, 833, 833, 759, 833, 815, 667, 722, 833, 759, 981, 722, 722, 667, 389, 
606, 389, 606, 500, 241, 611, 648, 556, 667, 574, 389, 611, 685, 370, 352, 
667, 352, 963, 685, 611, 667, 648, 519, 500, 426, 685, 611, 889, 611, 611, 
537, 389, 606, 389, 606, 
],
'URWPalladioL-Roma' => [
250, 278, 371, 500, 500, 840, 778, 278, 333, 333, 389, 606, 250, 606, 250, 
606, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 747, 778, 611, 709, 774, 611, 556, 763, 832, 337, 333, 726, 611, 
946, 831, 786, 604, 786, 668, 525, 613, 778, 722, 1000, 667, 667, 667, 333, 
606, 333, 606, 500, 278, 500, 553, 444, 611, 479, 333, 556, 582, 291, 234, 
556, 291, 883, 582, 546, 601, 560, 395, 424, 326, 603, 565, 834, 516, 556, 
500, 333, 606, 333, 606, 
],
'CenturySchL-Ital' => [
278, 333, 400, 556, 556, 833, 852, 204, 333, 333, 500, 606, 278, 606, 278, 
606, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 606, 606, 
606, 444, 747, 704, 722, 722, 778, 722, 667, 778, 833, 407, 611, 741, 667, 
944, 815, 778, 667, 778, 741, 667, 685, 815, 704, 926, 704, 685, 667, 333, 
606, 333, 606, 500, 204, 574, 556, 444, 611, 444, 333, 537, 611, 333, 315, 
556, 333, 889, 611, 500, 574, 556, 444, 444, 352, 611, 519, 778, 500, 500, 
463, 333, 606, 333, 606, 
],
'URWPalladioL-Bold' => [
250, 278, 402, 500, 500, 889, 833, 278, 333, 333, 444, 606, 250, 606, 250, 
296, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 747, 778, 667, 722, 833, 611, 556, 833, 833, 389, 389, 778, 611, 
1000, 833, 833, 611, 833, 722, 611, 667, 778, 778, 1000, 667, 667, 667, 333, 
606, 333, 606, 500, 278, 500, 611, 444, 611, 500, 389, 556, 611, 333, 333, 
611, 333, 889, 611, 556, 611, 611, 389, 444, 333, 611, 556, 833, 500, 556, 
500, 310, 606, 310, 606, 
],
'CenturySchL-BoldItal' => [
287, 333, 400, 574, 574, 889, 889, 259, 407, 407, 500, 606, 287, 606, 287, 
278, 574, 574, 574, 574, 574, 574, 574, 574, 574, 574, 287, 287, 606, 606, 
606, 481, 747, 741, 759, 759, 833, 741, 704, 815, 870, 444, 667, 778, 704, 
944, 852, 833, 741, 833, 796, 685, 722, 833, 741, 944, 741, 704, 704, 407, 
606, 407, 606, 500, 259, 667, 611, 537, 667, 519, 389, 611, 685, 389, 370, 
648, 389, 944, 685, 574, 648, 630, 519, 481, 407, 685, 556, 833, 574, 519, 
519, 407, 606, 407, 606, 
],
'URWPalladioL-Ital' => [
250, 333, 500, 500, 500, 889, 778, 278, 333, 333, 389, 606, 250, 606, 250, 
296, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 500, 747, 722, 611, 667, 778, 611, 556, 722, 778, 333, 333, 667, 556, 
944, 778, 778, 611, 778, 667, 556, 611, 778, 722, 944, 722, 667, 667, 333, 
606, 333, 606, 500, 278, 444, 463, 407, 500, 389, 278, 500, 500, 278, 278, 
444, 278, 778, 556, 444, 500, 463, 389, 389, 333, 556, 500, 722, 500, 500, 
444, 333, 606, 333, 606, 
],
'Dingbats' => [
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
278, 278, 278, 278, 278, 
],
'URWPalladioL-BoldItal' => [
250, 333, 500, 500, 500, 889, 833, 278, 333, 333, 444, 606, 250, 606, 250, 
315, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 250, 250, 606, 606, 
606, 444, 833, 722, 667, 685, 778, 611, 556, 778, 778, 389, 389, 722, 611, 
944, 778, 833, 667, 833, 722, 556, 611, 778, 667, 1000, 722, 611, 667, 333, 
606, 333, 606, 500, 278, 556, 537, 444, 556, 444, 333, 500, 556, 333, 333, 
556, 333, 833, 556, 556, 556, 537, 389, 444, 389, 556, 556, 833, 500, 556, 
500, 333, 606, 333, 606, 
],
'StandardSymL' => [
250, 333, 250, 500, 250, 833, 778, 250, 333, 333, 250, 549, 250, 549, 250, 
278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 
549, 444, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 
250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 
250, 333, 250, 500, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 
250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 
250, 480, 200, 480, 250, 
],
'URWChanceryL-MediItal' => [
220, 280, 220, 440, 440, 680, 780, 240, 260, 220, 420, 520, 220, 520, 220, 
340, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 260, 240, 520, 520, 
520, 380, 700, 620, 600, 520, 700, 620, 580, 620, 680, 380, 400, 660, 580, 
840, 700, 600, 540, 600, 600, 460, 500, 740, 640, 880, 560, 560, 620, 240, 
480, 320, 520, 500, 240, 420, 420, 340, 440, 340, 320, 400, 440, 240, 220, 
440, 240, 620, 460, 400, 440, 400, 300, 320, 320, 460, 440, 680, 420, 400, 
440, 240, 520, 240, 520, 
],
'PostNetJHC' => [
1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,
1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,
1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,
1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,1350,
270,270,270,270,270,270,270,270,270,270,270,270,270,270,270,
270,270,270,270,270,270,270,270,270,270,270,270,270,270,270,
270,270,270,270,270,270,270,270,270,270,270,270,270,270,270,
270,270,270,270,270,
],
);
}

sub stringwidth {
   my ($self,$string, $fontname, $fontsize) = @_;
   my $returnval = 0;
  
   foreach my $char (unpack("C*",$string)) {
       $returnval+=$self->{FONTS}{$fontname}->[$char-32];
   }
   return ($returnval*$fontsize/1000);

}


sub ListFonts {
	my $self = shift;
    my @tmp = %{$self->{FONTS}};
    my @returnval =();
    while (@tmp) {
        push @returnval, shift(@tmp);   
	shift @tmp;
    }
    return sort( {$a cmp $b;} @returnval);
}

1;
__END__

=head1 NAME

PostScript::MailLabels::BasicData - Basic data that is used by the MailLabels
                                    module. 

=head1 SYNOPSIS

	Loads up a few basic data items :

	Font metrics

	PS code for generating a calibration page

	PS code for generating a test page

	PS code for PostNET font

	Standard paper sizes

	Specs for Avery (tm) forms (incomplete)

=head1 DESCRIPTION

	All this does is initialize a bunch of data items. Not intended to be
	used by normal people. It just makes the MailLabel.pm code more
	compact. The documentation is probably not too complete.

	Note that the font metrics camne from PostScript::Metrics by Shawn Wallace.
	The PostNET barcode font came from James H. Cloos, Jr.

=head1 EXAMPLE

  require PostScript::MailLabels::BasicData;

  $data = new PostScript::MailLabels::BasicData;

	$code = '8460';
  @layout = @{$data{AVERY}{$code}};

 # layout=>[paper-size,[list of product codes], description,
 #          number per sheet, left-offset, top-offset, width, height]
 #			distances measured in points

 $testpage = $data{TESTPAGE};

=head1 REVISION HISTORY

    Version 1.30 Mon Nov 17 20:36:36 CST 2008
    Add Dymo label data (patch from brian d foy)
    Version 1.23 Mon Oct 20 20:09:09 CDT 2008
    Patch had an error - repired.
    Version 1.22 Sun Oct 19 16:22:56 CDT 2008
    Added Avery 8923 per patch from brian d. foy
    Added Userdefined hook for paper size per request of Jim Albert
	Version 1.21 Tue Nov 29 20:55:38 CST 2005
	Added Avery 5526 labels per request of Wallace Winfrey
	Version 1.20 - August 2005
	Added patch from Jonathan Kamens
	Version 1.10 - August 2004
	Added 5167 Avery stock
	Version 1.02 - January 2001
	Fixed calibration axis labels to work for arbitrary paper size
	Added y_gap to Avery data
	Version 1.01 - December 2000
	Added pagesize parameter to handle paper other than Letter.
	Added more axis labels so that A4 calibration plot would work.


=head1 AUTHOR

    Alan Jackson
    October 1999
    alan@ajackson.org

=head1 SEE ALSO


=cut
