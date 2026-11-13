import hljs from './languages.js';
import {
    escapeHtml, highlightLines, sizeClass, orderFiles, inRanges, emptyState, encodeCommit,
    encodeState, decodeState, unifiedRows, splitRows, textBlocks, inlineCode, sameSection,
    commitTree, subtree, stepChanges, mergePath, firstLine, flagSide, webUrl, isSvg, identityLine, staleReview,
    commitPanels, filePanels, shownPanel, panelSlot, needsSplit, fileLabel, renameBadge, renameFact, entryLabel, journalPlan,
} from './logic.js';
// These modules import from this one. None of them uses its imports while
// loading, so the cycle is safe.
import {
    notesSlot, formSlot, feedbackButton, requestButton, placeLineFeedback, lineClick, downloadFeedback, closeReview, holdForms,
    syncCommentBadges,
} from './feedback.js';
import { flagBadge, cardFlagList, decorateFlags, flagClick, flagList, showFlagFocus, syncWalkButtons } from './flags.js';
import { setupGuide, showGuide, playGuide, applyHighlights } from './guide.js';
import { setupSpeech, speakControls } from './speech.js';

// Per-browser conveniences. Storage can be unavailable (private mode, blocked
// site data); the page must still work, so failures fall back to defaults.
export const pref = {
    get(key, dflt) {
        try { return localStorage.getItem('review-helper.' + key) ?? dflt }
        catch { return dflt }
    },
    set(key, val) {
        try { localStorage.setItem('review-helper.' + key, val) }
        catch { /* not remembered */ }
    },
};

// The review this tab showed, kept for the tab's life (sessionStorage) to
// notice a server now serving another review on the same port.
const tabReview = {
    get() {
        try { return sessionStorage.getItem('review-helper.review') }
        catch { return null }
    },
    set(r) {
        try { sessionStorage.setItem('review-helper.review', JSON.stringify({ id: r.id, title: r.title })) }
        catch { /* not checked */ }
    },
};

export let review = null;
// logic.js's commitTree of the loaded review.
export let tree = null;
export let loadedIt;
export let state = emptyState();
let diffMode = pref.get('diff', 'unified');
let orderMode = pref.get('order', 'reading');
let currentNode = 'summary';
let observer = null;
// Sections in the band the observer watches, and the section last navigated
// to. A short last section cannot scroll to the top, so the one above it
// stays in the band; the navigated one wins while it is there.
const visible = new Set();
let pinned = null;
let pendingReveal = null;
let held = null;
// The applies waiting to place the page again once fills land, and the
// page's own last placement ({ hold, y }): a scroll since is the reader's.
let placing = 0;
let placed = null;
// Every panel or docs fill still in flight, by its box, whoever drew it (an
// earlier apply, a redraw on a toggle). Drawing shows each panel as
// "Loading…" until its fill lands, even from the cache, so apply() places
// the page again once those that can move its target have.
const inflight = new Map();
const rendered = {};
export const fileIndex = new Map();
export const fileData = new Map();
const cache = new Map();

export const $ = id => document.getElementById(id);

// ---- data ----

export async function getJSON(url) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`${url}: ${res.status} ${res.statusText}`);
    return res.json();
}

function cached(key, make) {
    if (!cache.has(key)) cache.set(key, make());
    return cache.get(key);
}

function contentUrl(revision, path) {
    return `api/content/${revision}/${path.split('/').map(encodeURIComponent).join('/')}`;
}

// Highlighted lines of a whole file at a commit, or null when it has none.
function contentLines(revision, path, kind) {
    return cached(`content:${revision}:${path}`, async () => {
        const res = await fetch(contentUrl(revision, path));
        if (res.status === 404) return null;
        if (!res.ok) throw new Error(`${path}: ${res.status} ${res.statusText}`);
        return highlightLines(hljs, await res.text(), kind);
    });
}

function oldLines(f) {
    const c = fileIndex.get(f.id).commit;
    return f.status === 'A' || !c.parent ? Promise.resolve(null) : contentLines(c.parent, f.old_path || f.path, f.kind);
}

function newLines(f) {
    const c = fileIndex.get(f.id).commit;
    return f.status === 'D' ? Promise.resolve(null) : contentLines(c.revision, f.path, f.kind);
}

export function loadFile(id) {
    return cached(`file:${id}`, async () => {
        const data = await getJSON(`api/file/${id}`);
        fileData.set(Number(id), data);
        return data;
    });
}

export function loadDiff(fid, sid) {
    return cached(`diff:${fid}:${sid ?? ''}`, () => getJSON(`api/diff/${fid}` + (sid ? `?section=${sid}` : '')));
}

async function loadReview(it) {
    review = await getJSON('api/review' + (it != null ? `?iteration=${it}` : ''));
    loadedIt = it;
    tree = commitTree(review.commits);
    fileIndex.clear();
    for (const c of review.commits) for (const f of c.files) fileIndex.set(f.id, { file: f, commit: c });
    for (const k of Object.keys(rendered)) delete rendered[k];
    checkTab();
    renderHeader();
    renderSummary();
    renderJournal();
    $('commits').replaceChildren(...tree.mainline.map(c => el('section', { class: 'commit', id: 'c' + c.id })));
    observeSections();
}

// Warn when this tab showed another review: the port may now be another
// server's. Accepting starts this review from the top.
function checkTab() {
    const stale = staleReview(tabReview.get(), review.review);
    $('stale').hidden = !stale;
    if (stale) $('stale_text').textContent = stale.text;
    else tabReview.set(review.review);
}

function acceptReview() {
    tabReview.set(review.review);
    $('stale').hidden = true;
    history.pushState(null, '', location.pathname);
    apply();
}

// ---- DOM helpers ----

export function el(tag, attrs, ...kids) {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
        if (v == null || v === false) continue;
        if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
        else if (k === 'html') node.innerHTML = v;
        else node.setAttribute(k, v === true ? '' : v);
    }
    for (const kid of kids.flat()) if (kid != null && kid !== false) node.append(kid);
    return node;
}

export function inline(text) {
    return inlineCode(text).map(p => (p.code ? el('code', {}, p.text) : p.text));
}

export function prose(text, missing, cls) {
    if (text == null || text === '') return el('p', { class: 'missing' }, missing);
    return el('div', { class: cls ? `prose ${cls}` : 'prose' }, textBlocks(text).map(b =>
        b.type === 'p' ? el('p', {}, inline(b.text)) : el('ul', {}, b.items.map(i => el('li', {}, inline(i))))));
}

// Agent prose under its heading, with buttons beside the heading (not in
// it, so the heading reads as just its name) to read it aloud.
function proseBlock(heading, text) {
    return [el('div', { class: 'prose-head' }, el('h3', {}, heading), speakControls(text)), prose(text, 'Not written yet.')];
}

function facts(pairs) {
    const dl = el('dl', { class: 'facts' });
    for (const [k, v] of pairs) if (v != null && v !== '') dl.append(el('dt', {}, k), el('dd', {}, v));
    return dl;
}

function counts(x) {
    return el('span', { class: 'counts', title: 'lines added / removed / changed' },
        el('span', { class: 'n-add' }, '+' + x.added), ' ',
        el('span', { class: 'n-del' }, '−' + x.removed), ' ',
        el('span', { class: 'n-chg' }, '~' + x.changed));
}

