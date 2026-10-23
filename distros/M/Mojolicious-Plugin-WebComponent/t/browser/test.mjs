import { chromium } from 'playwright';
const base = process.env.BASE;
const results = [];
const check = (name, ok, detail='') => { results.push(ok); console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  -> ' + detail : ''}`); };
// the app container installs Mojolicious before it listens
for (let i = 0; i < 240; i++) {
  try { await fetch(base + '/'); break; } catch { await new Promise(r => setTimeout(r, 1000)); }
}
// cold workers: the script route must answer from every prefork worker before any page was rendered
{
  const codes = [];
  for (let i = 0; i < 8; i++) codes.push((await fetch(`${base}/component/x/my-component.js`)).status);
  check('script route answers 200 from every worker before any page render', codes.every(c => c === 200), codes.join(' '));
  const outside = await fetch(`${base}/component/x/..%2f..%2f..%2f..%2fapp.pl`);
  check('path traversal is refused', outside.status === 404, String(outside.status));
}
const browser = await chromium.launch();
async function open(path) {
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(base + path);
  await page.waitForTimeout(300);
  return { page, errors };
}
{
  const { page, errors } = await open('/page?q=hello');
  check('page loads without JS errors', errors.length === 0, errors.join(' | '));
  for (const n of ['my-component', 'echo-box', 'tick-box', 'inline-box'])
    check(`${n} is defined`, await page.evaluate(n => !!customElements.get(n), n));
  check('my-component shadow root holds the template',
    await page.evaluate(() => document.querySelector('my-component')?.shadowRoot?.textContent.includes('This is a custom web component')));
  await page.evaluate(() => document.querySelector('my-component').setAttribute('message', 'hi there'));
  check('my-component message attribute updates #message',
    await page.evaluate(() => document.querySelector('my-component').shadowRoot.querySelector('#message').innerHTML) === 'hi there');
  check('request param reaches the template',
    await page.evaluate(() => document.querySelector('echo-box')?.shadowRoot?.querySelector('#q')?.textContent) === 'hello');
  check('non-ASCII in the template survives',
    await page.evaluate(() => document.querySelector('echo-box')?.shadowRoot?.querySelector('#u')?.textContent) === 'naïve €',
    await page.evaluate(() => document.querySelector('echo-box')?.shadowRoot?.querySelector('#u')?.textContent));
  check('backtick and backslash in a template survive (tick-box)',
    await page.evaluate(() => document.querySelector('tick-box')?.shadowRoot?.querySelector('#t')?.textContent) === '`tick` back\\slash',
    String(await page.evaluate(() => document.querySelector('tick-box')?.shadowRoot?.querySelector('#t')?.textContent)));
  check('non-ASCII in the component script survives',
    await page.evaluate(() => document.querySelector('echo-box')?.dataset.script) === 'café €',
    await page.evaluate(() => document.querySelector('echo-box')?.dataset.script));
  check('template => undef skips templating (inline-box renders)',
    await page.evaluate(() => document.querySelector('inline-box')?.shadowRoot?.querySelector('#in')?.textContent) === 'inline ok');
  await page.close();
}
// the checksum url is the same on every page view (and from every worker), so the browser caches the script
{
  // one context, so both page views share an HTTP cache
  const context = await browser.newContext();
  const src = async () => {
    const page = await context.newPage();
    await page.goto(base + '/page?q=cache');
    await page.waitForTimeout(300);
    const out = await page.evaluate(() => ({
      src: document.querySelector('script[src*="my-component.js"]').getAttribute('src'),
      transfer: performance.getEntriesByType('resource').filter(e => e.name.includes('my-component.js')).map(e => e.transferSize),
    }));
    await page.close();
    return out;
  };
  const first = await src(), second = await src();
  check('script url is stable across page views', first.src === second.src, `${first.src} | ${second.src}`);
  check('second page view takes the script from the browser cache', second.transfer.length === 1 && second.transfer[0] === 0, second.transfer.join(','));
  const res = await fetch(base + first.src);
  check('script is served immutable for its own checksum', res.headers.get('cache-control') === 'public, max-age=31536000, immutable', res.headers.get('cache-control'));
  const stale = await fetch(base + first.src.replace(/\/[0-9a-f]{40}\//, '/' + '0'.repeat(40) + '/'));
  check('a stale checksum is served no-cache', stale.status === 200 && stale.headers.get('cache-control') === 'no-cache', stale.headers.get('cache-control'));
}
for (const [label, qs] of [['${} in a param echoed by a template', 'q=' + encodeURIComponent('${window.__pwned=1}')],
                           ['backtick in the template param (404 message)', 'template=' + encodeURIComponent('`;window.__pwned=1;`')]]) {
  const { page } = await open('/page?' + qs);
  const pwned = await page.evaluate(() => window.__pwned === 1);
  check(`XSS blocked: ${label}`, !pwned, pwned ? 'attacker code RAN in the page' : '');
  await page.close();
}
await browser.close();
const failed = results.filter(x => !x).length;
console.log(`\n${results.length - failed}/${results.length} passed`);
process.exit(failed ? 1 : 0);
