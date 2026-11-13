// Flags: the agent's notes on lines, files and commits.
import { el, prose, review, tree, lineSource, navigate, showError, pref, $, LINE_TABLES } from './app.js';
import {
    flagsOf, cardFlags, flagEntry, flagPlan, subtree, flagGroups, sortFlags, FLAG_COLORS, seenMark, badgeOf, badgeTitle, flagComments, walkSteps,
} from './logic.js';
import { post, feedbackView, refresh } from './feedback.js';
import { playWalk, showGuide, keepMark } from './guide.js';
import { speakControls } from './speech.js';

let popup = null;
// The comment typed in a flag's popup and not sent, by flag id. Redraws,
// and closing and reopening the popup, put it back; sending clears it.
const drafts = new Map();
// The popup's comment edits left open, by feedback id, kept the same way.
const edits = new Map();

function draftOf(fl) {
    if (!drafts.has(fl.id)) drafts.set(fl.id, { comment: '' });
    return drafts.get(fl.id);
}

// A text field that keeps what is typed in it as the draft's key.
function drafted(field, draft, key) {
    field.value = draft[key];
    field.addEventListener('input', () => {
        draft[key] = field.value;
    });
    return field;
}

// Take note of the popup's open comment edits before it is redrawn or
// closed; an edit saved or cancelled is let go.
function keepEdits() {
    for (const box of popup?.querySelectorAll('.flag-comments > .fb[data-fb]') ?? []) {
        if (box.querySelector(':scope > form')) edits.set(box.dataset.fb, box);
        else edits.delete(box.dataset.fb);
    }
}

function me() {
    return review.identity?.reviewer;
}

const capital = s => s[0].toUpperCase() + s.slice(1);
const MEANING = Object.fromEntries(FLAG_COLORS);

function colorClass(fl) {
    return 'flag-' + fl.color;
}

function colorText(fl) {
    return `${fl.color} flag, ${MEANING[fl.color]}`;
}

// A part of the page drawn from the flags' state: redrawn in place when a
// flag is seen or commented on.
function flagSlot(tag, make) {
    const slot = el(tag, { class: 'flag-slot' });
    slot.make = make;
    fillSlot(slot);
    return slot;
}

function fillSlot(slot) {
    const x = slot.make();
    slot.replaceChildren(...(x ? [x] : []));
}

// A merge's flags include those of every commit it brought in.
function itemFlags(item) {
    if (item.type === 'commit') return subtree(tree, item.commit).flatMap(c => flagsOf(review.flags, c));
    return flagsOf(review.flags, item.commit, item.file, item.section);
}

// An item's badge: its flags (logic.js badgeOf), in the worst color, with a
// dot when some are unseen.
export function flagBadge(item) {
    return flagSlot('span', () => {
        const b = badgeOf(itemFlags(item), me());
        if (!b) return null;
        const title = badgeTitle(itemFlags(item)) + (b.unseen ? '; some not seen by you' : '');
        return el('span', { class: 'badge flag-' + b.color, title }, String(b.count),
            b.unseen ? el('span', { class: 'unseen-dot', 'aria-hidden': 'true' }) : null);
    });
}

const MARKS = {
    eye: 'M0.5 6 Q6 -0.5 11.5 6 Q6 12.5 0.5 6 Z M6 3.8 A2.2 2.2 0 1 0 6 8.2 A2.2 2.2 0 1 0 6 3.8 Z',
    talk: 'M0.5 0.5 H11.5 V8 H5.5 L2 11.5 V8 H0.5 Z',
};

export function markIcon(name) {
    const ns = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('class', 'flag-mark ' + name);
    svg.setAttribute('viewBox', '0 0 12 12');
    svg.setAttribute('aria-hidden', 'true');
    const path = document.createElementNS(ns, 'path');
    path.setAttribute('d', MARKS[name]);
    path.setAttribute('fill-rule', 'evenodd');
    svg.append(path);
    return svg;
}

