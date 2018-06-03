package Pcore::Ext::Context;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Ext::Context::Raw;
use Pcore::Ext::Context::Call;
use Pcore::Ext::Context::Func;
use Pcore::Ext::Context::L10N;

has app  => ();
has tree => ();
has ctx  => ();

has api           => ();    # ( is => 'ro', isa => HashRef, init_arg => undef );    # tied to $self->_ext_api_method
has class         => ();    # ( is => 'ro', isa => HashRef, init_arg => undef );    # tied to $self->_ext_class
has type          => ();    # ( is => 'ro', isa => HashRef, init_arg => undef );    # tied to $self->_ext_type
has _js_gen_cache => ();    # ( is => 'ro', isa => HashRef, init_arg => undef );    # cache for JS functions strings

sub BUILD ( $self, $args ) {
    weaken $self;

    tie $self->{api}->%*,   'Pcore::Ext::Context::_TiedAttr', $self, '_ext_api_method';
    tie $self->{class}->%*, 'Pcore::Ext::Context::_TiedAttr', $self, '_ext_class';
    tie $self->{type}->%*,  'Pcore::Ext::Context::_TiedAttr', $self, '_ext_type';

    return;
}

# JS GENERATORS
sub js_raw ( $self, $js ) {
    return bless {
        ext => $self,
        js  => $js,
      },
      'Pcore::Ext::Context::Raw';
}

sub js_call ( $self, $func_name, $func_args = undef ) {
    return bless {
        ext       => $self,
        func_name => $func_name,
        func_args => $func_args,
      },
      'Pcore::Ext::Context::Call';
}

sub js_func ( $self, @ ) {
    my ( $func_name, $func_args, $func_body );

    if ( @_ == 2 ) {
        $func_body = $_[1];
    }
    elsif ( @_ == 3 ) {
        $func_body = $_[2];

        if ( ref $_[1] eq 'ARRAY' ) {
            $func_args = $_[1];
        }
        else {
            $func_name = $_[1];
        }
    }
    elsif ( @_ == 4 ) {
        ( $func_name, $func_args, $func_body ) = ( $_[1], $_[2], $_[3] );
    }
    else {
        die q[Invalid params];
    }

    return bless {
        ext       => $self,
        func_name => $func_name,
        func_args => $func_args,
        func_body => $func_body,
      },
      'Pcore::Ext::Context::Func';
}

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
    my $data = do {
        my $method = "EXT_$self->{ctx}->{generator}";

        my $l10n = sub ( $msgid, $msgid_plural = undef, $num = undef ) : prototype($;$$) {
            my $domain = caller;

            $self->{ctx}->{l10n_domain}->{$domain} = undef;

            return bless {
                ext          => $self,
                domain       => $domain,
                msgid        => $msgid,
                msgid_plural => $msgid_plural,
                num          => $num // 1,
              },
              'Pcore::Ext::Context::L10N';
        };

        no strict qw[refs];    ## no critic qw[TestingAndDebugging::ProhibitProlongedStrictureOverride]
        no warnings qw[redefine];

        local *{"$self->{ctx}->{namespace}::l10n"} = $l10n;

        tie my $l10n_hash->%*, 'Pcore::Ext::Context::_l10n', $self;

        local ${"$self->{ctx}->{namespace}::l10n"} = $l10n_hash;

        *{"$self->{ctx}->{namespace}::$method"}->($self);
    };

    # set "extend" property
    $data->{extend} = $self->{ctx}->{extend} if $self->{ctx}->{extend};

    # remove "requires" property, because we build full app
    delete $data->{requires};

    # set alias
    $data->{alias} = "$self->{ctx}->{alias_namespace}.$self->{ctx}->{alias}" if $self->{ctx}->{alias};

    my $js = $self->js_call( 'Ext.define', [ $self->{ctx}->{ext_class_name}, $data ] )->to_js;

    my $js_gen_cache = $self->{_js_gen_cache};

    $js->$* =~ s/"__JS(\d+)__"/$js_gen_cache->{$1}->$*/smge;

    $self->{ctx}->{content} = $js;

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
        my $domain = caller;

        $_[0]->[0]->{ctx}->{l10n_domain}->{$domain} = undef;

        return bless {
            ext    => $_[0]->[0],
            domain => $domain,
            msgid  => $_[1],
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
## |      | 80                   | * Private subroutine/method '_ext_api_method' declared but not used                                            |
## |      | 111                  | * Private subroutine/method '_ext_class' declared but not used                                                 |
## |      | 124                  | * Private subroutine/method '_ext_type' declared but not used                                                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 22, 23, 24, 186      | Miscellanea::ProhibitTies - Tied variable used                                                                 |
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
