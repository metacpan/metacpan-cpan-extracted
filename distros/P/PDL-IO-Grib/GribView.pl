#!/usr/local/perl5/bin/perl
=head1 NAME

GribView.pl - script to view Grib Record Headers

=head1 DESCRIPTION

GribView.pl currently allows the user to browse Grib record headers and 
view the fields as interpreted by the PDL::IO::Grib package.  Maybe one day 
it could also edit the headers, view the data, and allow exports to other formats.

=cut
use blib;
use strict;
use warnings;
use Tk;
use Tk::FileDialog;
use PDL::IO::Grib;

$PDL::IO::Grib::debug=1;

my $pgplot;
my $trid;
BEGIN{
  $ENV{PGPLOT_DEV}=$^O =~ /MSWin32/ ? '/GW' : "/XSERVE";
  $ENV{PGPLOT_DIR}="/usr/local/pgplot/" if(!defined($ENV{PGPLOT_DIR}) and -e "/usr/local/pgplot");
  eval "use PGPLOT";
  if($@ ne ""){
    print "Could not load PGPLOT\n";
  }else{
    eval "use PDL::Graphics::PGPLOT";
    if($@ ne ""){
      print "PDL::Graphics::PGPLOT not found \n";
    }else{
      $pgplot=1;
    }
  }
  eval "use PDL::Graphics::TriD";
  if($@ ne ""){
    print "Could not load TriD\n";
  }else{
	 $trid=1;
  } 
}

my $TkObjects;
my $GribFile;
my $Field;
my $section;
my $debug;

$TkObjects->{MainWindow} = MainWindow->new( );

$TkObjects->{TLFrame1} = $TkObjects->{MainWindow}->Frame()->pack(-side=>'top',-fill=>'x');
$TkObjects->{TLFrame2} = $TkObjects->{MainWindow}->Frame(-width=>100,
																			-height=>300,
																		  -label=>'Field Identifiers')->pack(-side=>'left',-fill=>'both');
$TkObjects->{TLFrame3} = $TkObjects->{MainWindow}->Frame()->pack(-side=>'top',-fill=>'both');
$TkObjects->{TLFrame4} = $TkObjects->{MainWindow}->Frame()->pack(-side=>'top',-fill=>'both');


$TkObjects->{PDSFrame} = $TkObjects->{TLFrame3}->Frame(-label=>'PDS Section'
																		  )->pack(-side=>'left',
																					 -fill=>'both');
$TkObjects->{GDSFrame} = $TkObjects->{TLFrame3}->Frame(
																			-label=>'GDS Section'
																		  )->pack(-side=>'left',
																					 -fill=>'both');
$TkObjects->{BMSFrame} = $TkObjects->{TLFrame4}->Frame(-label=>'BMS Section'
																		  )->pack(-side=>'left',
																					 -fill=>'both');
$TkObjects->{BDSFrame} = $TkObjects->{TLFrame4}->Frame(
																			-label=>'BDS Section'
																		  )->pack(-side=>'left',
																					 -fill=>'both');

use constant PDS_DEFAULTS => {1=> {name=> 'PDS Length',
											  type=> 'uint3'},
										4=> {name=> 'Parameter Table Version'},
										5=> {name=> 'Center ID'},
										6=> {name=> 'Generating Process ID'},
										7=> {name=> 'Grid ID'},
										8=> {name=> 'GDS/BMS Flag',
											  type=>'bits'},
										9=> {name=> 'Parameter and units ID'},
										10=> {name=> 'Type of level or layer'},
										11=> {name=> 'Level top'},
										12=> {name=> 'Level bottom'},
										13=> {name=> 'Year'},
										14=> {name=> 'Month'},
										15=> {name=> 'Day'},
										16=> {name=> 'Hour'},
										17=> {name=> 'Minute'},
										18=> {name=> 'Forecast time unit'},
										19=> {name=> 'Forecast Time'},
										20=> {name=> 'Time Step'},
										21=> {name=> 'Time Range'},
										22=> {name=> 'Number in Average',
												type=> 'uint2'},
										24=> {name=> 'Number missing from Average'},
										25=> {name=> 'Century of initial time'},
										26=> {name=> 'Sub-center ID'},
										27=> {name=> 'Decimal Scale Factor',
												type=> 'int2'}};



