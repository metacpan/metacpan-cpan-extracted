/**
 * Funky Filter Toolbar - Saved Filters Management
 * 
 * Manages saved filters dropdown and filter state persistence with:
 * - Load/save/delete saved filters via API
 * - URL persistence for shareable filter links
 * - Quick filter dropdown UI
 * 
 * Usage:
 *   var toolbar = new Funky.FilterToolbar.create({
 *     context: 'trades',
 *     toolbarSelector: '#filterToolbar',
 *     dataTable: myDataTable,
 *     onFilterChange: function(filters) { ... }
 *   });
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.FilterToolbar] Registry not found. Load namespace.js first.');
		return;
	}

	/**
	 * FunkyFilterToolbar Constructor
	 * @param {Object} config - Configuration object
	 */
	function FunkyFilterToolbar(config) {
		this.config = Object.assign({
			context: 'default',
			toolbarSelector: null,
			onFilterChange: null,
			dataTable: null,
			savedFiltersEnabled: true,
			quickFiltersEnabled: true,
			persistToUrl: true
		}, config);

		this.savedFilters = [];
		this.activeFilterId = null;
		this.currentFilters = {};

		if (this.config.toolbarSelector) {
			this.init();
		}
	}

	/**
	 * Initialize toolbar
	 */
	FunkyFilterToolbar.prototype.init = function() {
		var self = this;
		var toolbar = document.querySelector(this.config.toolbarSelector);
		if (!toolbar) return;

		this._toolbar = toolbar;
		this._boundHandlers = {};

		// Load saved filters
		if (this.config.savedFiltersEnabled) {
			this.loadSavedFilters();
		}

		// Restore filters from URL
		if (this.config.persistToUrl) {
			this.restoreFromUrl();
		}

		// Bind toolbar toggle
		this._boundHandlers.toggleClick = function(e) {
			if (e.target.closest('.filter-toggle-btn')) {
				toolbar.classList.toggle('collapsed');
				Funky.Storage.setRaw('filter_toolbar_collapsed_' + self.config.context,
					toolbar.classList.contains('collapsed').toString());
			}
		};
		toolbar.addEventListener('click', this._boundHandlers.toggleClick);

		// Restore collapsed state
		var wasCollapsed = Funky.Storage.getRaw('filter_toolbar_collapsed_' + this.config.context, null);
		if (wasCollapsed === 'true') {
			toolbar.classList.add('collapsed');
		}

		// Bind saved filter dropdown
		this.bindSavedFilterDropdown();
	};

	/**
	 * Load saved filters from API
	 */
	FunkyFilterToolbar.prototype.loadSavedFilters = function() {
		var self = this;
		var useFunkyApi = window.Funky && window.Funky.Api;

		var promise;
		if (useFunkyApi) {
			// Funky.Api.get returns parsed JSON directly
			promise = Funky.Api.get('/api/saved_filters', { context: this.config.context });
		} else if (window.secureFetch) {
			promise = window.secureFetch('/api/saved_filters?context=' + this.config.context)
				.then(function(response) {
					return response.json();
				});
		} else {
			promise = fetch('/api/saved_filters?context=' + this.config.context)
				.then(function(response) {
					return response.json();
				});
		}

		promise
			.then(function(data) {
				self.savedFilters = data.filters || [];
				self.renderSavedFiltersDropdown();
			})
			.catch(function(error) {
				console.error('[Funky.FilterToolbar] Failed to load saved filters:', error);
			});
	};

	/**
	 * Bind saved filter dropdown events
	 */
	FunkyFilterToolbar.prototype.bindSavedFilterDropdown = function() {
		var self = this;
		var toolbar = this._toolbar;
		if (!toolbar) return;

		// Main click handler for toolbar (delegation)
		this._boundHandlers.toolbarClick = function(e) {
			var target = e.target;

			// Toggle dropdown
			var savedFilterBtn = target.closest('.saved-filter-btn');
			if (savedFilterBtn) {
				e.stopPropagation();
				var menu = savedFilterBtn.parentElement.querySelector('.saved-filter-menu');
				if (menu) {
					var isOpen = menu.classList.contains('show');
					menu.classList.toggle('show');
					savedFilterBtn.setAttribute('aria-expanded', !isOpen);
				}
				return;
			}

			// Delete filter
			if (target.classList.contains('filter-delete')) {
				e.stopPropagation();
				var filterItem = target.closest('.saved-filter-item');
				if (filterItem) {
					var filterId = filterItem.dataset.filterId;
					self.deleteFilter(filterId);
				}
				return;
			}

			// Filter item click
			var savedFilterItem = target.closest('.saved-filter-item');
			if (savedFilterItem) {
				var filterId = savedFilterItem.dataset.filterId;
				self.loadFilter(filterId);
				var menu = toolbar.querySelector('.saved-filter-menu');
				if (menu) menu.classList.remove('show');
				return;
			}

			// Save current filter
			if (target.closest('[data-action="save-filter"]')) {
				self.promptSaveFilter();
				return;
			}
		};
		toolbar.addEventListener('click', this._boundHandlers.toolbarClick);

		// Close on outside click
		this._boundHandlers.documentClick = function() {
			var menu = toolbar.querySelector('.saved-filter-menu');
			var btn = toolbar.querySelector('.saved-filter-btn');
			if (menu) menu.classList.remove('show');
			if (btn) btn.setAttribute('aria-expanded', 'false');
		};
		document.addEventListener('click', this._boundHandlers.documentClick);
	};

	/**
	 * Render the saved filters dropdown
	 */
	FunkyFilterToolbar.prototype.renderSavedFiltersDropdown = function() {
		var self = this;
		var D = Funky.Dom;
		var toolbar = this._toolbar || document.querySelector(this.config.toolbarSelector);
		var dropdownEl = toolbar ? toolbar.querySelector('.saved-filter-dropdown') : null;

		if (!dropdownEl) return;

		var activeFilter = this.savedFilters.find(function(f) { return f.id === self.activeFilterId; });
		var btnLabel = activeFilter ? activeFilter.name : 'Saved Filters';
		var hasActive = !!activeFilter;

		// Build items - use div wrapper since D.fragment returns native fragment without .child()
		var itemsContainer = D.div().class('saved-filters-items');

		if (this.savedFilters.length === 0) {
			itemsContainer.child(
				D.div().class('saved-filter-item').attr('role', 'menuitem').style({ color: 'var(--pro-text-muted)', cursor: 'default' }).text('No saved filters')
			);
		} else {
			this.savedFilters.forEach(function(filter) {
				var isActive = filter.id === self.activeFilterId;
				var filterInfo = D.div().class('filter-info');
				if (filter.is_default) {
					filterInfo.child(D.span().class('filter-star').aria('hidden', 'true').text('★'));
				}
				filterInfo.child(D.span().class('filter-label').text(filter.name));

				itemsContainer.child(
					D.div()
						.class(D.classes('saved-filter-item', isActive && 'active'))
						.data('filter-id', filter.id)
						.attr('role', 'menuitem')
						.attr('tabindex', '0')
						.aria('current', isActive ? 'true' : null)
						.child(
							filterInfo,
							D.button()
								.class('filter-delete')
								.attr('type', 'button')
								.aria('label', 'Delete filter ' + filter.name)
								.text('✕')
						)
				);
			});
		}

		// Build dropdown structure - use div wrapper since D.fragment returns native fragment without .child()
		var dropdown = D.div().class('saved-filter-dropdown').child(
			D.button()
				.class(D.classes('saved-filter-btn', hasActive && 'has-active'))
				.attr('type', 'button')
				.aria('haspopup', 'menu')
				.aria('expanded', 'false')
				.aria('label', activeFilter ? 'Saved Filters: ' + activeFilter.name + ' selected' : 'Saved Filters')
				.child(
					D.icon('fas fa-bookmark').aria('hidden', 'true'),
					D.span().class('filter-name').text(btnLabel),
					D.span().class('caret').aria('hidden', 'true').text('▼')
				),
			D.div().class('saved-filter-menu').attr('role', 'menu').aria('label', 'Saved Filters').child(
				D.div().class('saved-filter-menu-header').aria('hidden', 'true').text('Saved Filters'),
				itemsContainer,
				D.div().class('saved-filter-menu-actions').child(
					D.button().class('btn-funky btn-funky-primary').attr('type', 'button').data('action', 'save-filter').child(
						D.icon('fas fa-save').aria('hidden', 'true'),
						D.text(' Save Current')
					)
				)
			)
		);

		dropdownEl.innerHTML = '';
		dropdownEl.appendChild(dropdown.get());
	};

	/**
	 * Load a saved filter
	 */
	FunkyFilterToolbar.prototype.loadFilter = function(filterId) {
		var filter = this.savedFilters.find(function(f) { return f.id === filterId; });
		if (!filter) return;

		this.activeFilterId = filterId;
		this.currentFilters = filter.filter_config || {};

		// Apply filters
		if (this.config.onFilterChange) {
			this.config.onFilterChange(this.currentFilters);
		}

		// Reload DataTable
		if (this.config.dataTable && this.config.dataTable.ajax) {
			this.config.dataTable.ajax.reload();
		}

		// Update dropdown
		this.renderSavedFiltersDropdown();

		// Show toast and announce
		if (Funky.Toast) {
			Funky.Toast.success('Filter "' + filter.name + '" applied', 'Filter');
		}
		if (Funky.Announce) {
			Funky.Announce.polite('Filter ' + filter.name + ' applied');
		}
	};

	/**
	 * Delete a saved filter
	 */
	FunkyFilterToolbar.prototype.deleteFilter = function(filterId) {
		var self = this;
		var filter = this.savedFilters.find(function(f) { return f.id === filterId; });

		if (!confirm('Delete filter "' + filter.name + '"?')) return;

		var fetchFn = window.Funky && window.Funky.Api ? Funky.Api.fetch.bind(Funky.Api) : window.secureFetch;

		fetchFn('/api/saved_filters/' + filterId, {
				method: 'DELETE'
			})
			.then(function() {
				self.savedFilters = self.savedFilters.filter(function(f) { return f.id !== filterId; });
				if (self.activeFilterId === filterId) {
					self.activeFilterId = null;
				}
				self.renderSavedFiltersDropdown();

				if (Funky.Toast) {
					Funky.Toast.success('Filter deleted', 'Filter');
				}
				if (Funky.Announce) {
					Funky.Announce.polite('Filter ' + filter.name + ' deleted');
				}
			})
			.catch(function(error) {
				console.error('[Funky.FilterToolbar] Failed to delete filter:', error);
				if (Funky.Toast) {
					Funky.Toast.error('Failed to delete filter', 'Error');
				}
			});
	};

	/**
	 * Prompt to save current filter
	 */
	FunkyFilterToolbar.prototype.promptSaveFilter = function() {
		var name = prompt('Enter a name for this filter:');
		if (!name) return;

		this.saveFilter(name, this.currentFilters);
	};

	/**
	 * Save a filter
	 */
	FunkyFilterToolbar.prototype.saveFilter = function(name, filterConfig) {
		var self = this;
		var fetchFn = window.Funky && window.Funky.Api ? Funky.Api.fetch.bind(Funky.Api) : window.secureFetch;

		fetchFn('/api/saved_filters', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					name: name,
					context: this.config.context,
					filter_config: filterConfig
				})
			})
			.then(function(response) {
				return response.json();
			})
			.then(function(data) {
				self.loadSavedFilters(); // Reload list

				if (Funky.Toast) {
					Funky.Toast.success('Filter "' + name + '" saved', 'Filter');
				}
				if (Funky.Announce) {
					Funky.Announce.polite('Filter ' + name + ' saved');
				}
			})
			.catch(function(error) {
				console.error('[Funky.FilterToolbar] Failed to save filter:', error);
				if (Funky.Toast) {
					Funky.Toast.error('Failed to save filter', 'Error');
				}
			});
	};

	/**
	 * Update current filter state
	 */
	FunkyFilterToolbar.prototype.setFilters = function(filters) {
		this.currentFilters = filters;
		this.activeFilterId = null; // Clear active since modified
		this.renderSavedFiltersDropdown();

		if (this.config.persistToUrl) {
			this.persistToUrl();
		}
	};

	/**
	 * Persist current filters to URL
	 */
	FunkyFilterToolbar.prototype.persistToUrl = function() {
		var url = new URL(window.location);

		// Clear existing filter params
		var keysToDelete = [];
		url.searchParams.forEach(function(value, key) {
			if (key.startsWith('filter_')) {
				keysToDelete.push(key);
			}
		});
		keysToDelete.forEach(function(key) {
			url.searchParams.delete(key);
		});

		// Add current filters
		var self = this;
		Object.keys(this.currentFilters).forEach(function(key) {
			var value = self.currentFilters[key];
			if (value !== null && value !== undefined && value !== '') {
				url.searchParams.set('filter_' + key, value);
			}
		});

		window.history.replaceState({}, '', url);
	};

	/**
	 * Restore filters from URL
	 */
	FunkyFilterToolbar.prototype.restoreFromUrl = function() {
		var url = new URL(window.location);
		var filters = {};

		url.searchParams.forEach(function(value, key) {
			if (key.startsWith('filter_')) {
				filters[key.replace('filter_', '')] = value;
			}
		});

		if (Object.keys(filters).length > 0) {
			this.currentFilters = filters;
			if (this.config.onFilterChange) {
				this.config.onFilterChange(this.currentFilters);
			}
		}
	};

	/**
	 * Get copy-able filter link
	 */
	FunkyFilterToolbar.prototype.getFilterLink = function() {
		this.persistToUrl();
		return window.location.href;
	};

	/**
	 * Destroy and cleanup
	 */
	FunkyFilterToolbar.prototype.destroy = function() {
		var toolbar = this._toolbar;

		// Remove event listeners
		if (toolbar && this._boundHandlers) {
			if (this._boundHandlers.toggleClick) {
				toolbar.removeEventListener('click', this._boundHandlers.toggleClick);
			}
			if (this._boundHandlers.toolbarClick) {
				toolbar.removeEventListener('click', this._boundHandlers.toolbarClick);
			}
			if (this._boundHandlers.documentClick) {
				document.removeEventListener('click', this._boundHandlers.documentClick);
			}
		}

		this._boundHandlers = {};
		this._toolbar = null;
		this.savedFilters = [];
		this.currentFilters = {};

		// Unregister from _instances
		if (this.config.toolbarSelector) {
			var containerId = this.config.toolbarSelector.replace(/^#/, '');
			delete Funky.FilterToolbar._instances[containerId];
		}
	};

	// Factory object
	var FilterToolbarFactory = {
		/**
		 * Instance registry for Bindable Interface
		 * Keyed by container ID (toolbarSelector without #)
		 */
		_instances: {},

		/**
		 * Create new FilterToolbar instance
		 * @param {Object} config - Configuration options
		 * @returns {FunkyFilterToolbar} New instance
		 */
		create: function(config) {
			var instance = new FunkyFilterToolbar(config);

			// Register by container ID for Bindable Interface
			if (config.toolbarSelector) {
				var containerId = config.toolbarSelector.replace(/^#/, '');
				this._instances[containerId] = instance;
			}

			return instance;
		},

		/**
		 * Get instance by container ID
		 * @param {string} containerId - Container element ID
		 * @returns {FunkyFilterToolbar|undefined} Instance if found
		 */
		getInstance: function(containerId) {
			return this._instances[containerId];
		},

		/**
		 * Bindable Interface: Set filter data
		 * @param {string} containerId - Container element ID
		 * @param {Object} filters - Filter state to set
		 */
		setData: function(containerId, filters) {
			var instance = this._instances[containerId];
			if (instance) {
				instance.setFilters(filters || {});
				
				// Trigger onFilterChange callback if configured
				if (instance.config.onFilterChange) {
					instance.config.onFilterChange(instance.currentFilters);
				}
				
				// Reload DataTable if configured
				if (instance.config.dataTable && instance.config.dataTable.ajax) {
					instance.config.dataTable.ajax.reload();
				}
			} else {
				console.warn('[Funky.FilterToolbar] No instance found for container:', containerId);
			}
		},

		/**
		 * Bindable Interface: Get current filter state
		 * @param {string} containerId - Container element ID
		 * @returns {Object} Current filter state
		 */
		getData: function(containerId) {
			var instance = this._instances[containerId];
			if (instance) {
				return {
					filters: instance.currentFilters,
					activeFilterId: instance.activeFilterId,
					savedFilters: instance.savedFilters
				};
			}
			console.warn('[Funky.FilterToolbar] No instance found for container:', containerId);
			return { filters: {}, activeFilterId: null, savedFilters: [] };
		},

		constructor: FunkyFilterToolbar
	};

	// Register with Funky namespace
	Funky.register('FilterToolbar', FilterToolbarFactory);

})(window);
