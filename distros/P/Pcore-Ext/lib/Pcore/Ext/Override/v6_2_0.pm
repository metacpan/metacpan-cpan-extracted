package Pcore::Ext::Override::v6_2_0;

use Pcore;

sub overrides {
    return <<'JS';
        Ext.define('Ext.override.data.proxy.Direct', {
            override: 'Ext.data.proxy.Direct',

            compatibility: '6.*',

            batchActions: true,
            pageParam: '',

            reader: {
                type: 'json',
                rootProperty: 'data'
            },

            writer: {
                clientIdProperty: '__client_id__'
            }
        });

        Ext.define('Ext.override.data.operation.Operation', {
            override: 'Ext.data.operation.Operation',

            compatibility: '6.*',

            getStatus: function () {
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
            },

            getReason: function () {
                if (this.hasException()) {
                    return this.getErrorReason();
                } else {
                    return this.getResponse().result.reason;
                }
            },

            getErrorReason: function () {
                var error = this.getError();

                if (Ext.typeOf(error) == 'object') {
                    return error.reason;
                } else {
                    return error;
                }
            },

            getFormErrors: function () {
                var error = this.getError();

                if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
                    return error.error;
                } else {
                    return;
                }
            }
        });

        Ext.define('Ext.override.direct.Event', {
            override: 'Ext.direct.Event',

            compatibility: '6.*',

            getStatus: function () {
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
            },

            getReason: function () {
                if (this.message) {
                    return this.getErrorReason();
                } else {
                    return this.result.reason;
                }
            },

            getErrorReason: function () {
                var error = this.message;

                if (Ext.typeOf(error) == 'object') {
                    return error.reason;
                } else {
                    return error;
                }
            },

            getFormErrors: function () {
                var error = this.message;

                if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
                    return error.error;
                } else {
                    return;
                }
            }
        });

        // fix for Firefox v52+
        // https://www.sencha.com/forum/showthread.php?336762-Examples-don-t-work-in-Firefox-52-touchscreen/page2
        Ext.define('EXTJS_23846.Element', {
            override: 'Ext.dom.Element'
        }, function (Element) {
            var supports = Ext.supports,
                proto = Element.prototype,
                eventMap = proto.eventMap,
                additiveEvents = proto.additiveEvents;

            if (Ext.os.is.Desktop && supports.TouchEvents && !supports.PointerEvents) {
                eventMap.touchstart = 'mousedown';
                eventMap.touchmove = 'mousemove';
                eventMap.touchend = 'mouseup';
                eventMap.touchcancel = 'mouseup';

                additiveEvents.mousedown = 'mousedown';
                additiveEvents.mousemove = 'mousemove';
                additiveEvents.mouseup = 'mouseup';
                additiveEvents.touchstart = 'touchstart';
                additiveEvents.touchmove = 'touchmove';
                additiveEvents.touchend = 'touchend';
                additiveEvents.touchcancel = 'touchcancel';

                additiveEvents.pointerdown = 'mousedown';
                additiveEvents.pointermove = 'mousemove';
                additiveEvents.pointerup = 'mouseup';
                additiveEvents.pointercancel = 'mouseup';
            }
        });

        Ext.define('EXTJS_23846.Gesture', {
            override: 'Ext.event.publisher.Gesture'
        }, function (Gesture) {
            var me = Gesture.instance;

            if (Ext.supports.TouchEvents && !Ext.isWebKit && Ext.os.is.Desktop) {
                me.handledDomEvents.push('mousedown', 'mousemove', 'mouseup');
                me.registerEvents();
            }
        });

        Ext.define('Ext.override.direct.Provider', {
            override: 'Ext.direct.Provider',

            compatibility: '6.*',

            setToken: function(token) {
                var headers = this.getHeaders() || {};

                if (!token) {
                    delete headers.Authorization;
                }
                else {
                    headers.Authorization = 'Token ' + token;
                }

                this.setHeaders(headers);
            }
        });

        Ext.define('Pcore.direct.WebSocketProvider', {
            extend: 'Ext.direct.RemotingProvider',
            alias: 'direct.websocketprovider',

            token: null,

            webSocket: null,
            pendingCallbacks: [],
            pendingTransactions: {},

            getWebSocket: function (tid, cb) {
                if (!this.webSocket) {
                    var me = this;

                    this.pendingCallbacks.push([tid, cb]);

                    var protocol = location.protocol == 'https:'? 'wss':'ws';

                    var url = protocol + '://' + location.host + this.url;

                    if (this.token) {
                        url += '?access_token=' + this.token;
                    }

                    this.webSocket = new WebSocket(url, 'pcore');

                    this.webSocket.binaryType = 'blob';

                    this.webSocket.onopen = function (e) {me._onWebSocketOpen(e)};
                    this.webSocket.onmessage = function (e) {me._onWebSocketMessage(e)};
                    this.webSocket.onclose = function (e) {me._onWebSocketClose(e)};
                    this.webSocket.onerror = function (e) {me._onWebSocketError(e)};
                }

                // webSocket open
                else if (this.webSocket.readyState == 1) {
                    cb(this.webSocket);
                }

                // webSocket not ready
                else {
                    this.pendingCallbacks.push([tid, cb]);
                }
            },

            setToken: function(token) {
                if (token != this.token) {
                    this.token = token;

                    this.disconnect();
                }
            },

            disconnect: function () {
                if (this.webSocket) {
                    this.webSocket.close(1000, 'disconnected');

                    this.webSocket = null;

                    this._fireException();
                }
            },

            _onWebSocketOpen: function (e) {

                // run pending transactions
                while (this.pendingCallbacks.length) {
                    var cb = this.pendingCallbacks.pop();

                    cb[1](this.webSocket);
                }
            },

            _onWebSocketClose: function (e) {
                this.webSocket = null;

                this._fireException();
            },

            _onWebSocketError: function (e) {
                this.webSocket = null;

                this._fireException();
            },

            // TODO exception
            _onWebSocketMessage: function (e) {
                var me = this;

                var response = Ext.decode(e.data);

                var directEvent = Ext.create('direct.' + response.type, response);

                me.fireEvent('data', me, directEvent);

                transaction = me.getTransaction(directEvent);

                if (transaction) {
                    if (me.fireEvent('beforecallback', me, directEvent, transaction) !== false) {
                        me.runCallback(transaction, directEvent, true);
                    }

                    Ext.direct.Manager.removeTransaction(transaction);
                }
            },

            // TODO combine action + method, remove action + method from websocket.pcore protocol
            sendAjaxRequest: function(params) {
                var me = this;

                this.getWebSocket(params.jsonData.tid, function (webSocket) {
                    // pendingTransactions[params.jsonData.tid] = 1;

                    webSocket.send(Ext.encode(params.jsonData));
                });
            },

            // TODO process pending transactions
            _fireException: function() {

                // run pending transactions
                while (this.pendingCallbacks.length) {
                    var cb = this.pendingCallbacks.pop();

                    var transaction = Ext.direct.Manager.getTransaction(cb[0]);

                    if (transaction) {
                        var event = new Ext.direct.ExceptionEvent({
                            data: null,
                            transaction: transaction,
                            code: Ext.direct.Manager.exceptions.TRANSPORT,
                            message: 'Unable to connect to the server.',
                            xhr: null
                        });

                        this.runCallback(transaction, event, false);

                        Ext.direct.Manager.removeTransaction(transaction);
                    }
                }
            }
        });
JS
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Override::v6_2_0

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
