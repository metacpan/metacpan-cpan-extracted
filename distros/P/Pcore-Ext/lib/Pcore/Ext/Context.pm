package Pcore::Ext::Context;

use Pcore -class;
use Pcore::Ext::Context::Raw;
use Pcore::Ext::Context::Call;
use Pcore::Ext::Context::Func;

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );
has ctx => ( is => 'ro', isa => HashRef, required => 1 );

has framework => ( is => 'ro', isa => Enum [ 'classic', 'modern' ], default => 'classic' );

has js_gen_cache => ( is => 'ro', isa => HashRef, init_arg => undef );    # cache for JS functions strings

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
sub ext_class ( $self, $name ) {
    if ( my $class = $self->get_class($name) ) {

        # register requires
        $self->{ctx}->{requires}->{ $class->{class} } = undef;

        return $class->{class};
    }
    else {
        die qq[Can't resolve Ext name "$name" in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];
    }
}

sub ext_type ( $self, $name ) {
    if ( my $class = $self->get_class($name) ) {

        # register requires
        $self->{ctx}->{requires}->{ $class->{class} } = undef;

        return $class->{type};
    }
    else {
        die qq[Can't resolve Ext name "$name" in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];
    }
}

sub ext_api_method ( $self, $method_id ) {
    my $map = $self->{app}->{api}->{map};

    # add version to relative method id
    $method_id = "/$self->{ctx}->{api_ver}/$method_id" if substr( $method_id, 0, 1 ) ne q[/] && $self->{ctx}->{api_ver};

    my $method = $map->get_method($method_id) // die qq[API method "$method_id" is not exists in "$self->{ctx}->{namespace}::$self->{ctx}->{generator}"];

    my $ext_api_namespace = 'API.' . ref( $self->{app} ) =~ s[::][]smgr;

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

    return "$ext_api_namespace.$ext_api_action.$method->{method_name}";
}

sub get_class ( $self, $name ) {

    # search by full Ext class name
    if ( my $class_cfg = $Pcore::Ext::CFG->{class}->{$name} ) {
        return $class_cfg;
    }

    # name not contains '.' - this perl class name
    if ( index( $name, '.' ) == -1 ) {
        my $colon_idx = index $name, '::';

        if ( $colon_idx == -1 ) {

            # search by perl class name, related to the current namespace
            if ( my $class_name = $Pcore::Ext::CFG->{perl_class}->{"$self->{ctx}->{namespace}::$name"} ) {
                return $Pcore::Ext::CFG->{class}->{$class_name};
            }
        }
        elsif ( $colon_idx > 0 ) {

            # search by perl class name, related to the current namespace
            if ( my $class_name = $Pcore::Ext::CFG->{perl_class}->{"$self->{ctx}->{namespace}::$name"} ) {
                return $Pcore::Ext::CFG->{class}->{$class_name};
            }

            # search by full perl class name
            if ( my $class_name = $Pcore::Ext::CFG->{perl_class}->{$name} ) {
                return $Pcore::Ext::CFG->{class}->{$class_name};
            }
        }
        elsif ( $colon_idx == 0 ) {

            # search by perl class name, related to the app root Ext namespace
            if ( my $class_name = $Pcore::Ext::CFG->{perl_class}->{"$self->{ctx}->{root_namespace}$name"} ) {
                return $Pcore::Ext::CFG->{class}->{$class_name};
            }
        }
    }

    # name contains '.' - this is full Ext class name or full Ext class alias
    else {

        # search by full Ext class name in Ext. namespace
        if ( my $class = $Pcore::Ext::EXT->{ $self->{framework} }->{class}->{$name} ) {
            return $class;
        }

        # search by full alter Ext class name in Ext. namespace
        if ( my $class_name = $Pcore::Ext::EXT->{ $self->{framework} }->{alter_class}->{$name} ) {
            return $Pcore::Ext::EXT->{ $self->{framework} }->{class}->{$class_name};
        }

        # search by full Ext alias in Ext. namespace
        if ( my $class_name = $Pcore::Ext::EXT->{ $self->{framework} }->{alias_class}->{$name} ) {
            return $Pcore::Ext::EXT->{ $self->{framework} }->{class}->{$class_name};
        }
    }

    return;
}

sub to_js ( $self ) {
    my $cfg = do {
        my $method = "EXT_$self->{ctx}->{generator}";

        no strict qw[refs];

        *{"$self->{ctx}->{namespace}::$method"}->($self);
    };

    # resolve and add "extend" property
    if ( $self->{ctx}->{extend} ) {
        $cfg->{extend} = $self->ext_class( $self->{ctx}->{extend} );

        # add extend to requires
        $self->{ctx}->{requires}->{ $cfg->{extend} } = undef;
    }

    # create "requires" property
    push $cfg->{requires}->@*, sort keys $self->{ctx}->{requires}->%*;

    # set alias
    $cfg->{alias} = $self->{ctx}->{alias} if $self->{ctx}->{alias} && !exists $cfg->{alias};

    my $js = $self->js_call( 'Ext.define', [ $self->{ctx}->{class}, $cfg ] )->to_js;

    my $js_gen_cache = $self->{js_gen_cache};

    $js->$* =~ s/"__JS(\d+)__"/$js_gen_cache->{$1}->$*/smge;

    undef $self->{js_gen_cache};

    return $js;
}

1;
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
