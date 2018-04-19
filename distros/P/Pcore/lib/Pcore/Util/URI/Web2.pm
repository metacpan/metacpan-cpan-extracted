package Pcore::Util::URI::Web2;

use Pcore -role;
use Pcore::Util::Text qw[decode_utf8];

has _web2_data  => ( is => 'lazy', isa => Maybe [ArrayRef], init_arg => undef );
has web2_domain => ( is => 'lazy', isa => Maybe [Str],      init_arg => undef );
has web2_id     => ( is => 'lazy', isa => Maybe [Str],      init_arg => undef );
has is_web2 => ( is => 'lazy', isa => Bool, init_arg => undef );
has web2_canon => ( is => 'lazy', isa => Maybe [Str], init_arg => undef );    # subdomain.domain.tld, domain.tld/path/, without scheme

our $WEB2_CFG = P->cfg->load( $ENV->share->get('/data/web2.ini') );

our $WEB2_HOST_RE;
our $WEB2_RE;

sub _web2_compile {
    my @re;

    for my $host ( sort keys $WEB2_CFG->%* ) {
        $WEB2_RE->{$host} = qr[$WEB2_CFG->{$host}->{re}]smi if $WEB2_CFG->{$host}->{re};

        if ( $host =~ /[.]/sm ) {
            push @re, quotemeta $host;
        }
        else {
            push @re, $host . '[.][[:alpha:].]{2,6}';
        }
    }

    my $re = join q[|], @re;

    $WEB2_HOST_RE = qr[($re)\z]smi;

    return;
}

sub web2_cfg ($self) {
    return $WEB2_CFG;
}

sub web2_load_default_cfg ( $self, $cfg, $merge = 1 ) {
    $WEB2_CFG = P->cfg->load( $ENV->share->get('/data/web2.ini') );

    undef $WEB2_HOST_RE;
    undef $WEB2_RE;

    return;
}

sub web2_load_cfg ( $self, $cfg, $merge = 1 ) {
    $WEB2_CFG = {} if !$merge;

    for my $host ( keys $cfg->%* ) {
        $WEB2_CFG->{$host}->%* = $cfg->{$host}->%*;
    }

    undef $WEB2_HOST_RE;
    undef $WEB2_RE;

    return;
}

sub _build__web2_data ($self) {
    _web2_compile() if !$WEB2_HOST_RE;

    my $res;

    if ( $self->host->canon =~ $WEB2_HOST_RE ) {
        my $web2_domain = $1;

        my $web2_id = exists $WEB2_CFG->{$web2_domain} ? $web2_domain : $web2_domain =~ s/[.].+\z//smr;

        if ( $WEB2_CFG->{$web2_id}->{path} ) {

            # path-based web2 url must not contain subdomain and must have nont empty path
            if ( $self->host->canon eq $web2_domain && $self->path =~ m[\A(/[^/]+)/?]sm ) {
                $res = [ $web2_id, $web2_domain, $web2_domain . $1 . q[/] ];
            }
        }
        elsif ( $self->host->canon =~ /([^.]+[.]\Q$web2_domain\E)\z/sm ) {
            $res = [ $web2_id, $web2_domain, $1 ];
        }
    }

    return $res;
}

sub _build_web2_domain ($self) {
    if ( my $web2_data = $self->_web2_data ) {
        return $web2_data->[1];
    }
    else {
        return;
    }
}

sub _build_web2_id ($self) {
    if ( my $web2_data = $self->_web2_data ) {
        return $web2_data->[0];
    }
    else {
        return;
    }
}

sub _build_is_web2 ($self) {
    if ( my $web2_data = $self->_web2_data ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _build_web2_canon ($self) {
    if ( my $web2_data = $self->_web2_data ) {
        return $web2_data->[2];
    }
    else {
        return;
    }
}

# NOTE http request must be performed with recursion enabled
sub web2_check_available ( $self, $http_res ) {
    return undef if !$self->is_web2;    ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]

    return undef if !$http_res->{body}; ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]

    my $web2_id = $self->web2_id;

    my $cfg = $WEB2_CFG->{$web2_id};

    if ( $cfg->{status} && $http_res->{status} == $cfg->{status} ) { return 1 }

    if ( $WEB2_RE->{$web2_id} ) {
        eval { decode_utf8 $http_res->{body}->$* };

        return 1 if $http_res->{body}->$* =~ $WEB2_RE->{$web2_id};
    }

    return 0;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 138                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::URI::Web2

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