export function showError(err) {
    console.error(err);
    const box = $('error');
    box.hidden = false;
    box.textContent = String(err.message || err);
}

// ---- view state ----

function cstate(s, cid) {
    return (s.commits[cid] ??= { panel: '', commits: {}, files: {} });
}

// Open the merges a commit sits in, down to it.
function openPath(s, c) {
    let child = c;
    for (const m of mergePath(tree, c).reverse()) {
        const ms = cstate(s, m.id);
        ms.panel = '';
        ms.commits[child.id] = true;
        child = m;
    }
}

function dropBelow(s, c) {
    for (const k of subtree(tree, c).slice(1)) delete s.commits[k.id];
}

function isMerge(c) {
    return tree.kids.has(c.id);
}

// The panels a commit's or a file's tabs show (commitPanels, filePanels).
function tabsOf(item) {
    return item.type === 'commit' ? commitPanels(item.commit, isMerge(item.commit)) : filePanels(item.file);
}

// The panel of an item shown as a card (a commit's or file's slot resolved
// to the tab it shows, shownPanel), or undefined when the item is a
// collapsed row.
function panelOf(item) {
    const cs = state.commits[item.commit.id];
    const c = item.commit;
    if (item.type === 'commit') return mergePath(tree, c).length && !state.commits[c.merge_id]?.commits[c.id] ? undefined : shownPanel(tabsOf(item), cs?.panel ?? '');
    const fs = cs?.files[item.file.id];
    if (item.type === 'file') return fs && shownPanel(tabsOf(item), fs.panel);
    return fs?.sections[item.section.id];
}

// reveal ({ sel, side, line }) names a line to scroll to once a panel's line
// table matching sel shows it; hold ({ id, top }) an element to keep where it
// is on screen instead of scrolling to at. replace changes the current history
// entry instead of adding one.
export function go(mutate, at, reveal, hold, replace = false) {
    pendingReveal = reveal || null;
    held = hold || null;
    const next = decodeState(encodeState(state));
    mutate(next);
    next.at = at;
    const hash = '#' + encodeState(next);
    if (hash === location.hash) apply();
    else if (replace) {
        history.replaceState(history.state, '', hash);
        apply();
    }
    else location.hash = hash;
}

// Opening a commit collapses anything under it, but opening its panel keeps
// its files' state, hidden under the panel. Opening a file keeps the sections
// it has expanded and the commit's other files, and switches the commit to
// its list tab; opening a section switches its file to its list tab too.
// Panel undefined keeps the panel the item already shows, and a
// section newly expanded shows its diff. `also` changes the state first (the
// guide step, and undoing what the step left changed); a function it returns
// is called with the state once the item is open. `reveal` and `hold` are
// passed to go().
export function open(item, panel, also, reveal, hold) {
    const cid = item.commit.id;
    const fid = item.file?.id;
    const sid = item.section?.id;
    const mutate = s => {
        openPath(s, item.commit);
        if (item.type === 'commit') {
            dropBelow(s, item.commit);
            const next = panelSlot(tabsOf(item), panel ?? panelOf(item) ?? '');
            s.commits[cid] = { panel: next, commits: {}, files: next ? s.commits[cid]?.files ?? {} : {} };
            return;
        }
        const cs = cstate(s, cid);
        if (item.type === 'blob') {
            cs.view = item.path;
            return;
        }
        // The commit's diff tab stands in for its files; a target among them
        // switches the commit to its list tab.
        cs.panel = '';
        if (item.type === 'file') {
            cs.files[fid] = { panel: panelSlot(tabsOf(item), panel ?? panelOf(item) ?? ''), sections: cs.files[fid]?.sections ?? {} };
            return;
        }
        const fs = (cs.files[fid] ??= { panel: '', sections: {} });
        fs.panel = '';
        fs.sections[sid] = panel ?? panelOf(item) ?? 'd';
    };
    const at = { commit: 'c' + cid, blob: 'b' + cid, file: 'f' + fid, section: 's' + sid }[item.type];
    go(s => {
        const done = also?.(s);
        mutate(s);
        done?.(s);
    }, at, reveal, hold);
}

// Show a plan from logic.js's stepPlan or flagPlan; g sets the guide step,
// and first changes the state before the plan opens. A step records in u
// what it changed, for leaving it to undo. A guide step's section the page
// does not show (a later re-split took it away or left it untouched) gives
// false: its target is missing.
export async function navigate(plan, g, first) {
    const also = s => {
        first?.(s);
        if (g === undefined) return null;
        s.g = g;
        const before = decodeState(encodeState(s));
        return after => { after.u = stepChanges(before, after) };
    };
    if (plan.type === 'summary') return go(also, 'summary');
    const item = { type: plan.type, commit: plan.commit, file: plan.file, path: plan.path };
    if (plan.section) {
        const data = await loadFile(plan.file.id);
        item.section = data.sections.find(s => sameSection(s, plan.section));
        if (!item.section && g !== undefined) return false;
        if (!item.section) throw new Error(`No section ${plan.section.name} in ${plan.file.path}`);
    }
    const r = plan.reveal;
    const f = r && plan.commit.files.find(x => x.path === r.path);
    const sel = f ? panelSel(plan.panel, f, item.section) : r && plan.type === 'blob' ? blobSel(plan.commit.revision, r.path) : null;
    open(item, plan.panel, also, sel && { sel, side: r.side, line: r.line });
}

// The line table of the panel a plan opens, so the reveal skips the other
// tables of the same file: an expanded section's diff, or the file's.
function panelSel(panel, f, section) {
    const fid = `[data-fid="${f.id}"]`;
    if (panel === 'v') return 'table.code-view' + fid;
    return 'table.diff' + fid + (section ? `[data-sid="${section.id}"]` : ':not([data-sid])');
}

function blobSel(revision, path) {
    return `table[data-revision="${revision}"][data-path="${CSS.escape(path)}"]`;
}

// Scroll to the pending reveal line if a panel shows it.
function tryReveal() {
    if (!pendingReveal) return;
    const { sel, side, line } = pendingReveal;
    for (const t of $('main').querySelectorAll('.panel ' + sel)) {
        const row = t.querySelector(`tr[data-${side}="${line}"]`);
        if (!row) continue;
        pendingReveal = null;
        row.scrollIntoView({ block: 'center' });
        return;
    }
}

// Closing a whole-file view from its head puts the commit's card where
// that head was.
function closeView(item) {
    const cid = item.commit.id;
    const was = holdOf(item);
    go(s => { delete cstate(s, cid).view }, 'c' + cid, null, was && { ...was, id: 'c' + cid });
}

// An item's card, or its element when it has none (a collapsed row); its
// header sits at its top when in flow.
function inFlow(node) {
    return node.matches('.card') ? node : node.querySelector(':scope > .card') ?? node;
}

// The id of an item's element.
function idOf(item) {
    return { review: 'summary', commit: 'c' + item.commit?.id, blob: 'b' + item.commit?.id, file: 'f' + item.file?.id, section: 's' + item.section?.id }[item.type];
}

