package Rapi::Demo::CrudModes::Module::Alpha::Role;

use strict;
use warnings;

use Moose::Role;
use RapidApp::Util qw(:all);

has 'include_colspec',     is => 'ro', default => sub {['*']};
has 'updatable_colspec',   is => 'ro', default => sub {['*']};
has 'creatable_colspec',   is => 'ro', default => sub {['*']};
has 'destroyable_relspec', is => 'ro', default => sub {['*']};

has 'use_add_form',  is => 'ro', default => 0;
has 'use_edit_form', is => 'ro', default => 0;

has 'persist_immediately', is => 'ro', default => sub{{
  create  => 1,
  update  => 1,
  destroy => 1
}};

has 'confirm_on_destroy', is => 'ro', default => 0;

has 'ResultSource', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->app->model('DB')->schema->source('Alpha')
};

sub BUILD {}
after 'BUILD' => sub {
  my $self = shift;
  
  $self->apply_extconfig(
    # Show full text with the store buttons (default is false)
    show_store_button_text => \1, 
  );
};


use Data::Dumper::Concise 'Dumper';

sub dump_crud_options {
  my $self = shift;
  Dumper({
    use_add_form        => $self->use_add_form,
    use_edit_form       => $self->use_edit_form,
    confirm_on_destroy  => $self->confirm_on_destroy,
    persist_immediately => $self->persist_immediately
  })
}


1;

