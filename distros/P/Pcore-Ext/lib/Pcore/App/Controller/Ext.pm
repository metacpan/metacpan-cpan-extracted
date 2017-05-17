package Pcore::App::Controller::Ext;

use Pcore -role, -result;
use Pcore::Ext;
use Pcore::Share::Ext_v6_2_0;
use Pcore::Share::WWW;
use Pcore::Share::WWW::CDN;
use Pcore::Util::Data qw[to_json];

with qw[Pcore::App::Controller];

requires qw[ext_app ext_app_title];

has ext_default_theme_classic => ( is => 'ro', isa => Str, default => 'triton' );
has ext_default_theme_modern  => ( is => 'ro', isa => Str, default => 'triton' );
has ext_default_locale        => ( is => 'ro', isa => Str, default => 'en' );

has cache => ( is => 'ro', isa => ScalarRef, init_arg => undef );

our $EXT_VER       = 'v6.2.0';
our $EXT_FRAMEWORK = 'classic';

sub BUILD ( $self, $args ) {
    Pcore::Ext->SCAN( $self->{app}, Pcore::Share::Ext_v6_2_0->get_cfg, $EXT_FRAMEWORK );

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
                $req->( 200, [ 'Content-Type' => 'application/javascript' ], $class->{js} )->finish;
            }

            return;
        }
        else {
            $self->$orig($req);
        }

        return;
    }

    # return cached content
    if ( $self->{cache} ) {
        $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{cache} )->finish;

        return;
    }

    my $resources = [];

    # FontAwesome
    push $resources->@*, Pcore::Share::WWW->fontawesome;

    my $ext_resources;

    # get theme from query
    if ( $req->{env}->{QUERY_STRING} =~ /\btheme=([[:lower:]-]+)/sm ) {
        my $theme = $1;

        $ext_resources = Pcore::Share::WWW::CDN->ext( $EXT_VER, $EXT_FRAMEWORK, $theme, $self->{app}->{devel} );
    }

    # fallback to the default theme
    if ( !$ext_resources ) {
        my $theme = $EXT_FRAMEWORK eq 'classic' ? $self->ext_default_theme_classic : $self->ext_default_theme_modern;

        $ext_resources = Pcore::Share::WWW::CDN->ext( $EXT_VER, $EXT_FRAMEWORK, $theme, $self->{app}->{devel} );
    }

    push $resources->@*, $ext_resources->@*;

    # Ext locale
    my $locale = $self->ext_default_locale;

    push $resources->@*, Pcore::Share::WWW::CDN->ext_locale( $EXT_VER, $EXT_FRAMEWORK, $locale, $self->{app}->{devel} );

    # Ext overrides
    my $overrides;

    my $class = eval {
        my $over = $EXT_VER =~ s/[.]/_/smgr;

        P->class->load("Pcore::Ext::Override::$over");
    };

    if ( !$@ ) {
        $overrides = $class->overrides;

        if ( !$self->{app}->{devel} ) {
            require JavaScript::Packer;

            my $js_packer = JavaScript::Packer->init;

            $js_packer->minify( \$overrides, { compress => 'obfuscate' } );    # clean
        }
    }

    my $loader_path = {
        $Pcore::Ext::NS => '.',
        Ext             => '/static/ext/src/',
        'Ext.ux'        => '/static/ext/ux/',
    };

    my $ext_app = $Pcore::Ext::CFG->{app}->{ $self->{ext_app} };

    my $api_map = {

        # type            => 'remoting',
        type    => 'websocket',
        url     => $self->{app}->{router}->get_host_api_path( $req->{host} ),
        actions => $ext_app->{api},

        # not mandatory options
        id              => 'api',
        namespace       => 'API.' . ref( $self->{app} ) =~ s[::][]smgr,
        timeout         => 0,                                             # milliseconds, 0 - no timeout
        version         => undef,
        maxRetries      => 0,                                             # number of times to re-attempt delivery on failure of a call
        headers         => {},
        enableBuffer    => 10,                                            # \1, \0, milliseconds
        enableUrlEncode => undef,
    };

    my $data = {
        INDEX => {                                                        #
            title => $self->ext_app_title
        },
        resources => $resources,
        ext       => {
            api_map        => to_json($api_map)->$*,
            loader_path    => to_json( $loader_path, readable => $self->{app}->{devel} )->$*,
            app_namespace  => $Pcore::Ext::NS,
            viewport_class => $ext_app->{viewport},
            overrides      => $overrides,
            static_classes => !$self->{app}->{devel} ? $ext_app->{js}->$* : undef,
        },
    };

    $self->{cache} = P->tmpl->render( 'ext/index.html', $data );

    $req->( 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], $self->{cache} )->finish;

    return;
};

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
