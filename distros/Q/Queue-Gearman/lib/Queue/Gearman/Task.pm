package Queue::Gearman::Task;
use strict;
use warnings;
use utf8;

use Carp qw/carp/;
use Scalar::Util qw/weaken/;
use Queue::Gearman::Message qw/:headers :msgtypes/;

use Class::Accessor::Lite ro => [qw/
    func
    arg
    handle
    socket
    taskset
    is_background
    owner_pid
/], rw => [qw/data warning fail status exception result done/];

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        %args,
        owner_pid => $$,
    } => $class;
    $self->taskset->add($self);
    return $self;
}

sub is_finished { shift->done }

sub remove {
    my $self = shift;
    $self->taskset->remove($self->handle);
}

sub get_status {
    my $self = shift;
    unless ($self->is_background) {
        carp 'Can get status of background job only.';
        return;
    }
    $self->taskset->update_statuses();
    return @{ $self->status || [] };
}

sub wait :method {
    my $self = shift;
    return $self if $self->is_finished;

    if ($self->is_background) {
        carp 'Can wait for forground job only.';
        return $self;
    }

    $self->taskset->wait(@_);
    return $self;
}

sub DESTROY {
    my $self = shift;
    return if $self->{owner_pid} != $$;

    $self->remove();
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Queue::Gearman::Task - TODO

=head1 SYNOPSIS

    use Queue::Gearman::Task;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
