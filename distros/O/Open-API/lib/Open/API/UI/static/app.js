/* Open::API::UI - the whole client. Vanilla, one file, no dependencies.
 *
 * The server rendered the page shell (operation index, Authorize box);
 * this script fetches the spec JSON and does everything recursive in the
 * browser: schema trees, example payloads, try-it-out forms and request
 * execution. Nothing here is inline in the HTML, so the page runs under
 * script-src 'self'.
 */
(function () {
'use strict';

var CFG;            /* { basePath, specPath, tryIt, csrf: {header,cookie}|0 } */
var SPEC;           /* the fetched OpenAPI document */
var OPS = {};       /* operationId -> { path, method, op, item } */
var AUTH = {};      /* scheme name -> credential (or {user,pass}) */
var STORE_KEY = 'openapi-ui-auth';

/* ---- tiny DOM helpers --------------------------------------------------- */

function $(sel, el) { return (el || document).querySelector(sel); }
function $$(sel, el) {
    return Array.prototype.slice.call((el || document).querySelectorAll(sel));
}
function el(tag, attrs, kids) {
    var e = document.createElement(tag), k, i;
    if (attrs) for (k in attrs) {
        if (k === 'text') e.textContent = attrs[k];
        else if (k === 'class') e.className = attrs[k];
        else e.setAttribute(k, attrs[k]);
    }
    if (kids) for (i = 0; i < kids.length; i++)
        if (kids[i]) e.appendChild(kids[i]);
    return e;
}
function text(s) { return document.createTextNode(s); }

/* ---- boot ---------------------------------------------------------------- */

document.addEventListener('DOMContentLoaded', function () {
    CFG = JSON.parse($('#oa-config').textContent);
    fetch(CFG.specPath, { credentials: 'same-origin' })
        .then(function (r) {
            if (!r.ok) throw new Error('spec fetch: ' + r.status);
            return r.json();
        })
        .then(function (spec) { SPEC = spec; init(); })
        .catch(function (e) {
            var main = $('main') || document.body;
            main.insertBefore(
                el('p', { class: 'oa-note',
                          text: 'Could not load the spec (' + e.message + ')' }),
                main.firstChild);
        });
});

function init() {
    indexOperations();
    wireAuthorize();
    $$('details.oa-op').forEach(function (d) {
        d.addEventListener('toggle', function () {
            if (d.open) {
                hydrate(d);
                if (history.replaceState)
                    history.replaceState(null, '', '#' + d.id);
            }
        });
    });
    renderSchemaBrowser();
    followHash();
    window.addEventListener('hashchange', followHash);
}

function indexOperations() {
    var paths = SPEC.paths || {}, p, m, item, op;
    var methods = ['get', 'put', 'post', 'delete', 'options', 'head',
                   'patch', 'trace'];
    for (p in paths) {
        item = paths[p];
        if (!item || typeof item !== 'object') continue;
        for (var i = 0; i < methods.length; i++) {
            m = methods[i];
            op = item[m];
            if (op && op.operationId)
                OPS[op.operationId] = { path: p, method: m, op: op, item: item };
        }
    }
}

function followHash() {
    var h = location.hash.replace(/^#/, '');
    if (!h) return;
    /* accept swagger-ui style #/tag/opId as well as our #op-opId */
    if (h.charAt(0) === '/') {
        var seg = h.split('/');
        h = 'op-' + seg[seg.length - 1];
    }
    var d = document.getElementById(h);
    if (d && d.tagName === 'DETAILS') {
        d.open = true;   /* fires toggle -> hydrate */
        d.scrollIntoView();
    }
}

/* ---- $ref resolution ----------------------------------------------------- */

function resolveRef(ref) {
    if (typeof ref !== 'string' || ref.charAt(0) !== '#') return null;
    var node = SPEC, parts = ref.slice(2).split('/'), i, k;
    for (i = 0; i < parts.length; i++) {
        k = parts[i].replace(/~1/g, '/').replace(/~0/g, '~');
        if (node == null || typeof node !== 'object') return null;
        node = node[k];
    }
    return node == null ? null : node;
}

function refName(ref) {
    var seg = String(ref).split('/');
    return seg[seg.length - 1];
}

/* ---- schema rendering ----------------------------------------------------
 * renderSchema returns a DOM node describing a schema. `seen` is the set
 * of $ref strings already on this branch: a repeated ref renders as a
 * collapsed link instead of recursing (cycle guard).
 */

function typeOf(schema) {
    if (schema.type) {
        return Array.isArray(schema.type) ? schema.type.join(' | ')
                                          : schema.type;
    }
    if (schema.properties || schema.additionalProperties) return 'object';
    if (schema.items) return 'array';
    if (schema.enum) return 'enum';
    return '';
}

function constraintsOf(s) {
    var c = [];
    if (s.format) c.push(s.format);
    if (s.minimum !== undefined) c.push('>= ' + s.minimum);
    if (s.maximum !== undefined) c.push('<= ' + s.maximum);
    if (s.exclusiveMinimum !== undefined) c.push('> ' + s.exclusiveMinimum);
    if (s.exclusiveMaximum !== undefined) c.push('< ' + s.exclusiveMaximum);
    if (s.minLength !== undefined) c.push('minLength ' + s.minLength);
    if (s.maxLength !== undefined) c.push('maxLength ' + s.maxLength);
    if (s.minItems !== undefined) c.push('minItems ' + s.minItems);
    if (s.maxItems !== undefined) c.push('maxItems ' + s.maxItems);
    if (s.pattern) c.push('pattern ' + s.pattern);
    if (s.default !== undefined) c.push('default ' + JSON.stringify(s.default));
    if (s.nullable) c.push('nullable');
    if (s.enum) c.push('one of ' + s.enum.map(function (v) {
        return JSON.stringify(v);
    }).join(', '));
    return c.join(', ');
}

function renderSchema(schema, seen) {
    var box = el('div', { class: 'oa-schema' });
    box.appendChild(schemaTree(schema, seen || {}, null));
    return box;
}

function schemaTree(schema, seen, propName) {
    if (schema == null || typeof schema !== 'object')
        return el('span', { class: 'oa-prop-type', text: 'any' });

    if (schema.$ref) {
        var ref = schema.$ref, name = refName(ref);
        if (seen[ref])
            return el('span', { class: 'oa-cycle',
                                text: name + ' (recursive)' });
        var target = resolveRef(ref);
        if (!target)
            return el('span', { class: 'oa-cycle', text: ref + ' (unresolved)' });
        var branch = Object.create(seen);
        branch[ref] = true;
        var wrap = el('span', {});
        var body = null;
        var btn = el('button', { class: 'oa-ref-toggle', type: 'button',
                                 text: name });
        btn.addEventListener('click', function () {
            if (body) { body.hidden = !body.hidden; return; }
            body = el('div', {}, [schemaTree(target, branch, null)]);
            wrap.appendChild(body);
        });
        wrap.appendChild(btn);
        return wrap;
    }

    var kids = [], line = el('span', {});
    if (propName) {
        line.appendChild(el('span', { class: 'oa-prop-name', text: propName }));
        line.appendChild(text(' '));
    }

    var comb = schema.allOf ? 'allOf'
             : schema.oneOf ? 'oneOf'
             : schema.anyOf ? 'anyOf' : null;
    if (comb) {
        line.appendChild(el('span', { class: 'oa-prop-type', text: comb }));
        var ul = el('ul', {});
        schema[comb].forEach(function (sub) {
            ul.appendChild(el('li', {}, [schemaTree(sub, seen, null)]));
        });
        kids.push(line, ul);
        return el('span', {}, kids);
    }

    var t = typeOf(schema);
    line.appendChild(el('span', { class: 'oa-prop-type', text: t || 'any' }));
    var cons = constraintsOf(schema);
    if (cons) {
        line.appendChild(text(' '));
        line.appendChild(el('span', { class: 'oa-constraints', text: cons }));
    }
    if (schema.description) {
        line.appendChild(text(' - '));
        line.appendChild(el('span', { class: 'oa-constraints',
                                      text: schema.description }));
    }
    kids.push(line);

    if (t === 'object' || schema.properties) {
        var req = {}, i;
        (schema.required || []).forEach(function (r) { req[r] = true; });
        var props = schema.properties || {};
        var list = el('ul', {});
        Object.keys(props).forEach(function (name) {
            var item = el('li', {}, [schemaTree(props[name], seen, name)]);
            if (req[name])
                item.insertBefore(el('span', { class: 'oa-required',
                                               text: '* ' }),
                                  item.firstChild);
            list.appendChild(item);
        });
        if (schema.additionalProperties &&
            typeof schema.additionalProperties === 'object') {
            list.appendChild(el('li', {},
                [schemaTree(schema.additionalProperties, seen, '(additional)')]));
        }
        if (list.firstChild) kids.push(list);
    } else if (schema.items) {
        var inner = el('ul', {},
            [el('li', {}, [schemaTree(schema.items, seen, null)])]);
        kids.push(inner);
    }
    return el('span', {}, kids);
}

/* ---- example generation --------------------------------------------------- */

function exampleOf(schema, seen) {
    if (schema == null || typeof schema !== 'object') return null;
    if (schema.$ref) {
        if ((seen || {})[schema.$ref]) return null;
        var branch = Object.create(seen || {});
        branch[schema.$ref] = true;
        return exampleOf(resolveRef(schema.$ref) || {}, branch);
    }
    if (schema.examples) {
        if (Array.isArray(schema.examples) && schema.examples.length)
            return schema.examples[0];
        for (var k in schema.examples) {
            var ex = schema.examples[k];
            return ex && ex.value !== undefined ? ex.value : ex;
        }
    }
    if (schema.example !== undefined) return schema.example;
    if (schema.default !== undefined) return schema.default;
    if (schema.enum && schema.enum.length) return schema.enum[0];
    if (schema.allOf) {
        var merged = {};
        schema.allOf.forEach(function (sub) {
            var e = exampleOf(sub, seen);
            if (e && typeof e === 'object' && !Array.isArray(e))
                for (var p in e) merged[p] = e[p];
        });
        return merged;
    }
    if (schema.oneOf && schema.oneOf.length)
        return exampleOf(schema.oneOf[0], seen);
    if (schema.anyOf && schema.anyOf.length)
        return exampleOf(schema.anyOf[0], seen);

    var t = Array.isArray(schema.type) ? schema.type[0] : schema.type;
    if (!t) {
        if (schema.properties) t = 'object';
        else if (schema.items) t = 'array';
    }
    switch (t) {
        case 'object':
            var o = {}, props = schema.properties || {};
            for (var name in props) o[name] = exampleOf(props[name], seen);
            return o;
        case 'array':
            return schema.items ? [exampleOf(schema.items, seen)] : [];
        case 'integer': case 'number':
            return schema.minimum !== undefined ? schema.minimum : 0;
        case 'boolean': return true;
        case 'null':    return null;
        default:        return 'string';
    }
}

/* ---- operation hydration -------------------------------------------------- */

function mergedParams(entry) {
    /* path-item parameters apply to every method; operation-level ones
     * with the same (name, in) override them. */
    var seen = {}, out = [];
    var lists = [entry.op.parameters || [], entry.item.parameters || []];
    lists.forEach(function (list) {
        list.forEach(function (p) {
            if (p && p.$ref) p = resolveRef(p.$ref) || p;
            if (!p || !p.name) return;
            var key = (p.in || '') + ':' + p.name;
            if (seen[key]) return;
            seen[key] = true;
            out.push(p);
        });
    });
    return out;
}

function effectiveSecurity(op) {
    var sec = op.security !== undefined ? op.security : SPEC.security;
    return Array.isArray(sec) ? sec : [];
}

function hydrate(details) {
    if (details.getAttribute('data-hydrated')) return;
    details.setAttribute('data-hydrated', '1');
    var body = $('.oa-op-body', details);
    var entry = OPS[details.getAttribute('data-op')];
    if (!entry) {
        body.appendChild(el('p', { class: 'oa-note',
            text: 'operation not present in the spec JSON' }));
        return;
    }
    var op = entry.op;
    /* the shell already carries the description, markdown-rendered
     * server-side; only fall back to plain text when it is absent */
    if (op.description && !details.querySelector('.oa-md'))
        body.appendChild(el('p', { class: 'oa-description',
                                   text: op.description }));

    var params = mergedParams(entry);
    var inputs = { path: {}, query: {}, header: {} };
    if (params.length) {
        body.appendChild(el('h4', { text: 'Parameters' }));
        body.appendChild(paramTable(params, inputs));
    }

    var bodyUI = null;
    if (op.requestBody) {
        var rb = op.requestBody.$ref
            ? (resolveRef(op.requestBody.$ref) || {}) : op.requestBody;
        body.appendChild(el('h4', { text: 'Request body' +
            (rb.required ? ' (required)' : '') }));
        bodyUI = requestBodyUI(rb);
        body.appendChild(bodyUI.node);
    }

    if (CFG.tryIt) body.appendChild(tryUI(entry, inputs, bodyUI));

    body.appendChild(el('h4', { text: 'Responses' }));
    var resps = op.responses || {};
    Object.keys(resps).sort().forEach(function (status) {
        var r = resps[status];
        if (r && r.$ref) r = resolveRef(r.$ref) || r;
        var sec = el('div', {}, [
            el('p', {}, [
                el('span', { class: 'oa-status', text: status }),
                text(' ' + (r.description || ''))
            ])
        ]);
        var content = r.content || {};
        Object.keys(content).forEach(function (ct) {
            if (content[ct] && content[ct].schema) {
                sec.appendChild(el('p', { class: 'oa-note', text: ct }));
                sec.appendChild(renderSchema(content[ct].schema));
            }
        });
        body.appendChild(sec);
    });
}

function paramTable(params, inputs) {
    var table = el('table', { class: 'oa-params' });
    var head = el('tr', {});
    ['Name', 'In', 'Type', 'Description', CFG.tryIt ? 'Value' : '']
        .forEach(function (h) { head.appendChild(el('th', { text: h })); });
    table.appendChild(head);
    params.forEach(function (p) {
        var schema = p.schema || {};
        if (schema.$ref) schema = resolveRef(schema.$ref) || {};
        var row = el('tr', {});
        var name = el('td', {}, [text(p.name)]);
        if (p.required)
            name.insertBefore(el('span', { class: 'oa-required', text: '* ' }),
                              name.firstChild);
        row.appendChild(name);
        row.appendChild(el('td', { text: p.in || '' }));
        var t = el('td', {}, [text(typeOf(schema) || 'any')]);
        var cons = constraintsOf(schema);
        if (cons) {
            t.appendChild(el('br'));
            t.appendChild(el('span', { class: 'oa-constraints', text: cons }));
        }
        row.appendChild(t);
        row.appendChild(el('td', { class: 'oa-constraints',
                                   text: p.description || '' }));
        if (CFG.tryIt) {
            var cell = el('td', {});
            if (p.in === 'cookie') {
                cell.appendChild(el('span', { class: 'oa-note',
                    text: 'sent by the browser' }));
            } else if (inputs[p.in]) {
                var input = el('input', { type: 'text',
                    placeholder: schema.default !== undefined
                        ? String(schema.default) : '' });
                inputs[p.in][p.name] = { input: input, param: p,
                                         schema: schema };
                cell.appendChild(input);
            }
            row.appendChild(cell);
        }
        table.appendChild(row);
    });
    return table;
}

function isBinarySchema(s) {
    if (!s || typeof s !== 'object') return false;
    if (s.$ref) s = resolveRef(s.$ref) || {};
    return s.format === 'binary' || s.contentEncoding === 'base64';
}

/* One panel per declared content type, built lazily and swapped by the
 * select: a field list with file inputs for multipart, a single file
 * input for binary bodies, a textarea for everything else. */
function requestBodyUI(rb) {
    var content = rb.content || {};
    var types = Object.keys(content);
    var node = el('div', {});
    var select = null;
    if (types.length > 1) {
        select = el('select', { class: 'oa-ct-select' });
        types.forEach(function (ct) {
            select.appendChild(el('option', { value: ct, text: ct }));
        });
        node.appendChild(select);
    }
    var current = function () {
        return select ? select.value : (types[0] || 'application/json');
    };
    var stage = el('div', {});
    node.appendChild(stage);

    var panels = {};
    function panelFor(ct) {
        if (panels[ct]) return panels[ct];
        var p = { node: el('div', {}), kind: 'none' };
        var c = content[ct] || {};
        var schema = c.schema || null;
        if (schema) p.node.appendChild(renderSchema(schema));
        if (CFG.tryIt) buildInputs(p, ct, schema);
        panels[ct] = p;
        return p;
    }

    function buildInputs(p, ct, schema) {
        var deref = schema;
        if (deref && deref.$ref) deref = resolveRef(deref.$ref) || {};
        if (ct.indexOf('multipart/') === 0) {
            p.kind = 'form';
            p.fields = [];
            var props = (deref && deref.properties) || {};
            var req = {};
            ((deref && deref.required) || []).forEach(function (r) {
                req[r] = true;
            });
            Object.keys(props).forEach(function (name) {
                var ps = props[name] || {};
                if (ps.$ref) ps = resolveRef(ps.$ref) || {};
                var multi = ps.type === 'array';
                var item = multi ? (ps.items || {}) : ps;
                if (item.$ref) item = resolveRef(item.$ref) || {};
                var binary = isBinarySchema(item);
                var input = el('input',
                    binary ? { type: 'file' } : { type: 'text' });
                if (binary && multi) input.setAttribute('multiple', '');
                var label = el('label', {}, [text(name)]);
                if (req[name])
                    label.insertBefore(el('span', { class: 'oa-required',
                                                    text: '* ' }),
                                       label.firstChild);
                p.node.appendChild(el('div', { class: 'oa-field' },
                                      [label, input]));
                p.fields.push({ name: name, input: input, binary: binary });
            });
        } else if (ct === 'application/octet-stream' ||
                   isBinarySchema(deref)) {
            p.kind = 'file';
            p.file = el('input', { type: 'file' });
            p.node.appendChild(el('div', { class: 'oa-field' }, [p.file]));
        } else {
            p.kind = 'text';
            p.area = el('textarea', { class: 'oa-body-input',
                                      spellcheck: 'false' });
            var fill = el('button', { class: 'oa-btn', type: 'button',
                                      text: 'Fill example' });
            fill.addEventListener('click', function () {
                var ex = schema ? exampleOf(schema, {}) : null;
                p.area.value = ct.indexOf('json') >= 0
                    ? JSON.stringify(ex, null, 2)
                    : (ex == null ? '' : String(ex));
            });
            p.node.appendChild(fill);
            p.node.appendChild(p.area);
        }
    }

    var show = function () {
        stage.textContent = '';
        if (types.length) stage.appendChild(panelFor(current()).node);
    };
    show();
    if (select) select.addEventListener('change', show);

    return { node: node, contentType: current,
             panel: function () {
                 return types.length ? panelFor(current()) : null;
             } };
}

/* ---- try it out ------------------------------------------------------------ */

function tryUI(entry, inputs, bodyUI) {
    var box = el('div', { class: 'oa-try' });
    var exec = el('button', { class: 'oa-btn oa-exec', type: 'button',
                              text: 'Execute' });
    var out = el('div', { class: 'oa-response' });
    exec.addEventListener('click', function () {
        execute(entry, inputs, bodyUI, out);
    });
    box.appendChild(exec);
    box.appendChild(out);
    return box;
}

function baseURL() {
    /* absolute http(s) URLs and root-relative prefixes both just prepend;
     * an empty or missing servers list means same origin */
    var sel = $('#oa-server');
    return (sel ? sel.value : '').replace(/\/+$/, '');
}

function collectValue(rec) {
    var v = rec.input.value;
    if (v === '') return undefined;
    var s = rec.schema || {};
    var t = Array.isArray(s.type) ? s.type[0] : s.type;
    if (t === 'array')
        return v.split(',').map(function (x) { return x.trim(); });
    return v;
}

function execute(entry, inputs, bodyUI, out) {
    var method = entry.method.toUpperCase();
    var path = entry.path, name, rec, v;

    for (name in inputs.path) {
        rec = inputs.path[name];
        v = collectValue(rec);
        if (v === undefined) {
            renderError(out, "path parameter '" + name + "' is required");
            return;
        }
        path = path.split('{' + name + '}').join(encodeURIComponent(v));
    }

    var query = [];
    for (name in inputs.query) {
        v = collectValue(inputs.query[name]);
        if (v === undefined) continue;
        (Array.isArray(v) ? v : [v]).forEach(function (one) {
            query.push(encodeURIComponent(name) + '=' + encodeURIComponent(one));
        });
    }

    var headers = {};
    for (name in inputs.header) {
        v = collectValue(inputs.header[name]);
        if (v !== undefined) headers[name] = String(v);
    }

    attachAuth(headers, query, effectiveSecurity(entry.op));

    var unsafe = { GET: 0, HEAD: 0, OPTIONS: 0, TRACE: 0 }[method] !== 0;
    if (unsafe && CFG.csrf) {
        var tok = csrfToken();
        if (tok) headers[CFG.csrf.header] = tok;
    }

    var opts = { method: method, headers: headers,
                 credentials: 'same-origin' };
    if (bodyUI && method !== 'GET' && method !== 'HEAD') {
        var p = bodyUI.panel();
        var ct = bodyUI.contentType();
        if (p && p.kind === 'form') {
            var fd = new FormData(), any = false;
            p.fields.forEach(function (f) {
                if (f.binary) {
                    for (var i = 0; i < f.input.files.length; i++) {
                        fd.append(f.name, f.input.files[i]);
                        any = true;
                    }
                } else if (f.input.value !== '') {
                    fd.append(f.name, f.input.value);
                    any = true;
                }
            });
            /* no Content-Type here: the browser writes the multipart
             * header with its boundary */
            if (any) opts.body = fd;
        } else if (p && p.kind === 'file') {
            if (p.file.files[0]) {
                headers['Content-Type'] = ct;
                opts.body = p.file.files[0];
            }
        } else if (p && p.kind === 'text' && p.area.value !== '') {
            headers['Content-Type'] = ct;
            if (ct === 'application/x-www-form-urlencoded') {
                var parsed = null;
                try { parsed = JSON.parse(p.area.value); } catch (e) {}
                if (parsed && typeof parsed === 'object') {
                    var form = new URLSearchParams();
                    for (var k in parsed) form.append(k, parsed[k]);
                    opts.body = form.toString();
                } else opts.body = p.area.value;
            } else {
                opts.body = p.area.value;
            }
        }
    }

    var url = baseURL() + path + (query.length ? '?' + query.join('&') : '');
    var t0 = performance.now();
    fetch(url, opts).then(function (r) {
        return r.text().then(function (bodyText) {
            renderResponse(out, r, bodyText, performance.now() - t0);
        });
    }).catch(function (e) {
        renderError(out, 'request failed: ' + e.message +
            ' (a cross-origin server needs CORS and a wider connect-src)');
    });
}

function renderError(out, msg) {
    out.textContent = '';
    out.appendChild(el('p', {}, [
        el('span', { class: 'oa-status err', text: 'error' }),
        text(' ' + msg)
    ]));
}

function renderResponse(out, r, bodyText, ms) {
    out.textContent = '';
    var cls = r.status < 400 ? 'oa-status ok' : 'oa-status err';
    out.appendChild(el('p', {}, [
        el('span', { class: cls, text: String(r.status) }),
        text(' ' + (r.statusText || '')),
        el('span', { class: 'oa-elapsed',
                     text: Math.round(ms) + ' ms' })
    ]));
    var hdrs = [];
    r.headers.forEach(function (v, k) { hdrs.push(k + ': ' + v); });
    if (hdrs.length) {
        out.appendChild(el('h4', { text: 'Response headers' }));
        out.appendChild(el('pre', { class: 'oa-pre',
                                    text: hdrs.join('\n') }));
    }
    out.appendChild(el('h4', { text: 'Body' }));
    var pretty = bodyText;
    try { pretty = JSON.stringify(JSON.parse(bodyText), null, 2); }
    catch (e) {}
    out.appendChild(el('pre', { class: 'oa-pre',
                                text: pretty === '' ? '(empty)' : pretty }));
}

/* ---- authorize ------------------------------------------------------------- */

function wireAuthorize() {
    var saved = null;
    try { saved = JSON.parse(sessionStorage.getItem(STORE_KEY)); }
    catch (e) {}
    var remember = $('#oa-remember');
    if (saved) {
        AUTH = saved;
        if (remember) remember.checked = true;
    }
    var persist = function () {
        if (remember && remember.checked) {
            try { sessionStorage.setItem(STORE_KEY, JSON.stringify(AUTH)); }
            catch (e) {}
        } else {
            try { sessionStorage.removeItem(STORE_KEY); } catch (e) {}
        }
    };
    if (remember) remember.addEventListener('change', persist);

    $$('.oa-scheme').forEach(function (div) {
        var name = div.getAttribute('data-scheme');
        var type = div.getAttribute('data-type');
        var http = div.getAttribute('data-http');
        var wire = function (input, key) {
            if (AUTH[name] && AUTH[name][key] !== undefined)
                input.value = AUTH[name][key];
            input.addEventListener('input', function () {
                AUTH[name] = AUTH[name] || {};
                AUTH[name][key] = input.value;
                persist();
            });
            div.appendChild(input);
        };
        if (type === 'http' && http === 'basic') {
            wire(el('input', { type: 'text', placeholder: 'user',
                               autocomplete: 'off' }), 'user');
            wire(el('input', { type: 'password', placeholder: 'password',
                               autocomplete: 'off' }), 'pass');
        } else {
            var ph = type === 'apiKey' ? 'key value' : 'bearer token';
            wire(el('input', { type: 'password', placeholder: ph,
                               autocomplete: 'off' }), 'value');
        }
    });

    var csrfBox = $('#oa-csrf');
    if (csrfBox && CFG.csrf) {
        csrfBox.appendChild(el('h3', {}, [
            text('CSRF '),
            el('span', { class: 'oa-scheme-type',
                text: 'header ' + CFG.csrf.header +
                      ', cookie ' + CFG.csrf.cookie })
        ]));
        var input = el('input', { type: 'text', id: 'oa-csrf-token',
            placeholder: 'token (blank: read the ' + CFG.csrf.cookie +
                         ' cookie)',
            autocomplete: 'off' });
        csrfBox.appendChild(input);
    }
}

function attachAuth(headers, query, security) {
    /* Use the first alternative every one of whose schemes we hold a
     * credential for; with no credentials at all, attach nothing. */
    var schemes = (SPEC.components || {}).securitySchemes || {};
    var chosen = null;
    for (var i = 0; i < security.length; i++) {
        var alt = security[i], names = Object.keys(alt), ok = names.length > 0;
        for (var j = 0; j < names.length; j++)
            if (!credentialFor(names[j])) { ok = false; break; }
        if (ok) { chosen = names; break; }
    }
    if (!chosen) return;
    chosen.forEach(function (name) {
        var def = schemes[name] || {};
        var cred = credentialFor(name);
        if (def.type === 'http' && def.scheme === 'basic') {
            headers['Authorization'] =
                'Basic ' + btoa(cred.user + ':' + cred.pass);
        } else if (def.type === 'apiKey') {
            if (def.in === 'header') headers[def.name] = cred;
            else if (def.in === 'query')
                query.push(encodeURIComponent(def.name) + '=' +
                           encodeURIComponent(cred));
            /* in: cookie - the browser owns cookies; nothing to attach */
        } else {
            headers['Authorization'] = 'Bearer ' + cred;
        }
    });
}

function credentialFor(name) {
    var a = AUTH[name];
    if (!a) return null;
    var def = ((SPEC.components || {}).securitySchemes || {})[name] || {};
    if (def.type === 'http' && def.scheme === 'basic')
        return a.user || a.pass ? { user: a.user || '', pass: a.pass || '' }
                                : null;
    return a.value ? a.value : null;
}

/* ---- csrf ------------------------------------------------------------------ */

function csrfToken() {
    var manual = $('#oa-csrf-token');
    if (manual && manual.value) return manual.value;
    var want = CFG.csrf.cookie + '=';
    var parts = document.cookie.split(/;\s*/);
    for (var i = 0; i < parts.length; i++)
        if (parts[i].indexOf(want) === 0)
            return decodeURIComponent(parts[i].slice(want.length));
    return null;
}

/* ---- schema browser -------------------------------------------------------- */

function renderSchemaBrowser() {
    var section = $('#oa-schemas');
    var target = $('#oa-schemas-body');
    if (!section || !target) return;
    var schemas = (SPEC.components || {}).schemas || {};
    var names = Object.keys(schemas).sort();
    if (!names.length) return;
    names.forEach(function (name) {
        var seen = {};
        seen['#/components/schemas/' + name] = true;
        var d = el('details', {}, [
            el('summary', {}, [el('code', { text: name })]),
        ]);
        d.addEventListener('toggle', function () {
            if (d.open && !d.getAttribute('data-hydrated')) {
                d.setAttribute('data-hydrated', '1');
                d.appendChild(renderSchema(schemas[name], seen));
            }
        });
        target.appendChild(d);
    });
    section.hidden = false;
}

})();
