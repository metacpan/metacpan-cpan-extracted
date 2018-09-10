package Pcore::Ext::Lib::Core::Viewport;

use Pcore -l10n;
use Pcore::Resources::FA qw[:ALL];

# VIEWPORT CONTROLLER
sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        roles => [],

        api => {
            signin          => undef,    # $api->{'Auth/signin'},
            signout         => undef,    # $api->{'Auth/signout'},
            setLocale       => undef,    # $api->{'Auth/set_locale'},
            changePassword  => undef,    # $api->{'Auth/change_password'},
            recoverPassword => undef,    # $api->{'Auth/recover_password'},
        },

        # MATERIAL THEME
        theme => {
            accent   => undef,
            base     => undef,
            darkMode => \0
        },

        defaultMask => {
            transparent => \0,
            html        => qq[<img src="@{[ $cdn->('/static/loader4.gif') ]}" width="100"/>],
        },

        listen => {
            global => {
                mask            => 'mask',
                unmask          => 'unmask',
                unmatchedRoute  => 'onUnmatchedRoute',
                remoteEvent     => 'onRemoteEvent',
                requestError    => 'onRequestError',
                signin          => 'onSignin',
                signout         => 'onSignout',
                setLocale       => 'onSetLocale',
                setTheme        => 'setTheme',
                changePassword  => 'onChangePassword',
                recoverPassword => 'onRecoverPassword',
            },
        },

        routes => {    #
            'change-password/:{token}(/.*)' => 'routeChangePassword',
        },

        init => func ['view'], <<"JS",
            var me = this;

            // parse API methods
            for (var method in me.api) {
                me.api[method] = Ext.direct.Manager.parseMethod(me.api[method]);
            }

            // set material theme
            me.setTheme(me.theme, true);

            Ext.util.History.hashbang = true;

            // set token and disconnect
            APP.getApplication().api.auth(this.getToken());

            Ext.route.Router.suspend();

            me.initApp();

            me.callParent(arguments);
JS

        initApp => func [], <<"JS",
            var me = this;

            me.mask();

            me.doSignin(null, null, function(res) {
                if (res.isSuccess()) {

                    // store session
                    var session = me.checkSession(res.data.session);
                    me.getViewModel().set('session', session);

                    // store app settings
                    me.getViewModel().set('settings', res.data.settings);

                    me.setLocale(session.locale, function () {
                        Ext.route.Router.resume();
                    });
                }
                else {
                    me.unmask();

                    Ext.create({
                        xtype: 'dialog',
                        modal: false,
                        html: $l10n->{'Error connecting to the server'} + '<br/>' + $l10n->{'Try again.'},
                        buttons: [{
                            text: 'retry',
                            handler: function () {
                                this.up('dialog').close();

                                me.initApp();
                            }
                        }]
                    }).show();
                }
            });
JS

        checkSession => func ['session'], <<'JS',

            // compare roles
            if (session.is_authenticated && !session.is_root) {
                if (this.roles && this.roles.length) {
                    session.is_authenticated = false;

                    for (var role of this.roles) {
                        if (session.permissions[role]) {
                            session.is_authenticated = true;

                            break;
                        }
                    }
                }
            }

            if (!session.locale) session.locale = localStorage.locale || session.default_locale;

            session.theme = this.theme;

            return session;
JS

        # MATERIAL THEME
        setTheme => func [ 'newTheme', 'isDefaultTheme' ], <<"JS",
            if (Ext.theme.Material) {
                Ext.manifest.material = Ext.manifest.material || {};
                Ext.manifest.material.toolbar = Ext.manifest.material.toolbar || {};
                Ext.manifest.material.toolbar.dynamic = true;

                var userTheme = localStorage.theme ? JSON.parse(localStorage.theme) : {},
                    currentTheme = this.theme;

                if (isDefaultTheme) {
                    this.theme = Ext.apply(newTheme, userTheme, currentTheme);
                }
                else {
                    localStorage.theme = JSON.stringify(newTheme);

                    this.theme = Ext.apply(currentTheme, newTheme, userTheme);
                }

                Ext.theme.Material.setColors(this.theme);
            }
JS

        # MASK
        mask => func [], <<'JS',
            this.getView().setMasked(this.defaultMask);
JS

        unmask => func [], <<'JS',
            this.getView().unmask();
JS

        # EVENTS
        onUnmatchedRoute => func ['hash'], <<"JS",
            this.redirectTo('', {replace: true});
JS

        onRequestError => func ['res'], <<"JS",
                Ext.toast("Error: " + res.reason, 3000);
JS

        onRemoteEvent => func ['ev'], <<"JS",
