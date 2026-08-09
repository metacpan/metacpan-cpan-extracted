/**
 * Funky.PubSub - Application Event Bus
 *
 * Provides pub/sub functionality for decoupled communication between components.
 * All Funky PubSub events use the 'funky:' prefix with colon notation.
 *
 * NOTE: This is for application-level messaging, not DOM events.
 * For DOM events, use CustomEvent with dot notation (funky.component.action).
 *
 * NAMING CONVENTION:
 *   - PubSub events: funky:component:action (colons)
 *     Examples: 'funky:modal:show', 'funky:api:success', 'funky:cache:set'
 *   - DOM CustomEvents: funky.component.action (dots)
 *     Examples: 'funky.calendar.date-select', 'funky.iframe.loaded'
 *
 * Usage:
 *   Funky.PubSub.on('funky:modal:shown', function(data) { ... });
 *   Funky.PubSub.emit('funky:modal:shown', { id: 123 });
 *   Funky.PubSub.off('funky:modal:shown', handler);
 *   Funky.PubSub.once('funky:session:expired', function() { ... });
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.PubSub] Registry not found. Load namespace.js first.');
		return;
	}

	// Event listeners storage: { eventName: [{ handler, once }] }
	var listeners = Object.create(null);

	var PubSub = {
		/**
		 * Subscribe to an event
		 * 
		 * @param {string} event - Event name (use 'funky:component:action' format)
		 * @param {function} handler - Callback function
		 * @returns {function} - Unsubscribe function for convenience
		 */
		on: function(event, handler) {
			if (typeof event !== 'string' || typeof handler !== 'function') {
				console.error('[Funky.PubSub] Invalid arguments to on()');
				return function() {};
			}

			if (!listeners[event]) {
				listeners[event] = [];
			}

			listeners[event].push({ handler: handler, once: false });

			// Return unsubscribe function
			return function() {
				PubSub.off(event, handler);
			};
		},

		/**
		 * Subscribe to an event (fires only once, then auto-removes)
		 * 
		 * @param {string} event - Event name
		 * @param {function} handler - Callback function
		 * @returns {function} - Unsubscribe function
		 */
		once: function(event, handler) {
			if (typeof event !== 'string' || typeof handler !== 'function') {
				console.error('[Funky.PubSub] Invalid arguments to once()');
				return function() {};
			}

			if (!listeners[event]) {
				listeners[event] = [];
			}

			listeners[event].push({ handler: handler, once: true });

			return function() {
				PubSub.off(event, handler);
			};
		},

		/**
		 * Unsubscribe from an event
		 * 
		 * @param {string} event - Event name
		 * @param {function} handler - The handler to remove (optional - if omitted, removes all)
		 */
		off: function(event, handler) {
			if (typeof event !== 'string') {
				console.error('[Funky.PubSub] Invalid event name');
				return this;
			}

			if (!listeners[event]) {
				return this;
			}

			if (handler === undefined) {
				// Remove all listeners for this event
				delete listeners[event];
				return this;
			}

			// Remove specific handler
			listeners[event] = listeners[event].filter(function(listener) {
				return listener.handler !== handler;
			});

			// Clean up empty arrays
			if (listeners[event].length === 0) {
				delete listeners[event];
			}

			return this;
		},

		/**
		 * Emit an event to all subscribers
		 * 
		 * @param {string} event - Event name
		 * @param {*} data - Data to pass to handlers
		 */
		emit: function(event, data) {
			if (typeof event !== 'string') {
				console.error('[Funky.PubSub] Invalid event name');
				return;
			}

			var eventListeners = listeners[event];
			if (!eventListeners || eventListeners.length === 0) {
				return;
			}

			// Create a copy to avoid issues if handlers modify the array
			var toCall = eventListeners.slice();
			var toRemove = [];

			toCall.forEach(function(listener) {
				try {
					listener.handler(data);
				} catch (e) {
					console.error('[Funky.PubSub] Handler error for event:', event, e);
				}

				if (listener.once) {
					toRemove.push(listener);
				}
			});

			// Remove once listeners
			toRemove.forEach(function(listener) {
				PubSub.off(event, listener.handler);
			});
		},

		/**
		 * Check if an event has any listeners
		 * 
		 * @param {string} event - Event name
		 * @returns {boolean}
		 */
		hasListeners: function(event) {
			return !!(listeners[event] && listeners[event].length > 0);
		},

		/**
		 * Get count of listeners for an event
		 * 
		 * @param {string} event - Event name
		 * @returns {number}
		 */
		listenerCount: function(event) {
			return listeners[event] ? listeners[event].length : 0;
		},

		/**
		 * Remove all listeners for an event or all events
		 * Useful for cleanup/testing
		 * @param {string} [event] - Optional event name. If omitted, clears all.
		 * @returns {Object} this for chaining
		 */
		clear: function(event) {
			if (event !== undefined) {
				// Clear specific event
				delete listeners[event];
			} else {
				// Clear all
				listeners = Object.create(null);
			}
			return this;
		},

		/**
		 * Get all registered event names
		 *
		 * @returns {string[]}
		 */
		eventNames: function() {
			return Object.keys(listeners);
		},

		/**
		 * Alias for hasListeners (for consistency with other APIs)
		 * @param {string} event - Event name
		 * @returns {boolean}
		 */
		has: function(event) {
			return this.hasListeners(event);
		},

		/**
		 * Alias for listenerCount (for consistency with other APIs)
		 * @param {string} event - Event name
		 * @returns {number}
		 */
		subscribers: function(event) {
			return this.listenerCount(event);
		},

		/**
		 * Create a namespaced PubSub interface
		 * @param {string} prefix - Namespace prefix
		 * @returns {Object} Namespaced interface
		 */
		namespace: function(prefix) {
			var self = this;
			return {
				on: function(event, callback) {
					return self.on(prefix + ':' + event, callback);
				},
				off: function(event, callback) {
					return self.off(prefix + ':' + event, callback);
				},
				once: function(event, callback) {
					return self.once(prefix + ':' + event, callback);
				},
				emit: function(event, data) {
					return self.emit(prefix + ':' + event, data);
				},
				has: function(event) {
					return self.has(prefix + ':' + event);
				},
				subscribers: function(event) {
					return self.subscribers(prefix + ':' + event);
				},
				clear: function() {
					var names = self.eventNames();
					for (var i = 0; i < names.length; i++) {
						if (names[i].indexOf(prefix + ':') === 0) {
							self.off(names[i]);
						}
					}
				}
			};
		}
	};

	// Register with Funky namespace
	Funky.register('PubSub', PubSub);

})(window);
