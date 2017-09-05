package Pcore::App::Controller::Ext;

use Pcore -const, -role, -result;
use Pcore::Ext;
use Pcore::Share::Ext_v6_2_0;
use Pcore::Share::WWW;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Pcore::Util::Text qw[decode_utf8];
use JavaScript::Packer qw[];
use JavaScript::Beautifier qw[];

with qw[Pcore::App::Controller];

requires qw[ext_app ext_app_title];

has ext_default_theme_classic => ( is => 'ro', isa => Str, default => 'triton' );
has ext_default_theme_modern  => ( is => 'ro', isa => Str, default => 'triton' );
has ext_default_locale        => ( is => 'ro', isa => Str, default => 'en' );

has cache => ( is => 'ro', isa => ScalarRef, init_arg => undef );

our $EXT_VER       = 'v6.2.0';
our $EXT_FRAMEWORK = 'classic';
our $ext_framework = 'Pcore::Share::Ext_v6_2_0';

const our $DEFAULT_LOCALE => 'en';

sub BUILD ( $self, $args ) {
    Pcore::Ext->SCAN( $self->{app}, $ext_framework->get_cfg, $EXT_FRAMEWORK );

    die qq[Ext app "$self->{ext_app}" not found] if !$Pcore::Ext::CFG->{app}->{ $self->ext_app };

    return;
}

# this method can be overrided in the child class
sub run ( $self, $req ) {
    if ( $req->{path_tail} && $req->{path_tail}->is_file ) {

        # try to return static content
        $self->return_static($req);
    }
    else {
        $req->(404)->finish;
    }

    return;
}

