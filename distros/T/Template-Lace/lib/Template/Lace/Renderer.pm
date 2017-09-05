package Template::Lace::Renderer;

use Moo;
use Scalar::Util;

has [qw(model dom components)] => (is=>'ro', required=>1);

sub call {
  my ($self, $proto, @args) = @_;
  if(ref($proto)||'' eq 'CODE') {
    return $proto->($self->model, $self->dom, @args);
  } elsif($proto) {
    return $self->model->$proto($self->dom, @args);
  }
}

sub call_at {
  my ($self, $css, $proto, @args) = @_;
  my $dom = $self->dom->at($css);
  if(ref($proto)||'' eq 'CODE') {
    return $proto->($self->model, $dom, @args);
  } elsif($proto) {
    return $self->model->$proto($dom, @args);
  }
}

sub render {
  my $self = shift;
  my $rendered_dom = $self->get_processed_dom
    ->to_string;
  return $rendered_dom;
}

sub get_processed_dom {
  my $self = shift;
  my $dom = $self->dom;
  $self->process_components($dom);
  $self->model->process_dom($dom)
    if $self->model->can('process_dom');
  return $dom;
} 

sub process_components {
  my ($self, $dom) = @_;
  my @ordered_keys = @{$self->components->ordered_component_keys};
  my %constructed_components = ();
  foreach my $id(@ordered_keys) {
    next unless $self->components->handlers->{$id}; # might skip if 'static' handler
    next unless my $local_dom = $dom->at("[uuid='$id']");
    my $constructed_component = $self->process_component(
      $local_dom, 
      $self->components->handlers->{$id},
      \%constructed_components,
      %{$self->components->component_info->{$id}});
    $constructed_components{$id} = $constructed_component
      if $constructed_component;
  }
  # Now post process..  We do this so that parents can have access to
  # children for transforming dom.
  foreach my $id(@ordered_keys) {
    next unless $constructed_components{$id};
    my $processed_component = $constructed_components{$id}->get_processed_dom;

#=head1 comment

    # Move all the scripts, styles and links to the head area
    # TODO this probably doesn't work if the stuff is in a component
    # inside a component.
    $processed_component->find('link:not(head link)')->each(sub {
        return unless $_->attr('id') || $_->attr('href');
        $dom->append_link_uniquely($_);
        $_->remove;
    }); # href
    $processed_component->find('style:not(head style)')->each(sub {
        return unless $_->attr('id');
        $dom->append_style_uniquely($_);
        $_->remove;
    }); #id
    $processed_component->find('script:not(head script)')->each(sub {
        my ($e, $num) = @_;
        return unless $e->attr('id') || $e->attr('src');
        $dom->append_script_uniquely($e);
        $_->remove;
    }); #id or src

#=cut

    $dom->at("[uuid='$id']")->replace($processed_component);
  }
}

sub prepare_component_attrs {
  my ($self, $dom, $model, %component_info) = @_;
  my %attrs = ( 
    $self->process_attrs($model, $dom, %{$component_info{attrs}}),
    content=>$dom->content,
    model=>$model);
  return %attrs;
}

sub process_component {
  my ($self, $dom, $component, $constructed_components, %component_info) = @_;
  my %attrs = $self->prepare_component_attrs($dom, $self->model, %component_info);
  if(my $container_id = $component_info{current_container_id}) {
    # Its possible if the compoent was a 'on_component_add' type that
    # its been removed from the DOM and a Child might still have it as
    # a container by mistake.  Possible a TODO to have a better idea.
    $attrs{container} = $constructed_components->{$container_id}->model
      if $constructed_components->{$container_id};
  }

  if(Scalar::Util::blessed $component) {
    my $constructed_component;
    if($attrs{container}) {
      if($attrs{container}->can('create_child')) {
        $constructed_component = $attrs{container}->create_child($component, %attrs);
      } else {
        $constructed_component = $component->create(%attrs);
        $attrs{container}->add_child($constructed_component) if
          $attrs{container}->can('add_child');
      }
    } else {
      $constructed_component = $component->create(%attrs);
    }
    return $constructed_component;
  } elsif(ref($component) eq 'CODE') {
    die "Component not an object";
    #my $new_dom = $component->($dom->content, %attrs);
    #warn $new_dom;
    #$dom->replace($new_dom);
    #warn $dom;
    #return;
  }
}

sub process_attrs {
  my ($self, $ctx, $dom, %attrs) = @_;
  return map {
    my $proto = $attrs{$_};
    my $value = ref($proto) ? $proto->($ctx, $dom) : $proto;
    $_ => $value;
  } keys %attrs;
}

1;

=head1 NAME

Template::Lace::Renderer

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Renderer for the model.  Not really end user aimed.  See L<Template::Lace>
for main overview.

=head1 METHODS

This class defines the following public methods

=head2 call

Allows you to have the renderer 'call' a method into the model, with the current
DOM.  Takes either a coderef or a string (that must be the name of a method in the
model.  Example:

    $renderer->call(sub {
      my ($model, $dom) = @_;
      $model->add_debug($dom);
    }, @args);

    $renderer->call('add_debug', @args);

Are both the same as

   $renderer
     ->model
     ->add_debug($renderer->dom, @args);

You might find this is a useful shortcut (or not).

=head2 call_at

Basically similar to L</call> except allows you to specify a CSS match to
set the DOM.

    $renderer->call_at('#debug','add_debug', @args);

Is basically a shortcut for:

    my $dom = $renderer->dom->at('#debug);
   $renderer->model->add_debug($dom, @args);

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
