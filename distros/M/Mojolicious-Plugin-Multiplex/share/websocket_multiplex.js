// inspired by and forked from https://github.com/sockjs/websocket-multiplex/blob/master/multiplex_client.js

var WebSocketMultiplex = (function(){

  // EventTarget implementation taken (mostly) from
  // https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
  var EventTarget = function() {
    this.listeners = {};
  };

  EventTarget.prototype.listeners = null;
  EventTarget.prototype.addEventListener = function(type, callback) {
    if (!(type in this.listeners)) {
      this.listeners[type] = [];
    }
    this.listeners[type].push(callback);
  };

  EventTarget.prototype.removeEventListener = function(type, callback) {
    if (!(type in this.listeners)) {
      return;
    }
    var stack = this.listeners[type];
    for (var i = 0, l = stack.length; i < l; i++) {
      if (stack[i] === callback){
        stack.splice(i, 1);
        return;
      }
    }
  };

  EventTarget.prototype.dispatchEvent = function(event) {
    var type = event.type;

    // handle subscription via on attributes
    if(this['on' + type]) {
      this['on' + type].call(this, event);
    }

    // handle listeners added via addEventListener
    if (type in this.listeners) {
      var stack = this.listeners[type];
      for (var i = 0, l = stack.length; i < l; i++) {
        stack[i].call(this, event);
      }
    }

    return !event.defaultPrevented;
  };

  EventTarget.prototype.hasEventListeners = function(type) {
    if(('on' + type) in this) {
      return true;
    }

    if ((type in this.listeners) && (this.listeners[type].length)) {
      return true;
    }

    return false;
  };

    // ****

    var WebSocketMultiplex = function(ws) {
        if (ws instanceof WebSocket) {
            this.ws = ws;
        } else {
            this.ws = null;
            this._url = ws;
        }
        this.channels = {};
        this.open();
    };

    Object.defineProperty(WebSocketMultiplex.prototype, 'url', {
        get: function() { return this._url || this.ws.url },
        set: function(url) { this._url = url },
    });

    WebSocketMultiplex.prototype.open = function() {
        var self = this;

        if (!self.ws || self.ws.readyState > WebSocket.OPEN) {
          self.ws = new WebSocket(self.url);

          self.ws.addEventListener('open', function(e) {
              self.eachChannel(function(channel) {
                  setTimeout(function(){ channel.subscribe() }, 0);
              });
          });
        }

        self.ws.addEventListener('close', function(e) {
            self.eachChannel(function(channel) {
                channel.readyState = WebSocket.CONNECTING;
            });
            setTimeout(function(){ self.open() }, 500);
        });

        self.ws.addEventListener('message', function(e) {
            var t = e.data.split(',');
            var type = t.shift(), name = t.shift(),  payload = t.join();
            if(!(name in self.channels)) {
                return;
            }
            var sub = self.channels[name];

            switch(type) {
            case 'sta':
                if (payload === 'true') {
                    var was_open = sub.readyState === WebSocket.OPEN;
                    sub.readyState = WebSocket.OPEN;
                    if (! was_open) {
                      sub.dispatchEvent(new Event('open'));
                    }
                } else if (payload === 'false') {
                    var was_closed = sub.readyState === WebSocket.CLOSED;
                    sub.readyState = WebSocket.CLOSED;
                    delete self.channels[name];
                    if (! was_closed) {
                      sub.dispatchEvent(new CloseEvent('close'));
                    }
                }
                //TODO implement status request handler
                break;
            case 'uns':
                delete self.channels[name];
                sub.dispatchEvent(new CloseEvent('close'));
                break;
            case 'msg':
                sub.dispatchEvent(new MessageEvent('message', {data: payload}));
                break;
            case 'err':
                // this deviates from the WebSocket spec to include error detail
                sub.dispatchEvent(new CustomEvent('error', {detail: payload}));
                break;
            }
        });
    };

    WebSocketMultiplex.prototype.eachChannel = function(cb) {
        for (var channel in this.channels) {
            if (this.channels.hasOwnProperty(channel)) {
                cb(this.channels[channel]);
            }
        }
    };

    WebSocketMultiplex.prototype.channel = function(raw_name) {
        var name = escape(raw_name);
        if (! this.channels[name] ) {
            this.channels[name] = new WebSocketMultiplexChannel(this, name);
        }
        return this.channels[name];
    };


    var WebSocketMultiplexChannel = function(multiplex, name) {
        var self = this;
        EventTarget.call(self);
        this.multiplex = multiplex;
        var ws = multiplex.ws;
        this.name = name;

        // add jsonmessage event, to save reparsing of json data, common to websockets
        this.addEventListener('message', function(event) {
          // JSON.parse is expensive if there are no subscribers
          if (!this.hasEventListeners('jsonmessage')) return;
          var e = new MessageEvent('jsonmessage', { data: JSON.parse(event.data) });
          this.dispatchEvent(e);
        });

        this.readyState = WebSocket.CONNECTING;
        if(ws.readyState > WebSocket.CONNECTING) {
            setTimeout(function(){ self.subscribe() }, 0);
        } else {
            ws.addEventListener('open', function(){ self.subscribe() });
        }
    };
    WebSocketMultiplexChannel.prototype = new EventTarget();

    WebSocketMultiplexChannel.prototype.subscribe = function () {
        this.multiplex.ws.send('sub,' + this.name);
    };
    WebSocketMultiplexChannel.prototype.send = function(data) {
        this.multiplex.ws.send('msg,' + this.name + ',' + data);
    };
    WebSocketMultiplexChannel.prototype.close = function() {
        this.readyState = WebSocket.CLOSING;
        this.multiplex.ws.send('uns,' + this.name);
    };

    return WebSocketMultiplex;
})();


