package Pcore::Ext::Lib::Viewport;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

# VIEWPORT CONTROLLER
sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        isCordova => \0,

        api => {
            signin          => $api{'Auth/signin'},
            signout         => $api{'Auth/signout'},
            setLocale       => $api{'Auth/set_locale'},
            changePassword  => $api{'Auth/change_password'},
            recoverPassword => $api{'Auth/recover_password'},
        },

        # MATERIAL THEME
        defautTheme => {
            accent   => 'grey',
            base     => 'blue-grey',
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
            'confirm-email/:{token}(/.*)'   => 'routeConfirmEmail',
        },

        init => func ['view'], <<"JS",
            var me = this;

            me.isCordova = !!window.cordova;

            // parse API methods
            for (var method in me.api) {
                me.api[method] = Ext.direct.Manager.parseMethod(me.api[method]);
            }

            // set material theme
            me._applyTheme(me._getCurrentTheme());

            this.getViewModel().bind('{session.theme.darkMode}', function (newVal, oldVal, eOpt) {
                if (newVal == null) return;

                this.setTheme({ darkMode: newVal });
            }, this);

            Ext.util.History.hashbang = true;

            // set token and disconnect
            APP.getApplication().api.auth(this.getToken());

            Ext.route.Router.suspend();

            // cordova
            if (me.isCordova) {

                // initApp after device ready
                document.addEventListener('deviceready', function () {
                    me.onCordovaDeviceReady();

                    me.initApp();
                }, false);
            }

            // browser
            else {
                me.initApp();
            }

            me.callParent(arguments);
JS

        initApp => func <<"JS",
            var me = this;

            me.mask();

            me.doSignin(null, null, function(res) {
                if (res.isSuccess()) {

                    // get session
                    var session = me.checkSession(res.data);

                    me.setLocale(session.locale, function () {
                        Ext.route.Router.resume();

                        me.onAppReady();
                    });
                }
                else {
                    me.unmask();

                    var item = me.getView().add({
                        xtype: "$type{'/pcore/Form/ConnectionError/panel'}",
                        callback: function () {
                            me.getView().remove(item);

                            me.initApp();
                        }
                    });

                    me.getView().setActiveItem(item);
                }
            });
JS

        onCordovaDeviceReady => func <<'JS',
            return;
JS

        onAppReady => func <<'JS',
            return;
JS

        checkSession => func ['session'], <<'JS',
            session.hasRole = function (role) {
                if (!this.is_authenticated) return 0;

                if (this.is_root) return 1;

                return this.permissions[role] ? 1 : 0;
            };

            if (!Ext.isObject(session.locales)) session.locales = {};

            var locale = session.locale || localStorage.locale || session.default_locale;

            if (!session.locales[locale]) locale = session.default_locale;

            session.locale = locale;
            session.localeName = session.locales[locale];

            session.theme = this._getCurrentTheme();

            // update viewModel
            var viewModel = this.getViewModel();
            viewModel.set('session', session);

            return session;
JS

        # MATERIAL THEME
        setTheme => func ['theme'], <<"JS",
            if (!Ext.theme.Material) return;

            theme = Ext.apply(this._getCurrentTheme(), theme);

            localStorage.theme = JSON.stringify(theme);

            var session = this.getViewModel().get('session');
            if (session) session.theme = theme;

            this._applyTheme(theme);
JS

        _getCurrentTheme => func <<'JS',
            return Ext.apply({}, localStorage.theme ? JSON.parse(localStorage.theme) : {}, this.defaultTheme);
JS

        _applyTheme => func ['theme'], <<'JS',
            if (!Ext.theme.Material) return;

            Ext.manifest.material = Ext.manifest.material || {};
            Ext.manifest.material.toolbar = Ext.manifest.material.toolbar || {};
            Ext.manifest.material.toolbar.dynamic = true;

            Ext.theme.Material.setColors(theme);
JS

        # MASK
        mask => func <<'JS',
            this.getView().setMasked(this.defaultMask);
JS

        unmask => func <<'JS',
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

        getToken => func <<'JS',
            return sessionStorage.token || localStorage.token;
JS

        removeToken => func <<'JS',
            localStorage.removeItem('token');
            sessionStorage.removeItem('token');
JS

        # LOCALE
        onSetLocale => func ['locale'], <<"JS",

            // already using required locale
            if (Ext.L10N.getCurrentLocale() == locale) return;

            var me = this,
                viewModel = me.getViewModel(),
                session = viewModel.get('session');

            // locale is not allowed
            if (!session.locales[locale]) return;

            // store user locale in profile, if user is authenticated
            if (session.is_authenticated) this.doSetLocale(locale);

            me.setLocale(locale, function () {
                me.redirectTo(Ext.util.History.getToken(), {force: true});
            });
JS

        setLocale => func [ 'locale', 'cb' ], <<'JS',

            // already using required locale
            if (locale == Ext.L10N.getCurrentLocale()) {
                cb();
            }
            else {
                var me = this,
                    viewModel = me.getViewModel(),
                    session = viewModel.get('session');

                // locale is not allowed
                if (!session.locales[locale]) {
                    cb();

                    return;
                }

                // update localeName
                session.localeName = session.locales[locale];

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
                url: APP.getApplication().appCdn + '/locale/' + locale + '.js',
                onLoad: function () {
                    cb();
                }
            });
JS

        clearInterface => func <<'JS',
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

                    // get session
                    var session = me.checkSession(res.data);

                    // not authenticated
                    if (!session.is_authenticated) {
                        Ext.toast($l10n{'You have no permissions to access this area'}, 3000);

                        return;
                    }

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

        onSignout => func <<"JS",
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
                    Ext.toast($l10n{'Password changed'}, 5000);

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
                    Ext.toast($l10n{'Password change instructions was sent to the email address, associated with your account.'}, 5000);

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

        doSignout => func <<"JS",
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
            Ext.Viewport.add({
                xtype: "$type{'/pcore/Form/ChangePassword/dialog'}",
                token: values.token,
                redirectOnClose: ''
            }).show();

            this.unmask();
JS

        routeConfirmEmail => func ['values'], <<"JS",
            var me = this;

            $api{'Auth/confirm_email'}(values.token, function(res) {
                me.unmask();

                if (res.isSuccess()) {
                    Ext.toast($l10n{'Thank you, your email is confirmed.'}, 5000);
                }
                else {
                    Ext.toast($l10n{'Email confirmation error. Token is invalid.'}, 5000);
                }

                me.redirectTo('', {replace: true});

                return;
            });
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Viewport

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
