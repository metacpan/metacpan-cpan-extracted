package Reaction::UI::ViewPort::SearchableListViewContainer;
use Reaction::Class;

#use aliased 'Reaction::InterfaceModel::Search::Spec', 'SearchSpec';
use aliased 'Reaction::InterfaceModel::Action::Search::UpdateSpec', 'UpdateSearchSpec';
use aliased 'Reaction::UI::ViewPort::ListViewWithSearch';
use aliased 'Reaction::UI::ViewPort::Action' => 'ActionVP';
use aliased 'Reaction::UI::ViewPort';
use aliased 'Reaction::UI::ViewPort::Collection::Role::Pager', 'PagerRole';

use Method::Signatures::Simple;

use namespace::clean -except => 'meta';

extends 'Reaction::UI::ViewPort';

has 'listview' => (
    isa => ViewPort,
    is => 'ro', 
    required => 1, 
);

has 'search_form' => (isa => ViewPort, is => 'ro', required => 1);

override BUILDARGS => sub {
  my $args = super;
  my $spec_event_id = $args->{location}.':search-spec';
  my $spec_class = $args->{spec_class}
    or confess "Argument spec_class is required";
  my $listview_class = $args->{'listview_class'} || ListViewWithSearch;
  my $search_form_class = $args->{'search_form_class'} || ActionVP; 
  my $action_class = $args->{action_class}
    or confess "Argument action_class is required";
#  TODO: how do we autodiscover spec classes?
#  $spec_class =~ s/^::/${\SearchSpec}::/;
  Class::MOP::load_class($spec_class);
  my $spec = do {
    if (my $string = $args->{ctx}->req->query_params->{$spec_event_id}) {
      $spec_class->from_string($string, $args->{spec}||{});
    } else {
      $spec_class->new($args->{spec}||{});
    }
  };
  my $listview_location = $args->{location}.'-listview';
  my $listview = $args->{listview} = $listview_class->new(
    %$args,
    layout => $args->{'listview_layout'} || 'list_view',
    search_spec => $spec,
    location => $listview_location,
  );
  $args->{search_form} = $search_form_class->new(
    model => $action_class->new(
      target_model => $spec,
      %{$args->{search_model}||{}}
    ),
    location => $args->{location}.'-search_form',
    apply_label => 'search',
    ctx => $args->{ctx},
    on_apply_callback => sub {
      my ($vp, $spec) = @_;
      my $req = $vp->ctx->req;
      my $new_uri = $req->uri->clone;
      my %query = %{$req->query_parameters};
      delete @query{grep /^\Q${listview_location}\E/, keys %query};
      $query{$spec_event_id} = $spec->to_string;
      $new_uri->query_form(\%query);
      $req->uri($new_uri);
      $listview->clear_page;
      $listview->clear_order_by;
    },
    %{$args->{search}||{}}
  );
  $args;
};

override child_event_sinks => method () {
  ((map $self->$_, 'search_form', 'listview'), super);
};

1;

