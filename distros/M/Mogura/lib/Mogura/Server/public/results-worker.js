'use strict';
importScripts('/result-cache.js');

const tables = new Map();
let clearing = false;

const pause = (milliseconds, signal) => new Promise((resolve, reject) => {
  const abort = () => {clearTimeout(timer); reject(new DOMException('Aborted', 'AbortError'));};
  const timer = setTimeout(() => {signal.removeEventListener('abort', abort); resolve();}, milliseconds);
  signal.addEventListener('abort', abort, {once: true});
  if (signal.aborted) abort();
});

async function downloadPage(url, signal) {
  while (true) {
    const response = await fetch(url, {signal});
    if (response.status === 202 || response.status === 429) {
      await pause(1000, signal);
      continue;
    }
    const page = await response.json();
    if (!response.ok) throw new Error(page.error || `HTTP ${response.status}`);
    if (!ResultCache.validPage(page) || page.revision !== new URL(url).searchParams.get('version')) {
      const error = new Error('Invalid result format');
      error.code = 'result_format_invalid';
      throw error;
    }
    return page;
  }
}

async function sendWindow(table, request) {
  table.controller?.abort();
  const controller = table.controller = new AbortController();
  const url = new URL(table.url);
  url.searchParams.set('query', request.query.trim());
  // Overlapping 60-row windows align to 30-row boundaries, so scrolling by
  // one row does not create another persisted copy of almost identical data.
  url.searchParams.set('start', Math.floor(request.start / 30) * 30);
  if (request.column !== null) url.searchParams.set('column', request.column);
  url.searchParams.set('descending', request.descending ? '1' : '0');
  const key = url.href;
  try {
    const last = table.last?.url === key ? table.last : null;
    let page = last ? last.page : await table.cache?.read(key);
    let saved = last ? last.saved : Boolean(page);
    if (!page) page = await downloadPage(key, controller.signal);
    if (controller.signal.aborted || clearing) return;
    const current = table.last = {url: key, page, saved};
    postMessage({type: 'rows', kind: table.kind, sequence: request.sequence, ...page});
    if (!saved) {
      // Serialize writes so clear-cache can wait for the final transaction,
      // including writes started by a superseded scroll request.
      table.writing = (table.writing || Promise.resolve()).then(() => table.cache?.write(key, page) || false);
      saved = await table.writing;
      current.saved = saved;
    }
    if (controller.signal.aborted || clearing) return;
    postMessage({type: 'cache-ready', kind: table.kind, available: Boolean(table.cache), saved});
  } catch (error) {
    if (controller.signal.aborted) return;
    postMessage({type: 'failure', kind: table.kind, sequence: request.sequence, message: error.message, code: error.code});
    postMessage({type: 'cache-ready', kind: table.kind, available: Boolean(table.cache), saved: null});
  }
}

async function loadTables(sources) {
  for (const {kind, url} of sources) {
    const previous = tables.get(kind);
    if (previous) {
      previous.controller?.abort();
      tables.delete(kind);
      await previous.writing;
      previous.cache?.database.close();
    }
    const cache = await ResultCache.open(kind);
    tables.set(kind, {kind, url, cache});
    postMessage({type: 'ready', kind});
  }
}

async function clearCachedResults() {
  clearing = true;
  for (const table of tables.values()) table.controller?.abort();
  let cleared = true;
  for (const table of tables.values()) {
    try {
      await table.writing;
      if (!table.cache) throw new Error('Cache unavailable');
      await table.cache.remove(table.url);
      table.last = null;
    } catch {cleared = false;}
  }
  clearing = false;
  postMessage({type: cleared ? 'cache-cleared' : 'cache-failure'});
}

self.onmessage = ({data}) => {
  if (data.type === 'load') loadTables(data.sources);
  else if (data.type === 'clear-cache') clearCachedResults();
  else if (data.type === 'window' && !clearing && tables.has(data.kind)) sendWindow(tables.get(data.kind), data);
};
