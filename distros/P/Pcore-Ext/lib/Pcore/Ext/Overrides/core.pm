package Pcore::Ext::Overrides::core;

use Pcore -l10n;

sub EXT_L10N : Name('Ext.L10N') {
    return {
        singleton => \1,

        currentLocale => 'en',

        locale => {
            en => {
                messages      => undef,
                pluralFormExp => func ['n'],
                q[return n == 1 ? 0 : 1;],
                settings => {
                    thousandSeparator => ',',
                    decimalSeparator  => '.',
                    currencySign      => '$',
                    currencySpacer    => $SPACE,
                    currentcyAtEnd    => \0,
                    dateFormat        => 'm/d/Y',
                    firstDayOfWeek    => 0,
                    weekendDays       => [ 6, 0 ]
                }
            },
        },

        getCurrentLocale => func <<'JS',
            return this.currentLocale;
JS

        hasLocale => func ['locale'], <<'JS',
            if (locale == 'en' || this.locale[locale]) {
                return true;
            }
            else {
                return false;
            }
JS

        addLocale => func [ 'locale', 'data' ], <<'JS',
            this.locale[locale] = data;
JS

        setLocale => func ['locale'], <<"JS",

            // already using required locale
            if (locale == this.currentLocale) return false;

            // locale is unknown
            if (!this.hasLocale(locale)) return false;

            // switching locale
            this.currentLocale = locale;

            Ext.Date.monthNames = [
                $l10n{January}, $l10n{February}, $l10n{March},
                $l10n{April},   $l10n{May},      $l10n{June},
                $l10n{July},    $l10n{August},   $l10n{September},
                $l10n{October}, $l10n{November}, $l10n{December}
            ];

            Ext.Date.shortMonthNames = [
                $l10n{Jan}, $l10n{Feb}, $l10n{Mar},
                $l10n{Apr}, $l10n{May}, $l10n{Jun},
                $l10n{Jul}, $l10n{Aug}, $l10n{Sep},
                $l10n{Oct}, $l10n{Nov}, $l10n{Dec}
            ];

            Ext.Date.dayNames = [
                $l10n{Sunday},    $l10n{Monday},   $l10n{Tuesday},
                $l10n{Wednesday}, $l10n{Thursday}, $l10n{Friday},
                $l10n{Saturday}
            ];

            Ext.Date.dayNamesShort = [
                $l10n{Sun}, $l10n{Mon}, $l10n{Tue},
                $l10n{Wed}, $l10n{Thu}, $l10n{Fri},
                $l10n{Sat}
            ];

            Ext.Date.monthNumbers = {
                [$l10n{January}]: 0, [$l10n{February}]: 1,  [$l10n{March}]: 2,
                [$l10n{April}]: 3,   [$l10n{May}]: 4,       [$l10n{June}]: 5,
                [$l10n{July}]: 6,    [$l10n{August}]: 7,    [$l10n{September}]: 8,
                [$l10n{October}]: 9, [$l10n{November}]: 10, [$l10n{December}]: 11,

                [$l10n{Jan}]: 0, [$l10n{Feb}]: 1,  [$l10n{Mar}]: 2,
                [$l10n{Apr}]: 3, [$l10n{May}]: 4,  [$l10n{Jun}]: 5,
                [$l10n{Jul}]: 6, [$l10n{Aug}]: 7,  [$l10n{Sep}]: 8,
                [$l10n{Oct}]: 9, [$l10n{Nov}]: 10, [$l10n{Dec}]: 11
            };

            Ext.apply(Ext.util.Format, (this.locale[locale].settings || this.locale.en.settings));

            Ext.Date.firstDayOfWeek = (this.locale[locale].settings || this.locale.en.settings).firstDayOfWeek;
            Ext.Date.weekendDays = (this.locale[locale].settings || this.locale.en.settings).weekendDays;

            return true;
JS

        l10n => func ['item'], <<'JS',

            // item: [msgid, msgid_plural, num]
            var locale = this.locale[this.currentLocale],
                msg;

            // single
            if (item[1] == null) {
                if (!locale.messages) return item[0];

                msg = (locale.messages[item[0]] || [])[0];

                return msg == null ? item[0] : msg;

            }

            // plural
            else {
                var num = parseInt(item[2]);
                if (isNaN(num)) num = 1;

                if (locale.messages && locale.pluralFormExp) {
                    var idx = locale.pluralFormExp(num);

                    msg = (locale.messages[item[0]] || [])[idx];

                    if (msg != null) return msg;
                }

                // default English rules
                if (num == 1) {
                    return item[0];
                } else {
                    return item[1];
                }
            }
JS

        string => func ['buf'], <<'JS',
            this.buf = buf;
JS
      },
      func ['Class'], <<'JS';
          Class.string.prototype = {
            toString: function () {
                var buf = '';

                for (var i = 0, len = this.buf.length; i < len; i++) {
                    if (Array.isArray(this.buf[i])) {
                        buf += Ext.L10N.l10n(this.buf[i]);
                    } else {
                        buf += this.buf[i];
                    }
                }

                return buf;
            }
        };
JS
}

