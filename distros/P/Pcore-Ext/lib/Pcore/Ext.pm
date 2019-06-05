package Pcore::Ext v0.30.2;

use Pcore -dist, -class;
use Pcore::Ext::App;
use Pcore::Util::Scalar qw[is_ref];

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
        $cfg->{prefixes}->{app}   //= $cfg->{namespace} =~ s[::][/]smgr;

        $app = $self->{ext_app}->{$package} = Pcore::Ext::App->new($cfg);

        $app->build;
    }

    return $self->{ext_app}->{$package};
}

sub rebuild_all ($self) {
    $Pcore::Ext::App::MODULES = {};

    while ( my ( $package, $app ) = each $self->{ext_app}->%* ) {
        print "rebuild: $package ... ";

        eval { $app->build };

        if ($@) {
            say $@;
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

    undef $Pcore::Ext::App::FRAMEWORK if !$self->{app}->{devel};

    undef $Pcore::Ext::App::MODULES;

    return;
}

sub _init_reload ($self) {
    my $ext_ns = ref( $self->{app} ) . '::Ext' =~ s[::][/]smgr;

    for my $inc_path ( grep { !is_ref $_ } @INC ) {

        # Ext reloader
        P->path("$inc_path/$ext_ns")->poll_tree(
            abs       => 0,
            is_dir    => 0,
            max_depth => 0,
            sub ( $root, $changes ) {
                $self->rebuild_all;

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
## |    3 | 48                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
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
