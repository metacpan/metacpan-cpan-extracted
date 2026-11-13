// The guide bar, step navigation, highlights, and speech.
//
// Playing enters guide mode at step 1; after that only next and back move.
// Steps set the same view state a click would, plus g (the step) in the URL,
// so exploring by hand keeps the step and next carries on from it. A step
// records in the URL (u) what it changed: the panels it opened, the files and
// sections it expanded, the commit tab it switched to show its target.
// Moving off a step, to another or out of guide mode, undoes exactly that;
// what the reader had open before stays open.
//
// The flag walker is the same bar playing a list of flag steps instead of the
// guide (w in the URL). Moving off a flag, or leaving the walk, marks it seen.
// While walking, g is the flag's id, not its place in the list, so a reload
// stays on the same flag. The list is made when the walk starts or the page
// loads, so marking a flag keeps it in place until then; one made on load
// keeps the flag g names even when it is seen.
// Each flag step marks its flag where it lands (flags.js's jumpToFlag).
import { $, el, review, tree, state, go, navigate, LINE_TABLES, lineSource, pref, showError } from './app.js';
import { stepPlan, inRanges, undoChanges, walkSteps, seenMark, topicJumps } from './logic.js';
import { markSeen, jumpToFlag, flagText } from './flags.js';
import { playFromStart, stop, speakControls, hasVoices, speechHint } from './speech.js';

let shownStep = null;
// The text the bar read for the step it showed last.
let shownText = null;
let walk = { review: null, w: null, steps: [] };

// fresh makes a new walk list, without keeping the current flag.
function steps(w = state.w, fresh = false) {
    if (!w) return review?.guide || [];
    if (fresh || walk.review !== review || walk.w !== w) {
        const keep = fresh ? null : state.g;
        walk = { review, w, steps: review ? walkSteps(review.flags, review.commits, review.identity?.reviewer, w, keep) : [] };
    }
    return walk.steps;
}

function currentStep() {
    if (!state.g) return null;
    if (!state.w) return state.g <= steps().length ? state.g : null;
    const i = steps().findIndex(x => x.flag === state.g);
    return i < 0 ? null : i + 1;
}

// Undo in view state s what the step it shows changed.
function leaveStep(s) {
    undoChanges(s, s.u, tree);
    s.u = [];
}

// The flag of the walk step shown, or null.
function walkFlag() {
    const n = state.w && currentStep();
    return n ? review.flags.find(x => x.id === steps()[n - 1].flag) ?? null : null;
}

// The walk's flag last shown, and the flags whose seen mark the reader set
// by hand while the walk showed them: the reader's choice holds for the rest
// of the walk.
let walkShown = null;
const chosen = new Set();

// The reader set flag id's seen mark by hand; while the walk shows it, the
// walk leaves the mark as set.
export function keepMark(id) {
    if (walkFlag()?.id === id) chosen.add(id);
}

// The walk has left flag id (next, back, exit, the browser's Back, another
// walk): it is seen, unless the reader set its mark by hand during the walk.
// A flag of another iteration (the reader switched it) is not looked for.
function passed(id) {
    const fl = review?.flags.find(x => x.id === id);
    if (fl && !chosen.has(id) && !seenMark(fl, review.identity?.reviewer)) markSeen(fl, true).catch(showError);
}

// Show step n of the guide (w null) or of a flag walk.
async function gotoStep(n, w = state.w) {
    const step = steps(w)[n - 1];
    if (!step) return;
    const g = w ? step.flag : n;
    const plan = stepPlan(step, review);
    const first = s => {
        leaveStep(s);
        s.w = w;
    };
    try {
        // A step whose target is missing still shows its commentary.
        if (plan && w) await jumpToFlag(step.flag, () => navigate(plan, g, first));
        else if (!plan || await navigate(plan, g, first) === false) go(s => {
            first(s);
            s.g = g;
        }, state.at);
    }
    catch (err) {
        showError(err);
    }
}

