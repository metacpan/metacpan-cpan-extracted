package Pcore::App::Controller::Ext;

use Pcore -role, -const, -l10n;
use Pcore::Ext;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_plain_arrayref];

has ext_app   => ( required => 1 );     # name of the linked application, required
has ext_title => 'ExtJS Application';

has _bootstrap => ();

# TODO api_url
sub BUILD ( $self, $args ) {
    my $ns = ref( $self->{app} ) . '::Ext::' . $self->{ext_app};

    my $app = $self->{app}->{ext}->{ $self->{ext_app} } = Pcore::Ext->new(
        namespace => $ns,
        app       => $self->{app},      # maybe Pcore::App instance
        cdn       => undef,             # maybe Pcore::CDN instance
        prefixes  => {
            pcore => undef,
            dist  => undef,
            app   => undef,
        },

        # TODO
        # api_url => $self->{app}->{router}->get_host_api_path( $req->{host} ),
    );

    $app->build;

    die qq[Ext app "$self->{ext_app}" not found] if !defined $self->{app}->{ext}->{ $self->{ext_app} };

    return;
}

sub _get_app ($self) { return $self->{app}->{ext}->{ $self->{ext_app} } }

around run => sub ( $orig, $self, $req ) {
    if ( defined $req->{path} ) {
        if ( $req->{path} eq 'app.js' ) {
            $self->_return_app($req);
        }
        elsif ( $req->{path} eq 'overrides.js' ) {
            $self->_return_overrides($req);
        }
        elsif ( $req->{path} eq 'locale.js' ) {
            $self->_return_locale($req);
        }
        else {
            $self->$orig($req);
        }
    }
    else {
        $self->_return_bootstrap($req);
    }

    return;
};

sub _return_bootstrap ( $self, $req ) {
    my $app = $self->_get_app;

    if ( !$self->{_bootstrap} ) {
        push my $resources->@*, $app->get_resources( $self->{app}->{devel} )->@*;

        my $cdn = $self->{app}->{cdn};

        # overrides
        push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('overrides.js') );

        # app
        push $resources->@*, $cdn->get_script_tag( $self->get_abs_path('app.js') );

        # generate HTML tmpl
        $self->{_bootstrap} = \P->text->encode_utf8(
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

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{_bootstrap} )->finish;

    return;
}

sub _return_overrides ( $self, $req ) {
    my $app = $self->_get_app;

    my $etag = 'W/' . $app->get_overrides_md5( $self->{app}->{devel} );

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $etag ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $etag ], $app->get_overrides( $self->{app}->{devel} ) )->finish;
    }

    return;
}

sub _return_locale ( $self, $req ) {
    my $app = $self->_get_app;

    # get locale from query param
    ( my $locale ) = $req->{env}->{QUERY_STRING} =~ m/locale=([[:alpha:]-]+)/sm;

    return $req->(404)->finish if !$locale;

    my $etag = $app->get_locale_md5( $locale, $self->{app}->{devel} );

    return $req->(404)->finish if !$etag;

    $etag = 'W/' . $etag;

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $etag ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $etag ], $app->get_locale( $locale, $self->{app}->{devel} ) )->finish;
    }

    return;
}

sub _return_app ( $self, $req ) {
    my $app = $self->_get_app;

    my $etag = 'W/' . $app->get_app_md5( $self->{app}->{devel} );

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $etag ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $etag ], $app->get_app( $self->{app}->{devel} ) )->finish;
    }

    return;
}

1;
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
