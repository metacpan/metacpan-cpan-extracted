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
    this.closing = false;
  };

  Object.defineProperty(WebSocketMultiplex.prototype, 'url', {
    get: function() { return this._url || this.ws.url },
    set: function(url) { this._url = url },
  });

  WebSocketMultiplex.prototype.open = function() {
    var self = this;
    self.closing = false;

    if (!self.ws || self.ws.readyState > WebSocket.OPEN) {
      self.ws = new WebSocket(self.url);
    }

    self.ws.addEventListener('open', function(e) {
      self.eachChannel(function(channel) { channel.subscribe() });
    });

    self.ws.addEventListener('close', function(e) {
      self.eachChannel(function(channel) {
        if (self.closing) {
          // handle true close
        } else {
          channel.setReconnecting();
        }
      });
      window.setTimeout(function(){ self.open() }, 500);
    });

    self.ws.addEventListener('message', function(e) {
      var t = e.data.split(',');
      var type = t.shift(), name = t.shift(),  payload = t.join();
      if(!(name in self.channels)) {
        return;
      }
      var channel = self.channels[name];

      switch(type) {
      case 'sta':
        if (payload === 'true') {
          channel.setSubscribed();
        } else if (payload === 'false') {
          channel.setUnsubscribed();
          delete self.channels[name];
        }
        //TODO implement status request handler
        break;
      case 'uns':
        channel.setUnsubscribed();
        delete self.channels[name];
        break;
      case 'msg':
        channel.receiveMessage(payload);
        break;
      case 'err':
        channel.receiveError(payload);
        break;
      }
    });
  };

  WebSocketMultiplex.prototype.close = function() {
    this.closing = true;
    this.ws.close();
  };

  WebSocketMultiplex.prototype.eachChannel = function(cb) {
    for (var channel in this.channels) {
      if (this.channels.hasOwnProperty(channel)) {
        cb.call(this, this.channels[channel]);
      }
    }
  };

  WebSocketMultiplex.prototype.channel = function(raw_name) {
    var name = escape(raw_name);
    if (! this.channels[name] ) {
      this.channels[name] = new WebSocketMultiplexChannel(this, name);
      if (this.ws.readyState == WebSocket.OPEN) {
        this.channels[name].subscribe();
      }
    }
    return this.channels[name].subscriber();
  };

  // ***

  var WebSocketMultiplexChannel = function(multiplex, name) {
    this.multiplex    = multiplex;
    this.name         = name;
    this.subscribed   = false;
    this.reconnecting = false;
    this.subscribers  = [];
  };

  WebSocketMultiplexChannel.prototype.subscribe = function() {
    if (this.subscribed) return;
    this.multiplex.ws.send('sub,' + this.name);
  };

  WebSocketMultiplexChannel.prototype.setSubscribed = function() {
    this.subscribed = true;
    this.eachSubscriber(function(subscriber) {
      this.setSubscriberOpen(subscriber);
    });
    this.reconnecting = false;
  };

  WebSocketMultiplexChannel.prototype.unsubscribe = function() {
    if (!this.subscribed) return;
    this.multiplex.ws.send('uns,' + this.name);
  };

  WebSocketMultiplexChannel.prototype.setUnsubscribed = function() {
    if (!this.subscribed) return;
    this.eachSubscriber(function(subscriber) {
      this.setSubscriberClosed(subscriber);
    });
    this.subscribers = [];
  };

  WebSocketMultiplexChannel.prototype.setReconnecting = function() {
    this.reconnecting = true;
    this.subscribed   = false;
    this.eachSubscriber(function(subscriber) {
      subscriber.readyState = WebSocket.CONNECTING;
      subscriber.dispatchEvent(new CustomEvent('reconnecting'));
    });
  };

  WebSocketMultiplexChannel.prototype.subscriber = function() {
    var subscriber = new WebSocketMultiplexSubscriber(this);
    this.subscribers.push(subscriber);
    var self = this;
    if (this.subscribed) {
      window.setTimeout(function() { self.setSubscriberOpen(subscriber) }, 0);
    }
    return subscriber;
  };

  WebSocketMultiplexChannel.prototype.setSubscriberOpen = function(subscriber) {
    if (subscriber.readyState == WebSocket.OPEN) return;
    subscriber.readyState = WebSocket.OPEN;
    if (this.reconnecting) {
      subscriber.dispatchEvent(new CustomEvent('reconnected'));
    } else {
      subscriber.dispatchEvent(new Event('open'));
    }
  };

  WebSocketMultiplexChannel.prototype.setSubscriberClosed = function(subscriber) {
    if (subscriber.readyState == WebSocket.CLOSED) return;
    subscriber.readyState = WebSocket.CLOSED;
    subscriber.dispatchEvent(new CloseEvent('closed'));
  };

  WebSocketMultiplexChannel.prototype.eachSubscriber = function(cb) {
    var stack = this.subscribers;
    for (var i = 0, l = stack.length; i < l; i++) {
      cb.call(this, stack[i]);
    }
  };

  WebSocketMultiplexChannel.prototype.removeSubscriber = function(subscriber) {
    var stack = this.subscribers;
    for (var i = 0, l = stack.length; i < l; i++) {
      if (stack[i] === subscriber){
        stack.splice(i, 1);
        this.setSubscriberClosed(subscriber);
        if (! stack.length) {
          this.unsubscribe();
        }
        return;
      }
    }
  };

  WebSocketMultiplexChannel.prototype.send = function(data) {
    this.multiplex.ws.send('msg,' + this.name + ',' + data);
  };

  WebSocketMultiplexChannel.prototype.receiveMessage = function(payload) {
    this.eachSubscriber(function(subscriber) {
      subscriber.dispatchEvent(new MessageEvent('message', {data: payload}));
    });
  };

  WebSocketMultiplexChannel.prototype.receiveError = function(payload) {
    this.eachSubscriber(function(subscriber) {
      // this deviates from the WebSocket spec to include error detail
      subscriber.dispatchEvent(new CustomEvent('error', {detail: payload}));
    });
  };

  // ***

  var WebSocketMultiplexSubscriber = function(channel) {
    var self = this;
    EventTarget.call(self);
    self._channel   = channel;
    self.readyState = WebSocket.CONNECTING;

    // add jsonmessage event, to save reparsing of json data, common to websockets
    self.addEventListener('message', function(event) {
      // JSON.parse is expensive if there are no subscribers
      if (!self.hasEventListeners('jsonmessage')) return;
      var e = new MessageEvent('jsonmessage', { data: JSON.parse(event.data) });
      self.dispatchEvent(e);
    });
  };
  WebSocketMultiplexSubscriber.prototype = new EventTarget();

  WebSocketMultiplexSubscriber.prototype.send = function(data) {
    // if not OPEN throw DOMException.INVALID_STATE_ERR
    this._channel.send(data);
  };

  WebSocketMultiplexSubscriber.prototype.close = function() {
    this.readyState = WebSocket.CLOSING;
    this._channel.removeSubscriber(this);
    this._channel = null;
  };

  return WebSocketMultiplex;
})();



