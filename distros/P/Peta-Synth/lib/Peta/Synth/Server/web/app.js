// Peta::Synth's page: plays what the server renders and sets the synth up
// while it sounds. Everything goes over one WebSocket: JSON for control,
// binary frames (interleaved stereo float32) for sound.
'use strict';

const $ = (id) => document.getElementById(id);
const el = (tag, props = {}, ...children) => {
  const node = Object.assign(document.createElement(tag), props);
  for (const child of children) node.append(child);
  return node;
};

// A colour of the style sheet's, for the canvases.
const colour = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();

// The editor's groups, and the order it shows them in: what shapes every
// sound first, what only some sounds use after. list is the formants (or
// the patch's own partials), mods the modulation routes.
const GROUPS = {
  spectrum: 'Spectrum',
  partials: 'Partials over time',
  envelope: 'Envelope',
  pitch: 'Pitch and modulation',
  unison: 'Unison',
  noise: 'Noise',
  noise2: 'Noise, second band',
  noise3: 'Noise, third band',
  string: 'String (plucked or struck)',
  fm: 'FM',
  op1: 'FM operator 1',
  op2: 'FM operator 2',
  op3: 'FM operator 3',
  op4: 'FM operator 4',
  filter: 'Filter',
  env2: 'Second envelope',
  lfo: 'LFOs',
};
const ORDER = [
  'envelope', 'spectrum', 'list', 'filter', 'env2', 'pitch', 'lfo', 'mods',
  'partials', 'unison', 'noise', 'noise2', 'noise3', 'string', 'fm', 'op1', 'op2', 'op3', 'op4',
];

const app = {
  ws: null,
  init: null,
  channels: [],
  selected: 0,
  drumKey: 38,
  patch: null,
  audio: null,
  octave: 4,                 // the keyboard's lowest C: C4 is MIDI 60
  down: new Map(),           // key → pointer or computer key that holds it
  pending: new Map(),        // field → value, sent once a frame
  playing: null,             // the file playing, as the state says
  seeking: null,             // the position the bar is dragged to
  recording: false,
  wantFile: null,            // a file to select once the list has it
};

// The connection.

function connect() {
  const ws = new WebSocket(`ws://${location.host}/ws`);
  ws.binaryType = 'arraybuffer';
  ws.onopen = () => {
    $('link').classList.add('up');
    send({ type: 'hello' });
  };
  ws.onclose = () => {
    $('link').classList.remove('up');
    if (app.audio) stopAudio();
    setTimeout(connect, 1000);
  };
  ws.onmessage = (event) => {
    if (event.data instanceof ArrayBuffer) {
      if (app.audio) app.audio.node.port.postMessage(new Float32Array(event.data));
      return;
    }
    const message = JSON.parse(event.data);
    const handler = handlers[message.type];
    if (handler) handler(message);
  };
  app.ws = ws;
}

function send(message) {
  if (app.ws && app.ws.readyState === WebSocket.OPEN) app.ws.send(JSON.stringify(message));
}

// What the server sends, by type.
const handlers = {
  init(m) {
    app.init = m;
    app.channels = m.channels;
    const p = m.perl;
    const has = [p.jit && 'JIT', p.pdl && 'PDL', p.gpu && 'GPU'].filter(Boolean);
    $('perl').textContent = [`${p.perl} ${p.version}`, ...has, `${p.cpus} CPUs`].join(' · ');
    $('engine').textContent = m.engine;
    $('rate').textContent = `${m.rate / 1000} kHz`;
    $('bank-save').disabled = !m.bank;
    $('bank-save').title = m.bank ? `save every change to ${m.bank}` : 'start the server with --bank FILE to save';
    fillFiles(m.files);
    buildChannels();
    buildMaster();
    buildReverb();
    app.channelEq = structuredClone(m.channel_eq);
    app.arp = m.arp;
    buildArp();
    buildEq();
    buildDrumKeys();
    buildKeyChannels();
    selectChannel(app.selected);
  },

  state(m) {
    // Padded with figure spaces (a digit wide), so that what follows stays where it is.
    $('voices').textContent = String(m.voices).padStart(3, FIGURE_SPACE);
    $('partials').textContent = String(m.partials).padStart(3, FIGURE_SPACE);
    const load = Math.round(m.load * 100);
    $('load').textContent = `${load}%`.padStart(4, FIGURE_SPACE);
    const bar = $('load-bar');
    bar.style.width = `${Math.min(100, load)}%`;
    bar.style.background = load > 75 ? 'var(--bad)'
                         : load > 50 ? 'var(--accent)'
                         :             'var(--good)';
    m.level.forEach((level, i) => {
      const meter = document.querySelector(`#strip-${i} .level i`);
      if (meter) meter.style.height = `${Math.min(100, Math.sqrt(level) * 100)}%`;
    });
    updateChannels(m.channels);
    updateArp(m.arps);
    app.playing = m.playing;
    showPosition();
    showRecording(m.recording);
  },

  channels(m) {
    updateChannels(m.channels);
  },

  patch(m) {
    if (!isCurrentPatch(m.kind, m.number, m.bank)) return;
    app.patch = m;
    buildEditor();
  },

  // A field another page changed.
  patch_field(m) {
    if (!app.patch || !isCurrentPatch(m.kind, m.number, m.bank)) return;
    if (m.field === 'formants' || m.field === 'partials' || m.field === 'mods') {
      app.patch[m.field] = m.value;
      buildEditor();
      return;
    }
    app.patch.fields[m.field] = m.value;
    const field = document.querySelector(`[data-field="${m.field}"]`);
    if (field) field.update(m.value);
    drawPreviews();
  },

  files(m) { fillFiles(m.files); },

  saved(m) { toast(`saved to ${m.file}`); },
  recorded(m) {
    toast(`recorded into ${m.file}`);
    selectFile(m.file);
  },
  error(m) { toast(m.message, true); },
};

const FIGURE_SPACE = ' ';
const PLAY = '▶︎';
const PAUSE = '❚❚';

// Where the file is, or where the bar is dragged to; the button plays or pauses.
function showPosition() {
  const playing = app.playing;
  const running = playing && !playing.paused;
  $('play').textContent = running ? PAUSE : PLAY;
  $('play').title = running ? 'pause' : 'play';
  if (!playing) {
    $('progress').style.width = '0';
    $('position').textContent = '';
    return;
  }
  const { length, file } = playing;
  const position = Math.min(app.seeking ?? playing.position, length);
  $('progress').style.width = `${Math.max(0, Math.min(100, 100 * position / (length || 1)))}%`;
  $('position').textContent = `${file} · ${clock(Math.max(0, position))} / ${clock(length)}${playing.paused ? ' · paused' : ''}`;
}

function showRecording(seconds) {
  const record = $('record');
  app.recording = seconds != null;
  record.classList.toggle('on', app.recording);
  record.textContent = app.recording ? `■ ${clock(seconds)}` : '● Record';
}