// A flag's icon in its color, with no number: an eye once you have seen it,
// a speech mark when it has comments. Its color's meaning is in its title.
function icon(fl, opens = true) {
    const seen = !!seenMark(fl, me());
    const talk = flagComments(review.feedback, fl).length > 0;
    const title = capital(colorText(fl)) + ': ' + fl.sentence
        + [seen ? ' (seen)' : '', talk ? ' (comments)' : ''].join('');
    const attrs = opens ? { 'data-flag': fl.id, role: 'button', tabindex: 0 } : {};
    return el('span', { class: `flag-icon ${colorClass(fl)}${seen ? ' seen' : ''}`, title, ...attrs },
        '⚑', seen ? markIcon('eye') : null, talk ? markIcon('talk') : null);
}

// Gutter marks on a line table: an icon on the first shown line of each
// flag, a bar of its color on the rest. Drawn
// again from scratch whenever the flags' state changes.
export function decorateFlags(table) {
    for (const td of table.querySelectorAll('td.ln[data-flagged]')) {
        delete td.dataset.flagged;
        for (const ic of td.querySelectorAll(':scope > .flag-icon')) ic.remove();
    }
    const { revision, path, side } = lineSource(table);
    for (const fl of review.flags) {
        if (fl.commit !== revision || fl.path !== path || fl.line_start == null) continue;
        let first = true;
        for (let n = fl.line_start; n <= (fl.line_end ?? fl.line_start); n++) {
            const td = table.querySelector(`tr[data-${side}="${n}"] td.ln[data-side="${side}"]`);
            if (!td) continue;
            td.dataset.flagged = colorClass(fl);
            if (first) td.prepend(icon(fl));
            first = false;
        }
    }
    showFlagFocus();
}

// What speech reads for a flag: its sentence and detail.
export function flagText(fl) {
    return [fl.sentence, fl.detail].filter(Boolean).join('\n\n');
}

function lineText(fl) {
    return fl.line_start == null ? '' : `:${fl.line_start}${fl.line_end > fl.line_start ? '–' + fl.line_end : ''}`;
}

// The flags a commit's or file's card shows itself (logic.js cardFlags), a
// line each: its icon, kind and sentence, which open its popup as a gutter
// icon does, for a line flag where its lines are (with the path, on a
// commit's card), which jumps to them, and buttons to read it aloud.
export function cardFlagList(item, sections) {
    return flagSlot('div', () => {
        const list = cardFlags(review.flags, item.commit, item.file, sections);
        if (!list.length) return null;
        return el('ul', { class: 'card-flags' }, sortFlags(list, review.commits).map(fl => {
            const where = (item.file ? '' : fl.path ?? '') + lineText(fl);
            const plan = where && flagPlan(fl, review);
            return el('li', { 'data-card-flag': fl.id },
                icon(fl), ' ',
                el('button', { class: 'link', 'data-flag': fl.id, title: 'Show this flag' }, el('strong', {}, fl.kind + ':'), ' ', fl.sentence),
                plan ? [' ', el('button', {
                    class: 'link where', title: 'Show the flagged lines',
                    onclick: () => goToFlag(fl, plan),
                }, where)] : null,
                ' ', speakControls(flagText(fl)));
        }));
    });
}

// A flag link: going to the flag counts as seeing it.
function goToFlag(fl, plan) {
    if (!seenMark(fl, me())) markSeen(fl, true).catch(showError);
    jumpToFlag(fl.id, () => navigate(plan)).catch(showError);
}

// ---- the popup ----

// Closing the popup from the keyboard puts the focus back on the flag
// that opened it, or on its icon drawn again since.
function closePopup(refocus = false) {
    const id = popup?.flagId;
    const from = popup?.opener;
    const home = popup?.home;
    keepEdits();
    popup?.remove();
    popup = null;
    if (!refocus || id == null) return;
    // Icons are drawn again as flags change: find the one in the opener's
    // place, its gutter cell or its card's list.
    const sel = `[data-flag="${id}"]`;
    const to = from?.isConnected ? from : (home?.isConnected && home.querySelector(sel)) || document.querySelector(sel);
    to?.focus({ preventScroll: true });
}

