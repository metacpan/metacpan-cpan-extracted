(function () {
  'use strict';
  var ENDPOINT = document.body.dataset.endpoint;
  var $ = function (id) { return document.getElementById(id); };
  $('endpoint').textContent = ENDPOINT;

  function esc(s) {
    return String(s).replace(/[&<>]/g, function (c) {
      return c === '&' ? '&amp;' : c === '<' ? '&lt;' : '&gt;';
    });
  }

  /* tiny JSON syntax colouring for the response pane */
  function colour(json) {
    return esc(json).replace(
      /("(?:\\.|[^"\\])*")(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?/g,
      function (m, str, isKey, lit) {
        if (str) return '<span class="' + (isKey ? 'key' : 'str') + '">'
                      + str + (isKey || '') + '</span>';
        if (lit) return '<span class="lit">' + lit + '</span>';
        return '<span class="num">' + m + '</span>';
      });
  }

  function fail(label, detail) {
    $('status').textContent = label;
    $('status').className = 'bad';
    $('out').textContent = detail;
  }

  /* the Headers pane: a JSON object of string values, merged over the
     default Content-Type so a guard token or any custom header reaches
     the server - the introspection docs fetch sends them too */
  function headers() {
    var base = { 'Content-Type': 'application/json' };
    var text = $('headers').value.replace(/^\s+|\s+$/g, '');
    if (!text) return base;
    var h;
    try { h = JSON.parse(text); }
    catch (e) {
      fail('bad headers', 'Headers are not valid JSON: ' + e.message);
      return null;
    }
    if (!h || typeof h !== 'object' || h instanceof Array) {
      fail('bad headers', 'Headers must be a JSON object of strings');
      return null;
    }
    for (var k in h) base[k] = String(h[k]);
    return base;
  }

  function run() {
    var hdrs = headers();
    if (!hdrs) return;
    var body = { query: $('query').value };
    var vtext = $('variables').value.replace(/^\s+|\s+$/g, '');
    if (vtext) {
      try { body.variables = JSON.parse(vtext); }
      catch (e) {
        fail('bad variables',
             'Variables are not valid JSON: ' + e.message);
        return;
      }
    }
    var t0 = Date.now();
    fetch(ENDPOINT, {
      method: 'POST',
      headers: hdrs,
      body: JSON.stringify(body)
    }).then(function (res) {
      return res.text().then(function (text) {
        var ms = Date.now() - t0;
        $('status').textContent = res.status + ' in ' + ms + 'ms';
        $('status').className = res.ok ? 'ok' : 'bad';
        try {
          $('out').innerHTML = colour(
            JSON.stringify(JSON.parse(text), null, 2));
        } catch (e) { $('out').textContent = text; }
      });
    }).catch(function (e) {
      $('status').textContent = 'network error';
      $('status').className = 'bad';
      $('out').textContent = String(e);
    });
  }

  $('run').addEventListener('click', run);
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      run();
    }
  });
  $('query').addEventListener('keydown', function (e) {
    if (e.key === 'Tab') {
      e.preventDefault();
      var t = e.target, s = t.selectionStart;
      t.value = t.value.slice(0, s) + '  ' + t.value.slice(t.selectionEnd);
      t.selectionStart = t.selectionEnd = s + 2;
    }
  });

  /* schema docs from introspection - type names walk ofType chains */
  function typeRef(t) {
    if (!t) return '?';
    if (t.kind === 'NON_NULL') return typeRef(t.ofType) + '!';
    if (t.kind === 'LIST') return '[' + typeRef(t.ofType) + ']';
    return t.name || '?';
  }
  var Q = 'query { __schema { queryType { name } mutationType { name } '
        + 'types { name kind description fields(includeDeprecated: true) '
        + '{ name description args { name type '
        + '{ kind name ofType { kind name ofType { kind name '
        + 'ofType { kind name } } } } } type { kind name '
        + 'ofType { kind name ofType { kind name ofType { kind name } } } '
        + '} } } } }';
  function loadDocs() {
    var hdrs = headers();
    if (!hdrs) return;
    fetch(ENDPOINT, {
      method: 'POST',
      headers: hdrs,
      body: JSON.stringify({ query: Q })
    }).then(function (res) { return res.json(); }).then(function (d) {
      renderDocs(d);
    }).catch(function () {
      $('doc-list').textContent = 'introspection unavailable';
    });
  }
  function renderDocs(d) {
    var s = d.data && d.data.__schema;
    if (!s) {
      $('doc-list').textContent = d.errors && d.errors.length
        ? 'introspection refused: ' + d.errors[0].message
        : 'introspection disabled';
      return;
    }
    var roots = {};
    if (s.queryType) roots[s.queryType.name] = 'query';
    if (s.mutationType) roots[s.mutationType.name] = 'mutation';
    var html = '';
    s.types.forEach(function (t) {
      if (!t.fields || t.name.slice(0, 2) === '__') return;
      html += '<details' + (roots[t.name] ? ' open' : '') + '><summary>'
            + esc(t.name)
            + (roots[t.name] ? ' <span class="d">(' + roots[t.name] + ')</span>' : '')
            + '</summary>';
      t.fields.forEach(function (f) {
        var args = f.args.length
          ? '(' + f.args.map(function (a) {
              return esc(a.name) + ': ' + esc(typeRef(a.type));
            }).join(', ') + ')'
          : '';
        html += '<div class="f">' + esc(f.name) + args
              + ': <span class="t">' + esc(typeRef(f.type)) + '</span></div>';
      });
      html += '</details>';
    });
    $('doc-list').innerHTML = html || 'no object types';
  }
  $('doc-refresh').addEventListener('click', function (e) {
    e.preventDefault();
    $('doc-list').textContent = 'loading...';
    loadDocs();
  });
  loadDocs();
})();
