package Pcore::App::API::Auth::Cache;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken];

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has private_token => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );    # private_token_hash -> auth
has _depends_on => ( is => 'ro', isa => HashRef, init_arg => undef );
has _auth_ev => ( is => 'ro', isa => InstanceOf ['Pcore::Core::Event::Listener'], init_arg => undef );

# listen AUTH events
sub BUILD ( $self, $args ) {
    weaken $self;

    $self->{_auth_ev} = P->listen_events(
        'AUTH',
        sub ($ev) {
            $self->on_auth_event($ev);

            return;
        }
    );

    return;
}

sub drop_cache ($self) {
    delete $self->{private_token};

    delete $self->{_depends_on};

    return;
}

sub store ( $self, $auth ) {
    my $private_token_hash = $auth->{private_token}->[2];

    $self->{private_token}->{$private_token_hash} = $auth;

    if ( $auth->{depends_on} ) {
        for my $id ( $auth->{depends_on}->@* ) {
            $self->{_depends_on}->{$id}->{$private_token_hash} = undef;
        }
    }

    return;
}

sub delete_private_token ( $self, $private_token_hash ) {
    if ( my $auth = delete $self->{private_token}->{$private_token_hash} ) {

        if ( $auth->{depends_on} ) {
            for my $id ( $auth->{depends_on}->@* ) {
                delete $self->{_depends_on}->{$id}->{$private_token_hash};

                delete $self->{_depends_on}->{$id} if !$self->{_depends_on}->{$id}->%*;
            }
        }
    }

    return;
}

sub on_auth_event ( $self, $ev ) {
    if ( my $priv_tokens = delete $self->{_depends_on}->{ $ev->{data} } ) {
        for my $private_token_hash ( keys $priv_tokens->%* ) {
            $self->delete_private_token($private_token_hash);
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Auth::Cache

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