function clock(seconds) {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function toast(text, error = false) {
  const t = $('toast');
  t.textContent = text;
  t.classList.toggle('error', error);
  t.classList.add('show');
  clearTimeout(t.timer);
  t.timer = setTimeout(() => t.classList.remove('show'), error ? 5000 : 2500);
}

// Sound: an AudioWorklet fed with the server's frames; it reports what it has played.

// The spectrum from an analyser for each range, each a length of FFT: a
// partial is as many hertz wide as its analyser's bins, so the bass gets the
// longest (bins of 1.5 Hz at 48 kHz, 0.7 s of sound), the highs the shortest
// (23 Hz, 43 ms), and a partial is about as wide on the log scale low as
// high. [length, the frequency it serves below]; the last also the scope's.
const SPECTRUM_BANDS = [[32768, 300], [16384, 1000], [8192, 3000], [2048, Infinity]];

async function startAudio() {
  const ctx = new AudioContext({ sampleRate: app.init.rate, latencyHint: 'interactive' });
  await ctx.audioWorklet.addModule('worklet.js');
  const node = new AudioWorkletNode(ctx, 'peta-synth-player', { outputChannelCount: [2] });
  node.connect(ctx.destination);
  const analysers = SPECTRUM_BANDS.map(([size, below]) => {
    const analyser = ctx.createAnalyser();
    analyser.fftSize = size;
    node.connect(analyser);
    return { analyser, below, bins: new Float32Array(analyser.frequencyBinCount) };
  });
  node.port.onmessage = (event) => send({ type: 'played', frames: event.data.played });
  app.audio = { ctx, node, analysers };
  send({ type: 'audio', on: true });
  $('audio').textContent = '■ Stop sound';
  $('audio').classList.remove('primary');
  requestAnimationFrame(drawSound);
}

function stopAudio() {
  send({ type: 'audio', on: false });
  if (app.audio) app.audio.ctx.close();
  app.audio = null;
  for (const id of ['scope', 'analyser']) {
    const canvas = $(id);
    canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
  }
  $('audio').textContent = '▶ Start sound';
  $('audio').classList.add('primary');
}

function startAudioOrSay() {
  startAudio().catch((e) => toast(`no sound: ${e.message}`, true));
}

$('audio').onclick = () => (app.audio ? stopAudio() : startAudioOrSay());

// What plays, as it plays: the wave, and its spectrum on a log scale.
function drawSound() {
  if (!app.audio) return;
  const { analysers } = app.audio;

  const scope = $('scope');
  const g = scope.getContext('2d');
  const last = analysers[analysers.length - 1].analyser;
  const wave = new Float32Array(last.fftSize);
  last.getFloatTimeDomainData(wave);
  g.clearRect(0, 0, scope.width, scope.height);
  g.strokeStyle = colour('--accent-2');
  g.beginPath();
  for (let i = 0; i < scope.width; i++) {
    const v = wave[Math.floor(i * wave.length / scope.width)];
    const y = scope.height / 2 - v * scope.height / 2;
    if (i) g.lineTo(i, y);
    else g.moveTo(i, y);
  }
  g.stroke();

  const spec = $('analyser');
  const h = spec.getContext('2d');
  h.clearRect(0, 0, spec.width, spec.height);
  h.fillStyle = colour('--accent');
  const nyquist = app.audio.ctx.sampleRate / 2;
  for (const a of analysers) a.analyser.getFloatFrequencyData(a.bins);
  const hz = (x) => 20 * Math.pow(nyquist / 20, x / spec.width);
  for (let x = 0; x < spec.width; x++) {
    // The loudest of the bins the pixel covers (many, high up), or the one it
    // falls on, in the analyser for its frequency.
    const { bins } = analysers.find((a) => hz(x) < a.below);
    const bin = (f) => Math.min(bins.length - 1, Math.round(f / nyquist * bins.length));
    const [from, to] = [bin(hz(x)), bin(hz(x + 1))];
    let db = bins[from];
    for (let b = from + 1; b < to; b++) db = Math.max(db, bins[b]);
    const height = Math.max(0, (db + 100) / 100) * spec.height;
    h.fillRect(x, spec.height - height, 1, height);
  }
  requestAnimationFrame(drawSound);
}

// Files and the transport.

function fillFiles(files) {
  const select = $('files');
  const was = select.value;
  select.replaceChildren(...files.map((f) => el('option', { value: f, textContent: f })));
  if (!files.length) select.append(el('option', { value: '', textContent: 'no MIDI files yet: drop one below' }));
  if (files.includes(was)) select.value = was;
  if (files.includes(app.wantFile)) {
    select.value = app.wantFile;
    app.wantFile = null;
  }
}

// A file selected now if the list has it, or when the list comes that has it.
function selectFile(name) {
  const select = $('files');
  if ([...select.options].some((o) => o.value === name)) select.value = name;
  else app.wantFile = name;
}

// One button plays and pauses: playing, it pauses; paused, it goes on, or
// plays the file chosen meanwhile from its start; else it plays the file chosen.
$('play').onclick = () => {
  const playing = app.playing;
  if (playing && !playing.paused) return send({ type: 'pause', on: true });
  if (!$('files').value) return toast('choose a MIDI file first', true);
  if (!app.audio) startAudioOrSay();
  if (playing && playing.file === $('files').value) return send({ type: 'pause', on: false });
  send({ type: 'play', file: $('files').value });
};
$('stop').onclick = () => send({ type: 'stop' });
$('panic').onclick = () => send({ type: 'panic' });
$('reset').onclick = () => {
  if (confirm('Reset everything to how the server started: the channels, the mixer, the effects, the arpeggiators? The instruments keep their changes.')) send({ type: 'reset' });
};
$('record').onclick = () => {
  if (!app.recording && !app.audio) startAudioOrSay();
  send({ type: 'record', on: !app.recording });
};

// The bar: pressed or dragged, the file goes on from there when it is let go.
const seek = $('seek');
const seekTo = (e) => {
  const box = seek.getBoundingClientRect();
  app.seeking = Math.max(0, Math.min(1, (e.clientX - box.left) / box.width)) * app.playing.length;
  showPosition();
};
seek.onpointerdown = (e) => {
  if (!app.playing) return;
  seek.setPointerCapture(e.pointerId);
  seekTo(e);
};
seek.onpointermove = (e) => {
  if (app.seeking != null && app.playing) seekTo(e);
};
seek.onpointerup = () => {
  if (app.seeking == null) return;
  send({ type: 'seek', position: app.seeking });
  app.playing.position = app.seeking;    // until the state says where it is
  app.seeking = null;
};
seek.onpointercancel = () => {
  app.seeking = null;
  showPosition();
};

async function upload(file) {
  const response = await fetch(`/upload?name=${encodeURIComponent(file.name)}`, { method: 'POST', body: file });
  if (!response.ok) return toast(`${file.name}: ${(await response.text()).trim()}`, true);
  const { saved } = await response.json();
  toast(`${saved} uploaded`);
  selectFile(saved);
}

// A file dropped anywhere on the page is uploaded (the drop zone's too,
// as its drop goes on to the page).
document.body.ondragover = (e) => e.preventDefault();
document.body.ondrop = (e) => {
  e.preventDefault();
  for (const file of e.dataTransfer.files) upload(file);
};

const drop = $('drop');
drop.ondragover = (e) => {
  e.preventDefault();
  drop.classList.add('over');
};
drop.ondragleave = () => drop.classList.remove('over');
drop.ondrop = () => drop.classList.remove('over');
$('upload').onchange = (e) => {
  for (const file of e.target.files) upload(file);
};

// The channels.

// The controllers a channel's sliders send, and what a double-click sets them to.
const STRIP_SLIDERS = [
  { number: 7, field: 'volume', reset: 100, title: 'volume (CC7); double-click: 100' },
  { number: 10, field: 'pan', reset: 64, title: 'pan (CC10); double-click: centre' },
  { number: 91, field: 'send', reset: 40, title: 'reverb send (CC91); double-click: 40' },
  { number: 93, field: 'chorus', reset: 0, title: 'chorus (CC93): detuned copies of the partials, for the next notes; double-click: 0' },
];

function programName(n) { return `${n + 1} ${app.init.programs[n]}`; }

// The instrument chooser: General MIDI's sixteen families, each an icon,
// and under them the eight programs of the family pointed at, each with its
// variations; on a drum channel, the kits.
const FAMILIES = [
  ['Piano', 'piano'], ['Chromatic perc.', 'bell'], ['Organ', 'organ'], ['Guitar', 'guitar'],
  ['Bass', 'bass'], ['Strings', 'violin'], ['Ensemble', 'choir'], ['Brass', 'trumpet'],
  ['Reed', 'sax'], ['Pipe', 'flute'], ['Synth lead', 'saw'], ['Synth pad', 'pad'],
  ['Synth effects', 'sparkle'], ['Ethnic', 'banjo'], ['Percussive', 'conga'], ['Sound effects', 'speaker'],
];

// Line drawings on a 24 × 24 grid, in the text's colour.
const ICONS = {
  piano: '<rect x="2.5" y="6" width="19" height="12" rx="1.5"/><path d="M7.25 6v12M12 6v12M16.75 6v12"/>'
    + '<path d="M6 6h2.5v6.5H6zM10.75 6h2.5v6.5h-2.5zM15.5 6h2.5v6.5h-2.5z" fill="currentColor" stroke="none"/>',
  bell: '<path d="M6 16.5c1.2-1.2 1.5-3 1.5-6a4.5 4.5 0 0 1 9 0c0 3 .3 4.8 1.5 6z"/><path d="M10 19.5a2 2 0 0 0 4 0M12 4v2"/>',
  organ: '<path d="M3 20h18"/><rect x="4" y="11" width="3" height="9" rx="1.5"/><rect x="8.5" y="5" width="3" height="15" rx="1.5"/>'
    + '<rect x="13" y="8" width="3" height="12" rx="1.5"/><rect x="17.5" y="12.5" width="3" height="7.5" rx="1.5"/>',
  guitar: '<path d="M13.5 10.5 20 4M18.5 2.5l3 3"/><path d="M10.6 9.4c-1.2-1.2-3.4-1-4.4.4-.6.8-.5 1.7-1.6 2.6-1.6 1.3-2 3.7-.3 5.4s4.1 1.3'
    + ' 5.4-.3c.9-1.1 1.8-1 2.6-1.6 1.4-1 1.6-3.2.4-4.4z"/><circle cx="8.6" cy="15.4" r="1.3"/>',
  bass: '<path d="M4.5 10a4.5 4.5 0 0 1 9 0c0 4.5-4 8-9.5 10"/><circle cx="5.3" cy="10.2" r="1.4" fill="currentColor"/>'
    + '<circle cx="17.5" cy="7.5" r="1.1" fill="currentColor" stroke="none"/><circle cx="17.5" cy="12.5" r="1.1" fill="currentColor" stroke="none"/>',
  violin: '<path d="M12 2.5v6M10.5 2.5h3"/><path d="M12 8.5c-2.5 0-3.5 1.5-3 3 .3 1-.9 1.4-.9 3 0 2.8 1.8 4.5 3.9 4.5s3.9-1.7'
    + ' 3.9-4.5c0-1.6-1.2-2-.9-3 .5-1.5-.5-3-3-3zM12 12v5M4 20.5 20 7"/>',
  choir: '<circle cx="6.5" cy="9.5" r="2.2"/><circle cx="17.5" cy="9.5" r="2.2"/><circle cx="12" cy="7" r="2.6"/>'
    + '<path d="M2.5 19.5c0-3 1.8-5 4-5M21.5 19.5c0-3-1.8-5-4-5M7.5 19.5c0-3.5 2-6 4.5-6s4.5 2.5 4.5 6"/>',
  trumpet: '<path d="M3 12h11"/><path d="M14 9.5c3 0 5-1.5 7-3.5v12c-2-2-4-3.5-7-3.5z"/><path d="M6 12V9M9 12V9M12 12V9"/>'
    + '<path d="M4 12c0 2.5 2 3.5 4.5 3.5H14"/>',
  sax: '<path d="M17 2.5 13.5 6v8.5c0 3-1.8 5-4.5 5s-4.5-2-4.5-4.5v-2.5M2.5 12.5h4"/>'
    + '<circle cx="13.5" cy="9.5" r="1" fill="currentColor" stroke="none"/><circle cx="13.5" cy="12.5" r="1" fill="currentColor" stroke="none"/>',
  flute: '<rect x="2" y="10" width="20" height="4" rx="2"/><path d="M5 10v4"/><circle cx="10" cy="12" r=".9" fill="currentColor" stroke="none"/>'
    + '<circle cx="13.5" cy="12" r=".9" fill="currentColor" stroke="none"/><circle cx="17" cy="12" r=".9" fill="currentColor" stroke="none"/>',
  saw: '<path d="M3 17 8 7v10l5-10v10l5-10v10"/>',
  pad: '<path d="M3 10c3-4 6-4 9 0s6 4 9 0"/><path d="M3 15.5c3-4 6-4 9 0s6 4 9 0" opacity=".5"/>',
  sparkle: '<path d="M11 3c.6 4.2 1.8 5.4 6 6-4.2.6-5.4 1.8-6 6-.6-4.2-1.8-5.4-6-6 4.2-.6 5.4-1.8 6-6z"/>'
    + '<path d="M18 14.5c.3 1.6.9 2.2 2.5 2.5-1.6.3-2.2.9-2.5 2.5-.3-1.6-.9-2.2-2.5-2.5 1.6-.3 2.2-.9 2.5-2.5z"/>',
  banjo: '<circle cx="8" cy="16" r="5"/><circle cx="8" cy="16" r="2.2"/><path d="M11.5 12.5 20.5 3.5M19 2l3 3"/>',
  conga: '<ellipse cx="10" cy="11" rx="7" ry="2.5"/><path d="M3 11v5c0 1.4 3.1 2.5 7 2.5s7-1.1 7-2.5v-5M14 8.5 19.5 3"/>'
    + '<circle cx="20" cy="2.6" r="1.3" fill="currentColor" stroke="none"/>',
  speaker: '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11"/>',
  drums: '<ellipse cx="12" cy="11" rx="7.5" ry="2.8"/><path d="M4.5 11v6c0 1.5 3.4 2.8 7.5 2.8s7.5-1.3 7.5-2.8v-6M3 3.5l7 5M21 3.5l-7 5"/>',
};

const SVG_NS = 'http://www.w3.org/2000/svg';
const FAMILY_DWELL = 250;    // ms the pointer rests on a family before it shows

function icon(name) {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('class', 'icon');
  svg.innerHTML = ICONS[name];
  return svg;
}

const instrumentValue = (c) => (c.drum ? String(c.kit) : `${c.variation}:${c.program}`);

// What a channel plays, as its button shows it: an icon and a name.
function showInstrument(button, c) {
  let kind = 'drums';
  let name = `${app.init.kits[c.kit].name} kit`;
  if (!c.drum) {
    const variation = app.init.variations.find(([bank, program]) => bank === c.variation && program === c.program);
    kind = FAMILIES[c.program >> 3][1];
    name = variation ? `${c.program + 1}/${c.variation} ${variation[2]}` : programName(c.program);
  }
  button.replaceChildren(icon(kind), el('span', { textContent: name }));
  button.title = `${name}: click to choose ${c.drum ? 'the kit' : 'the instrument'}`;
  button.dataset.value = instrumentValue(c);
}

// The instrument chosen for channel i: sent, shown, and the editor follows.
function chooseInstrument(i, program, bank = 0) {
  const c = app.channels[i];
  if (c.drum) {
    c.kit = program;
    send({ type: 'program', channel: i, program });
  }
  else {
    [c.program, c.variation] = [program, bank];
    send({ type: 'program', channel: i, program, bank });
  }
  showInstrument($(`strip-${i}`).querySelector('.instrument'), c);
  if (app.selected === i) requestPatch();
}

let chooser = null;

function closeChooser() {
  if (!chooser) return;
  chooser.remove();
  chooser = null;
}

// A cell of the chooser: what it shows, whether it is what plays, what a click does.
function choice(className, active, onpick, ...children) {
  const cell = el('div', { className: active ? `${className} active` : className }, ...children);
  cell.onclick = (e) => {
    e.stopPropagation();
    onpick();
  };
  return cell;
}

function openChooser(anchor, i) {
  closeChooser();
  const c = app.channels[i];
  const pick = (program, bank) => () => {
    closeChooser();
    chooseInstrument(i, program, bank);
  };
  const panel = el('div', { className: 'chooser' });

  if (c.drum) {
    const kits = Object.entries(app.init.kits).sort(([a], [b]) => a - b);
    panel.append(el('div', { className: 'programs' }, ...kits.map(([kit, { name }]) =>
      choice('program', Number(kit) === c.kit, pick(Number(kit)), icon('drums'), el('span', { className: 'name', textContent: `${name} kit` })))));
  }
  else {
    const programs = el('div', { className: 'programs' });
    const show = (family) => {
      families.querySelectorAll('.family').forEach((f, n) => f.classList.toggle('shown', n === family));
      programs.replaceChildren(...[0, 1, 2, 3, 4, 5, 6, 7].map((k) => {
        const n = 8 * family + k;
        const chips = app.init.variations.filter(([, program]) => program === n).map(([bank, , name]) =>
          choice('chip', c.program === n && c.variation === bank, pick(n, bank), document.createTextNode(name)));
        return choice('program', c.program === n && !c.variation, pick(n, 0),
          el('span', { className: 'n', textContent: n + 1 }), el('span', { className: 'name', textContent: app.init.programs[n] }),
          ...(chips.length ? [el('div', { className: 'chips' }, ...chips)] : []));
      }));
    };
    // Pointed at, a family shows when the pointer rests on it, not as it
    // passes over on its way down to the programs; clicked, at once.
    let resting = null;
    const families = el('div', { className: 'families' }, ...FAMILIES.map(([name, kind], family) => {
      const cell = choice('family', c.program >> 3 === family, () => show(family), icon(kind), el('span', { textContent: name }));
      cell.onpointerenter = (e) => {
        clearTimeout(resting);
        if (e.pointerType === 'mouse') resting = setTimeout(() => show(family), FAMILY_DWELL);
      };
      cell.onpointerleave = () => clearTimeout(resting);
      return cell;
    }));
    panel.append(families, programs);
    show(c.program >> 3);
  }

  document.body.append(panel);
  chooser = panel;
  const r = anchor.getBoundingClientRect();
  const left = Math.max(8, Math.min(r.left, innerWidth - panel.offsetWidth - 8));
  let top = r.bottom + 6;
  if (top + panel.offsetHeight > innerHeight - 8) top = Math.max(8, r.top - panel.offsetHeight - 6);
  panel.style.left = `${left}px`;
  panel.style.top = `${top}px`;
}

document.addEventListener('pointerdown', (e) => {
  if (chooser && !chooser.contains(e.target) && !e.target.closest('.instrument')) closeChooser();
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeChooser();
});
addEventListener('resize', closeChooser);

function buildChannels() {
  const box = $('channels');
  const heads = ['#', 'instrument', 'volume', 'pan', 'reverb', 'chorus', '', '', ''];
  box.replaceChildren(el('div', { className: 'strip-head' }, ...heads.map((text) => el('span', { textContent: text }))));
  app.channels.forEach((c, i) => box.append(channelStrip(c, i)));
  updateChannels(app.channels);
}

// A channel's strip: its number, instrument, sliders, mute and level; a
// click on it selects the channel.
function channelStrip(c, i) {
  const program = el('button', { className: 'instrument' });
  showInstrument(program, c);
  program.onclick = () => (chooser ? closeChooser() : openChooser(program, i));

  const sliders = STRIP_SLIDERS.map(({ number, field, reset, title }) => {
    const input = el('input', { type: 'range', min: 0, max: 127, value: c[field], title });
    input.oninput = () => send({ type: 'cc', channel: i, number, value: Number(input.value) });
    input.onclick = (e) => e.stopPropagation();
    input.ondblclick = () => {
      input.value = reset;
      input.oninput();
    };
    return input;
  });

  const mute = el('button', { className: 'mute', textContent: 'M', title: 'mute' });
  mute.onclick = (e) => {
    e.stopPropagation();
    const on = !mute.classList.contains('on');
    mute.classList.toggle('on', on);
    send({ type: 'mute', channel: i, on });
  };

  const hold = el('button', { className: 'hold', textContent: 'H' });
  hold.onclick = (e) => {
    e.stopPropagation();
    if (app.channels[i].held.length) send({ type: 'let_go', channel: i });
  };

  const strip = el('div', { className: 'strip', id: `strip-${i}` },
    el('span', { className: 'num', textContent: i + 1 }), program, ...sliders, mute, hold,
    el('span', { className: 'level' }, el('i')));
  strip.onclick = () => selectChannel(i);
  return strip;
}

// The channels as the server has them; what is being handled stays as it is.
function updateChannels(channels) {
  channels.forEach((c, i) => {
    const strip = $(`strip-${i}`);
    if (!strip) return;
    const was = app.channels[i];
    app.channels[i] = c;
    if (!!was.drum !== !!c.drum) return buildChannels();

    const program = strip.querySelector('.instrument');
    const sliders = strip.querySelectorAll('input');
    if (program.dataset.value !== instrumentValue(c)) {
      showInstrument(program, c);
      if (app.selected === i) requestPatch();
    }
    sliders.forEach((input, s) => {
      if (document.activeElement !== input) input.value = c[STRIP_SLIDERS[s].field];
      input.classList.toggle('held', c.held.includes(`cc ${STRIP_SLIDERS[s].number}`));
    });
    program.classList.toggle('held', c.held.includes('program'));
    strip.querySelector('.mute').classList.toggle('on', !!c.mute);
    const hold = strip.querySelector('.hold');
    hold.classList.toggle('on', c.held.length > 0);
    hold.title = c.held.length
      ? `held against the file: ${c.held.map(heldName).join(', ')}; click to let go (the file's settings as of now)`
      : 'what you set here (or play live) is held against the file; nothing is held';
  });
}

// What a channel holds against the file, by name.
const SOUND_CONTROLLERS = { 70: 'variation', 71: 'resonance', 72: 'release', 73: 'attack', 74: 'cutoff',
  75: 'decay', 76: 'vibrato rate', 77: 'vibrato depth', 78: 'vibrato delay', 79: 'sound controller 10' };
function heldName(what) {
  if (what === 'program') return 'instrument';
  const [kind, name] = what.split(' ');
  if (kind === 'arp') return `arpeggiator ${name === 'mode' ? 'pattern' : name}`;
  const slider = STRIP_SLIDERS.find((s) => s.number === Number(name));
  if (slider) return slider.field === 'send' ? 'reverb' : slider.field;
  return Number(name) === 5 ? 'portamento time' : SOUND_CONTROLLERS[name];
}

function selectChannel(i) {
  app.selected = i;
  document.querySelectorAll('.strip').forEach((s, n) => s.classList.toggle('selected', n === i));
  $('key-channel').value = i;
  requestPatch();
  if (app.channelEq) buildChannelEq();
  if (app.arp) buildArp();
}

// The patch the editor shows: the selected channel's instrument, or on a
// drum channel the drum chosen.
function currentPatchId() {
  const c = app.channels[app.selected];
  if (c && c.drum) return { kind: 'drum', number: app.drumKey, bank: ownKit(c.kit, app.drumKey) };
  return { kind: 'program', number: c ? c.program : 0, bank: c ? c.variation : 0 };
}

// The kit whose patch a key plays in a kit: the kit, where it has the key
// as its own, or the standard kit.
function ownKit(kit, key) {
  const k = app.init.kits[kit];
  return k && k.keys.includes(key) ? kit : 0;
}

function isCurrentPatch(kind, number, bank) {
  const id = currentPatchId();
  return id.kind === kind && id.number === number && id.bank === bank;
}

function requestPatch() {
  const id = currentPatchId();
  $('drum-key').hidden = id.kind !== 'drum';
  send({ type: 'patch_get', ...id });
}

function buildDrumKeys() {
  const select = $('drum-key');
  const keys = Object.keys(app.init.drums).map(Number).sort((a, b) => a - b);
  select.replaceChildren(...keys.map((k) => el('option', { value: k, textContent: `${k} ${app.init.drums[k]}` })));
  select.value = app.drumKey;
  select.onchange = () => {
    app.drumKey = Number(select.value);
    requestPatch();
  };
}

// The patch editor: a slider for every field, grouped; changed fields are
// marked, and a double-click on a name brings the default back.

const LOG_STEPS = 1000;

// The fields of the harmonic spectrum that still apply to partials of a patch's own.
const OWN_PARTIALS_FIELDS = ['cutoff', 'bright', 'track'];

function toSlider(info, value) {
  if (info.scale !== 'log') return value;
  const low = Math.max(info.min, 1e-4);
  return Math.round(LOG_STEPS * Math.log(Math.max(value, low) / low) / Math.log(info.max / low));
}

function fromSlider(info, position) {
  if (info.scale !== 'log') return Number(position);
  const low = Math.max(info.min, 1e-4);
  return low * Math.pow(info.max / low, position / LOG_STEPS);
}

// A value as a field shows it: two or three figures.
function show(value) {
  if (typeof value !== 'number') return value;
  const a = Math.abs(value);
  if (a === 0) return '0';
  if (a >= 1000) return value.toFixed(0);
  if (a >= 10) return value.toFixed(1);
  if (a >= 0.1) return value.toFixed(2);
  return value.toPrecision(2);
}

// A group of the editor that folds at a click on its head; folded if it was.
function foldingGroup(name, head, body, closed) {
  const group = el('div', { className: 'group' }, head, body);
  group.dataset.group = name;
  if (closed.has(name)) group.classList.add('closed');
  head.onclick = () => group.classList.toggle('closed');
  return group;
}

function buildEditor() {
  const p = app.patch;
  $('patch-title').textContent = p.kind === 'drum' ? p.name
                               : p.bank           ? `${p.number + 1}/${p.bank} ${p.name}`
                               :                    `${p.number + 1} ${p.name}`;
  const box = $('fields');
  const closed = new Set([...box.querySelectorAll('.group.closed')].map((g) => g.dataset.group));
  box.replaceChildren();

  const fields = {};
  const parts = { list: listGroup(closed), mods: modsGroup(closed) };
  for (const info of app.init.fields) {
    if (info.name === 'length' && p.kind !== 'drum') continue;
    if (info.group === 'spectrum' && p.partials && !OWN_PARTIALS_FIELDS.includes(info.name)) continue;
    if (!fields[info.group]) {
      fields[info.group] = el('div', { className: 'fields' });
      const head = el('h3', { textContent: GROUPS[info.group] || info.group });
      parts[info.group] = foldingGroup(info.group, head, fields[info.group], closed);
    }
    fields[info.group].append(buildField(info));
  }
  if (p.partials) {
    const text = `${p.partials.length} partials of its own: the harmonic spectrum's fields do not apply.`;
    box.append(el('p', { className: 'hint', textContent: text }));
  }
  const order = [...ORDER, ...Object.keys(parts).filter((name) => !ORDER.includes(name))];
  box.append(...order.filter((name) => parts[name]).map((name) => parts[name]));
  drawPreviews();
}

// A number typed into a list, held to its range.
function numberInput(min, max, step, value, onchange) {
  const input = el('input', { type: 'number', min, max, step, value });
  input.onchange = () => {
    const v = Math.min(max, Math.max(min, Number(input.value) || 0));
    input.value = v;
    onchange(v);
  };
  return input;
}

function removeButton(onclick) {
  const remove = el('button', { textContent: '✕', title: 'remove' });
  remove.onclick = onclick;
  return remove;
}

// The routes of modulation: source, destination, amount, a row each.
function modsGroup(closed) {
  const p = app.patch;
  const info = app.init.mod;
  const rows = el('div', { className: 'list' });
  const head = el('h3', { textContent: 'Modulation', title: 'sources routed to destinations: each source times the amount' });
  const list = (p.mods || []).map((row) => [...row]);
  const changed = () => {
    p.mods = list.map((row) => [...row]);
    queueField('mods', p.mods);
  };
  const menu = (options, value, set) => {
    const select = el('select', {}, ...options.map((o) => el('option', { value: o.name, textContent: o.name, title: o.about })));
    select.value = value;
    select.onchange = () => {
      set(select.value);
      changed();
    };
    return select;
  };
  const draw = () => {
    const heads = ['source', 'destination', 'amount', ''];
    rows.replaceChildren(el('div', { className: 'list-row list-head' }, ...heads.map((text) => el('span', { textContent: text }))));
    list.forEach((row, r) => {
      const source = menu(info.sources, row[0], (v) => { row[0] = v; });
      const destination = menu(info.destinations, row[1], (v) => { row[1] = v; });
      const amount = numberInput(-24, 24, 0.05, row[2], (v) => {
        row[2] = v;
        changed();
      });
      const remove = removeButton(() => {
        list.splice(r, 1);
        changed();
        draw();
      });
      rows.append(el('div', { className: 'list-row' }, source, destination, amount, remove));
    });
    const add = el('button', { textContent: 'add a route' });
    add.onclick = () => {
      list.push(['lfo1', 'pitch', 0.2]);
      changed();
      draw();
    };
    rows.append(el('div', { className: 'row' }, add));
  };
  draw();
  return foldingGroup('mods', head, rows, closed);
}

// The filter's gain at x (a frequency over the cutoff), as the engines have it.
function filterGain(x, q, mode) {
  const x2 = x * x;
  const d = Math.sqrt((1 - x2) * (1 - x2) + x2 / (q * q));
  switch (mode) {
    case 'lp12': return 1 / d;
    case 'lp24': return 1 / (d * Math.sqrt(1 + x2 * x2));
    case 'hp12': return x2 / d;
    case 'hp24': return x2 * x2 / (d * Math.sqrt(1 + x2 * x2));
    case 'bp':   return x / q / d;
    default:     return 1;
  }
}

// The patch's lists: its own partials, or the formants of its harmonic
// spectrum, a row each, the whole list sent as it changes. Each column is
// [label, min, max, step]; add is the row a click on add adds.
const LISTS = {
  partials: {
    title: 'Own partials',
    about: 'partials of their own: frequency ratio to the note, amplitude, how much faster than the patch\'s decay they fade',
    columns: [['ratio', 0.05, 64, 0.01], ['amplitude', 0, 1, 0.01], ['decay ×', 0, 20, 0.1]],
    add: [2, 0.2, 1],
  },
  formants: {
    title: 'Formants',
    about: 'boosts (or cuts, below 0) of the harmonic spectrum around a frequency, as voices and resonating bodies have',
    columns: [['centre Hz', 20, 20000, 10], ['gain', -1, 10, 0.1], ['width oct', 0.05, 4, 0.05]],
    add: [1000, 1, 0.5],
  },
};

function listGroup(closed) {
  const p = app.patch;
  const name = p.partials ? 'partials' : 'formants';
  const spec = LISTS[name];
  const rows = el('div', { className: 'list' });
  const head = el('h3', { textContent: spec.title, title: spec.about });
  const list = (p[name] || []).map((row) => [...row]);
  const changed = () => {
    p[name] = list.map((row) => [...row]);
    queueField(name, p[name]);
    drawPreviews();
  };
  const draw = () => {
    const heads = [...spec.columns.map(([label]) => label), ''];
    rows.replaceChildren(el('div', { className: 'list-row list-head' }, ...heads.map((text) => el('span', { textContent: text }))));
    list.forEach((row, r) => {
      const inputs = spec.columns.map(([, min, max, step], c) => numberInput(min, max, step, row[c], (v) => {
        row[c] = v;
        changed();
      }));
      const remove = removeButton(() => {
        list.splice(r, 1);
        changed();
        draw();
      });
      rows.append(el('div', { className: 'list-row' }, ...inputs, remove));
    });

    const add = el('button', { textContent: name === 'partials' ? 'add a partial' : 'add a formant' });
    add.onclick = () => {
      list.push([...spec.add]);
      changed();
      draw();
    };
    const buttons = el('div', { className: 'row' }, add);
    if (name === 'partials') {
      const series = el('button', { textContent: 'harmonic series', title: 'back to the spectrum the patch\'s fields make' });
      series.onclick = () => setPartials(p, null);
      buttons.append(series);
    } else {
      const own = el('button', { textContent: 'own partials', title: 'partials of its own, from the strongest of the spectrum now' });
      own.onclick = () => setPartials(p, strongestPartials(p));
      buttons.append(own);
    }
    rows.append(buttons);
  };
  draw();
  return foldingGroup(`list-${name}`, head, rows, closed);
}

function setPartials(p, partials) {
  p.partials = partials;
  queueField('partials', partials);
  buildEditor();
}

// The twelve strongest partials of a patch's spectrum at middle C, as
// partials of its own: [ratio, amplitude (the strongest 1), decay ×1].
function strongestPartials(p) {
  const f = p.fields;
  const f0 = f.fixed || 440 * Math.pow(2, (60 + f.transpose - 69) / 12);
  const set = partialsOf(f, p).sort((a, b) => b[1] - a[1]).slice(0, 12);
  const top = set.length ? set[0][1] : 1;
  return set.sort((a, b) => a[0] - b[0]).map(([hz, a]) => [Number((hz / f0).toFixed(3)), Number((a / top).toFixed(3)), 1]);
}

// A field's row: its name (a double-click: the default), a slider or the
// choices, and its value.
function buildField(info) {
  const p = app.patch;
  const label = el('label', {
    textContent: info.name.replace(/_/g, ' '),
    title: `${info.about}\n(double-click: back to ${show(p.defaults[info.name])})`,
  });
  const output = el('output');
  const row = el('div', { className: info.scale === 'choice' ? 'field choices' : 'field' });
  row.dataset.field = info.name;
  const set = (value) => {
    p.fields[info.name] = value;
    row.update(value);
    queueField(info.name, value);
    drawPreviews();
  };

  let control;
  if (info.scale === 'choice') {
    control = el('span', { className: 'choice' });
    for (const option of info.choices || [info.min, info.max]) {
      const button = el('button', { textContent: option });
      button.onclick = () => set(option);
      control.append(button);
    }
  } else {
    const log = info.scale === 'log';
    control = el('input', {
      type: 'range',
      min: log ? 0 : info.min,
      max: log ? LOG_STEPS : info.max,
      step: log || info.scale === 'int' ? 1 : (info.max - info.min) / 500,
    });
    control.oninput = () => {
      const value = fromSlider(info, control.value);
      set(info.scale === 'int' ? Math.round(value) : value);
    };
  }

  row.update = (value) => {
    if (info.scale === 'choice') {
      control.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.textContent === value));
      output.textContent = '';
    } else {
      if (document.activeElement !== control) control.value = toSlider(info, value);
      output.textContent = info.scale === 'int' ? String(Math.round(value)) : show(value);
    }
    row.classList.toggle('changed', String(value) !== String(p.defaults[info.name]));
  };
  label.ondblclick = () => set(p.defaults[info.name]);
  row.append(label, control);
  if (info.scale !== 'choice') row.append(output);
  row.update(p.fields[info.name]);
  return row;
}

