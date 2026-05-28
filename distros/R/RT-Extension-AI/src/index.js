export { default as RtExtensionAi } from './rtextensionai.js';
import { initNaturalLanguageSearch } from './naturalLanguageSearch.js';

// Use RT's htmx.onLoad to initialize when the page is ready
if (typeof window !== 'undefined' && typeof htmx !== 'undefined') {
  htmx.onLoad(function() {
    initNaturalLanguageSearch();
  });
}
