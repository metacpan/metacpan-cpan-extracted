// Reading agent prose aloud with the browser's Web Speech API: the header's
// speech menu (voice and speed), and a play/pause and a stop button for each
// block of prose.
//
// One reading plays at a time. A reading is spoken a sentence at a time and
// remembers the sentence it is on, as the API's own pause and resume are
// unreliable (Chrome cuts long utterances off; cancel forgets the place).
// Pausing keeps that place and play resumes from that sentence; stopping, or
// reaching the end, goes back to the start. Starting another reading pauses
// the one playing, and so does its buttons leaving the page (a popup
// closed, a card collapsed), so nothing reads on with no way to stop it.
// Speech only ever uses the voice picked in the menu, or an on-device
// default: never the browser's own default, which may be online.
import { $, el, pref } from './app.js';
import { orderVoices, speechSentences } from './logic.js';

const synth = window.speechSynthesis;
let voices = [];
// Readings by their text and by id: { id, text, sentences, at, paused },
// at the sentence to speak next, paused whether it stopped part way (in its
// first sentence too).
const readings = new Map();
const byId = new Map();
let playing = null;
// The utterance being spoken: a cancel ends an utterance with an end or
// error event, so only this one moves its reading on.
let current = null;
// The text asked for while no voice was picked (or none had loaded yet);
// a voice picked or loaded plays it, while its buttons are on the page.
let waiting = null;

function reading(text) {
    let r = readings.get(text);
    if (!r) {
        r = { id: readings.size + 1, text, sentences: speechSentences(text), at: 0, paused: false };
        readings.set(text, r);
        byId.set(String(r.id), r);
    }
    return r;
}

// Whether a reading's buttons are on the page.
function onPage(r) {
    return !!document.querySelector(`.speak[data-speak="${r.id}"]`);
}

// A reading whose buttons left the page pauses, and a wait for one ends.
new MutationObserver(() => {
    if (playing && !onPage(playing)) pause();
    if (waiting != null && !onPage(reading(waiting))) waiting = null;
}).observe(document.documentElement, { childList: true, subtree: true });

// Play what waited for a voice, now there is one.
function playWaiting() {
    if (waiting != null && voice() && onPage(reading(waiting))) play(waiting, false);
}

function voice() {
    return voices.find(x => x.voice.voiceURI === $('speech_voice').value)?.voice ?? null;
}

// Play text's reading from where it stopped. With no voice picked it waits
// for one; ask opens the speech menu to pick it.
export function play(text, ask = true) {
    const r = reading(text);
    if (!voice()) {
        waiting = text;
        if (ask) $('speech_menu').open = true;
        return;
    }
    waiting = null;
    if (playing === r) return;
    halt();
    playing = r;
    say();
}

// Play text's reading from its start: the guide bar's reading of each step.
export function playFromStart(text, ask = true) {
    Object.assign(reading(text), { at: 0, paused: false });
    if (playing?.text === text) halt();
    play(text, ask);
}

// Pause whatever plays, keeping its place.
export function pause() {
    halt();
    sync();
}

// Stop text's reading, back to its start.
export function stop(text) {
    const r = reading(text);
    if (waiting === text) waiting = null;
    if (playing === r) halt();
    Object.assign(r, { at: 0, paused: false });
    sync();
}

function halt() {
    current = null;
    if (!playing) return;
    playing.paused = true;
    playing = null;
    synth?.cancel();
}

function say() {
    const r = playing;
    if (r.at >= r.sentences.length) {
        Object.assign(r, { at: 0, paused: false });
        playing = null;
        return sync();
    }
    // The voice gone (the browser's list changed), the menu fell back to
    // the default; with none, the reading pauses.
    const v = voice();
    if (!v) return pause();
    const u = new SpeechSynthesisUtterance(r.sentences[r.at]);
    u.voice = v;
    u.lang = v.lang;
    u.rate = Number($('speech_rate').value);
    u.onend = () => {
        if (current !== u) return;
        r.at++;
        say();
    };
    // A failure (no voice after all, a browser refusing to speak without
    // a click first) pauses the reading where it was.
    u.onerror = () => {
        if (current === u) pause();
    };
    current = u;
    synth.speak(u);
    sync();
}

// A block's buttons: play or pause, and stop. Null for no text.
export function speakControls(text) {
    if (!String(text ?? '').trim()) return null;
    const r = reading(text);
    const box = el('span', { class: 'speak', 'data-speak': r.id },
        el('button', { type: 'button', class: 'tool speak-play', 'data-act': 'speak-play', onclick: () => (playing === r ? pause() : play(text)) }),
        el('button', { type: 'button', class: 'tool speak-stop', 'data-act': 'speak-stop', title: 'Stop reading, back to the start', 'aria-label': 'Stop reading', onclick: () => stop(text) },
            el('span', { class: 'stop-mark', 'aria-hidden': 'true' })));
    syncBox(box);
    return box;
}

function syncBox(box) {
    const r = byId.get(box.dataset.speak);
    const on = playing === r;
    const [go, end] = box.children;
    go.replaceChildren(on ? el('span', { class: 'pause-mark', 'aria-hidden': 'true' }) : '▶︎');
    go.title = on ? 'Pause reading' : r.paused ? 'Resume reading' : 'Read aloud';
    go.setAttribute('aria-label', go.title);
    go.classList.toggle('active', on);
    end.disabled = !on && !r.paused;
    box.classList.toggle('playing', on);
}

function sync() {
    for (const box of document.querySelectorAll('.speak[data-speak]')) syncBox(box);
}

// ---- the header's speech menu ----

// With no voices the menu says why. With no remembered voice and no
// on-device one, the picker starts on "Pick a voice". Browsers may list
// their voices late, so this runs again on voiceschanged.
function loadVoices() {
    const { list, dflt } = orderVoices(synth?.getVoices() ?? [], document.documentElement.lang || navigator.language);
    voices = list;
    $('speech_hint').hidden = !!list.length;
    $('speech_opts').hidden = !list.length;
    const saved = pref.get('voice', '');
    const pick = list.find(x => x.voice.voiceURI === saved) || dflt;
    const option = (value, label, selected) => el('option', { value, selected, disabled: !value }, label);
    $('speech_voice').replaceChildren(
        ...(list.length && !pick ? [option('', 'Pick a voice', true)] : []),
        ...list.map(x => option(x.voice.voiceURI, x.label, x === pick)));
    document.dispatchEvent(new Event('voices'));
    playWaiting();
}

// Whether the browser has a voice to read with.
export function hasVoices() {
    return voices.length > 0;
}

export function speechHint() {
    return $('speech_hint').textContent;
}

function showRate() {
    $('speech_rate_val').textContent = Number($('speech_rate').value).toFixed(2) + '×';
}

export function setupSpeech() {
    $('speech_rate').value = Math.min(1.5, Math.max(0.75, Number(pref.get('rate', '1')) || 1));
    showRate();
    loadVoices();
    synth?.addEventListener('voiceschanged', loadVoices);
    // Picking a voice plays what waited for one, or goes on in it from the
    // sentence playing.
    $('speech_voice').addEventListener('change', e => {
        pref.set('voice', e.target.value);
        const was = playing;
        if (waiting != null) playWaiting();
        else if (was) {
            halt();
            playing = was;
            say();
        }
    });
    $('speech_rate').addEventListener('input', e => {
        pref.set('rate', e.target.value);
        showRate();
    });
}