// Where an item's header is on screen, to keep it there after a click
// redraws the item, or null when the item is off screen: its top, and where
// it sticks. A header stuck over its card scrolled above stays where it is
// stuck, its card's content starting under it again; one its card's end
// pushes up from there holds where it sticks if its card then reaches past
// it, and where it is if not (a collapsed row, or a card left short).
function holdOf(item) {
    const id = idOf(item);
    const node = $(id);
    const r = node?.getBoundingClientRect();
    if (!r || r.bottom <= 0 || r.top >= innerHeight) return null;
    const box = inFlow(node);
    const head = box.querySelector(':scope > .head') ?? box;
    const sticks = parseFloat(getComputedStyle(head).top);
    return { id, top: head.getBoundingClientRect().top, sticks: Number.isNaN(sticks) ? -Infinity : sticks };
}

// Scroll so the item hold names has its header where hold says. The page's
// own scroll is recorded, so a page still waiting to place itself does not
// take it for the reader's. The top of the page can stop the scroll short.
function placeAt(hold) {
    const box = inFlow($(hold.id));
    const head = box.querySelector(':scope > .head') ?? box;
    // A head pushed up from where it sticks: its card now reaching past
    // there, it sticks there; else its card's end keeps it where it was. A
    // sticky head stops short of its card's end by the card's bottom padding
    // and border and its own bottom margin.
    const pushed = hold.top < hold.sticks;
    const css = n => getComputedStyle(n);
    const gap = box === head ? 0 : parseFloat(css(box).paddingBottom) + parseFloat(css(box).borderBottomWidth) + parseFloat(css(head).marginBottom);
    const reaches = box.offsetHeight - gap - head.offsetHeight >= hold.sticks - hold.top;
    const r = box.getBoundingClientRect();
    const y = scrollY + (!pushed ? r.top - hold.top : reaches ? r.top - hold.sticks : r.bottom - gap - head.offsetHeight - hold.top);
    const room = $('room');
    room.style.height = Math.max(0, Math.ceil(room.offsetHeight + y + innerHeight - document.documentElement.scrollHeight)) + 'px';
    window.scrollTo(0, y);
    placed = { hold, y: scrollY };
}

// Change what an item shows in place, its header staying where it is.
export function keepHead(item, change) {
    const hold = holdOf(item);
    change();
    if (hold && $(hold.id)) placeAt(hold);
}

// Bring an item's header, with what opens under it, into view below the
// headers stuck over it, as going to the item does; nothing moves when both
// already show there.
export function showHead(item, under) {
    const node = $(idOf(item));
    const below = parseFloat(getComputedStyle(node).scrollMarginTop) || 0;
    if (inFlow(node).getBoundingClientRect().top >= below - 1 && under.getBoundingClientRect().bottom <= innerHeight) return;
    $('room').style.height = '0px';
    node.scrollIntoView({ block: 'start' });
}

// Room grown under the page so a header held near its end need not drop
// (placeAt sizes it), cut back to what still shows as the reader scrolls up.
function trimRoom() {
    const room = $('room');
    const shown = Math.ceil(innerHeight - room.getBoundingClientRect().top);
    if (room.offsetHeight > shown) room.style.height = Math.max(0, shown) + 'px';
}

// Draw box now and fill it by promise p, which never rejects.
function track(box, p) {
    inflight.set(p, box);
    p.finally(() => inflight.delete(p));
}

// The fills in flight that can still move target: those of boxes still drawn
// above it and, when inside counts (a target to show, not a header to hold),
// in it. No target waits on every one still drawn.
function movers(target, inside) {
    const ahead = box => {
        const at = box.compareDocumentPosition(target);
        return (at & Node.DOCUMENT_POSITION_FOLLOWING && !(at & Node.DOCUMENT_POSITION_CONTAINED_BY)) || (inside && target.contains(box));
    };
    return [...inflight].filter(([, box]) => box.isConnected && (!target || ahead(box))).map(([p]) => p);
}

// Node once its pictures have their size, so a panel does not grow after
// its fill lands.
async function pictured(node) {
    const imgs = node.matches('img') ? [node] : [...node.querySelectorAll('img')];
    await Promise.all(imgs.map(i => i.decode().catch(() => {})));
    return node;
}

// A panel opens in place: when the item is on screen, the page holds still.
function togglePanel(item, panel) {
    open(item, panelOf(item) === panel ? '' : panel, null, null, holdOf(item));
}

// A commit's or file's tab shows in place too, keeping what is expanded
// under it.
function showTab(item, panel) {
    if (panelOf(item) === panel) return;
    if (item.type === 'file') return open(item, panel, null, null, holdOf(item));
    go(s => {
        openPath(s, item.commit);
        cstate(s, item.commit.id).panel = panelSlot(tabsOf(item), panel);
    }, 'c' + item.commit.id, null, holdOf(item));
}

// A merged-in commit's, file's or section's row expands and collapses in
// place, collapsed from its head stuck over a card scrolled above too.
// Collapsing a commit drops everything under it.
function toggleRow(item) {
    const hold = holdOf(item);
    if (panelOf(item) === undefined) return open(item, undefined, null, null, hold);
    const c = item.commit;
    if (item.type === 'commit') {
        return go(s => {
            delete cstate(s, c.merge_id).commits[c.id];
            for (const k of subtree(tree, c)) delete s.commits[k.id];
        }, 'c' + c.id, null, hold);
    }
    const fid = item.file.id;
    if (item.type === 'file') return go(s => { delete cstate(s, item.commit.id).files[fid] }, 'f' + fid, null, hold);
    go(s => { delete cstate(s, item.commit.id).files[fid].sections[item.section.id] }, 's' + item.section.id, null, hold);
}

// Drop anything in the URL that does not belong to the loaded iteration.
function sanitize(s) {
    for (const cid of Object.keys(s.commits)) {
        if (!review.commits.some(c => String(c.id) === cid)) {
            delete s.commits[cid];
            continue;
        }
        const kids = tree.kids.get(Number(cid)) || [];
        for (const k of Object.keys(s.commits[cid].commits)) {
            if (!kids.some(x => String(x.id) === k)) delete s.commits[cid].commits[k];
        }
        // A panel the commit or file has no tab for shows its default tab,
        // and so does its slot written as that tab.
        for (const [fid, fs] of Object.entries(s.commits[cid].files)) {
            const x = fileIndex.get(Number(fid));
            if (String(x?.commit.id) !== cid) delete s.commits[cid].files[fid];
            else fs.panel = panelSlot(tabsOf({ type: 'file', file: x.file }), fs.panel);
        }
        s.commits[cid].panel = panelSlot(tabsOf({ type: 'commit', commit: tree.byId.get(Number(cid)) }), s.commits[cid].panel);
    }
}

let applySeq = 0;

