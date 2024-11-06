package Mojo::UserAgent::Role::TotalTimeout;

use strict;
use warnings;

use Mojo::Base -role;
use Time::HiRes 'time';
use Scalar::Util 'weaken';

our $VERSION = "v0.0.1";

has 'total_timeout';

around _start => sub {
    my ($orig, $self, $loop, $tx, @args) = @_;

    my $end_time;
    my $now = time;

    if (my $prev = $tx->previous) {
        if (Role::Tiny::does_role($prev, 'Mojo::Transaction::HTTP::Role::TotalTimeout')) {
            $tx->with_roles('+TotalTimeout')->__TotalTimeout__absolute_end_time(
                $end_time = $prev->__TotalTimeout__absolute_end_time
            );
        }
    } elsif (my $t = $self->total_timeout) {
        $tx->with_roles('+TotalTimeout')->__TotalTimeout__absolute_end_time($end_time = $now + $t);
    }

    # call original
    my $id = $self->$orig($loop, $tx, @args);

    if ($end_time) {
        if (my $t_other = $self->request_timeout) {
            if ($end_time < $now + $t_other) {
                $loop->remove($self->{connections}{$id}{timeout});
                $self->__TotalTimeout__set_timeout($id, $loop, $end_time);
            }
        } else {
            $self->__TotalTimeout__set_timeout($id, $loop, $end_time);
        }
    }

    return $id;
};

sub __TotalTimeout__set_timeout {
    my ($self, $id, $loop, $end_time) = @_;

    weaken $self;
    $self->{connections}{$id}{timeout} ||= $loop->timer(
        $end_time - time(),
        sub { $self->_error($id, 'Total timeout') },
    );
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::Role::TotalTimeout - Role for Mojo::UserAgent that enables setting total timeout including redirects

=head1 SYNOPSIS

    use Mojo::UserAgent;

    my $class = Mojo::UserAgent->with_roles('+TotalTimeout');
    my $ua = $class->max_redirects(5)->total_timeout(10);

=head1 DESCRIPTION

Mojo::UserAgent::Role::TotalTimeout is a role for LMojo::UserAgent> that simply allows setting a total timeout to
the useragent that includes redirects.

=head1 ATTRIBUTES

Mojo::UserAgent::Role::Timeout adds the following attribute to the L<Mojo::UserAgent> object:

=head2 total_timeout

    my $ua = $class->new;
    $ua->total_timeout(10);

The number of seconds the whole request (including redirections) will timeout at.

Defaults to 0, which disables the time limit.

L<Mojo::UserAgent>'s other timeouts (like C<request_timeout>) still apply regardless of this attribute's value.

=head1 TODO

=over 1

=item * Write tests

=back

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut

