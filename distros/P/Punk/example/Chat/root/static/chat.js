/* The browser half of the chat.
 *
 * Nothing here is Punk-specific: it is a plain RFC 6455 WebSocket talking
 * the small JSON protocol Chat::Controller::WS::Chat speaks. The one detail
 * worth noticing is the scheme - the page is served over TLS, so the socket
 * must be wss://. A browser refuses a plain ws:// from a secure page, which
 * is why bin/punk-chat terminates TLS for both on the same port. */

(function () {
  'use strict';

  var section = document.querySelector('.chat');
  var room    = section.getAttribute('data-room');
  var log     = document.getElementById('log');
  var status  = document.getElementById('status');
  var count   = document.getElementById('count');
  var form    = document.getElementById('say');
  var text    = document.getElementById('text');
  var send    = document.getElementById('send');

  var params = new URLSearchParams(location.search);
  var nick   = params.get('nick') || '';

  var ws, retry = 0, closing = false;

  function setStatus(state, label) {
    status.setAttribute('data-state', state);
    status.textContent = label;
    var live = state === 'open';
    text.disabled = !live;
    send.disabled = !live;
  }

  /* Every value on the wire came from another user, so it goes in as text,
   * never as markup. */
  function line(cls, parts) {
    var li = document.createElement('li');
    li.className = 'line ' + cls;
    parts.forEach(function (p) {
      var el = document.createElement('span');
      el.className = p[0];
      el.textContent = p[1];
      li.appendChild(el);
    });
    var atBottom = log.scrollHeight - log.scrollTop - log.clientHeight < 40;
    log.appendChild(li);
    if (atBottom) log.scrollTop = log.scrollHeight;
    return li;
  }

  function clock(iso) {
    if (!iso) return '';
    var d = new Date(iso);
    return isNaN(d) ? iso : d.toLocaleTimeString();
  }

  function message(m) {
    line(m.nick === nick ? 'msg mine' : 'msg', [
      ['at',   clock(m.created)],
      ['nick', m.nick],
      ['body', m.body]
    ]);
  }

  function notice(what, m) {
    line('note ' + what, [
      ['at',   clock(m.created)],
      ['body', m.text]
    ]);
  }

  function connect() {
    var scheme = location.protocol === 'https:' ? 'wss://' : 'ws://';
    var url = scheme + location.host + '/ws/' + encodeURIComponent(room)
            + (nick ? '?nick=' + encodeURIComponent(nick) : '');

    setStatus('connecting', retry ? 'reconnecting' : 'connecting');

    /* The subprotocol the route declares; offering none of the accepted
     * ones is refused by the server before the upgrade completes. */
    ws = new WebSocket(url, 'punk.chat.v1');

    ws.onopen = function () {
      retry = 0;
      setStatus('open', 'connected');
      text.focus();
    };

    ws.onmessage = function (e) {
      var m;
      try { m = JSON.parse(e.data); } catch (err) { return; }

      switch (m.type) {
        case 'welcome':
          nick = m.nick;
          log.replaceChildren();
          (m.messages || []).forEach(message);
          notice('joined', { created: null, text: 'you are ' + nick });
          break;
        case 'message':
          message(m);
          break;
        case 'presence':
          count.textContent = m.connected + ' here';
          notice(m.event, {
            created: m.created,
            text: m.nick + (m.event === 'join' ? ' joined' : ' left')
          });
          break;
        case 'cleared':
          log.replaceChildren();
          notice('cleared', {
            created: m.created,
            text: m.deleted + ' messages cleared by ' + (m.by || 'an admin')
          });
          break;
        case 'error':
          notice('error', { created: null, text: m.message });
          break;
      }
    };

    ws.onclose = function (e) {
      if (closing) return;
      setStatus('closed', 'disconnected (' + e.code + ')');
      retry += 1;
      setTimeout(connect, Math.min(500 * retry, 5000));
    };

    ws.onerror = function () { /* onclose does the reporting */ };
  }

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var body = text.value.trim();
    if (!body || !ws || ws.readyState !== WebSocket.OPEN) return;
    ws.send(JSON.stringify({ text: body }));
    text.value = '';
  });

  window.addEventListener('beforeunload', function () {
    closing = true;
    if (ws) ws.close(1000, 'leaving');
  });

  connect();
})();
