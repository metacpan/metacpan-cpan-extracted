package Reaction::UI::View;

use Reaction::Class;

# declaring dependencies
use Reaction::UI::LayoutSet;
use Reaction::UI::RenderingContext;
use aliased 'Reaction::UI::Skin';
use aliased 'Path::Class::Dir';

use namespace::clean -except => [ qw(meta) ];


has '_widget_cache' => (is => 'ro', default => sub { {} });

has '_layout_set_cache' => (is => 'ro', default => sub { {} });

has 'app' => (is => 'ro', required => 1);

has 'skin_name' => (is => 'ro', required => 1, default => 'default');

has 'skin' => (
  is => 'ro', lazy_build => 1,
  handles => [ qw(create_layout_set search_path_for_type) ]
);

has 'layout_set_class' => (is => 'ro', lazy_build => 1);

has 'rendering_context_class' => (is => 'ro', lazy_build => 1);

# default view doesn't localize
sub localize {
  my($self, $value) = @_;
  return $value;
}

sub _build_layout_set_class {
  my ($self) = @_;
  return $self->find_related_class('LayoutSet');
};
sub _build_rendering_context_class {
  my ($self) = @_;
  return $self->find_related_class('RenderingContext');
};
sub _build_skin {
  my ($self) = @_;
  Skin->new(
    name => $self->skin_name, view => $self,
    # path_to returns a File, not a Dir. Thanks, Catalyst.
    skin_base_dir => Dir->new($self->app->path_to('share', 'skin')),
  );
};
sub COMPONENT {
  my ($class, $app, $args) = @_;
  return $class->new(%{$args||{}}, app => $app);
};
sub render_window {
  my ($self, $window) = @_;
  my $root_vp = $window->focus_stack->vp_head;
  my $rctx = $self->create_rendering_context;
  my ($widget, $args) = $self->render_viewport_args($root_vp);
  $widget->render(widget => $rctx, $args);
};

# From 2007-07-11 @ #reaction (so don't blame me if you think this violates some stupid school of thought)
#15:09 <@groditi> mst: one quick thing though. do you remember what layout_args is?
#15:10 <@mst> isn't it crap to be passed to the top level widget render?
#15:11 <@groditi> that's what i thought..
#15:11 <@groditi> but it's kind of a no-op. there's an attr but nothing uses it
#15:11 <@groditi> i cant figure out if the data you give it ends up going anywhere
#15:12 <@groditi> although it'd be cool if anything you put there ended up being part of %_ in layout/widget land
#15:12 <@groditi> which would solve so fucking many of my gripes with widget/layout
#15:14 <@mst> I thought that was what it was supposed to do
#15:14 <@mst> wire it up :)

sub render_viewport_args {
  my ($self, $vp) = @_;
  my $layout_set = $self->layout_set_for($vp);
  my $widget = $self->widget_for($vp, $layout_set);
  my %layout_args = (%{ $vp->layout_args }, viewport => $vp);
  return ($widget, \%layout_args);
};
sub widget_for {
  my ($self, $vp, $layout_set) = @_;
  return
    $self->_widget_cache->{$layout_set->name}
      ||= $layout_set->widget_class
                     ->new(
                         view => $self, layout_set => $layout_set
                       );
};
sub layout_set_for {
  my ($self, $vp) = @_;
  my $lset_name = eval { $vp->layout };
  confess "Couldn't call layout method on \$vp arg ${vp}: $@" if $@;
  $lset_name = $self->layout_set_name_from_viewport( blessed($vp) )
    unless (length($lset_name));
  my $cache = $self->_layout_set_cache;
  return $cache->{$lset_name} ||= $self->create_layout_set($lset_name);
};

#XXX if it ever comes to it: this could be memoized. not bothering yet.
sub layout_set_name_from_viewport {
  my ($self, $class) = @_;
  my ($last) = ($class =~ /.*(?:::ViewPort::)(.+?)$/);
  #split when a non-uppercase letter meets an uppercase or when an
  #uppercase letter is followed by another uppercase and then a non-uppercase
  #FooBar = foo_bar; Foo_Bar = foo_bar; FOOBar = foo_bar; FooBAR = foo_bar
  my @fragments = map {
    join("_", split(/(?:(?<=[A-Z])(?=[A-Z][^_A-Z])|(?<=[^_A-Z])(?=[A-Z]))/, $_))
  } split('::', $last);
  return lc(join('/', @fragments));
};
sub layout_set_file_extension {
  confess View." is abstract, you must subclass it";
};
sub find_related_class {
  my ($self, $rel) = @_;
  my $own_class = ref($self) || $self;
  confess View." is abstract, you must subclass it" if $own_class eq View;
  foreach my $super ($own_class->meta->class_precedence_list) {
    next if $super eq View;
    if ($super =~ /::View::/) {
      (my $class = $super) =~ s/::View::/::${rel}::/;
      if (eval { Class::MOP::load_class($class) }) {
        return $class;
      }
    }
  }
  confess "Unable to find related ${rel} class for ${own_class}";
};
sub create_rendering_context {
  my ($self, @args) = @_;
  return $self->rendering_context_class->new(
           $self->rendering_context_args_for(@args),
           @args,
         );
};
sub rendering_context_args_for {
  return ();
};
sub layout_set_args_for {
  return ();
};

__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

Reaction::UI::View - Render the UI.

=head1 SYNOPSIS

  package MyApp::View::TT;
  use base 'Reaction::UI::View::TT';

  __PACKAGE__->config(
    skin_name => 'MyApp',
  );

  ## In the Window class:
  $res->body($self->view->render_window($self));

=head1 DESCRIPTION

Render the viewports in the current window using the chosen skin and
layoutset, via the matching widgets.

See also:

=over

=item L<Reaction::UI::Controller::Root>
=item L<Reaction::UI::ViewPort>
=item L<Reaction::UI::Window>
=item L<Reaction::UI::LayoutSet>
=item L<Reaction::UI::Widget>

=back

=head1 ATTRIBUTES

=head2 app

=over

=item Arguments: $app?

=back

The application L<Catalyst> class. This is set at
L<Catalyst/COMPONENT> time for you.

=head2 skin_name

=over

=item Arguments: $skinname?

=back

The name of the skin to use to render the pages. This should be the
name of a subdirectory under the F<share/skin> in your application
directory. The default skin name is C<default>, the default skin is
provided with Reaction.

See also: L<Reaction::UI::Skin>

=head2 skin

=over

=item Arguments: $skin?

=back

A L<Reaction::UI::Skin> object based on the L</skin_name>. It will be
created for you if not provided.

=head2 layout_set_class

The class of the L<Reaction::UI::LayoutSet> used to layout the
view. Defaults to searching down the precedence tree of the View class
looking for a class of the same name with C<View> replaced with
C<LayoutSet>.

=head2 rendering_context_class

The class of the L<Reaction::UI::RenderingContext> used to layout the
view. Defaults to searching down the precedence tree of the View class
looking for a class of the same name with C<View> replaced with
C<RenderingContext>.

=head1 METHODS

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

1;
