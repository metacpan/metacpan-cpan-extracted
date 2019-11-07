package <: $module_name :>;

use Pcore -dist, -class, -const, -res;
use <: $module_name ~ "::Const qw[:CONST]" :>;
use <: $module_name ~ "::Util" :>;

has cfg => ( required => 1 );

has util => ( init_arg => undef );    # InstanceOf ['<: $module_name :>::Util']

with qw[Pcore::App];

const our $PERMISSIONS => [ 'admin', 'user' ];

const our $NODE_REQUIRES => {
    '<: $module_name :>::Node::Worker' => undef,
    '<: $module_name :>::Node::Log'    => undef,
};

sub NODE_ON_EVENT ( $self, $ev ) {
    P->forward_event($ev);

    return;
}

sub NODE_ON_RPC ( $self, $ev ) {
    return;
}

const our $LOCALES => {
    en => 'English',
    de => 'Deutsche',
    ru => 'Русский',
};

# PERMISSIONS
sub get_permissions ($self) {
    return $PERMISSIONS;
}

# LOCALES
sub get_locales ($self) {
    return $LOCALES;
}

sub get_default_locale ( $self, $req ) {
    return 'en';
}

# RUN
sub run ( $self ) {
    $self->{util} = <: $module_name ~ "::Util" :>->new;

    # update schema
    print 'Updating DB schema ... ';
    say( my $res = $self->{util}->update_schema( $self->{cfg}->{db} ) );
    return $res if !$res;

    # load settings
    $res = $self->{util}->settings_load;

    # run local nodes
    print 'Starting nodes ... ';
    say $self->{node}->run_node(
        {   type      => '<: $module_name :>::Node::Worker',
            workers   => 1,
            buildargs => {
                cfg  => $self->{cfg},
                util => $self->{util},
            },
        },

        # {   type      => '<: $module_name :>::Node::Log',
        #     workers   => 1,
        #     buildargs => {
        #         cfg  => $self->{cfg},
        #         util => { settings => $self->{util}->{settings} },
        #     },
        # },
    );

    $self->{node}->wait_online;

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
## |    1 | 16, 17, 65           | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 104                  | Documentation::RequirePackageMatchesPodName - Pod NAME on line 108 does not match the package declaration      |
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
