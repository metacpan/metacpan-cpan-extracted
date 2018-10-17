package Pcore::App::Controller::Ext;

use Pcore -role, -const, -l10n;
use Pcore::Ext;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_plain_arrayref];
use JavaScript::Packer qw[];
use JavaScript::Beautifier qw[];

has ext_app   => undef;                 # name of the linked application, required
has ext_title => 'ExtJS Application';
has ext_theme => ();

has _cache => ();

const our $DEFAULT_THEME_CLASSIC => 'aria';
const our $DEFAULT_THEME_MODERN  => 'material';

sub BUILD ( $self, $args ) {
    Pcore::Ext->scan( $self->{app}, ref( $self->{app} ) . '::Ext' );

    die qq[Ext app "$self->{ext_app}" not found] if !$Pcore::Ext::APP->{ $self->{ext_app} };

    return;
}

sub build_resources ( $self, $req, $type ) {
    return;
}

sub build_theme ( $self, $req, $type ) {
    ( my $theme ) = $req->{env}->{QUERY_STRING} =~ m/theme=([[:alpha:]-]+)/sm;

    return $theme;
}

around run => sub ( $orig, $self, $req ) {
    if ( $req->{path_tail} ) {
        if ( $req->{path_tail} eq 'app.js' ) {
            $self->_return_app($req);
        }
        elsif ( $req->{path_tail} eq 'overrides.js' ) {
            $self->_return_overrides($req);
        }
        elsif ( $req->{path_tail} eq 'locale.js' ) {
            $self->_return_locale($req);
        }
        else {
            $self->$orig($req);
        }
    }
    else {
        $self->_return_html($req);
    }

    return;
};

sub _return_html ( $self, $req ) {
    my $app = $Pcore::Ext::APP->{ $self->{ext_app} };

    my $theme = $self->build_theme( $req, $app->{ext_type} ) || $self->{ext_theme} || ( $app->{ext_type} eq 'classic' ? $DEFAULT_THEME_CLASSIC : $DEFAULT_THEME_MODERN );

    if ( !$self->{_cache}->{html}->{$theme} ) {
        my $resources = [ ( $self->build_resources( $req, $app->{ext_type} ) // [] )->@* ];

        # pcore/api.js
        push $resources->@*, qq[<script src="@{[ $self->{app}->{cdn}->("/static/pcore/api.js") ]}" integrity="" crossorigin="anonymous"></script>];

        # CDN resources
        push $resources->@*, $self->{app}->{cdn}->get_resources(
            [ 'ext', $app->{ext_ver}, $app->{ext_type}, $theme, $app->{ext_type} eq 'classic' ? $DEFAULT_THEME_CLASSIC : $DEFAULT_THEME_MODERN, $self->{app}->{devel} ],
            'fa',    # NOTE FontAwesme must be after ExtJS in resources or icons will not be displayed
        )->@*;

        # overrides
        push $resources->@*, qq[<script src="$self->{path}overrides.js" integrity="" crossorigin="anonymous"></script>];

        # TODO calc checksum 'sha384-' . P->digest->sha384_b64( $res->{body}->$* );
        push $resources->@*, qq[<script src="$self->{path}app.js" integrity="" crossorigin="anonymous"></script>];

        # generate HTML tmpl
        $self->{_cache}->{html}->{$theme} = \P->text->encode_utf8(
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

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{_cache}->{html}->{$theme} )->finish;

    return;
}

sub _return_overrides ( $self, $req ) {
    if ( !$self->{_cache}->{overrides} ) {
        my $app = $Pcore::Ext::APP->{ $self->{ext_app} };

        my $js = $Pcore::Ext::EXT->{ $app->{ext_type} };

        $self->{_cache}->{overrides}->{js} = $self->_prepare_js($js);

        $self->{_cache}->{overrides}->{etag} = 'W/' . P->digest->md5_hex( $self->{_cache}->{overrides}->{js}->$* );
    }

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $self->{_cache}->{overrides}->{etag} ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $self->{_cache}->{overrides}->{etag} ], $self->{_cache}->{overrides}->{js} )->finish;
    }

    return;
}

