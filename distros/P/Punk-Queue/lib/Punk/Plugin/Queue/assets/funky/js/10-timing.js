/**
 * Funky Timing - Rate limiting utilities
 * 
 * Throttle and debounce functions for performance optimization.
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Timing] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Timing')) {
		return;
	}

	var Timing = {
		/**
		 * Throttle function execution
		 * @param {Function} fn - Function to throttle
		 * @param {number} limit - Minimum time between calls (ms)
		 * @returns {Function} Throttled function (or noop if fn is not a function)
		 */
		throttle: function(fn, limit) {
			if (typeof fn !== 'function') {
				return function() {};
			}
			// Handle NaN, negative, or undefined limit - treat as 0 (no throttling)
			var safeLimit = (typeof limit === 'number' && !isNaN(limit) && limit >= 0) ? limit : 0;
			var lastCall = 0;
			return function() {
				var now = Date.now();
				if (now - lastCall >= safeLimit) {
					lastCall = now;
					fn.apply(this, arguments);
				}
			};
		},

		/**
		 * Debounce function execution
		 * @param {Function} fn - Function to debounce
		 * @param {number} delay - Delay in milliseconds
		 * @returns {Function} Debounced function (or noop if fn is not a function)
		 */
		debounce: function(fn, delay) {
			if (typeof fn !== 'function') {
				return function() {};
			}
			var timeoutId;
			return function() {
				var context = this;
				var args = arguments;
				clearTimeout(timeoutId);
				timeoutId = setTimeout(function() {
					fn.apply(context, args);
				}, delay);
			};
		},

		/**
		 * RequestAnimationFrame wrapper with fallback
		 * @param {Function} fn - Function to call on next frame
		 * @returns {number} Animation frame ID (or null if fn is not a function)
		 */
		raf: function(fn) {
			if (typeof fn !== 'function') {
				return null;
			}
			var raf = window.requestAnimationFrame ||
				window.webkitRequestAnimationFrame ||
				function(cb) { return setTimeout(cb, 16); };
			return raf(fn);
		},

		/**
		 * Cancel animation frame
		 * @param {number} id - Animation frame ID
		 */
		cancelRaf: function(id) {
			var cancel = window.cancelAnimationFrame ||
				window.webkitCancelAnimationFrame ||
				clearTimeout;
			cancel(id);
		}
	};

	// Register with Funky namespace
	Funky.register('Timing', Timing);

})(window);
