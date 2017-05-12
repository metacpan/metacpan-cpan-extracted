package POE::Component::Pluggable::Pipeline;
$POE::Component::Pluggable::Pipeline::VERSION = '1.28';
#ABSTRACT: the plugin pipeline for POE::Component::Pluggable

use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);

sub new {
    my ($package, $pluggable) = @_;

    my $self = bless {
        PLUGS    => {},
        PIPELINE => [],
        HANDLES  => {},
        OBJECT   => $pluggable,
    }, $package;

    weaken($self->{OBJECT});

    return $self;
}

sub push {
    my ($self, $alias, $plug) = @_;

    if ($self->{PLUGS}{$alias}) {
        $@ = "Plugin named '$alias' already exists ($self->{PLUGS}{$alias})";
        return;
    }

    my $return = $self->_register($alias, $plug);
    return if !$return;

    push @{ $self->{PIPELINE} }, $plug;
    return scalar @{ $self->{PIPELINE} };
}

sub pop {
    my ($self) = @_;

    return if !@{ $self->{PIPELINE} };

    my $plug = pop @{ $self->{PIPELINE} };
    my $alias = $self->{PLUGS}{$plug};
    $self->_unregister($alias, $plug);

    return wantarray ? ($plug, $alias) : $plug;
}

sub unshift {
    my ($self, $alias, $plug) = @_;

    if ($self->{PLUGS}{$alias}) {
        $@ = "Plugin named '$alias' already exists ($self->{PLUGS}{$alias}";
        return;
    }

    my $return = $self->_register($alias, $plug);
    return if !$return;

    unshift @{ $self->{PIPELINE} }, $plug;
    return scalar @{ $self->{PIPELINE} };
}

sub shift {
    my ($self) = @_;

    return if !@{ $self->{PIPELINE} };

    my $plug = shift @{ $self->{PIPELINE} };
    my $alias = $self->{PLUGS}{$plug};
    $self->_unregister($alias, $plug);

    return wantarray ? ($plug, $alias) : $plug;
}

sub replace {
    my ($self, $old, $new_a, $new_p) = @_;

    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;

    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return;
    }

    $self->_unregister($old_a, $old_p);

    if ($self->{PLUGS}{$new_a}) {
        $@ = "Plugin named '$new_a' already exists ($self->{PLUGS}{$new_a}";
        return;
    }

    my $return = $self->_register($new_a, $new_p);
    return if !$return;

    for my $plugin (@{ $self->{PIPELINE} }) {
        if ($plugin == $old_p) {
            $plugin = $new_p;
            last;
        }
    }

    return 1;
}

sub remove {
    my ($self, $old) = @_;
    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;

    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return;
    }

    my $i = 0;
    for my $plugin (@{ $self->{PIPELINE} }) {
        if ($plugin == $old_p) {
            splice(@{ $self->{PIPELINE} }, $i, 1);
            last;
        }
        $i++;
    }

    $self->_unregister($old_a, $old_p);

    return wantarray ? ($old_p, $old_a) : $old_p;
}

sub get {
    my ($self, $old) = @_;

    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;


    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return;
    }

    return wantarray ? ($old_p, $old_a) : $old_p;
}

sub get_index {
    my ($self, $old) = @_;

    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;

    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return -1;
    }

    my $i = 0;
    for my $plugin (@{ $self->{PIPELINE} }) {
        return $i if $plugin == $old_p;
        $i++;
    }

    return -1;
}

sub insert_before {
    my ($self, $old, $new_a, $new_p) = @_;

    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;

    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return;
    }

    if ($self->{PLUGS}{$new_a}) {
        $@ = "Plugin named '$new_a' already exists ($self->{PLUGS}{$new_a}";
        return;
    }

    my $return = $self->_register($new_a, $new_p);
    return if !$return;

    my $i = 0;
    for my $plugin (@{ $self->{PIPELINE} }) {
        if ($plugin == $old_p) {
            splice(@{ $self->{PIPELINE} }, $i, 0, $new_p);
            last;
        }
        $i++;
    }

    return 1;
}