async function apply() {
    const seq = ++applySeq;
    try {
        const next = decodeState(location.hash);
        if (!review || next.it !== loadedIt) await loadReview(next.it);
        if (seq !== applySeq) return;
        sanitize(next);
        const fids = Object.values(next.commits).flatMap(cs => Object.keys(cs.files));
        await Promise.all(fids.map(loadFile));
        if (seq !== applySeq) return;
        state = next;
        // A toggle or tab redrawn under the keyboard focus takes it back.
        const focused = document.activeElement?.matches('.toggle, .tabs button') ? document.activeElement : null;
        const focusId = focused?.closest('[id]')?.id;
        const focusSel = focused?.matches('.tabs button') ? `.tabs button[data-panel="${focused.dataset.panel}"]` : '.toggle';
        for (const c of tree.mainline) {
            if (rendered[c.id]?.spec !== sectionSpec(c) && !redrawFiles(c)) renderCommit(c);
        }
        renderTree();
        syncCommentBadges();
        if (focusId && !focused.isConnected) $(focusId)?.querySelector(focusSel)?.focus({ preventScroll: true });
        // A reveal places the page itself, once its line shows.
        const hold = held;
        const reveal = pendingReveal;
        let at = reveal ? null : state.at;
        held = null;
        const place = () => {
            if (hold && $(hold.id)) placeAt(hold);
            else if (at && $(at)) {
                $('room').style.height = '0px';
                $(at).scrollIntoView({ block: 'start' });
            }
        };
        place();
        placed = { hold: hold && $(hold.id) ? hold : null, y: scrollY };
        // While the page waits to place itself again, the browser does not
        // anchor the scroll to what is on screen, so a scroll means the reader
        // scrolled. A header kept since by a click is placed instead, and the
        // page does not then go on to a flag jumped to.
        const wait = movers(hold ? $(hold.id) : state.at && $(state.at), !hold);
        if (wait.length && !placing++) $('main').classList.add('placing');
        Promise.all(wait).finally(() => {
            if (wait.length && !--placing) $('main').classList.remove('placing');
        }).then(() => {
            if (seq !== applySeq) return;
            const still = scrollY === placed.y;
            const kept = placed.hold !== hold && placed.hold;
            // A line no panel shows (outside the diff's hunks) never
            // reveals; the page goes to the target instead.
            if (reveal && pendingReveal === reveal) {
                pendingReveal = null;
                at = state.at;
                place();
            }
            // Unless the reader has scrolled meanwhile.
            else if (still && kept) {
                if ($(kept.id)) placeAt(kept);
            }
            else if (still) place();
            showFlagFocus(true, still && !kept);
        }).catch(showError);
        pinned = (state.at && $(state.at)?.closest('section.commit, #summary')?.id) || null;
        if (visible.has(pinned) && pinned !== currentNode) {
            currentNode = pinned;
            markCurrent();
        }
        showGuide();
        tryReveal();
    }
    catch (err) {
        showError(err);
    }
}

function rerenderAll() {
    for (const k of Object.keys(rendered)) delete rendered[k];
    for (const c of tree.mainline) renderCommit(c);
    renderTree();
    syncCommentBadges();
}

// ---- widgets ----

// Each maker returns a widget element for an item, or null.
export const widgetMakers = [
    // A commit or file picks its panel from its tabs (tabsBar).
    item => (item.type === 'section' ? panelButton(item, 'd', 'diff', 'Show the diff') : null),
    item => (item.type === 'section' ? panelButton(item, 'v', 'file', 'View the whole file after this commit') : null),
    feedbackButton,
    requestButton,
];

export function widgetBar(item) {
    return el('span', { class: 'widgets' }, widgetMakers.map(make => make(item)));
}

function panelButton(item, panel, label, title) {
    return el('button', {
        class: 'tool' + (panelOf(item) === panel ? ' active' : ''),
        title,
        'aria-pressed': String(panelOf(item) === panel),
        onclick: e => {
            e.stopPropagation();
            togglePanel(item, panel);
        },
    }, label);
}

// A commit's or file's tabs (tabsOf). A commit's: list (its files, or a
// merge's commits, as rows), diff (the whole commit's diff) and, for a merge
// that resolved conflicts, resolution. A file's: list (its sections), diff
// and file (the whole file after the commit). Each other tab shows its panel
// in place of the list; an item with nothing to list has no list tab and
// opens on its first other tab. Fewer than two choices show no tabs at all.
// One choice of a few, so a radio group, the tab shown checked.
const TABS = {
    d: ['diff', 'Show the whole diff'],
    r: ['resolution', 'Show how the merge resolved its conflicts'],
    v: ['file', 'View the whole file after this commit'],
};

function listTitle(item) {
    if (item.type === 'file') return 'Show the sections';
    return isMerge(item.commit) ? 'Show the commits it brought in' : 'Show the files';
}

function tabsBar(item) {
    const panels = tabsOf(item);
    if (panels.length < 2) return null;
    const shown = panelOf(item);
    const tab = panel => {
        const [label, title] = panel ? TABS[panel] : ['list', listTitle(item)];
        return el('button', {
            class: shown === panel ? 'active' : null,
            title,
            role: 'radio',
            'aria-checked': String(shown === panel),
            tabindex: shown === panel ? '0' : '-1',
            'data-panel': panel,
            onclick: e => {
                e.stopPropagation();
                showTab(item, panel);
            },
        }, label);
    };
    return el('span', { class: 'switch tabs', role: 'radiogroup', 'aria-label': 'Show', onkeydown: radioKeys }, panels.map(tab));
}

// Arrow keys move a radio group's choice to the next or previous radio.
function radioKeys(e) {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    const radios = [...e.currentTarget.querySelectorAll('[role=radio]')];
    const at = radios.indexOf(document.activeElement);
    if (!step || at < 0) return;
    e.preventDefault();
    e.stopPropagation();
    const next = radios[(at + step + radios.length) % radios.length];
    next.focus();
    next.click();
}

function resolvedBadge(c) {
    return c.resolution ? el('span', { class: 'resolved', title: 'This merge resolved conflicts' }, 'resolved conflicts') : null;
}

// A head or row that a click anywhere but on its widgets and flags toggles.
// Its toggle button carries the keyboard focus and aria-expanded.
function clickable(attrs, onclick, ...kids) {
    return el('div', {
        ...attrs,
        onclick: e => {
            // A mouse drag selecting text in it (a section row's counts;
            // the path is a button label, which browsers do not
            // drag-select) is not a toggle. A keyboard click (detail 0)
            // always toggles, whatever selection is left over.
            const sel = getSelection();
            if (e.detail !== 0 && !sel.isCollapsed && e.currentTarget.contains(sel.anchorNode)) return;
            if (!e.target.closest('.widgets, .tabs, .flag-icon, a, input, textarea, select')) onclick();
        },
    }, ...kids);
}

function toggleButton(label, expanded, cls, title) {
    return el('button', { class: 'link toggle' + (cls ? ' ' + cls : ''), title, 'aria-expanded': String(expanded) },
        expanded ? '▾ ' : '▸ ', label);
}

// One level of the page, whatever its kind (commit, merge, file, section,
// blob, which sets its color): closed, a one-line row; open, a card whose
// head carries the same title and parts, then its tabs and widgets, with
// the item's form slot and its body under it. The title is a heading of
// tag, or a span; rowParts show only in the row. onToggle, when given,
// opens the row and closes the card from its head; a mainline commit has
// none and is always open.
function levelNode({ kind, cls, id, open, label, tip = label, labelCls, tag = 'span', parts = [], rowParts = [], tabs, item, onToggle, body = [] }) {
    const title = el(tag, { class: 'title', title: tip }, onToggle ? toggleButton(label, open, labelCls, tip) : label);
    const attrs = { class: 'level' + (cls ? ' ' + cls : '') + (open ? ' card' : ''), id, 'data-kind': kind };
    if (!open) return el('div', attrs, clickable({ class: 'row' }, onToggle, title, parts, rowParts));
    const row = el('div', { class: 'row' }, title, parts);
    const widgets = item && kind !== 'blob' ? widgetBar(item) : null;
    const head = onToggle ? clickable({ class: 'head collapsible' }, onToggle, row, tabs, widgets) : el('div', { class: 'head' }, row, tabs, widgets);
    return el('div', attrs, head, widgets ? formSlot(item) : null, ...body);
}

