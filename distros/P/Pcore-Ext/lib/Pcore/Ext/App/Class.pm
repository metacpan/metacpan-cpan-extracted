package Pcore::Ext::App::Class;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_arrayref weaken];
use Pcore::Ext::App::Class::TiedResolver;
use Pcore::Ext::App::Class::Ctx::Raw;
use Pcore::Ext::App::Class::Ctx::Func;
use Pcore::Ext::App::Class::Ctx::Class;
use Pcore::Ext::App::Class::Ctx::Type;
use Pcore::Ext::App::Class::Ctx::L10N;

use overload '""' => sub ( $self, @ ) { return $self->{path} };

has app     => ( required => 1 );    # InstanceOf['Pcore::Ext']
has path    => ( required => 1 );    # Str, /Class/Path/name
has package => ( required => 1 );    # Str, perl package, Class::Path
has method  => ( required => 1 );    # Str, genertaor method, EXT_method

has name     => ();                  # Str, ExtJS class name
has extend   => ();
has override => ();
has type     => ();                  # ExtJS alias type
has alias    => ();                  # Str, ExtJS class alias

has requires             => ( init_arg => undef );    # HashRef
has api                  => ( init_arg => undef );    # HashRef, used api methods
has l10n                 => ( init_arg => undef );    # HashRef, used i10n msgid's
has build                => ( init_arg => undef );
has build_on_create_func => ( init_arg => undef );
has build_cache          => ( init_arg => undef );

sub BUILD ( $self, $args ) {
    weaken $self->{app};

    return;
}

sub resolve_class_name ( $self, $class_name ) {

    # class name is ExtJS class name
    if ( index( $class_name, '.' ) != -1 && index( $class_name, '/' ) == -1 ) {
        return $class_name;
    }

    # class name is absolute
    elsif ( substr( $class_name, 0, 1 ) eq '/' ) {

        # get prefix
        my ($prefix) = $class_name =~ m[\A/([^/]+)/]sm;

        # substitute prefix
        $class_name =~ s[\A/([^/]+)/][/$self->{app}->{prefixes}->{$prefix}/]sm if exists $self->{app}->{prefixes}->{$prefix};
    }

    # path is relative
    else {
        $class_name = ( $self->{path} =~ s[/[^/]+\z][]smr ) . "/$class_name";
    }

    # resolve relative path tokens and return path
    return P->path($class_name)->{path};
}

sub build ( $self ) {
    no warnings qw[redefine];

    # "raw" resolver
    local *{"$self->{package}\::raw"} = sub {
        return Pcore::Ext::App::Class::Ctx::Raw->new(
            class => $self,
            js    => shift,
        ), @_;
    };

    # "func" resolver
    local *{"$self->{package}\::func"} = sub {
        return Pcore::Ext::App::Class::Ctx::Func->new(
            class     => $self,
            func_args => is_plain_arrayref $_[0] ? shift : undef,
            func_body => shift,
        ), @_;
    };

    # "class" resolver
    tie my $class->%*, 'Pcore::Ext::App::Class::TiedResolver', sub ($class_name) {
        $class_name = $self->resolve_class_name($class_name);

        $self->{requires}->{$class_name} = 1;

        return Pcore::Ext::App::Class::Ctx::Class->new( class => $self, name => $class_name );
    };

    local *{"$self->{package}\::class"} = $class;

    # "type" resolver
    tie my $type->%*, 'Pcore::Ext::App::Class::TiedResolver', sub ($class_name) {
        $class_name = $self->resolve_class_name($class_name);

        $self->{requires}->{$class_name} = 1;

        return Pcore::Ext::App::Class::Ctx::Type->new( class => $self, name => $class_name );
    };

    local *{"$self->{package}\::type"} = $type;

    # "api" resolver
    tie my $api->%*, 'Pcore::Ext::App::Class::TiedResolver', sub ($method_id) {

        # add version to relative method id
        $method_id = "/v1/$method_id" if substr( $method_id, 0, 1 ) ne '/';

        # check, that API method exists
        die qq[API method "$method_id" is not exists in "$self->{path}"] if !$self->{app}->{ext}->{app}->{api}->get_method($method_id);

        my ( $action, $name ) = $method_id =~ m[/(.+)/([^/]+)\z]sm;

        $action =~ s[/][.]smg;

        $self->{api}->{$method_id} = {
            action => $action,
            name   => $name,
        };

        return "EXTDIRECT.$self->{app}->{api_namespace}.$action.$name";
    };

    local *{"$self->{package}\::api"} = $api;

    # "cdn" resolver
    local ${"$self->{package}\::cdn"} = $self->{app}->{cdn};

    # "l10n" resolver
    local *{"$self->{package}\::l10n"} = sub : prototype($;$$) ( $msgid, $msgid_plural = undef, $num = undef ) {

        # register msgid
        $self->{l10n}->{$msgid} = 1;

        return Pcore::Ext::App::Class::Ctx::L10N->new( class => $self, buf => [ [ $msgid, $msgid_plural, $num // 1 ] ] );
    };

    tie my $l10n_hash->%*, 'Pcore::Ext::App::Class::TiedResolver', sub ($msgid) {

        # register msgid
        $self->{l10n}->{$msgid} = 1;

        return Pcore::Ext::App::Class::Ctx::L10N->new( class => $self, buf => [ [$msgid] ] );
    };

    local *{"$self->{package}\::l10n"} = $l10n_hash;

    # build class
    ( $self->{build}, $self->{build_on_create_func} ) = $self->{package}->can( $self->{method} )->();

    return;
}

sub generate ($self) {
    my $class_name = $self->{override} ? 'null' : qq["$self->{name}"];

    my $build_cache = $self->{build_cache};

    my $js = "Ext.define($class_name," . P->data->to_json( $self->{build}, canonical => 1 );

    # add "on create" func
    $js .= ',' . $build_cache->{ $self->{build_on_create_func} }->generate($EMPTY) if $self->{build_on_create_func};

    $js .= ');';

    while ( $js =~ /__JS_\d+__/sm ) {
        $js =~ s[(["']?)(__JS_\d+__)(\1)][$build_cache->{$2}->generate($1 // $EMPTY )]smge;
    }

    $self->{build} = $js;

    # clean generator cache
    delete $self->{build_on_create_func};
    delete $self->{build_cache};

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 85, 96, 107, 141     | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 133                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
