/**
 * Funky.MediaQuery - Centralized Media Query Manager
 *
 * Provides shared matchMedia listeners with named breakpoints.
 * Multiple components can subscribe to the same query, sharing one listener.
 *
 * NAMING CONVENTION:
 *   - PubSub events: funky:mediaquery:change, funky:mediaquery:{breakpoint}
 *
 * Usage:
 *   Funky.MediaQuery.subscribe({
 *     breakpoint: 'mobile',
 *     namespace: 'my-component',
 *     onChange: function(matches) { console.log('Mobile:', matches); }
 *   });
 *
 *   Funky.MediaQuery.matches('mobile');  // true/false
 *   Funky.MediaQuery.unsubscribe('my-component');
 *
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.MediaQuery] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double registration
	if (window.Funky.isRegistered && window.Funky.isRegistered('MediaQuery')) {
		return;
	}

	var Funky = window.Funky;

	// =========================================================================
	// Predefined Breakpoints
	// =========================================================================

	var BREAKPOINTS = {
		'mobile':         '(max-width: 767px)',
		'tablet':         '(max-width: 1023px)',
		'tablet-only':    '(min-width: 768px) and (max-width: 1023px)',
		'desktop':        '(min-width: 1024px)',
		'large':          '(min-width: 1200px)',
		'xlarge':         '(min-width: 1440px)',
		'portrait':       '(orientation: portrait)',
		'landscape':      '(orientation: landscape)',
		'touch':          '(pointer: coarse)',
		'mouse':          '(pointer: fine)',
		'hover':          '(hover: hover)',
		'reduced-motion': '(prefers-reduced-motion: reduce)',
		'dark-mode':      '(prefers-color-scheme: dark)',
		'light-mode':     '(prefers-color-scheme: light)',
		'high-contrast':  '(prefers-contrast: more)'
	};

	// =========================================================================
	// State
	// =========================================================================

	// Map of query string -> { mql: MediaQueryList, handlers: [{namespace, onChange}], listener: Function }
	var queries = {};

	// Map of namespace -> query string (for quick unsubscribe lookup)
	var namespaceMap = {};

	// =========================================================================
	// Internal Functions
	// =========================================================================

	/**
	 * Resolve breakpoint name or query option to query string
	 * @param {Object} options - Subscribe options
	 * @returns {string|null} Query string
	 */
	function resolveQuery(options) {
		if (options.query) {
			return options.query;
		}
		if (options.breakpoint && BREAKPOINTS[options.breakpoint]) {
			return BREAKPOINTS[options.breakpoint];
		}
		console.warn('[MediaQuery] Unknown breakpoint:', options.breakpoint);
		return null;
	}

	/**
	 * Find breakpoint name for a query string
	 * @param {string} query - Query string
	 * @returns {string|null} Breakpoint name or null
	 */
	function findBreakpointName(query) {
		for (var name in BREAKPOINTS) {
			if (BREAKPOINTS.hasOwnProperty(name) && BREAKPOINTS[name] === query) {
				return name;
			}
		}
		return null;
	}

	/**
	 * Get or create MediaQueryList for a query
	 * @param {string} query - Media query string
	 * @returns {Object} Query entry with mql and handlers
	 */
	function getOrCreateQuery(query) {
		if (!queries[query]) {
			var mql = window.matchMedia(query);

			queries[query] = {
				mql: mql,
				handlers: [],
				listener: null
			};

			// Create shared listener
			queries[query].listener = function(e) {
				handleQueryChange(query, e.matches);
			};

			// Modern API with fallback for older browsers
			if (mql.addEventListener) {
				mql.addEventListener('change', queries[query].listener);
			} else if (mql.addListener) {
				mql.addListener(queries[query].listener);
			}
		}

		return queries[query];
	}

	/**
	 * Handle query change and notify all handlers
	 * @param {string} query - Query string
	 * @param {boolean} matches - Whether query matches
	 */
	function handleQueryChange(query, matches) {
		var entry = queries[query];
		if (!entry) return;

		// Notify all handlers
		for (var i = 0; i < entry.handlers.length; i++) {
			try {
				entry.handlers[i].onChange(matches);
			} catch (err) {
				console.error('[MediaQuery] Handler error:', err);
			}
		}

		// Emit PubSub events if available
		if (Funky.PubSub) {
			var breakpointName = findBreakpointName(query);

			// General change event
			Funky.PubSub.emit('funky:mediaquery:change', {
				query: query,
				matches: matches,
				breakpoint: breakpointName
			});

			// Named breakpoint event
			if (breakpointName) {
				Funky.PubSub.emit('funky:mediaquery:' + breakpointName, {
					matches: matches
				});
			}
		}
	}

	/**
	 * Remove listener and cleanup if no handlers left
	 * @param {string} query - Query string
	 */
	function cleanupQuery(query) {
		var entry = queries[query];
		if (!entry) return;

		if (entry.handlers.length === 0) {
			// Remove listener
			if (entry.mql.removeEventListener) {
				entry.mql.removeEventListener('change', entry.listener);
			} else if (entry.mql.removeListener) {
				entry.mql.removeListener(entry.listener);
			}

			delete queries[query];
		}
	}

	// =========================================================================
	// Public API
	// =========================================================================

	var MediaQuery = {
		/**
		 * Subscribe to a media query
		 * @param {Object} options
		 * @param {string} [options.breakpoint] - Named breakpoint (e.g., 'mobile')
		 * @param {string} [options.query] - Custom query string
		 * @param {string} options.namespace - Unique identifier for cleanup
		 * @param {Function} options.onChange - Callback function(matches)
		 * @param {boolean} [options.immediate=true] - Call onChange immediately with current state
		 * @returns {boolean} Success
		 */
		subscribe: function(options) {
			if (!options || !options.namespace) {
				console.warn('[MediaQuery] namespace is required');
				return false;
			}

			if (!options.onChange || typeof options.onChange !== 'function') {
				console.warn('[MediaQuery] onChange callback is required');
				return false;
			}

			var query = resolveQuery(options);
			if (!query) return false;

			// Check if namespace already subscribed
			if (namespaceMap[options.namespace]) {
				console.warn('[MediaQuery] Namespace already subscribed:', options.namespace);
				return false;
			}

			var entry = getOrCreateQuery(query);

			// Add handler
			entry.handlers.push({
				namespace: options.namespace,
				onChange: options.onChange
			});

			// Track namespace
			namespaceMap[options.namespace] = query;

			// Immediate callback with current state (default: true)
			if (options.immediate !== false) {
				options.onChange(entry.mql.matches);
			}

			return true;
		},

		/**
		 * Unsubscribe from a media query
		 * @param {string} namespace - The namespace to unsubscribe
		 * @returns {boolean} Success
		 */
		unsubscribe: function(namespace) {
			var query = namespaceMap[namespace];
			if (!query) return false;

			var entry = queries[query];
			if (!entry) return false;

			// Remove handler
			var newHandlers = [];
			for (var i = 0; i < entry.handlers.length; i++) {
				if (entry.handlers[i].namespace !== namespace) {
					newHandlers.push(entry.handlers[i]);
				}
			}
			entry.handlers = newHandlers;

			// Remove from namespace map
			delete namespaceMap[namespace];

			// Cleanup if no handlers left
			cleanupQuery(query);

			return true;
		},

		/**
		 * Check if a media query currently matches
		 * @param {string} nameOrQuery - Breakpoint name or query string
		 * @returns {boolean}
		 */
		matches: function(nameOrQuery) {
			var query = BREAKPOINTS[nameOrQuery] || nameOrQuery;

			// Check cached query first
			if (queries[query]) {
				return queries[query].mql.matches;
			}

			// One-off check
			return window.matchMedia(query).matches;
		},

		/**
		 * Get all predefined breakpoints
		 * @returns {Object}
		 */
		getBreakpoints: function() {
			var result = {};
			for (var name in BREAKPOINTS) {
				if (BREAKPOINTS.hasOwnProperty(name)) {
					result[name] = BREAKPOINTS[name];
				}
			}
			return result;
		},

		/**
		 * Add a custom named breakpoint
		 * @param {string} name - Breakpoint name
		 * @param {string} query - Media query string
		 * @returns {boolean} Success
		 */
		addBreakpoint: function(name, query) {
			if (BREAKPOINTS[name]) {
				console.warn('[MediaQuery] Breakpoint already exists:', name);
				return false;
			}
			BREAKPOINTS[name] = query;
			return true;
		},

		/**
		 * Remove a custom breakpoint
		 * Note: Only removes custom breakpoints, not built-in ones
		 * @param {string} name - Breakpoint name
		 * @returns {boolean} Success
		 */
		removeBreakpoint: function(name, query) {
			if (!BREAKPOINTS[name]) {
				return false;
			}
			// Only allow removal if the query matches (prevents removing built-ins accidentally)
			if (query && BREAKPOINTS[name] !== query) {
				return false;
			}
			delete BREAKPOINTS[name];
			return true;
		},

		/**
		 * Get all active subscriptions
		 * @returns {Object} Map of namespace -> query
		 */
		getSubscriptions: function() {
			var result = {};
			for (var ns in namespaceMap) {
				if (namespaceMap.hasOwnProperty(ns)) {
					result[ns] = namespaceMap[ns];
				}
			}
			return result;
		},

		/**
		 * Check if namespace is currently subscribed
		 * @param {string} namespace
		 * @returns {boolean}
		 */
		isSubscribed: function(namespace) {
			return !!namespaceMap[namespace];
		}
	};

	// Register with Funky
	Funky.register('MediaQuery', MediaQuery);

})(window);
