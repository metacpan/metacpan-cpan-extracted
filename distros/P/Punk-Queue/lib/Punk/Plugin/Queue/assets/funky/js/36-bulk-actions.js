/**
 * Funky Bulk Actions - Row Selection and Bulk Operations for Funky.Table
 *
 * Manages bulk action toolbar and integrates with Funky.Table selection:
 * - Listens to Funky.Table selection events
 * - Shows/hides action bar based on selection
 * - Provides action buttons with callbacks
 * - Dynamic action management via ActionRegistry
 *
 * Usage:
 *   var bulk = Funky.BulkActions.create({
 *     table: myFunkyTable,  // Funky.Table instance
 *     actions: [
 *       { id: 'delete', label: 'Delete Selected', icon: 'fa-trash', variant: 'danger' }
 *     ],
 *     onAction: function(actionId, selectedItems) { ... }
 *   });
 *
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.BulkActions] Registry not found. Load namespace.js first.');
		return;
	}

	/**
	 * FunkyBulkActions Constructor
	 * @param {Object} config - Configuration options
	 */
	function FunkyBulkActions(config) {
		this.config = Object.assign({
			table: null,                    // Funky.Table instance (required)
			tableSelector: null,            // Alternative: CSS selector to find table container
			actions: [],
			onAction: null,
			barPosition: 'top',             // 'top' or 'bottom'
			barClass: '',                   // Additional CSS class for action bar
			showCount: true,                // Show selection count badge
			showClear: true,                // Show clear button
			animation: true                 // Animate bar show/hide
		}, config);

		this._actionBar = null;
		this._table = null;
		this._container = null;
		this._boundHandlers = {};
		this._subscriptions = [];

		// Create ActionRegistry for dynamic action management
		var self = this;
		this.actionRegistry = Funky.ActionRegistry.create({
			schema: {
				label: '',
				icon: null,
				variant: 'primary',
				order: 50,
				hidden: false,
				disabled: false
			},
			onAdd: function() {
				self._rebuildButtons();
			},
			onRemove: function() {
				self._rebuildButtons();
			},
			onUpdate: function() {
				self._rebuildButtons();
			}
		});

		// Populate from initial config
		this.config.actions.forEach(function(action) {
			self.actionRegistry.add(action);
		});

		// Resolve table reference
		this._resolveTable();

		if (this._table) {
			this._init();
		} else {
			console.warn('[Funky.BulkActions] No Funky.Table instance provided or found');
		}
	}

	/**
	 * Resolve Funky.Table reference from config
	 */
	FunkyBulkActions.prototype._resolveTable = function() {
		// Direct table instance
		if (this.config.table) {
			this._table = this.config.table;
			// Funky.Table.container is a DOM element directly
			this._container = this._table.container || null;
			return;
		}

		// Find by selector
		if (this.config.tableSelector) {
			var containerId = this.config.tableSelector.replace(/^#/, '');

			// Try to get instance from Funky.Table registry
			if (Funky.Table && Funky.Table.getInstance) {
				this._table = Funky.Table.getInstance(containerId);
				if (this._table) {
					this._container = this._table.container || null;
					return;
				}
			}

			// Fallback: find container element
			this._container = document.querySelector(this.config.tableSelector);
		}
	};

	/**
	 * Initialize bulk actions
	 */
	FunkyBulkActions.prototype._init = function() {
		var self = this;

		// Create action bar
		this._createActionBar();

		// Listen to table DOM events (funky.table.select fires on any selection change)
		// The table dispatches this on its wrapper element
		var tableWrapper = this._table.wrapper && this._table.wrapper.el;

		if (tableWrapper) {
			this._boundHandlers.onSelectionChange = function() {
				self._updateUI();
			};

			tableWrapper.addEventListener('funky.table.select', this._boundHandlers.onSelectionChange);
		}

		// Also listen to table's onSelect/onDeselect callbacks if we can patch them
		// This handles the case where the table was created without explicit callbacks
		if (this._table.config) {
			var originalOnSelect = this._table.config.onSelect;
			var originalOnDeselect = this._table.config.onDeselect;

			this._table.config.onSelect = function(data, ids) {
				if (originalOnSelect) originalOnSelect(data, ids);
				self._updateUI();
			};

			this._table.config.onDeselect = function(data, table) {
				if (originalOnDeselect) originalOnDeselect(data, table);
				self._updateUI();
			};
		}

		// Initial UI update
		this._updateUI();
	};

	/**
	 * Create the bulk action toolbar
	 */
	FunkyBulkActions.prototype._createActionBar = function() {
		var self = this;

		// Create action bar element (starts hidden, show() makes it visible)
		var actionBar = document.createElement('div');
		actionBar.className = 'bulk-action-bar' + (this.config.barClass ? ' ' + this.config.barClass : '');
		actionBar.style.display = 'none';  // Start hidden
		actionBar.setAttribute('role', 'toolbar');
		actionBar.setAttribute('aria-label', 'Bulk actions');

		var inner = document.createElement('div');
		inner.className = 'bulk-action-bar-inner d-flex align-items-center gap-3';

		// Selection count badge
		if (this.config.showCount) {
			var countBadge = document.createElement('span');
			countBadge.className = 'selected-count badge bg-primary';
			countBadge.setAttribute('aria-live', 'polite');
			countBadge.setAttribute('aria-atomic', 'true');
			countBadge.textContent = '0 selected';
			inner.appendChild(countBadge);
		}

		// Action buttons container
		var buttonsContainer = document.createElement('div');
		buttonsContainer.className = 'bulk-actions-buttons d-flex gap-2';
		buttonsContainer.setAttribute('role', 'group');
		buttonsContainer.setAttribute('aria-label', 'Available actions');
		inner.appendChild(buttonsContainer);

		// Clear button
		if (this.config.showClear) {
			var clearBtn = document.createElement('button');
			clearBtn.type = 'button';
			clearBtn.className = 'btn btn-sm btn-outline-secondary btn-clear-selection';
			clearBtn.setAttribute('aria-label', 'Clear selection');
			clearBtn.innerHTML = '<i class="fas fa-times" aria-hidden="true"></i> Clear';
			clearBtn.addEventListener('click', function() {
				self.clearSelection();
			});
			inner.appendChild(clearBtn);
		}

		actionBar.appendChild(inner);
		this._actionBar = actionBar;

		// Build action buttons from registry
		this._buildActionButtons();

		// Insert action bar
		if (this._container) {
			if (this.config.barPosition === 'top') {
				this._container.insertBefore(actionBar, this._container.firstChild);
			} else {
				this._container.appendChild(actionBar);
			}
		}
	};

	/**
	 * Build action buttons from registry
	 */
	FunkyBulkActions.prototype._buildActionButtons = function() {
		var self = this;
		var buttonsContainer = this._actionBar.querySelector('.bulk-actions-buttons');
		if (!buttonsContainer) return;

		buttonsContainer.innerHTML = '';

		this.actionRegistry.getSorted().forEach(function(action) {
			if (action.hidden) return;

			var variant = action.variant || 'primary';
			var btn = document.createElement('button');
			btn.type = 'button';
			btn.className = 'btn btn-sm btn-' + variant;
			btn.dataset.action = action.id;
			btn.setAttribute('aria-label', action.label);
			btn.innerHTML = (action.icon ? '<i class="fas ' + action.icon + '" aria-hidden="true"></i> ' : '') + action.label;

			if (action.disabled) {
				btn.disabled = true;
			}

			btn.addEventListener('click', function() {
				if (self.config.onAction) {
					self.config.onAction(action.id, self.getSelectedItems(), self._table);
				}

				// Emit event
				if (Funky.PubSub) {
					Funky.PubSub.emit('funky:bulk-actions:action', {
						actionId: action.id,
						items: self.getSelectedItems(),
						table: self._table
					});
				}
			});

			buttonsContainer.appendChild(btn);
		});
	};

	/**
	 * Rebuild buttons when registry changes
	 */
	FunkyBulkActions.prototype._rebuildButtons = function() {
		if (this._actionBar) {
			this._buildActionButtons();
		}
	};

	/**
	 * Get selected items from Funky.Table
	 */
	FunkyBulkActions.prototype.getSelectedItems = function() {
		if (this._table && this._table.getSelectedData) {
			return this._table.getSelectedData();
		}
		return [];
	};

	/**
	 * Get selected IDs from Funky.Table
	 */
	FunkyBulkActions.prototype.getSelectedIds = function() {
		if (this._table && this._table.getSelectedIds) {
			return this._table.getSelectedIds();
		}
		return [];
	};

	/**
	 * Get selection count
	 */
	FunkyBulkActions.prototype.getSelectionCount = function() {
		if (this._table && this._table.selectedIds) {
			return this._table.selectedIds.size;
		}
		return 0;
	};

	/**
	 * Select items via Funky.Table
	 */
	FunkyBulkActions.prototype.select = function(ids) {
		if (this._table && this._table.select) {
			this._table.select(ids);
		}
		return this;
	};

	/**
	 * Deselect items via Funky.Table
	 */
	FunkyBulkActions.prototype.deselect = function(ids) {
		if (this._table && this._table.deselect) {
			this._table.deselect(ids);
		}
		return this;
	};

	/**
	 * Select all via Funky.Table
	 */
	FunkyBulkActions.prototype.selectAll = function() {
		if (this._table && this._table.selectAll) {
			this._table.selectAll();
		}
		return this;
	};

	/**
	 * Clear selection via Funky.Table
	 */
	FunkyBulkActions.prototype.clearSelection = function() {
		if (this._table && this._table.deselectAll) {
			this._table.deselectAll();
		}
		return this;
	};

	/**
	 * Update UI elements
	 */
	FunkyBulkActions.prototype._updateUI = function() {
		var count = this.getSelectionCount();

		var actionBar = this._actionBar;
		if (!actionBar) {
			return;
		}

		// Update count badge
		var countBadge = actionBar.querySelector('.selected-count');
		if (countBadge) {
			countBadge.textContent = count + ' selected';
		}

		// Show/hide action bar
		if (count > 0) {
			actionBar.classList.add('show');
			actionBar.style.display = '';  // Remove inline hide, let CSS class control display
		} else {
			actionBar.classList.remove('show');
			actionBar.style.display = 'none';  // Hide when no selection
		}

		// Emit event
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:bulk-actions:selection-changed', {
				count: count,
				items: this.getSelectedItems(),
				ids: this.getSelectedIds()
			});
		}
	};

	/**
	 * Add a bulk action
	 * @param {Object} action - Action config (requires id)
	 * @returns {FunkyBulkActions} this for chaining
	 */
	FunkyBulkActions.prototype.addAction = function(action) {
		this.actionRegistry.add(action);
		return this;
	};

	/**
	 * Remove a bulk action
	 * @param {string} id - Action ID
	 * @returns {FunkyBulkActions} this for chaining
	 */
	FunkyBulkActions.prototype.removeAction = function(id) {
		this.actionRegistry.remove(id);
		return this;
	};

	/**
	 * Enable or disable an action
	 * @param {string} id - Action ID
	 * @param {boolean} enabled - Whether action is enabled
	 * @returns {FunkyBulkActions} this for chaining
	 */
	FunkyBulkActions.prototype.setActionEnabled = function(id, enabled) {
		this.actionRegistry.update(id, { disabled: !enabled });
		return this;
	};

	/**
	 * Show or hide an action
	 * @param {string} id - Action ID
	 * @param {boolean} visible - Whether action is visible
	 * @returns {FunkyBulkActions} this for chaining
	 */
	FunkyBulkActions.prototype.setActionVisible = function(id, visible) {
		this.actionRegistry.update(id, { hidden: !visible });
		return this;
	};

	/**
	 * Get an action by ID
	 * @param {string} id - Action ID
	 * @returns {Object|null} Action config or null
	 */
	FunkyBulkActions.prototype.getAction = function(id) {
		return this.actionRegistry.get(id);
	};

	/**
	 * Get the Funky.Table instance
	 * @returns {Object|null} Table instance
	 */
	FunkyBulkActions.prototype.getTable = function() {
		return this._table;
	};

	/**
	 * Refresh - re-sync with table state
	 */
	FunkyBulkActions.prototype.refresh = function() {
		this._updateUI();
		return this;
	};

	/**
	 * Destroy instance
	 */
	FunkyBulkActions.prototype.destroy = function() {
		// Remove DOM event listeners from table wrapper
		if (this._table && this._table.wrapper && this._table.wrapper.el) {
			var tableWrapper = this._table.wrapper.el;
			if (this._boundHandlers.onSelectionChange) {
				tableWrapper.removeEventListener('funky.table.select', this._boundHandlers.onSelectionChange);
			}
		}

		// Unsubscribe from PubSub
		this._subscriptions.forEach(function(sub) {
			if (sub && sub.unsubscribe) {
				sub.unsubscribe();
			}
		});
		this._subscriptions = [];

		// Remove action bar
		if (this._actionBar && this._actionBar.parentNode) {
			this._actionBar.parentNode.removeChild(this._actionBar);
		}

		this._boundHandlers = {};
		this._actionBar = null;
		this._table = null;
		this._container = null;

		// Unregister from _instances (check both tableSelector and table.id)
		if (this.config.tableSelector) {
			var containerId = this.config.tableSelector.replace(/^#/, '');
			delete Funky.BulkActions._instances[containerId];
		}
		if (this.config.table && this.config.table.id) {
			delete Funky.BulkActions._instances[this.config.table.id];
		}
	};

	// Factory object for creating instances
	var BulkActionsFactory = {
		/**
		 * Instance registry
		 * Keyed by table container ID
		 */
		_instances: {},

		/**
		 * Create new BulkActions instance
		 * @param {Object} config - Configuration options
		 * @returns {FunkyBulkActions} New instance
		 */
		create: function(config) {
			var instance = new FunkyBulkActions(config);

			// Register by container ID
			if (config.tableSelector) {
				var containerId = config.tableSelector.replace(/^#/, '');
				this._instances[containerId] = instance;
			} else if (config.table && config.table.id) {
				this._instances[config.table.id] = instance;
			}

			return instance;
		},

		/**
		 * Get instance by container ID or table ID
		 * @param {string} id - Container or table ID
		 * @returns {FunkyBulkActions|undefined} Instance if found
		 */
		getInstance: function(id) {
			return this._instances[id];
		},

		/**
		 * Bindable Interface: Set selected items
		 * @param {string} containerId - Container element ID
		 * @param {Array} items - Array of IDs to select
		 */
		setData: function(containerId, items) {
			var instance = this._instances[containerId];
			if (instance && instance._table) {
				instance._table.deselectAll();
				if (Array.isArray(items) && items.length > 0) {
					instance._table.select(items);
				}
			} else {
				console.warn('[Funky.BulkActions] No instance found for:', containerId);
			}
		},

		/**
		 * Bindable Interface: Get selected items
		 * @param {string} containerId - Container element ID
		 * @returns {Array} Array of selected items
		 */
		getData: function(containerId) {
			var instance = this._instances[containerId];
			if (instance) {
				return instance.getSelectedItems();
			}
			console.warn('[Funky.BulkActions] No instance found for:', containerId);
			return [];
		},

		/**
		 * Constructor reference for instanceof checks
		 */
		constructor: FunkyBulkActions
	};

	// Register with Funky namespace
	Funky.register('BulkActions', BulkActionsFactory);

})(window);