sub _return_locale ( $self, $req ) {
    state $locale_settings = {};

    # get locale from query param
    ( my $locale ) = $req->{env}->{QUERY_STRING} =~ m/locale=([[:alpha:]-]+)/sm;

    if ( !$locale || !$self->{app}->get_locales->{$locale} ) {
        $req->(404)->finish;

        return;
    }

    if ( !$self->{_cache}->{locale}->{$locale} ) {
        my $app = $Pcore::Ext::APP->{ $self->{ext_app} };

        $locale_settings->{$locale} //= $ENV->{share}->read_cfg( 'data', "ext/locale/$locale.perl" );

        # load locale
        Pcore::Core::L10N::load_locale($locale) if !exists $Pcore::Core::L10N::MESSAGES->{$locale};

        # get messages, used by app classes
        my $locale_messages = $Pcore::Core::L10N::MESSAGES->{$locale};

        # grep app messages, that have translation
        my $messages = { $locale_messages->%{ grep { $locale_messages->{$_} } keys $app->{l10n}->%* } };

        my $plural_form_exp = $Pcore::Core::L10N::LOCALE_PLURAL_FORM->{$locale}->{exp} // 0;

        my $js = <<"JS";
            Ext.L10N.addLocale(
                '$locale',
                {   messages: @{[ to_json( $messages, canonical => 1 )->$* ]},
                    pluralFormExp: function (n) { return $plural_form_exp; },
                    settings: @{[ to_json( $locale_settings->{$locale}, canonical => 1 )->$* ]}
                }
            );
JS

        $self->{_cache}->{locale}->{$locale}->{js} = $self->_prepare_js($js);

        $self->{_cache}->{locale}->{$locale}->{etag} = 'W/' . P->digest->md5_hex( $self->{_cache}->{locale}->{$locale}->{js}->$* );
    }

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $self->{_cache}->{locale}->{$locale}->{etag} ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $self->{_cache}->{locale}->{$locale}->{etag} ], $self->{_cache}->{locale}->{$locale}->{js} )->finish;
    }

    return;
}

sub _return_app ( $self, $req ) {
    my $app = $Pcore::Ext::APP->{ $self->{ext_app} };

    if ( !$self->{_cache}->{app} ) {
        my $ext_app = $Pcore::Ext::APP->{ $self->{ext_app} };

        my $data = {
            api_path => $self->{app}->{router}->get_host_api_path( $req->{host} ),
            api_map  => to_json(
                {   type    => 'websocket',                                                 # remoting
                    url     => $self->{app}->{router}->get_host_api_path( $req->{host} ),
                    actions => $ext_app->{api},

                    # not mandatory options
                    # id              => 'api',
                    namespace       => 'EXTDIRECT.' . ref( $self->{app} ) =~ s[::][]smgr,
                    timeout         => 0,                                                   # milliseconds, 0 - no timeout
                    version         => undef,
                    maxRetries      => 0,                                                   # number of times to re-attempt delivery on failure of a call
                    headers         => {},
                    enableBuffer    => 10,                                                  # \1, \0, milliseconds
                    enableUrlEncode => undef,
                },
                canonical => 1
            ),
        };

        my $js = <<"JS";
            Ext.Loader.setConfig({
                enabled: false,
                disableCaching: false
            });

            // app classes
            $ext_app->{content}

            Ext.ariaWarn = Ext.emptyFn;

            // ExtDirect api
            Ext.direct.Manager.addProvider($data->{api_map}->$*);

            Ext.application({
                name: 'APP',
                api: new PCORE({
                    url: '$data->{api_path}',
                    version: '$ext_app->{api_ver}',
                    listenEvents: null,
                    onConnect: function(api) {},
                    onDisconnect: function(api, status, reason) {},
                    onEvent: function(api, ev) { Ext.fireEvent('remoteEvent', ev) },
                    onListen: function(api, events) {},
                    onRpc: null
                }),
                mainView: '$ext_app->{viewport}'
            });
JS

        $self->{_cache}->{app}->{js} = $self->_prepare_js($js);

        $self->{_cache}->{app}->{etag} = 'W/' . P->digest->md5_hex( $self->{_cache}->{app}->{js}->$* );
    }

    if ( $req->{env}->{HTTP_IF_NONE_MATCH} && $req->{env}->{HTTP_IF_NONE_MATCH} eq $self->{_cache}->{app}->{etag} ) {
        $req->(304)->finish;    # not modified
    }
    else {
        $req->( 200, [ 'Content-Type' => 'application/javascript', 'Cache-Control' => 'must-revalidate', Etag => $self->{_cache}->{app}->{etag} ], $self->{_cache}->{app}->{js} )->finish;
    }

    return;
}

sub _prepare_js ( $self, $js ) {
    P->text->encode_utf8($js);

    if ( $self->{app}->{devel} ) {
        $js = JavaScript::Beautifier::js_beautify(
            $js,
            {   indent_size               => 4,
                indent_character          => q[ ],
                preserve_newlines         => 1,
                space_after_anon_function => 1,
            }
        );
    }
    else {
        my $js_packer = JavaScript::Packer->init;

        $js_packer->minify( \$js, { compress => 'obfuscate' } );    # clean
    }

    return \$js;
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