// A field's change, sent with the others of the same frame.
function queueField(field, value) {
  const first = app.pending.size === 0;
  app.pending.set(field, value);
  if (!first) return;
  requestAnimationFrame(() => {
    const id = currentPatchId();
    for (const [f, v] of app.pending) send({ type: 'patch_set', ...id, field: f, value: v });
    app.pending.clear();
  });
}

$('patch-reset').onclick = () => send({ type: 'patch_reset', ...currentPatchId() });
$('bank-save').onclick = () => send({ type: 'bank_save' });

// The previews: the spectrum of middle C at velocity 100 and the envelope of
// a note held for a second, from the same formulas the voices use.

// A note's partials, [Hz, amplitude], up to 0.45 of the rate.
function partialsOf(f, p, key = 60, velocity = 100) {
  const v = velocity / 127;
  const f0 = f.fixed || 440 * Math.pow(2, (key + f.transpose - 69) / 12);
  const top = 0.45 * app.init.rate;
  const set = [];
  if (p.partials) {
    for (const [ratio, amp] of p.partials) set.push([ratio * f0, amp]);
  } else {
    const cutoff = f.cutoff * Math.pow(f0 / 261.6, f.track) * Math.pow(2, f.bright * (v - 0.75) * 2);
    const B = f.stretch * Math.pow(2, (key - 60) / 12 * (f.stretch_key || 0));
    for (let k = 1; k <= f.max; k++) {
      const hz = k * Math.sqrt(1 + B * k * k) * f0;
      if (hz > top) break;
      let amp = Math.pow(k, -f.slope) / Math.pow(1 + Math.pow(hz / cutoff, 4), (1 + (f.rolloff || 0)) / 2);
      if (k % 2 === 0) amp *= f.even;
      if (f.pluck) amp *= Math.abs(Math.sin(Math.PI * k * f.pluck));
      for (const [centre, gain, width] of p.formants || []) {
        amp *= 1 + gain * Math.exp(-Math.pow(Math.log2(hz / centre) / width, 2));
      }
      set.push([hz, amp]);
    }
  }
  // The filter where it rests (the second envelope at 0, the controllers at their middle).
  if (f.filter && f.filter !== 'off') {
    const fc = f.filter_cutoff * Math.pow(f0 / 261.6, f.filter_track) * Math.pow(2, f.filter_vel * (v - 0.75) * 2);
    for (const partial of set) partial[1] *= filterGain(partial[0] / fc, f.filter_q, f.filter);
  }
  return set.filter(([hz]) => hz <= top);
}

