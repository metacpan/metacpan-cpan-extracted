package Rapi::Blog::DB::ResultSet::Category;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub by_popularity {
  my $self = shift;
  
  $self->search_rs(undef, { 
    order_by => { '-desc' => $self->correlate('post_categories')->count_rs->as_query },
  })
}

sub alphabetically {
  (shift)->search_rs(undef, { order_by => { '-asc' => 'me.name' } })
}

sub by_most_recent {
	(shift)->search_rs(undef, { 
		join => { 'post_categories' => 'post' },
		order_by => { '-desc' => 'post.ts' },
		group_by => 'me.name' 
	})
}


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::ResultSet::ListAPI');

sub _api_default_params {{ limit => 200, sort => 'popularity' }}
sub _api_param_arg_order { [qw/search post_id/] } 

# Method exposed to templates:
sub list_categories {
  my ($self, @args) = @_;
  
  my $P = $self->_list_api_params(@args);
  
  my $Rs = $self
    ->search_rs(undef,{ '+columns' => {
      # pre-load 'posts_count' -- the Row class will use it (see Result::Category)
      posts_count => $self->correlate('post_categories')->count_rs->as_query
    }});
  
  $P->{sort} ||= 'popularity';
  if($P->{sort} eq 'alphabetical') {
    $Rs = $Rs->alphabetically;
  }
  elsif($P->{sort} eq 'recent') {
    $Rs = $Rs->by_most_recent;
  }
  else {
    $Rs = $Rs->by_popularity
  }
    
  $Rs = $Rs->search_rs(
    { 'post_categories.post_id' => $P->{post_id} },
    { join => 'post_categories' }
  ) if ($P->{post_id});
  
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$P->{search},'%') } }
  ) if ($P->{search});
  
  return $Rs->_list_api;
}


1;
