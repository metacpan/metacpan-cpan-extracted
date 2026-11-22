'use strict';

// Metadata and the compressed row blob are replaced in one transaction. A
// failed write rolls back both eviction and replacement, preserving old data.
class ResultCache {
  static databaseName = 'mogura-results-v1';
  static maximumBytes = 512 * 1024 * 1024;
  static kinds = ['packages', 'matches'];

  constructor(database, kind, budget) {
    this.database = database;
    this.kind = kind;
    this.budget = budget;
  }

  static async open(kind) {
    if (!this.kinds.includes(kind)) throw new Error('Unknown result kind');
    try {
      const database = await new Promise((resolve, reject) => {
        const request = indexedDB.open(this.databaseName, 1);
        let abandoned = false;
        request.onblocked = () => {
          abandoned = true;
          reject(new Error('Cache upgrade blocked'));
        };
        request.onerror = () => reject(request.error);
        request.onupgradeneeded = () => {
          for (const name of this.kinds) {
            const store = request.result.createObjectStore(name, {keyPath: 'url'});
            store.createIndex('path', 'path');
            store.createIndex('accessed', 'accessed');
          }
        };
        request.onsuccess = () => {
          const database = request.result;
          database.onversionchange = () => database.close();
          if (abandoned) database.close();
          else resolve(database);
        };
      });
      let budget = this.maximumBytes;
      try {
        const estimate = await navigator.storage.estimate();
        if (estimate.quota > 0) budget = Math.min(budget, Math.floor(estimate.quota / 4));
      } catch {}
      return new ResultCache(database, kind, budget);
    } catch {return null;}
  }

  transaction(mode, schedule) {
    return new Promise((resolve, reject) => {
      let transaction;
      try {
        transaction = this.database.transaction(this.kind, mode, {durability: 'strict'});
      } catch (error) {
        if (error.name !== 'TypeError') throw error;
        transaction = this.database.transaction(this.kind, mode);
      }
      let result;
      let failure;
      transaction.oncomplete = () => resolve(result);
      transaction.onabort = () => reject(failure || transaction.error || new Error('Cache transaction aborted'));
      const abort = error => {failure = error; transaction.abort();};
      try {schedule(transaction.objectStore(this.kind), value => {result = value;}, abort);} catch (error) {abort(error);}
    });
  }

  static validRows(rows) {
    return Array.isArray(rows) && rows.every(row => Array.isArray(row) && row.length === 5 && row.every(value => typeof value === 'string'));
  }

  static validPage(page) {
    return page && typeof page.revision === 'string'
      && ['start', 'count', 'total'].every(key => Number.isSafeInteger(page[key]) && page[key] >= 0)
      && page.count <= page.total && page.start <= page.count
      && this.validRows(page.rows) && page.rows.length <= 60
      && page.start + page.rows.length <= page.count;
  }

  async read(url) {
    try {
      const record = await this.transaction('readonly', (store, result) => {
        store.get(url).onsuccess = event => result(event.target.result);
      });
      if (!record || record.schema !== 1) return null;
      let stream = record.body.stream();
      if (record.encoding === 'gzip') stream = stream.pipeThrough(new DecompressionStream('gzip'));
      else if (record.encoding !== 'json') return null;
      const page = await new Response(stream).json();
      if (!ResultCache.validPage(page) || page.revision !== new URL(url).searchParams.get('version')) return null;
      try {
        await this.transaction('readwrite', (store, result, abort) => {
          store.get(url).onsuccess = event => {
            try {
              const current = event.target.result;
              if (current) store.put({...current, accessed: Date.now()});
            } catch (error) {abort(error);}
          };
        });
      } catch {}
      return page;
    } catch {return null;}
  }

  static async encode(page) {
    // Each response contains at most 60 rows; no whole-result string or object
    // is ever constructed in the browser.
    let stream = new Blob([JSON.stringify(page)]).stream();
    const compressed = typeof CompressionStream !== 'undefined' && typeof DecompressionStream !== 'undefined';
    if (compressed) stream = stream.pipeThrough(new CompressionStream('gzip'));
    return {body: await new Response(stream).blob(), encoding: compressed ? 'gzip' : 'json'};
  }

  async write(url, page) {
    try {
      const encoded = await ResultCache.encode(page);
      const record = {
        url, path: new URL(url).pathname, schema: 1, revision: page.revision,
        accessed: Date.now(), ...encoded,
        bytes: encoded.body.size + 512 + url.length * 2,
      };
      if (record.bytes > this.budget) return false;
      let extraEvictions = 0;
      while (true) {
        let remaining = 0;
        try {
          await this.transaction('readwrite', (store, result, abort) => {
            store.get('@usage').onsuccess = usageEvent => {
              let bytes = usageEvent.target.result?.bytes || 0;
              // Exact replacement and an LRU cursor keep writes independent of
              // the total number of saved pages. Old revisions age out normally.
              store.get(url).onsuccess = previousEvent => {
                try {
                  const previous = previousEvent.target.result;
                  if (previous) {
                    bytes -= previous.bytes;
                    store.delete(url);
                  }
                  let removed = 0;
                  store.index('accessed').openCursor().onsuccess = oldestEvent => {
                    try {
                      const oldest = oldestEvent.target.result;
                      if (oldest && (bytes + record.bytes > this.budget || removed < extraEvictions)) {
                        bytes -= oldest.value.bytes;
                        oldest.delete();
                        removed++;
                        oldest.continue();
                        return;
                      }
                      remaining = Boolean(oldest);
                      store.put(record);
                      store.put({url: '@usage', bytes: bytes + record.bytes});
                    } catch (error) {abort(error);}
                  };
                } catch (error) {abort(error);}
              };
            };
          });
          return true;
        } catch (error) {
          // Retrying changes only this kind's eviction plan. No deletion is
          // committed unless the new result also commits successfully.
          if (error.name !== 'QuotaExceededError' || !remaining) return false;
          extraEvictions = Math.max(1, extraEvictions * 2);
        }
      }
    } catch {return false;}
  }

  async remove(url) {
    const path = new URL(url).pathname;
    await this.transaction('readwrite', (store, result, abort) => {
      store.get('@usage').onsuccess = usageEvent => {
        let bytes = usageEvent.target.result?.bytes || 0;
        store.index('path').openCursor(path).onsuccess = event => {
          try {
            const cursor = event.target.result;
            if (cursor) {
              bytes -= cursor.value.bytes;
              cursor.delete();
              cursor.continue();
            } else {
              store.put({url: '@usage', bytes});
            }
          } catch (error) {abort(error);}
        };
      };
    });
  }

}
