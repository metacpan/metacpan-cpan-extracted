package Pcore::App::Controller::Ext;

use Pcore -const, -role, -result;
use Pcore::Ext;
use Pcore::Share::Ext_v6_2_0;
use Pcore::Share::WWW;
use Pcore::Util::Data qw[to_json];
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
        if ( $req->{path_tail} && $req->{path_tail} =~ /\A(.+)[.]js\z/sm ) {
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

            return;
        }
        else {
            $self->$orig($req);
        }

        return;
    }

    # get locale from query string
    my ($locale) = $req->{env}->{QUERY_STRING} =~ /\blocale=([[:alpha:]-]+)/sm;

    # validate locale
    my $locales = $ext_framework->get_locale;
    $locale = defined $locale && exists $locales->{$locale} ? $locale : exists $locales->{ $self->ext_default_locale } ? $self->ext_default_locale : $DEFAULT_LOCALE;

    # return cached content
    if ( $self->{cache}->{app}->{$locale} ) {
        $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{cache}->{app}->{$locale} )->finish;

        return;
    }

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

    my $ext_app_js = $self->_prepare_ext_app_js(
        {   overrides => $ext_framework->get_overrides,
            locale    => {
                class_name      => $ext_app->{l10n_class_name},
                messages        => to_json($locale_messages),
                plural_form_exp => $Pcore::Core::L10N::LOCALE_PLURAL_FORM->{$locale}->{exp} // 'null',
            },
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
            static_classes => $ext_app->{js},
        }
    );

    # generate HTML tmpl
    $self->{cache}->{app}->{$locale} = P->tmpl->render(
        'ext/index.html',
        {   INDEX => {    #
                title => $self->ext_app_title
            },
            resources  => $resources,
            ext_app_js => $ext_app_js->$*,
        }
    );

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{cache}->{app}->{$locale} )->finish;

    return;
};

sub _prepare_ext_app_js ( $self, $data ) {
    my $static_classes = $self->{app}->{devel} ? \q[] : $data->{static_classes};

    my $ext_app_js = <<"JS";
        $data->{overrides}->$*;

        Ext.define('$data->{locale}->{class_name}', {
            singleton: true,

            messages: $data->{locale}->{messages}->$*,

            l10n: function(msgid, domain) {
                if (msgid in this.messages[domain] && typeof( this.messages[domain][msgid][0] ) != 'undefined' ) {
                    return this.messages[domain][msgid][0];
                }
                else {
                    return msgid;
                }
            },

            l10np: function(msgid, msgid_plural, n, domain) {
                var idx = $data->{locale}->{plural_form_exp};

                if (msgid in this.messages[domain] && typeof( this.messages[domain][msgid][idx] ) != 'undefined' ) {
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
        });

        Ext.Loader.setConfig({
            enabled: true,
            disableCaching: false,
            paths: $data->{loader_paths}->$*
        });

        Ext.onReady(function() {
            Ext.ariaWarn = Ext.emptyFn;

            $static_classes->$*;

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

    return $self->_prepare_js($ext_app_js);
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
