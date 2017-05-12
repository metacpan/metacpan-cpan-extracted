package Spoon::Registry;
use Spoon::Base -Base;

const class_id => 'registry';
const registry_file => 'registry.dd';
const registry_directory => '.';
const lookup_class => 'Spoon::Lookup';

field lookup =>
      -init => '$self->load';
field 'temp_lookup';
field 'current_class_id';

sub registry_path {
    join '/', $self->registry_directory, $self->registry_file; 
}

sub load {
    my $path = $self->registry_path;
    my $lookup;
    if (-e $path) {
        $lookup = eval io($path)->all;
        die "$path seems to be corrupt:\n$@" if $@;
    }
    else {
        $lookup = $self->update->lookup;
    }
    $self->lookup(bless $lookup, $self->lookup_class);
    return $self->lookup;
}

sub update {
    my $lookup = {};
    $self->temp_lookup($lookup);
    $self->set_core_classes;
    for my $class_name (@{$self->hub->config->plugin_classes}) {
        my $object = $self->load_class($class_name);
        $self->not_a_plugin($class_name)
          unless $object->can('register');
        my $class_id = $self->$set_class_info($object);
        $self->current_class_id($class_id);
        $object->register($self);
    }
    $self->transform;
    $self->lookup($self->temp_lookup);
    return $self;
}

sub not_a_plugin {
    my $class_name = shift;
    die "$class_name is not a plugin\n";
}

sub load_class {
    my $class_name = shift;
    eval "require $class_name"; die $@ if $@;
    $class_name->new;
}

sub set_core_classes {
    my %all = $self->hub->config->all; 
    my $hub = $self->hub; 
    for my $key (keys %all) { 
        next unless $key =~ /(.*)_class$/; 
        my $class_id = $1;
        my $class_name = $all{$key}; 
        $self->temp_lookup->{classes}{$class_id} = $class_name; 
        my $object = $hub->can($class_id) && $hub->$class_id || 
          $self->load_class($class_name); 
          $self->add_classes($object); 
    } 
}

my sub set_class_info {
    my $object = shift;
    my $lookup = $self->temp_lookup;
    my $class_name = ref $object;
    my $class_id = $object->class_id
      or die "No class_id for $class_name\n";
    if (my $prev_name = $lookup->{classes}{$class_id}) {
        $self->plugin_redefined($class_id, $class_name, $prev_name);
    }
    $lookup->{classes}{$class_id} = $class_name;
    $self->add_classes($object);
    push @{$lookup->{plugins}}, {
        id => $class_id,
        title => $object->class_title,
    };
    return $class_id;
}

sub add_classes {
    my $object = shift;
    return unless
      $object->can('inline_classes');
    my $classes = $self->temp_lookup->{classes};
    for my $class_name (@{$object->inline_classes}) {
        my $object = $class_name->new;
        $classes->{$object->class_id} = $class_name;
    }
}

sub plugin_redefined {}

sub add {
    my $class_id = $self->current_class_id;
    my $key = shift;
    if ($key eq 'hook') {
        push @{$self->temp_lookup->{$key}}, [$class_id, @_];
    }
    else {
        my $value = shift;
        $self->temp_lookup->{$key}{$value} = [ $class_id, @_ ];
        push @{$self->temp_lookup->{add_order}{$class_id}{$key}}, $value;
    }
}

sub write {
    $self->dumper_to_file($self->registry_path, $self->lookup);
}

sub transform {
    $self->transform_hook;
}

sub transform_hook {
    my $lookup = $self->temp_lookup;
    return unless defined $lookup->{hook};
    my @hooks = @{$lookup->{hook}};
    my $new_hooks = {};
    for my $hook (@hooks) {
        my ($class_id, $target, %args) = @$hook;
        my $class_name = $lookup->{classes}{$class_id};
        my ($target_class_id, $target_method) =
          $target =~ /^(\w+):(\w+)$/;
        my $target_class_name = $lookup->{classes}{$target_class_id};
        die "Invalid hook '$target' in class '$class_id'\n"
          unless $target_class_id and
                 $target_class_name and
                 ($args{pre} or $args{post});
        push @{$new_hooks->{$target_class_name}}, [
            $target_class_name . '::' .$target_method,
            map {
                my $method = $args{$_};
                ($_, $class_name . '::' . $method);
            } (keys %args),
        ];
    }
    $self->temp_lookup->{hook} = $new_hooks;
}

package Spoon::Lookup;
use Spiffy -base;

# XXX consider an AUTOLOAD here.
field action => {};
field add_order => {};
field classes => {};
field plugins => [];
field preference => {};
field preload => {};
field wafl => {};

__END__

=head1 NAME 

Spoon::Registry - Spoon Registry Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