export function playGuide() {
    if (steps(null).length) gotoStep(1, null);
}

// Walk the flags: mode 'f' those not seen yet, 'a' all of them; of one
// color when given. Each starts at its list's first flag.
export function playWalk(mode, color = null) {
    const w = mode + (color?.[0] ?? '');
    if (steps(w, true).length) gotoStep(1, w);
}

// Where the guide's topic (or commit) buttons go from step n: logic.js
// topicJumps, each step's group being the entry its target is on. None in
// a walk.
function jumps(n) {
    if (state.w || !n) return { next: null, prev: null };
    return topicJumps(steps().map(s => stepPlan(s, review)?.commit?.id ?? null), n);
}

function syncJumps(n) {
    const { next, prev } = jumps(n);
    const word = review.commits.some(c => c.topic != null) ? 'topic' : 'commit';
    $('guide_prev_topic').hidden = prev == null;
    $('guide_next_topic').hidden = next == null;
    $('guide_topics').hidden = prev == null && next == null;
    // On a phone only the arrows show (review.css), the title saying the rest.
    $('guide_prev_topic').replaceChildren('«', el('span', { class: 'wide' }, ` previous ${word}`));
    $('guide_next_topic').replaceChildren(el('span', { class: 'wide' }, `next ${word} `), '»');
    $('guide_prev_topic').setAttribute('aria-label', `previous ${word}`);
    $('guide_next_topic').setAttribute('aria-label', `next ${word}`);
    $('guide_prev_topic').title = `Go to the first step of the ${word} before this one`;
    $('guide_next_topic').title = `Go to the next step on another ${word}`;
}

// The walker's controls for the flag of step n.
function syncWalk(n) {
    const step = state.w && n ? steps()[n - 1] : null;
    $('walk_opts').hidden = !step;
    if (!step) return;
    const fl = review.flags.find(x => x.id === step.flag);
    const me = review.identity?.reviewer;
    const mine = !!(fl && seenMark(fl, me));
    $('walk_mark').textContent = mine ? 'Mark unseen' : 'Mark seen';
    $('walk_mark').classList.toggle('active', mine);
    $('walk_mark').setAttribute('aria-pressed', mine);
    const others = (fl?.seen || []).filter(m => m.reviewer !== me).map(m => m.reviewer);
    $('walk_marks').textContent = others.length ? 'Seen by ' + others.join(', ') : '';
}

async function toggleMark() {
    const fl = walkFlag();
    if (!fl) return;
    keepMark(fl.id);
    try {
        await markSeen(fl, !seenMark(fl, review.identity?.reviewer));
    }
    catch (err) {
        showError(err);
    }
}

// Leave guide mode, or the walk.
function exitGuide() {
    go(s => {
        leaveStep(s);
        s.g = null;
        s.w = null;
    }, state.at);
}

// Sync the bar with the URL; called after every view change. A walk whose
// list lacks its flag (Back to a flag a newer list left out) makes the list
// again keeping it. One at a flag the review does not have is left, replacing
// the history entry so Back is not trapped there.
export function showGuide() {
    let n = currentStep();
    if (state.w && state.g && !n && review && review.flags.some(x => x.id === state.g)) {
        walk = { review: null, w: null, steps: [] };
        n = currentStep();
    }
    if (state.w && state.g && !n && review) return go(s => {
        leaveStep(s);
        s.g = null;
        s.w = null;
    }, state.at, null, null, true);
    // Whichever way the walk moved off a flag, that flag is seen.
    const now = state.w && n ? steps()[n - 1].flag : null;
    if (walkShown != null && walkShown !== now) passed(walkShown);
    walkShown = now;
    if (!state.w) chosen.clear();
    $('guide_bar').hidden = !n;
    document.body.classList.toggle('guiding', !!n);
    syncWalk(n);
    // The flag too: a walk made again can put another flag at the same step.
    const shown = n && `${state.w || ''}${n}/${steps().length}:${steps()[n - 1].flag ?? ''}`;
    if (shown === shownStep) return;
    shownStep = shown;
    // The step left stops being read.
    if (shownText != null) stop(shownText);
    shownText = null;
    syncSpeech();
    for (const t of $('main').querySelectorAll(LINE_TABLES)) applyHighlights(t);
    if (!n) return;
    const step = steps()[n - 1];
    shownText = stepText(n);
    $('guide_text').textContent = step.commentary;
    $('guide_speak').replaceChildren(speakControls(shownText) ?? '');
    $('guide_count').textContent = `${n} / ${steps().length}`;
    $('guide_back').disabled = n === 1;
    $('guide_next').disabled = n === steps().length;
    syncJumps(n);
    if (speechOn()) playFromStart(shownText, false);
}

