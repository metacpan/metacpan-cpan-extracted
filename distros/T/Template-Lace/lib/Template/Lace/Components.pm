package Template::Lace::Components;

use Moo;
use UUID::Tiny;
use JSON::MaybeXS ();

has [qw(handlers component_info ordered_component_keys)] => (is=>'ro', required=>1);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my %component_info = $class->get_component_info($args);
  my @ordered_component_keys = $class->get_component_ordered_keys(%component_info);
  my %handlers = $class->get_handlers($args, \%component_info, @ordered_component_keys);

  $args->{handlers} = \%handlers;
  $args->{component_info} = \%component_info;
  $args->{ordered_component_keys} = \@ordered_component_keys;

  return $args;
};

sub get_component_info {
  my ($class, $args) = @_;
  my %component_info = $class->find_components($args->{dom}, $args->{component_handlers});
  return %component_info;
}

sub get_handlers {
  my ($class, $args, $component_info, @ordered_component_keys) = @_;
  my %handlers = ();
  foreach my $key(@ordered_component_keys) {
    my $handler = $class->get_handler($args, %{$component_info->{$key}});
    $handlers{$key} = $handler;
  }
  return %handlers;
}

sub get_handler {
  my ($class, $args, %component_info) = @_;
  my $prefix = $component_info{prefix};
  my $name = $component_info{name};
  my $handler = '';
  if(ref($args->{component_handlers}{$prefix}) eq 'CODE') {
    $handler = $args->{component_handlers}{$prefix}->($name, $args, %{$component_info{attrs}});
  } else {
    $handler = $args->{component_handlers}{$prefix}{$name};
    $handler = (ref($handler) eq 'CODE') ? $handler->($args, %{$component_info{attrs}}): $handler;
  }

  # TODO should this be in the renderer?
  if($handler->model_class->can('on_component_add')) {
    my $dom_content = $args->{dom}->at("[uuid='$component_info{key}']");
    my %attrs = ( 
      $handler->renderer_class
        ->process_attrs(
            $handler->model_class,
            $args->{dom}, # DOM of containing template
            %{$component_info{attrs}}),
        content=>$dom_content->content,
      #  model=>$self->model
    );
    my $renderer = $handler->create(%attrs);
    $renderer->model->on_component_add($renderer->dom, $args->{dom});
    $dom_content->replace($renderer->dom);
  }

  return $handler;
}

sub find_components {
  my ($class, $dom, $handlers, $current_container_id, %components) = @_;
  $dom->child_nodes->each(sub {
    %components = $class->find_component(@_,
      $handlers,
      $current_container_id,
      %components);
  });
  return %components;
}

sub find_component {
  my ($class, $child_dom, $num, $handlers, $current_container_id, %components) = @_;
  if(my ($prefix, $component_name) = (($child_dom->tag||'') =~m/^(.+?)\-(.+)?/)) {
    ## if uuid exists, that means we already processed it.
    if($class->is_a_component($handlers, $prefix, $component_name)) {
      unless($child_dom->attr('uuid')) {
        my $uuid = $class->generate_component_uuid($prefix);
        $child_dom->attr({'uuid',$uuid});
        $components{$uuid} = +{
          order => (scalar(keys %components)),
          key => $uuid,
          $class->setup_component_info($prefix,
            $current_container_id,
            $component_name,
            $child_dom),
        };

        push @{$components{$current_container_id}{children_ids}}, $uuid
          if $current_container_id;

        my $old_current_container_id = $current_container_id;
        $current_container_id = $uuid;
        
        %components = $class->find_components(
          $child_dom,
          $handlers,
          $current_container_id,
          %components);

        $current_container_id = $old_current_container_id;
      }
    }
  }
  %components = $class->find_components(
    $child_dom,
    $handlers,
    $current_container_id,
    %components);
  return %components;
}

sub is_a_component {
  my ($class, $handlers, $prefix, $name) = @_;
  if($handlers->{$prefix}) {
    if(ref($handlers->{$prefix}) eq 'CODE') {
      return 1;
    } else {
      return $handlers->{$prefix}{$name} ? 1:0;
    }
  } else {
    return 0;
  }
}