function drawPreviews() {
  const p = app.patch;
  if (!p) return;
  drawSpectrum(p);
  drawEnvelope(p);
}

// Lines at 100 Hz, 1 kHz and 10 kHz on a canvas, at x(frequency).
function decades(g, x, h) {
  g.strokeStyle = colour('--line');
  for (const hz of [100, 1000, 10000]) {
    g.beginPath();
    g.moveTo(x(hz), 0);
    g.lineTo(x(hz), h);
    g.stroke();
  }
  g.fillStyle = colour('--muted');
  g.font = '10px system-ui';
  g.fillText('100 Hz', x(100) + 3, 11);
  g.fillText('1 kHz', x(1000) + 3, 11);
  g.fillText('10 kHz', x(10000) + 3, 11);
}

// The partials as bars, 60 dB high, on 20 Hz to 20 kHz; the bands of noise behind.
function drawSpectrum(p) {
  const f = p.fields;
  const canvas = $('spectrum-preview');
  const g = canvas.getContext('2d');
  const w = canvas.width;
  const h = canvas.height;
  const x = (hz) => w * Math.log(hz / 20) / Math.log(20000 / 20);
  g.clearRect(0, 0, w, h);
  decades(g, x, h);

  const set = partialsOf(f, p);
  const peak = Math.max(1e-9, ...set.map(([, a]) => a));
  g.fillStyle = colour('--accent');
  for (const [hz, amp] of set) {
    const db = 20 * Math.log10(amp / peak);
    const bar = Math.max(0, (db + 60) / 60) * (h - 14);
    g.fillRect(x(hz) - 1, h - bar, 2.5, bar);
  }

  // Where each band lets noise through, as tall as its level.
  for (const b of ['noise', 'noise2', 'noise3']) {
    if (!(f[b] > 0)) continue;
    const centre = f[`${b}_ratio`] ? f[`${b}_ratio`] * (f.fixed || 261.6) : f[`${b}_center`];
    const tall = Math.min(h - 14, 30 * Math.min(2, f[b]) / 0.5);
    const width = Math.max(4, w * 0.08 / Math.max(0.2, f[`${b}_q`]));
    const mode = f[`${b}_mode`];
    g.fillStyle = 'rgba(74,179,224,.3)';    // --accent-2, see-through
    if (mode === 'high') g.fillRect(x(centre), h - tall, w - x(centre), tall);
    else if (mode === 'low') g.fillRect(0, h - tall, x(centre), tall);
    else g.fillRect(x(centre) - width / 2, h - tall, width, tall);
  }
}