JS

        # TOKEN
        setToken => func [ 'token', 'persistent' ], <<'JS',
            this.removeToken();

            if (persistent) {
                localStorage.token = token;
            }
            else {
                sessionStorage.token = token;
            }
JS

        getToken => func [], <<'JS',
            return sessionStorage.token || localStorage.token;
JS

        removeToken => func [], <<'JS',
            localStorage.removeItem('token');
            sessionStorage.removeItem('token');
JS

        # LOCALE
        onSetLocale => func ['locale'], <<"JS",

            // already using required locale
            if (Ext.L10N.getCurrentLocale() == locale) return;

            // store user locale in profile, if user is authenticated
            if (this.getViewModel().get('session').is_authenticated) this.doSetLocale(locale);

            var me = this;

            me.setLocale(locale, function () {
                me.redirectTo(Ext.util.History.getToken(), {force: true});
            });
JS

        setLocale => func [ 'locale', 'cb' ], <<'JS',
            if (locale == Ext.L10N.getCurrentLocale()) {
                cb();
            }
            else {
                var me = this;

                // store locale in local storage
                localStorage.locale = locale;

                this.loadLocale(locale, function () {
                    Ext.L10N.setLocale(locale);

                    // redraw interface
                    me.clearInterface();

                    cb();
                });
            }
JS

        loadLocale => func [ 'locale', 'cb' ], <<'JS',
            if (Ext.L10N.hasLocale(locale)) {
                cb();

                return;
            }

            Ext.Loader.loadScript({
                url: 'locale.js?locale=' + locale,
                onLoad: function () {
                    cb();
                }
            });
JS

        clearInterface => func [], <<'JS',
            var view = this.getView();

            view.getItems().each(function(item) {
                view.remove(item);
            });
JS

        # USER ACTIONS
        onSignin => func [ 'username', 'password', 'persistent', 'cb' ], <<"JS",
            var me = this;

            me.mask();

            me.doSignin(username, password, function (res) {
                me.unmask();

                if (res.isSuccess()) {

                    // store app settings
                    me.getViewModel().set('settings', res.data.settings);

                    // store session
                    var session = me.checkSession(res.data.session);
                    me.getViewModel().set('session', session);

                    // not authenticated
                    if (!session.is_authenticated) {
                        Ext.toast($l10n->{'You have no permissions to access this area'}, 3000);

                        return;
                    };

                    // store API token
                    me.setToken(session.token, persistent);

                    // set token and disconnect
                    APP.getApplication().api.auth(session.token);

                    me.setLocale(session.locale, function () {
                        me.clearInterface();

                        me.redirectTo(Ext.util.History.getToken(), {force: true});
                    });

                    if (cb) cb(true);
                }
                else {
                    Ext.fireEvent('requestError', res);

                    if (cb) cb(false);
                }
            });
JS

        onSignout => func [], <<"JS",
            this.doSignout();

            // drop API token
            this.removeToken();

            // set token and disconnect
            APP.getApplication().api.auth(null);

            // clear session data
            this.getViewModel().set('session', {});

            this.clearInterface();

            // redirect
            this.redirectTo(Ext.util.History.getToken(), {force: true});
JS

        onChangePassword => func [ 'password', 'token', 'cb' ], <<"JS",
            var me = this;

            me.doChangePassword(password, token, function (res) {
                if (res.isSuccess()) {
                    Ext.toast($l10n->{'Password changed'}, 5000);

                    if (cb) cb(true);
                }
                else {
                    me.onRequestError(res);

                    if (cb) cb(false);
                }
            });
JS

        onRecoverPassword => func [ 'username', 'cb' ], <<"JS",
            var me = this;

            me.doRecoverPassword(username, function (res) {
                if (res.isSuccess()) {
                    Ext.toast($l10n->{'Password change instructions was sent to the email address, associated with your account.'}, 5000);

                    if (cb) cb(true);
                }
                else {
                    me.onRequestError(res);

                    if (cb) cb(false);
                }
            });
JS

        # API
        doSignin => func [ 'username', 'password', 'cb' ], <<"JS",
            this.api.signin({
                username: username,
                password: password
            }, cb);
JS

        doSignout => func [], <<"JS",
            this.api.signout();
JS

        doSetLocale => func ['locale'], <<"JS",
            this.api.setLocale(locale);
JS

        doChangePassword => func [ 'password', 'token', 'cb' ], <<"JS",
            this.api.changePassword({
                password: password,
                token: token
            }, cb);
JS

        doRecoverPassword => func [ 'username', 'cb' ], <<"JS",
            this.api.recoverPassword(username, cb);
