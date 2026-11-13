// What the page sends back: feedback, requests, the feedback download, and
// closing the review.
import {
    el, prose, $, review, tree, loadedIt, open, keepHead, showHead, getJSON, loadFile, loadDiff, fileIndex, fileData, navigate, renderHeader, showError,
} from './app.js';
import { belongsTo, diffLineSection, isAway, requestKinds, wasOn, mergePath, sameSection, lineInHunks, filePanels } from './logic.js';
import { refreshFlags, markIcon } from './flags.js';

const REQUEST_KIND = { debate: 'Debate', split: 'Split' };

// A form to open under an item's head once its card is rendered.
let pendingForm = null;
// Open forms, with what was typed in them, carried across a redraw: 'n' plus
// an item's key holds the form under its head, a line table key plus its
// side and line a line box.
const held = new Map();

function keyOf(item) {
    return item.type === 'review' ? 'review' : item.type[0] + (item.section ?? item.file ?? item.commit).id;
}

function anchorOf(item) {
    const a = { target: item.type };
    if (item.commit) a.commit = item.commit.revision;
    if (item.type === 'commit' && item.commit.topic != null) a.topic = item.commit.topic;
    if (item.file) a.path = item.file.path;
    if (item.section) a.section = { name: item.section.name, package: item.section.package ?? null };
    return a;
}

function tableKey(table) {
    return `l${table.dataset.fid}:${table.dataset.sid ?? ''}:`;
}

function boxKey(table, tr) {
    return tableKey(table) + tr.dataset.side + tr.dataset.line;
}

// Take the open forms out of a part of the page about to be redrawn; the
// redrawn notes and line tables put them back.
export function holdForms(box) {
    for (const f of box.querySelectorAll('.form-slot[data-key] > .form')) held.set('n' + f.parentElement.dataset.key, f);
    for (const tr of box.querySelectorAll('table[data-fid] tr.fb-form')) held.set(boxKey(tr.closest('table'), tr), tr);
}

export async function post(url, body) {
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`${url}: ${res.status} ${res.statusText}`);
    return res.json();
}

// Reload feedback, requests and the flags' state after a change, and redraw
// where they show.
export async function refresh() {
    const fresh = await getJSON('api/review' + (loadedIt != null ? `?iteration=${loadedIt}` : ''));
    review.review = fresh.review;
    review.feedback = fresh.feedback;
    review.requests = fresh.requests;
    for (const fl of fresh.flags) {
        const mine = review.flags.find(x => x.id === fl.id);
        if (mine) mine.seen = fl.seen;
    }
    fillNotes();
    for (const t of $('main').querySelectorAll('table[data-fid]')) placeLineFeedback(t);
    syncCommentBadges();
    refreshFlags();
}

// Redraw the feedback and requests under every card; the summary's list
// of those shown nowhere else depends on which flags the viewer shows.
export function fillNotes() {
    for (const slot of document.querySelectorAll('.notes')) fillSlot(slot);
}

// ---- notes under a card ----

export function notesSlot(item) {
    const slot = el('div', { class: 'notes', 'data-key': keyOf(item) });
    slot.item = item;
    fillSlot(slot);
    return slot;
}

// Where an item's feedback or request form opens: right under its head,
// above the card's content, so the head need not move to show it.
export function formSlot(item) {
    const slot = el('div', { class: 'form-slot', 'data-key': keyOf(item) });
    slot.item = item;
    const kept = held.get('n' + slot.dataset.key);
    held.delete('n' + slot.dataset.key);
    if (kept) slot.append(kept);
    if (pendingForm?.key === slot.dataset.key) {
        const kind = pendingForm.kind;
        pendingForm = null;
        showForm(slot, kind);
    }
    return slot;
}

function fillSlot(slot) {
    const a = anchorOf(slot.item);
    const kids = [
        ...review.feedback.filter(x => belongsTo(x, a)).map(fb => feedbackView(fb, 'line')),
        ...review.requests.filter(x => belongsTo(x, a)).map(requestView),
    ];
    if (slot.item.type === 'review') {
        // Feedback with no card or flag in this iteration to show under
        // (its commit, topic, path or flag is not here) cannot show at its
        // anchor, so the summary lists it.
        const fbs = review.feedback.filter(x => isAway(x, review.commits, review.flags));
        const rqs = review.requests.filter(x => isAway(x, review.commits, review.flags));
        if (fbs.length || rqs.length) {
            kids.push(el('h3', {}, 'Not shown in this iteration'),
                ...fbs.map(fb => feedbackView(fb, 'full')), ...rqs.map(requestView));
        }
    }
    slot.replaceChildren(...kids);
}

function where(x, detail) {
    if (detail === 'full') {
        const on = x.target === 'flag' ? `on flag: ${x.flag?.sentence ?? x.flag?.note}` : x.section?.name;
        return [x.commit?.slice(0, 12), x.topic, x.path, wasOn(x) ?? on, x.line != null ? `line ${x.line} (${x.side})` : null]
            .filter(Boolean).join(' ');
    }
    return x.target === 'line' ? `line ${x.line} (${x.side})` : wasOn(x);
}

// Only the author edits feedback; feedback with no reviewer, written before
// reviewers were recorded, is anyone's. The server enforces the same.
function mayEdit(fb) {
    return !fb.reviewer?.trim() || fb.reviewer === review.identity?.reviewer;
}

// detail: 'full' labels feedback with its whole anchor; any other value
// labels line feedback with its line, and file feedback with the section it
// was on before a re-split (see wasOn).
export function feedbackView(fb, detail) {
    const box = el('div', { class: 'fb', 'data-fb': fb.id });
    const draw = () => box.replaceChildren(...[
        el('div', { class: 'fb-head' },
            el('span', { class: 'status ' + fb.status }, fb.status),
            fb.reviewer ? el('span', { class: 'reviewer' }, fb.reviewer) : null,
            el('span', { class: 'meta' }, where(fb, detail)),
            fb.iteration !== review.iteration ? el('span', { class: 'meta' }, `iteration ${fb.iteration}`) : null,
            fb.resolved_in ? el('span', { class: 'meta' }, `resolved in iteration ${fb.resolved_in}`) : null,
            mayEdit(fb) ? el('button', { class: 'tool', title: 'Edit this feedback', onclick: edit }, 'edit') : null),
        prose(fb.body),
        fb.response ? el('div', { class: 'response' }, el('span', { class: 'who' }, 'Agent:'), prose(fb.response)) : null,
    ].filter(Boolean));
    const edit = () => {
        const body = el('textarea', { rows: 3, required: true });
        body.value = fb.body;
        const status = el('select', { title: 'Status' }, ['open', 'addressed', 'declined'].map(v =>
            el('option', { value: v, selected: v === fb.status }, v)));
        box.replaceChildren(form('Save', [body, status], () =>
            post(`api/feedback/${fb.id}`, { body: body.value, status: status.value }), draw));
        body.focus();
    };
    draw();
    return box;
}

function requestView(r) {
    const done = r.case_for != null || r.case_against != null;
    return el('div', { class: 'fb request' },
        el('div', { class: 'fb-head' },
            el('strong', {}, `${REQUEST_KIND[r.kind] || r.kind} requested`),
            r.reviewer ? el('span', { class: 'reviewer' }, `by ${r.reviewer}`) : null,
            el('span', { class: 'status ' + r.status }, r.status),
            wasOn(r) ? el('span', { class: 'meta' }, wasOn(r)) : null,
            r.iteration !== review.iteration ? el('span', { class: 'meta' }, `iteration ${r.iteration}`) : null),
        r.note ? prose(r.note) : null,
        done ? el('div', { class: 'debate' },
            el('div', { class: 'case for' }, el('h4', {}, 'Case for'), prose(r.case_for, 'Not written.')),
            el('div', { class: 'case against' }, el('h4', {}, 'Case against'), prose(r.case_against, 'Not written.'))) : null);
}

// ---- forms ----

// A small form; `send` posts it, then the page refreshes. `done` runs on
// success and on cancel (default: remove the form, or its table row).
function form(label, fields, send, done) {
    const box = el('form', { class: 'form' }, fields,
        el('div', { class: 'buttons' },
            el('button', { type: 'submit' }, label),
            el('button', { type: 'button', onclick: () => finish() }, 'Cancel')));
    const finish = done || (() => (box.closest('tr.fb-form') || box).remove());
    const submit = box.querySelector('button[type="submit"]');
    box.addEventListener('submit', async e => {
        e.preventDefault();
        // One post per form: a second submit while the first is in flight
        // would store the item twice.
        if (submit.disabled) return;
        submit.disabled = true;
        try {
            await send();
            finish();
            await refresh();
        }
        catch (err) {
            submit.disabled = false;
            showError(err);
        }
    });
    return box;
}

function showForm(slot, kind) {
    slot.querySelector(':scope > .form')?.remove();
    const item = slot.item;
    let f;
    if (kind === 'feedback') {
        const body = el('textarea', { rows: 3, required: true, placeholder: 'Feedback for the agent' });
        f = form('Add feedback', [body], () => post('api/feedback', { ...anchorOf(item), body: body.value, iteration: review.iteration }));
    }
    else {
        const kinds = requestKinds(item);
        const sel = el('select', { title: 'What to ask for' }, kinds.map(k => el('option', { value: k }, REQUEST_KIND[k])));
        const note = el('textarea', { rows: 2, placeholder: 'Note for the agent (optional)' });
        f = form('Request', [sel, note], () =>
            post('api/request', { kind: sel.value, ...anchorOf(item), note: note.value || null, iteration: review.iteration }));
    }
    slot.append(f);
    f.querySelector('textarea, select').focus({ preventScroll: true });
    return f;
}

// The form opens under the item's head, which stays where it is when the
// head's button was clicked; from the index, the page goes to the item, the
// form under its head. Every head with the buttons has a slot drawn.
function openForm(item, kind, fromTree) {
    const key = keyOf(item);
    const slot = $('main').querySelector(`.form-slot[data-key="${key}"]`);
    if (slot && fromTree) return showHead(item, showForm(slot, kind));
    if (slot) return keepHead(item, () => showForm(slot, kind));
    pendingForm = { key, kind };
    open(item);
}

function formButton(item, kind, label, title) {
    return el('button', {
        class: 'tool',
        title,
        onclick: e => {
            e.stopPropagation();
            openForm(item, kind, !!e.currentTarget.closest('#tree'));
        },
    }, label);
}

export function feedbackButton(item) {
    return formButton(item, 'feedback', 'feedback', 'Add feedback for the agent');
}

export function requestButton(item) {
    if (item.type === 'review') return null;
    return formButton(item, 'request', 'request',
        requestKinds(item).includes('split') ? 'Ask the agent for a debate or a new split' : 'Ask the agent for a debate');
}

// ---- line feedback ----

function afterRow(row, tr) {
    let at = row;
    while (at.nextElementSibling?.matches('.fb-row, .fb-form')) at = at.nextElementSibling;
    at.after(tr);
}

// Show line feedback under the rows it anchors to.
export function placeLineFeedback(table) {
    for (const tr of table.querySelectorAll('tr.fb-row')) tr.remove();
    const { file, commit } = fileIndex.get(Number(table.dataset.fid));
    for (const fb of review.feedback) {
        if (fb.target !== 'line' || fb.commit !== commit.revision || fb.path !== file.path) continue;
        const row = table.querySelector(`tr[data-${fb.side}="${fb.line}"]`);
        if (row) afterRow(row, el('tr', { class: 'fb-row' }, el('td', { colspan: row.cells.length }, feedbackView(fb, ''))));
    }
    for (const [key, kept] of held) {
        if (!key.startsWith(tableKey(table))) continue;
        const row = table.querySelector(`tr[data-${kept.dataset.side}="${kept.dataset.line}"]`);
        if (!row) continue;
        held.delete(key);
        kept.cells[0].colSpan = row.cells.length;
        afterRow(row, kept);
    }
}

// A click on a line number opens a feedback box under that row. Returns
// whether the click was one.
export function lineClick(e) {
    const td = e.target.closest('td.ln[data-side]');
    const table = td?.closest('table[data-fid]');
    if (!table) return false;
    const row = td.parentElement;
    const side = td.dataset.side;
    const line = Number(row.dataset[side]);
    if (!line) return false;
    // A box already open on the line takes the focus. Another line's box
    // goes only when nothing is typed in it: a draft is never dropped.
    const boxes = [...table.querySelectorAll('tr.fb-form')];
    const here = boxes.find(tr => tr.dataset.side === side && Number(tr.dataset.line) === line);
    if (here) {
        here.querySelector('textarea')?.focus();
        return true;
    }
    for (const tr of boxes) if (!tr.querySelector('textarea')?.value.trim()) tr.remove();

    const fid = Number(table.dataset.fid);
    const { file, commit } = fileIndex.get(fid);
    const body = el('textarea', { rows: 3, required: true, placeholder: `Feedback on line ${line} (${side})` });
    const f = form('Add feedback', [body], async () => {
        const data = await loadFile(fid);
        const sid = Number(table.dataset.sid);
        const s = sid ? data.sections.find(x => x.id === sid) : null;
        const hunks = !s && side === 'old' ? (await loadDiff(fid)).hunks : [];
        await post('api/feedback', {
            target: 'line', commit: commit.revision, path: file.path, line, side, body: body.value, iteration: review.iteration,
            section: s ? { name: s.name, package: s.package ?? null } : diffLineSection(hunks, data.sections, line, side),
        });
    });
    afterRow(row, el('tr', { class: 'fb-form', 'data-side': side, 'data-line': line }, el('td', { colspan: row.cells.length }, f)));
    body.focus();
    return true;
}

// ---- comments out of sight ----

// Feedback shows in one place: line feedback at its line, the rest under its
// item's card. A comment whose place is not drawn (a row closed above it, or
// a tab that does not show its line) is counted on a badge where the page
// stops short of it: the closed row, or the head of the open card that does
// not show it. A click on the badge goes to the first of them. Feedback
// with no entry in this iteration the summary lists; a flag's comments are
// in its popup, its icon marked.

// The commit entry and file a comment is on, or null.
function entryOf(fb) {
    for (const c of review.commits) {
        if (fb.target === 'commit') {
            if (fb.topic == null && c.revision === fb.commit && c.topic == null) return { commit: c, file: null };
            continue;
        }
        const file = c.revision === fb.commit && c.files.find(f => f.path === fb.path);
        if (file) return { commit: c, file };
    }
    return null;
}

function cardOf(node) {
    return node.matches('.card') ? node : node.querySelector(':scope > .card');
}

// An open card's head row, unless its panel is still loading: its line
// tables are not drawn yet, so whether they show a line is not known.
function headRow(card, line) {
    if (line && card.querySelector(':scope > .panel > .loading')) return null;
    return card.querySelector(':scope > .head > .row');
}

// Where a comment not drawn is to be counted: the row closed over it, or
// the head of the open card that stops short of it; null when nothing is
// to be counted (drawn, in no entry, or a panel still loading).
function hiddenAt(fb) {
    if (!['commit', 'file', 'section', 'line'].includes(fb.target) || (fb.target === 'commit' && fb.topic != null)) return null;
    const at = entryOf(fb);
    if (!at) return null;
    const line = fb.target === 'line';
    let card = null;
    for (const c of [...mergePath(tree, at.commit), at.commit]) {
        const node = $('c' + c.id);
        if (!node) return card && headRow(card, line);
        card = cardOf(node);
        if (!card) return node.querySelector(':scope > .row');
    }
    if (!at.file) return null;
    // The commit's diff or resolution tab stands in for its files.
    const fnode = $('f' + at.file.id);
    if (!fnode) return headRow(card, line);
    card = cardOf(fnode);
    if (!card) return fnode.querySelector(':scope > .row');
    if (fb.target === 'file') return null;
    const s = fb.section && (fileData.get(at.file.id)?.sections ?? []).find(x => sameSection(x, fb.section));
    // The file's diff or file tab stands in for its sections.
    const snode = s && !card.querySelector(':scope > .panel') ? $('s' + s.id) : null;
    if (!snode) return fb.target === 'section' ? (card.querySelector(':scope > .panel') ? headRow(card, false) : null) : headRow(card, line);
    const scard = cardOf(snode);
    if (!scard) return snode.querySelector(':scope > .row');
    return line ? headRow(scard, line) : null;
}

