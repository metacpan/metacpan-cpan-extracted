package Mojolicious::Page;
use Mojo::Base -base;

use POSIX;

use overload
  bool     => sub{1},
  '""'     => sub{ shift->to_string },
  fallback => 1;



has current_page => 1;
has total_row => 0;
has pre_page_row => 20;
has show_pages => 10;
has ["show_prev", "show_next", "show_first", "show_last"] => 1;
has ["url", "list"];
has prev => sub{
    my $self = shift;
    if($self->current_page <= 1){
      $self->show_prev(0);
      return 1;
    }
    return $self->current_page - 1;
  };
has next => sub{
    my $self = shift;
    if($self->current_page + 1 > $self->total_page){
      $self->show_next(0);
      return $self->total_page;
    }
    return $self->current_page + 1;
  };
has last => sub{
    shift->total_page;
  };
has first => 1;

has start_row => sub{
    my $self = shift;
    return ($self->current_page - 1) * $self->pre_page_row;
  };


has total_page => sub{
    my $self = shift;
    return ceil($self->total_row / $self->pre_page_row);
  };

sub pagging{
  my $self = shift;
  my $list = [];
  if($self->total_page <= $self->show_pages){
    for my $page (1 .. $self->total_page){
      push(@{$list}, {page => $page, is_current => ($page == $self->current_page ? 1 : 0)});
    }
  }else{
    if($self->current_page * 2 < $self->show_pages){
      for my $page (1 .. $self->show_pages){
        push(@{$list}, {page => $page, is_current => ($page == $self->current_page ? 1 : 0)});
      }
    }elsif(($self->total_page - $self->current_page) * 2 < $self->show_pages){
      for my $page (($self->total_page - $self->show_pages) .. $self->total_page){
        push(@{$list}, {page => $page, is_current => ($page == $self->current_page ? 1 : 0)});
      }
    }else{
      for my $page (($self->current_page - ($self->show_pages / 2)) .. ($self->current_page + ($self->show_pages / 2))){
        push(@{$list}, {page => $page, is_current => ($page == $self->current_page ? 1 : 0)});
      }
    }
  }
  $self->list($list);
  $self->show_prev;
  $self->show_next;
  $self->show_first;
  $self->show_last;
  $self->prev;
  $self->next;
  $self->last;
  $self->first;
  $self->{url} =~ s/\&?page=\d+//isg;
}

sub to_string{
  my $self = shift;
  $self->pagging unless($self->list);
  return " limit " . $self->start_row . "," . $self->pre_page_row;
}

sub to_hash{
  my $self = shift;
  $self->pagging unless($self->list);
  my %tmp = %$self;
  return \%tmp;
}


1;