// act names what a button does across redraws, so the focus can stay on it.
function toolButton(label, title, act, onclick) {
    return el('button', {
        class: 'tool', type: 'button', title, 'data-act': act,
        onclick: () => onclick().catch(showError),
    }, label);
}

function commentForm(fl) {
    const d = draftOf(fl);
    const body = drafted(el('textarea', { rows: 2, required: true, placeholder: 'Comment for the agent', 'aria-label': 'Comment for the agent' }), d, 'comment');
    const send = el('button', { type: 'submit' }, 'Add comment');
    return el('form', {
        class: 'form flag-comment',
        onsubmit: async e => {
            e.preventDefault();
            if (send.disabled) return;
            send.disabled = true;
            try {
                await post('api/feedback', { target: 'flag', flag: fl.note_id, body: body.value, iteration: review.iteration });
                d.comment = '';
                body.value = '';
                await refresh();
            }
            catch (err) {
                showError(err);
            }
            send.disabled = false;
        },
    }, body, el('div', { class: 'buttons' }, send));
}

// Drawn again while the focus is in it, the focus stays: on the control of
// the same act, else on the popup. Nothing typed is lost (drafts, edits).
function drawPopup(fl) {
    const focused = popup.contains(document.activeElement) ? document.activeElement : null;
    const act = focused?.dataset.act ?? (focused?.matches('.flag-comment textarea') ? 'comment' : null);
    const seen = !!seenMark(fl, me());
    keepEdits();
    popup.className = 'flag-popup ' + colorClass(fl);
    popup.flagId = fl.id;
    popup.replaceChildren(...[
        // The title wraps; the buttons keep one row, the close button with
        // the speech buttons.
        el('div', { class: 'fb-head' },
            el('span', { class: 'flag-title' },
                icon(fl, false), ' ',
                el('strong', {}, capital(colorText(fl))), ' ',
                el('span', { class: 'meta' }, fl.kind)),
            el('span', { class: 'flag-tools' },
                speakControls(flagText(fl)),
                el('button', { class: 'tool close', title: 'Close', onclick: () => closePopup(true) }, '×'))),
        fl.pending ? el('p', { class: 'flag-pending' }, 'The code under this flag changed; the agent has yet to keep, recolor or retire it.') : null,
        el('p', { class: 'flag-sentence' }, fl.sentence),
        fl.detail ? prose(fl.detail) : null,
        fl.color_reason ? el('p', { class: 'flag-reason' }, el('strong', {}, 'Color changed: '), fl.color_reason) : null,
        el('div', { class: 'flag-state' },
            toolButton(seen ? 'Mark unseen' : 'Mark seen', seen ? 'Show it as new to you again' : 'Mark it seen', 'seen', () => {
                keepMark(fl.id);
                return markSeen(fl, !seen);
            })),
        el('div', { class: 'flag-comments' }, flagComments(review.feedback, fl).map(fb => edits.get(String(fb.id)) ?? feedbackView(fb, '')), commentForm(fl)),
    ].filter(Boolean));
    if (!focused || document.activeElement === focused) return;
    // An edit kept is the same field, moved: it takes the focus back.
    if (popup.contains(focused)) return focused.focus({ preventScroll: true });
    const again = act === 'comment' ? popup.querySelector('.flag-comment textarea') : act && popup.querySelector(`[data-act="${act}"]`);
    (again && !again.disabled ? again : popup).focus({ preventScroll: true });
}