sub insert_after {
    my ($self, $old, $new_a, $new_p) = @_;
    my ($old_a, $old_p) = ref $old
        ? ($self->{PLUGS}{$old}, $old)
        : ($old, $self->{PLUGS}{$old})
    ;

    if (!$old_p) {
        $@ = "Plugin '$old_a' does not exist";
        return;
    }

    if ($self->{PLUGS}{$new_a}) {
        $@ = "Plugin named '$new_a' already exists ($self->{PLUGS}{$new_a}";
        return;
    }

    my $return = $self->_register($new_a, $new_p);
    return if !$return;

    my $i = 0;
    for my $plugin (@{ $self->{PIPELINE} }) {
        if ($plugin == $old_p) {
            splice(@{ $self->{PIPELINE} }, $i+1, 0, $new_p);
            last;
        }
        $i++;
    }

    return 1;
}

sub bump_up {
    my ($self, $old, $diff) = @_;
    my $idx = $self->get_index($old);

    return -1 if $idx < 0;

    my $pipeline = $self->{PIPELINE};
    $diff ||= 1;

    my $pos = $idx - $diff;

    if ($pos < 0) {
        carp "$idx - $diff is negative, moving to head of the pipeline";
    }

    splice(@$pipeline, $pos, 0, splice(@$pipeline, $idx, 1));
    return $pos;
}

sub bump_down {
    my ($self, $old, $diff) = @_;
    my $idx = $self->get_index($old);

    return -1 if $idx < 0;

    my $pipeline = $self->{PIPELINE};
    $diff ||= 1;

    my $pos = $idx + $diff;

    if ($pos >= @$pipeline) {
        carp "$idx + $diff is too high, moving to back of the pipeline";
    }

    splice(@$pipeline, $pos, 0, splice(@$pipeline, $idx, 1));
    return $pos;
}

sub _register {
    my ($self, $alias, $plug) = @_;
    return if !defined $self->{OBJECT};

    my $return;
    my $sub = "$self->{OBJECT}{_pluggable_reg_prefix}register";
    eval { $return = $plug->$sub($self->{OBJECT}) };

    if ($@) {
        chomp $@;
        my $error = "$sub call on plugin '$alias' failed: $@";
        $self->_handle_error($error, $plug, $alias);
    }
    elsif (!$return) {
        my $error = "$sub call on plugin '$alias' did not return a true value";
        $self->_handle_error($error, $plug, $alias);
    }

    $self->{PLUGS}{$plug} = $alias;
    $self->{PLUGS}{$alias} = $plug;

    $self->{OBJECT}->_pluggable_event(
        "$self->{OBJECT}{_pluggable_prefix}plugin_add",
        $alias, $plug,
    );

    return $return;
}

sub _unregister {
    my ($self, $alias, $plug) = @_;
    return if !defined $self->{OBJECT};

    my $return;
    my $sub = "$self->{OBJECT}{_pluggable_reg_prefix}unregister";
    eval { $return = $plug->$sub($self->{OBJECT}) };

    if ($@) {
        chomp $@;
        my $error = "$sub call on plugin '$alias' failed: $@";
        $self->_handle_error($error, $plug, $alias);
    }
    elsif (!$return) {
        my $error = "$sub call on plugin '$alias' did not return a true value";
        $self->_handle_error($error, $plug, $alias);
    }

    delete $self->{PLUGS}{$plug};
    delete $self->{PLUGS}{$alias};
    delete $self->{HANDLES}{$plug};

    $self->{OBJECT}->_pluggable_event(
        "$self->{OBJECT}{_pluggable_prefix}plugin_del",
        $alias, $plug,
    );

    return $return;
}

sub _handle_error {
    my ($self, $error, $plugin, $alias) = @_;

    warn "$error\n" if $self->{OBJECT}{_pluggable_debug};
    $self->{OBJECT}->_pluggable_event(
        "$self->{OBJECT}{_pluggable_prefix}plugin_error",
        $error, $plugin, $alias,
    );

    return;
}

