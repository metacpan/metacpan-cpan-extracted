#!/usr/bin/perl

use strict;
use warnings;

use POE;
use POEx::Tickit;

use Tickit::Widget::Static;

use Tickit::Widget::VBox;
use Tickit::Widget::Frame;

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

$vbox->add( Tickit::Widget::Frame->new(
      child => my $static = Tickit::Widget::Static->new(
         text => "Flashing text",
         align  => "centre",
         valign => "middle",
      ),
      style => { linetype => "single" },
) );

my $fg = 1;
POE::Session->create(
   inline_states => {
      _start => sub {
         $_[KERNEL]->delay_set( tick => 0.5 );
      },
      tick => sub {
         $fg++;
         $fg = 1 if $fg > 7;
         $static->set_style( fg => $fg );
         $static->redraw;

         $_[KERNEL]->delay_set( tick => 0.5 );
      },
   },
);

POEx::Tickit->new( root => $vbox )->run;
