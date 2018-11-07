// inspired by and forked from https://github.com/sockjs/websocket-multiplex/blob/master/multiplex_client.js

// EventTarget implementation taken (mostly) from
// https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
class EventTarget {

  constructor () {
    this.listeners = {};
  }

  addEventListener(type, callback) {
    if (!(type in this.listeners)) {
      this.listeners[type] = [];
    }
    this.listeners[type].push(callback);
  }

  removeEventListener(type, callback) {
    let listeners = this.listeners[type];
    if (!listeners) return;
    let index = listeners.findIndex(cb => cb === callback);
    if (index >= 0) listeners.splice(index, 1);
  }

  dispatchEvent(event) {
    let type = event.type;

    // handle subscription via on attributes
    if(this['on' + type]) {
      this['on' + type].call(this, event);
    }

    // handle listeners added via addEventListener
    if (type in this.listeners) {
      this.listeners[type].forEach(cb => cb.call(this, event));
    }

    return !event.defaultPrevented;
  }

  hasEventListeners(type) {
    if(('on' + type) in this) {
      return true;
    }

    if (type in this.listeners && this.listeners[type].length) {
      return true;
    }

    return false;
  }

}

class WebSocketMultiplexSubscriber extends EventTarget {

  constructor(channel) {
    super();
    this._channel   = channel;
    this.readyState = WebSocket.CONNECTING;

    // add jsonmessage event, to save reparsing of json data, common to websockets
    this.addEventListener('message', event => {
      // JSON.parse is expensive if there are no subscribers
      if (!this.hasEventListeners('jsonmessage')) return;
      let e = new MessageEvent('jsonmessage', { data: JSON.parse(event.data) });
      this.dispatchEvent(e);
    });
  }

  send(data) {
    // if not OPEN throw DOMException.INVALID_STATE_ERR
    this._channel.send(data);
  }

  close() {
    this.readyState = WebSocket.CLOSING;
    this._channel.removeSubscriber(this);
    this._channel = null;
  }

}

class WebSocketMultiplexChannel {

  constructor(multiplex, name) {
    this.multiplex    = multiplex;
    this.name         = name;
    this.subscribed   = false;
    this.reconnecting = false;
    this.subscribers  = [];
  }

  subscribe() {
    if (this.subscribed) return;
    this.multiplex.ws.send('sub,' + this.name);
  }

  setSubscribed() {
    this.subscribed = true;
    this.eachSubscriber(function(subscriber) {
      this.setSubscriberOpen(subscriber);
    });
    this.reconnecting = false;
  }

  unsubscribe() {
    if (!this.subscribed) return;
    this.multiplex.ws.send('uns,' + this.name);
  }

  setUnsubscribed() {
    if (!this.subscribed) return;
    this.eachSubscriber(function(subscriber) {
      this.setSubscriberClosed(subscriber);
    });
    this.subscribers = [];
  }

  setReconnecting() {
    this.reconnecting = true;
    this.subscribed   = false;
    this.eachSubscriber(subscriber => {
      subscriber.readyState = WebSocket.CONNECTING;
      subscriber.dispatchEvent(new CustomEvent('reconnecting'));
    });
  }

  subscriber() {
    let subscriber = new WebSocketMultiplexSubscriber(this);
    this.subscribers.push(subscriber);
    if (this.subscribed) {
      window.setTimeout(() => { this.setSubscriberOpen(subscriber) }, 0);
    }
    return subscriber;
  }

  setSubscriberOpen(subscriber) {
    if (subscriber.readyState == WebSocket.OPEN) return;
    subscriber.readyState = WebSocket.OPEN;
    if (this.reconnecting) {
      subscriber.dispatchEvent(new CustomEvent('reconnected'));
    } else {
      subscriber.dispatchEvent(new Event('open'));
    }
  }

  setSubscriberClosed(subscriber) {
    if (subscriber.readyState == WebSocket.CLOSED) return;
    subscriber.readyState = WebSocket.CLOSED;
    subscriber.dispatchEvent(new CloseEvent('closed'));
  }

  eachSubscriber(cb) {
    this.subscribers.forEach(s => cb.call(this, s));
  }

  removeSubscriber(subscriber) {
    let index = this.subscribers.findIndex(s => s === subscriber);
    if (index < 0) return;
    this.subscribers.splice(index, 1);
    this.setSubscriberClosed(subscriber);
    if (! this.subscribers.length) this.unsubscribe();
  }

  send(data) {
    this.multiplex.ws.send('msg,' + this.name + ',' + data);
  }

  receiveMessage(payload) {
    this.eachSubscriber(s => s.dispatchEvent(new MessageEvent('message', {data: payload})));
  }

  receiveError(payload) {
    // this deviates from the WebSocket spec to include error detail
    this.eachSubscriber(s => s.dispatchEvent(new CustomEvent('error', {detail: payload})));
  }

}

export default class WebSocketMultiplex {

  constructor(ws) {
    if (ws instanceof WebSocket) {
      this.ws = ws;
    } else {
      this.ws = null;
      this._url = ws;
    }
    this.channels = {};
    this.open();
    this.closing = false;
  }

  get url () { return this._url || this.ws.url }
  set url (url) { this._url = url }

  open() {
    this.closing = false;

    if (!this.ws || this.ws.readyState > WebSocket.OPEN) {
      this.ws = new WebSocket(this.url);
    }

    this.ws.addEventListener('open', e => {
      this.eachChannel(channel => channel.subscribe());
    });

    this.ws.addEventListener('close', e => {
      this.eachChannel(channel => {
        if (this.closing) {
          //TODO handle true close
        } else {
          channel.setReconnecting();
        }
      });

      // can't use window.setTimeout(this.open, 500) because we're defining the open method
      window.setTimeout(() => { this.open() }, 500);
    });

    this.ws.addEventListener('message', e => {
      let t = e.data.split(',');
      let type = t.shift(),
          name = t.shift(),
          payload = t.join();

      if(!(name in this.channels)) return;
      let channel = this.channels[name];

      switch(type) {
        case 'sta':
          if (payload === 'true') {
            channel.setSubscribed();
          } else if (payload === 'false') {
            channel.setUnsubscribed();
            delete this.channels[name];
          }
          //TODO implement status request handler
          break;
        case 'uns':
          channel.setUnsubscribed();
          delete this.channels[name];
          break;
        case 'msg':
          channel.receiveMessage(payload);
          break;
        case 'err':
          channel.receiveError(payload);
          break;
      }
    });
  }

  close() {
    this.closing = true;
    this.ws.close();
  }

  eachChannel(cb) {
    Object.values(this.channels).forEach((channel) => { cb.call(this, channel) });
  }

  channel(raw_name) {
    let name = escape(raw_name);
    if (! this.channels[name] ) {
      this.channels[name] = new WebSocketMultiplexChannel(this, name);
      if (this.ws.readyState == WebSocket.OPEN) {
        this.channels[name].subscribe();
      }
    }
    return this.channels[name].subscriber();
  }

}


