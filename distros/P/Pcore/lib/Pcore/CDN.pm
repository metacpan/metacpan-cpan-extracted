package Pcore::CDN;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_arrayref];
use overload '&{}' => sub ( $self, @ ) {
    sub { $self->{bucket}->{ $self->{default} }->get_url(@_) }
  },
  fallback => 1;

has bucket => ( init_arg => undef );
has default => ();

around new => sub ( $orig, $self, $args ) {
    $self = $self->$orig;

    $self->{default} = delete $args->{default};

    while ( my ( $name, $cfg ) = each $args->%* ) {
        $self->{bucket}->{$name} = P->class->load( $cfg->{type}, ns => 'Pcore::CDN::Bucket' )->new($cfg);

        $self->{default} //= $name;
    }

    return $self;
};

sub bucket ( $self, $name ) { return $self->{bucket}->{$name} }

sub get_nginx_cfg($self) {
    my @buf;

    for my $buck ( $self->{bucket}->%* ) {
        next if !$buck->{is_local};

        push @buf, $buck->get_nginx_cfg;
    }

    return join $LF, @buf;
}

# RESOURCES
sub get_resources ( $self, @resources ) {
    my @res;

    for my $args (@resources) {
        if ( is_plain_arrayref $args) {
            my $method = '_get_res_' . shift $args->@*;

            push @res, $self->$method( $args->@* )->@*;
        }
        else {
            my $method = '_get_res_' . $args;

            push @res, $self->$method->@*;
        }
    }

    return \@res;
}

# TODO
sub _get_res_fa ( $self, $ver = undef ) {
    $ver ||= 'v5.3.1';

    return [qq[<link rel="stylesheet" href="@{[ $self->("/static/fa-$ver/css/all.min.css") ]}" integrity="" crossorigin="anonymous" />]];
}

# TODO
sub _get_res_ext ( $self, $ver, $type, $theme, $default_theme, $debug = undef ) {
    $ver ||= 'v6.6.0';

    $debug = $debug ? '-debug' : q[];

    my $resources;

    # framework
    if ( $type eq 'classic' ) {
        push $resources->@*, qq[<script src="@{[ $self->("/static/ext-$ver/ext-all$debug.js") ]}" integrity="" crossorigin="anonymous"></script>];
    }
    else {
        push $resources->@*, qq[<script src="@{[ $self->("/static/ext-$ver/ext-modern-all$debug.js") ]}" integrity="" crossorigin="anonymous"></script>];
    }

    # ux
    # push $resources->@*, qq[<script src="/static/ext-$ver/packages/ux/${framework}/ux${debug}.js" integrity="" crossorigin="anonymous"></script>];

    # theme

    # TODO default theme
    $theme = $default_theme if 0;

    push $resources->@*, qq[<link rel="stylesheet" href="@{[ $self->("/static/ext-$ver/$type/theme-$theme/resources/theme-$theme-all$debug.css") ]}" integrity="" crossorigin="anonymous" />];
    push $resources->@*, qq[<script src="@{[ $self->("/static/ext-$ver/$type/theme-$theme/theme-${theme}$debug.js") ]}" integrity="" crossorigin="anonymous"></script>];

    # fashion, only for modern material theme
    push $resources->@*, qq[<script src="@{[ $self->("/static/ext-$ver/css-vars.js") ]}" integrity="" crossorigin="anonymous"></script>] if $theme eq 'material';

    return $resources;
}

# TODO
sub _get_res_amcharts ( $self, $ver = undef ) {
    $ver ||= 'v3.21.13';

    return [ $self->("/static/amcharts-$ver/") ];
}

# TODO
sub _get_res_ammap ( $self, $ver = undef ) {
    $ver ||= 'v3.21.13';

    return [ $self->("/static/ammap-$ver/") ];
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 62                   | * Private subroutine/method '_get_res_fa' declared but not used                                                |
## |      | 69                   | * Private subroutine/method '_get_res_ext' declared but not used                                               |
## |      | 102                  | * Private subroutine/method '_get_res_amcharts' declared but not used                                          |
## |      | 109                  | * Private subroutine/method '_get_res_ammap' declared but not used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 69                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::CDN

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