// ---- header and summary ----

export function renderHeader() {
    const title = review.review.title || 'Review';
    const closed = review.review.state === 'closed';
    $('title').textContent = title + (closed ? ' (closed)' : '');
    const who = identityLine(review.identity);
    $('identity').hidden = !who;
    $('identity').textContent = who ?? '';
    $('identity').title = [who, review.identity?.reviewer && `reviewing as ${review.identity.reviewer}`].filter(Boolean).join('\n');
    document.title = title + ' - Review Helper';
    const source = webUrl(review.review.source);
    $('source').hidden = !source;
    if (source) $('source').href = source;
    $('close_review').hidden = closed;
    $('guide_play').hidden = !review.guide?.length;
    syncWalkButtons();

    const its = review.iterations;
    $('iteration_wrap').hidden = its.length < 2;
    $('iteration').replaceChildren(...its.map(i => el('option', {
        value: i.number,
        selected: i.number === review.iteration,
        disabled: i.available === false,
    }, `${i.number}${i.available === false ? ' (pruned)' : ''}`)));

    const pending = review.commits.some(c => c.files.length && !c.order_set);
    $('order_toggle').title = pending ? 'File order (reading order still pending for some commits)' : 'File order';
    syncSwitch('order_toggle', orderMode);
    syncSwitch('diff_toggle', diffMode);
    // Now, not at the resize observer's next call: a scroll to a target may
    // come first, and would land under a header that just grew.
    syncHeaderHeight();
}

function syncSwitch(id, value) {
    for (const b of $(id).querySelectorAll('button')) {
        b.classList.toggle('active', b.dataset.value === value);
        if (b.getAttribute('role') !== 'radio') continue;
        b.setAttribute('aria-checked', String(b.dataset.value === value));
        b.tabIndex = b.dataset.value === value ? 0 : -1;
    }
}

function renderSummary() {
    const it = review.iterations.find(i => i.number === review.iteration);
    const s = review.summary || {};
    const item = { type: 'review' };
    // replaceChildren would show a null as the text "null".
    $('summary').replaceChildren(...[
        el('div', { class: 'head' }, el('h2', {}, 'Summary'),
            el('span', { class: 'widgets' },
                feedbackButton(item),
                el('button', { class: 'tool', title: 'Save all feedback and requests as a JSON file', onclick: () => downloadFeedback().catch(showError) }, 'download feedback'))),
        formSlot(item),
        it?.note ? el('div', { class: 'speak-row' }, speakControls(it.note)) : null,
        it?.note ? prose(it.note, null, 'note') : null,
        ...proseBlock('What', s.what),
        ...proseBlock('Why', s.why),
        ...proseBlock('How', s.how),
        flagList(),
        notesSlot(item),
    ].filter(x => x != null));
}

// The iteration's journal, last on the page: what the agent noted for the
// reviewer's information. Each entry opens to its details; a closed one
// drops them, so a reading of it pauses as a collapsed card's does.
function renderJournal() {
    const entries = review.journal ?? [];
    $('journal').hidden = !entries.length;
    $('journal').replaceChildren(...(entries.length ? [
        el('div', { class: 'head' }, el('h2', {}, 'Journal')),
        el('p', { class: 'meta' }, 'For your information: what the agent noted while working that probably needs no attention. The flags are what to check.'),
        el('ul', { class: 'journal-list' }, entries.map(journalEntry)),
    ] : []));
}

function journalEntry(e) {
    const plan = journalPlan(e, review);
    const body = () => [
        el('p', { class: 'meta' }, e.kind, ' · ',
            plan ? el('button', { class: 'link', title: 'Show the file', onclick: () => navigate(plan).catch(showError) }, e.path) : e.path,
            e.unit ? ` · ${e.unit}` : null,
            ' ', speakControls([e.sentence, e.detail].filter(Boolean).join('\n\n'))),
        e.detail ? prose(e.detail) : null,
    ].filter(Boolean);
    const box = el('details', { ontoggle: () => box.replaceChildren(box.firstChild, ...(box.open ? body() : [])) }, el('summary', {}, e.sentence));
    return el('li', { 'data-journal': e.id }, box);
}

// ---- commit sections ----

function orderedFiles(c) {
    return orderFiles(c.files, orderMode, c.order_set);
}

// A commit labelled as entryLabel says, among this iteration's commits.
function commitLabel(c) {
    return entryLabel(c, review.commits);
}

// Everything a mainline section shows, to tell when it must be redrawn.
function sectionSpec(c) {
    return subtree(tree, c).map(x => encodeCommit(state.commits[x.id])).join('|');
}

function renderCommit(c) {
    holdForms($('c' + c.id));
    $('c' + c.id).replaceChildren(commitView(c));
    rendered[c.id] = { spec: sectionSpec(c), parts: drawnParts(c) };
}

// Each commit's state under a mainline section, split into the files' and
// the rest, to tell when only some files changed.
function drawnParts(c) {
    return new Map(subtree(tree, c).map(x => {
        const cs = state.commits[x.id];
        const files = new Map(Object.entries(cs?.files ?? {}).map(([fid, fs]) => [fid, encodeCommit({ files: { [fid]: fs } })]));
        return [x.id, { rest: encodeCommit(cs && { ...cs, files: {} }), files }];
    }));
}

// Redraw only the files whose state changed, when nothing else did, so the
// commit's other expanded files keep their filled panels. False when the
// whole section must be drawn.
function redrawFiles(c) {
    const was = rendered[c.id]?.parts;
    if (!was) return false;
    const now = drawnParts(c);
    const changed = [];
    for (const [cid, part] of now) {
        const old = was.get(cid);
        if (!old || old.rest !== part.rest) return false;
        for (const fid of new Set([...old.files.keys(), ...part.files.keys()])) {
            if (old.files.get(fid) === part.files.get(fid)) continue;
            const box = $('f' + fid);
            if (!box) return false;
            changed.push([cid, fid, box]);
        }
    }
    for (const [cid, fid, box] of changed) {
        holdForms(box);
        box.replaceWith(fileView(fileIndex.get(Number(fid)).commit, fileIndex.get(Number(fid)).file, state.commits[cid]?.files[fid]));
    }
    rendered[c.id] = { spec: sectionSpec(c), parts: now };
    return true;
}

