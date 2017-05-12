package Perldoc::Server::Model::Index;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

use File::Monitor;
use Pod::Simple::Search;

sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub find_modules {
  my $self      = shift;
  my $search    = shift || '.';
  my $name2path = $self->name2path;
  
  return grep {/^$search/} (keys %{$name2path});
}


sub name2path {
  my $self        = shift;
  my @search_path = grep {/\w/} @{$self->{c}->config->{search_path}};
  
  state $monitor;
  unless ($monitor) {
    $monitor = File::Monitor->new();
    foreach my $directory (@search_path) {
      $monitor->watch({name=>$directory, recurse=>1});
    }
  }
  
  state $name2path;
  if (!$name2path or $monitor->scan) {
    $name2path = Pod::Simple::Search->new->inc(0)->survey((map {"$_/pods"} @search_path),@search_path);
  }
  
  return $name2path;
}

=head1 NAME

Perldoc::Server::Model::Index - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
