/**
 * Funky.Events - DOM Event Utilities
 *
 * Provides a clean API for working with native DOM events.
 * This is separate from Funky.PubSub (application pub/sub messaging).
 *
 * NAMING CONVENTION:
 *   - DOM Events (this module): Use dot notation for custom events: 'funky.component.action'
 *     Examples: 'click', 'submit', 'funky.modal.opened', 'funky.tabs.change'
 *   - PubSub (Funky.PubSub): Use colon notation for app messaging: 'funky:component:action'
 *     Examples: 'funky:trade:created', 'funky:cache:set', 'funky:session:expired'
 *
 * HANDLER REMOVAL:
 *   off() can be called with or without a handler reference:
 *
 *   // With handler - removes specific listener
 *   E.off(el, 'click', myHandler);
 *
 *   // Without handler - removes ALL listeners for that event on that element
 *   E.off(el, 'funky.modal.opened');
 *
 * Usage:
 *   Funky.Events.on(element, 'click', handler);
 *   Funky.Events.off(element, 'click', handler);
 *   Funky.Events.off(element, 'funky.modal.opened');  // Remove all
 *   Funky.Events.once(element, 'click', handler);
 *   Funky.Events.emit(element, 'funky.modal.opened', { data: 123 });
 *   Funky.Events.delegate(parent, '.child', 'click', handler);
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Events] Registry not found. Load namespace.js first.');
		return;
	}

	// =========================================================================
	// Handler Storage (for removal without handler reference)
	// =========================================================================

	var handlerStorage = new WeakMap();

	/**
	 * Store a handler reference for later removal
	 * @param {Element} target - Target element
	 * @param {string} eventKey - Event name
	 * @param {function} handler - Handler function
	 */
	function storeHandler(target, eventKey, handler) {
		var storage = handlerStorage.get(target);
		if (!storage) {
			storage = {};
			handlerStorage.set(target, storage);
		}
		if (!storage[eventKey]) {
			storage[eventKey] = [];
		}
		storage[eventKey].push(handler);
	}

	/**
	 * Get and clear all handlers for an event
	 * @param {Element} target - Target element
	 * @param {string} eventKey - Event name
	 * @returns {function[]} Array of handlers
	 */
	function getAndClearHandlers(target, eventKey) {
		var storage = handlerStorage.get(target);
		if (!storage || !storage[eventKey]) return [];
		var handlers = storage[eventKey];
		delete storage[eventKey];
		return handlers;
	}

	// =========================================================================
	// Events API
	// =========================================================================

	var Events = {
		/**
		 * Add event listener to element
		 *
		 * @param {Element|Window|Document|string} target - Element or selector to attach listener to
		 * @param {string} event - Event name (used exactly as provided)
		 * @param {function} handler - Event handler
		 * @param {boolean|object} options - addEventListener options
		 */
		on: function(target, event, handler, options) {
			// Resolve selector string to element
			if (typeof target === 'string') {
				target = document.querySelector(target);
			}

			if (!target || !event || typeof handler !== 'function') {
				console.error('[Funky.Events] Invalid arguments to on()');
				return;
			}

			target.addEventListener(event, handler, options);
			storeHandler(target, event, handler);
		},

		/**
		 * Remove event listener from element
		 *
		 * Can be called with or without a handler:
		 *   off(el, 'click', handler) - removes specific handler
		 *   off(el, 'funky.modal.opened') - removes ALL handlers for that event
		 *
		 * @param {Element|Window|Document} target - Element to remove listener from
		 * @param {string} event - Event name (must match exactly what was passed to on())
		 * @param {function} [handler] - Event handler (optional - if omitted, removes all)
		 * @param {boolean|object} options - removeEventListener options
		 */
		off: function(target, event, handler, options) {
			if (!target || !event) {
				console.error('[Funky.Events] Invalid arguments to off()');
				return;
			}

			// If handler provided, remove directly
			if (typeof handler === 'function') {
				target.removeEventListener(event, handler, options);
				return;
			}

			// No handler - remove all stored handlers for this event
			var handlers = getAndClearHandlers(target, event);
			handlers.forEach(function(h) {
				target.removeEventListener(event, h, options);
			});
		},

		/**
		 * Add one-time event listener
		 *
		 * @param {Element|Window|Document} target - Element to attach listener to
		 * @param {string} event - Event name
		 * @param {function} handler - Event handler
		 * @param {object} options - addEventListener options
		 */
		once: function(target, event, handler, options) {
			if (!target || !event || typeof handler !== 'function') {
				console.error('[Funky.Events] Invalid arguments to once()');
				return;
			}

			var opts = options || {};
			opts.once = true;

			target.addEventListener(event, handler, opts);
		},

		/**
		 * Dispatch custom event
		 *
		 * @param {Element|Window|Document} target - Element to dispatch from
		 * @param {string} event - Event name
		 * @param {*} detail - Event detail data
		 * @param {object} options - CustomEvent options (bubbles, cancelable, etc)
		 */
		emit: function(target, event, detail, options) {
			if (!target || !event) {
				console.error('[Funky.Events] Invalid arguments to emit()');
				return;
			}

			var opts = Object.assign({
				bubbles: true,
				cancelable: true,
				detail: detail
			}, options || {});

			var customEvent = new CustomEvent(event, opts);
			target.dispatchEvent(customEvent);
		},

		/**
		 * Event delegation - attach handler to parent for children matching selector
		 *
		 * @param {Element} parent - Parent element to attach listener to
		 * @param {string} selector - CSS selector for child elements
		 * @param {string} event - Event name
		 * @param {function} handler - Event handler
		 * @param {boolean|object} options - addEventListener options
		 * @returns {function} - Function to remove the delegated listener
		 */
		delegate: function(parent, selector, event, handler, options) {
			if (!parent || !selector || !event || typeof handler !== 'function') {
				console.error('[Funky.Events] Invalid arguments to delegate()');
				return function() {};
			}

			var delegatedHandler = function(e) {
				var target = e.target;

				// Walk up the DOM tree to find matching element
				while (target && target !== parent) {
					if (target.matches && target.matches(selector)) {
						// Call handler with correct context
						handler.call(target, e);
						return;
					}
					target = target.parentElement;
				}
			};

			parent.addEventListener(event, delegatedHandler, options);

			// Return cleanup function
			return function() {
				parent.removeEventListener(event, delegatedHandler, options);
			};
		},

		/**
		 * Wait for DOM ready
		 *
		 * @param {function} callback - Function to call when DOM is ready
		 */
		ready: function(callback) {
			if (typeof callback !== 'function') {
				console.error('[Funky.Events] Invalid callback to ready()');
				return;
			}

			if (document.readyState === 'loading') {
				document.addEventListener('DOMContentLoaded', callback, { once: true });
			} else {
				// DOM is already ready
				callback();
			}
		}
	};

	// Register with Funky namespace
	Funky.register('Events', Events);

})(window);