# ExtDirect websocket integration
sub EXT_direct_websocket_provider : Extend('Ext.direct.RemotingProvider') : Type('direct') : Alias('websocketprovider') {
    return {
        invokeFunction => func [ 'action', 'method', 'args' ],
        <<'JS',
            var a = '/' + action.replace(/\./g, '/') + '/' + method.name;

            // this is ExtDirect call
            if (typeof args[2] == 'object' && args[2].type == 'direct') {
                var me = this;

                var cb = args[1],
                    scope = args[2];

                var tx = {
                    callback: cb && scope ? cb.bind(scope) : cb,
                    callbackOptions: args[3]
                };

                APP.getApplication().api.callArray(a, [args[0]], function (res) {
                    var directEvent;

                    if (res.isSuccess()) {
                        directEvent = Ext.create('direct.rpc', {
                            type: 'rpc',
                            tid: null,
                            result: res
                        });
                    } else {
                        directEvent = Ext.create('direct.exception', {
                            type: 'exception',
                            tid: null,
                            message: res
                        });
                    }

                    me.runCallback(tx, directEvent);
                });
            }

            // this is manual call
            else {
                Array.prototype.unshift.call(args, a);

                APP.getApplication().api.call.apply(APP.getApplication().api, args);
            }
JS
    };
}

# override filter serializer
sub EXT_override_data_proxy_Server : Override('Ext.data.proxy.Server') {
    return {
        encodeFilters => func ['filters'],
        <<'JS',
            var out = {},
                length = filters.length,
                i, filter;

            for (i = 0; i < length; i++) {
                filter = filters[i];

                filter.getFilterFn();

                if (filter.generatedFilterFn) {
                    out[filter.getProperty()] = [filter.getOperator() || '=', filter.getValue()];
                }
            }

            return this.applyEncoding(out);
JS
    };
}

# override sorter serializer
sub EXT_override_util_Sorter : Override('Ext.util.Sorter') {
    return {
        serialize => func <<'JS',
            return [this.getProperty(), this.getDirection()];
JS
    };
}

# override default values
sub EXT_override_data_proxy_Direct : Override('Ext.data.proxy.Direct') {
    return {
        batchActions => \1,
        pageParam    => $EMPTY,

        reader => {
            type                => 'json',
            rootProperty        => 'data',
            summaryRootProperty => 'summary',
        },

        writer => { clientIdProperty => '__client_id__' }
    };
}

# add methods for work with pcore response object
sub EXT_override_data_operation_Operation : Override('Ext.data.operation.Operation') {
    return {
        toString => func <<'JS',
            return this.getStatus() + ' ' + this.getReason();
JS

        toRes => func <<'JS',
            return APP.getApplication().api.res([this.getStatus(), this.getReason()]);
JS

        getStatus => func <<'JS',
            if (this.hasException()) {
                var error = this.getError();

                if (Ext.typeOf(error) == 'object') {
                    return error.status;
                } else {

                    // TODO get and return XHR status
                    return 500;
                }
            } else {
                return this.getResponse().result.status;
            }
JS

        getReason => func <<'JS',
            if (this.hasException()) {
                return this.getErrorReason();
            } else {
                return this.getResponse().result.reason;
            }
JS

        getErrorReason => func <<'JS',
            var error = this.getError();

            if (Ext.typeOf(error) == 'object') {
                return error.reason;
            } else {
                return error;
            }
JS

        getFormErrors => func <<'JS',
            var error = this.getError();

            if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
                return error.error;
            } else {
                return;
            }
JS
    };
}