sub generate_component_uuid {
  my ($class, $prefix) = @_;
  my $uuid = UUID::Tiny::create_uuid_as_string;
  $uuid=~s/\-//g;
  return $uuid;
}

sub setup_component_info {
  my ($class, $prefix, $current_container_id, $name, $dom) = @_;
  my %attrs = $class->setup_component_attr($dom);
  return prefix => $prefix,
    name => $name,
    current_container_id => $current_container_id||'',
    attrs => \%attrs;
}

sub setup_component_attr {
  my ($class, $dom) = @_;
  return map {
    $_ => $class->attr_value_handler_factory($dom->attr->{$_});
  } keys %{$dom->attr||+{}};
}

sub attr_value_handler_factory {
  my ($class, $value) = @_;


  if(my ($node, $css) = ($value=~m/^\\['"](\@?)(.+)['"]$/)) {
    return $class->setup_css_match_handler($node, $css); # CSS match to content DOM
  } elsif(my $path = ($value=~m/^\$\.(.+)$/)[0]) {
    return $class->setup_data_path_hander($path); # is path to data
  } elsif($value=~/^\{/) {
    return $class->setup_hashrefdata_hander($value);
  }elsif($value=~/^\[/) {
    return $class->setup_arrayrefdata_hander($value);
  } else {
    return $value; # is literal or 'passthru' value
  }
}

sub setup_arrayrefdata_hander {
  my ($class, $value) = @_;
  my $ref = JSON::MaybeXS::decode_json($value);
  my @array = map {
    my $v = $_; $v =~s/^\$\.//;
    $class->attr_value_handler_factory($v);
  } @$ref;
  return sub {
    my ($ctx, $dom) = @_;
    return [ map { (ref($_)||'') eq 'CODE' ? $_->($ctx,$dom) : $_ } @array ];
  };
}


sub setup_hashrefdata_hander {
  my ($class, $value) = @_;
  my $ref = JSON::MaybeXS::decode_json($value);
  my %hash = map {
    my $v = $ref->{$_};
    $_ => $class->attr_value_handler_factory($v);
  } keys %$ref;
  return sub {
    my ($ctx, $dom) = @_;
    my %unrolled = map { $_ => $hash{$_}->($ctx,$dom) } keys(%hash);
    return \%unrolled;
  };
}

sub setup_css_match_handler {
  my ($class, $node, $css) = @_;
  if($node) {
    return sub { my ($view, $dom) = @_; $dom->find($css) };
  } else {
    if(my $content = $css=~s/\:content$//) { # hack to CSS to allow match on content
      return sub { my ($view, $dom) = @_; $dom->at($css)->content };
    } elsif(my $nodes = $css=~s/\:nodes$//) {
      return sub { my ($view, $dom) = @_; $dom->at($css)->descendant_nodes };      
    }else {
      return sub { my ($view, $dom) = @_; $dom->at($css) };
    }
  }
}

sub setup_data_path_hander {
  my ($class, $path) = @_;
  my @parts = $path=~m/\./ ? (split('\.', $path)) : ($path);
  return sub {
    my ($ctx, $dom) = @_;
    foreach my $part(@parts) {
      if(Scalar::Util::blessed $ctx) {
        $ctx = $ctx->$part;
      } elsif(ref($ctx) eq 'HASH') {
        $ctx = $ctx->{$part};
      } else {
        die "No '$part' in path '$path' for this view";
      }
    }
    return $ctx;
  };
}

sub get_component_ordered_keys {
  my ($class, %component_info) = @_;
  return map {
    $_->{key}
  } sort {
    $a->{order} <=> $b->{order}
  } map {
    $component_info{$_}
  } keys %component_info;
}

1;

=head1 NAME

Template::Lace::Components - Prepares a Component Hierarchy from a DOM

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Use by L<Template::Lace::Factory> to create a component hierarchy for a DOM
and from the defined component_mappings.  Not really end user bits aimed here
but you can subclass if you want customized component features.  See the main
docs in L<Template::Lace> for detailed discussion of Components.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
