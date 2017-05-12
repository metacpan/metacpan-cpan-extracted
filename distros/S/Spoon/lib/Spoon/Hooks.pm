package Spoon::Hooks;
use Spoon::Base -Base;

const hook_class => 'Spoon::Hook';
const hooked_class => 'Spoon::Hooked';

sub add {
    my ($target, %hooks) = @_;
    my $original = $self->assert_method($target);
    my $pre = $self->assert_method($hooks{pre});
    my $post = $self->assert_method($hooks{post});
    my $replacement = $self->new_hook_sub($original, $pre, $post);
    my $hook_point = $self->get_full_name($target);
    no warnings 'redefine';
    no strict 'refs';
    *$hook_point = $replacement;

    return $self->hooked_class->new(
        hook_point => $hook_point,
        original => $original, 
        replacement => $replacement, 
    );
}

sub new_hook_sub {
    my ($original, $pre, $post) = @_;
    sub {
        my $hook = $self->hook_class->new(
            code => $original,
            pre => $pre,
            post => $post,
        );
        $hook->returned([$hook->pre->(@_, $hook)]) 
          if $pre;
        my $code = $hook->code
          or return $hook->returned;
        my $new_args = $hook->new_args;
        @_ = @$new_args 
          if $new_args;
        $hook->returned([&$code(@_)]);
        return $hook->post->(@_, $hook) 
          if $hook->post;
        return $hook->returned;
    }
}

sub assert_method {
    return shift
      if not defined($_[0]) or ref($_[0]);
    my $full_name = $self->get_full_name(shift);
    my ($package, $method) = ($full_name) =~ /(.*)::(.*)/
      or die "Can't hook invalid fully qualified method name: '$full_name'";
    unless ($package->can('new')) {
        eval "require $package";
        undef($@);
        die "Can't hook $full_name. Can't find package '$package'"
          unless $package->can('new');
    }
    my $sub = $full_name;
    return \&$sub if defined &$sub;
    no strict 'refs';
    *$sub = eval <<END;
sub { 
    package $package;
    my \$self = shift;
    \$self->SUPER::$method(\@_);
};
END
    return \&$sub;
}

sub get_full_name {
    my $name = shift;
    return $name if $name =~ /::/;
    if ($name =~ /(.*):(.*)/) {
        my ($class_id, $method) = ($1, $2);
        my $package = $self->hub->registry->lookup->classes->{$class_id};
        return $package . '::' . $method;
    }
    return '';
}

package Spoon::Hooked;
use Spoon::Base -Base;

field 'hook_point';
field 'original';
field 'replacement';

sub unhook {
    my ($hook_point, $original, $replacement) = 
      @{$self}{qw(hook_point original replacement)};
    %$self = ();
    return unless defined $hook_point;
    no strict 'refs';
    my $current = *$hook_point{CODE};

    die "Unhooking error for $hook_point"
      unless "$current" eq "$replacement";
    no warnings;
    *$hook_point = $original;
    return 1;
}

sub DESTROY {
    $self->unhook;
}

package Spoon::Hook;
use Spoon::Base -Base;

field 'code';
field 'pre';
field 'post';
field 'new_args';

sub returned {
    $self->{returned} = shift if @_;
    $self->{returned} ||= [];
    wantarray ? (@{$self->{returned}}) : $self->{returned}[0];
}

sub returned_true {
    @{$self->{returned}} && $self->{returned}[0] && 1;
}

sub cancel {
    $self->code(undef);
    return ();
}

__END__

=head1 NAME 

Spoon::Hook - Spoon Method Hooking Facility

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
