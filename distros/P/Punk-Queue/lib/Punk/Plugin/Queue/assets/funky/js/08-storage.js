/**
 * Funky Storage - Centralized localStorage management
 * 
 * Namespaced storage with automatic JSON serialization.
 * All keys are prefixed with 'funky_' to avoid collisions.
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Storage] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Storage')) {
		return;
	}

	var PREFIX = 'funky_';

	var Storage = {
		/**
		 * Get value from localStorage
		 * @param {string} key - Storage key (without prefix)
		 * @param {*} defaultValue - Default value if key not found
		 * @returns {*} Stored value or default
		 */
		get: function(key, defaultValue) {
			try {
				var value = localStorage.getItem(PREFIX + key);
				if (value === null) return defaultValue;
				return JSON.parse(value);
			} catch (e) {
				console.warn('[Funky.Storage] Error reading key:', key, e);
				return defaultValue;
			}
		},

		/**
		 * Get raw string value from localStorage (no JSON parsing)
		 * @param {string} key - Storage key (without prefix)
		 * @param {string} defaultValue - Default value if key not found
		 * @returns {string} Stored value or default
		 */
		getRaw: function(key, defaultValue) {
			try {
				var value = localStorage.getItem(PREFIX + key);
				return value !== null ? value : defaultValue;
			} catch (e) {
				console.warn('[Funky.Storage] Error reading key:', key, e);
				return defaultValue;
			}
		},

		/**
		 * Set value in localStorage
		 * @param {string} key - Storage key (without prefix)
		 * @param {*} value - Value to store (will be JSON serialized)
		 * @returns {boolean} Success status
		 */
		set: function(key, value) {
			try {
				localStorage.setItem(PREFIX + key, JSON.stringify(value));
				return true;
			} catch (e) {
				console.warn('[Funky.Storage] Error writing key:', key, e);
				return false;
			}
		},

		/**
		 * Set raw string value in localStorage (no JSON serialization)
		 * @param {string} key - Storage key (without prefix)
		 * @param {string} value - Value to store
		 * @returns {boolean} Success status
		 */
		setRaw: function(key, value) {
			try {
				localStorage.setItem(PREFIX + key, value);
				return true;
			} catch (e) {
				console.warn('[Funky.Storage] Error writing key:', key, e);
				return false;
			}
		},

		/**
		 * Remove value from localStorage
		 * @param {string} key - Storage key (without prefix)
		 */
		remove: function(key) {
			try {
				localStorage.removeItem(PREFIX + key);
			} catch (e) {
				console.warn('[Funky.Storage] Error removing key:', key, e);
			}
		},

		/**
		 * Clear all storage keys with optional prefix filter
		 * @param {string} subPrefix - Optional sub-prefix to filter (e.g., 'prefs_')
		 */
		clear: function(subPrefix) {
			try {
				var fullPrefix = PREFIX + (subPrefix || '');
				var keysToRemove = [];

				for (var i = 0; i < localStorage.length; i++) {
					var key = localStorage.key(i);
					if (key && key.indexOf(fullPrefix) === 0) {
						keysToRemove.push(key);
					}
				}

				keysToRemove.forEach(function(key) {
					localStorage.removeItem(key);
				});
			} catch (e) {
				console.warn('[Funky.Storage] Error clearing storage:', e);
			}
		},

		/**
		 * Get all keys with optional prefix filter
		 * @param {string} subPrefix - Optional sub-prefix to filter
		 * @returns {string[]} Array of keys (without funky_ prefix)
		 */
		keys: function(subPrefix) {
			var fullPrefix = PREFIX + (subPrefix || '');
			var result = [];

			try {
				for (var i = 0; i < localStorage.length; i++) {
					var key = localStorage.key(i);
					if (key && key.indexOf(fullPrefix) === 0) {
						result.push(key.substring(PREFIX.length));
					}
				}
			} catch (e) {
				console.warn('[Funky.Storage] Error listing keys:', e);
			}

			return result;
		},

		/**
		 * Check if a key exists in localStorage
		 * @param {string} key - Storage key (without prefix)
		 * @returns {boolean} True if key exists
		 */
		has: function(key) {
			try {
				return localStorage.getItem(PREFIX + key) !== null;
			} catch (e) {
				return false;
			}
		}
	};

	// Register with Funky namespace
	Funky.register('Storage', Storage);

})(window);
