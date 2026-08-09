/**
 * Funky StatsBar - Dynamic Statistics Display
 * 
 * Renders a horizontal stats bar with configurable stat cards.
 * Supports real-time updates and integrates with cache layer.
 * 
 * Usage:
 *   Funky.StatsBar.init('#stats-container', {
 *     id: 'myStats',
 *     stats: [
 *       { id: 'total', icon: 'fa-users', label: 'Total', variant: 'primary' },
 *       { id: 'active', icon: 'fa-check', label: 'Active', variant: 'success' }
 *     ]
 *   });
 *   
 *   Funky.StatsBar.update('myStats', { total: 150, active: 142 });
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.StatsBar] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('StatsBar')) {
		return;
	}

	// Instance registry
	var _instances = Funky.Registry.createInstanceRegistry('StatsBar');

	/**
	 * Escape HTML to prevent XSS
	 */

	function escapeHtml(text) {
		if (text === null || text === undefined) return '';
		var div = document.createElement('div');
		div.textContent = String(text);
		return div.innerHTML;
	}

	/**
	 * Format number for display
	 */
	function formatNumber(value) {
		if (value === null || value === undefined) return '-';
		if (typeof value === 'number') {
			// Use Funky.Format if available
			if (Funky.Format && Funky.Format.number) {
				return Funky.Format.number(value, 0);
			}
			return value.toLocaleString();
		}
		return value;
	}

	/**
	 * Build DOM element for a stat card using theme's stat-card-pro structure
	 * Compatible with light/dark/system theme modes
	 */
	function buildStatCard(stat) {
		var D = Funky.Dom;
		var variant = stat.variant || 'secondary';
		var icon = stat.icon || 'fa-chart-bar';
		var label = stat.label || stat.id;

		// Use the theme's stat-card-pro structure for proper theme compatibility
		return D.div().class('stat-card-pro stat-card-' + variant).child(
			D.div().class('stat-icon').child(D.icon('fas ' + icon)),
			D.div().class('stat-content').child(
				D.div().class('stat-value').data('stat-id', stat.id).data('format', 'compact').text('-'),
				D.div().class('stat-label').text(label)
			)
		).get();
	}

	var StatsBar = {
		/**
		 * Initialize a stats bar
		 * @param {string} selector - Container selector
		 * @param {object} config - Configuration
		 * @param {string} config.id - Unique ID for this stats bar
		 * @param {Array} config.stats - Array of stat configurations
		 * @returns {object} StatsBar instance
		 */
		init: function(selector, config) {
			var container = document.querySelector(selector);
			if (!container) {
				console.error('[Funky.StatsBar] Container not found:', selector);
				return null;
			}

			config = config || {};
			var id = config.id || 'default';
			var stats = config.stats || [];

			// Build DOM elements - stat-card-pro elements directly in the container
			// The parent container should have .stats-bar .stats-bar-stretch classes for flexbox layout
			container.innerHTML = '';
			stats.forEach(function(stat) {
				container.appendChild(buildStatCard(stat));
			});

			// Store instance
			var instance = {
				container: container,
				config: config,
				stats: stats
			};

			// Register by config ID first, then container ID as fallback
			_instances.register(id, instance);

			// Also register by container ID if different from config ID
			if (container.id && container.id !== id) {
				_instances.register(container.id, instance);
			}

			return instance;
		},

		/**
		 * Update stat values
		 * @param {string} id - Stats bar ID
		 * @param {object} values - Object with stat id -> value mapping
		 * @param {object} options - Update options
		 * @param {boolean} options.announce - Whether to announce changes to screen readers
		 */
		update: function(id, values, options) {
			var instance = _instances.get(id);
			if (!instance) {
				console.warn('[Funky.StatsBar] Instance not found:', id);
				return;
			}

			var opts = options || {};
			var changedStats = [];

			Object.keys(values).forEach(function(statId) {
				var el = instance.container.querySelector('[data-stat-id="' + statId + '"]');
				if (el) {
					var oldValue = el.textContent;
					var newValue = formatNumber(values[statId]);
					el.textContent = newValue;

					// Animate if value changed
					if (oldValue !== newValue && oldValue !== '-') {
						el.classList.add('stats-value-changed');
						setTimeout(function() {
							el.classList.remove('stats-value-changed');
						}, 500);

						// Track changed stats for announcement
						var labelEl = el.parentElement && el.parentElement.querySelector('.stat-label');
						if (labelEl) {
							changedStats.push(labelEl.textContent + ': ' + newValue);
						}
					}
				}
			});

			// Announce significant changes to screen readers
			if (opts.announce !== false && changedStats.length > 0 && Funky.Announce) {
				Funky.Announce.polite('Stats updated. ' + changedStats.join(', '));
			}
		},

		/**
		 * Compute stats from data array
		 * @param {string} id - Stats bar ID
		 * @param {Array} data - Data array to compute stats from
		 * @param {Array} computations - Computation definitions
		 */
		compute: function(id, data, computations) {
			var instance = _instances.get(id);
			if (!instance) {
				console.warn('[Funky.StatsBar] Instance not found:', id);
				return;
			}

			var values = {};

			computations.forEach(function(comp) {
				var statId = comp.id;
				var type = comp.compute || 'count';

				switch (type) {
					case 'count':
						values[statId] = data.length;
						break;

					case 'countWhere':
						values[statId] = data.filter(function(item) {
							return item[comp.field] === comp.value;
						}).length;
						break;

					case 'sum':
						values[statId] = data.reduce(function(sum, item) {
							return sum + (parseFloat(item[comp.field]) || 0);
						}, 0);
						break;

					case 'avg':
						if (data.length === 0) {
							values[statId] = 0;
						} else {
							var sum = data.reduce(function(s, item) {
								return s + (parseFloat(item[comp.field]) || 0);
							}, 0);
							values[statId] = sum / data.length;
						}
						break;

					case 'min':
						values[statId] = data.reduce(function(min, item) {
							var val = parseFloat(item[comp.field]);
							return isNaN(val) ? min : Math.min(min, val);
						}, Infinity);
						if (values[statId] === Infinity) values[statId] = 0;
						break;

					case 'max':
						values[statId] = data.reduce(function(max, item) {
							var val = parseFloat(item[comp.field]);
							return isNaN(val) ? max : Math.max(max, val);
						}, -Infinity);
						if (values[statId] === -Infinity) values[statId] = 0;
						break;

					case 'custom':
						if (typeof comp.fn === 'function') {
							values[statId] = comp.fn(data);
						}
						break;
				}
			});

			this.update(id, values);
		},

		/**
		 * Get instance by ID
		 * @param {string} id - Stats bar ID
		 * @returns {object|null} Instance or null
		 */
		get: function(id) {
			return _instances.get(id) || null;
		},

		/**
		 * Destroy a stats bar instance
		 * @param {string} id - Stats bar ID
		 */
		destroy: function(id) {
			var instance = _instances.get(id);
			if (instance) {
				// Unregister by container ID if different from config ID
				if (instance.container.id && instance.container.id !== id) {
					_instances.unregister(instance.container.id);
				}
				instance.container.innerHTML = '';
				_instances.unregister(id);
			}
		},

		/**
		 * Destroy all stats bar instances
		 */
		destroyAll: function() {
			_instances.destroyAll();
		},

		/**
		 * Get instance by ID
		 * @param {string} id - Stats bar ID
		 * @returns {Object|null}
		 */
		getInstance: function(id) {
			return _instances.get(id);
		},

		/**
		 * Get all instances
		 * @returns {Object}
		 */
		getAll: function() {
			return _instances.getAll();
		},

		/**
		 * Bindable Interface: Set stats data
		 * @param {Array} data - Array of {label, value, trend} objects
		 */
		setData: function(data) {
			if (!Array.isArray(data)) {
				console.warn('[Funky.StatsBar] setData expects an array');
				return;
			}

			// Convert array format to id/value mapping
			// Find the first instance to update, or iterate all
			var allIds = _instances.list();
			var firstId = allIds[0];
			if (!firstId) {
				console.warn('[Funky.StatsBar] No instances available for setData');
				return;
			}

			var instance = _instances.get(firstId);
			var values = {};

			// Map data array to stat IDs based on position or label matching
			data.forEach(function(item, index) {
				if (instance.stats[index]) {
					var statId = instance.stats[index].id;
					values[statId] = item.value;
					
					// Update label if provided
					if (item.label) {
						var labelEl = instance.container.querySelector('[data-stat-id="' + statId + '"]');
						if (labelEl) {
							var labelSibling = labelEl.parentElement.querySelector('.stat-label');
							if (labelSibling) {
								labelSibling.textContent = item.label;
							}
						}
					}

					// Handle trend indicator if provided
					if (item.trend) {
						var valueEl = instance.container.querySelector('[data-stat-id="' + statId + '"]');
						if (valueEl) {
							valueEl.classList.remove('trend-up', 'trend-down', 'trend-neutral');
							valueEl.classList.add('trend-' + item.trend);
						}
					}
				}
			});

			this.update(firstId, values);
		}
	};

	// Expose _instances for bindable interface tests
	Object.defineProperty(StatsBar, '_instances', {
		get: function() {
			return _instances.getMap ? Object.fromEntries(_instances.getMap()) : {};
		},
		enumerable: true,
		configurable: true
	});

	// Register with Funky namespace
	Funky.register('StatsBar', StatsBar);

	console.log('[Funky.StatsBar] Initialized');

})(window);