// Tint the current step's highlight ranges in a line table.
export function applyHighlights(table) {
    for (const x of table.querySelectorAll('.hl')) x.classList.remove('hl');
    const n = currentStep();
    if (!n) return;
    const step = steps()[n - 1];
    const revision = stepPlan(step, review)?.commit?.revision;
    const { revision: trev, path } = lineSource(table);
    if (!revision || revision !== trev) return;
    const split = table.classList.contains('split');
    for (const h of step.highlight || []) {
        if (h.path !== path) continue;
        for (const row of table.querySelectorAll(`tr[data-${h.side}]`)) {
            if (!inRanges(Number(row.dataset[h.side]), [h.lines])) continue;
            // Side by side, only the cells of the highlighted side.
            const cells = !split ? [row] : h.side === 'old' ? [row.cells[0], row.cells[1]] : [row.cells[2], row.cells[3]];
            for (const c of cells) c.classList.add('hl');
        }
    }
}

// ---- speech ----

// The guide and the walker each have their own speech toggle, off by
// default: on, each step is read aloud as it shows (a flag: its sentence
// and detail).
function speechKey() {
    return state.w ? 'speech-walk' : 'speech';
}

function speechOn() {
    return pref.get(speechKey(), '0') === '1';
}

// What the bar reads for step n: a guide step's commentary, a flag's
// sentence and detail.
function stepText(n) {
    const step = n && steps()[n - 1];
    if (!step) return null;
    if (!state.w) return step.commentary;
    const fl = review.flags.find(x => x.id === step.flag);
    return fl ? flagText(fl) : step.commentary;
}

function syncSpeech() {
    const on = speechOn() && hasVoices();
    const t = $('speech_toggle');
    t.classList.toggle('active', on);
    t.setAttribute('aria-pressed', on);
    t.disabled = !hasVoices();
    t.title = !hasVoices() ? speechHint() : state.w ? 'Read each flag aloud as it arrives' : 'Read each step aloud as it shows';
}

function setupBarSpeech() {
    document.addEventListener('voices', syncSpeech);
    syncSpeech();
    $('speech_toggle').addEventListener('click', () => {
        pref.set(speechKey(), speechOn() ? '0' : '1');
        syncSpeech();
        const text = stepText(currentStep());
        if (!text) return;
        if (speechOn()) playFromStart(text);
        else stop(text);
    });
}

export function setupGuide() {
    $('guide_back').addEventListener('click', () => gotoStep(currentStep() - 1));
    $('guide_next').addEventListener('click', () => gotoStep(currentStep() + 1));
    $('guide_next_topic').addEventListener('click', () => gotoStep(jumps(currentStep()).next));
    $('guide_prev_topic').addEventListener('click', () => gotoStep(jumps(currentStep()).prev));
    // Back to the current step after exploring, and read it again.
    $('guide_replay').addEventListener('click', () => {
        shownStep = null;
        gotoStep(currentStep());
    });
    $('guide_exit').addEventListener('click', exitGuide);
    $('walk_mark').addEventListener('click', toggleMark);
    setupBarSpeech();
}
