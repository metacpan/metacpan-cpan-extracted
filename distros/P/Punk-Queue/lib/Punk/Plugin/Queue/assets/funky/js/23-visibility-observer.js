/**
 * Funky.VisibilityObserver
 *
 * Factory for creating visibility tracking instances using IntersectionObserver.
 * Provides a consistent, reusable API for tracking element visibility.
 *
 * @example
 * var observer = Funky.VisibilityObserver.init({
 *   threshold: 0.1,
 *   onVisible: function(element, entry) { console.log('Visible:', element); },
 *   onHidden: function(element, entry) { console.log('Hidden:', element); }
 * });
 *
 * observer.observe('#my-element');
 * observer.observeOnce('.animate-on-scroll', function(el) {
 *   el.classList.add('animated');
 * });
 *
 * observer.destroy();
 *
 * @version 1.0.4
 */
(function(global) {
	'use strict';

	// Ensure Funky registry exists
	if (!global.Funky || !global.Funky.register) {
		console.error('[Funky.VisibilityObserver] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent duplicate registration
	if (global.Funky.isRegistered && global.Funky.isRegistered('VisibilityObserver')) {
		return;
	}

	var Funky = global.Funky;
	var PubSub = Funky.PubSub;

	// =========================================================================
	// Defaults
	// =========================================================================

	var DEFAULTS = {
		root: null,                    // Viewport (null = browser viewport)
		rootMargin: '0px',             // Margin around root
		threshold: 0.1,                // 10% visible = "in viewport"
		onVisible: null,               // function(element, entry)
		onHidden: null,                // function(element, entry)
		namespace: 'visibility'        // For PubSub events
	};

	// =========================================================================
	// Instance Counter
	// =========================================================================

	var instanceCounter = 0;

	// =========================================================================
	// VisibilityObserverInstance Constructor
	// =========================================================================

	/**
	 * VisibilityObserver instance
	 * @param {Object} options - Configuration options
	 */
	function VisibilityObserverInstance(options) {
		var self = this;
		this._id = 'visibility-observer-' + (++instanceCounter);

		// Merge config with defaults
		this._config = {};
		for (var key in DEFAULTS) {
			if (DEFAULTS.hasOwnProperty(key)) {
				this._config[key] = DEFAULTS[key];
			}
		}
		if (options) {
			for (var optKey in options) {
				if (options.hasOwnProperty(optKey)) {
					this._config[optKey] = options[optKey];
				}
			}
		}

		// Internal state
		this._elements = new Map();    // element -> { onVisible, onHidden, once }
		this._visibleSet = new Set();  // Currently visible elements
		this._observer = null;

		// Check for IntersectionObserver support
		if (!('IntersectionObserver' in window)) {
			console.warn('[VisibilityObserver] IntersectionObserver not supported. Visibility tracking disabled.');
			return;
		}

		// Create the observer
		this._observer = new IntersectionObserver(function(entries) {
			self._handleIntersection(entries);
		}, {
			root: this._config.root,
			rootMargin: this._config.rootMargin,
			threshold: this._config.threshold
		});
	}

	VisibilityObserverInstance.prototype = {
		/**
		 * Get the observer ID
		 * @returns {string}
		 */
		getId: function() {
			return this._id;
		},

		/**
		 * Observe an element for visibility changes
		 * @param {string|HTMLElement} selector - Element or CSS selector
		 * @param {Object} [options] - Per-element options
		 * @param {Function} [options.onVisible] - Called when element becomes visible
		 * @param {Function} [options.onHidden] - Called when element becomes hidden
		 * @param {boolean} [options.once] - Unobserve after first visibility
		 * @returns {VisibilityObserverInstance} this
		 */
		observe: function(selector, options) {
			if (!this._observer) return this;

			var el = typeof selector === 'string'
				? document.querySelector(selector)
				: selector;

			if (!el) {
				console.warn('[VisibilityObserver] Element not found:', selector);
				return this;
			}

			// Don't observe the same element twice
			if (this._elements.has(el)) {
				return this;
			}

			this._elements.set(el, options || {});
			this._observer.observe(el);
			return this;
		},

		/**
		 * Observe element once - auto-unobserve after first visibility
		 * @param {string|HTMLElement} selector - Element or CSS selector
		 * @param {Function} [callback] - Called when element becomes visible
		 * @returns {VisibilityObserverInstance} this
		 */
		observeOnce: function(selector, callback) {
			return this.observe(selector, {
				once: true,
				onVisible: callback
			});
		},

		/**
		 * Observe multiple elements matching a selector
		 * @param {string} selector - CSS selector for multiple elements
		 * @param {Object} [options] - Per-element options
		 * @returns {VisibilityObserverInstance} this
		 */
		observeAll: function(selector, options) {
			var self = this;
			var elements = document.querySelectorAll(selector);
			elements.forEach(function(el) {
				self.observe(el, options);
			});
			return this;
		},

		/**
		 * Stop observing an element
		 * @param {string|HTMLElement} selector - Element or CSS selector
		 * @returns {VisibilityObserverInstance} this
		 */
		unobserve: function(selector) {
			if (!this._observer) return this;

			var el = typeof selector === 'string'
				? document.querySelector(selector)
				: selector;

			if (el && this._elements.has(el)) {
				this._observer.unobserve(el);
				this._elements.delete(el);
				this._visibleSet.delete(el);
			}
			return this;
		},

		/**
		 * Check if element is currently visible
		 * @param {HTMLElement} element
		 * @returns {boolean}
		 */
		isVisible: function(element) {
			return this._visibleSet.has(element);
		},

		/**
		 * Get all currently visible elements
		 * @returns {Array<HTMLElement>}
		 */
		getVisible: function() {
			return Array.from(this._visibleSet);
		},

		/**
		 * Get count of observed elements
		 * @returns {number}
		 */
		count: function() {
			return this._elements.size;
		},

		/**
		 * Handle intersection observer entries
		 * @private
		 */
		_handleIntersection: function(entries) {
			var self = this;

			entries.forEach(function(entry) {
				var el = entry.target;
				var opts = self._elements.get(el) || {};
				var wasVisible = self._visibleSet.has(el);
				var isVisible = entry.isIntersecting;

				if (isVisible && !wasVisible) {
					// Element became visible
					self._visibleSet.add(el);

					// Per-element callback
					if (opts.onVisible) {
						opts.onVisible(el, entry);
					}

					// Global callback
					if (self._config.onVisible) {
						self._config.onVisible(el, entry);
					}

					// PubSub event
					if (PubSub) {
						PubSub.emit('funky:visibility:visible', {
							element: el,
							entry: entry,
							observerId: self._id
						});
					}

					// One-shot: unobserve after visible
					if (opts.once) {
						self.unobserve(el);
					}

				} else if (!isVisible && wasVisible) {
					// Element became hidden
					self._visibleSet.delete(el);

					// Per-element callback
					if (opts.onHidden) {
						opts.onHidden(el, entry);
					}

					// Global callback
					if (self._config.onHidden) {
						self._config.onHidden(el, entry);
					}

					// PubSub event
					if (PubSub) {
						PubSub.emit('funky:visibility:hidden', {
							element: el,
							entry: entry,
							observerId: self._id
						});
					}
				}
			});
		},

		/**
		 * Destroy the observer and clean up
		 */
		destroy: function() {
			if (this._observer) {
				this._observer.disconnect();
				this._observer = null;
			}
			this._elements.clear();
			this._visibleSet.clear();
		}
	};

	// =========================================================================
	// Instance Registry
	// =========================================================================

	var _instances = Funky.Registry.createInstanceRegistry('VisibilityObserver');

	// =========================================================================
	// Factory
	// =========================================================================

	var VisibilityObserver = {
		/**
		 * Create a new VisibilityObserver instance
		 * @param {Object} [options] - Configuration options
		 * @param {Element} [options.root] - Scroll container (null = viewport)
		 * @param {string} [options.rootMargin] - Margin around root (e.g., '100px')
		 * @param {number} [options.threshold] - Visibility threshold (0-1)
		 * @param {Function} [options.onVisible] - Global visible callback
		 * @param {Function} [options.onHidden] - Global hidden callback
		 * @returns {VisibilityObserverInstance}
		 */
		init: function(options) {
			var instance = new VisibilityObserverInstance(options);
			_instances.register(instance._id, instance);
			return instance;
		},

		/**
		 * @deprecated Use init() instead
		 */
		create: function(options) {
			if (Funky.debug) {
				console.warn('[Funky.VisibilityObserver] create() is deprecated. Use init() instead.');
			}
			return this.init(options);
		},

		/**
		 * Get instance by ID
		 * @param {string} id
		 * @returns {VisibilityObserverInstance|null}
		 */
		getInstance: function(id) {
			return _instances.get(id);
		},

		/**
		 * Get all instances
		 * @returns {VisibilityObserverInstance[]}
		 */
		getAll: function() {
			return _instances.getAll();
		},

		/**
		 * Destroy all instances
		 */
		destroyAll: function() {
			_instances.destroyAll();
		}
	};

	// Register with Funky
	Funky.register('VisibilityObserver', VisibilityObserver);

})(typeof window !== 'undefined' ? window : this);
