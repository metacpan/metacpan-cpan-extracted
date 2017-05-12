package Reaction::UI::Widget;

use Reaction::Class;
use aliased 'Reaction::UI::ViewPort';
use aliased 'Reaction::UI::View';
use aliased 'Reaction::UI::LayoutSet';

use namespace::clean -except => [ qw(meta) ];


sub DEBUG_FRAGMENTS () { $ENV{REACTION_UI_WIDGET_DEBUG_FRAGMENTS} }
sub DEBUG_LAYOUTS () { $ENV{REACTION_UI_WIDGET_DEBUG_LAYOUTS} }

has 'view' => (isa => View, is => 'ro', required => 1);
has 'layout_set' => (isa => LayoutSet, is => 'ro', required => 1);
has 'fragment_names' => (is => 'ro', lazy_build => 1);
has 'basic_layout_args' => (is => 'ro', lazy_build => 1);
sub _build_fragment_names {
  my ($self) = shift;
  return [
    map { /^_fragment_(.*)/; $1; }
    grep { /^_fragment_/ }
    map { $_->{name} }
    $self->meta->get_all_methods
  ];
};
sub render {
  my ($self, $fragment_name, $rctx, $passed_args) = @_;
  confess "\$passed_args not hashref" unless ref($passed_args) eq 'HASH';
  if (DEBUG_FRAGMENTS) {
    my $vp = $passed_args->{viewport};
    $self->view->app->log->debug(
      "Rendering fragment ${fragment_name} for ".ref($self)
      ." for VP ${vp} at ".$vp->location
    );
  }
  my $args = { self => $self, %$passed_args };
  my $new_args = { %$args };
  my $render_tree = $self->_render_dispatch_order(
                      $fragment_name, $args, $new_args
                    );
  $rctx->dispatch($render_tree, $new_args);
};
sub _method_for_fragment_name {
  my ($self, $fragment_name) = @_;
  return $self->can("_fragment_${fragment_name}");
};
sub _render_dispatch_order {
  my ($self, $fragment_name, $args, $new_args) = @_;

  my @render_stack = (my $render_deep = (my $render_curr = []));
  my @layout_order = $self->layout_set->widget_order_for($fragment_name);

  if (my $f_meth = $self->_method_for_fragment_name($fragment_name)) {
    my @wclass_stack;
    my $do_render = sub {
      my $package = shift;
      if (@layout_order) {
        while ($package eq $layout_order[0][0]
               || $layout_order[0][0]->isa($package)) {
          my $new_curr = [];
          my @l = @{shift(@layout_order)};
          if (DEBUG_LAYOUTS) {
            $self->view->app->log->debug(
              "Layout ${fragment_name} in ${\$l[1]->name} from ${\$l[1]->source_file}"
            );
          }
          push(@$render_curr, [ -layout, $l[1], $fragment_name, $new_curr ]);
          push(@render_stack, $new_curr);
          push(@wclass_stack, $l[0]);
          $render_deep = $render_curr = $new_curr;
          last unless @layout_order;
        }
      }
      if (@wclass_stack) {
        while ($package ne $wclass_stack[-1]
               && $package->isa($wclass_stack[-1])) {
          pop(@wclass_stack);
          $render_curr = pop(@render_stack);
        }
      }
      push(@{$render_curr}, [ '-render', @_ ]);
    };
    $self->$f_meth($do_render, $args, $new_args);
  }
  # if we had no fragment method or if we still have layouts left
  if (@layout_order) {
    while (my $l = shift(@layout_order)) {
      if (DEBUG_LAYOUTS) {
        $self->view->app->log->debug(
          "Layout ${fragment_name} in ${\$l->[1]->name} from ${\$l->[1]->source_file}"
        );
      }
      push(@$render_deep, [
        -layout => $l->[1], $fragment_name, ($render_deep = [])
      ]);
    }
  }

  return $render_stack[0];
};
sub _build_basic_layout_args {
  my ($self) = @_;
  my $args;
  foreach my $name (@{$self->fragment_names},
                    @{$self->layout_set->layout_names}) {
    $args->{$name} ||= sub { $self->render($name, @_); };
  }
  return $args;
};
sub _fragment_viewport {
  my ($self, $do_render, $args, $new_args) = @_;
  my $vp = $args->{'_'};
  my ($widget, $merge_args) = $self->view->render_viewport_args($vp);
  $merge_args->{outer} = { %$new_args };
  delete @{$new_args}{keys %$new_args}; # fresh start
  @{$new_args}{keys %$merge_args} = values %$merge_args;
  $do_render->(Widget, $widget, 'widget');
};
sub _fragment_widget {
  my ($self, $do_render, $args, $new_args) = @_;
  my $merge = $self->basic_layout_args;
#warn "Merge: ".join(', ', keys %$merge)." into: ".join(', ', keys %$new_args);
  delete @{$merge}{keys %$new_args}; # nuke 'self' and 'viewport'
  @{$new_args}{keys %$merge} = values %$merge;
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::Widget - The base widget.

=head1 DESCRIPTION

This is the base class for all widgets. It provides common functionality and 
fragments. It is also concerned with the rendering of the fragments.

=head1 FRAGMENTS

=head2 widget

This is the root fragment for every widget.

=head2 viewport

This fragment is used to render another viewport from inside a fragment. It
assumes the viewport is stored in the C<_> argument.

=head1 ENVIRONMENT FLAGS

=over

=item REACTION_UI_WIDGET_DEBUG_FRAGMENTS

Log additional debugging output for fragment processing.

=item REACTION_UI_WIDGET_DEBUUG_LAYOUTS

Log additional debugging output for layout processing.

=back

=head1 ATTRIBUTES

=head2 view

The widget's view object. Is required, readonly and must be a L<Reaction::UI::View>.

=head2 layout_set

The widget's layout set. Is required, readonly and must be a L<Reaction::UI::LayoutSet>.

=head2 fragment_names

List of names of known fragments for the current widget. Lazily computed from all 
methods that are named in the pattern C<_fragment_$name>.

=head2 basic_layout_args

A lazily built hash reference containing the rendered fragments defined in both the widget and
the layout set, keyed by the fragments' names.

=head

=head1 METHODS

=head2 render

  $widget->render('fragment_name', $reaction_ctx, \%passed_args);

This method is concerned with rendering a fragment.

=head1 SEE ALSO

=over 4

=item * L<Reaction::Manual::Widgets>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