use constant GDS_DEFAULTS => {1=> {name=>'GDS Length',
											  type=>'uint3'},
										4=> {name=>'Number of vertical coordinate parameters'},
										5=> {name=>'Location of vertical coordinate parameters'}, 	  
										6=> {name=>'Data representation type'},
										7=> {name=>'Ni Number of points on a Latitude',
											  type=>'uint2'},
										9=>  {name=>'Nj Number of points on a Longitude',
												type => 'uint2'},
										11=> {name=>'latitude of first point',
												type => 'int3'},
										14=> {name=>'longitude of first point',
												type => 'int3'},
										17=> {name=>'Resolution and component flag',
												type=>'bits'},
										18=> {name=>'latitude of last gridpoint',
												type => 'int3'},
										21=> {name=>'longitude of last gridpoint',
												type => 'int3'},
										24=> {name=>'Longitude increment',
												type => 'int2'},
										26=> {name=>'Latitude direction increment',
												type => 'int2'},
										28=> {name=>'Scanning mode flags',
												type => 'bits'}};

use constant BMS_DEFAULTS => {1=> {name=>'BMS Length',
											  type=>'uint3'},
										4=> {name=>'unused bit count'},
										5=> {name=>'bms usage flag',
											  type=>'uint2'}};


use constant BDS_DEFAULTS => {1=> {name=>'BDS Length',
											  type=>'uint3'},
										4=> {name=>'flags',
											  type=>'bits'},
										5=> {name=>'binary scale factor',
											  type=>'int2'},
										7=> {name=>'reference value',
											  type=>'float'},
										11=>{name=>'bits per value'}};

my $types={PDS=>PDS_DEFAULTS,
			  GDS=>GDS_DEFAULTS,
			  BMS=>BMS_DEFAULTS,
			  BDS=>BDS_DEFAULTS};

						  

$TkObjects->{Open} =  $TkObjects->{TLFrame1}->Menubutton(-text=>'FILE ',
							 -relief=>'raised',
							 -menuitems => [[ command => "Open",
									  -command=>[\&opengrib]],
									[ command => "Exit",-command=> sub {exit}]]);
$TkObjects->{Open}->pack(-side=>'left',-anchor=>'nw',-fill=>'y');
if($pgplot or $trid){
  $TkObjects->{View} =  $TkObjects->{TLFrame1}->Menubutton(-text=>'VIEW DATA',
																			-relief=>'raised')->pack(-side=>'left',-anchor=>'nw',-fill=>'y');
  if($pgplot){																									
	 $TkObjects->{View}->command(-label=>'PGPLOT Contour', -command=>[\&pgplot_contour]);
  }
  if($trid){
	 $TkObjects->{View}->command(-label=>'TriD Contour', -command=>[\&trid_contour]);
  }
#  $TkObjects->{View_mb}->pack(-side=>'left',-anchor=>'nw',-fill=>'y');
}


$TkObjects->{ListBox} =  $TkObjects->{TLFrame2}->Scrolled("Listbox",
																			 -scrollbars=>"oe",
																			 -height=>22,
																			 -width=>26);
$TkObjects->{ListBox}->pack(-fill=>'both');

$TkObjects->{ListBox}->bind('<Button-1>', 
									 [ \&FieldSelect, Ev('y') ]);

foreach my $section (qw(PDS GDS BMS BDS)){
  
  $TkObjects->{$section."Scroll"} = $TkObjects->{$section."Frame"}->Scrollbar();
  $TkObjects->{$section."Listboxes"} = [ $TkObjects->{$section."Frame"}->Listbox(-width=>30),
													  $TkObjects->{$section."Frame"}->Listbox() ];
  
  foreach my $list (@{$TkObjects->{$section."Listboxes"}}){
	 $list->configure(-yscrollcommand => [ \&scroll_listboxes, 
														$TkObjects->{$section."Scroll"},
														$list, $TkObjects->{$section."Listboxes"}]);
  }
  $TkObjects->{$section."Scroll"}->configure(-command=> sub { 
															  foreach my $list (@{$TkObjects->{$section."Listboxes"}}){
																 $list->yview(@_);}});

  foreach my $list (@{$TkObjects->{$section."Listboxes"}}){
	 $list->pack(-side=>'left'); 
  }
  $TkObjects->{$section."Scroll"}->pack(-side=>'left',-fill=>'y');

}