# add methods for work with pcore response object
sub EXT_override_direct_Event : Override('Ext.direct.Event') {
    return {
        toString => func <<'JS',
            return this.getStatus() + ' ' + this.getReason();
JS

        getStatus => func <<'JS',
            var error = this.message;

            if (error) {
                if (Ext.typeOf(error) == 'object') {
                    return error.status;
                } else {

                    // TODO get and return XHR status
                    return 500;
                }
            } else {
                return this.result.status;
            }
JS

        getReason => func <<'JS',
            if (this.message) {
                return this.getErrorReason();
            } else {
                return this.result.reason;
            }
JS

        getErrorReason => func <<'JS',
            var error = this.message;

            if (Ext.typeOf(error) == 'object') {
                return error.reason;
            } else {
                return error;
            }
JS

        getFormErrors => func <<'JS',
            var error = this.message;

            if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
                return error.error;
            } else {
                return;
            }
JS
    };
}

# allow to redirect to '', when current hash is ''
# https://www.sencha.com/forum/showthread.php?343467-6-5-0-redirectTo-force-is-ignored
sub EXT_override_app_BaseController : Override('Ext.app.BaseController') {
    return {
        redirectTo => func [ 'hash', 'opt' ],
        <<'JS',
            var me = this,
                currentHash = Ext.util.History.getToken(),
                Router = Ext.route.Router,
                delimiter = Router.getMultipleToken(),

                // FIX IN HERE
                // check if currentHash is defined even if empty string
                tokens = currentHash == null ? [] : currentHash.split(delimiter),

                length = tokens.length,
                force, i, name, obj, route, token, match;
            if (hash === -1) {
                return Ext.util.History.back();
            } else if (hash === 1) {
                return Ext.util.History.forward();
            } else if (hash.isModel) {
                hash = hash.toUrl();
            } else if (Ext.isObject(hash)) {

                for (name in hash) {
                    obj = hash[name];
                    if (!Ext.isObject(obj)) {
                        obj = {
                            token: obj
                        };
                    }
                    if (length) {
                        route = Router.getByName(name);
                        if (route) {
                            match = false;
                            for (i = 0; i < length; i++) {
                                token = tokens[i];
                                if (route.matcherRegex.test(token)) {
                                    match = true;
                                    if (obj.token) {

                                        if (obj.fn && obj.fn.call(this, token, tokens, obj) === false) {


                                            continue;
                                        }
                                        tokens[i] = obj.token;
                                        if (obj.force) {

                                            route.lastToken = null;
                                        }
                                    } else {

                                        tokens.splice(i, 1);
                                        i--;
                                        length--;

                                        route.lastToken = null;
                                    }
                                }
                            }
                            if (obj && obj.token && !match) {

                                tokens.push(obj.token);
                            }
                        }
                    } else if (obj && obj.token) {

                        tokens.push(obj.token);
                    }
                }
                hash = tokens.join(delimiter);
            }
            if (opt === true) {

                force = opt;
                opt = null;
            } else if (opt) {
                force = opt.force;
            }

            length = tokens.length;

            if (force && length) {
                for (i = 0; i < length; i++) {
                    token = tokens[i];
                    Router.clearLastTokens(token);
                }
            }
            if (currentHash === hash) {
                if (force) {

                    Router.onStateChange(hash);
                }

                return false;
            }
            if (opt && opt.replace) {
                Ext.util.History.replace(hash);
            } else {
                Ext.util.History.add(hash);
            }

            return true;
JS
      },
      func ['Class'], <<'JS';

        // apply method on the BaseController that uses the Ext.route.Mixin
        Ext.app.BaseController.prototype.redirectTo = Class.prototype.redirectTo;
JS
}

sub EXT_override_util_Format : Override('Ext.util.Format') {
    return {
        label => func [ 'text', 'color' ],
        <<'JS',
            return '<span style="padding:2px 10px;background-color:' + color + ';">' + text + '</span>';
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Overrides::core

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
