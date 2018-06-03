package Pcore::App::Controller::Index;

use Pcore -role;

with qw[Pcore::App::Controller];

eval { require Pcore::Resources };

sub run ( $self, $req ) {
    if ( $req->{path_tail}->is_file ) {
        $self->return_static($req);

        return;
    }
    else {
        return $self->SUPER::run($req);
    }
}

sub get_nginx_cfg ($self) {
    my @buf;

    my $locations = $ENV->{share}->get_storage('www');

    # add_header    Cache-Control "public, private, must-revalidate, proxy-revalidate";

    for ( my $i = 0; $i <= $locations->$#*; $i++ ) {
        my $location = $i == 0 ? '/static/' : "\@$locations->[$i]";

        my $next = $i < $locations->$#* ? "\@$locations->[$i + 1]" : '=404';

        push @buf, <<"TXT";
    location $location {
        add_header    Cache-Control "public, max-age=30672000";
        root          $locations->[$i];
        try_files     \$uri $next;
    }
TXT
    }

    return <<"TXT";
    location =/ {
        error_page 418 = \@backend;
        return 418;
    }

    location / {
        error_page 418 = \@backend;
        return 418;
    }

@{[join $LF, @buf]}
TXT
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 27                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::Index

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
