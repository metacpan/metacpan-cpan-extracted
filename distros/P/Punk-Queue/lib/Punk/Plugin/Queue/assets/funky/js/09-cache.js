/**
 * Funky Cache - In-memory data cache with TTL and LRU eviction
 * 
 * Provides a per-entity-type cache with automatic expiry and size limits.
 * Used for caching API responses to reduce server load and improve responsiveness.
 * 
 * Store structure:
 * {
 *   trades: {
 *     byId: { 123: { data, timestamp, accessTime } },
 *     list: { data, timestamp },
 *     meta: { ttl, maxEntries }
 *   }
 * }
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Cache] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Cache')) {
		return;
	}

	// Default configuration
	var DEFAULT_TTL = 5 * 60 * 1000;       // 5 minutes
	var DEFAULT_MAX_ENTRIES = 500;          // Max items per entity type
	var CLEANUP_INTERVAL = 60 * 1000;       // Run cleanup every minute

	// Internal store (entity-type based)
	var store = {};

	// Simple key-value store
	var kvStore = {};
	var kvMaxSize = 1000;

	// Per-type configuration
	var typeConfig = {};

	// Event listeners
	var listeners = {};

	// Statistics
	var cacheStats = {
		hits: 0,
		misses: 0
	};

	/**
	 * Get or create store for entity type
	 */
	function getTypeStore(type) {
		if (!store[type]) {
			store[type] = {
				byId: {},
				list: null,
				meta: {
					ttl: typeConfig[type]?.ttl || DEFAULT_TTL,
					maxEntries: typeConfig[type]?.maxEntries || DEFAULT_MAX_ENTRIES
				}
			};
		}
		return store[type];
	}

	/**
	 * Check if an entry is expired
	 */
	function isExpired(entry, ttl) {
		if (!entry || !entry.timestamp) return true;
		return (Date.now() - entry.timestamp) > ttl;
	}

	/**
	 * Emit an event to listeners
	 */
	function emit(event, data) {
		var handlers = listeners[event];
		if (handlers) {
			handlers.forEach(function(handler) {
				try {
					handler(data);
				} catch (e) {
					console.error('[Funky.Cache] Event handler error:', e);
				}
			});
		}
	}

	/**
	 * Enforce max entries limit using LRU eviction
	 */
	function enforceLRU(typeStore) {
		var byId = typeStore.byId;
		var maxEntries = typeStore.meta.maxEntries;
		var keys = Object.keys(byId);
		
		if (keys.length <= maxEntries) return;

		// Sort by accessTime (oldest first)
		keys.sort(function(a, b) {
			return (byId[a].accessTime || 0) - (byId[b].accessTime || 0);
		});

		// Remove oldest entries
		var toRemove = keys.length - maxEntries;
		for (var i = 0; i < toRemove; i++) {
			delete byId[keys[i]];
		}
	}

	/**
	 * Periodic cleanup of expired entries
	 */
	function cleanupExpired() {
		var now = Date.now();
		Object.keys(store).forEach(function(type) {
			var typeStore = store[type];
			var ttl = typeStore.meta.ttl;

			// Clean byId entries
			Object.keys(typeStore.byId).forEach(function(id) {
				if (isExpired(typeStore.byId[id], ttl)) {
					delete typeStore.byId[id];
				}
			});

			// Clean list if expired
			if (typeStore.list && isExpired(typeStore.list, ttl)) {
				typeStore.list = null;
			}
		});
	}

	// Start cleanup interval
	setInterval(cleanupExpired, CLEANUP_INTERVAL);

	/**
	 * Enforce max size on kvStore using LRU eviction
	 */
	function enforceKvLRU() {
		var keys = Object.keys(kvStore);
		if (keys.length <= kvMaxSize) return;

		// Sort by accessTime (oldest first)
		keys.sort(function(a, b) {
			return (kvStore[a].accessTime || 0) - (kvStore[b].accessTime || 0);
		});

		// Remove oldest entries
		var toRemove = keys.length - kvMaxSize;
		for (var i = 0; i < toRemove; i++) {
			delete kvStore[keys[i]];
		}
	}

	/**
	 * Emit PubSub event if available
	 */
	function emitPubSub(event, data) {
		if (Funky.PubSub && typeof Funky.PubSub.emit === 'function') {
			Funky.PubSub.emit(event, data);
		}
	}

	var Cache = {
		/**
		 * Configure TTL and max entries for a specific entity type
		 * @param {string} type - Entity type
		 * @param {object} config - { ttl: ms, maxEntries: number }
		 */
		configure: function(type, config) {
			typeConfig[type] = Object.assign({}, typeConfig[type], config);
			if (store[type]) {
				store[type].meta = Object.assign(store[type].meta, config);
			}
		},

		/**
		 * Get a single item from cache
		 * Supports both entity-type API: get(type, id) and simple key API: get(key)
		 * @param {string} typeOrKey - Entity type or cache key
		 * @param {string|number} [id] - Entity ID (if using entity-type API)
		 * @returns {*} Cached data or undefined if not found/expired
		 */
		get: function(typeOrKey, id) {
			// Simple key-value API (single argument)
			if (arguments.length === 1) {
				var entry = kvStore[typeOrKey];
				if (!entry) {
					cacheStats.misses++;
					return undefined;
				}
				if (entry.ttl && isExpired(entry, entry.ttl)) {
					delete kvStore[typeOrKey];
					cacheStats.misses++;
					return undefined;
				}
				entry.accessTime = Date.now();
				cacheStats.hits++;
				return entry.data;
			}

			// Entity-type API (two arguments)
			var typeStore = store[typeOrKey];
			if (!typeStore) {
				cacheStats.misses++;
				return null;
			}

			var typeEntry = typeStore.byId[id];
			if (!typeEntry) {
				cacheStats.misses++;
				return null;
			}

			if (isExpired(typeEntry, typeStore.meta.ttl)) {
				delete typeStore.byId[id];
				cacheStats.misses++;
				return null;
			}

			// Update access time for LRU
			typeEntry.accessTime = Date.now();
			cacheStats.hits++;
			return typeEntry.data;
		},

		/**
		 * Get cached list for an entity type
		 * @param {string} type - Entity type
		 * @returns {Array|null} Cached list or null if not found/expired
		 */
		getList: function(type) {
			var typeStore = store[type];
			if (!typeStore || !typeStore.list) return null;

			if (isExpired(typeStore.list, typeStore.meta.ttl)) {
				typeStore.list = null;
				return null;
			}

			return typeStore.list.data;
		},

		/**
		 * Cache a single item
		 * Supports both entity-type API: set(type, id, data) and simple key API: set(key, data, options)
		 * @param {string} typeOrKey - Entity type or cache key
		 * @param {string|number|*} idOrData - Entity ID or data (if using simple key API)
		 * @param {*} [dataOrOptions] - Data to cache or options { ttl: ms }
		 */
		set: function(typeOrKey, idOrData, dataOrOptions) {
			var now = Date.now();

			// Simple key-value API: set(key, data) or set(key, data, options)
			if (arguments.length <= 2 || (arguments.length === 3 && typeof dataOrOptions === 'object' && dataOrOptions !== null && ('ttl' in dataOrOptions || 'stale' in dataOrOptions))) {
				var key = typeOrKey;
				var data = idOrData;
				var options = dataOrOptions || {};

				kvStore[key] = {
					data: data,
					timestamp: now,
					accessTime: now,
					ttl: options.ttl || DEFAULT_TTL,
					stale: options.stale || false
				};

				enforceKvLRU();
				emit('updated', { key: key, data: data });
				emitPubSub('funky:cache:set', { key: key, data: data });
				return;
			}

			// Entity-type API: set(type, id, data)
			var typeStore = getTypeStore(typeOrKey);

			typeStore.byId[idOrData] = {
				data: dataOrOptions,
				timestamp: now,
				accessTime: now
			};

			// Also update in list if present
			if (typeStore.list && Array.isArray(typeStore.list.data)) {
				var list = typeStore.list.data;
				var index = list.findIndex(function(item) {
					return item && (item.id === idOrData || item.id === String(idOrData));
				});
				if (index !== -1) {
					list[index] = dataOrOptions;
				}
			}

			enforceLRU(typeStore);
			emit('updated', { type: typeOrKey, id: idOrData, data: dataOrOptions });
		},

		/**
		 * Cache a list of items
		 * @param {string} type - Entity type
		 * @param {Array} data - List of items to cache
		 */
		setList: function(type, data) {
			var typeStore = getTypeStore(type);
			var now = Date.now();

			typeStore.list = {
				data: data,
				timestamp: now
			};

			// Also populate byId cache from list
			if (Array.isArray(data)) {
				data.forEach(function(item) {
					if (item && item.id) {
						typeStore.byId[item.id] = {
							data: item,
							timestamp: now,
							accessTime: now
						};
					}
				});
				enforceLRU(typeStore);
			}
		},

		/**
		 * Invalidate a single cached item
		 * @param {string} type - Entity type
		 * @param {string|number} id - Entity ID
		 */
		invalidate: function(type, id) {
			var typeStore = store[type];
			if (!typeStore) return;

			delete typeStore.byId[id];

			// Also remove from list if present
			if (typeStore.list && Array.isArray(typeStore.list.data)) {
				typeStore.list.data = typeStore.list.data.filter(function(item) {
					return !(item && (item.id === id || item.id === String(id)));
				});
			}

			emit('invalidated', { type: type, id: id });
		},

		/**
		 * Clear all cached data for an entity type, or clear kvStore if no argument
		 * @param {string} [type] - Entity type (optional)
		 */
		clear: function(type) {
			if (arguments.length === 0) {
				// Clear kvStore when called without arguments
				kvStore = {};
				emit('cleared', { type: null });
				return;
			}
			if (store[type]) {
				store[type].byId = {};
				store[type].list = null;
			}
			emit('cleared', { type: type });
		},

		/**
		 * Clear all cached data
		 */
		clearAll: function() {
			store = {};
			emit('cleared', { type: null });
		},

		/**
		 * Check if an item exists in cache and is not expired
		 * @param {string} type - Entity type
		 * @param {string|number} id - Entity ID
		 * @returns {boolean}
		 */
		has: function(type, id) {
			return this.get(type, id) !== null;
		},

		/**
		 * Check if a list exists in cache and is not expired
		 * @param {string} type - Entity type
		 * @returns {boolean}
		 */
		hasList: function(type) {
			return this.getList(type) !== null;
		},

		/**
		 * Get cache statistics
		 * @returns {object} Stats per entity type
		 */
		stats: function() {
			var stats = {};
			Object.keys(store).forEach(function(type) {
				var typeStore = store[type];
				stats[type] = {
					itemCount: Object.keys(typeStore.byId).length,
					hasList: !!typeStore.list,
					ttl: typeStore.meta.ttl,
					maxEntries: typeStore.meta.maxEntries
				};
			});
			return stats;
		},

		/**
		 * Register an event listener
		 * @param {string} event - Event name ('updated', 'invalidated', 'cleared')
		 * @param {function} handler - Event handler
		 */
		on: function(event, handler) {
			if (!listeners[event]) {
				listeners[event] = [];
			}
			listeners[event].push(handler);
		},

		/**
		 * Remove an event listener
		 * @param {string} event - Event name
		 * @param {function} handler - Handler to remove
		 */
		off: function(event, handler) {
			if (!listeners[event]) return;
			listeners[event] = listeners[event].filter(function(h) {
				return h !== handler;
			});
		},

		// =========================================================================
		// Simple Key-Value API Methods
		// =========================================================================

		/**
		 * Delete a cache entry by key
		 * @param {string} key - Cache key
		 */
		delete: function(key) {
			delete kvStore[key];
			emit('invalidated', { key: key });
			emitPubSub('funky:cache:delete', { key: key });
		},

		/**
		 * Clear cache entries matching a pattern prefix
		 * @param {string} pattern - Key prefix to match (e.g., 'users:')
		 */
		clearPattern: function(pattern) {
			var keysToDelete = [];
			Object.keys(kvStore).forEach(function(key) {
				if (key.indexOf(pattern) === 0) {
					keysToDelete.push(key);
				}
			});
			keysToDelete.forEach(function(key) {
				delete kvStore[key];
			});
			emit('cleared', { pattern: pattern });
		},

		/**
		 * Set maximum cache size
		 * @param {number} size - Maximum number of entries
		 */
		setMaxSize: function(size) {
			kvMaxSize = size;
			enforceKvLRU();
		},

		/**
		 * Get current cache size
		 * @returns {number} Number of cached entries
		 */
		size: function() {
			return Object.keys(kvStore).length;
		},

		/**
		 * Get cache keys matching a prefix
		 * @param {string} [prefix] - Optional prefix to filter keys
		 * @returns {Array} Array of matching keys
		 */
		keys: function(prefix) {
			var allKeys = Object.keys(kvStore);
			if (!prefix) return allKeys;
			return allKeys.filter(function(key) {
				return key.indexOf(prefix) === 0;
			});
		},

		/**
		 * Get cache statistics
		 * @returns {Object} { hits, misses, hitRate }
		 */
		getStats: function() {
			var total = cacheStats.hits + cacheStats.misses;
			return {
				hits: cacheStats.hits,
				misses: cacheStats.misses,
				hitRate: total > 0 ? cacheStats.hits / total : 0
			};
		},

		/**
		 * Reset cache statistics
		 */
		resetStats: function() {
			cacheStats.hits = 0;
			cacheStats.misses = 0;
		}
	};

	// Register with Funky namespace
	Funky.register('Cache', Cache);

	console.log('[Funky.Cache] Initialized');

})(window);
