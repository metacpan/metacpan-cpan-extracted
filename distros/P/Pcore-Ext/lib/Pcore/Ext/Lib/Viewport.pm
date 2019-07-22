package Pcore::Ext::Lib::Viewport;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];
use Pcore::App::API qw[:PERMISSIONS];

# VIEWPORT CONTROLLER
sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {
        isCordova => \0,

        api => {
            signin          => $api{'Auth/signin'},
            signout         => $api{'Profile/signout'},
            setLocale       => $api{'Profile/set_locale'},
            recoverPassword => $api{'Auth/recover_password'},
        },

        # MATERIAL THEME
        defautTheme => {
            accent   => 'grey',
            base     => 'blue-grey',
            darkMode => \0
        },

        defaultMask => { xtype => $type{'/pcore/Mask/loading'} },

        listen => {
            global => {
                mask            => 'mask',
                unmask          => 'unmask',
                unmatchedRoute  => 'onUnmatchedRoute',
                redirectTo      => 'onRedirectTo',
                remoteEvent     => 'onRemoteEvent',
                requestError    => 'onRequestError',
                signin          => 'onSignin',
                signout         => 'onSignout',
                setLocale       => 'onSetLocale',
                setTheme        => 'setTheme',
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

            Ext.state.Provider.register(new Ext.state.LocalStorage());

            // set material theme
            me._applyTheme(me._getCurrentTheme());

            this.getViewModel().bind('{settings.theme.darkMode}', function (newVal, oldVal, eOpt) {
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

        checkSession => func ['session'], <<"JS",
            session.hasPermissions = function (permissions) {

                // no permissions, authorization is not required
                if (!permissions) return 1;

                if (Ext.isArray(permissions)) {

                    // no permissions, authorization is not required
                    if (!permissions.length) return 1;

                    // compare permissions for authenticated session only
                    if (this.is_authenticated) {

                        // compare permissions
                        for ( let permission of permissions ) {
                            if (permission == '$PERMISSION_ANY_AUTHENTICATED_USER') return 1;

                            if (this.permissions[permission]) return 1;
                        }
                    }
                }
                else {
                    if (permissions == '$PERMISSION_ANY_AUTHENTICATED_USER' && this.is_authenticated) return 1;

                    if (this.permissions[permissions]) return 1;
                }

                return 0;
            };

            var settings = session.settings;
            delete session.settings;

            if (!Ext.isObject(settings.locales)) settings.locales = {};

            var locale = session.locale || localStorage.locale || settings.default_locale;

            if (!settings.locales[locale]) locale = settings.default_locale;

            session.locale = locale;
            session.localeName = settings.locales[locale];

            settings.theme = this._getCurrentTheme();

            // update viewModel
            var viewModel = this.getViewModel();
            viewModel.set('session', session);
            viewModel.set('settings', settings);

            return session;
JS

        # MATERIAL THEME
        setTheme => func ['theme'], <<"JS",
            if (!Ext.theme.Material) return;

            theme = Ext.apply(this._getCurrentTheme(), theme);

            localStorage.theme = JSON.stringify(theme);

            var settings = this.getViewModel().get('settings');
            if (settings) settings.theme = theme;

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
        mask => func ['view'], <<'JS',
            if (!view) view = this.getView();

            view.setMasked(this.defaultMask);
JS

        unmask => func ['view'], <<'JS',
            if (!view) view = this.getView();

            view.unmask();
JS

        # EVENTS
        onUnmatchedRoute => func ['hash'], <<'JS',
            this.redirectTo('', {replace: true});
JS

        onRedirectTo => func [ 'hash', 'args' ], <<'JS',
            this.redirectTo( hash, args );
JS

        onRequestError => func ['res'], <<'JS',
            Ext.toast("Error: " + res, 3000);
JS

        # TODO
        onRemoteEvent => func ['ev'], <<'JS',
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
                session = viewModel.get('session'),
                settings = viewModel.get('settings');

            // locale is not allowed
            if (!settings.locales[locale]) return;

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
                    session = viewModel.get('session'),
                    settings = viewModel.get('settings');

                // locale is not allowed
                if (!settings.locales[locale]) {
                    cb();

                    return;
                }

                // update localeName
                session.localeName = settings.locales[locale];

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

                // remove item from the parent container and destroy it
                item.destroy();
            });
JS

        # USER ACTIONS
        onSignin => func [ 'username', 'password', 'persistent', 'cb' ], <<"JS",
            var me = this;

            me.doSignin(username, password, function (res) {
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
