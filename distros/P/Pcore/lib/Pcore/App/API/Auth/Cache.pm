package Pcore::App::API::Auth::Cache;

use Pcore -class;

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has private_token => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has auth          => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub remove_auth ( $self, $auth_id ) {
    if ( my $auth = $self->{auth}->{$auth_id} ) {

        # remove private token
        delete $self->{private_token}->{ $auth->{private_token}->[2] };

        # remove auth
        delete $self->{auth}->{$auth_id};
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