// The envelope of a note held one second (a drum: as long as it rings),
// over two and a half, with the fundamental's own decay.
function drawEnvelope(p) {
  const f = p.fields;
  const drum = p.kind === 'drum';
  const canvas = $('envelope-preview');
  const e = canvas.getContext('2d');
  const seconds = 2.5;
  const held = 1;
  const whileHeld = (t) => {
    if (t < f.attack) return t / f.attack;
    t -= f.attack + f.hold;
    if (t <= 0) return 1;
    return f.sustain + (1 - f.sustain) * Math.exp(-t / Math.max(f.fall, 1e-3));
  };
  const at = (t) => {
    let level = whileHeld(Math.min(t, held));
    if (t > held && !drum) level *= Math.exp(-(t - held) / Math.max(f.release, 1e-3));
    if (drum && t > f.length) level *= Math.exp(-(t - f.length) / 0.01);
    return level * Math.exp(-f.decay * t);
  };
  e.clearRect(0, 0, canvas.width, canvas.height);

  const hx = (held / seconds) * canvas.width;
  e.strokeStyle = colour('--line');
  e.beginPath();
  e.moveTo(hx, 0);
  e.lineTo(hx, canvas.height);
  e.stroke();
  e.fillStyle = colour('--muted');
  e.font = '10px system-ui';
  e.fillText(drum ? 'rings' : 'key up', hx + 3, 11);

  e.strokeStyle = colour('--accent-2');
  e.lineWidth = 2;
  e.beginPath();
  for (let i = 0; i <= canvas.width; i++) {
    const y = canvas.height - 4 - at((i / canvas.width) * seconds) * (canvas.height - 18);
    if (i) e.lineTo(i, y);
    else e.moveTo(i, y);
  }
  e.stroke();
  e.lineWidth = 1;
}

