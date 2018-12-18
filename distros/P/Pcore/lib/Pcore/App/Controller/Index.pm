package Pcore::App::Controller::Index;

use Pcore -role;

with qw[Pcore::App::Controller];

sub get_nginx_cfg ($self) {
    return <<"TXT";
    location =/ {
        error_page 418 = \@backend;
        return 418;
    }

    location / {
        rewrite ^/favicon.ico\$ /cdn/favicon.ico last;
        rewrite ^/robots.txt\$ /cdn/robots.txt last;

        error_page 418 = \@backend;
        return 418;
    }
TXT
}

1;
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
