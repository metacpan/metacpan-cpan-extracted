package Rapi::Demo::CrudModes::Module::Alpha::DV;

use strict;
use warnings;

use Moose;
extends 'RapidApp::Module::DbicDV';
with 'Rapi::Demo::CrudModes::Module::Alpha::Role';

use RapidApp::Util qw(:all);
use Path::Class qw(file dir);

has '+tt_file', default => 'templates/alpha_dv.html';

has '+tt_include_path', default => sub {
  my $self = shift;
  dir( $self->app->ra_builder->data_dir )->stringify;
};

sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig( 
    itemSelector    => 'div.alpha-row',
    selectedClass   => 'selected',
    scrollNodeClass => 'rows-wrap' 
  );
}



1;

