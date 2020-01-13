package <: $module_name ~ "::Util" :>;

use Pcore -class, -res;
use Pcore::API::SMTP;
use <: $module_name ~ "::Const qw[]" :>;

has app      => ();
has tmpl     => ( init_arg => undef );    # InstanceOf ['Pcore::Util::Tmpl']
has dbh      => ( init_arg => undef );    # ConsumerOf ['Pcore::Handle::DBI']
has settings => ( init_arg => undef );    # HashRef

has _smtp => ( is => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['Pcore::API::SMTP'] ]

sub BUILD ( $self, $args ) {

    # init tmpl
    $self->{tmpl} = P->tmpl;

    # set settings listener
    P->bind_events(
        'app.api.settings.updated',
        sub ($ev) {
            $self->{settings} = $ev->{data};

            delete $self->{_smtp};

            return;
        }
    );

    return;
}

*TO_JSON = *TO_CBOR = sub ($self) {
    return { settings => $self->{settings} };
};

# DBH
sub build_dbh ( $self, $db ) {
    $self->{dbh} = P->handle($db) if !defined $self->{dbh};

    return $self->{dbh};
}

sub update_schema ( $self, $db ) {
    my $dbh = $self->build_dbh($db);

    $dbh->load_schema( $ENV->{share}->get_location('/<: $dist_name :>/db'), 'main' );

    return $dbh->upgrade_schema;
}

# SMTP
sub _build__smtp ($self) {
    my $cfg = $self->{settings};

    return if !$cfg->{smtp_host} || !$cfg->{smtp_port} || !$cfg->{smtp_username} || !$cfg->{smtp_password};

    return Pcore::API::SMTP->new( {
        host     => $cfg->{smtp_host},
        port     => $cfg->{smtp_port},
        username => $cfg->{smtp_username},
        password => $cfg->{smtp_password},
        tls      => $cfg->{smtp_tls},
    } );
}

sub sendmail ( $self, $to, $bcc, $subject, $body ) {
    my $smtp = $self->_smtp;

    my $res;

    if ( !$smtp ) {
        $res = res [ 500, 'SMTP is not configured' ];
    }
    else {
        $res = $smtp->sendmail(
            from     => $smtp->{username},
            reply_to => $smtp->{username},
            to       => $to,
            bcc      => $bcc,
            subject  => $subject,
            body     => $body
        );
    }

    P->sendlog( '<: $dist_name :>.FATAL', 'SMTP error', "$res" ) if !$res;

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 5                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 48, 87               | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 94                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 98 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::Util" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
