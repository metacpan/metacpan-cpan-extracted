package MojoX::JSON::RPC::Service::AutoRegister;
use Mojo::Base 'MojoX::JSON::RPC::Service';
our $VERSION = 0.001;

=head1 NAME

MojoX::JSON::RPC::Service::AutoRegister - Base class for RPC Services

=head1 DESCRIPTION

This object represent a base class for RPC Services.
It only ovverides the C<new> to inject C<'with_mojo_tx'=1>, C<'with_svc_obj'=1> and C<'with_self'=1>  options by default.
For more information on how services work, have a look at
L<MojoX::JSON::RPC::Service>.

Every function that starts with C<rpc_> it's automatically registered as an
rpc service, this means that on your service file you must only add

    __PACKAGE__->register_rpc;

at the bottom of the code.
You can also defines your suffix or your regex to match the functions to being automatically registered.

=head1 METHODS

Inherits all methods from L<MojoX::JSON::RPC::Service> and adds the following new ones:

=head2 register_rpc

witouth arguments, register all the methods of the class that starts with "rpc_" as a RPC services

=head2 register_rpc_suffix

    __PACKAGE__->register_rpc_suffix("somesuffix");

Accept  an argument, the suffix name. Register all the methods of the class that starts with the given suffix as a RPC services (e.g. somesuffix_edit, somesuffix_lay )

=head2 register_rpc_regex

    __PACKAGE__->register_rpc_regex(qr//);

Accept  an argument, a regex. Register all the methods of the class that matches the given regex as a RPC services

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>, vytas E<lt>vytas@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler, vytas

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MojoX::JSON::RPC::Service>

=cut

sub new {
    my ( $self, @params ) = @_;

    $self = $self->SUPER::new(@params);

    foreach my $method ( keys %{ $self->{'_rpcs'} } ) {
        $self->{'_rpcs'}->{$method}->{'with_mojo_tx'} = 1;
        $self->{'_rpcs'}->{$method}->{'with_svc_obj'} = 1;
        $self->{'_rpcs'}->{$method}->{'with_self'}    = 1;
    }

    return $self;
}

sub register_rpc {
    my $caller_package_name = caller;

    MojoX::JSON::RPC::Service::AutoRegister->register_rpc_regex(
        qr/^ rpc _ /x, $caller_package_name, );
}

sub register_rpc_suffix {
    my ( undef, $suffix ) = @_;

    my $caller_package_name = caller;

    MojoX::JSON::RPC::Service::AutoRegister->register_rpc_regex(
        qr/^ $suffix _ /x,
        $caller_package_name, );
}

sub register_rpc_regex {
    my ( undef, $regex, $package ) = @_;
    $package = caller if ( !defined($package) );

    my @methods = ();
    my $symbols = { eval( '%' . $package . '::' ) };

    foreach my $entry ( keys %{$symbols} ) {

        # this allows functions that match the regex to be automatically
        # exported as rpc public services
        if ( defined( $package->can($entry) ) && ( $entry =~ $regex ) ) {
            push( @methods, $entry );
        }
    }

    $package->register_rpc_method_names(@methods);
}

1;
