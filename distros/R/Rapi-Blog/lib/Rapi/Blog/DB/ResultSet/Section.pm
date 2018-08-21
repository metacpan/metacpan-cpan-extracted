package Rapi::Blog::DB::ResultSet::Section;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub by_popularity {
  my $self = shift;
  
  $self->search_rs(undef, { 
    order_by => { '-desc' => $self->correlate('trk_section_posts')->count_rs->as_query },
  })
}

sub alphabetically {
  (shift)->search_rs(undef, { order_by => { '-asc' => 'me.name' } })
}

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::ResultSet::ListAPI');

sub _api_default_params {{ limit => 200, sort => 'alphabetical' }}
sub _api_param_arg_order { [qw/search parent_id/] } 
sub _api_params_undef_map {{ parent_id => 'none' }};

# Method exposed to templates:
sub list_sections {
  my ($self, @args) = @_;
  
  my $P = $self->_list_api_params(@args);
  
  my $Rs = $self
    ->search_rs(undef,{ '+columns' => {
      # pre-load 'posts_count' -- the Row class will use it (see Result::Section)
      posts_count       => $self->correlate('trk_section_posts')             ->count_rs->as_query,
      subsections_count => $self->correlate('trk_section_sections_sections') ->count_rs->as_query,
      
    }});
  
  $P->{sort} ||= 'alphabetical';
  if($P->{sort} eq 'alphabetical') {
    $Rs = $Rs->alphabetically;
  }
  else {
    $Rs = $Rs->by_popularity
  }
    
  $Rs = $Rs->search_rs(
    { 'me.parent_id' => $P->{parent_id} },
  ) if (exists $P->{parent_id});
  
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$P->{search},'%') } }
  ) if ($P->{search});
  
  return $Rs->_list_api;
}


1;
