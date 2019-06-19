package Pcore::App::Controller::Ext;

use Pcore -role, -const, -l10n;
use Pcore::Ext;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_plain_arrayref];

has ext_package => ( required => 1 );     # name of the linked application, required
has ext_title   => 'ExtJS Application';

has _index => ();

# TODO api_url
sub BUILD ( $self, $args ) {

    # init Ext
    my $ext = $self->{app}->{ext} //= Pcore::Ext->new( app => $self->{app} );

    # expand relative package name
    if ( index( $self->{ext_package}, '::' ) == -1 ) {
        $self->{ext_package} = ref( $self->{app} ) . '::Ext::' . $self->{ext_package};
    }
    else {
        return if !P->class->find( $self->{ext_package} );
    }

    $ext->create_app(
        $self->{ext_package},
        {   cdn      => undef,    # maybe InstanceOf['Pcore::CDN']
            prefixes => {
                pcore => undef,
                dist  => undef,
                app   => undef,
            },

            # TODO
            # api_url => $self->{app}->{router}->get_host_api_path( $req->{host} ),
        }
    );

    return;
}

sub _get_app ($self) { return $self->{app}->{ext}->{ext_app}->{ $self->{ext_package} } }

around run => sub ( $orig, $self, $req ) {
    return $req->return_xxx(404) if !$self->_get_app;

    $self->_return_index($req);

    return;
};

sub get_resources ($self) {
    my $cdn = $self->{app}->{cdn};

    return [
        # $cdn->get_resources('jssha')->@*,
    ];
}

sub _return_index ( $self, $req ) {
    my $app = $self->_get_app;

    if ( !$self->{_index} ) {
        push my $resources->@*, $app->get_resources( $self->{app}->{devel} )->@*;

        my $cdn = $self->{app}->{cdn};

        push $resources->@*, $self->get_resources->@*;

        # overrides
        # push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('overrides.js') );
        push $resources->@*, $cdn->get_script_tag( $cdn->("/app/overrides.js") );

        # app
        # push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('app.js') );
        push $resources->@*, $cdn->get_script_tag( $cdn->("/app/$app->{id}/app.js") );

        # generate HTML tmpl
        $self->{_index} = \P->text->encode_utf8(
            P->tmpl->render(
                'ext/index.html',
                {   INDEX => {    #
                        title => $self->{ext_title}
                    },
                    resources => $resources,
                }
            )->$*
        );
    }

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{_index} )->finish;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 74                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::Ext - ExtJS application HTTP controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
