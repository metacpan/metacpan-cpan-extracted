package Pcore::Ext::Lib::Form::Auth;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        init => func ['view'],
        <<~'JS',
            this.callParent(arguments);

            if (view.getShowSignup() && view.getCanSignup()) {
                this.showSignup();
            }
            else {
                this.showSignin();
            }
JS

        showSignin => func <<~"JS",
            var me = this,
                view = this.getView();

            view.setItems({
                xtype: "$type{signin_form}",
            });

            view.setTitle($l10n{'SIGN IN'});

            if (!view.getCanSignup()) {
                this.lookup('signup-link').hide();
            }

            if (!view.getCanRecoverPassword()) {
                this.lookup('recover-password-link').hide();
            }
JS

        showSignup => func <<"JS",
            var me = this,
                view = this.getView();

            view.setItems({
                xtype: "$type{signup_form}",
            });

            view.setTitle($l10n{'REGISTER ACCOUNT'});
JS

        showRecoverPassword => func <<"JS",
            var me = this,
                view = this.getView();

            view.setItems({
                xtype: "$type{recover_password_form}",
            });

            view.setTitle($l10n{'RECOVER PASSWORD'});

            if (!view.getCanSignup()) {
                this.lookup('signup-link').hide();
            }
JS

        doSignin => func <<'JS',
            var view = this.getView(),
                form = view.down('fieldpanel');

            if (form.validate()) {
                this.fireSigninEvent(form.getFields('username').getValue(), form.getFields('password').getValue());
            }
JS

        fireSigninEvent => func [ 'username', 'password' ], <<"JS",
            var me = this,
                view = this.getView(),
                form = view.down('fieldpanel');

            Ext.fireEvent('mask', view);

            Ext.fireEvent('signin',
                username,
                password,
                this.lookup('remember_me').isChecked(),
                function (success) {
                    view.unmask();

                    if (success) view.destroy();
                }
            );
JS

        doSignup => func <<"JS",
                var me = this,
                    view = this.getView(),
                    form = view.down('fieldpanel');

                if (form.validate()) {
                    var password = form.getFields('password').getValue(),
                        password1 = form.getFields('password1').getValue();

                    if (password != password1) {
                        form.getFields('password1').setError($l10n{'Passwords are not match'});

                        return;
                    }

                    Ext.fireEvent('mask', view);

                    $api{'Admin/Users/create'}(form.getValues(), function(res) {
                        view.unmask();

                        if (res.isSuccess()) {
                            Ext.toast($l10n{'Account created'}, 5000);

                            Ext.fireEvent('signin',
                                form.getFields('username').getValue(),
                                password,
                                1,
                                function (success) {if (success) view.destroy();}
                            );
                        }
                        else {
                            Ext.fireEvent('requestError', res);
                        }
                    });
                }
JS

        doRecoverPassword => func <<"JS",
                var me = this;
                var view = this.getView(),
                    form = view.down('fieldpanel'),
                    username_field = form.getFields('username');

                form.clearErrors();

                if (username_field.validate()) {
                    Ext.fireEvent('mask', view);

                    Ext.fireEvent('recoverPassword',
                        username_field.getValue(),
                        function (success) {
                            view.unmask();

                            form.reset(true);
                        }
                    );
                }
JS
    };
}

sub EXT_dialog : Extend('Ext.Dialog') : Type('widget') {
    return {
        controller => $type{'controller'},

        title => { text => l10n('SIGN IN') },

        # defaultFocus => 'textfield[name=username]',
        draggable  => \0,
        scrollable => \1,
        width      => 320,
        maxHeight  => '100%',

        config => {
            canSignup          => 1,
            canRecoverPassword => 1,
            showSignup         => 0,    # show signup form on start
        },
    };
}

