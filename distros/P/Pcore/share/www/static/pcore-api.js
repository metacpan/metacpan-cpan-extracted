/*
<script type="text/javascript">
    function onPcoreLoad() {
        API = new PCORE({
            url: '//centos/api/',
            version: 'v1',
            listenEvents: null,
            onConnect: function(api) {},
            onDisconnect: function(api, status, reason) {},
            onEvent: function(api, ev) {},
            onListen: function(api, events) {},
            onRpc: function(api, req, method, args) {
                req(200);

                req([200, 'OK'], data);

                req([200, 'OK'], data, {
                    total: 50,
                    rows: 100
                });
            }
        });

        API.call('Auth/app_init', 1, function(res) {
            console.log(res);
            console.log(res.toString());
            console.log(res.isSuccess());
        });
    };
</script>

<script src="/static/pcoreApi.js?cb=onPcoreLoad" type="text/javascript"></script>
*/

PCORE = function (obj) {
    this.version = obj.version;
    this.listenEvents = obj.listenEvents;
    this.onConnect = obj.onConnect;
    this.onDisconnect = obj.onDisconnect;
    this.onEvent = obj.onEvent;
    this.onListen = obj.onListen;
    this.onRpc = obj.onRpc;

    var a = document.createElement('a');
    a.href = obj.url || '/api/';
    var url = new URL(a.href);
    if (url.protocol != 'ws:' && url.protocol != 'wss:') {
        if (url.protocol == 'https:') {
            url.protocol = 'wss:';
        } else {
            url.protocol = 'ws:';
        }
    }
    this.url = url.toString();

    Object.setPrototypeOf(this, pcoreApi);
};

