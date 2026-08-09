# Vendored Funky-Frame subset

Source: /Users/lnation/Semantic/Funky-Frame (npm `funky-frame`)
Version: 1.0.4
Commit:  39cdad36ef286631d6aba937f81fcea54b810f59 (v1.0.4, 2026-01-07)

Note: js/core/namespace.js in this version hardcodes `Funky.version =
'1.0.2'` while the dist is 1.0.4; the runtime report is expected to say
1.0.2. Pin by the commit above, not by `Funky.version`.

## Re-vendor procedure

1. Check out the pinned commit (or the new one being moved to) in the
   Funky-Frame repo.
2. Re-copy every file listed below, keeping the numeric order prefixes -
   the server concatenates in lexical order and the order IS the
   dependency order (namespace absolutely first, registry second,
   themes.css last of the framework css).
3. Re-verify the three wire contracts this UI leans on, which are
   Funky internals and may move: Funky.Table `_buildAjaxParams` /
   `_handleAjaxResponse` (request `draw/page/limit/search/sort`,
   response `{data, total}`), the csrf cookie name `csrf_token` +
   header `X-CSRF-Token` in js/core/api.js, and Funky.SPA's
   `#spaContent` + `data-page` contract.
4. Update version + commit here, run t/75-admin-assets.t (bundle
   completeness/order) and the t/7x suite.

## js/ (concatenated into funky.js, this order)

    01-namespace.js          core - MUST be first; creates + locks the registry
    02-registry.js           core - MUST precede any component using
                             createInstanceRegistry at module scope
                             (table, stats-bar)
    03-util.js
    04-dom.js
    05-events.js
    06-pubsub.js
    07-media-query.js        badge depends on it
    08-storage.js            filter-toolbar depends on it
    09-cache.js
    10-timing.js
    11-date.js
    12-keyboard.js
    13-announce.js
    14-live-binding.js
    15-csrf.js
    16-api.js
    17-history.js
    18-animate.js            toast depends on it
    19-modal.js
    20-navigation.js
    21-pages.js
    22-spa.js
    23-visibility-observer.js
    24-websocket.js
    25-formatting.js         stats-bar hard-requires Funky.Format
    26-action-registry.js    bulk-actions calls ActionRegistry.create
                             unconditionally in its constructor
    27-toast.js
    28-spinner.js
    29-skeleton.js
    30-empty-state.js
    31-badge.js
    32-charts.js             pure inline SVG - the no-chart-library rule
                             survives
    33-relative-time.js
    34-stats-bar.js
    35-table.js
    36-bulk-actions.js
    37-filter-toolbar.js

## css/ (concatenated into funky.css, this order; punk-queue.css is
## appended after by the server as the override layer)

    01-dom.css
    02-layout.css
    03-buttons.css
    04-cards.css
    05-forms.css
    06-tables.css            Funky.Table's own skin (datatables-funky.css
                             is the legacy jQuery skin - NOT vendored)
    07-stats.css             also carries the Charts sparkline classes
    08-modals.css
    09-toasts.css
    10-empty-state.css
    11-skeleton.css
    12-spinner.css
    13-badge.css
    14-relative-time.css
    15-filters.css
    16-spa.css
    17-animate.css
    18-themes.css            MUST be last of the framework css (defines
                             the --pro-* tokens and [data-theme])

## Icon-font and Bootstrap checkpoint (per the plan: vendor NEITHER)

FontAwesome: NOT vendored. Components that emit `fas fa-*` markup -
toast, modal (alert/confirm), empty-state, stats-bar, bulk-actions,
table (search/clear/columns/export icons), dom (actionButton/alert) -
are covered by punk-queue.css, which neutralises `i.fas` into a plain
inline element and supplies unicode glyphs via ::before for the classes
this UI actually renders. Clean components needing nothing: charts,
relative-time, skeleton, spinner, badge.

Bootstrap: NOT vendored. Funky's modal/toast/bulk-actions emit
Bootstrap STRUCTURAL class names (modal-dialog, toast-container, btn,
btn-close, d-flex, me-2, visually-hidden...); punk-queue.css provides a
minimal implementation of exactly the classes this UI renders, themed
with the --pro-* tokens so light/dark follow themes.css. No --bs-*
variable is consumed by any vendored css file (themes.css only DEFINES
--bs-* bridges, outbound).

## Behavioural facts that shaped app.js

- serverSide requires `ajax: {url}`; `ajaxUrl` silently downgrades to
  client-side paging. Selection hardcodes `row.id`.
- `Pages.handleDataChange` has no caller inside Funky - the ws entity
  bridge in app.js is ours.
- `onRowClick` fires ONLY from keyboard activation (Enter on a focused
  row). A mouse click on a selectable table goes to _handleClick ->
  _handleRowClick, which does selection and nothing else - so a
  clickable row needs a real `a[href]` in the row, rendered with a
  `data-action` attribute (which _handleClick excludes from selection).
  The jobs table's ID link is the example.
- Do NOT add your own click listener to such a link:
  SPA.bindNavigation already intercepts every same-origin `a[href]` at
  the document, and a second navigate() races it - the two URL
  spellings (href attribute vs link.href property) slip loadPage's
  string-compare concurrent-load guard, and the doubled showLoading
  overwrites SPA.loadingTimeout, orphaning a 300ms spinner timer that
  no hideLoading ever clears: a stuck "Loading..." overlay on a page
  that actually loaded. Links that SPA refuses (href="#") are the ones
  that need their own delegated handler - the overview breakdown
  names are that case.

## Not vendored, deliberately

- js/components/table.js drags no extra files, but is 370KB unminified
  and all-or-nothing; accepted.
- datatables-funky.css (legacy jQuery DataTables skin; the few
  .bulk-actions rules it carried are reproduced in punk-queue.css).
- vendor/bootstrap, vendor/fontawesome, fonts/, icons/ (see checkpoint).
- js/core/tabs.js, popover, tooltip, forms machinery, pwa/*, sw/*,
  dev/* - nothing in these pages initialises them.
