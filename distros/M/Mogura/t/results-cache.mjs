import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createServer} from 'node:http';
import {readFile, mkdtemp, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {chromium} from 'playwright';

// Use real IndexedDB transactions, Blob persistence and worker lifetimes.
// An in-memory API mock cannot establish rollback or reopen behavior.
const scripts = new Map(await Promise.all(['i18n.js', 'result-cache.js', 'results-worker.js', 'results.js'].map(async name => [name, await readFile(`lib/Mogura/Server/public/${name}`)])));
const catalogs = Object.fromEntries(await Promise.all(['ja', 'en'].map(async locale => [locale, JSON.parse(await readFile(`lib/Mogura/Server/public/locales/${locale}.json`, 'utf8'))])));
const requests = [];
let pending = 0;
let generation = 0;
let buildPolls = 0;
let failBuild = false;
const server = createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (url.pathname.startsWith('/scans/')) requests.push(url.href);
  const script = scripts.get(url.pathname.slice(1));
  if (script) {
    response.setHeader('Content-Type', 'text/javascript; charset=utf-8');
    response.end(script);
    return;
  }
  if (url.pathname.endsWith('/rebuild')) {
    generation++;
    buildPolls = 1;
    response.writeHead(202, {'Content-Type': 'application/json'});
    response.end(JSON.stringify({status_url: '/scans/a/results/matches/build'}));
    return;
  }
  if (url.pathname.endsWith('/build')) {
    response.setHeader('Content-Type', 'application/json');
    response.end(JSON.stringify({state: buildPolls-- > 0 ? 'running' : failBuild ? 'failed' : 'ready', url: `/scans/a/results/matches?version=build${generation}`}));
    return;
  }
  if (url.pathname.includes('/results/')) {
    response.setHeader('Content-Type', 'application/json');
    if (pending-- > 0) {response.writeHead(202); response.end('{"pending":1}'); return;}
    const total = 12050;
    const start = Number(url.searchParams.get('start') || 0);
    const query = url.searchParams.get('query');
    const count = query === 'target' ? 1 : total;
    const rows = Array.from({length: Math.min(60, count - start)}, (_, i) => [`CVE-${start + i}`, query || 'package', '1.0', 'High', '2.0']);
    if (start === 0 && !query) rows[0] = ['CVE-0', '不明', '0', 'Unknown', ''];
    response.end(JSON.stringify({revision: url.searchParams.get('version'), total, count, start, rows}));
    return;
  }
  if (url.pathname === '/ui' || url.pathname === '/build-ui') {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    const locale = url.searchParams.get('lang') === 'en' ? 'en' : 'ja';
    const messages = JSON.stringify(catalogs[locale]).replaceAll('&', '&amp;').replaceAll('\"', '&quot;').replaceAll('<', '&lt;');
    response.end(`<html lang="${locale}"><body><textarea id="draft"></textarea>${['packages', 'matches'].map(kind => `
      <section data-result-table="${kind}" data-source="${url.pathname === '/build-ui' && kind === 'matches' ? '' : `/scans/a/results/${kind}?version=v1`}">
        <input data-result-search disabled><span data-result-count></span><p data-result-status>読み込み中…</p>
        <div data-result-viewport style="height:572px;overflow:auto" hidden><table><thead><tr>${[0,1,2,3,4].map(column => `<th><button data-sort="${column}" disabled>Sort<span data-sort-indicator></span></button></th>`).join('')}</tr></thead><tbody></tbody></table></div>
        <nav data-result-pager hidden><button data-page-step="-1">前へ</button><span data-page-range></span><button data-page-step="1">次へ</button></nav>
      </section>`).join('')}${url.pathname === '/build-ui' ? '<form action="/scans/a/results/matches/rebuild" data-result-build="matches"><button>一覧を作成</button><span data-build-message></span><progress data-build-progress hidden></progress></form>' : ''}<span data-cache-status hidden></span><button data-clear-cache disabled>Clear</button><script src="/i18n.js" data-messages="${messages}"></script><script src="/results.js"></script></body></html>`);
    return;
  }
  response.setHeader('Content-Type', 'text/html; charset=utf-8');
  response.end('<html><body><script src="/result-cache.js"></script></body></html>');
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const origin = `http://127.0.0.1:${server.address().port}`;
const profile = await mkdtemp(join(tmpdir(), 'mogura-idb-'));
let context;
const open = async () => {
  context = await chromium.launchPersistentContext(profile, {headless: true});
  const page = await context.newPage();
  await page.goto(origin);
  return page;
};
let page;
try {
  page = await open();
  await test('separate compressed caches survive browser close and reopen', async () => {
    assert.deepEqual(await page.evaluate(async () => {
      const result = {revision: 'v1', total: 1, count: 1, start: 0, rows: [['日本語', 'b', 'c', 'd', 'e']]};
      const saved = [];
      for (const kind of ['packages', 'matches']) {
        const cache = await ResultCache.open(kind);
        saved.push(await cache.write(`${location.origin}/scans/persist/results/${kind}?version=v1`, result));
        cache.database.close();
      }
      return saved;
    }), [true, true]);
    await context.close();
    page = await open();
    assert.deepEqual(await page.evaluate(async () => {
      const values = [];
      for (const kind of ['packages', 'matches']) {
        const cache = await ResultCache.open(kind);
        values.push((await cache.read(`${location.origin}/scans/persist/results/${kind}?version=v1`)).rows[0][0]);
        cache.database.close();
      }
      return values;
    }), ['日本語', '日本語']);
  });
  await test('quota failure rolls back eviction and revision replacement', async () => {
    assert.deepEqual(await page.evaluate(async () => {
      const cache = await ResultCache.open('matches');
      const url = `${location.origin}/scans/atomic/results/grype?version=v1`;
      const result = {revision: 'v1', total: 1, count: 1, start: 0, rows: [['old', 'b', 'c', 'd', 'e']]};
      await cache.write(url, result);
      const original = IDBObjectStore.prototype.put;
      IDBObjectStore.prototype.put = function() {throw new DOMException('Injected quota failure', 'QuotaExceededError');};
      let saved;
      try {saved = await cache.write(url.replace('v1', 'v2'), {...result, revision: 'v2'});}
      finally {IDBObjectStore.prototype.put = original;}
      const old = await cache.read(url);
      const packages = await ResultCache.open('packages');
      const sibling = await packages.read(`${location.origin}/scans/persist/results/packages?version=v1`);
      cache.database.close(); packages.database.close();
      return [saved, old.rows[0][0], sibling.rows[0][0]];
    }), [false, 'old', '日本語']);
  });
  await test('same-revision pages coexist; clearing one result preserves others', async () => {
    assert.deepEqual(await page.evaluate(async () => {
      const cache = await ResultCache.open('packages');
      const url = `${location.origin}/scans/pages/results/syft?version=v1&start=`;
      const result = {revision: 'v1', total: 100, count: 100, start: 0, rows: [['first', 'b', 'c', 'd', 'e']]};
      await cache.write(url + '0', result);
      await cache.write(url + '30', {...result, start: 30});
      const both = Boolean(await cache.read(url + '0')) && Boolean(await cache.read(url + '30'));
      await cache.remove(url + '0');
      const removed = !await cache.read(url + '30');
      const other = Boolean(await cache.read(`${location.origin}/scans/persist/results/packages?version=v1`));
      cache.database.close();
      return [both, removed, other];
    }), [true, true, true]);
  });
  await test('eviction is local to its kind and respects recent reads', async () => {
    assert.deepEqual(await page.evaluate(async () => {
      const cache = await ResultCache.open('matches');
      await cache.transaction('readwrite', store => store.clear());
      const result = {revision: 'v1', total: 1, count: 1, start: 0, rows: [['row', 'b', 'c', 'd', 'e']]};
      const url = n => `${location.origin}/scans/lru${n}/results/grype?version=v1`;
      await cache.write(url(1), result);
      const bytes = await cache.transaction('readonly', (store, done) => {store.get(url(1)).onsuccess = event => done(event.target.result.bytes);});
      cache.budget = bytes * 2 + 20;
      await new Promise(resolve => setTimeout(resolve, 5));
      await cache.write(url(2), result);
      await new Promise(resolve => setTimeout(resolve, 5));
      await cache.read(url(1));
      await cache.write(url(3), result);
      const present = await Promise.all([1,2,3].map(async n => Boolean(await cache.read(url(n)))));
      cache.database.close();
      return present;
    }), [true, false, true]);
  });
  await test('paged worker handles preparation, reuses cache, searches and navigates large results', async () => {
    pending = 1;
    const failures = [];
    page.on('pageerror', error => failures.push(error.message));
    await page.goto(`${origin}/ui`);
    await page.waitForFunction(() => [...document.querySelectorAll('[data-result-count]')].every(node => node.textContent === '12,050 件'));
    await page.waitForFunction(() => !document.querySelector('[data-clear-cache]').disabled);
    const downloaded = requests.length;
    assert(downloaded >= 3, 'initial preparation was polled');
    await page.reload();
    await page.waitForFunction(() => [...document.querySelectorAll('[data-result-count]')].every(node => node.textContent === '12,050 件'));
    await page.waitForFunction(() => !document.querySelector('[data-clear-cache]').disabled);
    assert.equal(requests.length, downloaded, 'reopening uses persisted pages without result downloads');
    const matches = page.locator('[data-result-table="matches"]');
    let releasePage;
    let pageRequested;
    const pageGate = new Promise(resolve => {releasePage = resolve;});
    const requested = new Promise(resolve => {pageRequested = resolve;});
    await page.route('**/scans/a/results/matches?**', async route => {
      pageRequested();
      await pageGate;
      await route.continue();
    });
    await matches.locator('[data-page-step="1"]').click();
    await requested;
    await matches.locator('[data-page-step="1"]').evaluate(button => {button.click(); button.click();});
    releasePage();
    await matches.locator('tbody tr:not([data-spacer])').first().waitFor();
    await page.waitForFunction(() => document.querySelector('[data-result-table="matches"] [data-page-range]').textContent === '61–120 / 12,050 件');
    await page.unroute('**/scans/a/results/matches?**');
    assert.equal(await matches.locator('tbody tr:not([data-spacer]) td').first().textContent(), 'CVE-60');
    assert(await matches.locator('[data-result-viewport]').evaluate(node => node.scrollHeight) < 3000);
    await matches.locator('[data-result-search]').fill('target');
    await page.waitForFunction(() => document.querySelector('[data-result-table="matches"] [data-result-count]').textContent === '1 / 12,050 件');
    assert.equal(await matches.locator('tbody tr:not([data-spacer]) td').nth(1).textContent(), 'target');
    await page.locator('[data-clear-cache]').click();
    await page.waitForFunction(() => document.querySelector('[data-cache-status]').textContent === 'キャッシュを削除しました。');
    const beforeReload = requests.length;
    await page.reload();
    await page.waitForFunction(() => [...document.querySelectorAll('[data-result-count]')].every(node => node.textContent === '12,050 件'));
    assert.equal(requests.length, beforeReload + 2, 'cleared results fetched independently');
    assert.deepEqual(failures, []);
    assert(requests.every(url => !url.includes('/download/')), 'raw JSON never requested');
  });
  await test('English counts, search and cache messages reuse pages saved in Japanese', async () => {
    const firstRow = page.locator('[data-result-table="matches"] tbody tr').first().locator('td');
    assert.deepEqual(await firstRow.allTextContents(), ['CVE-0', '不明', '0', 'Unknown', '不明']);
    const before = requests.length;
    await page.goto(`${origin}/ui?lang=en`);
    await page.waitForFunction(() => [...document.querySelectorAll('[data-result-count]')].every(node => node.textContent === '12,050 results'));
    await page.waitForFunction(() => !document.querySelector('[data-clear-cache]').disabled);
    assert.equal(requests.length, before, 'language changes reuse the same result cache');
    assert.deepEqual(await firstRow.allTextContents(), ['CVE-0', '不明', '0', 'Unknown', 'Unknown']);
    const matches = page.locator('[data-result-table="matches"]');
    await matches.locator('[data-result-search]').fill('target');
    await page.waitForFunction(() => document.querySelector('[data-result-table="matches"] [data-result-count]').textContent === '1 / 12,050 results');
    await page.locator('[data-clear-cache]').click();
    await page.waitForFunction(() => document.querySelector('[data-cache-status]').textContent === 'Cache cleared.');
  });
  await test('worker validation errors use the page language in both locales', async () => {
    for (const locale of ['ja', 'en']) {
      const isolated = await context.browser().newContext();
      await isolated.route('**/scans/a/results/*?**', route => route.fulfill({
        contentType: 'application/json', body: JSON.stringify({revision: 'wrong'}),
      }));
      const tab = await isolated.newPage();
      await tab.goto(`${origin}/ui?lang=${locale}`);
      await tab.waitForFunction(message => [...document.querySelectorAll('[data-result-status]')].every(node => node.textContent === message), catalogs[locale].result_format_invalid);
      await isolated.close();
    }
  });
  await test('one kind failing to save does not redownload or evict its sibling', async () => {
    const isolated = await context.browser().newContext();
    await isolated.route('**/results-worker.js', route => route.fulfill({
      contentType: 'text/javascript; charset=utf-8',
      body: `const originalPut = IDBObjectStore.prototype.put;
        IDBObjectStore.prototype.put = function(...args) {
          if (this.name === 'matches') throw new DOMException('Injected failure', 'QuotaExceededError');
          return originalPut.apply(this, args);
        };\n${scripts.get('results-worker.js')}`,
    }));
    const tab = await isolated.newPage();
    await tab.goto(`${origin}/ui`);
    await tab.waitForFunction(() => document.querySelector('[data-cache-status]').textContent === '脆弱性の一覧をこのブラウザーに保存できませんでした。');
    const before = requests.length;
    await tab.reload();
    await tab.waitForFunction(() => document.querySelector('[data-cache-status]').textContent === '脆弱性の一覧をこのブラウザーに保存できませんでした。');
    assert.equal(requests.length, before + 1);
    assert(requests.at(-1).includes('/results/matches?'));
    await isolated.close();
  });
  await test('unavailable IndexedDB still displays paged results and reports save failure', async () => {
    const isolated = await context.browser().newContext();
    await isolated.route('**/results-worker.js', route => route.fulfill({
      contentType: 'text/javascript; charset=utf-8',
      body: `IDBFactory.prototype.open = () => {throw new DOMException('Denied', 'SecurityError');};\n${scripts.get('results-worker.js')}`,
    }));
    const tab = await isolated.newPage();
    await tab.goto(`${origin}/ui`);
    await tab.waitForFunction(() => [...document.querySelectorAll('[data-result-count]')].every(node => node.textContent === '12,050 件'));
    await tab.waitForFunction(() => document.querySelector('[data-cache-status]').textContent.includes('パッケージ・脆弱性'));
    assert.equal(await tab.locator('[data-clear-cache]').isVisible(), false);
    await isolated.close();
  });
  await test('manual creation and rebuild preserve drafts, old rows, and the sibling cache', async () => {
    await page.goto(`${origin}/build-ui`);
    await page.waitForFunction(() => document.querySelector('[data-result-table="packages"] [data-result-count]').textContent === '12,050 件');
    const matches = page.locator('[data-result-table="matches"]');
    await page.locator('#draft').fill('unsaved note');
    const siblingRequests = () => requests.filter(url => url.includes('/results/packages?')).length;
    const before = siblingRequests();
    await page.locator('[data-result-build] button').click();
    await page.waitForFunction(() => document.querySelector('[data-result-table="matches"]').dataset.source.endsWith('build1'));
    await matches.locator('tbody tr:not([data-spacer])').first().waitFor();
    await page.locator('[data-result-build] button').click();
    assert.equal(await matches.locator('[data-result-viewport]').isVisible(), true, 'old rows remain during rebuild');
    await page.waitForFunction(() => document.querySelector('[data-result-table="matches"]').dataset.source.endsWith('build2'));
    await page.waitForFunction(() => !document.querySelector('[data-clear-cache]').disabled);
    assert(requests.some(url => url.includes('version=build2')), 'new generation bypasses old page cache');
    assert.equal(await page.locator('#draft').inputValue(), 'unsaved note');
    assert.equal(siblingRequests(), before, 'rebuilding matches does not reload packages');
    failBuild = true;
    await page.locator('[data-result-build] button').click();
    await page.waitForFunction(() => document.querySelector('[data-build-message]').textContent.includes('失敗'));
    assert.equal(await page.locator('[data-result-build] button').isEnabled(), true);
    assert((await matches.getAttribute('data-source')).endsWith('build2'), 'failed rebuild keeps previous generation');
    assert.equal(await matches.locator('[data-result-viewport]').isVisible(), true);
    failBuild = false;
  });
} finally {
  await context?.close();
  await new Promise(resolve => server.close(resolve));
  await rm(profile, {recursive: true, force: true});
}
