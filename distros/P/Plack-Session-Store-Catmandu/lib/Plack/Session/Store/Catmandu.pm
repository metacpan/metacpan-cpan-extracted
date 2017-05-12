package Plack::Session::Store::Catmandu;

=head1 NAME

Plack::Session::Store::Catmandu - Plack session store backed by a Catmandu::Store

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::Session;
    use Plack::Session::Store::Catmandu;

    my $app = sub {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ];
    };

    builder {
        enable 'Session', store => Plack::Session::Store::Catmandu->new(
            store => 'MongoDB',
            bag => 'sessions',
        );
        $app;
    };

=cut

use Catmandu::Sane;
use parent qw(Plack::Session::Store);
use Catmandu;

sub new {
    my ($class, %opts) = @_;
    bless {
        store_name => $opts{store} // Catmandu->default_store,
        bag_name => $opts{bag} // 'session',
    }, $class;
}

sub bag {
    my ($self) = @_;
    $self->{bag} ||= Catmandu->store($self->{store_name})->bag($self->{bag_name});
}

sub fetch {
    my ($self, $id) = @_;
    my $obj = $self->bag->get($id) || return;
    delete $obj->{_id};
    $obj;
}

sub store {
    my ($self, $id, $obj) = @_;
    $obj->{_id} = $id;
    $self->bag->add($obj);
    delete $obj->{_id};
    $obj;
}

sub remove {
    my ($self, $id) = @_;
    $self->bag->delete($id);
}

1;

=head1 SEE ALSO

L<Plack::Middleware::Session>, L<Catmandu>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