# FORMS
sub EXT_signin_form : Extend('Ext.Panel') {
    return {
        keyMap => { ENTER => 'doSignin' },

        items => [
            {   xtype => 'fieldpanel',

                items => [
                    {   xtype      => 'textfield',
                        name       => 'username',
                        label      => l10n('User Name or Email'),
                        allowBlank => \0,
                        required   => \1,
                    },
                    {   xtype      => 'passwordfield',
                        name       => 'password',
                        label      => l10n('Password'),
                        allowBlank => \0,
                        required   => \1,
                    },
                    {   xtype     => 'checkboxfield',
                        reference => 'remember_me',
                        boxLabel  => l10n('Remember Me'),
                        checked   => 1,
                        hidden    => \1,
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },
            {   layout => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    {   reference => 'recover-password-link',
                        xtype     => $type{'/pcore/Link/panel'},
                        html      => l10n('Forgot password?'),
                        handler   => 'showRecoverPassword',
                    },
                    {   xtype => 'spacer',
                        flex  => 1,
                    },
                    {   xtype   => 'button',
                        text    => l10n('Sign in'),
                        ui      => 'confirm',
                        handler => 'doSignin',
                        width   => '50%',
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },

            {   layout => {
                    type  => 'vbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [

                    # TELEGRAM
                    {   xtype => $type{'/pcore/Telegram/button'},
                        bind  => { telegramBotId => '{settings.telegram_bot_name}' },
                    },
                ],
            },

            {   reference => 'signup-link',
                layout    => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    { html => l10n('Do not have account?') . '&nbsp;', },
                    {   xtype   => $type{'/pcore/Link/panel'},
                        html    => l10n('Create yours now.'),
                        handler => 'showSignup'
                    },
                ],
            },
        ],
    };
}

sub EXT_signup_form : Extend('Ext.Panel') {
    return {
        keyMap => { ENTER => 'doSignup' },

        items => [
            {   xtype => 'fieldpanel',

                items => [
                    {   xtype      => 'textfield',
                        name       => 'username',
                        label      => l10n('User Name'),
                        allowBlank => \0,
                        required   => \1,
                    },
                    {   xtype      => 'emailfield',
                        name       => 'email',
                        label      => l10n('Email'),
                        allowBlank => \0,
                        required   => \1,
                        validators => 'email',
                    },
                    {   xtype      => 'passwordfield',
                        name       => 'password',
                        label      => l10n('Password'),
                        allowBlank => \0,
                        required   => \1,
                    },
                    {   xtype      => 'passwordfield',
                        name       => 'password1',
                        label      => l10n('Confirm Password'),
                        allowBlank => \0,
                        required   => \1,
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },
            {   layout => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    {   xtype => 'spacer',
                        flex  => 1,
                    },
                    {   xtype   => 'button',
                        text    => l10n('Register'),
                        ui      => 'confirm',
                        handler => 'doSignup',
                        width   => '50%',
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },
            {   layout => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    { html => l10n('Already have account?') . '&nbsp;', },
                    {   xtype   => $type{'/pcore/Link/panel'},
                        html    => l10n('Tap here to sign in.'),
                        handler => 'showSignin'
                    },
                ],
            },
        ],
    };
}

sub EXT_recover_password_form : Extend('Ext.Panel') {
    return {
        keyMap => { ENTER => 'doRecoverPassword' },

        items => [
            {   xtype => 'fieldpanel',

                items => [
                    {   xtype      => 'textfield',
                        name       => 'username',
                        label      => l10n('User Name or Email'),
                        allowBlank => \0,
                        required   => \1,
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },
            {   layout => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    {   xtype => 'spacer',
                        flex  => 1,
                    },
                    {   xtype   => 'button',
                        text    => l10n('Recover Password'),
                        ui      => 'confirm',
                        handler => 'doRecoverPassword',
                    },
                ],
            },
            {   xtype  => 'spacer',
                height => 20,
            },
            {   layout => {
                    type  => 'hbox',
                    pack  => 'center',
                    align => 'center',
                },

                items => [
                    { html => l10n('You can') . '&nbsp;', },
                    {   xtype   => $type{'/pcore/Link/panel'},
                        html    => l10n('Signin'),
                        handler => 'showSignin'
                    },
                    {   xtype     => 'container',
                        reference => 'signup-link',
                        layout    => {
                            type  => 'hbox',
                            pack  => 'center',
                            align => 'center',
                        },
                        items => [
                            { html => '&nbsp;' . l10n('or') . '&nbsp;', },
                            {   xtype   => $type{'/pcore/Link/panel'},
                                html    => l10n('Register'),
                                handler => 'showSignup'
                            },
                        ],
                    },
                ],
            },
        ],
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Form::Auth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