MainLoop;



sub opengrib {
  my $path = '.';
  
  my($LoadDialog) = $TkObjects->{MainWindow}->FileDialog(-Title =>'Choose an input file',
												-Create => 0);

  my $file = $LoadDialog->Show(-Path=>$path);
  return unless(defined $file);

  
  print "HERE $path $file\n" if($debug);

  if($file =~ /([^\/]+).gz$/){
	 my $nfile="/tmp/$1";
	 system("gzip -cd $file > $nfile");
	 if(-e $nfile){
		$file = $nfile;
	 }else{
		print "Unable to decompress $file at ",__FILE__," ",__LINE__,"\n";
		return;
	 }
  }

    
  $GribFile = new PDL::IO::Grib($file);

  $TkObjects->{MainWindow}->title("GribView: $file");  
  
  
  $TkObjects->{ListBox}->delete(0,"end");
  foreach(sort idsort keys %$GribFile){
	 next if(/^_/);
    my $name = $GribFile->{$_}->name();
	 if(defined $name){
		$TkObjects->{ListBox}->insert("end",sprintf("%-16.16s %s",$_,$name));
	 }else{
		$TkObjects->{ListBox}->insert("end",$_);
	 }
  }

}

sub FieldSelect{
  my($lb,$y) = @_;

  my $val = $lb->get($lb->nearest($y));
  $val =~ s/\s+.*$//;

  $Field=$GribFile->{$val};

  foreach (qw(PDS GDS BMS BDS)){
#  foreach (qw(PDS )){
	 $section = $_;
	 ShowSection();
  }
  my $data = $Field->read_data($GribFile->{_FILEHANDLE});
  print join(' ',$data->stats),"\n";

}

sub ShowSection{
  
  my $f = $Field;
  return unless defined $f->{$section};
  
  my $wcnt = $f->{$section}->nelem;

  my $shown=0;

  $types->{GDS} = lookup_gds_types($f->gds_attribute(4),
											  $f->gds_attribute(5),
											  $f->gds_attribute(6)) if($section eq 'GDS');

  foreach(@ { $TkObjects->{$section."Listboxes"}}){
	 # empty before refilling
	 $_->delete(0,'end');
  }

  foreach my $num (1..$wcnt){
	 my $val;

    my $dtype = $types->{$section}{$num}{type};

 	 if($shown-- <= 0){
		if(defined $dtype){
		  my($o,$l);
		  $o=$num-1;
		  if($dtype eq 'uint3'){
			 $l=$o+2;
			 $val = $f->{$section}->slice("$o:$l")->unpackint3();
			 $shown=2;
		  }elsif($dtype eq 'int3'){
			 $l=$o+2;
			 $val = $f->{$section}->slice("$o:$l")->unpackint3('signed');
			 $shown=2;
		  }elsif($dtype eq 'uint2'){
			 $l=$o+1;
			 $val = $f->{$section}->slice("$o:$l")->unpackint2();
			 $shown=1;
		  }elsif($dtype eq 'int2'){
			 $l=$o+1;
			 $val = $f->{$section}->slice("$o:$l")->unpackint2('signed');
			 $shown=1;
		  }elsif($dtype eq 'float'){
			 $l=$o+3;
			 $val = sprintf("%f",PDL::IO::Grib::Wgrib::decode_ref_val($f->{$section}->slice("$o:$l")));
			 $shown=3;
		  }elsif($dtype eq 'char'){
			 $val = unpack "C",$f->{$section}->slice("($o)");
		  }elsif($dtype eq 'bits'){
			 $val = '';
			 my $tval = $f->{$section}->slice("($o)");
			 my @twos = (128,64,32,16,8,4,2,1);
          for(my $i=0;$i<8;$i++){
				if($tval & $twos[$i]){
				  $val .= '1';
				}else{
				  $val .= '0';
				}
			 }
		  }
		}else{
		  $val = $f->{$section}->at($num-1);
		}
	 }
    next unless (defined $val);
	 my $name = "$num ";
	 if(defined $types->{$section}{$num}{name}){
		$name .= $types->{$section}{$num}{name};
	 }

	 $TkObjects->{$section."Listboxes"}[0]->insert('end',$name);
	 $TkObjects->{$section."Listboxes"}[1]->insert('end',$val);

  }
  

}
			
	
sub idsort{

  my(@a) = split(/:/,$a);
  my(@b) = split(/:/,$b);

  $#a<=1
	 or
  $#b<=1
	 or
  $a[0] <=> $b[0]
    or
  $a[1] <=> $b[1]
    or
  $a[2] <=> $b[2]
    or
  $a[3] <=> $b[3]
    or
  $a[4] <=> $b[4]
    or
  $a cmp $b;
}

