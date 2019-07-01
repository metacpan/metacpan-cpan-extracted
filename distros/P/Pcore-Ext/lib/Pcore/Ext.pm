package Pcore::Ext v0.34.0;

use Pcore -dist, -class;
use Pcore::Ext::App;
use Pcore::Util::Scalar qw[is_ref];
use Pcore::Util::Path::Poll qw[:POLL];

has app => ( required => 1 );    # InstanceOf['Pcore::App']

has ext_app => ();

sub BUILD ( $self, $args ) {
    $self->_init_reload if $self->{app}->{devel};

    return;
}

sub create_app ( $self, $package, $cfg ) {
    my $app;

    if ( !exists $self->{ext_app}->{$package} ) {
        $cfg->{devel}     = $self->{app}->{devel};
        $cfg->{ext}       = $self;
        $cfg->{id}        = P->digest->md5_hex($package);
        $cfg->{namespace} = $package;

        $cfg->{api_namespace} //= $cfg->{namespace} =~ s/:://smgr;

        $cfg->{cdn} //= $self->{app}->{cdn};

        $cfg->{prefixes}->{pcore} //= 'Pcore/Ext/Lib';
        $cfg->{prefixes}->{dist}  //= ref( $self->{app} ) . '::Ext' =~ s[::][/]smgr;
        $cfg->{prefixes}->{lib}   //= ref( $self->{app} ) . '::Ext' =~ s[::][/]smgr . '/Lib';
        $cfg->{prefixes}->{app}   //= $cfg->{namespace} =~ s[::][/]smgr;

        $app = $self->{ext_app}->{$package} = Pcore::Ext::App->new($cfg);

        $app->build;
    }

    return $self->{ext_app}->{$package};
}

sub rebuild_all ( $self, $modifications ) {
    for my $module ( $modifications->@* ) {
        delete $Pcore::Ext::App::MODULES->{$module};
    }

    while ( my ( $package, $app ) = each $self->{ext_app}->%* ) {
        print "rebuild: $package ... ";

        eval { $app->build };

        if ($@) {
            $@->sendlog;
        }
        else {
            say 'done';
        }
    }

    return;
}

sub clear_cache ($self) {
    for my $module ( keys $Pcore::Ext::App::MODULES->%* ) {
        P->class->unload($module);
    }

    undef $Pcore::Ext::App::MODULES;

    undef $Pcore::Ext::App::FRAMEWORK;

    return;
}

sub _init_reload ($self) {
    my $pcore_lib_ns       = 'Pcore/Ext/Lib';
    my $pcore_overrides_ns = 'Pcore/Ext/Overrides';
    my $ext_ns             = ref( $self->{app} ) . '::Ext' =~ s[::][/]smgr;

    for my $inc_path ( grep { !is_ref $_ } @INC ) {

        # pcore ext lib
        P->path("$inc_path/$pcore_lib_ns")->poll_tree(
            abs       => 0,
            is_dir    => 0,
            max_depth => 0,
            sub ( $root, $changes ) {
                my $modifications;

                for my $change ( $changes->@* ) {
                    if ( $change->[1] == $POLL_MODIFIED || $change->[1] == $POLL_REMOVED ) {
                        push $modifications->@*, "$pcore_lib_ns/$change->[0]";
                    }
                }

                $self->rebuild_all($modifications) if $modifications;

                return;
            }
        );

        # pcore ext overrides
        P->path("$inc_path/$pcore_overrides_ns")->poll_tree(
            abs       => 0,
            is_dir    => 0,
            max_depth => 0,
            sub ( $root, $changes ) {
                my $modifications;

                for my $change ( $changes->@* ) {
                    if ( $change->[1] == $POLL_MODIFIED || $change->[1] == $POLL_REMOVED ) {
                        push $modifications->@*, "$pcore_overrides_ns/$change->[0]";
                    }
                }

                $self->rebuild_all($modifications) if $modifications;

                return;
            }
        );

        # ext app reloader
        P->path("$inc_path/$ext_ns")->poll_tree(
            abs       => 0,
            is_dir    => 0,
            max_depth => 0,
            sub ( $root, $changes ) {
                my $modifications;

                for my $change ( $changes->@* ) {
                    if ( $change->[1] == $POLL_MODIFIED || $change->[1] == $POLL_REMOVED ) {
                        push $modifications->@*, "$ext_ns/$change->[0]";
                    }
                }

                $self->rebuild_all($modifications) if $modifications;

                return;
            }
        );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 52                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