// The side column's sections fold; which are folded is remembered in this
// browser (where it may store anything).

const FOLDS = 'peta-synth-folds';

function storedFolds() {
  try {
    return JSON.parse(localStorage.getItem(FOLDS) || 'null');
  } catch (e) {
    return null;
  }
}

function storeFolds(names) {
  try {
    localStorage.setItem(FOLDS, JSON.stringify(names));
  } catch (e) {
    // Not stored: the page forgets, nothing else.
  }
}

function setupFolds() {
  const folded = storedFolds();
  for (const fold of document.querySelectorAll('.side .fold')) {
    const name = fold.dataset.fold;
    if (folded) fold.classList.toggle('closed', folded.includes(name));
    fold.querySelector('h2').onclick = () => {
      fold.classList.toggle('closed');
      storeFolds([...document.querySelectorAll('.side .fold.closed')].map((f) => f.dataset.fold));
      if (fold.classList.contains('closed')) return;
      // A canvas folded away is drawn again.
      if (name === 'eq') drawEq($('eq-curve'), app.eq);
      if (name === 'channel-eq' && app.channelEq) drawEq($('channel-eq-curve'), app.channelEq[app.selected]);
    };
  }
}

// Master and reverb.

// A slider with its label and its value, shown by format.
function knob(box, label, min, max, step, value, onchange, format = show) {
  const input = el('input', { type: 'range', min, max, step, value });
  const output = el('output', { textContent: format(Number(value)) });
  input.oninput = () => {
    output.textContent = format(Number(input.value));
    onchange(Number(input.value));
  };
  box.append(el('div', { className: 'knob' }, el('label', { textContent: label }), input, output));
  return input;
}

function toggle(box, label, on, onchange) {
  const button = el('button', { textContent: label, className: on ? 'on' : '' });
  button.onclick = () => {
    const now = !button.classList.contains('on');
    button.classList.toggle('on', now);
    onchange(now);
  };
  box.append(button);
  return button;
}

function buildMaster() {
  const box = $('master');
  box.replaceChildren();
  const s = app.init.synth;
  const set = (name) => (v) => send({ type: 'synth', name, value: v });
  const most = (v) => `≤ ${v}`;
  knob(box, 'gain', 0, 1, 0.01, s.gain, set('gain'));
  knob(box, 'partials', 1, 256, 1, s.partials, set('partials'), most);
  knob(box, 'voices', 8, 512, 1, s.voices, set('voices'), most);
  const fidelity = buttons(box, 'fidelity', ['low', 'mid', 'high'], s.fidelity, set('fidelity'));
  fidelity.title = 'what may be left out that is hardly heard: mid and low end voices sooner as they fade (low: at most 48 at once); high leaves nothing out';
  const auto = toggle(box, 'auto quality', !!s.auto, (on) => set('auto')(on ? 1 : 0));
  auto.title = 'fewer partials for new notes when the machine cannot keep up, more when it can';
}

