package Lcom::Index::ConfirmEmail;

use Pcore -class, -l10n;

with qw[Pcore::App::Controller Pcore::App::Controller::Ext];

has path => '/confirm-email/', init_arg => undef;

sub run ( $self, $req ) {
    my $token;

    my $accept = sub {
        $req->(
            200, [ 'Content-Type' => 'text/html' ], <<"HTML"
                <h1><center>$l10n{'Email address confirmed successfully'}.</center></h1>
HTML
        )->finish;

        return;
    };

    my $reject = sub {
        $req->(
            400, [ 'Content-Type' => 'text/html' ], <<"HTML"
                <h1><center>$l10n{'Token is invalid or email address is already confirmed'}.</center></h1>
HTML
        )->finish;

        return;
    };

    if ( $req->{env}->{QUERY_STRING} && $req->{env}->{QUERY_STRING} =~ /id=([[:alnum:]]+)/sm ) {
        $token = $1;

        my $auth = $req->authenticate;

        return $reject->() if !$auth;

        $auth->api_call(
            '/v1/Auth/confirm_email_by_token',
            $token,
            sub ($res) {
                if ($res) {
                    $accept->();
                }
                else {
                    $reject->();
                }

                return;
            }
        );

        return;
    }
    else {
        $reject->();
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Lcom::Index::ConfirmEmail

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
