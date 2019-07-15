package Pcore::Ext::Lib::Form::ChangePassword;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        submit => func <<"JS",
            var me = this,
                view = this.getView(),
                form = view.down('fieldpanel');

            if (form.validate()) {
                var password = form.getFields('password').getValue(),
                    password1_field = form.getFields('password1');

                if (password != password1_field.getValue()) {
                    password1_field.setError($l10n{'Passwords are not match'});

                    return;
                }

                var token = view.getToken(),
                    callback = function (res) {
                        view.unmask();

                        if (res.isSuccess()) {
                            Ext.toast($l10n{'Password changed'}, 3000);

                            me.close();
                        }
                        else {
                            Ext.fireEvent('requestError', res);
                        }
                    };

                Ext.fireEvent('mask', view);

                if (token) {
                    let api = view.getApiChangePasswordToken();

                    Ext.direct.Manager.parseMethod(api)(token, password, callback);
                }
                else {
                    let api = view.getApiChangePasswordProfile();

                    Ext.direct.Manager.parseMethod(api)(password, callback);
                }
            }
JS

        close => func <<"JS",
            var view = this.getView();

            view.destroy();
JS

        onDestroy => func <<"JS",
            var view = this.getView(),
                redirectOnClose = view.getRedirectOnClose();

            if (redirectOnClose != null) this.redirectTo(redirectOnClose, {replace: true});
JS
    };
}

sub EXT_dialog : Extend('Ext.Dialog') : Type('widget') {
    return {
        controller => $type{controller},

        config => {
            apiChangePasswordProfile => $api{'Profile/change_password'},
            apiChangePasswordToken   => $api{'Auth/change_password'},
            token                    => undef,                             # change password token
            redirectOnClose          => undef,                             # hash, to redirect to on destroy
        },

        title => { text => l10n('CHANGE PASSWORD') },

        # defaultFocus => 'passwordfield[name=password]',
        closable   => \1,
        draggable  => \0,
        scrollable => \1,
        width      => 320,
        maxHeight  => '100%',

        keyMap => { ENTER => 'submit', },

        listeners => { destroy => 'onDestroy' },

        items => [ {
            xtype => 'fieldpanel',

            items => [
                {   xtype    => 'passwordfield',
                    name     => 'password',
                    label    => l10n('New Password'),
                    required => \1,
                },
                {   xtype    => 'passwordfield',
                    name     => 'password1',
                    label    => l10n('Confirm New Password'),
                    required => \1,
                },
            ],

            buttons => [
                {   text    => l10n('Cancel'),
                    ui      => 'decline',
                    handler => 'close',
                },
                {   text    => l10n('Change'),
                    ui      => 'confirm',
                    handler => 'submit',
                },
            ]
        } ]
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Form::ChangePassword

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