function buildReverb() {
  const box = $('reverb');
  box.replaceChildren();
  const r = app.init.reverb;
  const set = (name) => (v) => send({ type: 'reverb', name, value: v });
  knob(box, 'time', 0.1, 10, 0.1, r.time, set('time'), (v) => `${show(v)} s`);
  knob(box, 'size', 0.2, 3, 0.01, r.size, set('size'));
  knob(box, 'damp', 0, 0.95, 0.01, r.damp, set('damp'));
  knob(box, 'level', 0, 2, 0.01, r.level, set('level'));
  knob(box, 'predelay', 0, 0.2, 0.001, r.predelay, set('predelay'), (v) => `${Math.round(v * 1000)} ms`);
  toggle(box, 'reverb on', !!r.on, (on) => set('on')(on ? 1 : 0));
}

// The master equalizer: four bands, their response drawn as the server
// computes it (the cookbook's biquads).

const EQ_BANDS = [
  { name: 'low', label: 'low shelf', type: 'lowshelf' },
  { name: 'mid1', label: 'low mid', type: 'peak' },
  { name: 'mid2', label: 'high mid', type: 'peak' },
  { name: 'high', label: 'high shelf', type: 'highshelf' },
];

// A band's coefficients, normalized by a0: [b0, b1, b2, 1, a1, a2].
function eqCoefficients(type, freq, gain, q, rate) {
  const A = Math.pow(10, gain / 40);
  const w0 = Math.min(2 * Math.PI * freq / rate, Math.PI * 0.99);
  const cos = Math.cos(w0);
  const sin = Math.sin(w0);
  const alpha = sin / (2 * q);
  const s = 2 * Math.sqrt(A) * alpha;
  let c;
  if (type === 'peak') {
    c = [1 + alpha * A, -2 * cos, 1 - alpha * A, 1 + alpha / A, -2 * cos, 1 - alpha / A];
  } else if (type === 'lowshelf') {
    c = [A * ((A + 1) - (A - 1) * cos + s), 2 * A * ((A - 1) - (A + 1) * cos), A * ((A + 1) - (A - 1) * cos - s),
         (A + 1) + (A - 1) * cos + s, -2 * ((A - 1) + (A + 1) * cos), (A + 1) + (A - 1) * cos - s];
  } else {
    c = [A * ((A + 1) + (A - 1) * cos + s), -2 * A * ((A - 1) + (A + 1) * cos), A * ((A + 1) + (A - 1) * cos - s),
         (A + 1) - (A - 1) * cos + s, 2 * ((A - 1) - (A + 1) * cos), (A + 1) - (A - 1) * cos - s];
  }
  return c.map((v) => v / c[3]);
}

// The equalizer's gain at a frequency, dB: the bands' responses added up.
function eqResponse(params, freq) {
  const rate = app.init.rate;
  const w = 2 * Math.PI * freq / rate;
  let db = 0;
  for (const b of EQ_BANDS) {
    const p = params[b.name];
    if (!p.gain) continue;
    const [b0, b1, b2, , a1, a2] = eqCoefficients(b.type, p.freq, p.gain, p.q, rate);
    const nr = b0 + b1 * Math.cos(w) + b2 * Math.cos(2 * w);
    const ni = -b1 * Math.sin(w) - b2 * Math.sin(2 * w);
    const dr = 1 + a1 * Math.cos(w) + a2 * Math.cos(2 * w);
    const di = -a1 * Math.sin(w) - a2 * Math.sin(2 * w);
    db += 10 * Math.log10((nr * nr + ni * ni) / (dr * dr + di * di));
  }
  return db;
}

// The curve, ±15 dB, over 20 Hz to 20 kHz (or half the rate).
function drawEq(canvas, params) {
  const e = canvas.getContext('2d');
  const { width: w, height: h } = canvas;
  const top = Math.min(20000, app.init.rate / 2);
  const x = (f) => Math.log(f / 20) / Math.log(top / 20) * w;
  const y = (db) => h / 2 - db / 15 * (h / 2);
  e.clearRect(0, 0, w, h);

  e.strokeStyle = 'rgba(138, 148, 163, 0.35)';    // --muted, see-through
  e.beginPath();
  e.moveTo(0, y(0));
  e.lineTo(w, y(0));
  for (const f of [100, 1000, 10000]) {
    e.moveTo(x(f), 0);
    e.lineTo(x(f), h);
  }
  e.stroke();

  e.strokeStyle = colour('--accent');
  e.lineWidth = 2;
  e.beginPath();
  for (let i = 0; i <= w; i++) {
    const f = 20 * Math.pow(top / 20, i / w);
    const v = y(eqResponse(params, f));
    if (i) e.lineTo(i, v);
    else e.moveTo(i, v);
  }
  e.stroke();
  e.lineWidth = 1;
}

// An equalizer's controls in a box, its curve on a canvas; onset(band,
// what, value) for each change.
function eqPanel(box, canvas, params, onset) {
  box.replaceChildren();
  const set = (band, what) => (v) => {
    params[band][what] = v;
    onset(band, what, v);
    drawEq(canvas, params);
  };
  // Frequency on a log scale: 0 .. 1000 over 20 Hz .. 20 kHz.
  const toHz = (v) => Number((20 * Math.pow(1000, v / 1000)).toPrecision(2));
  const fromHz = (f) => Math.round(1000 * Math.log(f / 20) / Math.log(1000));
  const hz = (f) => f >= 1000 ? `${(f / 1000).toFixed(f >= 10000 ? 0 : 1)} kHz` : `${f} Hz`;
  const dB = (v) => `${v > 0 ? '+' : ''}${v} dB`;

  const gains = [];
  for (const b of EQ_BANDS) {
    const p = params[b.name];
    gains.push(knob(box, b.label, -12, 12, 0.5, p.gain, set(b.name, 'gain'), dB));
    knob(box, '', 0, 1000, 1, fromHz(p.freq), (v) => set(b.name, 'freq')(toHz(v)), (v) => hz(toHz(v)));
    if (b.type === 'peak') knob(box, '', 0.3, 8, 0.1, p.q, set(b.name, 'q'), (v) => `Q ${v}`);
  }
  const flat = el('button', { textContent: 'flat', title: 'every band to 0 dB' });
  flat.onclick = () => {
    for (const input of gains) {
      input.value = 0;
      input.dispatchEvent(new Event('input'));
    }
  };
  box.append(flat);
  drawEq(canvas, params);
}

function buildEq() {
  app.eq = structuredClone(app.init.eq);
  eqPanel($('eq'), $('eq-curve'), app.eq, (band, what, value) => send({ type: 'eq', band, what, value }));
}

// The selected channel's equalizer: gains on its voices' partials.
// The selected channel's arpeggiator: on and latch, its pattern and rate
// as buttons, tempo, octaves, gate and swing as sliders.
function buildArp() {
  const channel = app.selected;
  const a = app.arp.channels[channel];
  const choices = (name) => app.arp.fields.find((f) => f.name === name).choices;
  const set = (name) => (value) => {
    a[name] = value;
    send({ type: 'arp', channel, name, value });
  };
  $('arp-title').textContent = `Channel ${channel + 1} arpeggiator`;
  const box = $('arp');
  box.replaceChildren();
  const held = app.channels[channel].held.filter((what) => what.startsWith('arp '));
  if (held.length) {
    // What is held against the file: each a chip, a click lets it go.
    const chips = el('div', { className: 'held-chips' }, el('span', { textContent: 'held:' }));
    for (const what of held) {
      const chip = el('button', { className: 'chip held', textContent: `${heldName(what).replace('arpeggiator ', '')} ✕`,
        title: 'held against the file: click to let go (the file\'s setting as of now)' });
      chip.onclick = () => send({ type: 'let_go', channel, what });
      chips.append(chip);
    }
    box.append(chips);
  }
  const mark = (control, name) => control.classList.toggle('held', held.includes(`arp ${name}`));
  const row = el('div', { className: 'row' });
  mark(toggle(row, 'arpeggiator on', !!a.on, (on) => set('on')(on ? 1 : 0)), 'on');
  mark(toggle(row, 'latch', !!a.latch, (on) => set('latch')(on ? 1 : 0)), 'latch');
  box.append(row);
  mark(buttons(box, 'pattern', choices('mode'), a.mode, set('mode')), 'mode');
  mark(buttons(box, 'rate', choices('rate'), a.rate, set('rate')), 'rate');
  mark(knob(box, 'tempo', 30, 300, 1, a.tempo, set('tempo'), (v) => `${Math.round(v)} bpm`), 'tempo');
  mark(knob(box, 'octaves', 1, 4, 1, a.octaves, set('octaves'), String), 'octaves');
  mark(knob(box, 'gate', 0.05, 1, 0.01, a.gate, set('gate'), (v) => `${Math.round(v * 100)}%`), 'gate');
  mark(knob(box, 'swing', 0, 0.5, 0.01, a.swing, set('swing'), (v) => `${Math.round(v * 100)}%`), 'swing');
  app.arpShown = arpKey(channel);
}

