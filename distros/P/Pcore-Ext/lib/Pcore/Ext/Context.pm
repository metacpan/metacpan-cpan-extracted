package Pcore::Ext::Context;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken is_plain_arrayref];
use Pcore::Ext::Context::Raw;
use Pcore::Ext::Context::Func;
use Pcore::Ext::Context::L10N;

has app  => ();
has tree => ();
has ctx  => ();

has _js_gen_cache => ();    # ( is => 'ro', isa => HashRef, init_arg => undef );    # cache for JS functions strings

# Ext resolvers
sub _ext_api_method ( $self, $method_id ) {
    my $map = $self->{app}->{api}->{map};

    # add version to relative method id
    $method_id = "/$self->{ctx}->{api_ver}/$method_id" if substr( $method_id, 0, 1 ) ne q[/] && $self->{ctx}->{api_ver};

    my $method = $map->get_method($method_id) // die qq[API method "$method_id" is not exists in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];

    my $ext_api_action = $method->{class_path} =~ s[/][.]smgr =~ s[\A[.]][]smr;

    if ( !exists $self->{ctx}->{api}->{ $method->{id} } ) {
        $self->{ctx}->{api}->{ $method->{id} } = {
            action   => $ext_api_action,
            name     => $method->{method_name},
            len      => 1,
            params   => [],
            strict   => \0,
            metadata => {
                len    => 1,
                params => [],
                strict => \0,
            },
            formHandler => \0,
        };
    }

    my $ext_api_namespace = 'EXTDIRECT.' . ref( $self->{app} ) =~ s[::][]smgr;

    return "$ext_api_namespace.$ext_api_action.$method->{method_name}";
}

sub _ext_class ( $self, $name ) {
    if ( my $class = $self->_resolve_class_path($name) ) {

        # register requires
        $self->{ctx}->{requires}->{ $class->{class_path} } = undef;

        return $class->{ext_class_name};
    }
    else {
        die qq[Can't resolve Ext name "$name" in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];
    }
}

sub _ext_type ( $self, $name ) {
    if ( my $class = $self->_resolve_class_path($name) ) {

        # register requires
        $self->{ctx}->{requires}->{ $class->{class_path} } = undef;

        return $class->{alias};
    }
    else {
        die qq[Can't resolve Ext name "$name" in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];
    }
}

sub _resolve_class_path ( $self, $path ) {
    my $resolved;

    # path is related to the current context app_path
    if ( substr( $path, 0, 2 ) eq '//' ) {
        substr $path, 0, 2, q[];

        $resolved = P->path( $path, base => $self->{ctx}->{app_path} )->to_string;
    }

    # path is absolute
    elsif ( substr( $path, 0, 1 ) eq '/' ) {
        $resolved = P->path( $path, base => '/' )->to_string;
    }

    # path is related to the current context context_path
    else {
        $resolved = P->path( $path, base => $self->{ctx}->{context_path} )->to_string;
    }

    die qq[Can't resolve path "$path" in class "$self->{ctx}->{namespace}::EXT_$self->{ctx}->{generator}"] if !exists $self->{tree}->{$resolved};

    return $self->{tree}->{$resolved};
}

sub to_js ( $self ) {
    my ( $data, $on_create_func ) = do {
        my $method = "EXT_$self->{ctx}->{generator}";

        my $l10n = sub : prototype($;$$) ( $msgid, $msgid_plural = undef, $num = undef ) {

            # register msgid in ctx
            $self->{ctx}->{l10n}->{$msgid} = 1;

            return bless {
                ctx => $self,
                buf => [ [ $msgid, $msgid_plural, $num // 1 ] ],
              },
              'Pcore::Ext::Context::L10N';
        };

        no warnings qw[redefine];

        local *{"$self->{ctx}->{namespace}\::raw"} = sub : prototype($) ($js) {
            return bless {
                ctx => $self,
                js  => $js,
              },
              'Pcore::Ext::Context::Raw';
        };

        local *{"$self->{ctx}->{namespace}\::func"} = sub {
            return bless(
                {   ctx       => $self,
                    func_args => is_plain_arrayref $_[0] ? shift : undef,
                    func_body => shift,
                },
                'Pcore::Ext::Context::Func'
            ), @_;
        };

        # CDN link
        local ${"$self->{ctx}->{namespace}::cdn"} = $self->{app}->{cdn};

        tie my $api->%*,   'Pcore::Ext::Context::_TiedAttr', $self, '_ext_api_method';
        tie my $class->%*, 'Pcore::Ext::Context::_TiedAttr', $self, '_ext_class';
        tie my $type->%*,  'Pcore::Ext::Context::_TiedAttr', $self, '_ext_type';

        local *{"$self->{ctx}->{namespace}::api"}   = \$api;
        local *{"$self->{ctx}->{namespace}::class"} = \$class;
        local *{"$self->{ctx}->{namespace}::type"}  = \$type;

        local *{"$self->{ctx}->{namespace}::l10n"} = $l10n;

        tie my $l10n_hash->%*, 'Pcore::Ext::Context::_l10n', $self;

        local ${"$self->{ctx}->{namespace}::l10n"} = $l10n_hash;

        # run generator
        *{"$self->{ctx}->{namespace}::$method"}->();
    };

    # remove "requires" property, because we build full app
    delete $data->{requires};

    # set "override" property
    if ( $self->{ctx}->{override} ) {
        $data->{override} = $self->{ctx}->{override};
    }

    else {

        # set "extend" property
        if ( $self->{ctx}->{extend} ) {
            $data->{extend} = $self->{ctx}->{extend};
        }

        # set alias, if is not already defined
        if ( !$data->{alias} && $self->{ctx}->{alias} ) {
            $data->{alias} = "$self->{ctx}->{alias_namespace}.$self->{ctx}->{alias}";
        }
    }

    my $class_name = $self->{ctx}->{override} ? q[null] : qq["$self->{ctx}->{ext_class_name}"];

    my $js = qq[Ext.define( $class_name, ] . P->data->to_json( $data, canonical => 1 )->$* . qq[@{[ defined $on_create_func ? ',"' . $on_create_func->TO_JSON . '"' : q[] ]})];

    my $js_gen_cache = $self->{_js_gen_cache};

    $js =~ s/"__JS(\d+)__"/$js_gen_cache->{$1}->$*/smge;

    $self->{ctx}->{content} = \$js;

    return;
}

package Pcore::Ext::Context::_TiedAttr {

    sub TIEHASH ( $self, @args ) {
        return bless [ {}, @args ], $self;
    }

    sub FETCH {
        my $method = $_[0]->[2];

        return $_[0]->[1]->$method( $_[1] );
    }
}

package Pcore::Ext::Context::_l10n {

    sub TIEHASH ( $self, $ctx ) {
        return bless [$ctx], $self;
    }

    sub FETCH {

        # register msgid in ctx
        $_[0]->[0]->{ctx}->{l10n}->{ $_[1] } = 1;

        return bless {
            ctx => $_[0]->[0],
            buf => [ [ $_[1] ] ],
          },
          'Pcore::Ext::Context::L10N';
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 16                   | * Private subroutine/method '_ext_api_method' declared but not used                                            |
## |      | 47                   | * Private subroutine/method '_ext_class' declared but not used                                                 |
## |      | 60                   | * Private subroutine/method '_ext_type' declared but not used                                                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 137, 138, 139, 147   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 102, 116             | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
