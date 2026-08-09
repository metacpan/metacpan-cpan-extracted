/**
 * Funky History - Reusable LRU history tracking
 * 
 * Provides LRU (Least Recently Used) history management with:
 * - Automatic deduplication (moves to front)
 * - Configurable max size
 * - Optional localStorage persistence via Funky.Storage
 * - Event emission on changes
 * 
 * @module Funky.History
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.History] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('History')) {
		return;
	}

	// Shortcuts (lazy load to avoid dependency order issues)
	var Storage = null;
	var E = null;

	function getStorage() {
		if (!Storage && Funky.Storage) {
			Storage = Funky.Storage;
		}
		return Storage;
	}

	function getEvents() {
		if (!E && Funky.PubSub) {
			E = Funky.PubSub;
		}
		return E;
	}

	// ==========================================================================
	// CONSTANTS
	// ==========================================================================

	var DEFAULTS = {
		key: null,           // Storage key (required for persistence)
		namespace: null,     // Namespace prefix for storage key (prevents collisions)
		maxItems: 10,        // Maximum items to keep
		persist: true,       // Persist to Funky.Storage
		dedupe: true,        // Remove duplicates (move to front)
		emitEvents: true,    // Emit change events
		comparator: null,    // Custom equality function: function(a, b) => boolean
		onChange: null       // Callback on any change: function(action, data)
	};

	// Active instances for named histories
	var instances = {};

	// ==========================================================================
	// HISTORY INSTANCE
	// ==========================================================================

	/**
	 * History instance constructor
	 * @param {Object} options
	 */
	function HistoryInstance(options) {
		this.options = Object.assign({}, DEFAULTS, options);
		this.items = [];
		this._batchMode = false;
		this._batchItems = [];
		this._cursor = -1; // For traversal (-1 = no position)
		
		// Load from storage if persistence enabled
		if (this.options.persist && this.options.key) {
			this._load();
		}
	}

	HistoryInstance.prototype = {
		/**
		 * Add item to history (moves to front if exists)
		 * @param {*} item - Item to add (typically string ID)
		 * @param {Object} [options] - Optional settings
		 * @param {boolean} [options.silent] - Skip event emission
		 * @returns {HistoryInstance} For chaining
		 */
		add: function(item, options) {
			if (item == null) return this;
			
			options = options || {};
			
			// Remove if already exists (dedupe)
			if (this.options.dedupe) {
				var existingIndex = this._indexOf(item);
				if (existingIndex !== -1) {
					this.items.splice(existingIndex, 1);
				}
			}
			
			// Add to front
			this.items.unshift(item);
			
			// Track for batch mode
			if (this._batchMode) {
				this._batchItems.push(item);
			}
			
			// Trim to max size
			if (this.items.length > this.options.maxItems) {
				this.items = this.items.slice(0, this.options.maxItems);
			}
			
			// Persist
			this._save();
			
			// Emit event (unless in batch mode or silent)
			if (!this._batchMode && !options.silent) {
				this._emit('add', { item: item, size: this.items.length });
			}
			
			return this;
		},

		/**
		 * Add multiple items (in order, first = most recent)
		 * @param {Array} items
		 * @param {Object} [options] - Optional settings
		 * @param {boolean} [options.silent] - Skip individual events (batch event still emits)
		 * @returns {HistoryInstance}
		 */
		addAll: function(items, options) {
			if (!Array.isArray(items)) return this;
			
			options = options || {};
			
			// Add in reverse so first item ends up at front
			for (var i = items.length - 1; i >= 0; i--) {
				this.add(items[i], { silent: true });
			}
			
			// Emit single batch event unless silent
			if (!options.silent) {
				this._emit('batch', { items: items, size: this.items.length });
			}
			
			return this;
		},

		/**
		 * Execute multiple operations as a batch (single event)
		 * @param {Function} fn - Function containing operations
		 * @returns {HistoryInstance}
		 */
		batch: function(fn) {
			this._batchMode = true;
			this._batchItems = [];
			
			try {
				fn.call(this);
			} finally {
				this._batchMode = false;
				if (this._batchItems.length > 0) {
					this._emit('batch', { items: this._batchItems, size: this.items.length });
				}
				this._batchItems = [];
			}
			
			return this;
		},

		/**
		 * Remove item from history
		 * @param {*} item
		 * @returns {boolean} True if removed
		 */
		remove: function(item) {
			var index = this._indexOf(item);
			if (index === -1) return false;
			
			this.items.splice(index, 1);
			this._save();
			this._emit('remove', { item: item, size: this.items.length });
			
			return true;
		},

		/**
		 * Check if item exists in history
		 * @param {*} item
		 * @returns {boolean}
		 */
		has: function(item) {
			return this._indexOf(item) !== -1;
		},

		/**
		 * Get all items (most recent first)
		 * @returns {Array} Copy of items array
		 */
		getAll: function() {
			return this.items.slice();
		},

		/**
		 * Get item at index
		 * @param {number} index
		 * @returns {*}
		 */
		get: function(index) {
			return this.items[index];
		},

		/**
		 * Get most recent item
		 * @returns {*}
		 */
		first: function() {
			return this.items[0];
		},

		/**
		 * Get oldest item
		 * @returns {*}
		 */
		last: function() {
			return this.items[this.items.length - 1];
		},

		/**
		 * Get number of items
		 * @returns {number}
		 */
		size: function() {
			return this.items.length;
		},

		/**
		 * Check if history is empty
		 * @returns {boolean}
		 */
		isEmpty: function() {
			return this.items.length === 0;
		},

		/**
		 * Remove and return most recent item (front)
		 * @returns {*} The removed item, or undefined if empty
		 */
		pop: function() {
			if (this.items.length === 0) return undefined;
			
			var item = this.items.shift();
			this._save();
			this._emit('pop', { item: item, size: this.items.length });
			
			// Adjust cursor if needed
			if (this._cursor >= 0) {
				this._cursor = Math.max(-1, this._cursor - 1);
			}
			
			return item;
		},

		/**
		 * Remove and return oldest item (end)
		 * @returns {*} The removed item, or undefined if empty
		 */
		shift: function() {
			if (this.items.length === 0) return undefined;
			
			var item = this.items.pop();
			this._save();
			this._emit('shift', { item: item, size: this.items.length });
			
			// Adjust cursor if it was pointing at the removed item
			if (this._cursor >= this.items.length) {
				this._cursor = this.items.length - 1;
			}
			
			return item;
		},

		/**
		 * Return most recent item without removing it
		 * Alias for first() for stack-like semantics
		 * @returns {*}
		 */
		peek: function() {
			return this.items[0];
		},

		// =====================================================================
		// TRAVERSAL METHODS (cursor-based navigation)
		// =====================================================================

		/**
		 * Get current cursor position
		 * @returns {number} -1 if not positioned, 0+ if positioned
		 */
		cursor: function() {
			return this._cursor;
		},

		/**
		 * Get item at current cursor position
		 * @returns {*} Current item, or undefined if not positioned
		 */
		current: function() {
			if (this._cursor < 0 || this._cursor >= this.items.length) {
				return undefined;
			}
			return this.items[this._cursor];
		},

		/**
		 * Move cursor to next (older) item
		 * @returns {*} The next item, or undefined if at end
		 */
		next: function() {
			if (this.items.length === 0) return undefined;
			
			// Initialize cursor if not set
			if (this._cursor < 0) {
				this._cursor = 0;
				return this.items[0];
			}
			
			// Move forward (older)
			if (this._cursor < this.items.length - 1) {
				this._cursor++;
				return this.items[this._cursor];
			}
			
			return undefined; // At end
		},

		/**
		 * Move cursor to previous (newer) item
		 * @returns {*} The previous item, or undefined if at start
		 */
		prev: function() {
			if (this.items.length === 0 || this._cursor <= 0) {
				return undefined;
			}
			
			this._cursor--;
			return this.items[this._cursor];
		},

		/**
		 * Move cursor to specific index
		 * @param {number} index - Target index
		 * @returns {*} Item at index, or undefined if out of bounds
		 */
		goto: function(index) {
			if (index < 0 || index >= this.items.length) {
				return undefined;
			}
			
			this._cursor = index;
			return this.items[this._cursor];
		},

		/**
		 * Reset cursor to unpositioned state
		 * @returns {HistoryInstance}
		 */
		resetCursor: function() {
			this._cursor = -1;
			return this;
		},

		/**
		 * Check if cursor can move to next (older)
		 * @returns {boolean}
		 */
		hasNext: function() {
			return this._cursor < this.items.length - 1;
		},

		/**
		 * Check if cursor can move to previous (newer)
		 * @returns {boolean}
		 */
		hasPrev: function() {
			return this._cursor > 0;
		},

		/**
		 * Clear all items
		 * @returns {HistoryInstance}
		 */
		clear: function() {
			var oldSize = this.items.length;
			this.items = [];
			this._cursor = -1;
			this._save();
			this._emit('clear', { previousSize: oldSize });
			return this;
		},

		/**
		 * Iterate over items
		 * @param {Function} callback - function(item, index)
		 */
		forEach: function(callback) {
			for (var i = 0; i < this.items.length; i++) {
				callback(this.items[i], i);
			}
		},

		/**
		 * Map items to new array
		 * @param {Function} callback - function(item, index) => mapped
		 * @returns {Array}
		 */
		map: function(callback) {
			var result = [];
			for (var i = 0; i < this.items.length; i++) {
				result.push(callback(this.items[i], i));
			}
			return result;
		},

		/**
		 * Filter items
		 * @param {Function} callback - function(item, index) => boolean
		 * @returns {Array}
		 */
		filter: function(callback) {
			var result = [];
			for (var i = 0; i < this.items.length; i++) {
				if (callback(this.items[i], i)) {
					result.push(this.items[i]);
				}
			}
			return result;
		},

		/**
		 * Update max items limit
		 * @param {number} max
		 * @returns {HistoryInstance}
		 */
		setMaxItems: function(max) {
			this.options.maxItems = max;
			if (this.items.length > max) {
				this.items = this.items.slice(0, max);
				this._save();
			}
			return this;
		},

		/**
		 * Get storage key
		 * @returns {string|null}
		 */
		getKey: function() {
			return this.options.key;
		},

		/**
		 * Force reload from storage
		 * @returns {HistoryInstance}
		 */
		reload: function() {
			this._load();
			this._emit('reload', { size: this.items.length });
			return this;
		},

		/**
		 * Force save to storage
		 * @returns {HistoryInstance}
		 */
		save: function() {
			this._save();
			return this;
		},

		/**
		 * Destroy instance
		 */
		destroy: function() {
			if (this.options.key && instances[this.options.key]) {
				delete instances[this.options.key];
			}
			this.items = [];
		},

		// =====================================================================
		// PRIVATE METHODS
		// =====================================================================

		/**
		 * Find index of item
		 * @private
		 */
		_indexOf: function(item) {
			var comparator = this.options.comparator;
			for (var i = 0; i < this.items.length; i++) {
				if (comparator) {
					if (comparator(this.items[i], item)) {
						return i;
					}
				} else if (this.items[i] === item) {
					return i;
				}
			}
			return -1;
		},

		/**
		 * Get namespaced storage key
		 * @private
		 */
		_getStorageKey: function() {
			var key = this.options.key;
			if (!key) return null;
			
			if (this.options.namespace) {
				return this.options.namespace + ':' + key;
			}
			return key;
		},

		/**
		 * Load from storage
		 * @private
		 */
		_load: function() {
			var storage = getStorage();
			var storageKey = this._getStorageKey();
			if (!storage || !storageKey) return;
			
			try {
				var stored = storage.get(storageKey, []);
				if (Array.isArray(stored)) {
					this.items = stored.slice(0, this.options.maxItems);
				}
			} catch (e) {
				console.warn('[Funky.History] Failed to load:', storageKey, e);
			}
		},

		/**
		 * Save to storage
		 * @private
		 */
		_save: function() {
			if (!this.options.persist) return;
			
			var storage = getStorage();
			var storageKey = this._getStorageKey();
			if (!storage || !storageKey) return;
			
			try {
				storage.set(storageKey, this.items);
			} catch (e) {
				console.warn('[Funky.History] Failed to save:', storageKey, e);
			}
		},

		/**
		 * Emit event
		 * @private
		 */
		_emit: function(action, data) {
			var payload = Object.assign({
				key: this.options.key
			}, data);
			
			// Call onChange callback if provided
			if (typeof this.options.onChange === 'function') {
				try {
					this.options.onChange(action, payload);
				} catch (e) {
					console.warn('[Funky.History] onChange callback error:', e);
				}
			}
			
			// Emit PubSub event if enabled
			if (!this.options.emitEvents) return;
			
			var events = getEvents();
			if (!events) return;
			
			events.emit('funky:history:' + action, payload);
		}
	};

	// ==========================================================================
	// PUBLIC API
	// ==========================================================================

	var History = {
		/**
		 * Create a new history instance
		 * If key is provided and instance exists, returns existing instance
		 * 
		 * @param {Object} options
		 * @param {string} options.key - Storage key (enables get() by key)
		 * @param {string} options.namespace - Namespace prefix for storage key
		 * @param {number} options.maxItems - Max items (default: 10)
		 * @param {boolean} options.persist - Persist to storage (default: true)
		 * @param {boolean} options.dedupe - Remove duplicates (default: true)
		 * @param {Function} options.comparator - Custom equality: function(a, b) => boolean
		 * @param {Function} options.onChange - Callback: function(action, data)
		 * @returns {HistoryInstance}
		 */
		create: function(options) {
			options = Object.assign({}, DEFAULTS, options);
			
			// Return existing instance if key matches
			if (options.key && instances[options.key]) {
				return instances[options.key];
			}
			
			var instance = new HistoryInstance(options);
			
			// Store named instances
			if (options.key) {
				instances[options.key] = instance;
			}
			
			return instance;
		},

		/**
		 * Get existing instance by key
		 * @param {string} key - Storage key
		 * @returns {HistoryInstance|null}
		 */
		get: function(key) {
			return instances[key] || null;
		},

		/**
		 * Check if instance exists
		 * @param {string} key
		 * @returns {boolean}
		 */
		has: function(key) {
			return !!instances[key];
		},

		/**
		 * Destroy instance by key
		 * @param {string} key
		 */
		destroy: function(key) {
			if (instances[key]) {
				instances[key].destroy();
			}
		},

		/**
		 * Destroy all instances
		 */
		destroyAll: function() {
			var keys = Object.keys(instances);
			for (var i = 0; i < keys.length; i++) {
				instances[keys[i]].destroy();
			}
		},

		/**
		 * Get all instance keys
		 * @returns {Array<string>}
		 */
		keys: function() {
			return Object.keys(instances);
		},

		/**
		 * Expose DEFAULTS for inspection
		 */
		DEFAULTS: DEFAULTS
	};

	// Register with Funky namespace
	Funky.register('History', History);

})(window);