qq[Pipey McPipeline];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Pluggable::Pipeline - the plugin pipeline for POE::Component::Pluggable

=head1 VERSION

version 1.28

=head1 SYNOPSIS

  use POE qw( Component::Pluggable );
  use POE::Component::Pluggable::Pipeline;
  use My::Plugin;

  my $self = POE::Component::Pluggable->new();

  # the following operations are presented in pairs
  # the first is the general procedure, the second is
  # the specific way using the pipeline directly

  # to install a plugin
  $self->plugin_add(mine => My::Plugin->new);
  $self->pipeline->push(mine => My::Plugin->new);  

  # to remove a plugin
  $self->plugin_del('mine');        # or the object
  $self->pipeline->remove('mine');  # or the object

  # to get a plugin
  my $plug = $self->plugin_get('mine');
  my $plug = $self->pipeline->get('mine');

  # there are other very specific operations that
  # the pipeline offers, demonstrated here:

  # to get the pipeline object itself
  my $pipe = $self->pipeline;

  # to install a plugin at the front of the pipeline
  $pipe->unshift(mine => My::Plugin->new);

  # to remove the plugin at the end of the pipeline
  my $plug = $pipe->pop;

  # to remove the plugin at the front of the pipeline
  my $plug = $pipe->shift;

  # to replace a plugin with another
  $pipe->replace(mine => newmine => My::Plugin->new);

  # to insert a plugin before another
  $pipe->insert_before(mine => newmine => My::Plugin->new);

  # to insert a plugin after another
  $pipe->insert_after(mine => newmine => My::Plugin->new);

  # to get the location in the pipeline of a plugin
  my $index = $pipe->get_index('mine');

  # to move a plugin closer to the front of the pipeline
  $pipe->bump_up('mine');

  # to move a plugin closer to the end of the pipeline
  $pipe->bump_down('mine');

=head1 DESCRIPTION

POE::Component::Pluggable::Pipeline defines the Plugin pipeline system
for L<POE::Component::Pluggable|POE::Component::Pluggable> instances.

=head1 METHODS

=head2 C<new>

Takes one argument, the POE::Component::Pluggable object to attach to.

=head2 C<push>

Takes two arguments, an alias for a plugin and the plugin object itself.
If a plugin with that alias already exists, C<$@> will be set and C<undef>
will be returned. Otherwise, it adds the plugin to the end of the pipeline
and registers it. This will yield a C<plugin_add> event. If successful, it
returns the size of the pipeline.

 my $new_size = $pipe->push($name, $plug);

=head2 C<unshift>

Takes two arguments, an alias for a plugin and the plugin object itself.
If a plugin with that alias already exists, C<$@> will be set and C<undef>
will be returned. Otherwise, it adds the plugin to the beginning of the
pipeline and registers it. This will yield a C<plugin_add> event. If
successful, it returns the size of the pipeline.

 my $new_size = $pipe->push($name, $plug);

=head2 C<shift>

Takes no arguments. The first plugin in the pipeline is removed. This will
yield a C<plugin_del> event. In list context, it returns the plugin and its
alias; in scalar context, it returns only the plugin. If there were no
elements, an empty list or C<undef> will be returned.

 my ($plug, $name) = $pipe->shift;
 my $plug = $pipe->shift;

=head2 C<pop>

Takes no arguments. The last plugin in the pipeline is removed. This will
yield an C<plugin_del> event. In list context, it returns the plugin and its
alias; in scalar context, it returns only the plugin. If there were no
elements, an empty list or C<undef> will be returned.

 my ($plug, $name) = $pipe->pop;
 my $plug = $pipe->pop;

=head2 C<replace>

Take three arguments, the old plugin or its alias, an alias for the new
plugin and the new plugin object itself. If the old plugin doesn't exist,
or if there is already a plugin with the new alias (besides the old plugin),
$@ will be set and C<undef> will be returned. Otherwise, it removes the old
plugin (yielding an C<plugin_del> event) and replaces it with the new
plugin. This will yield an C<plugin_add> event. If successful, it returns 1.

 my $success = $pipe->replace($name, $new_name, $new_plug);
 my $success = $pipe->replace($plug, $new_name, $new_plug);