JS

        # ROUTES HANDLERS
        routeChangePassword => func ['values'], <<"JS",
            Ext.create({
                xtype: "$type->{'/Pcore/Ext/Lib/Core/Viewport/change_password'}",
                token: values.token,
                redirectOnClose: ''
            }).show();

            this.unmask();
JS
    };
}

# SIGNIN DIALOG
sub EXT_signin_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        submit => func [],
        <<"JS",
                var me = this;
                var view = this.getView();
                var form = view.down('fieldpanel');

                if (form.validate()) {
                    Ext.fireEvent('signin',
                        form.getFields('username').getValue(),
                        form.getFields('password').getValue(),
                        this.lookup('remember_me').isChecked(),
                        function (success) {if (success) view.destroy()}
                    );
                }
JS

        recoverPassword => func [], <<"JS",
                var me = this;
                var view = this.getView(),
                    form = view.down('fieldpanel'),
                    username_field = form.getFields('username');

                form.clearErrors();

                if (username_field.validate()) {
                    Ext.fireEvent('mask');

                    Ext.fireEvent('recoverPassword',
                        username_field.getValue(),
                        function (success) {
                            Ext.fireEvent('unmask');

                            form.reset(true);
                        }
                    );
                }
JS
    };
}

sub EXT_signin : Extend('Ext.Dialog') : Type('widget') {
    return {
        controller => $type->{signin_controller},

        title        => { text => l10n('SIGN IN') },
        defaultFocus => 'textfield[name=username]',
        draggable    => \0,
        width        => 320,

        keyMap => { ENTER => 'submit', },

        items => [ {
            xtype => 'fieldpanel',

            items => [
                {   xtype       => 'textfield',
                    name        => 'username',
                    label       => l10n('User name'),
                    placeholder => l10n('email'),
                    allowBlank  => \0,
                    required    => \1,
                },
                {   xtype       => 'passwordfield',
                    name        => 'password',
                    label       => l10n('Password'),
                    placeholder => l10n('password'),
                    allowBlank  => \0,
                    required    => \1,
                },
                {   xtype     => 'checkboxfield',
                    reference => 'remember_me',
                    boxLabel  => l10n('Remember me'),
                    checked   => 1,
                },
            ],

            buttons => [
                {   text    => l10n('Forgot password'),
                    ui      => 'decline',
                    handler => 'recoverPassword',
                },
                {   text      => l10n('Sign in'),
                    iconCls   => $FAS_SIGN_IN_ALT,
                    iconAlign => 'left',
                    ui        => 'confirm',
                    handler   => 'submit',
                },
            ]
        } ],
    };
}

# CHANGE PASSWORD DIALOG
sub EXT_change_password_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        submit => func [],
        <<"JS",
            var me = this;
            var view = this.getView();
            var form = view.down('fieldpanel');

            if (form.validate()) {
                var password = form.getFields('password').getValue(),
                    password1_field = form.getFields('password1');

                if (password != password1_field.getValue()) {
                    password1_field.setError($l10n->{'Passwords are not match'});

                    return;
                }

                Ext.fireEvent('mask');

                Ext.fireEvent('changePassword',
                    password,
                    view.getToken(),
                    function (success) {
                        Ext.fireEvent('unmask');

                        if (success) me.close()
                    }
                );
            }
JS

        close => func [], <<"JS",
            var view = this.getView();

            view.destroy();
JS

        onDestroy => func [], <<"JS",
            var view = this.getView(),
                redirectOnClose = view.getRedirectOnClose();

            if (redirectOnClose != null) this.redirectTo(redirectOnClose);
JS
    };
}

sub EXT_change_password : Extend('Ext.Dialog') : Type('widget') {
    return {
        controller => $type->{change_password_controller},

        config => {
            token           => undef,    # change password token
            redirectOnClose => undef,    # hash, to redirect to on destroy
        },

        title        => { text => l10n('PASSWORD CHANGING') },
        defaultFocus => 'passwordfield[name=password]',
        draggable    => \0,
        closable     => \1,
        width        => 320,

        keyMap => { ENTER => 'submit', },

        listeners => { destroy => 'onDestroy' },

        items => [ {
            xtype => 'fieldpanel',

            items => [
                {   xtype       => 'passwordfield',
                    name        => 'password',
                    label       => l10n('New password'),
                    placeholder => l10n('password'),
                    required    => \1,
                },
                {   xtype       => 'passwordfield',
                    name        => 'password1',
                    label       => l10n('Confirm new password'),
                    placeholder => l10n('password'),
                    required    => \1,
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

Pcore::Ext::Lib::Core::Viewport

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