var pcoreApi = {
    url: null,
    version: null,
    listenEvents: null,
    onConnect: null,
    onDisconnect: null,
    onEvent: null,
    onListen: null,
    onRpc: null,

    _ws: null,
    _connId: 0,
    _tid: 0,
    _sendQueue: [],
    _tidCallbacks: {},

    connect: function () {
        if (!this._ws) {
            this._ws = new WebSocket(this.url, 'pcore');

            this._ws.binaryType = 'blob';

            var me = this;

            this._ws.onopen = function (e) {
                me._onConnect(e);
            };

            this._ws.onclose = function (e) {
                me._onDisconnect(e);
            };

            this._ws.onmessage = function (e) {
                me._onMessage(e);
            };
        }
    },

    disconnect: function () {
        if (this._ws) {
            this._ws.close(1000, 'disconnected');
        }
    },

    res: function (status) {
        var res = {};

        if (Array.isArray(status)) {
            res.status = status[0];

            res.reason = status[1];
        } else {
            res.status = status;

            res.reason = '';
        }

        Object.setPrototypeOf(res, pcoreApiResponse);

        return res;
    },

    call: function () {
        var method = arguments[0],
            cb,
            args;

        if (arguments.length > 1) {
            if (typeof arguments[arguments.length - 1] == 'function') {
                cb = arguments[arguments.length - 1];

                if (arguments.length > 2) {
                    args = Array.prototype.slice.call(arguments, 1, -1);
                }
            } else {
                args = Array.prototype.slice.call(arguments, 1);
            }
        }

        this.callArray(method, args, cb);
    },

    callArray: function (method, args, cb) {
        if (method.substring(0, 1) != '/') {
            method = '/' + this.version + '/' + method;
        }

        var msg = {
            type: 'rpc',
            method: method,
            args: args
        };

        this._sendQueue.push([msg, cb]);

        this._send();
    },

    fireRemoteEvent: function (key, data) {
        var msg = {
            type: 'event',
            event: {
                key: key,
                data: data
            }
        };

        this._sendQueue.push([msg, null]);

        this._send();
    },

    listenRemoteEvents: function (events) {
        var msg = {
            type: 'listen',
            events: events
        };

        this._sendQueue.push([msg, null]);

        this._send();
    },

    _send: function () {
        if (this._ws && this._ws.readyState == 1) {
            while (this._sendQueue.length) {
                var msg = this._sendQueue.pop();

                if (msg[1]) {
                    msg[0].tid = ++this._tid;

                    this._tidCallbacks[msg[0].tid] = msg[1];
                }

                this._ws.send(JSON.stringify(msg[0]));
            }

        } else {
            this.connect();
        }
    },

    _onConnect: function (e) {
        if (this.listenEvents) {
            var msg = {
                type: 'listen',
                events: this.listenEvents
            };

            this._ws.send(JSON.stringify(msg));
        }

        this._send();

        if (this.onConnect) {
            this.onConnect(this);
        }
    },

    _onDisconnect: function (e) {
        var status = e.code,
            reason = e.reason || 'Abnormal Closure';

        this._connId++;

        for (var tid in this._tidCallbacks) {
            cb = this._tidCallbacks[tid];

            delete this._tidCallbacks[tid];

            cb({
                status: status,
                reason: reason
            });
        }

        this._ws = null;

        if (this.onDisconnect) {
            this.onDisconnect(this, status, reason);
        }

        if (this._sendQueue.length) {
            this.connect();
        }
    },

    _onMessage: function (e) {
        var tx = JSON.parse(e.data);

        if (tx.type == 'listen') {
            if (this.onListen) {
                this.onListen(this, tx.events);
            }
        } else if (tx.type == 'event') {
            if (this.onEvent) {
                this.onEvent(this, tx.event);
            }
        } else if (tx.type == 'rpc') {
            if (tx.method) {
                if (this.onRpc) {
                    var req = pcoreApiRequest.bind({
                        _api: this,
                        _connId: this._connId,
                        _tid: tx.tid
                    });

                    this.onRpc(this, req, tx.method, tx.args);
                } else {
                    var msg = {
                        type: 'rpc',
                        tid: tx.tid,
                        result: {
                            status: 400,
                            reason: 'RPC calls are not supported'
                        }
                    };

                    this._sendQueue.push([msg, null]);

                    this._send();
                }
            } else {
                if (this._tidCallbacks[tx.tid]) {
                    cb = this._tidCallbacks[tx.tid];

                    delete this._tidCallbacks[tx.tid];

                    Object.setPrototypeOf(tx.result, pcoreApiResponse);

                    cb(tx.result);
                }
            }
        }
    }
};

var pcoreApiRequest = function () {
    if (this._tid && this._connId == this._api._connId) {
        if (this._respond) {
            console.log('Double response on PCORE API request');

            return;
        }

        this._respond = 1;

        var msg = {
            type: 'rpc',
            tid: this._tid,
        };

        if (arguments.length > 2) {
            msg.result = Object.assign({}, arguments[2]);

            msg.result.data = arguments[1];
        } else if (arguments.length == 2) {
            msg.result.data = arguments[1];
        }

        if (Array.isArray(arguments[0])) {
            msg.result.status = arguments[0][0];

            msg.result.reason = arguments[0][1];
        } else {
            msg.result.status = arguments[0];
        }

        if (!msg.result.reason) {
            msg.result.reason = 'Unknown Reason';
        }

        this._api._sendQueue.push([msg, null]);

        this._api._send();
    }
};

var pcoreApiResponse = {
    toString: function () {
        return this.status + ' ' + this.reason;
    },

    isInfo: function () {
        return this.status < 200;
    },

    isSuccess: function () {
        return this.status >= 200 && this.status < 300;
    },

    isRedirect: function () {
        return this.status >= 300 && this.status < 400;
    },

    isError: function () {
        return this.status >= 400;
    },

    isClientError: function () {
        return this.status >= 400 && this.status < 500;
    },

    isServerError: function () {
        return this.status >= 500;
    }
};

var re = /cb=([^&]+)/;
var cb = re.exec(document.currentScript.src);

if (cb && window[cb[1]] !== undefined) {
    window[cb[1]]();
}
