#!/usr/bin/perl

BEGIN {
  push @INC , '../';  
  push @INC , '../SVG';
}
  
  use SVG;
  use strict;
  use CGI ':new :header';
  my $p = CGI->new;
  $| = 1;

  my $svg= SVG->new(width=>200,height=>200); 

  my $y=$svg->group( id     =>  'group_y',
                     style  =>  {stroke=>'red', fill=>'green'} );

  my $z=$svg->tag('g',  id=>'group_z',
                        style=>{ stroke=>'rgb(100,200,50)', 
                                 fill=>'rgb(10,100,150)'} );

 
  $y->circle(cx=>100,
             cy=>100,
             r=>50, 
             id=>'circle_y',);

  $z->tag('circle',cx=>50,
             cy=>50,
             r=>100, 
             id=>'circle_z',);
  
  # an anchor with a rectangle within group within group z

  my $k = $z -> anchor(
		     -href   => 'http://test.hackmare.com/',
		     -target => 'new_window_0') -> 
                      rectangle ( x=>20,
                                      y=>50,
                                      width=>20,
                                      height=>30,
                                      rx=>10,
                                      ry=>5,
                                      id=>'rect_z',);
  

  print $p->header('image/svg-xml');
  print $svg->xmlify;