// Opening a flag's popup counts as seeing it. The focus moves into it, so
// its controls are the next Tab away.
function showPopup(fl, anchor) {
    closePopup();
    popup = el('div', { role: 'dialog', 'aria-label': 'Flag', tabindex: -1 });
    popup.opener = anchor;
    popup.home = anchor.closest('td.ln, .flag-slot');
    drawPopup(fl);
    document.body.append(popup);
    const r = anchor.getBoundingClientRect();
    const maxLeft = document.documentElement.clientWidth - popup.offsetWidth - 8;
    popup.style.left = Math.max(8, Math.min(r.left, maxLeft)) + window.scrollX + 'px';
    popup.style.top = r.bottom + window.scrollY + 4 + 'px';
    popup.focus({ preventScroll: true });
    if (!seenMark(fl, me())) markSeen(fl, true).catch(showError);
}

// A click on a gutter flag, or a card's flag line, opens its popup. Returns
// whether the click was one.
const FLAG_OPENER = '.flag-icon[data-flag], .card-flags [data-flag]';

export function flagClick(e) {
    const ic = e.target.closest(FLAG_OPENER);
    if (!ic) return false;
    // An icon drawn before its flag went away (a reload of the review) opens
    // nothing.
    const fl = review.flags.find(x => String(x.id) === ic.dataset.flag);
    if (fl) showPopup(fl, ic);
    return true;
}

// A click in the speech menu (a voice or speed for the flag being read)
// leaves the popup open, and its reading going.
document.addEventListener('click', e => {
    if (popup && e.target.isConnected && !popup.contains(e.target) && !e.target.closest(`${FLAG_OPENER}, #speech_menu`)) closePopup();
});
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closePopup(true);
    else if ((e.key === 'Enter' || e.key === ' ') && e.target.matches?.('.flag-icon[data-flag]')) {
        e.preventDefault();
        e.target.click();
    }
});

// ---- the summary's list ----

function flagWhere(fl) {
    const c = flagEntry(fl, review.commits);
    const at = !c ? 'commit ' + fl.commit.slice(0, 12) : c.topic != null ? c.topic : 'commit ' + c.position;
    return `${at}${fl.path ? ' · ' + fl.path + lineText(fl) : ''}`;
}

// Who has seen the flag, this reviewer as "you".
function flagMarks(fl) {
    const names = (fl.seen || []).map(m => (m.reviewer === me() ? 'you' : m.reviewer));
    return names.length ? el('span', { class: 'flag-marks' }, ' seen by ' + names.join(', ')) : null;
}

function flagItem(fl) {
    const plan = flagPlan(fl, review);
    return el('li', {},
        icon(fl, false), ' ',
        plan ? el('button', { class: 'link', onclick: () => goToFlag(fl, plan) }, fl.sentence) : fl.sentence,
        ' ', el('span', { class: 'meta' }, `${fl.kind}, ${flagWhere(fl)}`), flagMarks(fl));
}

// How many flags a walk would step through: mode 'f' those not seen, 'a'
// all; of one color when given.
function walkCount(mode, color = '') {
    return walkSteps(review.flags, review.commits, me(), mode + color.slice(0, 1)).length;
}

// The two ways to start a walk, with their counts: the flags not seen yet,
// and every flag; each disabled when it has none. Accented
// (the header's and the summary's), the first carries the flag mark.
// buttons, when given, are the pair to set (the header's).
function walkButtons(color = '', accent = false, buttons = null) {
    const [fresh, all] = buttons ?? [0, 1].map(() => el('button', { class: accent ? 'play' : 'tool walk' }));
    const which = color ? color + ' ' : '';
    for (const [b, mode, label, title] of [
        [fresh, 'f', (accent ? '⚑ ' : '') + 'Walk new', `Step through the ${which}flags you have not seen, from the first of them`],
        [all, 'a', 'Walk all', `Step through every ${which}flag, seen ones too, from the first`],
    ]) {
        const count = walkCount(mode, color);
        b.textContent = `${label} (${count})`;
        b.title = title;
        b.disabled = !count;
        b.onclick = e => {
            e.preventDefault();
            playWalk(mode, color || null);
        };
    }
    return [fresh, all];
}

