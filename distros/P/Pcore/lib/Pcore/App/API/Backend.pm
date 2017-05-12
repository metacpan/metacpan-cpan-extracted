package Pcore::App::API::Backend;

use Pcore -role;

requires(

    # INIT
    '_build_host',
    '_build_is_local',
    'init',
    'register_app_instance',
    'connect_app_instance',

    # AUTH
    'auth_token',
);

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has is_local     => ( is => 'lazy', isa => Bool, init_arg => undef );                   # backend is local or remote
has host         => ( is => 'lazy', isa => Str,  init_arg => undef );                   # backend host name
has is_connected => ( is => 'ro',   isa => Bool, default  => 0, init_arg => undef );    # backend is connected

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