// A commit or merge: a mainline one is always open, its section carrying
// its id; one a merge brought in is a row in that merge until opened. Its
// diff or resolution tab shows in place of its files or commits, right
// under its summary and the flags no row carries; their state stays, to show
// again on the list tab.
function commitView(c) {
    const item = { type: 'commit', commit: c };
    const cs = state.commits[c.id];
    const merged = mergePath(tree, c).length > 0;
    const open = panelOf(item) !== undefined;
    const kids = tree.kids.get(c.id);
    const label = commitLabel(c);
    const node = { kind: kids ? 'merge' : 'commit', id: merged ? 'c' + c.id : null, open, label, tag: 'h2', item,
        parts: [resolvedBadge(c)], onToggle: merged ? () => toggleRow(item) : null };
    if (!open) {
        const gist = firstLine(c.what);
        return levelNode({ ...node, rowParts: [flagBadge(item), gist ? el('span', { class: 'gist' }, inline(gist)) : null] });
    }
    const { files, pending } = orderedFiles(c);
    const date = c.authored ? new Date(c.authored * 1000).toLocaleString() : null;
    const panel = panelBox(item, shownPanel(tabsOf(item), cs?.panel ?? ''));
    const list = !kids && !panel && tabsOf(item).includes('');
    return levelNode({ ...node, tabs: tabsBar(item), body: [
        el('div', { class: 'meta' }, el('code', {}, c.revision.slice(0, 12)), c.author ? ' ' + c.author : '', date ? ' ' + date : ''),
        facts([['Renamed', renameFact(c.files)]]),
        proseBlock('What', c.what),
        proseBlock('Why', c.why),
        proseBlock('How', c.how),
        el('details', {}, el('summary', {}, 'Commit message'), el('pre', { class: 'message' }, c.message)),
        cardFlagList(item),
        panel,
        kids && !panel ? [el('h3', {}, 'Commits'), el('div', { class: 'commit-list' }, kids.map(commitView))] : null,
        cs?.view ? blobView(c, cs.view) : null,
        list ? el('h3', {}, 'Files', pending ? el('span', { class: 'pending', title: 'The agent has not set a reading order; showing A–Z' }, ' reading order pending') : null) : null,
        list ? el('div', { class: 'files' }, files.map(f => fileView(c, f, cs?.files[f.id]))) : null,
        notesSlot(item),
    ] });
}

// A file shown whole as it is at a commit that need not have changed it, as
// a guide touring the code as it lands shows it. It shows only open; its
// head closes it.
function blobView(c, path) {
    const box = el('div', { class: 'panel view' }, el('p', { class: 'missing loading' }, 'Loading…'));
    track(box, fillBlob(box, c, path).catch(err => {
        box.replaceChildren(el('p', { class: 'error' }, String(err.message || err)));
    }));
    return levelNode({ kind: 'blob', cls: 'blob', id: 'b' + c.id, open: true, label: path, tag: 'h2',
        onToggle: () => closeView({ type: 'blob', commit: c, path }), body: [
            el('div', { class: 'meta' }, 'As of ', el('code', {}, c.revision.slice(0, 12)), ' ', commitLabel(c)),
            box,
        ] });
}

async function fillBlob(box, c, path) {
    const kind = review.content_kinds?.[`${c.revision}:${path}`] ?? 'text';
    if (kind === 'image') return box.replaceChildren(await pictured(el('img', { src: contentUrl(c.revision, path), alt: path })));
    if (kind === 'binary') return box.replaceChildren(el('p', { class: 'missing' }, 'Binary file.'));
    const lines = await contentLines(c.revision, path, kind);
    if (!lines) return box.replaceChildren(el('p', { class: 'missing' }, 'Not in this commit.'));
    box.replaceChildren(codeTable({ 'data-revision': c.revision, 'data-path': path }, lines, null, []));
    decorateIn(box);
}

const STATUS_LABEL = { A: 'added', D: 'deleted', M: 'modified', R: 'renamed' };

// A file as a one-line row that expands in place, or, expanded (fs
// defined), as a card with its tabs, facts, summary, the flags no section
// row carries, and its sections or the panel its tab shows in their place
// (their state stays, to show again on the list tab). The row shows only
// the path (its color tells the status, its tooltip says it), the counts and
// the flags, as a section's row does.
function fileView(c, f, fs) {
    const item = { type: 'file', commit: c, file: f };
    const node = { kind: 'file', cls: 'file', id: 'f' + f.id, open: !!fs, label: fileLabel(f), tip: `${fileLabel(f)} (${STATUS_LABEL[f.status]})`,
        labelCls: sizeClass(f), parts: [renameTag(f), counts(f), flagBadge(item)], item, onToggle: () => toggleRow(item) };
    if (!fs) return levelNode(node);
    const data = fileData.get(f.id);
    const shown = shownPanel(tabsOf(item), fs.panel);
    const size = f.size_before == null && f.size_after == null ? null
        : `${f.size_before ?? '—'} → ${f.size_after ?? '—'} ${f.size_unit}`;
    return levelNode({ ...node, tabs: tabsBar(item), body: [
        facts([
            ['Status', STATUS_LABEL[f.status] + (f.old_path ? ` from ${f.old_path}` : '')],
            ['Kind', f.kind],
            ['Lines', counts(f)],
            ['Size', size],
            ['Object system', f.object_system],
            ['Paradigms', f.paradigms],
        ]),
        proseBlock('What changed', f.what),
        !data.sections.length && needsSplit(f) && f.split_source === 'none' ? el('p', { class: 'meta' }, 'No sections yet: the agent has not split this file.') : null,
        cardFlagList(item, data.sections),
        panelBox(item, shown),
        !shown && data.sections.length ? el('h3', {}, 'Sections') : null,
        !shown && data.sections.length ? el('div', { class: 'sections' }, data.sections.map(s => sectionView(c, f, s, fs.sections[s.id]))) : null,
        notesSlot(item),
    ] });
}

// A renamed file's badge: renamed, or renamed + changed.
function renameTag(f) {
    const badge = renameBadge(f);
    return badge ? el('span', { class: 'tag', title: `Renamed from ${f.old_path}` }, badge) : null;
}

// A section as a one-line row that expands in place, or, expanded (panel
// defined), as a card with its summary, docs and panel.
function sectionView(c, f, s, panel) {
    const item = { type: 'section', commit: c, file: f, section: s };
    const node = { kind: 'section', cls: 'section', id: 's' + s.id, open: panel !== undefined, label: s.name,
        labelCls: s.deleted ? 'deleted' : null, parts: [counts(s), flagBadge(item)], item, onToggle: () => toggleRow(item) };
    if (panel === undefined) return levelNode(node);
    const docs = el('div', { class: 'docs' });
    if (s.doc_ranges.length) track(docs, fillDocs(docs, f, s).catch(showError));
    return levelNode({ ...node, body: [
        el('div', { class: 'section-body' + (s.doc_ranges.length ? ' with-docs' : '') },
            el('div', {},
                facts([
                    ['Package', s.package],
                    ['Deleted', s.deleted ? 'yes' : null],
                ]),
                proseBlock('What changed', s.what)),
            docs),
        notesSlot(item),
        panelBox(item, panel),
    ] });
}

// Documentation the backend rendered arrives as doc_html (standards/API.md,
// GET /api/file/ID); other documentation shows as highlighted lines.
async function fillDocs(box, f, s) {
    if (s.doc_html != null) return box.append(el('h3', {}, 'Documentation'), el('div', { class: 'pod', html: s.doc_html }));
    const lines = await newLines(f);
    if (!lines) return;
    box.append(el('h3', {}, 'Documentation'), codeTable({ 'data-fid': f.id }, lines, l => inRanges(l, s.doc_ranges), []));
    decorateIn(box);
}

// ---- diff and file panels ----

function panelBox(item, panel) {
    if (!panel) return null;
    const box = el('div', { class: 'panel' + (panel === 'v' ? ' view' : '') }, el('p', { class: 'missing loading' }, 'Loading…'));
    const fill = { d: fillDiff, v: fillView, r: fillResolution }[panel];
    // Filled, the panel shows the line comments it has; the others are
    // counted where the page stops short of them.
    track(box, fill(box, item).catch(err => {
        box.replaceChildren(el('p', { class: 'error' }, String(err.message || err)));
    }).then(() => syncCommentBadges()));
    return box;
}