// The arpeggiators as the server has them (a file, MIDI, another page may
// have changed them): the panel built again when the selected one's
// settings or what it holds changed, not while it is being handled.
const arpKey = (channel) => JSON.stringify([app.arp.channels[channel], app.channels[channel].held]);
function updateArp(arps) {
  if (!app.arp) return;
  app.arp.channels = arps;
  if (!app.pointerDown && arpKey(app.selected) !== app.arpShown) buildArp();
}
document.addEventListener('pointerdown', () => { app.pointerDown = true; }, true);
for (const type of ['pointerup', 'pointercancel']) document.addEventListener(type, () => { app.pointerDown = false; }, true);

// One of a few, as buttons: the one chosen lit.
function buttons(box, label, options, value, onchange) {
  const group = el('div', { className: 'choice' });
  for (const option of options) {
    const button = el('button', { textContent: option.replace(/_/g, ' '), className: option === value ? 'on' : '' });
    button.onclick = () => {
      group.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b === button));
      onchange(option);
    };
    group.append(button);
  }
  box.append(el('div', { className: 'knob buttons' }, el('label', { textContent: label }), group));
  return group;
}

function buildChannelEq() {
  const channel = app.selected;
  $('channel-eq-title').textContent = `Channel ${channel + 1} equalizer`;
  eqPanel($('channel-eq'), $('channel-eq-curve'), app.channelEq[channel],
    (band, what, value) => send({ type: 'channel_eq', channel, band, what, value }));
}

// The keyboard: on the page, on the computer's keys, and from MIDI devices.

const COMPUTER = ['a', 'w', 's', 'e', 'd', 'f', 't', 'g', 'y', 'h', 'u', 'j', 'k', 'o', 'l', 'p', ';', "'"];
const BLACK = [1, 3, 6, 8, 10];    // the black keys, in semitones above C

function buildKeyChannels() {
  const select = $('key-channel');
  select.replaceChildren(...app.channels.map((_, i) => el('option', { value: i, textContent: `channel ${i + 1}` })));
  select.value = app.selected;
  select.onchange = () => selectChannel(Number(select.value));
}

function keyChannel() { return Number($('key-channel').value || 0); }

function keyOf(key) { return document.querySelector(`.key[data-key="${key}"]`); }

function noteOn(key, holder) {
  if (key < 0 || key > 127 || app.down.has(key)) return;
  app.down.set(key, holder);
  send({ type: 'note', on: true, channel: keyChannel(), key, velocity: Number($('velocity').value) });
  const k = keyOf(key);
  if (k) k.classList.add('down');
}

function noteOff(key) {
  if (!app.down.has(key)) return;
  app.down.delete(key);
  send({ type: 'note', on: false, channel: keyChannel(), key });
  const k = keyOf(key);
  if (k) k.classList.remove('down');
}

// Every key held by holder let go, but the one it holds now (if any).
function letGo(holder, except = null) {
  for (const [key, who] of [...app.down]) {
    if (who === holder && key !== except) noteOff(key);
  }
}

// As many octaves as the width takes (two to six), from the playing octave.
function buildKeyboard() {
  const box = $('keyboard');
  box.replaceChildren();
  const width = box.clientWidth || 800;
  const octaves = Math.max(2, Math.min(6, Math.floor(width / (7 * 26))));
  const whites = octaves * 7 + 1;
  const keyWidth = width / whites;
  // From the playing octave, as far as MIDI's highest key (127) lets it.
  const base = Math.min(12 * (app.octave + 1), 12 * Math.floor((127 - 12 * octaves) / 12));
  let white = 0;
  for (let key = base; key <= base + 12 * octaves; key++) {
    const note = key % 12;
    const black = BLACK.includes(note);
    const k = el('div', { className: `key ${black ? 'black' : 'white'}` });
    k.dataset.key = key;
    if (black) {
      k.style.left = `${white * keyWidth - keyWidth * 0.3}px`;
      k.style.width = `${keyWidth * 0.6}px`;
    } else {
      k.style.left = `${white * keyWidth}px`;
      k.style.width = `${keyWidth}px`;
      if (note === 0) k.append(el('span', { className: 'label', textContent: `C${Math.floor(key / 12) - 1}` }));
      white++;
    }
    if (app.down.has(key)) k.classList.add('down');
    box.append(k);
  }
  $('octave').textContent = `C${app.octave}`;
}

const keyboard = $('keyboard');
keyboard.onpointerdown = (e) => {
  const k = e.target.closest('.key');
  if (!k) return;
  keyboard.setPointerCapture(e.pointerId);
  keyboard.dataset.pointer = e.pointerId;
  noteOn(Number(k.dataset.key), `pointer${e.pointerId}`);
};
// A pointer slid across the keys plays the one it is on.
keyboard.onpointermove = (e) => {
  if (!e.buttons) return;
  const target = document.elementFromPoint(e.clientX, e.clientY);
  const k = target && target.closest && target.closest('.key');
  const holder = `pointer${e.pointerId}`;
  letGo(holder, k ? Number(k.dataset.key) : null);
  if (k) noteOn(Number(k.dataset.key), holder);
};
keyboard.onpointerup = keyboard.onpointercancel = (e) => letGo(`pointer${e.pointerId}`);

// Whether the computer's keys type into a control (a slider excepted).
function typing() {
  const active = document.activeElement;
  return /INPUT|SELECT|TEXTAREA/.test(active.tagName) && active.type !== 'range';
}

window.addEventListener('keydown', (e) => {
  if (e.repeat || e.ctrlKey || e.metaKey || e.altKey || typing()) return;
  const name = e.key.toLowerCase();
  const index = COMPUTER.indexOf(name);
  if (index >= 0) noteOn(12 * (app.octave + 1) + index, `key${name}`);
  else if (e.key === 'z') shiftOctave(-1);
  else if (e.key === 'x') shiftOctave(1);
});
window.addEventListener('keyup', (e) => {
  const name = e.key.toLowerCase();
  if (COMPUTER.includes(name)) letGo(`key${name}`);
});
window.addEventListener('blur', () => {
  for (const key of [...app.down.keys()]) noteOff(key);
});

function shiftOctave(by) {
  app.octave = Math.max(0, Math.min(8, app.octave + by));
  buildKeyboard();
}
$('octave-down').onclick = () => shiftOctave(-1);
$('octave-up').onclick = () => shiftOctave(1);
$('velocity').oninput = () => { $('velocity-value').textContent = $('velocity').value; };
$('bend').oninput = () => send({ type: 'bend', channel: keyChannel(), value: Number($('bend').value) });
$('bend').onpointerup = () => {
  $('bend').value = 0;
  $('bend').oninput();
};
$('mod').oninput = () => send({ type: 'cc', channel: keyChannel(), number: 1, value: Number($('mod').value) });
window.addEventListener('resize', buildKeyboard);

// Web MIDI: the device chosen plays the synth.
async function setUpMidi() {
  if (!navigator.requestMIDIAccess) {
    $('midi-note').textContent = 'this browser has no Web MIDI';
    return;
  }
  const access = await midiAccess();
  if (!access) {
    $('midi-note').textContent = 'MIDI not allowed';
    return;
  }

  const select = $('midi-in');
  const fill = () => {
    const was = select.value;
    select.replaceChildren(el('option', { value: '', textContent: 'none' }),
      ...[...access.inputs.values()].map((i) => el('option', { value: i.id, textContent: i.name })));
    select.value = [...access.inputs.keys()].includes(was) ? was : '';
  };
  fill();
  access.onstatechange = fill;

  let current = null;
  select.onchange = () => {
    if (current) current.onmidimessage = null;
    current = access.inputs.get(select.value) || null;
    if (current) current.onmidimessage = midiMessage;
  };
}

// System exclusive where the browser allows it (resets, master volume),
// else without; null if MIDI is not allowed at all.
async function midiAccess() {
  try {
    return await navigator.requestMIDIAccess({ sysex: true });
  } catch (e) {
    try {
      return await navigator.requestMIDIAccess();
    } catch (e2) {
      return null;
    }
  }
}

// Every message as it came, but the clock and the like (the synth reads it).
function midiMessage(event) {
  if (event.data[0] >= 0xf1) return;
  send({ type: 'midi', data: Array.from(event.data) });
}

// The header's height, for what stays in sight below it (it wraps when narrow).
function followBar() {
  const bar = document.querySelector('.bar');
  const set = () => document.documentElement.style.setProperty('--bar', `${bar.offsetHeight}px`);
  new ResizeObserver(set).observe(bar);
}

followBar();
buildKeyboard();
setUpMidi();
setupFolds();
connect();
