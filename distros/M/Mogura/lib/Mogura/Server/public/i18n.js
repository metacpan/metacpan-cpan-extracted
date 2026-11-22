'use strict';

// The server escapes this JSON as an HTML attribute; no inline script or
// additional request is needed before the controls become usable.
globalThis.MoguraI18n = (() => {
  const messages = JSON.parse(document.currentScript.dataset.messages);
  const locale = document.documentElement.lang;
  const numbers = new Intl.NumberFormat(locale);
  return Object.freeze({
    number: value => numbers.format(value),
    t: (key, values = {}) => (messages[key] ?? key).replace(/\{([a-z_]+)\}/g, (match, name) => values[name] ?? match),
  });
})();
