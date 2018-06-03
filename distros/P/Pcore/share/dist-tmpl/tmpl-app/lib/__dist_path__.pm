package <: $module_name :> v0.0.0;

use Pcore -dist, -class, -const, -res;
use <: $module_name ~ "::Const qw[:CONST]" :>;
use <: $module_name ~ "::Util" :>;

has cfg => ( is => 'ro', isa => HashRef, required => 1 );

has util => ( is => 'ro', isa => InstanceOf ['<: $module_name :>::Util'], init_arg => undef );

with qw[Pcore::App];

const our $APP_API_ROLES => [ 'admin', 'user' ];

sub run ( $self ) {
    $self->{util} = <: $module_name ~ "::Util" :>->new;

    # update schema
    print 'Updating DB schema ... ';
    say( my $res = $self->{util}->update_schema( $self->{cfg}->{_}->{db} ) );
    return $res if !$res;

    # load settings
    $res = $self->{util}->load_settings;

    # run RPC
    print 'Starting RPC hub ... ';
    say $self->{node}->run_node(
        {   type           => '<: $module_name :>::RPC::Worker',
            workers        => 1,
            token          => undef,
            listen_events  => undef,
            forward_events => ['APP.SETTINGS_UPDATED'],
            buildargs      => {                                    #
                cfg  => $self->{cfg},
                util => $self->{util},
            },
        },
        {   type           => '<: $module_name :>::RPC::Log',
            workers        => 1,
            token          => undef,
            listen_events  => undef,
            forward_events => undef,
            buildargs      => {                                    #
                cfg  => $self->{cfg},
                util => { settings => $self->{util}->{settings} },
            },
        },
    );

    $self->{node}->wait_for_online;

    # app ready
    return res 200;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 4, 5                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 9, 29, 39            | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 73                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 77 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

<: $author :> <<: $author_email :>>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) <: $copyright_year :> by <: $copyright_holder :>.

=cut