=head2 C<insert_before>

Takes three arguments, the plugin that is relative to the operation,
an alias for the new plugin and the new plugin object itself. If the first
plugin doesn't exist, or if there is already a plugin with the new alias,
C<$@> will be set and C<undef> will be returned. Otherwise, the new plugin is
placed just prior to the other plugin in the pipeline. If successful,
it returns 1.

 my $success = $pipe->insert_before($name, $new_name, $new_plug);
 my $success = $pipe->insert_before($plug, $new_name, $new_plug);

=head2 C<insert_after>

Takes three arguments, the plugin that is relative to the operation,
an alias for the new plugin and the new plugin object itself. If the
first plugin doesn't exist, or if there is already a plugin with the
new alias, C<$@> will be set and C<undef> will be returned. Otherwise,
the new plugin is placed just after to the other plugin in the pipeline.
If successful, it returns 1.

 my $success = $pipe->insert_after($name, $new_name, $new_plug);
 my $success = $pipe->insert_after($plug, $new_name, $new_plug);

=head2 C<bump_up>

Takes one or two arguments, the plugin or its alias, and the distance to
bump the plugin. The distance defaults to 1. If the plugin doesn't exist,
C<$@> will be set and B<-1 will be returned, not undef>. Otherwise, the
plugin will be moved the given distance closer to the front of the
pipeline. A warning is issued alerting you if it would have been moved
past the beginning of the pipeline, and the plugin is placed at the
beginning. If successful, the new index of the plugin in the pipeline is
returned.

 my $pos = $pipe->bump_up($name);
 my $pos = $pipe->bump_up($plug);
 my $pos = $pipe->bump_up($name, $delta);
 my $pos = $pipe->bump_up($plug, $delta);

=head2 C<bump_down>

Takes one or two arguments, the plugin or its alias, and the distance to
bump the plugin. The distance defaults to 1. If the plugin doesn't exist,
C<$@> will be set and B<-1 will be returned, not C<undef>>. Otherwise, the
plugin will be moved the given distance closer to the end of the pipeline.
A warning is issued alerting you if it would have been moved past the end
of the pipeline, and the plugin is placed at the end. If successful, the new
index of the plugin in the pipeline is returned.

 my $pos = $pipe->bump_down($name);
 my $pos = $pipe->bump_down($plug);
 my $pos = $pipe->bump_down($name, $delta);
 my $pos = $pipe->bump_down($plug, $delta);

=head2 C<remove>

Takes one argument, a plugin or its alias. If the plugin doesn't exist,
C<$@> will be set and C<undef> will be returned. Otherwise, the plugin is
removed from the pipeline. This will yield an C<plugin_del> event. In list
context,it returns the plugin and its alias; in scalar context, it returns
only the plugin.

 my ($plug, $name) = $pipe->remove($the_name);
 my ($plug, $name) = $pipe->remove($the_plug);
 my $plug = $pipe->remove($the_name);
 my $plug = $pipe->remove($the_plug);

=head2 C<get>

Takes one argument, a plugin or its alias. If no such plugin exists, C<$@>
will be set and C<undef> will be returned. In list context, it returns the
plugin and its alias; in scalar context, it returns only the plugin.

 my ($plug, $name) = $pipe->get($the_name);
 my ($plug, $name) = $pipe->get($the_plug);
 my $plug = $pipe->get($the_name);
 my $plug = $pipe->get($the_plug);

=head2 C<get_index>

Takes one argument, a plugin or its alias. If no such plugin exists, C<$@>
will be set and B<-1 will be returned, not C<undef>>. Otherwise, the index
in the pipeline is returned.

 my $pos = $pipe->get_index($name);
 my $pos = $pipe->get_index($plug);

=head1 BUGS

None known so far.

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>,

L<POE::Component::Pluggable|POE::Component::Pluggable>.

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Apocalypse <perl@0ne.us>

=item *

Hinrik Örn Sigurðsson

=item *

Jeff Pinyan

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