sub scroll_listboxes {
  my ($sb,$scrolled,$lbs,@args) = @_;
  $sb->set(@args);
  my($top,$bottom) = $scrolled->yview();
  foreach my $list (@$lbs){
	 $list->yviewMoveto($top);
  }
}

sub lookup_gds_types{
  my($gds4, $gds5, $gds6) = @_;
  
  my $types;

  $types = GDS_DEFAULTS;

  if($gds6 == 5){
    for(7..27){
		undef $types->{$_};
	 }
	 $types->{7}{name}='NX ';
	 $types->{7}{type}='uint2';
	 $types->{9}{name}='NY ';
	 $types->{9}{type}='uint2';
	 $types->{11}{name}='Lat of first grid point';
	 $types->{11}{type}='int3';
	 $types->{14}{name}='Lon of first grid point';
	 $types->{14}{type}='int3';
	 $types->{17}{name}='Resolution and componet flags';
	 $types->{17}{type}='bits';
	 $types->{18}{name}='grid orientation';
	 $types->{18}{type}='int3';
	 $types->{21}{name}='X-direction grid length';
	 $types->{21}{type}='int3';
	 $types->{23}{name}='Y-direction grid length';
	 $types->{23}{type}='int3';
	 $types->{27}{name}='Projection Center flag';
	 $types->{27}{type}='bits';
	 $types->{28}{name}='Scanning Mode';
	 $types->{28}{type}='bits';
  }elsif($gds6 == 192){
    for(7..27){
		undef $types->{$_};
	 }
	 $types->{11}{type}='int3';
	 $types->{11}{name}='ND: number of diamonds';
	 $types->{14}{type}='int3';
	 $types->{14}{name}='NI: intervals on a main side';
	 $types->{17}{name}='Resolution and componet flags';
	 $types->{17}{type}='bits';
	 $types->{18}{name}='LAPP: Location of Isocondrahedral';
	 $types->{18}{type}='int3';
	 $types->{21}{name}='LOPP: pole point';
	 $types->{21}{type}='int3';
	 $types->{24}{name}='LAMPL';
	 $types->{24}{type}='int3';

	 $types->{28}{name}='Scanning Mode';
	 $types->{28}{type}='bits';
  }	 

  for(my $i=0; $i<=$gds4; $i++){
	 $types->{4*$i+$gds5}{name}="vertical parm $i";
	 $types->{4*$i+$gds5}{type}='float';
  }
  return $types;
}

sub pgplot_contour{
  my(@args) = @_;

  return unless defined $Field;

  my $data = $Field->read_data($GribFile->{_FILEHANDLE});
  
  cont $data;
  
}

sub trid_contour{
  my(@args) = @_;

  return unless defined $Field;

  my $data = $Field->read_data($GribFile->{_FILEHANDLE});
  
  
  my @stats = $data->stats;
  print $Field->name," @stats\n";
 
  
  PDL::Graphics::TriD::contour3d($data,undef,undef, {Labels=>[]});
  
}
