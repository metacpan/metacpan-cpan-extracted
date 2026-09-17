/* waterfall.js - pan and zoom a trace.
 *
 * THE WHOLE TRICK: every bar is positioned in terms of two CSS custom
 * properties on the container. A pan rewrites TWO PROPERTIES and the browser
 * recomputes layout once. The obvious implementation - walking the bars and
 * setting each one's left and width - is four thousand DOM writes for a large
 * trace, and it is why most trace viewers stutter.
 *
 * Everything here is enhancement. The waterfall is complete and correct in
 * the markup with this file absent.
 */
(function () {
  'use strict';
  /* Loaded from the layout on every page, including ones with no chart on
   * them and, under a test runner, with no document at all. Bail before
   * touching the DOM rather than throwing on load. */
  if (typeof document === 'undefined') return;
  var wf = document.getElementById('wf');
  if (!wf) return;

  var scale = 1, offset = 0;

  function apply() {
    if (scale < 1) { scale = 1; offset = 0; }
    /* Clamp so the trace cannot be dragged off the screen entirely - a pan
     * that loses the data is a pan the user cannot undo. */
    var min = -(scale - 1) * wf.clientWidth;
    if (offset < min) offset = min;
    if (offset > 0) offset = 0;
    wf.style.setProperty('--wf-scale', scale);
    wf.style.setProperty('--wf-offset', offset + 'px');
  }

  wf.addEventListener('wheel', function (e) {
    if (!e.ctrlKey && !e.metaKey) return;
    e.preventDefault();
    var rect = wf.getBoundingClientRect();
    var at = e.clientX - rect.left;
    var before = (at - offset) / scale;
    scale *= e.deltaY < 0 ? 1.15 : 1 / 1.15;
    if (scale > 200) scale = 200;
    offset = at - before * scale;
    apply();
  }, { passive: false });

  var dragging = false, startX = 0, startOffset = 0;
  wf.addEventListener('pointerdown', function (e) {
    dragging = true; startX = e.clientX; startOffset = offset;
    wf.setPointerCapture(e.pointerId);
  });
  wf.addEventListener('pointermove', function (e) {
    if (!dragging) return;
    offset = startOffset + (e.clientX - startX);
    apply();
  });
  wf.addEventListener('pointerup', function (e) {
    dragging = false;
    try { wf.releasePointerCapture(e.pointerId); } catch (x) {}
  });

  /* Subtree collapse: a class on the row, so the CSS does the hiding.
   *
   * BY IDENTITY, NOT BY ADJACENCY. Rows are emitted in (trace, start) order -
   * chronological - so a subtree's descendants are only next to each other
   * when nothing else was running. Walking forward while depth is greater
   * than the clicked row's stops at the first sibling that is not, which
   * hides a slice of whatever happened to be interleaved and leaves the rest
   * of the real subtree on screen.
   *
   * A row carries data-span and data-parent, so the descendants are the
   * transitive closure over those - wherever they sit in the list. */
  /* The attribute row under a span: hidden until its button is pressed. */
  function detailOf(id) {
    return wf.querySelector('li[data-detail="' + id + '"]');
  }
  function closeDetail(id) {
    var d = detailOf(id);
    if (!d) return;
    d.hidden = true;
    var b = wf.querySelector('button[data-more="' + id + '"]');
    if (b) b.setAttribute('aria-expanded', 'false');
  }

  wf.addEventListener('click', function (e) {
    var btn = e.target.closest ? e.target.closest('button[data-more]') : null;
    if (btn) {
      e.stopPropagation();
      var d = detailOf(btn.getAttribute('data-more'));
      if (!d) return;
      d.hidden = !d.hidden;
      btn.setAttribute('aria-expanded', d.hidden ? 'false' : 'true');
      return;
    }
    var li = e.target.closest ? e.target.closest('li') : null;
    if (!li || dragging) return;
    /* An attribute row is not a span and has no subtree. */
    if (!li.hasAttribute('data-span')) return;
    /* A row with no depth is in a cycle, or deeper than assembly would
     * follow. It has no subtree anyone can name, so it does not collapse. */
    if (+li.getAttribute('data-depth') < 0) return;

    var rows = wf.querySelectorAll('li[data-span]');
    var kids = {}, i, r, p;
    for (i = 0; i < rows.length; i++) {
      r = rows[i];
      p = r.getAttribute('data-parent');
      if (!p || p === '0') continue;
      (kids[p] || (kids[p] = [])).push(r);
    }

    var hide = !li.classList.contains('collapsed');
    li.classList.toggle('collapsed', hide);

    var stack = [ li.getAttribute('data-span') ], seen = {};
    while (stack.length) {
      var id = stack.pop();
      if (seen[id]) continue;          /* a cycle must not spin here */
      seen[id] = 1;
      var cs = kids[id] || [];
      for (i = 0; i < cs.length; i++) {
        cs[i].hidden = hide;
        /* Its attribute row goes with it, and comes back closed: an
         * expanded subtree should look as it did before the collapse,
         * not spring every statement open. */
        closeDetail(cs[i].getAttribute('data-span'));
        stack.push(cs[i].getAttribute('data-span'));
      }
    }
  });

  /* Errors only, as a class on the root rather than a filter over the rows. */
  var only = document.getElementById('errors-only');
  if (only) only.addEventListener('change', function () {
    wf.classList.toggle('errors-only', only.checked);
  });

  apply();
})();
