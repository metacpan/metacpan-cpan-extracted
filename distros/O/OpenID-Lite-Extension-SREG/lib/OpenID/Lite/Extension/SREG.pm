package OpenID::Lite::Extension::SREG;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.01';

our @EXPORT_OK = qw(SREG_NS_1_0 SREG_NS_1_1 SREG_NS_ALIAS);

use constant SREG_NS_1_0   => q{http://openid.net/sreg/1.0};
use constant SREG_NS_1_1   => q{http://openid.net/extensions/sreg/1.1};
use constant SREG_NS_ALIAS => q{sreg};

1;

=head1 NAME

OpenID::Lite::Extension::SREG - SREG extension plugin for OpenID::Lite

=head1 SYNOPSIS

RP side

    sub login {
        ...
        my $checkid_req = $rp->begin( $identifier )
            or $your_app->error( $rp->errstr );

        $sreg_req = OpenID::Lite::Extension::SREG::Request->new;
        $sreg_req->request_field('nickname');
        $sreg_req->request_field('fullname');
        $sreg_req->policy_url( $policy_url );
        $checkid_req->add_extension( $sreg_req );

        $your_app->redirect_to( $checkid_req->redirect_url( ... ) );
    }

    sub complete {
        ...
        my $result = $rp->complete( $your_app->request )

        if ( $result->is_success ) {

            ...

            my $sreg_res = OpenID::Lite::Extension::SREG::Response->from_success_response( $result );
            my $data = $sreg_res->data;
            say $data->{nickname};
            say $data->{fullname};

            ...

        } elsif ( ... ) {
            ...
        }
    }


OP side

    my $res = $op->handle_request( $your_app->request );

    if ( $res->is_positive_assertion ) {

        my $sreg_req = OpenID::Lite::Extension::SREG::Request->from_provider_response($res);
        my $policy_url = $sreg_req->policy_url;
        if ( $sreg_res ) {
            my $sreg_data = {
                nickname => $user->nickname,
                fullname => $user->fullname,
                email    => $user->email,
            };
            my $sreg_res = OpenID::Lite::Extension::SREG::Response->extract_response($sreg_req, $sreg_data);
            $res->add_extension( $sreg_res );
        }

        $your_app->redirect_to( $res->make_signed_url() );

    } elsif ( $res->is_for_setup ) {

        my $message = '';
        my $sreg_req = OpenID::Lite::Extension::SREG::Request->from_provider_response($res);
        if ($sreg_req) {
            my $fields = $sreg_req->all_requested_fields();
            $message .= sprintf(q{RP requested %s},  join(', ', @$fields));
            $your_app->render( message => $message );
        }
    }...

=head1 DESCRIPTION

This module is plugin for OpenID::Lite to acomplish SREG extension flow on easy way.

http://openid.net/specs/openid-simple-registration-extension-1_0.html

http://openid.net/specs/openid-simple-registration-extension-1_1-01.html


=head1 SEE ALSO

L<OpenID::Lite::Extension::SREG::Request>
L<OpenID::Lite::Extension::SREG::Response>

L<OpenID::Lite::RelyingParty>
L<OpenID::Lite::Provider>

=head1 AUTHOR

Lyo Kato, E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
