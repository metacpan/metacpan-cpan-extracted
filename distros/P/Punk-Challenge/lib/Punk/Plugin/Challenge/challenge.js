/* Punk::Plugin::Challenge - the browser solver.
 *
 * One file, no dependencies, no build step. Reads the puzzle from the
 * interstitial's data attributes, finds the nonce in a Worker so the page
 * stays responsive, posts the solution to the verify route, and goes where
 * the page said to go.
 *
 * The SHA-256 is written here, against FIPS 180-4, and checked against
 * Digest::SHA by the distribution's tests. Not Web Crypto: crypto.subtle
 * is asynchronous and each call is a round trip to the browser's crypto
 * thread, tens of microseconds, which at 2^16 calls is seconds and at 2^20
 * a minute. A straight implementation over typed arrays runs about a
 * million hashes a second in a Worker.
 *
 * window.PunkChallenge.solve(puzzle) returns a Promise of the solution
 * string, for a single-page application handling the 403 JSON from its own
 * fetch calls. solveSync and sha256hex are the same code with no Worker,
 * for the tests.
 */
(function (root) {
  'use strict';

  /* The solver, as a function so its source can be handed to a Worker.
   * Everything it needs is inside it: nothing from the enclosing scope
   * survives the trip through a Blob. */
  function makeSolver() {
    var K = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];
    var W = new Int32Array(64);
    var H = new Int32Array(8);

    /* SHA-256 of buf[0 .. len), which must have room for the padding:
     * ((len + 9 + 63) & ~63) bytes. The digest is left in H. */
    function sha256(buf, len) {
      var padded = (len + 9 + 63) & ~63;
      var i, j, a, b, c, d, e, f, g, h, t1, t2;
      buf[len] = 0x80;
      for (i = len + 1; i < padded; i++) buf[i] = 0;
      /* the bit length, big-endian; a message here is well under 2^32 bits */
      var bits = len * 8;
      buf[padded - 4] = (bits >>> 24) & 0xff;
      buf[padded - 3] = (bits >>> 16) & 0xff;
      buf[padded - 2] = (bits >>> 8) & 0xff;
      buf[padded - 1] = bits & 0xff;

      H[0] = 0x6a09e667; H[1] = 0xbb67ae85 | 0; H[2] = 0x3c6ef372; H[3] = 0xa54ff53a | 0;
      H[4] = 0x510e527f; H[5] = 0x9b05688c | 0; H[6] = 0x1f83d9ab; H[7] = 0x5be0cd19;

      for (i = 0; i < padded; i += 64) {
        for (j = 0; j < 16; j++) {
          W[j] = (buf[i + 4 * j] << 24) | (buf[i + 4 * j + 1] << 16)
               | (buf[i + 4 * j + 2] << 8) | buf[i + 4 * j + 3];
        }
        for (j = 16; j < 64; j++) {
          var w15 = W[j - 15], w2 = W[j - 2];
          var s0 = ((w15 >>> 7) | (w15 << 25)) ^ ((w15 >>> 18) | (w15 << 14)) ^ (w15 >>> 3);
          var s1 = ((w2 >>> 17) | (w2 << 15)) ^ ((w2 >>> 19) | (w2 << 13)) ^ (w2 >>> 10);
          W[j] = (W[j - 16] + s0 + W[j - 7] + s1) | 0;
        }
        a = H[0]; b = H[1]; c = H[2]; d = H[3]; e = H[4]; f = H[5]; g = H[6]; h = H[7];
        for (j = 0; j < 64; j++) {
          var S1 = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
          var ch = (e & f) ^ (~e & g);
          t1 = (h + S1 + ch + K[j] + W[j]) | 0;
          var S0 = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
          var maj = (a & b) ^ (a & c) ^ (b & c);
          t2 = (S0 + maj) | 0;
          h = g; g = f; f = e; e = (d + t1) | 0;
          d = c; c = b; b = a; a = (t1 + t2) | 0;
        }
        H[0] = (H[0] + a) | 0; H[1] = (H[1] + b) | 0; H[2] = (H[2] + c) | 0; H[3] = (H[3] + d) | 0;
        H[4] = (H[4] + e) | 0; H[5] = (H[5] + f) | 0; H[6] = (H[6] + g) | 0; H[7] = (H[7] + h) | 0;
      }
    }

    /* Leading zero bits of the digest in H. */
    function zeroBits() {
      var n = 0, i, w;
      for (i = 0; i < 8; i++) {
        w = H[i] >>> 0;
        if (w === 0) { n += 32; continue; }
        n += Math.clz32(w);
        break;
      }
      return n;
    }

    function encode(str) {
      return new TextEncoder().encode(str);
    }

    /* The difficulty is the third field of the puzzle. */
    function bitsOf(puzzle) {
      var f = String(puzzle).split('.');
      var bits = f.length === 5 ? parseInt(f[2], 10) : NaN;
      if (!(bits >= 1 && bits <= 22)) throw new Error('not a puzzle: ' + puzzle);
      return bits;
    }

    /* puzzle "." nonce for nonce = 0, 1, 2 ... until the hash begins with
     * bits zero bits. The prefix is encoded once; each nonce is written as
     * ASCII digits after it, into one buffer that is padded in place. */
    function solveSync(puzzle) {
      var bits = bitsOf(puzzle);
      var prefix = encode(puzzle + '.');
      var buf = new Uint8Array(prefix.length + 20 + 9 + 64);
      var nonce, digits, i, len;
      buf.set(prefix, 0);
      for (nonce = 0; ; nonce++) {
        digits = String(nonce);
        len = prefix.length + digits.length;
        for (i = 0; i < digits.length; i++) buf[prefix.length + i] = digits.charCodeAt(i);
        sha256(buf, len);
        if (zeroBits() >= bits) return puzzle + '.' + digits;
      }
    }

    function sha256hex(str) {
      var bytes = encode(str);
      var buf = new Uint8Array(bytes.length + 9 + 64);
      var out = '', i, w;
      buf.set(bytes, 0);
      sha256(buf, bytes.length);
      for (i = 0; i < 8; i++) {
        w = (H[i] >>> 0).toString(16);
        out += '00000000'.slice(w.length) + w;
      }
      return out;
    }

    return { solveSync: solveSync, sha256hex: sha256hex, bitsOf: bitsOf };
  }

  var solver = makeSolver();

  /* The Worker's whole program: the solver, and a message loop around it. */
  var workerSource = 'var S = (' + makeSolver.toString() + ')();\n'
    + 'onmessage = function (e) {\n'
    + '  try { postMessage({ solution: S.solveSync(e.data.puzzle) }); }\n'
    + '  catch (err) { postMessage({ error: String(err && err.message || err) }); }\n'
    + '};\n';

  /* Solve in a Worker, so the page thread stays responsive while the phone
   * works - a solver on the main thread makes the tab look hung, which
   * makes people close it. Inline when a Worker cannot be had. */
  function solve(puzzle) {
    return new Promise(function (resolve, reject) {
      var bits;
      try { bits = solver.bitsOf(puzzle); } catch (e) { reject(e); return; }
      var worker = null, url = null;
      function inline() {
        setTimeout(function () {
          try { resolve(solver.solveSync(puzzle)); } catch (e) { reject(e); }
        }, 0);
      }
      function done() {
        if (worker) { worker.terminate(); worker = null; }
        if (url) { URL.revokeObjectURL(url); url = null; }
      }
      if (typeof Worker === 'undefined' || typeof Blob === 'undefined'
          || typeof URL === 'undefined' || !URL.createObjectURL) {
        inline();
        return;
      }
      try {
        url = URL.createObjectURL(new Blob([workerSource], { type: 'text/javascript' }));
        worker = new Worker(url);
      }
      catch (e) {
        done();
        inline();
        return;
      }
      worker.onmessage = function (e) {
        done();
        if (e.data && e.data.solution) resolve(e.data.solution);
        else reject(new Error(e.data && e.data.error || 'no solution'));
      };
      worker.onerror = function () {
        done();
        inline();
      };
      worker.postMessage({ puzzle: puzzle, bits: bits });
    });
  }

  root.PunkChallenge = {
    solve: solve,
    solveSync: solver.solveSync,
    sha256hex: solver.sha256hex
  };

  /* The interstitial: solve, post the solution as JSON, and on a 200 go
   * where the page said. On anything else, submit the hidden form: the
   * server-side path that answers with a redirect, and works where fetch
   * did not. `to` is a same-origin path or nothing at all. */
  function samePath(to) {
    return (typeof to === 'string' && to.charAt(0) === '/' && to.charAt(1) !== '/') ? to : '/';
  }

  function start() {
    var body = root.document.body;
    var d = body && body.dataset;
    if (!d || !d.puzzle) return;
    var to = samePath(d.to);
    var form = root.document.querySelector('form input[name="solution"]');
    form = form && form.form;

    function fallback(solution) {
      if (!form) { root.location.replace(to); return; }
      form.elements.solution.value = solution;
      if (form.elements.to) form.elements.to.value = to;
      form.submit();
    }

    solve(d.puzzle).then(function (solution) {
      if (typeof root.fetch !== 'function') { fallback(solution); return; }
      root.fetch(d.verify, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify({ solution: solution })
      }).then(function (r) {
        if (r.ok) root.location.replace(to);
        else fallback(solution);
      }, function () {
        fallback(solution);
      });
    }, function () {
      /* not a puzzle: nothing to solve, and nothing to submit */
    });
  }

  if (root.document && root.document.body) start();
  else if (root.document && root.document.addEventListener)
    root.document.addEventListener('DOMContentLoaded', start);
})(typeof globalThis !== 'undefined' ? globalThis : (typeof self !== 'undefined' ? self : this));