// Count the comments not drawn on badges where the page stops short of them.
// A badge already on a row is kept, its count updated, so it keeps the
// keyboard focus.
export function syncCommentBadges() {
    const main = $('main');
    const at = new Map();
    if (review) {
        const drawn = new Set([...main.querySelectorAll('tr.fb-row .fb[data-fb], .notes .fb[data-fb]')].map(x => x.dataset.fb));
        for (const fb of review.feedback) {
            if (drawn.has(String(fb.id))) continue;
            const row = hiddenAt(fb);
            if (!row) continue;
            if (!at.has(row)) at.set(row, []);
            at.get(row).push(fb);
        }
    }
    for (const b of main.querySelectorAll('.cmt-badge')) if (!at.has(b.parentElement)) b.remove();
    for (const [row, fbs] of at) {
        const b = row.querySelector(':scope > .cmt-badge') ?? commentBadge();
        countBadge(b, fbs);
        // Right after the title: a narrow head clips its row's end, never
        // the badge.
        const title = row.querySelector(':scope > .title');
        if (b.previousElementSibling !== title) title ? title.after(b) : row.append(b);
    }
}

function commentBadge() {
    const b = el('button', {
        class: 'cmt-badge', type: 'button',
        onclick: e => {
            // Not a click on the row or head it sits in.
            e.stopPropagation();
            showComment(b.fbs[0]).catch(showError);
        },
    }, markIcon('talk'), el('span', { class: 'n' }));
    return b;
}

function countBadge(b, fbs) {
    const n = fbs.length;
    const title = `${n} comment${n === 1 ? '' : 's'} not shown here; click to show ${n === 1 ? 'it' : 'the first'}`;
    b.fbs = fbs;
    b.title = title;
    b.setAttribute('aria-label', title);
    b.querySelector('.n').textContent = String(n);
}

// Go to a comment: a line comment on the tab that shows its line (its
// section's diff when that has it, else the file's diff, or the whole file
// for a new line the diff leaves out), any other with its item's card.
async function showComment(fb) {
    const { commit, file } = entryOf(fb) ?? {};
    if (!commit) return;
    if (fb.target === 'line') {
        const reveal = { path: file.path, side: fb.side, line: fb.line };
        const s = fb.section && (await loadFile(file.id)).sections.find(x => sameSection(x, fb.section));
        if (s && lineInHunks((await loadDiff(file.id, s.id)).hunks ?? [], fb.line, fb.side)) {
            return navigate({ type: 'section', commit, file, section: fb.section, panel: 'd', reveal });
        }
        const inDiff = lineInHunks((await loadDiff(file.id)).hunks ?? [], fb.line, fb.side);
        const panel = !inDiff && fb.side === 'new' && filePanels(file).includes('v') ? 'v' : 'd';
        return navigate({ type: 'file', commit, file, panel, reveal });
    }
    const type = fb.target === 'commit' ? 'commit' : fb.target === 'file' ? 'file' : 'section';
    await navigate({ type, commit, file, section: type === 'section' ? fb.section : null });
    // Once drawn, the comment comes into view.
    const t0 = performance.now();
    const look = () => {
        const box = $('main').querySelector(`.notes .fb[data-fb="${fb.id}"]`);
        if (box) box.scrollIntoView({ block: 'center' });
        else if (performance.now() - t0 < 3000) requestAnimationFrame(look);
    };
    requestAnimationFrame(look);
}

// ---- download and close ----

export async function downloadFeedback() {
    const data = await getJSON('api/feedback');
    const blob = new Blob([JSON.stringify(data, null, 2) + '\n'], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = el('a', { href: url, download: `review-feedback-${review.review.id}.json` });
    document.body.append(a);
    a.click();
    a.remove();
    // The download has started from the URL; free the blob once it has it.
    setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export async function closeReview() {
    const ok = confirm('Close this review?\n\n'
        + 'Closing lets "review-helper prune" remove the pinned refs that keep old iterations viewable, '
        + 'so earlier iterations may lose their diffs.');
    if (!ok) return;
    await post('api/close', {});
    await refresh();
    renderHeader();
}
