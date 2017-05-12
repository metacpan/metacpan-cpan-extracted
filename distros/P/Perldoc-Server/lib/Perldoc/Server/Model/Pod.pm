package Perldoc::Server::Model::Pod;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

use File::Slurp qw/slurp/;
use Memoize;
use Pod::Simple::Search;

memoize('section', NORMALIZER => sub { $_[1] });

sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub pod {
  my ($self,$pod) = @_;
  
  if (my $file = $self->find($pod)) {
    return slurp($file);
  }
  
  return "=head1 Cannot find Pod for $pod";
}


sub find {
  my ($self,$pod) = @_;
  
  my @search_path = grep {/\w/} @{$self->{c}->config->{search_path}};
  return Pod::Simple::Search->new->inc(0)->find($pod, @search_path,map{"$_/pods"} @search_path);
}


sub title {
  my ($self,$page) = @_;
  state %name2title;
  
  unless (exists $name2title{$page}) {
    local $_ = $self->pod($page);
    if (/=head1 NAME\s*?[\n|\r](\S.*?)[\n|\r]\s*[\n|\r]/si or 
        /=head1 TITLE\s*?[\n|\r](\S.*?)[\n|\r]\s*[\n|\r]/si) {
      my $title = $1;
      if (defined $title) {
        $title =~ s/E<(.*?)>/&$1;/g;
        $title =~ s/[A-DF-Z]<(.*?)>/$1/g;
        $title =~ s/.*? -+\s+//;
        $title =~ s/\(\$.*?\$\)//;
        $name2title{$page} = $title;
      }
    }
  }
  
  return $name2title{$page};
}


sub section {
  my ($self, $page) = @_;
  
  foreach my $section ($self->{c}->model('Section')->list) {
    my @section_pages = $self->{c}->model('Section')->pages($section);
    if ($page ~~ @section_pages) {
      return $section;
    }
  }
  return;
}

=head1 NAME

Perldoc::Server::Model::Pod - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