async function fillDiff(box, item) {
    if (item.type !== 'commit') box.replaceChildren(await fileDiff(item.file, item.section?.id));
    else {
        const parts = await Promise.all(orderedFiles(item.commit).files.map(async f =>
            el('div', { class: 'file-diff' }, el('h4', { class: sizeClass(f) }, fileLabel(f), ' ', renameTag(f)), await fileDiff(f))));
        box.replaceChildren(...parts);
    }
    decorateIn(box);
}

async function fileDiff(f, sid) {
    const c = fileIndex.get(f.id).commit;
    if (f.kind === 'image') return pictured(beforeAfter(c, f));
    const diff = await loadDiff(f.id, sid);
    if (diff.binary || f.kind === 'binary') return el('p', { class: 'missing' }, 'Binary file; no diff.');
    if (!diff.hunks.length) return el('p', { class: 'missing' }, 'No line changes.');
    const [oldL, newL] = await Promise.all([oldLines(f), newLines(f)]);
    return diffTable(diff.hunks, oldL, newL, { 'data-fid': f.id, 'data-sid': sid });
}

// Hunks as a unified or side-by-side table; oldL and newL are the
// highlighted lines of each side, or null to show the hunks' own text.
function diffTable(hunks, oldL, newL, attrs) {
    const code = (lines, n, text) => lines?.[n - 1] ?? escapeHtml(text);
    const cls = { ' ': 'ctx', '-': 'del', '+': 'add' };
    let html = '';
    if (diffMode === 'split') {
        const side = (r, x, lines) => x
            ? `<td class="ln ${cls[x.type]}" data-side="${x === r.left ? 'old' : 'new'}">${x.line}</td><td class="code ${cls[x.type]}">${code(lines, x.line, x.text)}</td>`
            : '<td class="ln none"></td><td class="code none"></td>';
        for (const r of splitRows(hunks)) {
            html += r.kind === 'part' ? `<tr class="part"><td colspan="4">${escapeHtml(r.label)}</td></tr>`
                : r.kind === 'hunk' ? `<tr class="hunk"><td colspan="4">${escapeHtml(r.header)}</td></tr>`
                : `<tr${r.left ? ` data-old="${r.left.line}"` : ''}${r.right ? ` data-new="${r.right.line}"` : ''}>${side(r, r.left, oldL)}${side(r, r.right, newL)}</tr>`;
        }
    }
    else {
        for (const r of unifiedRows(hunks)) {
            if (r.kind === 'part') {
                html += `<tr class="part"><td colspan="3">${escapeHtml(r.label)}</td></tr>`;
                continue;
            }
            if (r.kind === 'hunk') {
                html += `<tr class="hunk"><td colspan="3">${escapeHtml(r.header)}</td></tr>`;
                continue;
            }
            const text = r.type === '-' ? code(oldL, r.old, r.text) : code(newL, r.new, r.text);
            html += `<tr class="${cls[r.type]}"${r.old ? ` data-old="${r.old}"` : ''}${r.new ? ` data-new="${r.new}"` : ''}>`
                + `<td class="ln" data-side="old">${r.old ?? ''}</td><td class="ln" data-side="new">${r.new ?? ''}</td><td class="code">${text}</td></tr>`;
        }
    }
    return el('table', { class: 'diff ' + diffMode, ...attrs, html: '<tbody>' + html + '</tbody>' });
}

// The file before and after the commit, side by side: an image's diff, and
// the picture atop an SVG's file tab (SVG is also diffed as text).
function beforeAfter(c, f, preview) {
    return el('div', { class: 'images' + (preview ? ' preview' : '') },
        f.status !== 'A' && c.parent ? el('figure', {}, el('img', { src: contentUrl(c.parent, f.old_path || f.path), alt: 'before' }), el('figcaption', {}, 'before')) : null,
        f.status !== 'D' ? el('figure', {}, el('img', { src: contentUrl(c.revision, f.path), alt: 'after' }), el('figcaption', {}, 'after')) : null);
}

// A merge's conflict resolutions (git: what git show --remerge-diff shows): the
// merge against the VCS's own re-merge of its parents, per file.
async function fillResolution(box, item) {
    const data = await getJSON(`api/resolution/${item.commit.id}`);
    const files = (data.files || []).filter(f => f.hunks?.length);
    if (!files.length) return box.replaceChildren(el('p', { class: 'missing' }, 'No conflict resolutions.'));
    box.replaceChildren(...files.map(f =>
        el('div', { class: 'file-diff' }, el('h4', {}, f.path), diffTable(f.hunks, null, null, { 'data-merge': item.commit.id }))));
}

async function fillView(box, item) {
    const f = item.file;
    const c = item.commit;
    if (f.status === 'D') return box.replaceChildren(el('p', { class: 'missing' }, 'Deleted in this commit.'));
    if (f.kind === 'image') return box.replaceChildren(await pictured(el('img', { src: contentUrl(c.revision, f.path), alt: f.path })));
    if (f.kind === 'binary') return box.replaceChildren(el('p', { class: 'missing' }, 'Binary file.'));
    const lines = await newLines(f);
    const marks = item.section ? [...item.section.ranges, ...item.section.doc_ranges] : [];
    // A file's own tab shows an SVG as a picture too, above its source.
    const picture = item.type === 'file' && isSvg(f.path) ? beforeAfter(c, f, true) : null;
    // Its size is known before the table goes in, so a reveal in the box
    // stays put.
    if (picture) await pictured(picture);
    box.replaceChildren(...[picture, codeTable({ 'data-fid': f.id }, lines || [], null, marks)].filter(Boolean));
    const first = box.querySelector('tr.mark');
    if (first) box.scrollTop = first.offsetTop - 40;
    decorateIn(box);
}

// Lines as a numbered table; attrs say whose lines they are (see decorateIn),
// `only` filters which lines appear, `marks` tints ranges.
function codeTable(attrs, lines, only, marks) {
    let html = '';
    let last = 0;
    lines.forEach((line, i) => {
        const n = i + 1;
        if (only && !only(n)) return;
        if (only && last && n !== last + 1) html += '<tr class="gap"><td colspan="2"></td></tr>';
        last = n;
        html += `<tr data-new="${n}"${inRanges(n, marks) ? ' class="mark"' : ''}><td class="ln" data-side="new">${n}</td><td class="code">${line}</td></tr>`;
    });
    return el('table', { class: 'code-view', ...attrs, html: '<tbody>' + html + '</tbody>' });
}

// Line tables carry data-fid (and data-sid for a section diff), or, for a
// whole file at a commit that did not change it, data-revision and data-path.
// Their rows carry data-old/data-new and their line-number cells data-side.
export const LINE_TABLES = 'table[data-fid], table[data-path]';

// The commit revision, path and flag side of a line table's lines.
export function lineSource(table) {
    if (!table.dataset.fid) return { revision: table.dataset.revision, path: table.dataset.path, side: 'new' };
    const { file, commit } = fileIndex.get(Number(table.dataset.fid));
    return { revision: commit.revision, path: file.path, side: flagSide(file) };
}

// Flags, line feedback and guide highlights on the line tables in box. Line
// feedback needs a file entry, so whole files at other commits take none.
function decorateIn(box) {
    for (const t of box.querySelectorAll(LINE_TABLES)) {
        decorateFlags(t);
        if (t.dataset.fid) placeLineFeedback(t);
        applyHighlights(t);
    }
    syncCommentBadges();
    tryReveal();
}

