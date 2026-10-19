// The player: a ring buffer of stereo frames that the page fills with what
// the server sends, played 128 frames at a time. It says how many frames it
// has played, which is the clock the server renders by.

class PetaSynthPlayer extends AudioWorkletProcessor {
  constructor() {
    super();
    this.size = sampleRate * 2;            // two seconds of room
    this.left = new Float32Array(this.size);
    this.right = new Float32Array(this.size);
    this.read = 0;
    this.write = 0;
    this.count = 0;
    this.played = 0;                       // frames taken from the buffer (or dropped)
    this.starved = 0;                      // quanta of 128 played as silence
    this.sinceReport = 0;
    this.port.onmessage = (event) => this.push(event.data);
  }

  push(frames) {
    const n = frames.length >> 1;
    for (let i = 0; i < n; i++) {
      if (this.count === this.size) {      // full: the oldest frame goes, counted as played
        this.read = (this.read + 1) % this.size;
        this.count--;
        this.played++;
      }
      this.left[this.write] = frames[2 * i];
      this.right[this.write] = frames[2 * i + 1];
      this.write = (this.write + 1) % this.size;
      this.count++;
    }
  }

  process(inputs, outputs) {
    const out = outputs[0];
    const l = out[0];
    const r = out[1] || out[0];
    const n = l.length;
    if (this.count < n) {
      l.fill(0);
      r.fill(0);
      this.starved++;
    } else {
      for (let i = 0; i < n; i++) {
        l[i] = this.left[this.read];
        r[i] = this.right[this.read];
        this.read = (this.read + 1) % this.size;
      }
      this.count -= n;
      this.played += n;
    }
    this.sinceReport += n;
    if (this.sinceReport >= sampleRate / 50) {    // fifty times a second
      this.sinceReport = 0;
      this.port.postMessage({ played: this.played, buffered: this.count, starved: this.starved });
    }
    return true;
  }
}

registerProcessor('peta-synth-player', PetaSynthPlayer);
