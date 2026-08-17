// CSRF token auto-injection for AJAX requests.
// Reads the token from <meta name="csrf-token"> and adds it as
// X-CSRF-Token header on all mutating fetch/XMLHttpRequest calls.
(function () {
    'use strict';

    var token = null;

    function getToken() {
        if (token === null) {
            var meta = document.querySelector('meta[name="csrf-token"]');
            token = meta ? meta.getAttribute('content') : false;
        }
        return token || null;
    }

    function isMutating(method) {
        return ['POST', 'PUT', 'PATCH', 'DELETE'].indexOf(method.toUpperCase()) !== -1;
    }

    function ensureHeader(headers) {
        if (headers instanceof Headers) {
            if (!headers.has('X-CSRF-Token')) {
                headers.set('X-CSRF-Token', getToken());
            }
            return headers;
        }
        // Plain object
        var lower = {};
        for (var k in headers) {
            if (headers.hasOwnProperty(k)) {
                lower[k.toLowerCase()] = k;
            }
        }
        if (!lower['x-csrf-token']) {
            headers['X-CSRF-Token'] = getToken();
        }
        return headers;
    }

    var t = getToken();
    if (!t) { return; }

    // Patch fetch
    var _fetch = window.fetch;
    window.fetch = function (url, opts) {
        opts = opts || {};
        var method = (opts.method || 'GET').toUpperCase();
        if (isMutating(method)) {
            if (opts.headers) {
                opts.headers = ensureHeader(opts.headers);
            } else {
                opts.headers = { 'X-CSRF-Token': t };
            }
        }
        return _fetch.call(this, url, opts);
    };

    // Patch XMLHttpRequest
    var _open  = XMLHttpRequest.prototype.open;
    var _send  = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function (method, url) {
        this.__csrf_method = method;
        return _open.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function (body) {
        if (isMutating(this.__csrf_method)) {
            this.setRequestHeader('X-CSRF-Token', t);
        }
        return _send.call(this, body);
    };
})();