// One color's flags, collapsed to its name until opened, with walks of its
// own. Whether it is open is remembered per browser.
function flagGroup(g) {
    const key = 'flags-' + g.color;
    const box = el('details', { class: 'flag-group flag-' + g.color, open: pref.get(key, '0') === '1', ontoggle: () => pref.set(key, box.open ? '1' : '0') },
        el('summary', {},
            el('span', { class: 'flag-icon flag-' + g.color, title: `${capital(g.color)} flags, ${MEANING[g.color]}` }, '⚑'),
            ` ${capital(g.color)}: ${MEANING[g.color]} `,
            el('span', { class: 'walk-start' }, walkButtons(g.color))),
        el('ul', { class: 'flag-list' }, g.flags.map(flagItem)));
    return box;
}

// The flags, for the review summary, by color, red first, each group in
// commit, path and line order.
export function flagList() {
    return flagSlot('div', () => {
        if (!review.flags.length) return null;
        return el('div', { id: 'flag_list' },
            el('div', { class: 'head' }, el('h3', {}, 'Flags'),
                el('span', { class: 'walk-start' }, walkButtons('', true))),
            flagGroups(sortFlags(review.flags, review.commits)).map(flagGroup));
    });
}

// ---- flag state ----

// Mark a flag seen by this reviewer, or not.
export async function markSeen(fl, seen) {
    fl.seen = (await post(`api/flag/${fl.id}`, { seen })).seen;
    refreshFlags();
}

// Redraw everything drawn from the flags' state: badges, card lists, the
// summary's list, gutters, the open popup, the header and the walker.
export function refreshFlags() {
    for (const slot of document.querySelectorAll('.flag-slot')) fillSlot(slot);
    for (const t of $('main').querySelectorAll(LINE_TABLES)) decorateFlags(t);
    showFlagFocus();
    const fl = popup && review.flags.find(x => x.id === popup.flagId);
    if (fl) drawPopup(fl);
    else closePopup();
    syncWalkButtons();
    showGuide();
}

// The header's Walk new and Walk all, with their counts; hidden with no
// flags.
export function syncWalkButtons() {
    $('walk_start').hidden = !review?.flags.length;
    if (review) walkButtons('', true, [$('walk_new'), $('walk_all')]);
}

// ---- the flag jumped to ----

// A flag link or a walker step marks its flag where it lands: the flagged
// lines, with a callout with its sentence just above them, or for a
// whole-file or commit flag its line on the card, tinted in the flag's color
// with a thick bar. The mark lasts while the URL is the one the
// jump made, so any other navigation, the walker's next step included, drops
// it. On arrival the page scrolls the target below the stuck heads, into the
// upper part of the screen, and the callout pulses.
let focus = null;
// The arrival pulse's length (review.css: four half-second swings).
const PULSE_MS = 2000;
let pulseEnd = 0;

// Jump to flag id by calling nav, which navigates to it.
export async function jumpToFlag(id, nav) {
    focus = { id, hash: null, arrive: true };
    try {
        // A flag's plan sets the URL before navigating awaits anything, so
        // the jump's URL is known now, before the reader can go elsewhere.
        const going = nav();
        if (focus?.id === id) focus.hash = location.hash;
        await going;
    }
    catch (err) {
        focus = null;
        throw err;
    }
}