// ---- tree ----

function renderTree() {
    const nav = $('tree');
    const top = nav.scrollTop;
    const node = (id, label, cls, onclick, item, kids) => el('li', { 'data-node': id, class: cls },
        el('div', { class: 'node' },
            el('button', { class: 'link', onclick: () => { hideTreeOnPhone(); onclick() } }, label),
            item ? flagBadge(item) : null,
            item?.type === 'commit' ? resolvedBadge(item.commit) : null,
            item?.type === 'file' ? renameTag(item.file) : null,
            item ? widgetBar(item) : null),
        kids);

    // A merge expands to its commits; a merged-in commit shows as open while
    // its merge's section has it open.
    const entry = c => {
        const cs = state.commits[c.id];
        const item = { type: 'commit', commit: c };
        const kids = tree.kids.get(c.id);
        const opened = state.commits[c.merge_id]?.commits[c.id];
        return node('c' + c.id, commitLabel(c), 'commit' + (kids ? ' merge' : '') + (opened ? ' open' : ''), () => open(item), item,
            el('ul', {}, kids ? kids.map(entry) : fileNodes(c, cs)));
    };
    const fileNodes = (c, cs) => {
        const { files, pending } = orderedFiles(c);
        return [
            pending ? el('li', { class: 'pending' }, 'reading order pending') : null,
            ...files.map(f => {
                const fs = cs?.files[f.id];
                const item = { type: 'file', commit: c, file: f };
                const secs = fs ? fileData.get(f.id)?.sections || [] : [];
                return node('f' + f.id, fileLabel(f), sizeClass(f) + (fs ? ' open' : ''), () => open(item), item,
                    secs.length ? el('ul', {}, secs.map(s => {
                        const sitem = { type: 'section', commit: c, file: f, section: s };
                        return node('s' + s.id, s.name, (s.deleted ? 'deleted' : '') + (s.id in fs.sections ? ' open' : ''),
                            () => open(sitem), sitem);
                    })) : null);
            }),
        ];
    };

    nav.replaceChildren(el('ul', {},
        node('summary', 'Summary', '', () => go(() => {}, 'summary')),
        tree.mainline.map(entry)));
    nav.scrollTop = top;
    markCurrent();
}

function markCurrent() {
    for (const li of $('tree').querySelectorAll('li.current')) li.classList.remove('current');
    const li = $('tree').querySelector(`li[data-node="${currentNode}"]`);
    if (!li) return;
    li.classList.add('current');
    keepInView(li.firstChild);
}

// Scroll only the tree, never the page, to show a node.
function keepInView(node) {
    const nav = $('tree');
    const t = nav.getBoundingClientRect();
    const n = node.getBoundingClientRect();
    if (n.top < t.top) nav.scrollTop -= t.top - n.top + 8;
    else if (n.bottom > t.bottom) nav.scrollTop += Math.min(n.bottom - t.bottom + 8, n.top - t.top - 8);
    if (n.left < t.left || n.left > t.right - 40) nav.scrollLeft += n.left - t.left - 8;
}

function observeSections() {
    observer?.disconnect();
    visible.clear();
    const order = ['summary', ...tree.mainline.map(c => 'c' + c.id)];
    observer = new IntersectionObserver(entries => {
        for (const e of entries) {
            if (e.isIntersecting) visible.add(e.target.id);
            else visible.delete(e.target.id);
        }
        const cur = visible.has(pinned) ? pinned : order.find(id => visible.has(id));
        if (cur && cur !== currentNode) {
            currentNode = cur;
            markCurrent();
        }
    }, { rootMargin: '-60px 0px -55% 0px' });
    for (const id of order) observer.observe($(id));
}

// ---- layout controls ----

const phone = matchMedia('(max-width: 700px)');

// The tree starts closed. Opened or closed by its tabs, it stays so on the
// next visit, except at phone width, where it is an overlay that always
// starts closed. Opened, it shows the current node.
function setTreeHidden(hidden, remember) {
    document.body.classList.toggle('tree-hidden', hidden);
    if (remember) pref.set('tree-open', hidden ? '0' : '1');
    if (!hidden) markCurrent();
}

function hideTreeOnPhone() {
    if (phone.matches) setTreeHidden(true, false);
}

// The line between the header's groups shows only between them on one row:
// a first group with nothing shown is hidden, and a second group wrapped to
// a row of its own drops the line but keeps its indent, so dropping it
// cannot unwrap the row.
function syncHeaderHeight() {
    const nav = $('head_nav'), view = $('head_view');
    nav.hidden = ![...nav.children].some(c => !c.hidden);
    view.classList.toggle('lead', !nav.hidden && view.offsetTop > nav.offsetTop + nav.offsetHeight / 2);
    document.documentElement.style.setProperty('--header-h', $('header').offsetHeight + 'px');
}

function setupLayout() {
    // The header wraps when it does not fit; everything below it is offset
    // by its real height.
    new ResizeObserver(syncHeaderHeight).observe($('header'));
    // The tree's tabs centre in the space between the header and the guide bar.
    new ResizeObserver(() => document.documentElement.style.setProperty('--guide-h', $('guide_bar').offsetHeight + 'px'))
        .observe($('guide_bar'));
    setTreeHidden(phone.matches || pref.get('tree-open', '0') !== '1', false);
    const width = Number(pref.get('tree-width', 0));
    if (width) document.body.style.setProperty('--tree-w', width + 'px');

    $('tree_open').addEventListener('click', () => {
        setTreeHidden(false, !phone.matches);
        $('tree_close').focus();
    });
    $('tree_close').addEventListener('click', () => {
        setTreeHidden(true, !phone.matches);
        $('tree_open').focus();
    });

    const grip = $('tree_grip');
    grip.addEventListener('pointerdown', e => {
        grip.setPointerCapture(e.pointerId);
        const move = ev => {
            const w = Math.max(120, Math.min(ev.clientX, window.innerWidth * 0.6));
            document.body.style.setProperty('--tree-w', Math.round(w) + 'px');
        };
        grip.addEventListener('pointermove', move);
        grip.addEventListener('pointerup', () => {
            grip.removeEventListener('pointermove', move);
            pref.set('tree-width', parseInt(getComputedStyle(document.body).getPropertyValue('--tree-w')));
        }, { once: true });
    });

    const toggle = (id, set) => $(id).addEventListener('click', e => {
        const value = e.target.dataset.value;
        if (!value) return;
        set(value);
        syncSwitch(id, value);
        if (review) rerenderAll();
    });
    toggle('order_toggle', v => pref.set('order', orderMode = v));
    toggle('diff_toggle', v => pref.set('diff', diffMode = v));
    $('order_toggle').addEventListener('keydown', radioKeys);
    $('diff_toggle').addEventListener('keydown', radioKeys);

    $('main').addEventListener('click', e => {
        if (flagClick(e) || lineClick(e)) e.preventDefault();
    });
    $('close_review').addEventListener('click', () => closeReview().catch(showError));
    $('guide_play').addEventListener('click', playGuide);
    $('stale_accept').addEventListener('click', acceptReview);

    $('iteration').addEventListener('change', e => {
        location.hash = '#' + encodeState({ ...emptyState(), it: Number(e.target.value) });
    });
}

setupLayout();
setupSpeech();
setupGuide();
window.addEventListener('hashchange', apply);
window.addEventListener('scroll', trimRoom, { passive: true });
apply();
