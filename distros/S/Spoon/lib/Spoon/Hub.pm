package Spoon::Hub;
use Spoon::Base -Base;

const class_id => 'hub';
field action => '_default_';

field main => -weak;
field config_files => [];
field all_hooks => [];

sub new {
    $self = super;
    $self->init;
    $Spoon::Base::HUB = $self;
}

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ /.*::(.*)/
      or die "Can't AUTOLOAD '$AUTOLOAD'";
    my $class_id = $1;
    return if $class_id eq 'DESTROY';
    field $class_id => 
          -init => "\$self->load_class('$class_id')";
    $self->$class_id(@_);
}

sub pre_process {}
sub post_process {}

sub process {
    $self->preload;
    my $action = $self->action;
    die "No plugin for action '$action'"
      unless defined $self->registry->lookup->action->{$action};
    my ($class_id, $method) = 
      @{$self->registry->lookup->action->{$action}};
    $method ||= $action;
    return $self->$class_id->$method;
}

sub preload {
    my $preload = $self->registry->lookup->preload;
    map {
        $self->load_class($_->[0])
    } sort {
        $b->[1] <=> $a->[1]
    } map {
        my %hash = @{$preload->{$_}}[1..$#{$preload->{$_}}];
        [$_, $hash{priority} || 0];
    } keys %$preload;
    return $self;
}

sub load_class {
    my $class_id = shift;
    return $self if $class_id eq 'hub';
    return $self->$class_id 
      if $self->can($class_id) and defined $self->{$class_id};

    my $class_class = $class_id . '_class';

    my $class_name = $self->config->can($class_class)
        ? $self->config->$class_class
        : $self->registry_loaded
          ? $self->registry->lookup->classes->{$class_id}
          : Carp::confess "Can't find a class for class_id '$class_id'";

    Carp::confess "No class defined for class_id '$class_id'"
      unless $class_name;
    unless ($class_name->can('new')) {
        eval "require $class_name";
        die $@ if $@;
    }
    $self->add_hooks
      unless $class_id eq 'hooks';
    my $object = $class_name->new
      or die "Can't create new '$class_name' object";
    $class_id ||= $object->class_id;
    die "No class_id defined for class: '$class_name'\n"
      unless $class_id;
    field $class_id => 
          -init => "\$self->load_class('$class_id')";
    $self->$class_id($object);
    $object->init;
    return $object;
}

sub add_hooks {
    return unless $self->registry_loaded;
    my $hooks = $self->registry->lookup->{hook}
      or return;
    for my $class_name (keys %$hooks) {
        next unless $class_name->can('new');
        $self->add_hook(@$_) for @{$hooks->{$class_name} || []};
        delete $hooks->{$class_name};
    }
    delete $self->registry->lookup->{hook}
      if not keys %$hooks;
}

sub add_hook {
    my $hooks = $self->all_hooks;
    push @$hooks, $self->hooks->add(@_);
    return $hooks->[-1];
}

sub remove_hooks {
    my $hooks = $self->all_hooks;
    while (@$hooks) {
        pop(@$hooks)->unhook;
    }
}

sub registry_loaded {
    defined $self->{registry} &&
    defined $self->{registry}{lookup};
}

sub DESTROY {
    $self->remove_hooks;
}

__END__

=head1 NAME 

Spoon::Hub - Spoon Hub Base Class

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