around run => sub ( $orig, $self, $req ) {

    # if path tail is not empty - fallback to the original method
    if ( $req->{path_tail} ) {

        # .js file request
        if ( $req->{path_tail} =~ /\A(.+)[.]js\z/sm ) {
            if ( $req->{path_tail} eq 'overrides.js' ) {
                $self->_return_overrides($req);
            }
            elsif ( $req->{path_tail} eq 'app.js' ) {
                $self->_return_app($req);
            }
            else {
                my $class = $Pcore::Ext::CFG->{class}->{"$Pcore::Ext::NS.$1"};

                if ( !$class ) {
                    $req->(404)->finish;
                }
                else {
                    if ( !exists $self->{cache}->{class}->{ $class->{class} } ) {
                        $self->{cache}->{class}->{ $class->{class} } = $self->_prepare_js( $class->{js}->$* );
                    }

                    $req->( 200, [ 'Content-Type' => 'application/javascript' ], $self->{cache}->{class}->{ $class->{class} } )->finish;
                }
            }
        }
        elsif ( $req->{path_tail} eq 'app.js.map' ) {
            $self->_return_src_map($req);
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

    # get locale
    my $locale = $self->_get_locale($req);

    if ( !$self->{cache}->{app}->{$locale}->{html} ) {
        my $resources = [];

        # FontAwesome
        push $resources->@*, Pcore::Share::WWW->fontawesome;

        my $ext_resources;

        # get theme from query
        if ( $req->{env}->{QUERY_STRING} =~ /\btheme=([[:lower:]-]+)/sm ) {
            my $theme = $1;

            $ext_resources = $ext_framework->ext( $EXT_FRAMEWORK, $theme, $self->{app}->{devel} );
        }

        # fallback to the default theme
        if ( !$ext_resources ) {
            my $theme = $EXT_FRAMEWORK eq 'classic' ? $self->ext_default_theme_classic : $self->ext_default_theme_modern;

            $ext_resources = $ext_framework->ext( $EXT_FRAMEWORK, $theme, $self->{app}->{devel} );
        }

        push $resources->@*, $ext_resources->@*;

        # Ext locale
        push $resources->@*, $ext_framework->ext_locale( $EXT_FRAMEWORK, $locale, $self->{app}->{devel} );

        # TODO calc checksum 'sha384-' . P->digest->sha384_b64( $res->body->$* );
        push $resources->@*, qq[<script src="$self->{path}overrides.js" integrity="" crossorigin="anonymous"></script>];
        push $resources->@*, qq[<script src="$self->{path}app.js?locale=$locale" integrity="" crossorigin="anonymous"></script>];

        # generate HTML tmpl
        $self->{cache}->{app}->{$locale}->{html} = P->tmpl->render(
            'ext/index.html',
            {   INDEX => {    #
                    title => $self->ext_app_title
                },
                resources => $resources,
            }
        );
    }

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{cache}->{app}->{$locale}->{html} )->finish;

    return;
}

sub _return_overrides ( $self, $req ) {
    if ( !$self->{cache}->{overrides} ) {
        $self->{cache}->{overrides} = $self->_prepare_js( $ext_framework->get_overrides->$* );
    }

    $req->( 200, [ 'Content-Type' => 'application/javascript', ], $self->{cache}->{overrides} )->finish;

    return;
}

sub _return_app ( $self, $req ) {

    # get locale
    my $locale = $self->_get_locale($req);

    if ( !$self->{cache}->{app}->{$locale}->{app} ) {
        my $ext_app = $Pcore::Ext::CFG->{app}->{ $self->{ext_app} };

        my $data = {
            locale  => $self->_get_app_locale($locale),
            api_map => to_json(
                {   type    => 'websocket',                                                 # remoting
                    url     => $self->{app}->{router}->get_host_api_path( $req->{host} ),
                    actions => $ext_app->{api},

                    # not mandatory options
                    id              => 'api',
                    namespace       => 'API.' . ref( $self->{app} ) =~ s[::][]smgr,
                    timeout         => 0,                                                   # milliseconds, 0 - no timeout
                    version         => undef,
                    maxRetries      => 0,                                                   # number of times to re-attempt delivery on failure of a call
                    headers         => {},
                    enableBuffer    => 10,                                                  # \1, \0, milliseconds
                    enableUrlEncode => undef,
                }
            ),
            loader_paths => to_json(
                {   $Pcore::Ext::NS => '.',
                    Ext             => '/static/ext/src/',
                    'Ext.ux'        => '/static/ext/ux/',
                }
            ),
            app_namespace  => $Pcore::Ext::NS,
            viewport_class => $ext_app->{viewport},
        };

        my $header = <<"JS";
            $data->{locale};

            Ext.Loader.setConfig({
                enabled: true,
                disableCaching: false,
                paths: $data->{loader_paths}->$*
            });
JS

        my $footer = <<"JS";
            Ext.onReady(function() {
                Ext.ariaWarn = Ext.emptyFn;

                Ext.direct.Manager.addProvider($data->{api_map}->$*);

                Ext.application({
                    extend: 'Ext.app.Application',
                    requires: ['$data->{viewport_class}'],
                    name: '$data->{app_namespace}',
                    appFolder: '.',
                    glyphFontFamily: 'FontAwesome',
                    mainView: '$data->{viewport_class}'
                });
            });
JS

        if ( $self->{app}->{devel} ) {
            ( $self->{cache}->{app}->{$locale}->{app}, $self->{cache}->{app}->{$locale}->{src_map} ) = $self->_add_src_map( \$header, map( { [ $Pcore::Ext::CFG->{class}->{$_}->{js}, s/\A$Pcore::Ext::NS[.]//smr . '.js' ] } $ext_app->{classes}->@* ), \$footer );

            $self->{cache}->{app}->{$locale}->{src_map} = to_json $self->{cache}->{app}->{$locale}->{src_map};
        }
        else {
            my $classes = join ';', map { $Pcore::Ext::CFG->{class}->{$_}->{js}->$* } $ext_app->{classes}->@*;

            $self->{cache}->{app}->{$locale}->{app} = $self->_prepare_js("${header}${classes};${footer}");
        }
    }

    $req->(
        200,
        [   'Content-Type' => 'application/javascript',
            ( $self->{app}->{devel} ? ( 'X-SourceMap' => "$self->{path}app.js.map?locale=$locale" ) : () ),
        ],
        $self->{cache}->{app}->{$locale}->{app}
    )->finish;

    return;
}

sub _return_src_map ( $self, $req ) {

    # get locale
    my $locale = $self->_get_locale($req);

    my $src_map = $self->{cache}->{app}->{$locale}->{src_map};

    if ($src_map) {
        $req->( 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ], $src_map )->finish;
    }
    else {
        $req->(404)->finish;
    }

    return;
}

sub _get_locale ( $self, $req ) {

    # get locale from query string
    my ($locale) = $req->{env}->{QUERY_STRING} =~ /\blocale=([[:alpha:]-]+)/sm;

    # validate locale
    my $locales = $ext_framework->get_locale;

    $locale = defined $locale && exists $locales->{$locale} ? $locale : exists $locales->{ $self->ext_default_locale } ? $self->ext_default_locale : $DEFAULT_LOCALE;

    return $locale;
}

sub _get_app_locale ( $self, $locale ) {
    my $ext_app = $Pcore::Ext::CFG->{app}->{ $self->{ext_app} };

    # load locale domains
    my $locale_domains = [qw[Lcom]];

    for my $domain ( keys $ext_app->{l10n_domain}->%* ) {
        Pcore::Core::L10N::load_domain_locale( $domain, $locale );
    }

    # prepare locale messages
    my $locale_messages;

    for my $domain ( keys $Pcore::Core::L10N::MESSAGES->%* ) {
        $locale_messages->{$domain} = $Pcore::Core::L10N::MESSAGES->{$domain}->{$locale};
    }

    my $data->{locale} = {
        class_name => $ext_app->{l10n_class_name},
        messages   => \decode_utf8( to_json( $locale_messages, readable => 1 )->$* ),
        plural_form_exp => $Pcore::Core::L10N::LOCALE_PLURAL_FORM->{$locale}->{exp} // 'null',
    };

    return <<"JS";
        Ext.define('$data->{locale}->{class_name}', {
            singleton: true,

            messages: $data->{locale}->{messages}->$*,

            l10n: function(msgid, domain) {
                if (msgid in this.messages[domain] && typeof this.messages[domain][msgid][0] !== 'undefined' ) {
                    return this.messages[domain][msgid][0];
                }
                else {
                    return msgid;
                }
            },

            l10np: function(msgid, msgid_plural, n, domain) {
                var idx = $data->{locale}->{plural_form_exp};

                if (msgid in this.messages[domain] && typeof this.messages[domain][msgid][idx] !== 'undefined' ) {
                    return this.messages[domain][msgid][idx];
                }
                else {
                    if ( n == 1 ) {
                        return msgid;
                    }
                    else {
                        return msgid_plural;
                    }
                }
            }
        })
JS
}

sub _add_src_map ( $self, @js ) {

    # https://www.html5rocks.com/en/tutorials/developertools/sourcemaps/#toc-base64vlq
    # https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/view#
    # http://www.murzwin.com/base64vlq.html

    state $to_vlq = sub( @num ) {
        state $map = do {
            my $i = 0;

            my %m = map { $i++ => $_ } split //sm, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';

            \%m;
        };

        my $result = q[];

        for my $num (@num) {
            if ( $num < 0 ) {
                $num = ( -$num << 1 ) | 1;
            }
            else {
                $num <<= 1;
            }

            do {
                my $clamped = $num & 31;

                $num >>= 5;

                if ( $num > 0 ) {
                    $clamped |= 32;
                }

                $result .= $map->{$clamped};
            } while ( $num > 0 );
        }

        return $result;
    };

    my $src_map = {
        version    => 3,
        file       => 'app.js',
        sourceRoot => $self->{path},
        sources    => [],
        names      => [],
        mappings   => q[],
    };

    my $buf    = q[];
    my $ln_idx = 0;
    my $src_idx;

    for my $js (@js) {
        my $src_name;

        if ( is_plain_arrayref $js) {
            ( $js, $src_name ) = $js->@*;
        }

        $js = $self->_prepare_js( $js->$* . q[;] );

        if ( defined $src_name ) {
            push $src_map->{sources}->@*, $src_name;
        }

        my @lines = split /$LF/sm, $js->$*;

        for my $ln ( 0 .. $#lines ) {
            $buf .= $lines[$ln] . $LF;

            if ( defined $src_name ) {

                if ( !$ln ) {

                    # generated column, original file this appeared in, original line number, original column
                    $src_map->{mappings} .= $to_vlq->( 0, $src_idx // 0, 0 - $ln_idx, 0 ) . q[;];
                }
                else {
                    $src_map->{mappings} .= $to_vlq->( 0, 0, 1, 0 ) . q[;];
                }
            }
            else {

                # generated column
                $src_map->{mappings} .= q[;];
            }
        }

        if ( defined $src_name ) {
            $src_idx //= 1;
            $ln_idx = @lines - 1;
        }
    }

    return \$buf, $src_map;
}

sub _prepare_js ( $self, $js ) {
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
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 363                  | ControlStructures::ProhibitPostfixControls - Postfix control "while" used                                      |
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
