package Pcore::App::Controller::Ext;

use Pcore -role, -const, -l10n;
use Pcore::Ext;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_plain_arrayref];

has ext_app   => ( required => 1 );     # name of the linked application, required
has ext_title => 'ExtJS Application';

has _index => ();

# TODO api_url
sub BUILD ( $self, $args ) {

    # init Ext
    my $ext = $self->{app}->{ext} //= Pcore::Ext->new( app => $self->{app} );

    # TODO return if in production mode and app is absolute, eg: Module::Path::App
    return if index( $self->{ext_app}, '::' ) != -1 && !$self->{app}->{devel};

    # expand app namespace, if it is relative to the current dist
    my $ns = index( $self->{ext_app}, '::' ) == -1 ? ref( $self->{app} ) . '::Ext::' . $self->{ext_app} : $self->{ext_app};

    $ext->create_app(
        $self->{ext_app},
        {   namespace => $ns,
            cdn       => undef,    # maybe InstanceOf['Pcore::CDN']
            prefixes  => {
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

sub _get_app ($self) { return $self->{app}->{ext}->{ext_app}->{ $self->{ext_app} } }

around run => sub ( $orig, $self, $req ) {
    return $req->return_xxx(404) if !$self->_get_app;

    $self->_return_index($req);

    return;
};

sub _return_index ( $self, $req ) {
    my $app = $self->_get_app;

    if ( !$self->{_index} ) {
        push my $resources->@*, $app->get_resources( $self->{app}->{devel} )->@*;

        my $cdn = $self->{app}->{cdn};

        # overrides
        # push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('overrides.js') );
        push $resources->@*, $cdn->get_script_tag( $cdn->("/app/overrides.js") );

        # app
        # push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('app.js') );
        push $resources->@*, $cdn->get_script_tag( $cdn->("/app/$self->{ext_app}/app.js") );

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
## |    3 | 63                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
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