// Mark the flag jumped to, and drop marks of any other; called as line
// tables fill and once the page settles (settled), which places an arrival
// unless the reader scrolled meanwhile (still false), as apply() does.
export function showFlagFocus(settled = false, still = true) {
    for (const x of document.querySelectorAll('[data-flag-focus]')) x.removeAttribute('data-flag-focus');
    for (const x of document.querySelectorAll('.flag-callout-row, .flag-callout')) x.remove();
    for (const x of document.querySelectorAll('.card-flags .flag-arrive')) x.classList.remove('flag-arrive');
    if (focus?.hash !== location.hash) focus = null;
    const fl = focus && review.flags.find(x => x.id === focus.id);
    const at = fl && focusTarget(fl);
    if (at) for (const x of at.marks) x.dataset.flagFocus = colorClass(fl);
    // Drawn again (a flag's state changed) while it pulses: it pulses on.
    if (at && performance.now() < pulseEnd) at.callout.classList.add('flag-arrive');
    if (!settled || !focus?.arrive) return;
    focus.arrive = false;
    if (!at) return;
    at.callout.classList.add('flag-arrive');
    pulseEnd = performance.now() + PULSE_MS;
    if (still) bringIntoView(at.top);
}

function callout(fl) {
    return el('div', { class: 'flag-callout ' + colorClass(fl), role: 'note' },
        el('span', { class: 'flag-icon ' + colorClass(fl), title: capital(colorText(fl)) }, '⚑'), ' ', el('strong', {}, fl.kind + ':'), ' ', fl.sentence);
}

// What to mark for a flag ({ marks, callout, top }, top the element to
// scroll to), placing the callout; null while the target is not drawn.
function focusTarget(fl) {
    const plan = flagPlan(fl, review);
    if (!plan) return null;
    let card;
    if (plan.type === 'commit') {
        const box = $('c' + plan.commit.id);
        card = box?.matches('.card') ? box : box?.querySelector(':scope > .card');
    }
    else card = $(plan.type === 'blob' ? 'b' + plan.commit.id : 'f' + plan.file.id);
    if (!card) return null;
    if (plan.reveal) {
        const panel = card.querySelector(':scope > .panel');
        if (!panel || panel.querySelector(':scope > .loading')) return null;
        const table = panel.querySelector('table');
        const at = table && lineTarget(fl, table, plan.reveal.side);
        if (at) return at;
    }
    // A whole-file or commit flag, or lines its panel does not show (no line
    // changes, a binary file, an error): its line on the card, or, on a card
    // with none (a file its commit did not change), a callout under the head.
    const line = card.querySelector(`:scope > .flag-slot > .card-flags [data-card-flag="${fl.id}"]`);
    if (line) return { marks: [line], callout: line, top: line };
    const head = card.querySelector(':scope > .head');
    if (!head) return null;
    const note = callout(fl);
    head.after(note);
    return { marks: [head], callout: note, top: card };
}

// The flagged rows of a line table, or their side's cells side by side, and
// a callout row above the first.
function lineTarget(fl, table, side) {
    const split = table.classList.contains('split');
    const rows = [];
    for (let n = fl.line_start; n <= (fl.line_end ?? fl.line_start); n++) {
        const row = table.querySelector(`tr[data-${side}="${n}"]`);
        if (row) rows.push(row);
    }
    if (!rows.length) return null;
    const note = callout(fl);
    const tr = el('tr', { class: 'flag-callout-row' }, el('td', { colspan: rows[0].cells.length }, note));
    rows[0].before(tr);
    const marks = split ? rows.flatMap(r => (side === 'old' ? [r.cells[0], r.cells[1]] : [r.cells[2], r.cells[3]])) : rows;
    return { marks, callout: note, top: tr };
}

// Scroll el into the upper part of the screen, below the heads stuck over
// it (the stack its --cards counts); a whole-file view scrolls in
// its own box first.
function bringIntoView(target) {
    const box = target.closest('.panel.view');
    if (box) box.scrollTop += target.getBoundingClientRect().top - box.getBoundingClientRect().top - 40;
    const cs = getComputedStyle(target);
    const v = name => parseFloat(cs.getPropertyValue(name)) || 0;
    const stuck = v('--header-h') + v('--cards') * v('--head-h');
    window.scrollBy(0, target.getBoundingClientRect().top - Math.max(stuck + 16, innerHeight / 4));
}
