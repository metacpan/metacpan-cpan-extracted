/**
 * Funky.Pages - Page Registry and Cache System
 * 
 * Manages page modules for the SPA, providing:
 * - Page registration with lifecycle hooks (init, destroy, update)
 * - HTML + state caching for instant navigation
 * - Entity-based cache invalidation for WebSocket integration
 * 
 * @module Funky.Pages
 */
(function(window) {
	'use strict';

	// Ensure Funky namespace exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Pages] Funky registry not found. Load namespace.js first.');
		return;
	}

	// Guard against re-registration
	if (Funky.has('Pages')) {
		console.warn('[Funky.Pages] Already registered');
		return;
	}

	// ============================================
	// Configuration
	// ============================================

	var CONFIG = {
		cacheTTL: 5 * 60 * 1000, // 5 minutes default
		maxCacheSize: 20, // Max pages to cache
		debug: false // Enable debug logging
	};

	// ============================================
	// Private State
	// ============================================

	// Registered page modules: pageId → PageModule
	var registry = {};

	// Cached page data: pageId → { html, timestamp, scrollY, state, stale }
	var cache = {};

	// Entity → pageId[] mapping for WebSocket invalidation
	var entityMap = {};

	// Currently active page
	var activePage = null;

	// Managed pages (pages that have been mounted via Pages system)
	var managedPages = {};

	// ============================================
	// Logging
	// ============================================

	function log() {
		if (CONFIG.debug) {
			var args = ['[Funky.Pages]'].concat(Array.prototype.slice.call(arguments));
			console.log.apply(console, args);
		}
	}

	// ============================================
	// Form State Preservation Utilities
	// ============================================

	/**
	 * Capture form state from all forms in a container
	 * @param {string} [containerSelector] - Container to search (default: #spaContent)
	 * @returns {Object} - Form states keyed by form id or index
	 */
	function captureFormState(containerSelector) {
		var container;
		try {
			container = document.querySelector(containerSelector || '#spaContent');
		} catch (e) {
			// Invalid selector - return empty state
			return {};
		}
		if (!container) return {};

		var forms = container.querySelectorAll('form');
		var formStates = {};

		forms.forEach(function(form, index) {
			var formId = form.id || 'form_' + index;
			var formData = {};

			// Get all form elements
			var elements = form.querySelectorAll('input, select, textarea');
			elements.forEach(function(el) {
				var name = el.name || el.id;
				if (!name) return;

				if (el.type === 'checkbox') {
					formData[name] = el.checked;
				} else if (el.type === 'radio') {
					if (el.checked) {
						formData[name] = el.value;
					}
				} else if (el.tagName === 'SELECT' && el.multiple) {
					formData[name] = Array.from(el.selectedOptions).map(function(opt) {
						return opt.value;
					});
				} else {
					formData[name] = el.value;
				}
			});

			// Capture focus state
			var activeEl = document.activeElement;
			if (form.contains(activeEl) && (activeEl.name || activeEl.id)) {
				formData._focusedElement = activeEl.name || activeEl.id;
				formData._selectionStart = activeEl.selectionStart;
				formData._selectionEnd = activeEl.selectionEnd;
			}

			if (Object.keys(formData).length > 0) {
				formStates[formId] = formData;
			}
		});

		log('Captured form state:', formStates);
		return formStates;
	}

	/**
	 * Restore form state to forms in a container
	 * @param {Object} formStates - Form states from captureFormState()
	 * @param {string} [containerSelector] - Container to search (default: #spaContent)
	 */
	function restoreFormState(formStates, containerSelector) {
		if (!formStates || Object.keys(formStates).length === 0) return;

		var container = document.querySelector(containerSelector || '#spaContent');
		if (!container) return;

		log('Restoring form state:', formStates);

		Object.keys(formStates).forEach(function(formId) {
			var formData = formStates[formId];
			var form = container.querySelector('#' + formId) ||
				container.querySelectorAll('form')[parseInt(formId.replace('form_', ''), 10)];

			if (!form) return;

			Object.keys(formData).forEach(function(name) {
				if (name.startsWith('_')) return; // Skip meta fields

				var value = formData[name];
				var el = form.querySelector('[name="' + name + '"], #' + name);

				if (!el) return;

				if (el.type === 'checkbox') {
					el.checked = !!value;
				} else if (el.type === 'radio') {
					var radio = form.querySelector('[name="' + name + '"][value="' + value + '"]');
					if (radio) radio.checked = true;
				} else if (el.tagName === 'SELECT' && el.multiple) {
					Array.from(el.options).forEach(function(opt) {
						opt.selected = value.indexOf(opt.value) !== -1;
					});
					// MAYBE WE WANT TO HOOK IN COMBO BOX HERE
					// if (window.jQuery && jQuery(el).data('select2')) {
					// 	jQuery(el).trigger('change');
					// }
				} else {
					el.value = value;
					// MAYBE WE WANT TO HOOK IN COMBO BOX HERE
					// if (el.tagName === 'SELECT' && window.jQuery && jQuery(el).data('select2')) {
					// 	jQuery(el).trigger('change');
					// }
				}
			});

			// Restore focus
			if (formData._focusedElement) {
				var focusEl = form.querySelector('[name="' + formData._focusedElement + '"], #' + formData._focusedElement);
				if (focusEl) {
					focusEl.focus();
					if (focusEl.setSelectionRange && formData._selectionStart !== undefined) {
						try {
							focusEl.setSelectionRange(formData._selectionStart, formData._selectionEnd);
						} catch (e) {
							// Some input types don't support setSelectionRange
						}
					}
				}
			}
		});
	}

	// ============================================
	// Partial Re-render Utilities
	// ============================================

	/**
	 * Update specific elements in a container without full re-init
	 * Useful for partial page updates from WebSocket data
	 * 
	 * @param {string} selector - Elements to update (e.g., '[data-entity-id="123"]')
	 * @param {Function} updateFn - Function(element) that updates the element
	 * @param {Object} [options] - Options
	 * @param {string} [options.container] - Container selector (default: #spaContent)
	 * @returns {number} - Number of elements updated
	 */
	function updateElements(selector, updateFn, options) {
		options = options || {};
		var container = document.querySelector(options.container || '#spaContent');
		if (!container) return 0;
		if (!updateFn || typeof updateFn !== 'function') return 0;

		var elements;
		try {
			elements = container.querySelectorAll(selector);
		} catch (e) {
			// Invalid selector
			return 0;
		}
		var count = 0;

		elements.forEach(function(el) {
			try {
				updateFn(el);
				count++;
			} catch (err) {
				console.error('[Funky.Pages] Error updating element:', err);
			}
		});

		log('Updated', count, 'elements matching', selector);
		return count;
	}

	/**
	 * Update a single row in a table (for DataTable-like partial updates)
	 * @param {string} tableSelector - Table selector
	 * @param {string|number} rowId - Row identifier (data-id attribute value)
	 * @param {Object} data - New data for the row
	 * @param {Function} renderFn - Function(data) that returns row HTML
	 * @returns {boolean} - Whether row was found and updated
	 */
	function updateTableRow(tableSelector, rowId, data, renderFn) {
		var table = document.querySelector(tableSelector);
		if (!table) return false;

		var row = table.querySelector('tr[data-id="' + rowId + '"]');
		if (!row) return false;

		try {
			var newHtml = renderFn(data);
			row.outerHTML = newHtml;
			log('Updated table row:', rowId);
			return true;
		} catch (err) {
			console.error('[Funky.Pages] Error updating table row:', err);
			return false;
		}
	}

	/**
	 * Remove a row from a table
	 * @param {string} tableSelector - Table selector
	 * @param {string|number} rowId - Row identifier (data-id attribute value)
	 * @returns {boolean} - Whether row was found and removed
	 */
	function removeTableRow(tableSelector, rowId) {
		var table = document.querySelector(tableSelector);
		if (!table) return false;

		var row = table.querySelector('tr[data-id="' + rowId + '"]');
		if (!row) return false;

		row.parentNode.removeChild(row);
		log('Removed table row:', rowId);
		return true;
	}

	/**
	 * Add a row to a table
	 * @param {string} tableSelector - Table selector
	 * @param {Object} data - Data for the new row
	 * @param {Function} renderFn - Function(data) that returns row HTML
	 * @param {Object} [options] - Options
	 * @param {boolean} [options.prepend] - Add to beginning (default: false, append)
	 * @returns {boolean} - Whether row was added
	 */
	function addTableRow(tableSelector, data, renderFn, options) {
		options = options || {};
		var table = document.querySelector(tableSelector);
		if (!table) return false;

		var tbody = table.querySelector('tbody') || table;

		try {
			var newHtml = renderFn(data);
			if (options.prepend && tbody.firstElementChild) {
				tbody.firstElementChild.insertAdjacentHTML('beforebegin', newHtml);
			} else {
				tbody.insertAdjacentHTML('beforeend', newHtml);
			}
			log('Added table row');
			return true;
		} catch (err) {
			console.error('[Funky.Pages] Error adding table row:', err);
			return false;
		}
	}

	// ============================================
	// Registry Methods
	// ============================================

	/**
	 * Register a page module
	 * @param {string} pageId - Unique page identifier (matches data-page attribute)
	 * @param {Object} module - Page module with lifecycle methods
	 * @param {string} module.id - Page identifier
	 * @param {string[]} [module.entities] - Entity types this page displays
	 * @param {Function} module.init - Called when page becomes visible
	 * @param {Function} module.destroy - Called before navigating away, returns state
	 * @param {Function} [module.update] - Called for targeted WebSocket updates
	 * @param {Object} [module.subRoutes] - Sub-route configuration (convenience wrapper for SPA.SubRouter)
	 * @param {Function} module.subRoutes.activate - Called on sub-route navigation (context) => state
	 * @param {Function} module.subRoutes.restore - Called on browser back/forward (state, context)
	 * @param {Function} [module.subRoutes.deactivate] - Called before navigating away from sub-route
	 */
	function register(pageIdOrModule, module) {
		var pageId, pageModule;

		// Support both signatures: register(module) and register(pageId, module)
		if (typeof pageIdOrModule === 'object' && pageIdOrModule !== null) {
			// Called as register(module) - extract id from module
			pageModule = pageIdOrModule;
			pageId = pageModule.id;
		} else {
			// Called as register(pageId, module)
			pageId = pageIdOrModule;
			pageModule = module;
		}

		if (!pageId || typeof pageId !== 'string') {
			console.error('[Funky.Pages] Invalid pageId:', pageId);
			return false;
		}

		if (registry[pageId]) {
			log('Page already registered:', pageId);
			return false;
		}

		// Validate required methods
		if (typeof pageModule.init !== 'function') {
			console.error('[Funky.Pages] Page module must have init() method:', pageId);
			return false;
		}

		// Store the module
		registry[pageId] = pageModule;

		// Build entity → page mapping
		if (pageModule.entities && Array.isArray(pageModule.entities)) {
			pageModule.entities.forEach(function(entity) {
				if (!entityMap[entity]) {
					entityMap[entity] = [];
				}
				if (entityMap[entity].indexOf(pageId) === -1) {
					entityMap[entity].push(pageId);
				}
			});
		}

		// Register sub-routes with SPA.SubRouter if defined
		if (pageModule.subRoutes && Funky.SPA && Funky.SPA.SubRouter) {
			// Derive base path from pageId (e.g., 'docs' → '/docs')
			var basePath = '/' + pageId.replace(/^\/+/, '');

			var registered = Funky.SPA.SubRouter.register(basePath, {
				activate: pageModule.subRoutes.activate,
				restore: pageModule.subRoutes.restore,
				deactivate: pageModule.subRoutes.deactivate,
				queryOnly: pageModule.subRoutes.queryOnly || false
			});

			if (registered) {
				log('Registered sub-routes for:', basePath);
			}
		}

		log('Registered page:', pageId, pageModule.entities || []);
		return true;
	}

	/**
	 * Get a registered page module
	 * @param {string} pageId
	 * @returns {Object|null}
	 */
	function get(pageId) {
		return registry[pageId] || null;
	}

	/**
	 * Check if a page is registered
	 * @param {string} pageId
	 * @returns {boolean}
	 */
	function has(pageId) {
		return Object.prototype.hasOwnProperty.call(registry, pageId);
	}

	/**
	 * Check if a page is currently managed by the Pages system
	 * @param {string} pageId
	 * @returns {boolean}
	 */
	function isManaged(pageId) {
		return Object.prototype.hasOwnProperty.call(managedPages, pageId);
	}

	/**
	 * List all registered pages
	 * @returns {string[]}
	 */
	function list() {
		return Object.keys(registry);
	}

	/**
	 * Get the currently active page ID
	 * @returns {string|null}
	 */
	function getActivePage() {
		return activePage;
	}

	// ============================================
	// Cache Methods
	// ============================================

	var cacheAPI = {
		/**
		 * Store page HTML and state in cache
		 * @param {string} pageId
		 * @param {string} html - Page HTML content
		 * @param {Object} [state] - Optional state to preserve
		 */
		set: function(pageId, html, state) {
			// Enforce cache size limit
			var keys = Object.keys(cache);
			if (keys.length >= CONFIG.maxCacheSize) {
				// Remove oldest entry
				var oldest = keys.reduce(function(a, b) {
					return cache[a].timestamp < cache[b].timestamp ? a : b;
				});
				delete cache[oldest];
				log('Cache evicted:', oldest);
			}

			cache[pageId] = {
				html: html,
				timestamp: Date.now(),
				scrollY: state && state.scrollY || 0,
				state: state || {},
				stale: false
			};

			log('Cache set:', pageId);
		},

		/**
		 * Get cached page data
		 * @param {string} pageId
		 * @returns {Object|null} - { html, timestamp, scrollY, state, stale }
		 */
		get: function(pageId) {
			var entry = cache[pageId];

			if (!entry) {
				return null;
			}

			// Check TTL
			if (Date.now() - entry.timestamp > CONFIG.cacheTTL) {
				log('Cache expired:', pageId);
				delete cache[pageId];
				return null;
			}

			// Check if stale (marked for refresh)
			if (entry.stale) {
				log('Cache stale:', pageId);
				return null;
			}

			log('Cache hit:', pageId);
			return entry;
		},

		/**
		 * Update cached state for a page
		 * @param {string} pageId
		 * @param {Object} state
		 */
		updateState: function(pageId, state) {
			if (cache[pageId]) {
				Object.assign(cache[pageId].state, state);
				cache[pageId].scrollY = state.scrollY || cache[pageId].scrollY;
				log('Cache state updated:', pageId);
			}
		},

		/**
		 * Mark a cached page as stale (needs refresh)
		 * @param {string} pageId
		 */
		markStale: function(pageId) {
			if (cache[pageId]) {
				cache[pageId].stale = true;
				log('Cache marked stale:', pageId);
			}
		},

		/**
		 * Invalidate (remove) a specific page from cache
		 * @param {string} pageId
		 */
		invalidate: function(pageId) {
			if (cache[pageId]) {
				delete cache[pageId];
				log('Cache invalidated:', pageId);
			}
		},

		/**
		 * Invalidate all pages that display a specific entity type
		 * @param {string} entityType
		 */
		invalidateByEntity: function(entityType) {
			var pages = entityMap[entityType] || [];
			pages.forEach(function(pageId) {
				cacheAPI.markStale(pageId);
			});
			log('Cache invalidated by entity:', entityType, pages);
		},

		/**
		 * Clear all cached pages
		 */
		clear: function() {
			cache = {};
			log('Cache cleared');
		},

		/**
		 * Check if a page is cached (and valid)
		 * @param {string} pageId
		 * @returns {boolean}
		 */
		has: function(pageId) {
			return cacheAPI.get(pageId) !== null;
		},

		/**
		 * Get cache statistics
		 * @returns {Object}
		 */
		stats: function() {
			return {
				size: Object.keys(cache).length,
				maxSize: CONFIG.maxCacheSize,
				pages: Object.keys(cache),
				entityMap: entityMap
			};
		}
	};

	// ============================================
	// Lifecycle Methods
	// ============================================

	/**
	 * Mount a page (restore from cache or initialize fresh)
	 * @param {string} pageId
	 * @param {Object} [cachedEntry] - Cached data if available
	 */
	function mount(pageId, cachedEntry) {
		// Prevent double-mount (e.g., script executes + $(document).ready both call mount)
		if (activePage === pageId) {
			log('Page already mounted:', pageId);
			return true;
		}

		var module = registry[pageId];

		if (!module) {
			log('No module registered for:', pageId);
			return false;
		}

		activePage = pageId;
		managedPages[pageId] = true;

		// Determine state to pass to init
		var state = cachedEntry ? cachedEntry.state : {};
		if (cachedEntry && cachedEntry.scrollY) {
			state.scrollY = cachedEntry.scrollY;
		}

		try {
			log('Mounting page:', pageId, state);
			module.init(state);

			// Restore form state after init (DOM should be ready)
			if (state.formStates) {
				requestAnimationFrame(function() {
					restoreFormState(state.formStates);
				});
			}

			// Initialize page animations if available
			if (window.Funky && window.Funky.PageAnimate) {
				var pageElement = document.querySelector('[data-page="' + pageId + '"]');
				if (pageElement) {
					Funky.PageAnimate.enter(pageElement, pageId);
					Funky.PageAnimate.init(pageElement);
				}
			}

			// Refresh skip links if available (rescan for new skip targets)
			if (window.Funky && window.Funky.SkipLink) {
				Funky.SkipLink.refresh();
			}

			// Dispatch event
			var event = new CustomEvent('funky.pages.mounted', {
				detail: { pageId: pageId, cached: !!cachedEntry }
			});
			document.dispatchEvent(event);

			return true;
		} catch (err) {
			console.error('[Funky.Pages] Error mounting page:', pageId, err);
			return false;
		}
	}

	/**
	 * Unmount the current page (cleanup and preserve state)
	 * Note: Exit animations are handled by SPA before calling this method
	 * @param {string} pageId
	 * @returns {Object|null} - State returned from destroy()
	 */
	function unmount(pageId) {
		var module = registry[pageId];

		if (!module) {
			log('No module to unmount for:', pageId);
			return null;
		}

		var state = null;

		try {
			log('Unmounting page:', pageId);

			// Capture form state before destroy (in case destroy modifies DOM)
			var formStates = captureFormState();

			if (typeof module.destroy === 'function') {
				state = module.destroy() || {};
			} else {
				state = {};
			}

			// Capture scroll position
			state.scrollY = window.scrollY || window.pageYOffset;

			// Add form states
			if (Object.keys(formStates).length > 0) {
				state.formStates = formStates;
			}

			// Update cache with preserved state
			cacheAPI.updateState(pageId, state);

			// Dispatch event
			var event = new CustomEvent('funky.pages.unmounted', {
				detail: { pageId: pageId, state: state }
			});
			document.dispatchEvent(event);

		} catch (err) {
			console.error('[Funky.Pages] Error unmounting page:', pageId, err);
			state = { scrollY: 0 };
		}

		if (activePage === pageId) {
			activePage = null;
		}

		// Clear managed state so page can be re-mounted
		delete managedPages[pageId];

		return state;
	}

	/**
	 * Force refresh a page (re-fetch from server)
	 * @param {string} pageId
	 */
	function refresh(pageId) {
		cacheAPI.invalidate(pageId);

		// Trigger SPA navigation to current URL
		if (Funky.SPA && typeof Funky.SPA.refresh === 'function') {
			Funky.SPA.refresh();
		} else {
			window.location.reload();
		}
	}

	// ============================================
	// WebSocket Integration
	// ============================================

	/**
	 * Handle data change from WebSocket
	 * @param {string} entityType - e.g., 'trade', 'client'
	 * @param {string|number} entityId - The specific entity ID
	 * @param {string} action - 'create', 'update', 'delete', 'refresh'
	 * @param {Object} [data] - Optional data payload
	 */
	function handleDataChange(entityType, entityId, action, data) {
		log('Data change:', entityType, entityId, action);

		var affectedPages = entityMap[entityType] || [];

		affectedPages.forEach(function(pageId) {
			var module = registry[pageId];

			if (!module) return;

			if (pageId === activePage) {
				// Page is active
				if (action === 'refresh') {
					// Force immediate re-fetch from server
					log('Refresh action - re-fetching page:', pageId);
					refresh(pageId);
				} else if (typeof module.update === 'function') {
					// Call update() for targeted DOM update
					try {
						module.update(entityType, entityId, data, action);
						log('Updated active page:', pageId);
					} catch (err) {
						console.error('[Funky.Pages] Error updating page:', pageId, err);
					}
				} else {
					// No update method - mark stale for refresh on next visit
					cacheAPI.markStale(pageId);
				}
			} else {
				// Page is cached but not active - mark as stale
				cacheAPI.markStale(pageId);
			}
		});
	}

	/**
	 * Get pages affected by an entity type
	 * @param {string} entityType
	 * @returns {string[]}
	 */
	function getPagesByEntity(entityType) {
		return entityMap[entityType] || [];
	}

	// ============================================
	// Prefetching
	// ============================================

	/**
	 * Prefetch a page in the background
	 * @param {string} url - URL to prefetch
	 */
	function prefetch(url) {
		if (!url) return;
		// Don't prefetch if already cached
		var pageId = extractPageId(url);
		if (pageId && cacheAPI.has(pageId)) {
			log('Skip prefetch, already cached:', pageId);
			return;
		}

		// Use low priority fetch
		if (window.fetch) {
			fetch(url, {
				method: 'GET',
				headers: {
					'X-Requested-With': 'XMLHttpRequest',
					'Accept': 'text/html'
				},
				credentials: 'same-origin',
				priority: 'low'
			}).then(function(response) {
				if (response.ok) {
					return response.text();
				}
			}).then(function(html) {
				if (html) {
					// Extract page ID from response and cache
					var tempDiv = document.createElement('div');
					tempDiv.innerHTML = html;
					var content = tempDiv.querySelector('[data-page]');
					if (content) {
						var fetchedPageId = content.getAttribute('data-page');
						cacheAPI.set(fetchedPageId, html, {});
						log('Prefetched:', fetchedPageId);
					}
				}
			}).catch(function(err) {
				// Silently fail prefetch
				log('Prefetch failed:', url, err);
			});
		}
	}

	/**
	 * Extract page ID from URL
	 * @param {string} url
	 * @returns {string|null}
	 */
	function extractPageId(url) {
		// Simple extraction - could be enhanced
		var path = url.replace(/^https?:\/\/[^\/]+/, '').split('?')[0];
		return path.replace(/^\//, '').replace(/\//g, '-') || 'home';
	}

	// ============================================
	// Configuration
	// ============================================

	/**
	 * Configure the Pages system
	 * @param {Object} options
	 */
	function configure(options) {
		if (!options) return;
		if (options.cacheTTL) CONFIG.cacheTTL = options.cacheTTL;
		if (options.maxCacheSize) CONFIG.maxCacheSize = options.maxCacheSize;
		if (options.debug !== undefined) CONFIG.debug = options.debug;
		log('Configured:', CONFIG);
	}

	// ============================================
	// Public API
	// ============================================

	var Pages = {
		// Registry
		register: register,
		get: get,
		has: has,
		isManaged: isManaged,
		list: list,
		getActivePage: getActivePage,

		// Cache
		cache: cacheAPI,

		// Lifecycle
		mount: mount,
		unmount: unmount,
		refresh: refresh,

		// WebSocket integration
		handleDataChange: handleDataChange,
		getPagesByEntity: getPagesByEntity,

		// Prefetching
		prefetch: prefetch,

		// Form state utilities (for manual use by page modules)
		captureFormState: captureFormState,
		restoreFormState: restoreFormState,

		// Partial re-render utilities (for use in page update() methods)
		updateElements: updateElements,
		updateTableRow: updateTableRow,
		removeTableRow: removeTableRow,
		addTableRow: addTableRow,

		// Configuration
		configure: configure
	};

	// Register with Funky namespace
	Funky.register('Pages', Pages);

})(window);
