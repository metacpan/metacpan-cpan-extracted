package Pcore::Ext::Lib::modern::Form::ChangePassword;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        submit => func <<"JS",
            var me = this;
            var view = this.getView();
            var form = view.down('fieldpanel');

            if (form.validate()) {
                var password = form.getFields('password').getValue(),
                    password1_field = form.getFields('password1');

                if (password != password1_field.getValue()) {
                    password1_field.setError($l10n{'Passwords are not match'});

                    return;
                }

                Ext.fireEvent('mask');

                Ext.fireEvent('changePassword',
                    password,
                    view.getToken(),
                    function (success) {
                        Ext.fireEvent('unmask');

                        if (success) me.close();
                    }
                );
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
            token           => undef,    # change password token
            redirectOnClose => undef,    # hash, to redirect to on destroy
        },

        title => { text => l10n('PASSWORD CHANGING') },

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
                {   text    => l10n('Change Password'),
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

Pcore::Ext::Lib::modern::Form::ChangePassword

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
