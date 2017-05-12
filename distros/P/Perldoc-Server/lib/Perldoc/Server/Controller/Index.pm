package Perldoc::Server::Controller::Index;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Index - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(1) {
  my ($self, $c, $section) = @_;

  if ($c->model('Section')->exists($section)) {
    my @pages = map {
      {
        name  => $_,
        title => $c->model('Pod')->title($_),
        link  => $c->uri_for('/view',split(/::/,$_)),
      }
    } $c->model('Section')->pages($section);
    
    $c->stash->{pages}         = \@pages;
    $c->stash->{title}         = $c->model('Section')->name($section);
    $c->stash->{page_template} = 'section_index.tt';
  }
}


sub modules :Local :Args(0) {
  my ($self, $c) = @_;
    
  $c->response->redirect( $c->uri_for('/index/modules','A') );
}


sub functions :Local :Args(0) {
  my ($self, $c) = @_;
  
  my @function_az;
  foreach my $letter ('A'..'Z') {
    my ($link,@functions);
    if (my @function_list = grep {/^[^a-z]*$letter/i} sort ($c->model('PerlFunc')->list)) {
      $link = "#$letter";
      foreach my $function (@function_list) {
        (my $url = $function) =~ s/[^\w-].*//i;
        my $description = $c->model('PerlFunc')->description($function);
        push @functions,{name=>$function, url=>$url, description=>$description};
      }
    } 
    push @function_az, {letter=>$letter, link=>$link, functions=>\@functions};
  }
  
  $c->stash->{title}         = 'Perl functions A-Z';
  $c->stash->{function_az}   = \@function_az;
  $c->stash->{page_template} = 'function_index.tt';
}


sub functions_by_category :Local :Args(0) {
  my ($self, $c) = @_;

  my @function_cat;  
  foreach my $category ($c->model('PerlFunc')->category_list) {
    $c->log->debug($category);
    my $name = $c->model('PerlFunc')->category_description($category);
    (my $link = $name) =~ tr/ /-/;
    my @functions;
    foreach my $function (sort ($c->model('PerlFunc')->category_functions($category))) {
      (my $url = $function) =~ s/[^\w-].*//i;
      my $description = $c->model('PerlFunc')->description($function);
      push @functions,{name=>$function, url=>$url, description=>$description};
    }
    push @function_cat,{name=>$name, link=>$link, functions=>\@functions};
  }

  $c->stash->{title}         = 'Perl functions by category';
  $c->stash->{function_cat}  = \@function_cat;
  $c->stash->{page_template} = 'function_bycat.tt';
}


sub pragmas :Local :Args(0) {
  my ($self, $c) = @_;

  my %pages = map {$_=>1} grep {
    /^[a-z]/
  } $c->model('Index')->find_modules;

  foreach my $section ($c->model('Section')->list) {
    delete $pages{$_} foreach $c->model('Section')->pages($section);
  }
  
  delete $pages{$_} foreach qw/
    perllocal perltoc perlcn perljp perlko perltw lwpcook lwptut pp
    inc::Module::Install perl5db
  /;

  my @pages = map {
    {
      name  => $_,
      title => $c->model('Pod')->title($_),
      link  => $c->uri_for('/view',split(/::/,$_)),
    }
  } keys %pages;

  $c->stash->{pages}         = [ sort {$a->{name} cmp $b->{name}} @pages ];
  $c->stash->{title}         = 'Pragmas';
  $c->stash->{page_template} = 'section_index.tt';
}

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
