package OpenID::Lite::Extension::UI;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.01';
our @EXPORT_OK = qw(UI_NS UI_POPUP_NS UI_LANG_NS UI_NS_ALIAS);

use constant UI_NS       => q{http://specs.openid.net/extensions/ui/1.0};
use constant UI_POPUP_NS => q{http://specs.openid.net/extensions/ui/1.0/popup};
use constant UI_LANG_NS  => q{http://specs.openid.net/extensions/ui/1.0/lang-pref};
use constant UI_NS_ALIAS => q{ui};

1;

=head1 NAME

OpenID::Lite::Extension::UI - UI extension plugin for OpenID::Lite

=head1 SYNOPSIS

RP side

    sub login {
        ...
        my $checkid_req = $rp->begin( $identifier )
            or $your_app->error( $rp->errstr );

        $ui_req = OpenID::Lite::Extension::UI->new;
        $ui_req->mode('popup');
        $ui_req->lang('en-US');
        $checkid_req->add_extension( $ui_req );

        $your_app->redirect_to( $checkid_req->redirect_url( ... ) );
    }

OP side

    my $res = $op->handle_request( $your_app->request );

    if ( $res->is_for_setup ) {

        my %option;
        my $ui_req = OpenID::Lite::Extension::UI::Request->from_provider_response($res);
        if ($ui_req) {
            if ($ui_req->mode eq 'popup') {
                $option{template} = 'openid_popup.tt';
            }
        }
        $your_app->render( %option );
    }...

=head1 DESCRIPTION

This module is plugin for OpenID::Lite to acomplish UI extension flow on easy way.
http://wiki.openid.net/f/openid_ui_extension_draft01.html

=head1 SEE ALSO

L<OpenID::Lite::Extension::UI::Request>

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
