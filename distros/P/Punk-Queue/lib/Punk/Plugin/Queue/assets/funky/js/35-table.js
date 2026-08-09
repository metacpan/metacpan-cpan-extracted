/**
 * Funky.Table - Native ES5 table component
 * Replaces jQuery DataTables with Funky.Dom patterns
 * 
 * Usage:
 *   var table = Funky.Table.init('#myTable', {
 *     columns: [
 *       { data: 'id', title: 'ID' },
 *       { data: 'name', title: 'Name' }
 *     ],
 *     ajax: { url: '/api/data' }
 *   });
 * 
 * @version 1.0.4
 */
(function(window, document) {
	'use strict';

	// =========================================================================
	// Registry Guard
	// =========================================================================

	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Table] Registry not found. Load namespace.js first.');
		return;
	}

	var D = Funky.Dom;
	var P = Funky.PubSub;

	if (!D || !D.create) {
		console.error('[Funky.Table] Funky.Dom not loaded. Load dom.js first.');
		return;
	}

	// =========================================================================
	// Default Configuration
	// =========================================================================

	var DEFAULTS = {
		// Data source
		data: null,                          // Array of row data
		ajax: null,                          // AJAX config: { url, method, data, dataSrc }
		ajaxUrl: null,                       // Simple URL string (alternative to ajax object)
		tableName: null,                     // Table name for auto-detecting data key
		dataSrc: null,                       // Function to extract data from response
		extraAjaxData: null,                 // Extra data to send with AJAX requests
		updateStats: null,                   // Callback to update stats from response

		// Columns
		columns: [],                         // Column definitions

		// Paging
		paging: true,                        // Enable pagination
		pageLength: 25,                      // Rows per page
		lengthMenu: [[10, 25, 50, 100, -1], [10, 25, 50, 100, 'All']],
		lengthChange: true,                  // Allow length change

		// Searching
		searching: true,                     // Enable search
		searchDelay: 300,                    // Debounce delay (ms)

		// Ordering
		ordering: true,                      // Enable sorting
		order: [[0, 'asc']],                 // Initial sort: [[colIndex, 'asc'|'desc']]
		multiSort: false,                    // Allow multi-column sort

		// Server-side
		serverSide: false,                   // Server-side processing
		processing: true,                    // Show processing indicator
		deferLoading: null,                  // Pre-set total count

		// Selection
		select: false,                       // false | 'single' | 'multi' | 'os'
		selectAllCheckbox: false,            // Add select-all checkbox

		// Features
		enableColvis: false,                 // Column visibility toggle
		enableExport: false,                 // Export buttons
		enableImport: false,                 // Import button
		buttons: [],                         // Custom button configs

		// Responsive
		responsive: true,                    // Enable responsive mode
		breakpoints: {
			sm: 576,
			md: 768,
			lg: 992,
			xl: 1200
		},

		// Appearance
		scrollX: false,                      // Horizontal scroll
		scrollY: null,                       // Vertical scroll (height)
		autoWidth: true,                     // Auto-calculate widths
		fixedHeader: true,                   // Sticky header (default: on)
		striped: true,                       // Zebra striping
		hover: true,                         // Hover effect
		bordered: true,                      // Cell borders
		compact: false,                      // Compact mode
		emptyMessage: 'No data available',   // Empty state message

		// Conditional Formatting
		conditionalFormatting: {
			enabled: false,                  // Enable conditional formatting
			rules: [],                       // Formatting rules array
			onRuleApplied: null              // Callback when rule applied
		},

		// State
		stateSave: false,                    // Persist state
		stateKey: null,                      // Storage key
		stateDuration: 7200,                 // State TTL (seconds)

		// Accessibility
		ariaLabel: 'Data table',
		infoTemplate: 'Showing {start} to {end} of {total} entries',

		// Callbacks
		initComplete: null,                  // function(table)
		drawCallback: null,                  // function(table)
		rowCallback: null,                   // function(row, data, index)
		createdRow: null,                    // function(row, data, dataIndex)
		headerCallback: null,                // function(thead, data, start, end, display)
		footerCallback: null,                // function(tfoot, data, start, end, display)

		// Events (handled via callbacks or Funky.PubSub)
		onSelect: null,                      // function(selectedData, table)
		onDeselect: null,                    // function(deselectedData, table)
		onOrder: null,                       // function(order, table)
		onPage: null,                        // function(page, table)
		onSearch: null,                      // function(query, table)
		onExportCSV: null,                   // function(query, table)
		onExportExcel: null,                 // function(query, table)
		onImport: null,                      // function()
		onError: null,                       // function(error, table)

		// Debug
		debug: false                         // Console logging
	};

	var COLUMN_DEFAULTS = {
		data: null,                          // Data property name or index
		title: '',                           // Column header text
		name: null,                          // Column identifier
		className: '',                       // CSS class for cells
		orderable: true,                     // Allow sorting
		searchable: true,                    // Include in search
		visible: true,                       // Column visibility
		width: null,                         // Column width
		type: 'string',                      // Data type: string, num, date, html
		render: null,                        // Custom render function
		defaultContent: '',                  // Default if data is null
		responsivePriority: undefined,       // Lower = keep visible longer (undefined = always show)
		cellType: 'td',                      // 'td' or 'th'
		contentPadding: '',                  // Additional padding content
		createdCell: null                    // function(cell, cellData, rowData, rowIndex, colIndex)
	};

	// =========================================================================
	// Table Module
	// =========================================================================

	var _instances = Funky.Registry.createInstanceRegistry('Table');

	var Table = {};

	Table._idCounter = 0;

	// =========================================================================
	// TableInstance Constructor
	// =========================================================================

	function TableInstance(container, config) {
		var self = this;

		// Container element
		this.container = container;

		// Generate unique ID
		this.id = 'funky-table-' + (++Table._idCounter);

		// Merge configuration
		this.config = this._mergeConfig(config || {});

		if (this.config.debug) {
			console.log('[Funky.Table] TableInstance created with config:', this.config);
			console.log('[Funky.Table] serverSide:', this.config.serverSide, 'ajaxUrl:', this.config.ajaxUrl);
		}

		// Validate configuration
		this._validateConfig();

		// Initialize state
		this.data = [];
		this.displayData = [];
		this.totalRecords = 0;
		this.filteredRecords = 0;
		this.currentPage = 1;
		this.sortOrder = [];
		this.searchQuery = '';
		this.selectedRows = new Set();
		this.selectedIds = new Set();        // Track selected row IDs
		this.lastSelectedIndex = -1;         // Track last selected row for range selection
		this.columns = [];
		this.isLoading = false;
		this.isDestroyed = false;
		this.searchTimeout = null;
		this.currentBreakpoint = null;
		this.draw = 0;                       // Request counter for server-side
		this._formattingRules = [];          // Conditional formatting rules
		this._formattingCache = new Map();   // Cache for min/max calculations

		// DOM references
		this.wrapper = null;
		this.toolbar = null;
		this.tableEl = null;
		this.thead = null;
		this.tbody = null;
		this.tfoot = null;
		this.info = null;
		this.pagination = null;
		this.processingOverlay = null;

		// Bound event handlers (for proper removal)
		this._onResize = this._handleResize.bind(this);
		this._onSort = this._handleSort.bind(this);
		this._onClick = this._handleClick.bind(this);
		this._onKeyDown = this._handleKeyDown.bind(this);
		this._onHeaderKeyDown = this._handleHeaderKeydown.bind(this);

		// Cleanup functions for proper memory management
		this._cleanups = [];
		this._keyboardUnregisters = [];

		// Initialize
		this._init();
	}

	// =========================================================================
	// Configuration Methods
	// =========================================================================

	/**
	 * Deep merge user config with defaults
	 */
	TableInstance.prototype._mergeConfig = function(userConfig) {
		var merged = {};
		var key;

		// Copy defaults
		for (key in DEFAULTS) {
			if (DEFAULTS.hasOwnProperty(key)) {
				merged[key] = DEFAULTS[key];
			}
		}

		// Override with user config
		for (key in userConfig) {
			if (userConfig.hasOwnProperty(key)) {
				// Deep merge for objects (except arrays and functions)
				if (merged[key] !== null && 
					typeof merged[key] === 'object' && 
					!Array.isArray(merged[key]) &&
					typeof userConfig[key] === 'object' &&
					!Array.isArray(userConfig[key]) &&
					typeof userConfig[key] !== 'function') {
					merged[key] = this._mergeConfig.call(
						{ _mergeConfig: this._mergeConfig },
						Object.assign({}, merged[key], userConfig[key])
					);
				} else {
					merged[key] = userConfig[key];
				}
			}
		}

		return merged;
	};

	/**
	 * Validate configuration and warn about issues
	 */
	TableInstance.prototype._validateConfig = function() {
		var config = this.config;

		// Must have columns
		if (!config.columns || !config.columns.length) {
			console.warn('[Funky.Table] No columns defined');
		}

		// Must have data source
		if (!config.data && !config.ajax) {
			if (this.config.debug) {
				console.warn('[Funky.Table] No data source (data or ajax)');
			}
		}

		// Server-side requires ajax
		if (config.serverSide && !config.ajax) {
			console.warn('[Funky.Table] serverSide requires ajax config');
			config.serverSide = false;
		}

		// Selection mode validation and normalization
		// Support both 'select' and 'selectable' config keys
		if (this.config.debug) {
			console.log('[Funky.Table] Before normalization - select:', config.select, 'selectable:', config.selectable);
		}
		if (config.select && !config.selectable) {
			config.selectable = config.select;
		}
		if (!config.selectable) {
			config.selectable = 'none';
		}
		if (!['none', 'single', 'multi', 'os'].includes(config.selectable)) {
			console.warn('[Funky.Table] Invalid select mode:', config.selectable);
			config.selectable = 'none';
		}
		if (this.config.debug) {
			console.log('[Funky.Table] After normalization - selectable:', config.selectable);
		}
	};

	// =========================================================================
	// Initialization
	// =========================================================================

	/**
	 * Initialize the table instance
	 */
	TableInstance.prototype._init = function() {
		if (this.config.debug) {
			console.log('[Funky.Table] Initializing:', this.id);
		}

		// Process column definitions
		this._processColumns();

		// Add responsive control column for expand/collapse
		this._addResponsiveControlColumn();

		// Add checkbox column for multi-selection
		this._addCheckboxColumn();

		// Initialize sort order
		this._initializeSort();

		// Create DOM structure
		this._createDOM();

		// Bind events
		this._bindEvents();

		// Determine initial breakpoint
		this._determineBreakpoint();

		// Initialize conditional formatting
		this._initConditionalFormatting();

		// Initialize context menu
		this._initContextMenu();

		// Initialize filters
		this._initFilters();

		// Initialize advanced filter
		this._initAdvancedFilter();

		// Initialize column profiles
		this._initColumnProfiles();

		// Initialize aggregations
		this._initAggregations();

		// Initialize live binding
		this._initLiveBinding();

		// Initialize buttons
		this._initButtons();

		// Initialize animations
		this._initAnimations();

		// Initialize WebSocket
		this._initWebSocket();

		// Initialize accessibility
		this._initAccessibility();

		// Apply initial sort indicators
		this._updateSortIndicators();

		// Register instance
		var containerId = this.container.id || this.id;
		_instances.register(containerId, this);

		// Load initial data
		if (this.config.data) {
			this._setClientData(this.config.data);
		}
		this._loadData();

		// Callback
		if (typeof this.config.initComplete === 'function') {
			this.config.initComplete(this);
		}

		// Emit event
		if (P && P.emit) {
			P.emit('funky:table:init', { table: this, id: this.id });
		}
	};

	/**
	 * Process column definitions
	 */
	TableInstance.prototype._processColumns = function() {
		var self = this;

		this.columns = this.config.columns.map(function(col, index) {
			var processed = {};
			var key;

			// Copy column defaults
			for (key in COLUMN_DEFAULTS) {
				if (COLUMN_DEFAULTS.hasOwnProperty(key)) {
					processed[key] = COLUMN_DEFAULTS[key];
				}
			}

			// Override with column config
			for (key in col) {
				if (col.hasOwnProperty(key)) {
					processed[key] = col[key];
				}
			}

			// Ensure required properties
			processed.index = index;
			processed.name = processed.name || processed.data || ('col' + index);

			return processed;
		});
	};

	/**
	 * Initialize sort order from config
	 */
	TableInstance.prototype._initializeSort = function() {
		var self = this;

		if (this.config.order && this.config.order.length > 0) {
			this.sortOrder = this.config.order.map(function(item) {
				return {
					column: item[0],
					dir: item[1] || 'asc'
				};
			});
		}
	};

	// =========================================================================
	// DOM Creation
	// =========================================================================

	/**
	 * Create the complete DOM structure
	 */
	TableInstance.prototype._createDOM = function() {
		var self = this;

		// Create wrapper structure
		this.wrapper = D.div()
			.classAdd('funky-table-wrapper')
			.attr('id', this.id);

		// Add appearance classes
		if (this.config.striped) {
			this.wrapper.classAdd('funky-table-striped');
		}
		if (this.config.hover) {
			this.wrapper.classAdd('funky-table-hover');
		}
		if (this.config.bordered) {
			this.wrapper.classAdd('funky-table-bordered');
		}
		if (this.config.compact) {
			this.wrapper.classAdd('funky-table-compact');
		}

		// Toolbar (search, buttons, length menu)
		this.toolbar = this._createToolbar();
		this.toolbar.appendTo(this.wrapper);

		// Table container (for horizontal scroll and fixed header)
		var tableContainer = D.div()
			.classAdd('funky-table-container')
			.attr('tabindex', '-1');  // Prevent scroll container from stealing focus
		
		this.tableContainer = tableContainer;  // Store reference

		if (this.config.scrollX) {
			tableContainer.classAdd('funky-table-scroll-x');
		}
		
		// Responsive mode: disable horizontal scroll so columns hide instead
		if (this.config.responsive && !this.config.scrollX) {
			tableContainer.classAdd('funky-table-responsive-mode');
		}
		
		// Fixed header: create scrollable container with default max-height
		// scrollY overrides the default height
		if (this.config.fixedHeader || this.config.scrollY) {
			var maxHeight = this.config.scrollY || '60vh';
			tableContainer.classAdd('funky-table-scroll-body');
			tableContainer.style({ maxHeight: maxHeight, overflowY: 'auto' });
		}

		tableContainer.appendTo(this.wrapper);

		// Create table element
		this.tableEl = D.create('table')
			.classAdd('funky-table')
			.attr('role', 'grid')
			.attr('aria-label', this.config.ariaLabel)
			.attr('tabindex', '0')
			.appendTo(tableContainer);

		// Apply fixed header class for sticky headers
		if (this.config.fixedHeader) {
			this.tableEl.classAdd('funky-table-fixed-header');
		}

		// Create thead
		this.thead = D.create('thead').appendTo(this.tableEl);
		this._createHeader();

		// Create tbody
		this.tbody = D.create('tbody').appendTo(this.tableEl);

		// Footer section (pagination, info)
		var footer = D.div()
			.classAdd('funky-table-footer')
			.appendTo(this.wrapper);

		// Info
		this.info = D.div()
			.classAdd('funky-table-info')
			.attr('role', 'status')
			.attr('aria-live', 'polite')
			.appendTo(footer);

		// Context menu hint (shown when context menu is enabled)
		if (this.config.contextMenu && this.config.contextMenu.enabled) {
			this.contextMenuHint = D.div()
				.classAdd('funky-table-context-hint')
				.attr('title', 'Right-click on a row or press Shift+F10 to access actions')
				.html('<i class="fas fa-mouse-pointer"></i> <span>Right-click for options</span> <kbd>Shift+F10</kbd>')
				.appendTo(footer);
		}

		// Pagination
		this.pagination = D.div()
			.classAdd('funky-table-pagination')
			.appendTo(footer);

		// Processing overlay
		this.processingOverlay = D.div()
			.classAdd('funky-table-processing')
			.style({ display: 'none' })
			.appendTo(this.wrapper);

		D.div()
			.classAdd('funky-table-spinner')
			.appendTo(this.processingOverlay);

		// Append wrapper to container
		if (this.container.tagName === 'TABLE') {
			var parent = this.container.parentNode;
			parent.replaceChild(this.wrapper.el, this.container);
		} else {
			this.container.appendChild(this.wrapper.el);
		}
	};

	/**
	 * Create toolbar with search, buttons, length menu
	 */
	TableInstance.prototype._createToolbar = function() {
		var self = this;

		var toolbar = D.div().classAdd('funky-table-toolbar');

		// Left side: buttons
		var leftGroup = D.div()
			.classAdd('funky-table-toolbar-left')
			.appendTo(toolbar);

		this._createButtons(leftGroup);

		// Right side: length menu + search
		var rightGroup = D.div()
			.classAdd('funky-table-toolbar-right')
			.appendTo(toolbar);

		// Length menu
		if (this.config.paging && this.config.lengthChange) {
			this._createLengthMenu(rightGroup);
		}

		// Search
		if (this.config.searching) {
			this._createSearch(rightGroup);
		}

		return toolbar;
	};

	/**
	 * Create column headers
	 */
	TableInstance.prototype._createHeader = function() {
		var self = this;

		var headerRow = D.create('tr').appendTo(this.thead);
		this._headerRow = headerRow.el;  // Store reference for responsive updates

		this.columns.forEach(function(col, index) {
			var th = D.create('th')
				.classAdd('funky-table-th')
				.attr('data-column-index', index)
				.attr('scope', 'col');

			// Add column class
			if (col.className) {
				th.classAdd(col.className);
			}
			
			// Add control header class for responsive control column
			if (col.name === '_control') {
				th.classAdd('funky-table-control-header');
			}

			// Set width
			if (col.width) {
				th.style({ width: col.width });
			}

			// Title - use headerRender if provided, otherwise use title
			var titleSpan = D.span()
				.classAdd('funky-table-header-title');
			
			if (typeof col.headerRender === 'function') {
				var headerContent = col.headerRender();
				if (typeof headerContent === 'string') {
					titleSpan.html(headerContent);
				} else {
					titleSpan.text(col.title || col.data || '');
				}
			} else {
				titleSpan.text(col.title || col.data || '');
			}
			titleSpan.appendTo(th);

			// Sort indicator (if orderable)
			if (col.orderable && self.config.ordering) {
				th.classAdd('funky-table-sortable')
					.attr('tabindex', '0')
					.attr('role', 'columnheader')
					.attr('aria-sort', 'none');

				D.span()
					.classAdd('funky-table-sort-icon')
					.appendTo(th);
			}

			// Visibility
			if (!col.visible) {
				th.classAdd('funky-table-hidden');
			}

			th.appendTo(headerRow);
		});
	};

	/**
	 * Create length menu dropdown
	 */
	TableInstance.prototype._createLengthMenu = function(container) {
		var self = this;

		var lengthWrapper = D.div()
			.classAdd('funky-table-length')
			.appendTo(container);

		D.create('label')
			.attr('for', this.id + '-length')
			.text('Show ')
			.appendTo(lengthWrapper);

		var select = D.create('select')
			.classAdd('funky-table-length-select', 'form-select', 'form-select-sm')
			.attr('id', this.id + '-length')
			.attr('aria-label', 'Entries per page')
			.appendTo(lengthWrapper);

		var values = this.config.lengthMenu[0];
		var labels = this.config.lengthMenu[1] || values;

		for (var i = 0; i < values.length; i++) {
			var val = values[i];
			var opt = D.create('option')
				.attr('value', val)
				.text(labels[i])
				.appendTo(select);

			if (val === self.config.pageLength) {
				opt.attr('selected', 'selected');
			}
		}

		D.create('span')
			.text(' entries')
			.appendTo(lengthWrapper);

		// Use ComboBox if available
		if (Funky.ComboBox) {
			Funky.ComboBox.init(select.el, {
				searchable: false,
				clearable: false,
				width: '80px'
			});
		}

		// Event handler
		var changeHandler = function(e) {
			var newLength = parseInt(e.target.value, 10);
			self.config.pageLength = newLength;
			self.currentPage = 1;
			self._loadData();

			if (Funky.Announce) {
				Funky.Announce.polite('Showing ' + newLength + ' entries per page');
			}
		};
		select.on('change', changeHandler);
		this._cleanups.push(function() {
			select.off('change', changeHandler);
		});
	};

	/**
	 * Create search input
	 */
	TableInstance.prototype._createSearch = function(container) {
		var self = this;

		var searchWrapper = D.div()
			.classAdd('funky-table-search')
			.appendTo(container);

		// Search icon
		D.create('span')
			.classAdd('funky-table-search-icon')
			.html('<i class="fas fa-search"></i>')
			.appendTo(searchWrapper);

		// Search input
		this.searchInput = D.create('input')
			.classAdd('funky-table-search-input', 'form-control', 'form-control-sm')
			.attr('type', 'search')
			.attr('placeholder', 'Search...')
			.attr('aria-label', 'Search table')
			.attr('autocomplete', 'off')
			.appendTo(searchWrapper);

		// Clear button
		this.searchClear = D.create('button')
			.classAdd('funky-table-search-clear')
			.attr('type', 'button')
			.attr('aria-label', 'Clear search')
			.html('<i class="fas fa-times"></i>')
			.style({ display: 'none' })
			.appendTo(searchWrapper);

		// Debounced search handler
		var inputHandler = function(e) {
			var query = e.target.value;
			self._handleSearchInput(query);
		};
		this.searchInput.on('input', inputHandler);
		this._cleanups.push(function() {
			if (self.searchInput) self.searchInput.off('input', inputHandler);
		});

		// Clear button handler
		var clearHandler = function() {
			self.searchInput.el.value = '';
			self._handleSearchInput('');
			self.searchInput.el.focus();
		};
		this.searchClear.on('click', clearHandler);
		this._cleanups.push(function() {
			if (self.searchClear) self.searchClear.off('click', clearHandler);
		});

		// Keyboard handlers
		var keydownHandler = function(e) {
			// Enter key - immediate search
			if (e.key === 'Enter') {
				e.preventDefault();
				if (self.searchTimeout) {
					clearTimeout(self.searchTimeout);
					self.searchTimeout = null;
				}
				self._executeSearch(e.target.value);
			}

			// Escape - clear search
			if (e.key === 'Escape') {
				e.preventDefault();
				self.searchInput.el.value = '';
				self._handleSearchInput('');
			}
		};
		this.searchInput.on('keydown', keydownHandler);
		this._cleanups.push(function() {
			if (self.searchInput) self.searchInput.off('keydown', keydownHandler);
		});
	};

	/**
	 * Handle search input with debounce
	 */
	TableInstance.prototype._handleSearchInput = function(query) {
		var self = this;

		// Update clear button visibility
		if (this.searchClear) {
			this.searchClear.style({
				display: query.length > 0 ? 'flex' : 'none'
			});
		}

		// Clear existing timeout
		if (this.searchTimeout) {
			clearTimeout(this.searchTimeout);
		}

		// Debounce
		this.searchTimeout = setTimeout(function() {
			self._executeSearch(query);
		}, this.config.searchDelay);
	};

	/**
	 * Execute search
	 */
	TableInstance.prototype._executeSearch = function(query) {
		this.searchQuery = query.trim();
		this.currentPage = 1;

		if (this.config.debug) {
			console.log('[Funky.Table] Search:', this.searchQuery);
		}

		// Determine if using AJAX
		var ajaxUrl = this.config.ajaxUrl ||
			(this.config.ajax && typeof this.config.ajax === 'string' ? this.config.ajax : null) ||
			(this.config.ajax && this.config.ajax.url ? this.config.ajax.url : null);

		// For client-side, apply filters and re-render
		if (!ajaxUrl) {
			this._applyClientFilters();
			this._renderData();
		} else {
			// For server-side, reload data
			this._loadData();
		}

		// Callback
		if (typeof this.config.onSearch === 'function') {
			this.config.onSearch(this.searchQuery, this);
		}

		// Announce results
		if (Funky.Announce && this.searchQuery) {
			var count = this.filteredRecords;
			Funky.Announce.polite(count + ' results found for "' + this.searchQuery + '"');
		}
	};

	/**
	 * Create action buttons (legacy system - for enableColvis, enableExport, enableImport)
	 * The new button system uses _initButtons with buttons.items, buttons.export, buttons.colvis
	 */
	TableInstance.prototype._createButtons = function(container) {
		var self = this;

		// Check if any legacy buttons are needed
		var hasLegacyButtons = this.config.enableColvis || 
			this.config.enableExport || 
			this.config.enableImport ||
			(Array.isArray(this.config.buttons) && this.config.buttons.length > 0);
		
		// Skip if using new button system or no legacy buttons
		if (!hasLegacyButtons) return;

		var btnGroup = D.div()
			.classAdd('funky-table-buttons')
			.appendTo(container);

		// Column visibility
		if (this.config.enableColvis) {
			var colvisBtn = D.create('button')
				.classAdd('btn', 'btn-funky', 'btn-funky-secondary', 'btn-sm')
				.html('<i class="fas fa-columns"></i> Columns')
				.attr('type', 'button');
			// Use the same dropdown setup as the new button system
			this._setupColumnVisibilityButton(colvisBtn, {}, btnGroup.el);
		}

		// Export buttons
		if (this.config.enableExport) {
			D.create('button')
				.classAdd('btn', 'btn-funky', 'btn-funky-secondary', 'btn-sm')
				.html('<i class="fas fa-file-csv"></i> CSV')
				.attr('type', 'button')
				.on('click', function() { self._exportCSV(); })
				.appendTo(btnGroup);

			D.create('button')
				.classAdd('btn', 'btn-funky', 'btn-funky-secondary', 'btn-sm')
				.html('<i class="fas fa-file-excel"></i> Excel')
				.attr('type', 'button')
				.on('click', function() { self._exportXLSX(); })
				.appendTo(btnGroup);
		}

		// Import button
		if (this.config.enableImport) {
			D.create('button')
				.classAdd('btn', 'btn-funky', 'btn-funky-primary', 'btn-sm')
				.html('<i class="fas fa-file-upload"></i> Import')
				.attr('type', 'button')
				.on('click', function() { self._import(); })
				.appendTo(btnGroup);
		}

		// Custom buttons
		if (this.config.buttons && this.config.buttons.length > 0) {
			this.config.buttons.forEach(function(btnConfig) {
				var btn = D.create('button')
					.classAdd('btn', 'btn-funky', 'btn-sm')
					.html(btnConfig.text || btnConfig.label)
					.attr('type', 'button');

				if (btnConfig.className) {
					btn.classAdd(btnConfig.className);
				}

				if (btnConfig.action) {
					btn.on('click', function(e) {
						btnConfig.action.call(self, e, self);
					});
				}

				btn.appendTo(btnGroup);
			});
		}
	};

	// =========================================================================
	// Event Binding
	// =========================================================================

	/**
	 * Bind event handlers
	 */
	TableInstance.prototype._bindEvents = function() {
		var self = this;

		// Resize handler for responsive
		window.addEventListener('resize', this._onResize);
		this._cleanups.push(function() {
			window.removeEventListener('resize', self._onResize);
		});

		// Visibility observer for responsive - recalculate when table becomes visible
		if (this.config.responsive && Funky.VisibilityObserver) {
			var observeTarget = this.wrapper && this.wrapper.el ? this.wrapper.el : this.container;

			this._visibilityObserver = Funky.VisibilityObserver.init({ threshold: 0.01 });
			this._visibilityObserver.observe(observeTarget, {
				onVisible: function() {
					// Table just became visible - force recalculate responsive
					self._determineBreakpoint(true);
				}
			});

			this._cleanups.push(function() {
				if (self._visibilityObserver) {
					self._visibilityObserver.destroy();
					self._visibilityObserver = null;
				}
			});
		}

		// Header click for sorting
		if (this.thead && this.thead.el) {
			this.thead.el.addEventListener('click', this._onSort);
			this._cleanups.push(function() {
				if (self.thead && self.thead.el) {
					self.thead.el.removeEventListener('click', self._onSort);
				}
			});

			// Header keyboard navigation - use Funky.Keyboard for F1 help integration
			this._setupHeaderKeyboardShortcuts();

			// Bind select-all handler
			var selectAllCheckbox = this.thead.el.querySelector('.funky-table-select-all');
			if (selectAllCheckbox) {
				var selectAllHandler = function(e) {
					self._handleSelectAll(e.target.checked);
				};
				selectAllCheckbox.addEventListener('change', selectAllHandler);
				this._cleanups.push(function() {
					selectAllCheckbox.removeEventListener('change', selectAllHandler);
				});
			}
		}

		// Body click for selection and control
		if (this.tbody && this.tbody.el) {
			this.tbody.el.addEventListener('click', this._onClick);
			this._cleanups.push(function() {
				if (self.tbody && self.tbody.el) {
					self.tbody.el.removeEventListener('click', self._onClick);
				}
			});

			// Body keyboard navigation - use Funky.Keyboard for F1 help integration
			this._setupBodyKeyboardShortcuts();

			// Control button click for responsive expand
			var controlClickHandler = function(e) {
				self._handleControlClick(e);
			};
			this.tbody.el.addEventListener('click', controlClickHandler);
			this._cleanups.push(function() {
				if (self.tbody && self.tbody.el) {
					self.tbody.el.removeEventListener('click', controlClickHandler);
				}
			});
		}
	};

	/**
	 * Unbind event handlers
	 */
	TableInstance.prototype._unbindEvents = function() {
		// Execute all cleanup functions
		if (this._cleanups && this._cleanups.length) {
			this._cleanups.forEach(function(fn) {
				try { fn(); } catch (e) { /* ignore */ }
			});
			this._cleanups = [];
		}
	};

	// =========================================================================
	// Data Loading
	// =========================================================================

	/**
	 * Load data from server or render client data
	 */
	TableInstance.prototype._loadData = function() {
		if (this.isLoading || this.isDestroyed) return;

		// Determine AJAX URL
		var ajaxUrl = this.config.ajaxUrl || 
			(this.config.ajax && typeof this.config.ajax === 'string' ? this.config.ajax : null) ||
			(this.config.ajax && this.config.ajax.url ? this.config.ajax.url : null);

		if (!ajaxUrl) {
			// Client-side only
			this._applyClientFilters();
			this._renderData();
			return;
		}

		var self = this;
		this.isLoading = true;
		this.draw++;

		// Show processing
		this._showProcessing(true);

		// Build request parameters
		var params = this._buildAjaxParams();

		// Make request
		this._doAjaxRequest(ajaxUrl, params, function(response) {
			self._handleAjaxResponse(response);
		}, function(error) {
			self._handleAjaxError(error);
		});
	};

	/**
	 * Build AJAX request parameters (DataTables-compatible)
	 */
	TableInstance.prototype._buildAjaxParams = function() {
		var params = {};

		// Required DataTables params
		params.draw = this.draw;
		params.page = this.currentPage;
		params.limit = this.config.pageLength;

		// Search
		if (this.searchQuery) {
			params.search = this.searchQuery;
		}

		// Sort - JSON stringified array
		if (this.sortOrder.length > 0) {
			var sortArray = [];
			var columnMapping = this._getColumnMapping();
			var sortableColumns = this._getSortableColumns();

			for (var i = 0; i < this.sortOrder.length; i++) {
				var sortItem = this.sortOrder[i];
				var columnName = columnMapping[sortItem.column];

				if (columnName && sortableColumns.has(columnName)) {
					sortArray.push({
						column: columnName,
						dir: sortItem.dir
					});
				}
			}

			if (sortArray.length > 0) {
				params.sort = JSON.stringify(sortArray);
			}
		}

		// Extra AJAX data (filters, etc.)
		var extraData = this.config.extraAjaxData;
		if (extraData && typeof extraData === 'object') {
			for (var key in extraData) {
				if (extraData.hasOwnProperty(key)) {
					var value = extraData[key];
					// Skip empty values
					if (value !== null && value !== undefined && value !== '') {
						if (Array.isArray(value) && value.length === 0) {
							continue;
						}
						// Flatten single-item arrays
						if (Array.isArray(value) && value.length === 1) {
							params[key] = value[0];
						} else {
							params[key] = value;
						}
					}
				}
			}
		}

		return params;
	};

	/**
	 * Get column name mapping array
	 */
	TableInstance.prototype._getColumnMapping = function() {
		return this.columns.map(function(col) {
			return col.name || col.data;
		});
	};

	/**
	 * Get set of sortable column names
	 */
	TableInstance.prototype._getSortableColumns = function() {
		var sortable = new Set();
		this.columns.forEach(function(col) {
			if (col.orderable && (col.name || col.data)) {
				sortable.add(col.name || col.data);
			}
		});
		return sortable;
	};

	/**
	 * Execute AJAX request
	 */
	TableInstance.prototype._doAjaxRequest = function(baseUrl, params, onSuccess, onError) {
		var self = this;
		var url = this._buildUrl(baseUrl, params);

		// Use Funky.Api if available, else native fetch
		if (Funky.Api && Funky.Api.get) {
			Funky.Api.get(url)
				.then(function(response) {
					onSuccess(response);
				})
				.catch(function(error) {
					onError(error);
				});
		} else {
			// Native fetch fallback
			fetch(url, {
				method: 'GET',
				headers: {
					'Accept': 'application/json',
					'X-Requested-With': 'XMLHttpRequest'
				},
				credentials: 'same-origin'
			})
			.then(function(response) {
				if (!response.ok) {
					throw new Error('HTTP ' + response.status);
				}
				return response.json();
			})
			.then(function(data) {
				onSuccess(data);
			})
			.catch(function(error) {
				onError(error);
			});
		}
	};

	/**
	 * Build URL with query parameters
	 */
	TableInstance.prototype._buildUrl = function(baseUrl, params) {
		var url = baseUrl;

		// Check if base URL already has query params
		var hasQuery = url.indexOf('?') !== -1;
		var queryParts = [];

		for (var key in params) {
			if (params.hasOwnProperty(key)) {
				var value = params[key];
				if (Array.isArray(value)) {
					// Handle arrays as multiple params
					for (var i = 0; i < value.length; i++) {
						queryParts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value[i]));
					}
				} else {
					queryParts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
				}
			}
		}

		if (queryParts.length > 0) {
			url += (hasQuery ? '&' : '?') + queryParts.join('&');
		}

		return url;
	};

	/**
	 * Handle successful AJAX response
	 */
	TableInstance.prototype._handleAjaxResponse = function(response) {
		this.isLoading = false;
		this._showProcessing(false);

		if (this.config.debug) {
			console.log('[Funky.Table] _handleAjaxResponse raw response:', response);
		}

		// Extract data using dataSrc or auto-detect
		var data = this._extractData(response);

		if (this.config.debug) {
			console.log('[Funky.Table] _handleAjaxResponse extracted data:', data);
		}

		// Update totals
		this.totalRecords = response.total || response.recordsTotal || data.length;
		this.filteredRecords = response.total || response.recordsFiltered || data.length;

		// Store data
		this.data = data;
		this.displayData = data;

		if (this.config.debug) {
			console.log('[Funky.Table] _handleAjaxResponse this.displayData:', this.displayData);
		}

		// Clear formatting cache for new data
		this._clearFormattingCache();

		// Update stats callback
		if (typeof this.config.updateStats === 'function') {
			this.config.updateStats(response);
		}

		// Render
		this._renderData();

		// Announce data loaded for screen readers
		this._announceDataLoaded();

		// Restore focus if table had focus
		this._restoreFocus();

		if (this.config.debug) {
			console.log('[Funky.Table] Loaded', data.length, 'rows, total:', this.totalRecords);
		}
	};

	/**
	 * Extract data array from response
	 */
	TableInstance.prototype._extractData = function(response) {
		// Custom dataSrc function
		if (typeof this.config.dataSrc === 'function') {
			return this.config.dataSrc(response);
		}

		// Auto-detect based on tableName
		if (this.config.tableName) {
			var tableName = this.config.tableName;
			var snakeCase = tableName.replace(/-/g, '_');
			var irregularPlural = snakeCase.replace(/ys$/, 'ies');

			var possibleKeys = [tableName, snakeCase, irregularPlural, 'data'];

			for (var i = 0; i < possibleKeys.length; i++) {
				if (response[possibleKeys[i]]) {
					return response[possibleKeys[i]];
				}
			}
		}

		// Fallback to data key or response itself if array
		if (response.data) {
			return response.data;
		}

		if (Array.isArray(response)) {
			return response;
		}

		console.warn('[Funky.Table] Could not extract data from response');
		return [];
	};

	/**
	 * Handle AJAX error
	 */
	TableInstance.prototype._handleAjaxError = function(error) {
		this.isLoading = false;
		this._showProcessing(false);

		console.error('[Funky.Table] AJAX error:', error);

		// Callback
		if (typeof this.config.onError === 'function') {
			this.config.onError(error, this);
		}

		// Show error toast
		if (Funky.Toast) {
			Funky.Toast.error('Error loading data. Please try again.');
		}

		// Render empty state
		this.data = [];
		this.displayData = [];
		this.totalRecords = 0;
		this.filteredRecords = 0;
		this._renderData();
	};

	// =========================================================================
	// Client-Side Data Processing
	// =========================================================================

	/**
	 * Set client-side data
	 */
	TableInstance.prototype._setClientData = function(data) {
		this.data = Array.isArray(data) ? data : [];
		this.totalRecords = this.data.length;

		// Apply client-side filtering
		this._applyClientFilters();

		// Render
		this._renderData();
	};

	/**
	 * Apply client-side search and sort
	 */
	TableInstance.prototype._applyClientFilters = function() {
		var data = this.data.slice(); // Copy

		// Determine if using AJAX
		var ajaxUrl = this.config.ajaxUrl || 
			(this.config.ajax && typeof this.config.ajax === 'string' ? this.config.ajax : null) ||
			(this.config.ajax && this.config.ajax.url ? this.config.ajax.url : null);

		// Client-side search (only if not using server-side)
		if (this.searchQuery && !ajaxUrl) {
			data = this._filterClientData(data, this.searchQuery);
		}

		// Client-side sort (only if not using server-side)
		if (this.sortOrder.length > 0 && !ajaxUrl) {
			data = this._sortClientData(data);
		}

		this.filteredRecords = data.length;
		this.displayData = data;
	};

	/**
	 * Filter data client-side
	 */
	TableInstance.prototype._filterClientData = function(data, query) {
		var self = this;
		var lowerQuery = query.toLowerCase();
		var searchableColumns = this.columns.filter(function(col) {
			return col.searchable;
		});

		// Use FuzzySearch if available and enabled
		if (this.config.fuzzySearch && Funky.FuzzySearch) {
			return this._fuzzyFilter(data, query, searchableColumns);
		}

		// Standard contains search
		return data.filter(function(row) {
			for (var i = 0; i < searchableColumns.length; i++) {
				var col = searchableColumns[i];
				var value = self._getNestedValue(row, col.data);

				if (value !== null && value !== undefined) {
					if (String(value).toLowerCase().indexOf(lowerQuery) !== -1) {
						return true;
					}
				}
			}
			return false;
		});
	};

	/**
	 * Fuzzy filter using Funky.FuzzySearch
	 */
	TableInstance.prototype._fuzzyFilter = function(data, query, searchableColumns) {
		var self = this;

		// Build searchable text for each row
		var items = data.map(function(row, index) {
			var searchText = searchableColumns.map(function(col) {
				var value = self._getNestedValue(row, col.data);
				return value != null ? String(value) : '';
			}).join(' ');

			return { index: index, text: searchText, row: row };
		});

		// Perform fuzzy search
		var results = Funky.FuzzySearch.search(items, query, {
			key: 'text',
			threshold: this.config.fuzzyThreshold || 0.3
		});

		return results.map(function(result) {
			return result.row;
		});
	};

	/**
	 * Sort data client-side
	 */
	TableInstance.prototype._sortClientData = function(data) {
		var self = this;
		var sortOrder = this.sortOrder;

		return data.sort(function(a, b) {
			for (var i = 0; i < sortOrder.length; i++) {
				var sort = sortOrder[i];
				var col = self.columns[sort.column];
				if (!col) continue;

				var aVal = self._getNestedValue(a, col.data);
				var bVal = self._getNestedValue(b, col.data);

				// Handle null/undefined
				if (aVal == null) aVal = '';
				if (bVal == null) bVal = '';

				// Compare
				var cmp = 0;
				if (typeof aVal === 'number' && typeof bVal === 'number') {
					cmp = aVal - bVal;
				} else {
					cmp = String(aVal).localeCompare(String(bVal));
				}

				if (cmp !== 0) {
					return sort.dir === 'desc' ? -cmp : cmp;
				}
			}
			return 0;
		});
	};

	/**
	 * Get nested value from object using dot notation
	 */
	TableInstance.prototype._getNestedValue = function(obj, path) {
		if (!path || !obj) return null;

		var parts = path.split('.');
		var value = obj;

		for (var i = 0; i < parts.length; i++) {
			if (value === null || value === undefined) return null;
			value = value[parts[i]];
		}

		return value;
	};

	// =========================================================================
	// Processing State
	// =========================================================================

	/**
	 * Show/hide processing overlay
	 */
	TableInstance.prototype._showProcessing = function(show) {
		if (!this.processingOverlay) return;

		if (show) {
			this.processingOverlay.style({ display: 'flex' });
			if (this.tableEl) {
				this.tableEl.attr('aria-busy', 'true');
			}
			// Announce loading for screen readers
			this._announceLoading();
		} else {
			this.processingOverlay.style({ display: 'none' });
			if (this.tableEl) {
				this.tableEl.attr('aria-busy', 'false');
			}
		}
	};

	// =========================================================================
	// Row Rendering
	// =========================================================================

	/**
	 * Built-in column type handlers
	 */
	TableInstance.prototype.COLUMN_TYPES = {
		// Checkbox column for selection
		checkbox: function(data, type, row) {
			if (type !== 'display') return '';
			return '<input type="checkbox" class="funky-table-checkbox" />';
		},

		// Expand/collapse control for responsive
		control: function(data, type, row) {
			if (type !== 'display') return '';
			return '<button class="funky-table-control" aria-label="Show details">' +
				'<i class="fas fa-plus"></i></button>';
		}
	};

	/**
	 * Render data to table body
	 */
	TableInstance.prototype._renderData = function() {
		var self = this;

		if (this.config.debug) {
			console.log('[Funky.Table] _renderData:', this.displayData.length, 'rows');
		}

		// Clear tbody
		if (this.tbody && this.tbody.el) {
			this.tbody.el.innerHTML = '';
		}

		// Get page of data
		var pageData = this._getPageData();

		if (this.config.debug) {
			console.log('[Funky.Table] _renderData pageData:', pageData, 'length:', pageData ? pageData.length : 'null');
			console.log('[Funky.Table] _renderData tbody:', this.tbody, 'tbody.el:', this.tbody ? this.tbody.el : 'null');
		}

		// Check for empty state
		if (pageData.length === 0) {
			this._renderEmptyState();
		} else {
			// Render rows
			pageData.forEach(function(row, rowIndex) {
				var tr = self._renderRow(row, rowIndex);
				self.tbody.el.appendChild(tr.el);
			});
		}

		// Update info and pagination
		this._updateInfo();
		this._updatePagination();

		// Calculate and render aggregations
		if (this._aggregations) {
			this._calculateAggregations();
		}

		// Row animation delay
		this._applyRowAnimations();

		// Draw callback
		if (typeof this.config.drawCallback === 'function') {
			this.config.drawCallback.call(this, this);
		}
		
		// Apply responsive visibility to newly rendered rows
		if (this.config.responsive && this.currentBreakpoint) {
			this._updateResponsiveColumns();
		}

		// Emit event
		if (P && P.emit) {
			P.emit('funky:table:draw', { table: this, id: this.id });
		}

		// Announce to screen readers
		if (Funky.Announce) {
			var count = this.filteredRecords;
			var msg = count === 0 ? 'No records found' : count + ' records loaded';
			Funky.Announce.polite(msg);
		}
	};

	/**
	 * Get current page of data
	 */
	TableInstance.prototype._getPageData = function() {
		if (this.config.debug) {
			console.log('[Funky.Table] _getPageData: serverSide=', this.config.serverSide, 'paging=', this.config.paging, 'currentPage=', this.currentPage);
		}

		// For server-side pagination, the server already returns just the page data
		if (this.config.serverSide) {
			if (this.config.debug) {
				console.log('[Funky.Table] _getPageData (serverSide): returning', this.displayData.length, 'rows, currentPage:', this.currentPage);
				console.log('[Funky.Table] _getPageData displayData:', this.displayData);
			}
			return this.displayData;
		}
		
		if (!this.config.paging) {
			return this.displayData;
		}

		var pageLength = this.config.pageLength;

		// Handle "show all" option (-1)
		if (pageLength === -1) {
			return this.displayData;
		}

		var start = (this.currentPage - 1) * pageLength;
		var end = start + pageLength;

		return this.displayData.slice(start, end);
	};

	/**
	 * Render a single row
	 */
	TableInstance.prototype._renderRow = function(rowData, rowIndex) {
		var self = this;

		if (this.config.debug) {
			console.log('[Funky.Table] _renderRow:', rowIndex, 'rowData:', rowData);
		}

		var tr = D.create('tr')
			.classAdd('funky-table-row')
			.attr('data-row-index', rowIndex)
			.attr('data-index', rowIndex);

		// Add row ID for selection
		if (rowData.id !== undefined) {
			tr.attr('data-id', rowData.id);
		}

		// Selection state
		if (this.config.select && this.selectedIds.has(String(rowData.id))) {
			tr.classAdd('funky-table-row-selected');
			tr.attr('aria-selected', 'true');
		}

		// Render cells
		this.columns.forEach(function(col, colIndex) {
			var td = self._renderCell(rowData, col, colIndex, rowIndex);
			tr.el.appendChild(td.el);
		});

		// Add accessibility attributes (after cells are rendered so gridcell roles can be set)
		this._addRowAriaAttributes(tr.el, rowData, rowIndex);

		// Apply conditional formatting
		this._applyConditionalFormatting(rowData, tr.el);

		// CreatedRow callback
		if (typeof this.config.createdRow === 'function') {
			this.config.createdRow.call(this, tr.el, rowData, rowIndex);
		}

		// Row callback
		if (typeof this.config.rowCallback === 'function') {
			this.config.rowCallback.call(this, tr.el, rowData, rowIndex);
		}

		return tr;
	};

	/**
	 * Render a single cell
	 */
	TableInstance.prototype._renderCell = function(rowData, column, colIndex, rowIndex) {
		var td = D.create(column.cellType || 'td')
			.classAdd('funky-table-cell')
			.attr('data-column-index', colIndex)
			.attr('data-column', column.data || column.name);

		// Column class
		if (column.className) {
			td.classAdd(column.className);
		}

		// Hidden column
		if (!column.visible) {
			td.classAdd('funky-table-hidden');
		}

		// Get raw value
		var rawValue = this._getNestedValue(rowData, column.data);

		if (this.config.debug) {
			console.log('[Funky.Table] _renderCell: column.data=', column.data, 'rawValue=', rawValue, 'rowData=', rowData);
		}

		// Use default content if value is null/undefined
		if ((rawValue === null || rawValue === undefined) && column.defaultContent) {
			rawValue = column.defaultContent;
		}

		// Render content
		var content = this._renderCellContent(rawValue, column, rowData, rowIndex);

		if (typeof content === 'string') {
			td.html(content);
		} else if (content instanceof Node) {
			td.el.appendChild(content);
		} else if (content && content.el) {
			td.el.appendChild(content.el);
		}

		// CreatedCell callback
		if (typeof column.createdCell === 'function') {
			column.createdCell.call(this, td.el, rawValue, rowData, rowIndex, colIndex);
		}

		return td;
	};

	/**
	 * Render cell content using column renderer
	 */
	TableInstance.prototype._renderCellContent = function(value, column, rowData, rowIndex) {
		var renderer = this._getColumnRenderer(column);

		if (renderer) {
			var meta = {
				row: rowIndex,
				col: column.index,
				settings: this.config
			};
			return renderer(value, 'display', rowData, meta);
		}

		// Apply search highlighting for searchable columns without custom renderer
		if (column.searchable && this.searchQuery) {
			return this._highlightSearch(value);
		}

		return this._escapeHtml(value);
	};

	/**
	 * Highlight search matches in cell content
	 */
	TableInstance.prototype._highlightSearch = function(text) {
		if (!this.searchQuery || !text) return this._escapeHtml(text);

		var query = this.searchQuery.toLowerCase();
		var textStr = String(text);
		var lowerText = textStr.toLowerCase();
		var index = lowerText.indexOf(query);

		if (index === -1) return this._escapeHtml(text);

		// Build highlighted text
		var before = textStr.substring(0, index);
		var match = textStr.substring(index, index + query.length);
		var after = textStr.substring(index + query.length);

		return this._escapeHtml(before) +
			'<mark class="funky-table-highlight">' + this._escapeHtml(match) + '</mark>' +
			this._escapeHtml(after);
	};

	/**
	 * Get renderer for column (supports type shorthand)
	 */
	TableInstance.prototype._getColumnRenderer = function(column) {
		// Explicit render function
		if (typeof column.render === 'function') {
			return column.render;
		}

		// Type shorthand from COLUMN_TYPES
		if (column.type && this.COLUMN_TYPES[column.type]) {
			return this.COLUMN_TYPES[column.type];
		}

		// Funky.Renderers by name
		if (column.type && Funky.Renderers && typeof Funky.Renderers[column.type] === 'function') {
			return Funky.Renderers[column.type]();
		}

		// No renderer - use default escape
		return null;
	};

	/**
	 * Escape HTML for safe display
	 */
	TableInstance.prototype._escapeHtml = function(text) {
		if (text === null || text === undefined) return '-';
		if (typeof text === 'object') return JSON.stringify(text);

		var div = document.createElement('div');
		div.textContent = String(text);
		return div.innerHTML;
	};

	/**
	 * Render empty state
	 */
	TableInstance.prototype._renderEmptyState = function() {
		// Count visible columns (not hidden by responsive, user toggle, or control column visibility)
		var visibleCount = 0;
		var self = this;
		
		// Check if control column should be hidden (no hidden columns to expand)
		var totalHidden = (this.hiddenColumns ? this.hiddenColumns.length : 0) + 
		                  (this.manuallyHiddenColumns ? this.manuallyHiddenColumns.length : 0);
		var controlColumnVisible = totalHidden > 0;
		
		this.columns.forEach(function(col, index) {
			// Check if this is the control column
			var isControlColumn = col.name === '_control' || col.data === '_control';
			if (isControlColumn && !controlColumnVisible) {
				return; // Skip hidden control column
			}
			
			// Check if column is visible (not responsively hidden and not user-hidden)
			var isResponsivelyHidden = self.hiddenColumns && self.hiddenColumns.indexOf(index) !== -1;
			var isUserHidden = self._columnVisibility && self._columnVisibility[col.data] === false;
			var isVisible = col.visible !== false && !isResponsivelyHidden && !isUserHidden;
			if (isVisible) {
				visibleCount++;
			}
		});
		
		// Fallback to total columns if no visible count determined
		var colSpan = visibleCount > 0 ? visibleCount : this.columns.length;

		var tr = D.create('tr').classAdd('funky-table-empty-row');

		var td = D.create('td')
			.attr('colspan', colSpan)
			.classAdd('funky-table-empty-cell')
			.appendTo(tr);

		// Use EmptyState component if available
		if (Funky.EmptyState && Funky.EmptyState.html) {
			var emptyHtml = Funky.EmptyState.html({
				icon: 'inbox',
				title: this.config.emptyMessage || 'No data available',
				compact: true
			});
			td.el.innerHTML = emptyHtml;
		} else {
			D.div()
				.classAdd('funky-table-empty')
				.child(
					D.create('i').classAdd('fas', 'fa-inbox', 'funky-table-empty-icon'),
					D.span().text(this.config.emptyMessage || 'No data available')
				)
				.appendTo(td);
		}

		this.tbody.el.appendChild(tr.el);
	};

	/**
	 * Apply row animation delays for staggered entrance
	 */
	TableInstance.prototype._applyRowAnimations = function() {
		if (!this.tbody || !this.tbody.el) return;

		var rows = this.tbody.el.querySelectorAll('.funky-table-row');
		for (var i = 0; i < rows.length; i++) {
			rows[i].style.animationDelay = (i * 0.03) + 's';
		}
	};

	// =========================================================================
	// Conditional Formatting
	// =========================================================================

	/**
	 * Initialize Conditional Formatting
	 */
	TableInstance.prototype._initConditionalFormatting = function() {
		var config = this.config.conditionalFormatting;
		if (!config || !config.enabled) return;

		this._formattingRules = config.rules || [];
		this._formattingCache = new Map();
	};

	/**
	 * Apply conditional formatting during render
	 */
	TableInstance.prototype._applyConditionalFormatting = function(row, rowElement) {
		var self = this;

		if (!this._formattingRules || this._formattingRules.length === 0) return;

		this._formattingRules.forEach(function(rule) {
			if (rule.enabled === false) return;

			if (rule.target === 'row') {
				self._applyRowRule(rule, row, rowElement);
			} else if (rule.target === 'cell') {
				self._applyCellRule(rule, row, rowElement);
			}
		});
	};

	/**
	 * Apply row-level formatting rule
	 */
	TableInstance.prototype._applyRowRule = function(rule, row, rowElement) {
		var matches = false;

		if (typeof rule.condition === 'function') {
			matches = rule.condition(row);
		} else if (rule.expression) {
			matches = this._evaluateExpression(rule.expression, row);
		}

		if (matches) {
			if (rule.style) {
				this._applyStyles(rowElement, rule.style);
			}
			if (rule.className) {
				rowElement.classList.add(rule.className);
			}

			this._triggerRuleApplied(rule, rowElement, row);
		}
	};

	/**
	 * Apply cell-level formatting rule
	 */
	TableInstance.prototype._applyCellRule = function(rule, row, rowElement) {
		var cell = rowElement.querySelector('[data-column="' + rule.column + '"]');
		if (!cell) return;

		var value = this._getNestedValue(row, rule.column);

		switch (rule.type) {
			case 'colorScale':
				this._applyColorScale(rule, value, cell);
				break;
			case 'dataBar':
				this._applyDataBar(rule, value, cell, row);
				break;
			case 'iconSet':
				this._applyIconSet(rule, value, cell);
				break;
			default:
				this._applyValueConditions(rule, value, cell, row);
		}
	};

	/**
	 * Apply simple value conditions
	 */
	TableInstance.prototype._applyValueConditions = function(rule, value, cell, row) {
		var self = this;

		if (!rule.conditions) return;

		rule.conditions.forEach(function(condition) {
			var matches = false;

			if (condition.operator) {
				matches = self._evaluateOperator(condition.operator, value, condition.value);
			} else if (condition.value !== undefined) {
				matches = value === condition.value;
			} else if (typeof condition.test === 'function') {
				matches = condition.test(value, row);
			}

			if (matches) {
				if (condition.style) {
					self._applyStyles(cell, condition.style);
				}
				if (condition.className) {
					cell.classList.add(condition.className);
				}

				self._triggerRuleApplied(rule, cell, row);
			}
		});
	};

	/**
	 * Evaluate comparison operator
	 */
	TableInstance.prototype._evaluateOperator = function(operator, value, compareValue) {
		switch (operator) {
			case '===':
			case '==':
				return value == compareValue;
			case '!==':
			case '!=':
				return value != compareValue;
			case '>':
				return value > compareValue;
			case '>=':
				return value >= compareValue;
			case '<':
				return value < compareValue;
			case '<=':
				return value <= compareValue;
			case 'contains':
				return String(value).indexOf(compareValue) !== -1;
			case 'startsWith':
				return String(value).indexOf(compareValue) === 0;
			case 'endsWith':
				return String(value).slice(-compareValue.length) === compareValue;
			case 'between':
				return Array.isArray(compareValue) && value >= compareValue[0] && value <= compareValue[1];
			case 'in':
				return Array.isArray(compareValue) && compareValue.indexOf(value) !== -1;
			case 'empty':
				return value === null || value === undefined || value === '';
			case 'notEmpty':
				return value !== null && value !== undefined && value !== '';
			default:
				return false;
		}
	};

	/**
	 * Evaluate expression string
	 */
	TableInstance.prototype._evaluateExpression = function(expression, row) {
		try {
			var func = new Function('row', 'return ' + expression);
			return func(row);
		} catch (e) {
			console.warn('[Funky.Table] Failed to evaluate expression:', expression, e);
			return false;
		}
	};

	/**
	 * Apply color scale gradient
	 */
	TableInstance.prototype._applyColorScale = function(rule, value, cell) {
		var config = rule.colorScale;
		var numValue = parseFloat(value);

		if (isNaN(numValue)) return;

		var minVal = config.min.value === 'auto' ? this._getColumnMin(rule.column) : config.min.value;
		var maxVal = config.max.value === 'auto' ? this._getColumnMax(rule.column) : config.max.value;

		var color;

		if (config.mid) {
			var midVal = config.mid.value === 'auto' ? (minVal + maxVal) / 2 : config.mid.value;

			if (numValue <= minVal) {
				color = config.min.color;
			} else if (numValue >= maxVal) {
				color = config.max.color;
			} else if (numValue <= midVal) {
				var ratio = (numValue - minVal) / (midVal - minVal);
				color = this._interpolateColor(config.min.color, config.mid.color, ratio);
			} else {
				var ratio = (numValue - midVal) / (maxVal - midVal);
				color = this._interpolateColor(config.mid.color, config.max.color, ratio);
			}
		} else {
			var ratio = (numValue - minVal) / (maxVal - minVal);
			ratio = Math.max(0, Math.min(1, ratio));
			color = this._interpolateColor(config.min.color, config.max.color, ratio);
		}

		cell.style.backgroundColor = color;
	};

	/**
	 * Interpolate between two colors
	 */
	TableInstance.prototype._interpolateColor = function(color1, color2, ratio) {
		var rgb1 = this._hexToRgb(color1);
		var rgb2 = this._hexToRgb(color2);

		if (!rgb1 || !rgb2) return color1;

		var r = Math.round(rgb1.r + (rgb2.r - rgb1.r) * ratio);
		var g = Math.round(rgb1.g + (rgb2.g - rgb1.g) * ratio);
		var b = Math.round(rgb1.b + (rgb2.b - rgb1.b) * ratio);

		return 'rgb(' + r + ',' + g + ',' + b + ')';
	};

	/**
	 * Convert hex to RGB
	 */
	TableInstance.prototype._hexToRgb = function(hex) {
		if (hex.indexOf('rgb') === 0) {
			var match = hex.match(/(\d+),\s*(\d+),\s*(\d+)/);
			if (match) {
				return { r: parseInt(match[1]), g: parseInt(match[2]), b: parseInt(match[3]) };
			}
			return null;
		}

		var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
		return result ? {
			r: parseInt(result[1], 16),
			g: parseInt(result[2], 16),
			b: parseInt(result[3], 16)
		} : null;
	};

	/**
	 * Apply data bar
	 */
	TableInstance.prototype._applyDataBar = function(rule, value, cell, row) {
		var config = rule.dataBar;
		var numValue = parseFloat(value);

		if (isNaN(numValue)) return;

		var min = config.min === 'auto' ? this._getColumnMin(rule.column) : config.min;
		var max = config.max === 'auto' ? this._getColumnMax(rule.column) : config.max;

		var percentage = ((numValue - min) / (max - min)) * 100;
		percentage = Math.max(0, Math.min(100, percentage));

		var container = D.create('div')
			.classAdd('funky-data-bar-container');

		var bar = D.create('div')
			.classAdd('funky-data-bar')
			.style({
				width: percentage + '%',
				background: config.color || 'var(--pro-primary)'
			});

		container.el.appendChild(bar.el);

		if (config.showValue !== false) {
			var valueSpan = D.create('span')
				.classAdd('funky-data-bar-value')
				.text(cell.textContent);
			container.el.appendChild(valueSpan.el);
		}

		cell.innerHTML = '';
		cell.appendChild(container.el);
	};

	/**
	 * Get column minimum value
	 */
	TableInstance.prototype._getColumnMin = function(column) {
		var cacheKey = 'min_' + column;
		if (this._formattingCache.has(cacheKey)) {
			return this._formattingCache.get(cacheKey);
		}

		var min = Infinity;
		var self = this;
		this.data.forEach(function(row) {
			var val = parseFloat(self._getNestedValue(row, column));
			if (!isNaN(val) && val < min) min = val;
		});

		this._formattingCache.set(cacheKey, min);
		return min;
	};

	/**
	 * Get column maximum value
	 */
	TableInstance.prototype._getColumnMax = function(column) {
		var cacheKey = 'max_' + column;
		if (this._formattingCache.has(cacheKey)) {
			return this._formattingCache.get(cacheKey);
		}

		var max = -Infinity;
		var self = this;
		this.data.forEach(function(row) {
			var val = parseFloat(self._getNestedValue(row, column));
			if (!isNaN(val) && val > max) max = val;
		});

		this._formattingCache.set(cacheKey, max);
		return max;
	};

	/**
	 * Apply icon set
	 */
	TableInstance.prototype._applyIconSet = function(rule, value, cell) {
		var config = rule.iconSet;
		var numValue = parseFloat(value);
		var matchedIcon = null;

		for (var i = 0; i < config.icons.length; i++) {
			var iconRule = config.icons[i];
			if (this._evaluateOperator(iconRule.operator, numValue, iconRule.value)) {
				matchedIcon = iconRule;
				break;
			}
		}

		if (!matchedIcon) return;

		var iconClasses = matchedIcon.icon.split(' ');
		var icon = D.create('i');
		for (var j = 0; j < iconClasses.length; j++) {
			icon.classAdd(iconClasses[j]);
		}
		icon.style({ color: matchedIcon.color || 'inherit' });

		var originalContent = cell.textContent;
		var position = config.position || 'left';

		switch (position) {
			case 'left':
				cell.innerHTML = '';
				cell.appendChild(icon.el);
				if (config.showValue !== false) {
					cell.appendChild(document.createTextNode(' ' + originalContent));
				}
				break;
			case 'right':
				cell.innerHTML = '';
				if (config.showValue !== false) {
					cell.appendChild(document.createTextNode(originalContent + ' '));
				}
				cell.appendChild(icon.el);
				break;
			case 'replace':
				cell.innerHTML = '';
				cell.appendChild(icon.el);
				break;
		}
	};

	/**
	 * Apply styles object to element
	 */
	TableInstance.prototype._applyStyles = function(element, styles) {
		for (var prop in styles) {
			if (styles.hasOwnProperty(prop)) {
				element.style[prop] = styles[prop];
			}
		}
	};

	/**
	 * Trigger rule applied callback
	 */
	TableInstance.prototype._triggerRuleApplied = function(rule, element, row) {
		var config = this.config.conditionalFormatting;
		if (config && typeof config.onRuleApplied === 'function') {
			config.onRuleApplied(rule, element, row);
		}
	};

	/**
	 * Clear formatting cache (call on data change)
	 */
	TableInstance.prototype._clearFormattingCache = function() {
		if (this._formattingCache) {
			this._formattingCache.clear();
		}
	};

	// =========================================================================
	// Info & Pagination
	// =========================================================================

	/**
	 * Update info text
	 */
	TableInstance.prototype._updateInfo = function() {
		if (!this.info || !this.info.el) return;

		var pageLength = this.config.pageLength;
		var start = (this.currentPage - 1) * pageLength + 1;
		var end = Math.min(start + pageLength - 1, this.filteredRecords);
		var total = this.filteredRecords;
		var grandTotal = this.totalRecords;

		if (this.config.debug) {
			console.log('[Funky.Table] _updateInfo: pageLength=', pageLength, 'start=', start, 'end=', end, 'total=', total, 'grandTotal=', grandTotal);
			console.log('[Funky.Table] _updateInfo: infoTemplate=', this.config.infoTemplate);
		}

		if (total === 0) {
			start = 0;
			end = 0;
		}

		// Build info text with locale formatting
		var text = this.config.infoTemplate
			.replace('{start}', start.toLocaleString())
			.replace('{end}', end.toLocaleString())
			.replace('{total}', total.toLocaleString());

		// Show filtered count if different from total
		if (grandTotal !== total && grandTotal > 0) {
			text += ' (filtered from ' + grandTotal.toLocaleString() + ' total entries)';
		}

		this.info.el.textContent = text;
	};

	/**
	 * Update pagination controls
	 */
	TableInstance.prototype._updatePagination = function() {
		if (!this.config.paging || !this.pagination || !this.pagination.el) return;

		var self = this;

		// Clear existing
		this.pagination.el.innerHTML = '';

		var totalPages = this._getTotalPages();
		if (totalPages <= 1) return;

		// Create pagination nav
		var nav = D.create('nav')
			.attr('aria-label', 'Table pagination')
			.appendTo(this.pagination);

		var ul = D.create('ul')
			.classAdd('funky-table-pagination-list')
			.appendTo(nav);

		// Previous button
		this._createPaginationButton(ul, 'prev', '«', 'Previous page', this.currentPage === 1);

		// Page numbers
		var pages = this._getVisiblePageNumbers(totalPages);
		for (var i = 0; i < pages.length; i++) {
			var page = pages[i];
			if (page === 'ellipsis') {
				self._createPaginationEllipsis(ul);
			} else {
				self._createPaginationButton(ul, page, page, 'Page ' + page, false, page === self.currentPage);
			}
		}

		// Next button
		this._createPaginationButton(ul, 'next', '»', 'Next page', this.currentPage === totalPages);
	};

	/**
	 * Get total number of pages
	 */
	TableInstance.prototype._getTotalPages = function() {
		if (this.config.pageLength <= 0) return 1;
		return Math.ceil(this.filteredRecords / this.config.pageLength);
	};

	/**
	 * Get array of visible page numbers with ellipsis
	 */
	TableInstance.prototype._getVisiblePageNumbers = function(totalPages) {
		var current = this.currentPage;
		var pages = [];
		var maxVisible = 7; // Show at most 7 page buttons

		if (totalPages <= maxVisible) {
			// Show all pages
			for (var i = 1; i <= totalPages; i++) {
				pages.push(i);
			}
		} else {
			// Always show first page
			pages.push(1);

			if (current > 3) {
				pages.push('ellipsis');
			}

			// Show pages around current
			var start = Math.max(2, current - 1);
			var end = Math.min(totalPages - 1, current + 1);

			for (var j = start; j <= end; j++) {
				pages.push(j);
			}

			if (current < totalPages - 2) {
				pages.push('ellipsis');
			}

			// Always show last page
			pages.push(totalPages);
		}

		return pages;
	};

	/**
	 * Create pagination button
	 */
	TableInstance.prototype._createPaginationButton = function(container, value, label, ariaLabel, disabled, active) {
		var self = this;

		var li = D.create('li')
			.classAdd('funky-table-pagination-item')
			.appendTo(container);

		var btn = D.create('button')
			.classAdd('funky-table-pagination-btn')
			.attr('type', 'button')
			.attr('aria-label', ariaLabel)
			.text(label)
			.appendTo(li);

		if (disabled) {
			btn.classAdd('funky-table-pagination-disabled')
				.attr('disabled', 'disabled')
				.attr('aria-disabled', 'true');
		}

		if (active) {
			btn.classAdd('funky-table-pagination-active')
				.attr('aria-current', 'page');
		}

		if (!disabled) {
			btn.on('click', function() {
				self._goToPage(value);
			});
		}

		return li;
	};

	/**
	 * Create ellipsis indicator
	 */
	TableInstance.prototype._createPaginationEllipsis = function(container) {
		var li = D.create('li')
			.classAdd('funky-table-pagination-item', 'funky-table-pagination-ellipsis')
			.appendTo(container);

		D.create('span')
			.text('…')
			.attr('aria-hidden', 'true')
			.appendTo(li);

		return li;
	};

	/**
	 * Go to specific page
	 */
	TableInstance.prototype._goToPage = function(page) {
		var totalPages = this._getTotalPages();

		if (page === 'prev') {
			page = this.currentPage - 1;
		} else if (page === 'next') {
			page = this.currentPage + 1;
		}

		page = parseInt(page, 10);

		if (isNaN(page) || page < 1 || page > totalPages) return;
		if (page === this.currentPage) return;

		this.currentPage = page;
		this._loadData();

		// Announce page change for screen readers
		this._announcePageChange();
	};

	// =========================================================================
	// Sorting
	// =========================================================================

	/**
	 * Handle header click for sorting
	 */
	TableInstance.prototype._handleSort = function(e) {
		if (!this.config.ordering) return;

		var th = e.target.closest('th.funky-table-sortable');
		if (!th) return;

		var columnIndex = parseInt(th.getAttribute('data-column-index'), 10);
		var column = this.columns[columnIndex];

		if (!column || !column.orderable) return;

		// Determine new direction
		var currentSort = this._getColumnSort(columnIndex);
		var newDir = this._getNextSortDirection(currentSort);

		// Multi-sort with Shift key, otherwise single column
		if (e.shiftKey && this.config.multiSort) {
			this._addSort(columnIndex, newDir);
		} else {
			this._setSort(columnIndex, newDir);
		}

		// Update visual indicators
		this._updateSortIndicators();

		// Reload data
		this.currentPage = 1;
		this._loadData();

		// Callback
		if (typeof this.config.onOrder === 'function') {
			this.config.onOrder(this.sortOrder, this);
		}

		// Emit event
		if (P && P.emit) {
			P.emit('funky:table:order', { table: this, id: this.id, order: this.sortOrder });
		}

		// Announce sort change for screen readers
		var dir = newDir === 'asc' ? 'asc' : newDir === 'desc' ? 'desc' : 'asc';
		this._announceSortChange(column.title, dir);
	};

	/**
	 * Setup header keyboard shortcuts with Funky.Keyboard
	 */
	TableInstance.prototype._setupHeaderKeyboardShortcuts = function() {
		var self = this;

		if (!this.thead || !this.thead.el) return;

		// Ensure thead has ID for scoping
		if (!this.thead.el.id) {
			this.thead.el.id = 'funky-table-thead-' + this.instanceId;
		}

		if (Funky.Keyboard) {
			var headerKeys = [
				{ key: 'enter', description: 'Sort column' },
				{ key: 'space', description: 'Sort column' },
				{ key: 'arrowright', description: 'Next header' },
				{ key: 'arrowdown', description: 'Next header' },
				{ key: 'arrowleft', description: 'Previous header' },
				{ key: 'arrowup', description: 'Previous header' }
			];

			headerKeys.forEach(function(keyDef) {
				self._keyboardUnregisters.push(Funky.Keyboard.register({
					key: keyDef.key,
					scope: '#' + self.thead.el.id,
					handler: function(e) {
						self._handleHeaderKeydown(e);
					},
					description: keyDef.description,
					group: 'Table Header',
					preventDefault: true
				}));
			});
		} else {
			// Fallback for environments without Funky.Keyboard
			this.thead.el.addEventListener('keydown', this._onHeaderKeyDown);
			this._cleanups.push(function() {
				if (self.thead && self.thead.el) {
					self.thead.el.removeEventListener('keydown', self._onHeaderKeyDown);
				}
			});
		}
	};

	/**
	 * Setup body keyboard shortcuts with Funky.Keyboard
	 */
	TableInstance.prototype._setupBodyKeyboardShortcuts = function() {
		var self = this;

		if (!this.tbody || !this.tbody.el) return;

		// Ensure tbody has ID for scoping
		if (!this.tbody.el.id) {
			this.tbody.el.id = 'funky-table-tbody-' + this.instanceId;
		}

		if (Funky.Keyboard) {
			var bodyKeys = [
				{ key: 'space', description: 'Toggle row selection' },
				{ key: 'arrowdown', description: 'Focus next row' },
				{ key: 'arrowup', description: 'Focus previous row' }
			];

			bodyKeys.forEach(function(keyDef) {
				self._keyboardUnregisters.push(Funky.Keyboard.register({
					key: keyDef.key,
					scope: '#' + self.tbody.el.id,
					handler: function(e) {
						self._handleKeyDown(e);
					},
					description: keyDef.description,
					group: 'Table Body',
					preventDefault: true
				}));
			});

			// Ctrl+A for select all (multi-select only)
			if (this.config.selectable === 'multi') {
				this._keyboardUnregisters.push(Funky.Keyboard.register({
					key: 'a',
					mod: true,
					scope: '#' + this.tbody.el.id,
					handler: function(e) {
						self._handleKeyDown(e);
					},
					description: 'Select all rows',
					group: 'Table Body',
					preventDefault: true
				}));
			}
		} else {
			// Fallback for environments without Funky.Keyboard
			this.tbody.el.addEventListener('keydown', this._onKeyDown);
			this._cleanups.push(function() {
				if (self.tbody && self.tbody.el) {
					self.tbody.el.removeEventListener('keydown', self._onKeyDown);
				}
			});
		}
	};

	/**
	 * Handle keyboard navigation on headers
	 */
	TableInstance.prototype._handleHeaderKeydown = function(e) {
		if (!this.config.ordering) return;

		var th = e.target.closest('th.funky-table-sortable');
		if (!th) return;

		// Enter or Space to sort
		if (e.key === 'Enter' || e.key === ' ') {
			e.preventDefault();
			this._handleSort(e);
			return;
		}

		// Arrow key navigation between sortable headers
		var headers = this.thead.el.querySelectorAll('th.funky-table-sortable');
		var headerArray = Array.prototype.slice.call(headers);
		var currentIndex = headerArray.indexOf(th);

		if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
			e.preventDefault();
			var next = headers[currentIndex + 1];
			if (next) next.focus();
		} else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
			e.preventDefault();
			var prev = headers[currentIndex - 1];
			if (prev) prev.focus();
		}
	};

	/**
	 * Get current sort direction for column
	 */
	TableInstance.prototype._getColumnSort = function(columnIndex) {
		for (var i = 0; i < this.sortOrder.length; i++) {
			if (this.sortOrder[i].column === columnIndex) {
				return this.sortOrder[i].dir;
			}
		}
		return null;
	};

	/**
	 * Get next sort direction in cycle: null -> asc -> desc -> null
	 */
	TableInstance.prototype._getNextSortDirection = function(current) {
		if (current === null || current === undefined) {
			return 'asc';
		} else if (current === 'asc') {
			return 'desc';
		} else {
			return null; // Remove sort
		}
	};

	/**
	 * Set single column sort (clears others)
	 */
	TableInstance.prototype._setSort = function(columnIndex, direction) {
		if (direction === null) {
			this.sortOrder = [];
		} else {
			this.sortOrder = [{
				column: columnIndex,
				dir: direction
			}];
		}
	};

	/**
	 * Add/update sort for column (multi-column)
	 */
	TableInstance.prototype._addSort = function(columnIndex, direction) {
		var existingIndex = -1;
		for (var i = 0; i < this.sortOrder.length; i++) {
			if (this.sortOrder[i].column === columnIndex) {
				existingIndex = i;
				break;
			}
		}

		if (direction === null) {
			if (existingIndex !== -1) {
				this.sortOrder.splice(existingIndex, 1);
			}
		} else if (existingIndex !== -1) {
			this.sortOrder[existingIndex].dir = direction;
		} else {
			this.sortOrder.push({
				column: columnIndex,
				dir: direction
			});
		}
	};

	/**
	 * Update visual sort indicators on headers
	 */
	TableInstance.prototype._updateSortIndicators = function() {
		if (!this.thead || !this.thead.el) return;

		var self = this;
		var headers = this.thead.el.querySelectorAll('th.funky-table-sortable');

		for (var i = 0; i < headers.length; i++) {
			var th = headers[i];
			var columnIndex = parseInt(th.getAttribute('data-column-index'), 10);
			var sortDir = self._getColumnSort(columnIndex);
			var sortIndex = self._getSortIndex(columnIndex);

			// Remove existing sort classes
			th.classList.remove('funky-table-sort-asc', 'funky-table-sort-desc');

			// Remove sort order badge
			var orderBadge = th.querySelector('.funky-table-sort-order');
			if (orderBadge) orderBadge.parentNode.removeChild(orderBadge);

			if (sortDir) {
				// Add direction class
				th.classList.add('funky-table-sort-' + sortDir);

				// Set aria-sort
				th.setAttribute('aria-sort', sortDir === 'asc' ? 'ascending' : 'descending');

				// Show order number for multi-sort
				if (self.sortOrder.length > 1 && sortIndex !== -1) {
					var badge = document.createElement('span');
					badge.className = 'funky-table-sort-order';
					badge.textContent = sortIndex + 1;
					th.appendChild(badge);
				}
			} else {
				th.setAttribute('aria-sort', 'none');
			}
		}
	};

	/**
	 * Get position of column in sort order (for multi-sort numbering)
	 */
	TableInstance.prototype._getSortIndex = function(columnIndex) {
		for (var i = 0; i < this.sortOrder.length; i++) {
			if (this.sortOrder[i].column === columnIndex) {
				return i;
			}
		}
		return -1;
	};

	// =========================================================================
	// Placeholder Methods (implemented in later phases)
	// =========================================================================

	/**
	 * Handle window resize (Phase 17 - Responsive)
	 */
	TableInstance.prototype._handleResize = function() {
		// Implemented in Phase 17
	};

	/**
	 * Handle row click for selection
	 */
	TableInstance.prototype._handleClick = function(e) {
		if (this.config.selectable === 'none') return;

		// Check if clicking on checkbox
		var checkbox = e.target.closest('.funky-table-select-row');
		if (checkbox) {
			this._handleCheckboxClick(e, checkbox);
			return;
		}

		// Check if clicking on control button (don't select)
		if (e.target.closest('.funky-table-control-btn')) return;

		// Check if clicking on action button (don't select)
		if (e.target.closest('.actions-column') || e.target.closest('[data-action]')) return;

		// Row click selection
		var row = e.target.closest('.funky-table-row');
		if (row) {
			this._handleRowClick(e, row);
		}
	};

	/**
	 * Handle checkbox click
	 */
	TableInstance.prototype._handleCheckboxClick = function(e, checkbox) {
		var row = checkbox.closest('.funky-table-row');
		if (!row) return;

		var rowId = row.getAttribute('data-id');
		var rowIndex = parseInt(row.getAttribute('data-row-index'), 10);

		if (checkbox.checked) {
			this._selectRow(rowId, rowIndex, e.shiftKey);
		} else {
			this._deselectRow(rowId);
		}

		e.stopPropagation();
	};

	/**
	 * Handle row click (non-checkbox)
	 */
	TableInstance.prototype._handleRowClick = function(e, row) {
		var rowId = row.getAttribute('data-id');
		var rowIndex = parseInt(row.getAttribute('data-row-index'), 10);

		if (this.config.selectable === 'single') {
			// Single select - toggle or replace
			if (this.selectedIds.has(String(rowId))) {
				this._deselectRow(rowId);
			} else {
				this._clearSelection();
				this._selectRow(rowId, rowIndex, false);
			}
		} else if (this.config.selectable === 'multi') {
			// Multi select with modifiers
			if (e.ctrlKey || e.metaKey) {
				// Ctrl+click - toggle
				if (this.selectedIds.has(String(rowId))) {
					this._deselectRow(rowId);
				} else {
					this._selectRow(rowId, rowIndex, false);
				}
			} else if (e.shiftKey) {
				// Shift+click - range select
				this._selectRow(rowId, rowIndex, true);
			} else {
				// Click - replace selection
				this._clearSelection();
				this._selectRow(rowId, rowIndex, false);
			}
		}
	};

	/**
	 * Handle select-all checkbox
	 */
	TableInstance.prototype._handleSelectAll = function(checked) {
		var self = this;

		if (checked) {
			// Select all visible rows
			this.displayData.forEach(function(row) {
				if (row.id !== undefined) {
					self.selectedIds.add(String(row.id));
				}
			});
		} else {
			// Deselect all
			this.selectedIds.clear();
		}

		this._updateSelectionUI();
		this._emitSelectionChange();
	};

	/**
	 * Select a row
	 */
	TableInstance.prototype._selectRow = function(rowId, rowIndex, shiftSelect) {
		var self = this;

		if (shiftSelect && this.lastSelectedIndex !== -1 && this.config.selectable === 'multi') {
			// Range selection
			var start = Math.min(this.lastSelectedIndex, rowIndex);
			var end = Math.max(this.lastSelectedIndex, rowIndex);

			for (var i = start; i <= end; i++) {
				var row = this.displayData[i];
				if (row && row.id !== undefined) {
					this.selectedIds.add(String(row.id));
				}
			}
		} else {
			this.selectedIds.add(String(rowId));
		}

		this.lastSelectedIndex = rowIndex;
		this._updateSelectionUI();
		this._emitSelectionChange();
	};

	/**
	 * Deselect a row
	 */
	TableInstance.prototype._deselectRow = function(rowId) {
		this.selectedIds.delete(String(rowId));
		this._updateSelectionUI();
		this._emitSelectionChange();
	};

	/**
	 * Clear all selection
	 */
	TableInstance.prototype._clearSelection = function() {
		this.selectedIds.clear();
		this.lastSelectedIndex = -1;
		this._updateSelectionUI();
		this._emitSelectionChange();
	};

	/**
	 * Update selection UI (checkboxes and row classes)
	 */
	TableInstance.prototype._updateSelectionUI = function() {
		var self = this;
		if (!this.tbody || !this.tbody.el) return;

		// Update rows
		var rows = this.tbody.el.querySelectorAll('.funky-table-row');
		for (var i = 0; i < rows.length; i++) {
			var row = rows[i];
			var rowId = row.getAttribute('data-id');
			var selected = self.selectedIds.has(String(rowId));

			if (selected) {
				row.classList.add('funky-table-row-selected');
				row.setAttribute('aria-selected', 'true');
			} else {
				row.classList.remove('funky-table-row-selected');
				row.setAttribute('aria-selected', 'false');
			}

			// Update checkbox if present
			var checkbox = row.querySelector('.funky-table-select-row');
			if (checkbox) {
				checkbox.checked = selected;
			}
		}

		// Update select-all checkbox
		if (this.thead && this.thead.el) {
			var selectAll = this.thead.el.querySelector('.funky-table-select-all');
			if (selectAll) {
				var allSelected = this.displayData.length > 0 &&
					this.displayData.every(function(row) {
						return self.selectedIds.has(String(row.id));
					});
				var someSelected = this.selectedIds.size > 0;

				selectAll.checked = allSelected;
				selectAll.indeterminate = someSelected && !allSelected;
			}
		}
	};

	/**
	 * Generic event emitter
	 * Fires both custom DOM events and Funky.Events
	 * @param {string} eventName - Event name (without 'funky:table:' prefix)
	 * @param {Object} detail - Event data
	 */
	TableInstance.prototype._emit = function(eventName, detail) {
		var self = this;
		var fullEventName = 'funky:table:' + eventName;

		// Fire Funky.PubSub if available
		if (P && P.emit) {
			P.emit(fullEventName, Object.assign({ table: this, id: this.id }, detail || {}));
		}

		// Fire DOM custom event (uses dot notation: funky.table.eventName)
		if (this.wrapper && this.wrapper.el) {
			var event = new CustomEvent('funky.table.' + eventName, {
				bubbles: true,
				detail: Object.assign({ table: this }, detail || {})
			});
			this.wrapper.el.dispatchEvent(event);
		}

		// Fire callback if configured (on + PascalCase event name)
		var callbackName = 'on' + eventName.charAt(0).toUpperCase() + eventName.slice(1);
		if (typeof this.config[callbackName] === 'function') {
			this.config[callbackName](detail, this);
		}
	};

	/**
	 * Emit selection change event
	 */
	TableInstance.prototype._emitSelectionChange = function() {
		var self = this;

		// Get selected rows data
		var selectedData = this.data.filter(function(row) {
			return self.selectedIds.has(String(row.id));
		});

		var selectedIds = Array.from(this.selectedIds);

		// Fire callback
		if (typeof this.config.onSelect === 'function') {
			this.config.onSelect(selectedData, selectedIds);
		}

		// Fire DOM event
		if (this.wrapper && this.wrapper.el) {
			var event = new CustomEvent('funky.table.select', {
				detail: {
					selected: selectedData,
					ids: selectedIds
				}
			});
			this.wrapper.el.dispatchEvent(event);
		}

		// Announce selection change for screen readers
		this._announceSelectionChange();
	};

	/**
	 * Add responsive control column for expand/collapse
	 * This column shows a +/- button to reveal hidden columns on small screens
	 */
	TableInstance.prototype._addResponsiveControlColumn = function() {
		// Only add if responsive is enabled
		if (!this.config.responsive) return;

		var self = this;

		var controlColumn = {
			index: 0,
			data: null,
			title: '',
			name: '_control',
			className: 'funky-table-control-cell',
			orderable: false,
			searchable: false,
			visible: true,
			width: '30px',
			responsivePriority: 0,  // Always visible (lowest = most important)
			render: function(data, type, row, meta) {
				return '<button class="funky-table-control-btn" aria-label="Show details" aria-expanded="false">' +
					'<i class="fas fa-plus"></i></button>';
			}
		};

		// Insert at beginning
		this.columns.unshift(controlColumn);

		// Reindex all columns
		for (var i = 0; i < this.columns.length; i++) {
			this.columns[i].index = i;
		}

		if (this.config.debug) {
			console.log('[Funky.Table] Added responsive control column');
		}
	};

	/**
	 * Add checkbox column for multi-selection
	 */
	TableInstance.prototype._addCheckboxColumn = function() {
		if (this.config.debug) {
			console.log('[Funky.Table] _addCheckboxColumn check, selectable:', this.config.selectable);
		}
		if (this.config.selectable !== 'multi') return;

		var self = this;

		// Insert checkbox column at beginning (after control column if present)
		var insertIndex = this.config.responsive ? 1 : 0;

		var checkboxColumn = {
			index: insertIndex,
			data: null,
			title: '',
			name: '_select',
			className: 'funky-table-select-cell',
			orderable: false,
			searchable: false,
			visible: true,
			width: '40px',
			responsivePriority: 1,
			headerRender: function() {
				return '<input type="checkbox" class="funky-table-select-all" aria-label="Select all rows">';
			},
			render: function(data, type, row, meta) {
				var checked = self.selectedIds.has(String(row.id)) ? 'checked' : '';
				return '<input type="checkbox" class="funky-table-select-row" aria-label="Select row" ' + checked + '>';
			}
		};

		this.columns.splice(insertIndex, 0, checkboxColumn);

		// Reindex all columns
		for (var i = 0; i < this.columns.length; i++) {
			this.columns[i].index = i;
		}
	};

	/**
	 * Handle keyboard navigation and selection
	 */
	TableInstance.prototype._handleKeyDown = function(e) {
		if (this.config.selectable === 'none') return;
		if (!this.tbody || !this.tbody.el) return;

		var focusedRow = this.tbody.el.querySelector('.funky-table-row:focus, .funky-table-row.funky-table-row-focused');
		if (!focusedRow) return;

		var rowIndex = parseInt(focusedRow.getAttribute('data-row-index'), 10);
		var rowId = focusedRow.getAttribute('data-id');

		// Space - toggle selection
		if (e.key === ' ' || e.key === 'Space') {
			e.preventDefault();
			this.toggleSelect(rowId);
			return;
		}

		// Ctrl+A - select all
		if ((e.ctrlKey || e.metaKey) && e.key === 'a') {
			e.preventDefault();
			this.selectAll();
			return;
		}

		// Arrow navigation
		if (e.key === 'ArrowDown') {
			e.preventDefault();
			this._focusRow(rowIndex + 1, e.shiftKey);
		} else if (e.key === 'ArrowUp') {
			e.preventDefault();
			this._focusRow(rowIndex - 1, e.shiftKey);
		}
	};

	/**
	 * Focus a row by index
	 */
	TableInstance.prototype._focusRow = function(index, extendSelection) {
		if (index < 0 || index >= this.displayData.length) return;
		if (!this.tbody || !this.tbody.el) return;

		var rows = this.tbody.el.querySelectorAll('.funky-table-row');
		var targetRow = rows[index];
		if (!targetRow) return;

		// Remove focus from current
		var current = this.tbody.el.querySelector('.funky-table-row-focused');
		if (current) {
			current.classList.remove('funky-table-row-focused');
			current.setAttribute('tabindex', '-1');
		}

		// Add focus to target
		targetRow.classList.add('funky-table-row-focused');
		targetRow.setAttribute('tabindex', '0');
		targetRow.focus();

		// Extend selection if shift held
		if (extendSelection && this.config.selectable === 'multi') {
			var rowId = targetRow.getAttribute('data-id');
			this._selectRow(rowId, index, true);
		}
	};

	// =========================================================================
	// Context Menu
	// =========================================================================

	/**
	 * Initialize Context Menu integration
	 */
	TableInstance.prototype._initContextMenu = function() {
		var config = this.config.contextMenu;
		if (!config || !config.enabled) return;
		if (!Funky.ContextMenu) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Funky.ContextMenu required for context menus');
			}
			return;
		}

		// Store config
		this._contextMenuConfig = config;
		this._activeContextMenu = null;

		// Bind row context menu
		this._bindRowContextMenu();

		// Bind header context menu
		if (config.headerMenu && config.headerMenu.enabled) {
			this._bindHeaderContextMenu();
		}
	};

	/**
	 * Bind context menu to table rows
	 */
	TableInstance.prototype._bindRowContextMenu = function() {
		var self = this;
		var config = this._contextMenuConfig;

		if (!this.tbody || !this.tbody.el) return;

		var contextMenuHandler = function(e) {
			var row = e.target.closest('.funky-table-row');
			if (!row) return;

			var rowId = row.getAttribute('data-id');
			if (!rowId) return;

			e.preventDefault();

			var rowData = self._getRowDataById(rowId);
			if (!rowData) return;

			// Select row if not already selected (unless disabled)
			if (config.selectOnContextMenu !== false) {
				if (!self.selectedIds.has(String(rowId))) {
					if (!e.ctrlKey && !e.metaKey) {
						self._clearSelection();
					}
					var rowIndex = parseInt(row.getAttribute('data-row-index'), 10);
					self._selectRow(rowId, rowIndex, false);
				}
			}

			// Mark row as context menu active
			self._setContextMenuActiveRow(row);

			var selectedRows = self.getSelectedData();

			// Build menu items
			var items = self._buildContextMenuItems(rowData, selectedRows);

			// Open context menu
			self._openContextMenu(e.clientX, e.clientY, items, rowData, selectedRows);
		};

		this.tbody.el.addEventListener('contextmenu', contextMenuHandler);
		this._cleanups.push(function() {
			if (self.tbody && self.tbody.el) {
				self.tbody.el.removeEventListener('contextmenu', contextMenuHandler);
			}
		});

		// Keyboard support: Shift+F10 for context menu
		this._bindContextMenuKeyboard();
	};

	/**
	 * Bind keyboard shortcut for context menu using Funky.Keyboard
	 */
	TableInstance.prototype._bindContextMenuKeyboard = function() {
		var self = this;
		var tableScope = 'funky-table-' + this.instanceId;

		// Handler for opening context menu via keyboard
		var openContextMenuViaKeyboard = function() {
			// Find the focused row - prioritize keyboard focus over selection
			var focusedRow = self.tbody.el.querySelector('.funky-table-row-focused');
			if (!focusedRow) {
				// Try native :focus
				focusedRow = self.tbody.el.querySelector('.funky-table-row:focus');
			}
			if (!focusedRow) {
				// Fallback to row at _focusedCell.row
				var rows = self.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)');
				if (self._focusedCell && self._focusedCell.row >= 0 && self._focusedCell.row < rows.length) {
					focusedRow = rows[self._focusedCell.row];
				}
			}
			if (!focusedRow) {
				// Last resort: first row
				focusedRow = self.tbody.el.querySelector('.funky-table-row[data-id]');
			}
			if (focusedRow) {
				var rowId = focusedRow.getAttribute('data-id');
				var rowData = self._getRowDataById(rowId);
				if (rowData) {
					self._setContextMenuActiveRow(focusedRow);
					var selectedRows = self.getSelectedData();
					var items = self._buildContextMenuItems(rowData, selectedRows);
					// Position near the row
					var rect = focusedRow.getBoundingClientRect();
					self._openContextMenu(rect.left + 50, rect.top + rect.height / 2, items, rowData, selectedRows);
				}
			}
		};

		// Use Funky.Keyboard if available
		if (typeof Funky !== 'undefined' && Funky.Keyboard) {
			// Register Shift+F10 for context menu (global scope, but checks table focus)
			var unregisterShiftF10 = Funky.Keyboard.register({
				key: 'f10',
				shift: true,
				handler: function() {
					// Only trigger if focus is within this table
					var activeElement = document.activeElement;
					if (self.wrapper && self.wrapper.el && self.wrapper.el.contains(activeElement)) {
						openContextMenuViaKeyboard();
						return true;  // Handled
					}
					return false;  // Let other handlers try
				},
				scope: 'global',
				description: 'Open table context menu',
				group: 'Table',
				allowInInput: false
			});

			this._cleanups.push(unregisterShiftF10);

			// Register table as a focus region for F6 navigation
			if (Funky.FocusManager && Funky.FocusManager.registerRegion) {
				Funky.FocusManager.registerRegion({
					name: 'table-' + this.instanceId,
					element: this.wrapper.el,
					order: 50  // Middle priority
				});
			}
		} else {
			// Fallback: native keydown listener
			var keyboardContextMenuHandler = function(e) {
				// Shift+F10 or ContextMenu key (keyCode 93)
				if ((e.shiftKey && e.key === 'F10') || e.key === 'ContextMenu' || e.keyCode === 93) {
					e.preventDefault();
					openContextMenuViaKeyboard();
				}
			};

			this.tbody.el.addEventListener('keydown', keyboardContextMenuHandler);
			this._cleanups.push(function() {
				if (self.tbody && self.tbody.el) {
					self.tbody.el.removeEventListener('keydown', keyboardContextMenuHandler);
				}
			});
		}
	};

	/**
	 * Build context menu items
	 */
	TableInstance.prototype._buildContextMenuItems = function(row, selectedRows) {
		var config = this._contextMenuConfig;
		var items = [];
		var self = this;
		var itemIndex = 0;

		// Static items
		if (config.items && config.items.length) {
			for (var i = 0; i < config.items.length; i++) {
				items.push(self._processMenuItem(config.items[i], row, selectedRows, itemIndex++));
			}
		}

		// ActionRegistry items
		if (config.actionRegistry && Funky.ActionRegistry) {
			var registryItems = Funky.ActionRegistry.getActions(config.actionRegistry, {
				row: row,
				selectedRows: selectedRows,
				table: self
			});

			if (registryItems && registryItems.length) {
				if (items.length) {
					items.push({ type: 'divider', divider: true });
					itemIndex++;
				}
				for (var j = 0; j < registryItems.length; j++) {
					items.push(self._processMenuItem(registryItems[j], row, selectedRows, itemIndex++));
				}
			}
		}

		// Dynamic items
		if (typeof config.dynamicItems === 'function') {
			var dynamicItems = config.dynamicItems(row, selectedRows, self);
			if (dynamicItems && dynamicItems.length) {
				for (var k = 0; k < dynamicItems.length; k++) {
					items.push(self._processMenuItem(dynamicItems[k], row, selectedRows, itemIndex++));
				}
			}
		}

		return items;
	};

	/**
	 * Process menu item - resolve enabled state, etc.
	 */
	TableInstance.prototype._processMenuItem = function(item, row, selectedRows, index) {
		var self = this;

		if (item.type === 'divider') {
			return { type: 'divider', divider: true };
		}

		var processed = {
			id: item.id || ('table-menu-item-' + (index || 0)),
			label: item.label,
			icon: item.icon,
			className: item.className,
			disabled: false
		};

		// Check enabled state
		if (typeof item.enabled === 'function') {
			processed.disabled = !item.enabled(row, selectedRows, self);
		} else if (item.enabled === false) {
			processed.disabled = true;
		}

		// Wrap action with row context
		if (typeof item.action === 'function') {
			processed.action = function() {
				item.action(row, self, selectedRows);
			};
		}

		// Process submenu
		if (item.submenu && item.submenu.length) {
			processed.submenu = [];
			for (var i = 0; i < item.submenu.length; i++) {
				processed.submenu.push(self._processMenuItem(item.submenu[i], row, selectedRows, i));
			}
		}

		return processed;
	};

	/**
	 * Open context menu at position
	 */
	TableInstance.prototype._openContextMenu = function(x, y, items, row, selectedRows) {
		var self = this;
		var config = this._contextMenuConfig;

		// Close existing menu
		if (this._activeContextMenu) {
			Funky.ContextMenu.hide();
		}

		// Callback
		if (typeof config.onOpen === 'function') {
			config.onOpen(row, items);
		}

		// Show menu - Funky.ContextMenu.show(x, y, options)
		Funky.ContextMenu.show(x, y, {
			items: items,
			className: 'funky-table-context-menu',
			onSelect: function(itemId, targetElement, event) {
				// Find the item by id and call its action
				var selectedItem = null;
				for (var i = 0; i < items.length; i++) {
					// Skip dividers
					if (items[i].divider || items[i].type === 'divider') continue;
					
					// Match by id
					if (items[i].id === itemId) {
						selectedItem = items[i];
						break;
					}
				}
				
				// Call the item's action if it has one
				if (selectedItem && typeof selectedItem.action === 'function') {
					selectedItem.action();
				}
				
				// Also call config onSelect if defined
				if (typeof config.onSelect === 'function') {
					config.onSelect(itemId, row, selectedRows);
				}
			},
			onHide: function() {
				self._clearContextMenuActiveRow();
				self._activeContextMenu = null;
				if (typeof config.onClose === 'function') {
					config.onClose();
				}
			}
		});
		
		this._activeContextMenu = true;
	};

	/**
	 * Set active row styling for context menu
	 */
	TableInstance.prototype._setContextMenuActiveRow = function(row) {
		this._clearContextMenuActiveRow();
		if (row) {
			row.classList.add('funky-context-menu-active');
		}
	};

	/**
	 * Clear active row styling
	 */
	TableInstance.prototype._clearContextMenuActiveRow = function() {
		if (!this.tbody || !this.tbody.el) return;
		var activeRow = this.tbody.el.querySelector('.funky-context-menu-active');
		if (activeRow) {
			activeRow.classList.remove('funky-context-menu-active');
		}
	};

	/**
	 * Bind context menu to header cells
	 */
	TableInstance.prototype._bindHeaderContextMenu = function() {
		var self = this;
		var config = this._contextMenuConfig.headerMenu;

		if (!this.thead || !this.thead.el) return;

		var headerContextMenuHandler = function(e) {
			var th = e.target.closest('th');
			if (!th) return;

			e.preventDefault();

			var columnIndex = parseInt(th.getAttribute('data-column-index'), 10);
			if (isNaN(columnIndex)) return;

			var column = self.columns[columnIndex];
			if (!column) return;

			var items = self._buildHeaderMenuItems(column, config.items || []);

			Funky.ContextMenu.show({
				x: e.clientX,
				y: e.clientY,
				items: items,
				className: 'funky-table-context-menu',
				onSelect: function(itemId) {
					self._handleHeaderMenuAction(itemId, column);
				}
			});
		};

		this.thead.el.addEventListener('contextmenu', headerContextMenuHandler);
		this._cleanups.push(function() {
			if (self.thead && self.thead.el) {
				self.thead.el.removeEventListener('contextmenu', headerContextMenuHandler);
			}
		});
	};

	/**
	 * Build header context menu items
	 */
	TableInstance.prototype._buildHeaderMenuItems = function(column, baseItems) {
		var items = [];

		for (var i = 0; i < baseItems.length; i++) {
			var item = baseItems[i];
			if (item.type === 'divider') {
				items.push(item);
				continue;
			}

			var processed = {
				id: item.id,
				label: item.label,
				icon: item.icon,
				disabled: false
			};

			// Disable sort options if column not sortable
			if ((item.id === 'sort-asc' || item.id === 'sort-desc') && column.orderable === false) {
				processed.disabled = true;
			}

			items.push(processed);
		}

		return items;
	};

	/**
	 * Handle header menu action
	 */
	TableInstance.prototype._handleHeaderMenuAction = function(itemId, column) {
		switch (itemId) {
			case 'sort-asc':
				this.order([[column.index, 'asc']]);
				break;
			case 'sort-desc':
				this.order([[column.index, 'desc']]);
				break;
			case 'hide-column':
				// Column visibility - Phase 12
				if (this.config.debug) {
					console.log('[Funky.Table] Hide column:', column.data);
				}
				break;
			case 'column-settings':
				// Column settings - Phase 12
				if (this.config.debug) {
					console.log('[Funky.Table] Column settings:', column.data);
				}
				break;
		}
	};

	/**
	 * Get row data by ID
	 */
	TableInstance.prototype._getRowDataById = function(id) {
		for (var i = 0; i < this.data.length; i++) {
			if (String(this.data[i].id) === String(id)) {
				return this.data[i];
			}
		}
		return null;
	};

	// =========================================================================
	// Filters
	// =========================================================================

	/**
	 * Initialize all filters
	 */
	TableInstance.prototype._initFilters = function() {
		if (!this.config.filters) return;

		var filters = this.config.filters;

		// Date range filter
		if (filters.dateRange && filters.dateRange.enabled) {
			this._initDateRangeFilter(filters.dateRange);
		}

		// Client filter
		if (filters.client && filters.client.enabled) {
			this._initClientFilter(filters.client);
		}

		// Custom filters
		if (filters.custom && filters.custom.length > 0) {
			var self = this;
			for (var i = 0; i < filters.custom.length; i++) {
				self._initCustomFilter(filters.custom[i]);
			}
		}
	};

	/**
	 * Initialize date range filter
	 */
	TableInstance.prototype._initDateRangeFilter = function(config) {
		var self = this;

		var pickerEl = typeof config.selector === 'string'
			? document.querySelector(config.selector)
			: config.selector;

		var columnEl = config.columnSelector
			? document.querySelector(config.columnSelector)
			: null;

		if (!pickerEl) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Date range picker element not found:', config.selector);
			}
			return;
		}

		// Initialize column selector with ComboBox
		if (columnEl && Funky.ComboBox && config.columns && config.columns.length) {
			// Add options
			for (var i = 0; i < config.columns.length; i++) {
				var col = config.columns[i];
				var option = document.createElement('option');
				option.value = col.value;
				option.textContent = col.label;
				if (col.selected) option.selected = true;
				columnEl.appendChild(option);
			}

			Funky.ComboBox.init(columnEl, {
				searchable: false,
				clearable: false,
				width: '150px'
			});

			// Column change reloads table
			columnEl.addEventListener('change', function() {
				self._applyDateRangeFilter();
			});
		}

		// Calculate default range
		var defaultRange = this._getDefaultDateRange(config.defaultRange || 'last7days');

		// Initialize date picker
		if (Funky.DatePicker) {
			this._dateRangePicker = Funky.DatePicker.create(pickerEl, {
				mode: 'range',
				timePicker: true,
				timePicker24Hour: true,
				format: 'YYYY-MM-DD HH:mm',
				ranges: true,
				opens: 'left',
				autoApply: false
			});

			// Set initial range
			if (this._dateRangePicker.setRange) {
				this._dateRangePicker.setRange(defaultRange.start, defaultRange.end);
			}

			// Store config
			this._dateRangeConfig = config;

			// Listen for changes
			if (P && P.on) {
				P.on(pickerEl, 'funky.datepicker.change', function(e) {
					self._applyDateRangeFilter();
				});
			} else {
				pickerEl.addEventListener('change', function() {
					self._applyDateRangeFilter();
				});
			}
		}

		// Store config for initial apply
		this._dateRangeConfig = config;

		// Apply initial filter
		this._applyDateRangeFilter();
	};

	/**
	 * Get default date range by name
	 */
	TableInstance.prototype._getDefaultDateRange = function(rangeName) {
		var now = new Date();
		var start = new Date();
		var end = new Date();

		switch (rangeName) {
			case 'today':
				start.setHours(0, 0, 0, 0);
				end.setHours(23, 59, 59, 999);
				break;
			case 'yesterday':
				start.setDate(start.getDate() - 1);
				start.setHours(0, 0, 0, 0);
				end.setDate(end.getDate() - 1);
				end.setHours(23, 59, 59, 999);
				break;
			case 'last7days':
				start.setDate(start.getDate() - 6);
				start.setHours(0, 0, 0, 0);
				end.setHours(23, 59, 59, 999);
				break;
			case 'last30days':
				start.setDate(start.getDate() - 29);
				start.setHours(0, 0, 0, 0);
				end.setHours(23, 59, 59, 999);
				break;
			case 'thisMonth':
				start.setDate(1);
				start.setHours(0, 0, 0, 0);
				break;
			case 'allTime':
			default:
				start.setFullYear(start.getFullYear() - 10);
				break;
		}

		return { start: start, end: end };
	};

	/**
	 * Apply date range filter to extraAjaxData
	 */
	TableInstance.prototype._applyDateRangeFilter = function() {
		if (!this._dateRangeConfig) return;

		var config = this._dateRangeConfig;
		var range = null;

		// Get range from picker if available
		if (this._dateRangePicker && this._dateRangePicker.getRange) {
			range = this._dateRangePicker.getRange();
		}

		// Get column from selector
		var columnEl = config.columnSelector
			? document.querySelector(config.columnSelector)
			: null;
		var dateColumn = columnEl ? columnEl.value : (config.columns && config.columns[0] ? config.columns[0].value : 'created_at');

		// Ensure extraAjaxData exists
		if (!this.config.extraAjaxData) {
			this.config.extraAjaxData = {};
		}

		// Update extraAjaxData
		this.config.extraAjaxData.date_column = dateColumn;

		if (range && range.start && range.end) {
			this.config.extraAjaxData.date_from = this._formatDateTime(range.start);
			this.config.extraAjaxData.date_to = this._formatDateTime(range.end);
		}

		// Reload table (skip if not yet initialized)
		if (this.data && this.data.length >= 0) {
			this.currentPage = 1;
			this._loadData();
		}
	};

	/**
	 * Format date for server (YYYY-MM-DD HH:mm:ss)
	 */
	TableInstance.prototype._formatDateTime = function(date) {
		if (!date) return '';
		var pad = function(n) { return n < 10 ? '0' + n : n; };

		return date.getFullYear() + '-' +
			pad(date.getMonth() + 1) + '-' +
			pad(date.getDate()) + ' ' +
			pad(date.getHours()) + ':' +
			pad(date.getMinutes()) + ':' +
			pad(date.getSeconds());
	};

	/**
	 * Initialize client (entity) filter
	 */
	TableInstance.prototype._initClientFilter = function(config) {
		var self = this;

		var selectEl = typeof config.selector === 'string'
			? document.querySelector(config.selector)
			: config.selector;

		if (!selectEl) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Client filter element not found:', config.selector);
			}
			return;
		}

		if (!Funky.ComboBox) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Funky.ComboBox required for client filter');
			}
			return;
		}

		// ComboBox configuration
		var comboConfig = {
			mode: config.mode || 'multi',
			placeholder: config.placeholder || 'Filter by ' + (config.label || 'Client'),
			clearable: true,
			scrollTags: true
		};

		// Remote data configuration
		if (config.remote) {
			comboConfig.remote = {
				url: config.remote.url,
				searchParam: config.remote.searchParam || 'search',
				pageParam: config.remote.pageParam || 'page',
				delay: config.remote.delay || 250,
				transform: config.remote.transform,
				processResponse: config.remote.processResponse || function(data) {
					var key = null;
					for (var k in data) {
						if (data.hasOwnProperty(k) && Array.isArray(data[k])) {
							key = k;
							break;
						}
					}
					return {
						items: key ? data[key] : [],
						hasMore: data.page * data.limit < data.total
					};
				}
			};
		}

		Funky.ComboBox.init(selectEl, comboConfig);

		// Store config
		this._clientFilterConfig = config;
		this._clientFilterEl = selectEl;

		// Listen for changes
		selectEl.addEventListener('change', function() {
			self._applyClientFilter();
		});
	};

	/**
	 * Apply client filter to extraAjaxData
	 */
	TableInstance.prototype._applyClientFilter = function() {
		if (!this._clientFilterConfig || !this._clientFilterEl) return;

		var config = this._clientFilterConfig;
		var paramName = config.paramName || 'client_id';

		var instance = Funky.ComboBox.getInstance(this._clientFilterEl);
		var selected = instance ? instance.getValue() : [];

		// Ensure extraAjaxData exists
		if (!this.config.extraAjaxData) {
			this.config.extraAjaxData = {};
		}

		// Clear existing param
		delete this.config.extraAjaxData[paramName];

		// Set new value
		if (selected && selected.length > 0) {
			var ids = [];
			for (var i = 0; i < selected.length; i++) {
				var item = selected[i];
				var id = typeof item === 'object' ? item.id : item;
				if (id !== null && id !== '' && id !== undefined) {
					ids.push(id);
				}
			}

			if (ids.length > 0) {
				this.config.extraAjaxData[paramName] = ids;
			}
		}

		// Reload table
		this.currentPage = 1;
		this._loadData();
	};

	/**
	 * Initialize custom filter
	 */
	TableInstance.prototype._initCustomFilter = function(config) {
		var self = this;

		var element = typeof config.selector === 'string'
			? document.querySelector(config.selector)
			: config.selector;

		if (!element) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Custom filter element not found:', config.selector);
			}
			return;
		}

		// Initialize ComboBox if it's a select
		if (element.tagName === 'SELECT' && Funky.ComboBox) {
			var comboConfig = {
				mode: config.mode || 'single',
				searchable: config.searchable !== false,
				clearable: config.clearable !== false
			};

			if (config.remote) {
				comboConfig.remote = config.remote;
			}

			Funky.ComboBox.init(element, comboConfig);
		}

		// Listen for changes
		element.addEventListener('change', function() {
			self._applyCustomFilter(element, config);
		});

		// Store for reference
		if (!this._customFilters) {
			this._customFilters = [];
		}
		this._customFilters.push({ element: element, config: config });
	};

	/**
	 * Apply custom filter
	 */
	TableInstance.prototype._applyCustomFilter = function(element, config) {
		var paramName = config.paramName;
		if (!paramName) return;

		var value;

		// Get value based on element type
		if (element.tagName === 'SELECT') {
			var instance = Funky.ComboBox && Funky.ComboBox.getInstance(element);
			if (instance) {
				value = instance.getValue();
			} else {
				value = element.value;
			}
		} else if (element.tagName === 'INPUT') {
			if (element.type === 'checkbox') {
				value = element.checked ? (element.value || true) : null;
			} else {
				value = element.value;
			}
		}

		// Ensure extraAjaxData exists
		if (!this.config.extraAjaxData) {
			this.config.extraAjaxData = {};
		}

		// Clear or set param
		if (value === null || value === '' || (Array.isArray(value) && value.length === 0)) {
			delete this.config.extraAjaxData[paramName];
		} else {
			this.config.extraAjaxData[paramName] = value;
		}

		// Reload
		this.currentPage = 1;
		this._loadData();
	};

	// =========================================================================
	// Advanced Filter Methods (Phase 11)
	// =========================================================================

	/**
	 * Initialize Advanced Filter integration
	 */
	TableInstance.prototype._initAdvancedFilter = function() {
		var config = this.config.advancedFilter;
		if (!config || !config.enabled) return;
		if (!Funky.AdvancedFilter) {
			console.warn('[Funky.Table] Funky.AdvancedFilter required for advanced filtering');
			return;
		}

		var self = this;

		// Determine button element
		var buttonEl = config.buttonSelector
			? document.querySelector(config.buttonSelector)
			: null;

		// Create button if not provided
		if (!buttonEl && config.autoCreateButton !== false) {
			buttonEl = this._createAdvancedFilterButton();
		}

		if (!buttonEl) {
			console.warn('[Funky.Table] No button element for AdvancedFilter');
			return;
		}

		// Store button reference
		this._advancedFilterButton = buttonEl;

		// Create AdvancedFilter instance
		this._advancedFilter = Funky.AdvancedFilter.init(buttonEl, {
			context: config.context || this.config.tableName + '_filters',
			optionsEndpoint: config.optionsEndpoint || '/api/filter_options/' + this.config.tableName,
			savedFiltersEndpoint: config.savedFiltersEndpoint || '/api/saved_filters',
			dataTable: this,
			extraAjaxData: this.config.extraAjaxData,
			multiSelectFields: config.fields ? config.fields.multiSelect : [],
			rangeFields: config.fields ? config.fields.range : [],
			dateFields: config.fields ? config.fields.date : [],
			existingFilters: this.config.extraAjaxData,
			onApply: function(filterParams) {
				self._applyAdvancedFilters(filterParams);
			},
			onClear: function() {
				self._clearAdvancedFilters();
			}
		});

		// Chip container
		if (config.chipContainer) {
			this._filterChipContainer = typeof config.chipContainer === 'string'
				? document.querySelector(config.chipContainer)
				: config.chipContainer;
		}

		// URL persistence - check for hash on init
		if (config.urlPersistence !== false) {
			this._checkFilterHash();
		}
	};

	/**
	 * Create advanced filter button
	 */
	TableInstance.prototype._createAdvancedFilterButton = function() {
		var D = Funky.Dom;

		var btn = D.create('button')
			.attr('type', 'button')
			.classAdd('btn')
			.classAdd('btn-outline-secondary')
			.classAdd('funky-table-filter-btn')
			.append(D.create('i').classAdd('fas').classAdd('fa-filter'))
			.append(D.create('span').text(' Filters'));

		// Add to button container or header actions
		var headerActions = D.one(this.container).one('.funky-table-header-actions');
		if (headerActions) {
			headerActions.prepend(btn);
		} else if (this._buttonContainer) {
			D.one(this._buttonContainer).append(btn);
		} else {
			D.one(this.container).prepend(btn);
		}

		return btn.el;
	};

	/**
	 * Apply advanced filters
	 */
	TableInstance.prototype._applyAdvancedFilters = function(filterParams) {
		var self = this;

		// Ensure extraAjaxData exists
		if (!this.config.extraAjaxData) {
			this.config.extraAjaxData = {};
		}

		// Merge with extraAjaxData
		Object.keys(filterParams).forEach(function(key) {
			var value = filterParams[key];
			if (value !== null && value !== '' && !(Array.isArray(value) && value.length === 0)) {
				self.config.extraAjaxData[key] = value;
			} else {
				delete self.config.extraAjaxData[key];
			}
		});

		// Update filter chips
		this._updateFilterChips(filterParams);

		// Update button badge
		this._updateAdvancedFilterBadge(filterParams);

		// Callback
		if (this.config.advancedFilter && typeof this.config.advancedFilter.onFilterChange === 'function') {
			this.config.advancedFilter.onFilterChange(filterParams);
		}

		// Emit event
		this._emit('advancedFilterChange', { filters: filterParams });

		// Reload
		this.currentPage = 1;
		this._loadData();
	};

	/**
	 * Clear advanced filters
	 */
	TableInstance.prototype._clearAdvancedFilters = function() {
		var self = this;
		var fields = this.config.advancedFilter && this.config.advancedFilter.fields;

		if (fields) {
			var allFields = [].concat(
				fields.multiSelect || [],
				fields.range || [],
				fields.date || []
			);

			allFields.forEach(function(field) {
				delete self.config.extraAjaxData[field];
				delete self.config.extraAjaxData[field + '_min'];
				delete self.config.extraAjaxData[field + '_max'];
				delete self.config.extraAjaxData[field + '_from'];
				delete self.config.extraAjaxData[field + '_to'];
			});
		}

		// Clear chips
		if (this._filterChipContainer) {
			this._filterChipContainer.innerHTML = '';
		}

		// Clear button badge
		this._updateAdvancedFilterBadge({});

		// Emit event
		this._emit('advancedFilterClear', {});

		// Reload
		this.currentPage = 1;
		this._loadData();
	};

	/**
	 * Update filter chips display
	 */
	TableInstance.prototype._updateFilterChips = function(filterParams) {
		if (!this._filterChipContainer) return;

		var D = Funky.Dom;
		var self = this;

		// Clear existing chips
		this._filterChipContainer.innerHTML = '';

		// Create chip container
		var container = D.create('div').classAdd('funky-filter-chips');

		var hasFilters = false;
		var filterKeys = Object.keys(filterParams);

		filterKeys.forEach(function(key) {
			var value = filterParams[key];
			if (value === null || value === '' || (Array.isArray(value) && value.length === 0)) {
				return;
			}

			// Skip range suffixes to avoid duplicates
			if (key.match(/_(min|max|from|to)$/)) return;

			hasFilters = true;

			var displayValue = Array.isArray(value) ? value.length + ' selected' : String(value);
			var displayKey = self._formatFieldName(key);

			var chip = D.create('span')
				.classAdd('funky-filter-chip')
				.attr('data-filter-key', key)
				.append(D.create('span').classAdd('funky-filter-chip-label').text(displayKey + ': '))
				.append(D.create('span').classAdd('funky-filter-chip-value').text(displayValue))
				.append(
					D.create('button')
						.classAdd('funky-filter-chip-remove')
						.attr('type', 'button')
						.attr('aria-label', 'Remove ' + displayKey + ' filter')
						.append(D.create('i').classAdd('fas').classAdd('fa-times'))
						.on('click', function() {
							self._removeFilterChip(key);
						})
				);

			container.append(chip);
		});

		if (hasFilters) {
			// Add clear all button
			var clearAllBtn = D.create('button')
				.classAdd('funky-filter-chip-clear-all')
				.attr('type', 'button')
				.text('Clear All')
				.on('click', function() {
					self._clearAdvancedFilters();
					if (self._advancedFilter) {
						self._advancedFilter.clearFilters();
					}
				});

			container.append(clearAllBtn);
		}

		D.one(this._filterChipContainer).append(container);
	};

	/**
	 * Remove a single filter chip
	 */
	TableInstance.prototype._removeFilterChip = function(key) {
		delete this.config.extraAjaxData[key];

		// Also remove related fields (for ranges)
		delete this.config.extraAjaxData[key + '_min'];
		delete this.config.extraAjaxData[key + '_max'];
		delete this.config.extraAjaxData[key + '_from'];
		delete this.config.extraAjaxData[key + '_to'];

		// Update AdvancedFilter UI
		if (this._advancedFilter && this._advancedFilter.removeFilter) {
			this._advancedFilter.removeFilter(key);
		}

		// Get remaining filter params
		var remainingParams = {};
		var self = this;
		if (this.config.advancedFilter && this.config.advancedFilter.fields) {
			var fields = this.config.advancedFilter.fields;
			var allFields = [].concat(
				fields.multiSelect || [],
				fields.range || [],
				fields.date || []
			);

			allFields.forEach(function(field) {
				if (self.config.extraAjaxData[field] !== undefined) {
					remainingParams[field] = self.config.extraAjaxData[field];
				}
			});
		}

		// Update chips
		this._updateFilterChips(remainingParams);

		// Update button badge
		this._updateAdvancedFilterBadge(remainingParams);

		// Reload
		this.currentPage = 1;
		this._loadData();
	};

	/**
	 * Update advanced filter button badge
	 */
	TableInstance.prototype._updateAdvancedFilterBadge = function(filterParams) {
		if (!this._advancedFilterButton) return;

		var D = Funky.Dom;
		var btn = D.one(this._advancedFilterButton);

		// Remove existing badge
		var existingBadge = btn.one('.funky-filter-badge');
		if (existingBadge) {
			existingBadge.remove();
		}

		// Count active filters
		var count = 0;
		Object.keys(filterParams).forEach(function(key) {
			var value = filterParams[key];
			if (value !== null && value !== '' && !(Array.isArray(value) && value.length === 0)) {
				// Skip suffixes
				if (!key.match(/_(min|max|from|to)$/)) {
					count++;
				}
			}
		});

		if (count > 0) {
			var badge = D.create('span')
				.classAdd('funky-filter-badge')
				.text(String(count));
			btn.append(badge);
		}
	};

	/**
	 * Format field name for display
	 */
	TableInstance.prototype._formatFieldName = function(field) {
		return field
			.replace(/_id$/, '')
			.replace(/_/g, ' ')
			.replace(/\b\w/g, function(l) { return l.toUpperCase(); });
	};

	/**
	 * Check URL hash for filter state
	 */
	TableInstance.prototype._checkFilterHash = function() {
		var hash = window.location.hash;
		if (!hash || hash.indexOf('#filter=') !== 0) return;

		var filterData = hash.substring(8);
		try {
			var decoded = atob(filterData);
			var params = JSON.parse(decoded);

			if (this._advancedFilter && this._advancedFilter.loadFromParams) {
				this._advancedFilter.loadFromParams(params);
			} else {
				this._applyAdvancedFilters(params);
			}
		} catch (e) {
			console.warn('[Funky.Table] Failed to parse filter hash:', e);
		}
	};

	// =========================================================================
	// Column Profiles Methods (Phase 12)
	// =========================================================================

	/**
	 * Initialize Column Profiles integration
	 */
	TableInstance.prototype._initColumnProfiles = function() {
		var config = this.config.columnProfiles;
		if (!config || !config.enabled) return;

		var self = this;
		this._columnProfiles = {
			profiles: [],
			activeProfile: null,
			storageKey: config.storageKey || this.config.tableName + '_column_profiles'
		};

		// Initialize column visibility state
		this._columnVisibility = {};
		this.config.columns.forEach(function(col) {
			self._columnVisibility[col.data] = col.visible !== false;
		});

		// Load saved profiles from storage
		this._loadSavedProfiles();

		// Add predefined profiles
		if (config.profiles && config.profiles.length) {
			config.profiles.forEach(function(profile) {
				self._addProfile(profile, true);
			});
		}

		// Create profile dropdown
		this._createProfileDropdown(config.buttonSelector);

		// Load default profile
		var defaultProfile = config.defaultProfile || 'Default';
		var saved = this._getLastUsedProfile();
		if (saved) {
			this._applyProfile(saved);
		} else {
			this._applyProfileByName(defaultProfile);
		}

		// Initialize server sync if enabled
		this._initProfileServerSync();
	};

	/**
	 * Load saved profiles from localStorage
	 */
	TableInstance.prototype._loadSavedProfiles = function() {
		var key = this._columnProfiles.storageKey;
		try {
			var saved = localStorage.getItem(key);
			if (saved) {
				var profiles = JSON.parse(saved);
				this._columnProfiles.profiles = profiles;
			}
		} catch (e) {
			console.warn('[Funky.Table] Failed to load saved profiles:', e);
		}
	};

	/**
	 * Save profiles to localStorage
	 */
	TableInstance.prototype._saveProfilesToStorage = function() {
		var key = this._columnProfiles.storageKey;
		try {
			var userProfiles = this._columnProfiles.profiles.filter(function(p) {
				return !p.predefined;
			});
			localStorage.setItem(key, JSON.stringify(userProfiles));
		} catch (e) {
			console.warn('[Funky.Table] Failed to save profiles:', e);
		}
	};

	/**
	 * Get last used profile name
	 */
	TableInstance.prototype._getLastUsedProfile = function() {
		try {
			var lastUsed = localStorage.getItem(this._columnProfiles.storageKey + '_active');
			if (lastUsed) {
				return this._columnProfiles.profiles.find(function(p) {
					return p.name === lastUsed;
				});
			}
		} catch (e) {}
		return null;
	};

	/**
	 * Save last used profile name
	 */
	TableInstance.prototype._saveLastUsedProfile = function(profileName) {
		try {
			localStorage.setItem(this._columnProfiles.storageKey + '_active', profileName);
		} catch (e) {}
	};

	/**
	 * Add a profile
	 */
	TableInstance.prototype._addProfile = function(profile, predefined) {
		var existing = this._columnProfiles.profiles.find(function(p) {
			return p.name === profile.name;
		});

		var profileData = {
			name: profile.name,
			description: profile.description || '',
			columns: profile.columns || null,
			columnWidths: profile.columnWidths || null,
			columnOrder: profile.columnOrder || null,
			predefined: !!predefined
		};

		if (existing) {
			existing.name = profileData.name;
			existing.description = profileData.description;
			existing.columns = profileData.columns;
			existing.columnWidths = profileData.columnWidths;
			existing.columnOrder = profileData.columnOrder;
			existing.predefined = profileData.predefined;
		} else {
			this._columnProfiles.profiles.push(profileData);
		}

		if (!predefined) {
			this._saveProfilesToStorage();
		}
	};

	/**
	 * Create profile dropdown UI
	 */
	TableInstance.prototype._createProfileDropdown = function(buttonSelector) {
		var D = Funky.Dom;
		var self = this;

		// Find or create button
		var btn = buttonSelector
			? document.querySelector(buttonSelector)
			: null;

		if (!btn) {
			btn = D.create('button')
				.attr('type', 'button')
				.classAdd('btn')
				.classAdd('btn-outline-secondary')
				.classAdd('dropdown-toggle')
				.classAdd('funky-profile-btn')
				.attr('data-bs-toggle', 'dropdown')
				.attr('aria-expanded', 'false')
				.append(D.create('i').classAdd('fas').classAdd('fa-columns'))
				.append(D.create('span').classAdd('funky-profile-name').text(' Columns'));

			// Add to header actions
			var headerActions = D.one(this.container).one('.funky-table-header-actions');
			if (headerActions) {
				// Create dropdown wrapper
				var dropdown = D.create('div').classAdd('dropdown').style({ display: 'inline-block' });
				dropdown.append(btn);
				headerActions.prepend(dropdown);
				btn = btn.el;
				this._profileDropdown = dropdown.el;
			} else {
				btn = btn.el;
			}
		} else {
			// Wrap existing button in dropdown
			var dropdown = D.create('div').classAdd('dropdown').style({ display: 'inline-block' });
			btn.parentNode.insertBefore(dropdown.el, btn);
			dropdown.el.appendChild(btn);
			this._profileDropdown = dropdown.el;
		}

		this._profileButton = btn;

		// Create dropdown menu
		var menu = D.create('ul')
			.classAdd('dropdown-menu')
			.classAdd('funky-profile-menu');

		this._profileMenu = menu.el;

		if (this._profileDropdown) {
			D.one(this._profileDropdown).append(menu);
		} else {
			D.one(this._profileButton).parent().append(menu);
		}

		// Rebuild menu
		this._rebuildProfileMenu();
	};

	/**
	 * Rebuild profile dropdown menu
	 */
	TableInstance.prototype._rebuildProfileMenu = function() {
		var D = Funky.Dom;
		var self = this;
		var menu = D.one(this._profileMenu);

		menu.html('');

		// Profile list
		this._columnProfiles.profiles.forEach(function(profile) {
			var isActive = self._columnProfiles.activeProfile &&
				self._columnProfiles.activeProfile.name === profile.name;

			var item = D.create('li');
			var link = D.create('a')
				.classAdd('dropdown-item')
				.attr('href', '#')
				.on('click', function(e) {
					e.preventDefault();
					self._applyProfile(profile);
				});

			if (isActive) {
				link.classAdd('active');
				link.append(D.create('i').classAdd('fas').classAdd('fa-check').classAdd('me-2'));
			}

			link.append(D.create('span').text(profile.name));

			if (profile.description) {
				link.append(
					D.create('small')
						.classAdd('d-block')
						.classAdd('text-muted')
						.text(profile.description)
				);
			}

			item.append(link);
			menu.append(item);
		});

		// Divider
		menu.append(D.create('li').append(D.create('hr').classAdd('dropdown-divider')));

		// Save current as profile
		menu.append(
			D.create('li').append(
				D.create('a')
					.classAdd('dropdown-item')
					.attr('href', '#')
					.append(D.create('i').classAdd('fas').classAdd('fa-save').classAdd('me-2'))
					.append(D.create('span').text('Save Current as Profile...'))
					.on('click', function(e) {
						e.preventDefault();
						self._showSaveProfileDialog();
					})
			)
		);

		// Manage profiles
		menu.append(
			D.create('li').append(
				D.create('a')
					.classAdd('dropdown-item')
					.attr('href', '#')
					.append(D.create('i').classAdd('fas').classAdd('fa-cog').classAdd('me-2'))
					.append(D.create('span').text('Manage Profiles...'))
					.on('click', function(e) {
						e.preventDefault();
						self._showManageProfilesDialog();
					})
			)
		);

		// Column toggle section
		menu.append(D.create('li').append(D.create('hr').classAdd('dropdown-divider')));
		menu.append(
			D.create('li').append(
				D.create('h6')
					.classAdd('dropdown-header')
					.text('Toggle Columns')
			)
		);

		// Column checkboxes
		this.config.columns.forEach(function(col) {
			if (col.data === '_select' || col.data === '_actions') return;

			var isVisible = self._isColumnVisible(col.data);

			var item = D.create('li');
			var link = D.create('a')
				.classAdd('dropdown-item')
				.classAdd('funky-column-toggle')
				.attr('href', '#')
				.on('click', function(e) {
					e.preventDefault();
					e.stopPropagation();
					self.toggleColumn(col.data);
					self._rebuildProfileMenu();
				});

			var checkbox = D.create('input')
				.attr('type', 'checkbox')
				.classAdd('form-check-input')
				.classAdd('me-2');

			if (isVisible) {
				checkbox.attr('checked', 'checked');
			}

			link.append(checkbox);
			link.append(D.create('span').text(col.title || col.data));

			item.append(link);
			menu.append(item);
		});
	};

	/**
	 * Apply a column profile
	 */
	TableInstance.prototype._applyProfile = function(profile) {
		var self = this;

		this._columnProfiles.activeProfile = profile;
		this._saveLastUsedProfile(profile.name);

		// Apply column visibility
		if (profile.columns) {
			this.config.columns.forEach(function(col) {
				if (col.data === '_select' || col.data === '_actions') return;
				var visible = profile.columns.indexOf(col.data) !== -1;
				self._setColumnVisible(col.data, visible);
			});
		} else {
			this.config.columns.forEach(function(col) {
				self._setColumnVisible(col.data, true);
			});
		}

		// Apply column widths
		if (profile.columnWidths) {
			Object.keys(profile.columnWidths).forEach(function(colData) {
				self._setColumnWidth(colData, profile.columnWidths[colData]);
			});
		}

		// Apply column order
		if (profile.columnOrder) {
			self._reorderColumns(profile.columnOrder);
		}

		// Update UI
		this._updateProfileButtonLabel(profile.name);
		this._rebuildProfileMenu();
		this._render();

		// Emit event
		this._emit('profileChange', { profile: profile });

		// Callback
		if (this.config.columnProfiles && typeof this.config.columnProfiles.onProfileChange === 'function') {
			this.config.columnProfiles.onProfileChange(profile);
		}
	};

	/**
	 * Apply profile by name
	 */
	TableInstance.prototype._applyProfileByName = function(name) {
		var profile = this._columnProfiles.profiles.find(function(p) {
			return p.name === name;
		});

		if (profile) {
			this._applyProfile(profile);
		}
	};

	/**
	 * Update profile button label
	 */
	TableInstance.prototype._updateProfileButtonLabel = function(profileName) {
		if (!this._profileButton) return;

		var D = Funky.Dom;
		var nameSpan = D.one(this._profileButton).one('.funky-profile-name');
		if (nameSpan) {
			nameSpan.text(' ' + profileName);
		}
	};

	/**
	 * Show save profile dialog
	 */
	TableInstance.prototype._showSaveProfileDialog = function() {
		var self = this;

		// Get current visible columns
		var visibleColumns = this.config.columns
			.filter(function(col) { return self._isColumnVisible(col.data); })
			.map(function(col) { return col.data; });

		// Use Funky.Modal if available, otherwise prompt
		if (Funky.Modal) {
			Funky.Modal.prompt({
				title: 'Save Column Profile',
				message: 'Enter a name for this profile:',
				placeholder: 'Profile name',
				confirmText: 'Save',
				onConfirm: function(name) {
					if (name) {
						self._addProfile({
							name: name,
							description: '',
							columns: visibleColumns,
							columnWidths: self._getColumnWidths(),
							columnOrder: self._getColumnOrder()
						});
						self._applyProfileByName(name);
					}
				}
			});
		} else {
			var name = prompt('Enter profile name:');
			if (!name) return;

			this._addProfile({
				name: name,
				description: '',
				columns: visibleColumns,
				columnWidths: this._getColumnWidths(),
				columnOrder: this._getColumnOrder()
			});

			this._applyProfileByName(name);
		}
	};

	/**
	 * Show manage profiles dialog
	 */
	TableInstance.prototype._showManageProfilesDialog = function() {
		var self = this;
		var userProfiles = this._columnProfiles.profiles.filter(function(p) {
			return !p.predefined;
		});

		if (userProfiles.length === 0) {
			if (Funky.Announce) {
				Funky.Announce.info('No user-created profiles to manage.');
			} else {
				alert('No user-created profiles to manage.');
			}
			return;
		}

		var profileNames = userProfiles.map(function(p) { return p.name; }).join('\n');

		if (Funky.Modal) {
			Funky.Modal.prompt({
				title: 'Manage Profiles',
				message: 'Enter profile name to delete:\n\n' + profileNames,
				placeholder: 'Profile name',
				confirmText: 'Delete',
				confirmClass: 'btn-danger',
				onConfirm: function(toDelete) {
					if (toDelete) {
						self._columnProfiles.profiles = self._columnProfiles.profiles.filter(function(p) {
							return p.name !== toDelete || p.predefined;
						});
						self._saveProfilesToStorage();
						self._rebuildProfileMenu();
						if (Funky.Announce) {
							Funky.Announce.success('Profile "' + toDelete + '" deleted.');
						}
					}
				}
			});
		} else {
			var toDelete = prompt('Enter profile name to delete:\n\n' + profileNames);
			if (toDelete) {
				this._columnProfiles.profiles = this._columnProfiles.profiles.filter(function(p) {
					return p.name !== toDelete || p.predefined;
				});
				this._saveProfilesToStorage();
				this._rebuildProfileMenu();
			}
		}
	};

	/**
	 * Check if column is visible
	 */
	TableInstance.prototype._isColumnVisible = function(colData) {
		if (!this._columnVisibility) {
			return true;
		}
		return this._columnVisibility[colData] !== false;
	};

	/**
	 * Set column visibility
	 */
	TableInstance.prototype._setColumnVisible = function(colData, visible) {
		if (!this._columnVisibility) {
			this._columnVisibility = {};
		}
		this._columnVisibility[colData] = visible;

		// Update column definition
		var col = this.config.columns.find(function(c) {
			return c.data === colData;
		});
		if (col) {
			col.visible = visible;
		}
	};

	/**
	 * Get column widths
	 */
	TableInstance.prototype._getColumnWidths = function() {
		var widths = {};
		this.config.columns.forEach(function(col) {
			if (col.width) {
				widths[col.data] = col.width;
			}
		});
		return widths;
	};

	/**
	 * Set column width
	 */
	TableInstance.prototype._setColumnWidth = function(colData, width) {
		var col = this.config.columns.find(function(c) {
			return c.data === colData;
		});
		if (col) {
			col.width = width;
		}
	};

	/**
	 * Get column order
	 */
	TableInstance.prototype._getColumnOrder = function() {
		return this.config.columns.map(function(col) {
			return col.data;
		});
	};

	/**
	 * Reorder columns
	 */
	TableInstance.prototype._reorderColumns = function(order) {
		var self = this;
		var orderedColumns = [];

		// First, add columns in specified order
		order.forEach(function(colData) {
			var col = self.config.columns.find(function(c) {
				return c.data === colData;
			});
			if (col) {
				orderedColumns.push(col);
			}
		});

		// Then, add any remaining columns not in order
		this.config.columns.forEach(function(col) {
			if (order.indexOf(col.data) === -1) {
				orderedColumns.push(col);
			}
		});

		this.config.columns = orderedColumns;
	};

	/**
	 * Initialize server sync for profiles
	 */
	TableInstance.prototype._initProfileServerSync = function() {
		var config = this.config.columnProfiles;
		if (!config || !config.serverSync || !config.serverSync.enabled) return;

		this._loadProfilesFromServer();
	};

	/**
	 * Load profiles from server
	 */
	TableInstance.prototype._loadProfilesFromServer = function() {
		var config = this.config.columnProfiles.serverSync;
		var self = this;

		var url = config.endpoint + '?context=' + encodeURIComponent(config.context);

		fetch(url, {
			method: 'GET',
			headers: { 'Accept': 'application/json' }
		})
		.then(function(response) { return response.json(); })
		.then(function(data) {
			if (data.profiles) {
				data.profiles.forEach(function(p) {
					self._addProfile(p, false);
				});
				self._rebuildProfileMenu();
			}
		})
		.catch(function(err) {
			console.warn('[Funky.Table] Failed to load profiles from server:', err);
		});
	};

	/**
	 * Sync profile to server
	 */
	TableInstance.prototype._syncProfileToServer = function(profile) {
		var config = this.config.columnProfiles.serverSync;
		if (!config || !config.enabled) return;

		fetch(config.endpoint, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				'Accept': 'application/json'
			},
			body: JSON.stringify({
				context: config.context,
				profile: profile
			})
		}).catch(function(err) {
			console.warn('[Funky.Table] Failed to sync profile to server:', err);
		});
	};

	// =========================================================================
	// Aggregations Methods (Phase 13)
	// =========================================================================

	/**
	 * Initialize Aggregations
	 */
	TableInstance.prototype._initAggregations = function() {
		var config = this.config.aggregations;
		if (!config || !config.enabled) return;

		this._aggregations = {
			config: config,
			calculated: {},
			serverSide: config.serverSide && config.serverSide.enabled
		};

		// Create footer if needed
		if (config.position === 'footer' || config.position === 'both' || !config.position) {
			this._createAggregationFooter();
		}

		// Create header row if needed
		if (config.position === 'header' || config.position === 'both') {
			this._createAggregationHeader();
		}
	};

	/**
	 * Create aggregation footer
	 */
	TableInstance.prototype._createAggregationFooter = function() {
		var table = this.tableEl ? this.tableEl.el : null;
		if (!table) return;

		// Find or create tfoot
		var tfoot = table.querySelector('tfoot');
		if (!tfoot) {
			tfoot = document.createElement('tfoot');
			table.appendChild(tfoot);
		}

		this._aggregationFooter = tfoot;
	};

	/**
	 * Create aggregation header row
	 */
	TableInstance.prototype._createAggregationHeader = function() {
		var D = Funky.Dom;
		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (!tableEl) return;
		
		var thead = tableEl.querySelector('thead');
		if (!thead) return;

		var row = D.create('tr').classAdd('funky-aggregation-row');
		this._aggregationHeader = row.el;

		// Insert after header row
		var headerRow = thead.querySelector('tr');
		if (headerRow && headerRow.nextSibling) {
			thead.insertBefore(row.el, headerRow.nextSibling);
		} else {
			thead.appendChild(row.el);
		}
	};

	/**
	 * Calculate and render aggregations
	 */
	TableInstance.prototype._calculateAggregations = function() {
		if (!this._aggregations) return;

		var config = this._aggregations.config;
		var self = this;

		// Use server-side aggregations if available
		if (this._aggregations.serverSide && this._aggregations.serverData) {
			this._aggregations.calculated = this._aggregations.serverData;
		} else {
			// Calculate client-side
			if (config.columns) {
				Object.keys(config.columns).forEach(function(column) {
					var colConfig = config.columns[column];

					// Handle array of aggregations
					if (Array.isArray(colConfig)) {
						self._aggregations.calculated[column] = colConfig.map(function(agg) {
							return self._calculateAggregation(column, agg);
						});
					} else {
						self._aggregations.calculated[column] = self._calculateAggregation(column, colConfig);
					}
				});
			}
		}

		// Render
		this._renderAggregations();

		// Emit event
		this._emit('aggregationsCalculated', { aggregations: this._aggregations.calculated });

		// Callback
		if (typeof config.onCalculate === 'function') {
			config.onCalculate(this._aggregations.calculated);
		}
	};

	/**
	 * Calculate single aggregation
	 */
	TableInstance.prototype._calculateAggregation = function(column, aggConfig) {
		var self = this;
		var dataSource = this.displayData && this.displayData.length > 0 ? this.displayData : this.data;

		// Normalize string config to object: 'sum' -> { type: 'sum' }
		if (typeof aggConfig === 'string') {
			aggConfig = { type: aggConfig };
		}

		var values = dataSource.map(function(row) {
			return row[column];
		}).filter(function(v) {
			return v !== null && v !== undefined && v !== '';
		});

		var numericValues = values.map(function(v) {
			return parseFloat(v);
		}).filter(function(v) {
			return !isNaN(v);
		});

		var result = {
			type: aggConfig.type,
			label: aggConfig.label || '',
			value: null,
			formatted: ''
		};

		switch (aggConfig.type) {
			case 'sum':
				result.value = numericValues.reduce(function(a, b) { return a + b; }, 0);
				break;

			case 'avg':
			case 'average':
				result.value = numericValues.length > 0
					? numericValues.reduce(function(a, b) { return a + b; }, 0) / numericValues.length
					: 0;
				break;

			case 'min':
				result.value = numericValues.length > 0
					? Math.min.apply(Math, numericValues)
					: null;
				break;

			case 'max':
				result.value = numericValues.length > 0
					? Math.max.apply(Math, numericValues)
					: null;
				break;

			case 'count':
				result.value = values.length;
				break;

			case 'countDistinct':
				var unique = [];
				values.forEach(function(v) {
					if (unique.indexOf(v) === -1) unique.push(v);
				});
				result.value = unique.length;
				break;

			case 'weightedAvg':
				var weights = dataSource.map(function(row) {
					return parseFloat(row[aggConfig.weightColumn]) || 0;
				});
				var totalWeight = weights.reduce(function(a, b) { return a + b; }, 0);
				var weightedSum = 0;
				numericValues.forEach(function(v, i) {
					weightedSum += v * weights[i];
				});
				result.value = totalWeight > 0 ? weightedSum / totalWeight : 0;
				break;

			case 'first':
				result.value = values.length > 0 ? values[0] : null;
				break;

			case 'last':
				result.value = values.length > 0 ? values[values.length - 1] : null;
				break;

			case 'median':
				if (numericValues.length > 0) {
					var sorted = numericValues.slice().sort(function(a, b) { return a - b; });
					var mid = Math.floor(sorted.length / 2);
					result.value = sorted.length % 2
						? sorted[mid]
						: (sorted[mid - 1] + sorted[mid]) / 2;
				}
				break;

			case 'stddev':
				if (numericValues.length > 0) {
					var avg = numericValues.reduce(function(a, b) { return a + b; }, 0) / numericValues.length;
					var squareDiffs = numericValues.map(function(v) {
						return Math.pow(v - avg, 2);
					});
					var avgSquareDiff = squareDiffs.reduce(function(a, b) { return a + b; }, 0) / squareDiffs.length;
					result.value = Math.sqrt(avgSquareDiff);
				}
				break;

			case 'custom':
				if (typeof aggConfig.fn === 'function') {
					result.value = aggConfig.fn(values, dataSource, numericValues);
					// Custom function may return formatted string directly
					if (typeof result.value === 'string') {
						result.formatted = result.value;
						return result;
					}
				}
				break;
		}

		// Format the value
		result.formatted = this._formatAggregationValue(result.value, aggConfig.format);

		return result;
	};

	/**
	 * Format aggregation value
	 */
	TableInstance.prototype._formatAggregationValue = function(value, format) {
		if (value === null || value === undefined) return '-';

		var config = this._aggregations && this._aggregations.config.formatting || {};
		var formatConfig = config[format] || {};

		switch (format) {
			case 'number':
				return this._formatAggNumber(value, formatConfig);
			case 'currency':
				return this._formatAggCurrency(value, formatConfig);
			case 'percent':
				return this._formatAggPercent(value, formatConfig);
			default:
				if (typeof value === 'number') {
					return this._formatAggNumber(value, { decimals: 2 });
				}
				return String(value);
		}
	};

	/**
	 * Format number for aggregation
	 */
	TableInstance.prototype._formatAggNumber = function(value, config) {
		var decimals = config.decimals !== undefined ? config.decimals : 0;
		var separator = config.thousandsSeparator || ',';

		var parts = value.toFixed(decimals).split('.');
		parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, separator);

		return parts.join('.');
	};

	/**
	 * Format currency for aggregation
	 */
	TableInstance.prototype._formatAggCurrency = function(value, config) {
		var prefix = config.prefix || '$';
		var suffix = config.suffix || '';
		var formatted = this._formatAggNumber(value, config);

		return prefix + formatted + suffix;
	};

	/**
	 * Format percent for aggregation
	 */
	TableInstance.prototype._formatAggPercent = function(value, config) {
		var decimals = config.decimals !== undefined ? config.decimals : 2;
		var suffix = config.suffix || '%';

		return value.toFixed(decimals) + suffix;
	};

	/**
	 * Render aggregations
	 */
	TableInstance.prototype._renderAggregations = function() {
		if (this._aggregationFooter) {
			this._renderAggregationRow(this._aggregationFooter, 'footer');
		}

		if (this._aggregationHeader) {
			this._renderAggregationRow(this._aggregationHeader, 'header');
		}
	};

	/**
	 * Render aggregation row
	 */
	TableInstance.prototype._renderAggregationRow = function(container, position) {
		var D = Funky.Dom;
		var self = this;
		var calculated = this._aggregations.calculated;

		container.innerHTML = '';

		var row = D.create('tr').classAdd('funky-aggregation-row');

		// Check if control column should be visible (only when there are hidden columns)
		var hiddenCount = (this.hiddenColumns ? this.hiddenColumns.length : 0) + 
		                  (this.manuallyHiddenColumns ? this.manuallyHiddenColumns.length : 0);
		var controlColumnVisible = hiddenCount > 0;
		
		// Get array of responsively hidden column indices
		var responsivelyHidden = this.hiddenColumns || [];

		// Use this.columns (includes dynamically added control/checkbox columns), not this.config.columns
		this.columns.forEach(function(col, colIndex) {
			// Skip hidden columns (user-toggled visibility)
			if (self._columnVisibility && self._columnVisibility[col.data] === false) {
				return;
			}

			// Check if this is a special column (use name since data might be null)
			var isControlColumn = col.name === '_control' || col.data === '_control';
			var isSelectColumn = col.name === '_select' || col.data === '_select';
			var isActionsColumn = col.name === '_actions' || col.data === '_actions';
			
			// Check if column is responsively hidden
			var isResponsivelyHidden = responsivelyHidden.indexOf(colIndex) !== -1;

			var td = D.create('td')
				.classAdd('funky-aggregation-cell')
				.attr('data-column-index', colIndex);
			
			// Apply responsive hidden class if needed
			if (isResponsivelyHidden) {
				td.classAdd('funky-table-hidden');
			}

			// Control column: always include but hide with CSS class when not visible
			if (isControlColumn) {
				if (!controlColumnVisible) {
					td.classAdd('funky-table-hidden');
				}
				row.append(td);
				return;
			}

			// Select and actions columns: empty cells
			if (isSelectColumn || isActionsColumn) {
				row.append(td);
				return;
			}

			var aggData = calculated[col.data];

			if (!aggData) {
				row.append(td);
				return;
			}

			// Handle multiple aggregations
			if (Array.isArray(aggData)) {
				var multiContainer = D.create('div').classAdd('funky-aggregation-multi');

				aggData.forEach(function(agg) {
					var line = D.create('div').classAdd('funky-aggregation-line');

					if (agg.label) {
						line.append(
							D.create('span')
								.classAdd('funky-aggregation-label')
								.text(agg.label + ' ')
						);
					}

					line.append(
						D.create('span')
							.classAdd('funky-aggregation-value')
							.text(agg.formatted)
					);

					multiContainer.append(line);
				});

				td.append(multiContainer);
			} else {
				if (aggData.label) {
					td.append(
						D.create('span')
							.classAdd('funky-aggregation-label')
							.text(aggData.label + ' ')
					);
				}

				td.append(
					D.create('span')
						.classAdd('funky-aggregation-value')
						.text(aggData.formatted)
				);
			}

			row.append(td);
		});

		D.one(container).append(row);
	};

	/**
	 * Store server-side aggregations from response
	 */
	TableInstance.prototype._storeServerAggregations = function(response) {
		if (!this._aggregations || !this._aggregations.serverSide) return;

		var key = this._aggregations.config.serverSide.key || 'aggregations';
		if (response[key]) {
			this._aggregations.serverData = response[key];
		}
	};

	/**
	 * Calculate group aggregations
	 */
	TableInstance.prototype._calculateGroupAggregations = function(groupKey, groupRows) {
		var config = this._aggregations && this._aggregations.config.groups;
		if (!config || !config.enabled) return null;

		var self = this;
		var groupAggs = {};

		Object.keys(config.columns).forEach(function(column) {
			var colConfig = config.columns[column];
			var values = groupRows.map(function(row) { return row[column]; });
			var numericValues = values.map(function(v) {
				return parseFloat(v);
			}).filter(function(v) {
				return !isNaN(v);
			});

			var result = { type: colConfig.type, label: colConfig.label || '', value: null };

			switch (colConfig.type) {
				case 'sum':
					result.value = numericValues.reduce(function(a, b) { return a + b; }, 0);
					break;
				case 'avg':
					result.value = numericValues.length > 0
						? numericValues.reduce(function(a, b) { return a + b; }, 0) / numericValues.length
						: 0;
					break;
				case 'count':
					result.value = groupRows.length;
					break;
				case 'min':
					result.value = numericValues.length > 0
						? Math.min.apply(Math, numericValues)
						: null;
					break;
				case 'max':
					result.value = numericValues.length > 0
						? Math.max.apply(Math, numericValues)
						: null;
					break;
			}

			result.formatted = self._formatAggregationValue(result.value, colConfig.format);
			groupAggs[column] = result;
		});

		return groupAggs;
	};

	/**
	 * Render group subtotal row
	 */
	TableInstance.prototype._renderGroupSubtotalRow = function(groupKey, groupAggs) {
		var D = Funky.Dom;
		var self = this;

		var row = D.create('tr')
			.classAdd('funky-group-subtotal')
			.attr('data-group', groupKey);

		this.config.columns.forEach(function(col) {
			var td = D.create('td');

			if (col.data === self.config.groupBy) {
				td.text(groupKey + ' Subtotal')
				   .classAdd('funky-group-subtotal-label');
			} else if (groupAggs && groupAggs[col.data]) {
				var agg = groupAggs[col.data];
				if (agg.label) {
					td.append(D.create('span').classAdd('funky-aggregation-label').text(agg.label + ' '));
				}
				td.append(D.create('span').classAdd('funky-aggregation-value').text(agg.formatted));
			}

			row.append(td);
		});

		return row.el;
	};

	// =========================================================================
	// LiveBinding Methods (Phase 14)
	// =========================================================================

	/**
	 * Initialize LiveBinding integration
	 */
	TableInstance.prototype._initLiveBinding = function() {
		var config = this.config.liveBinding;
		if (!config || !config.enabled) return;

		var self = this;

		// Store binding state
		this._liveBinding = {
			connected: false,
			source: null,
			lastUpdate: null,
			paused: false,
			destroyed: false
		};

		// Create live indicator
		this._createLiveIndicator();

		// Initialize based on source type
		switch (config.source) {
			case 'ajax':
				this._initAjaxLiveBinding(config.ajax || {});
				break;
			case 'websocket':
				this._initWebSocketBinding(config.websocket || {});
				break;
			case 'eventsource':
				this._initEventSourceBinding(config.eventsource || {});
				break;
			case 'custom':
				// Custom source - user handles updates via API
				this._liveBinding.source = 'custom';
				this._setLiveConnected(true);
				break;
			default:
				console.warn('[Funky.Table] Unknown liveBinding source:', config.source);
		}
	};

	/**
	 * Initialize AJAX polling live binding
	 */
	TableInstance.prototype._initAjaxLiveBinding = function(config) {
		var self = this;
		var url = config.url || this.config.ajaxUrl;
		var interval = config.interval || 30000;
		var debounce = config.debounce || 1000;
		var retryAttempts = config.retryAttempts || 3;
		var retryDelay = config.retryDelay || 5000;

		var retryCount = 0;
		var debounceTimer = null;

		// Debounced fetch function
		var fetchData = function() {
			if (self._liveBinding.paused || self._liveBinding.destroyed) return;

			if (debounceTimer) {
				clearTimeout(debounceTimer);
			}

			debounceTimer = setTimeout(function() {
				self._liveAjaxFetch(url, retryAttempts, retryDelay, function(success) {
					if (success) {
						retryCount = 0;
						self._setLiveConnected(true);
					} else {
						retryCount++;
						if (retryCount >= retryAttempts) {
							self._setLiveConnected(false);
						}
					}
				});
			}, debounce);
		};

		// Set up polling interval (don't do initial fetch - _loadData handles it)
		this._liveBinding.pollInterval = setInterval(fetchData, interval);

		// Store for cleanup
		this._liveBinding.source = 'ajax';
		this._liveBinding.fetchData = fetchData;
		this._setLiveConnected(true);
	};

	/**
	 * Perform AJAX fetch for live binding
	 */
	TableInstance.prototype._liveAjaxFetch = function(url, retryAttempts, retryDelay, callback) {
		var self = this;
		var config = this.config.liveBinding;
		var attempt = 0;

		var doFetch = function() {
			var params = Object.assign({}, self.config.extraAjaxData || {}, {
				page: self.currentPage,
				pageLength: self.config.pageLength,
				orderBy: self.sortOrder.column,
				orderDir: self.sortOrder.direction,
				search: self.searchQuery
			});

			if (self._liveBinding.lastUpdate) {
				params._since = self._liveBinding.lastUpdate;
			}

			fetch(url + '?' + new URLSearchParams(params).toString(), {
				method: 'GET',
				headers: { 'Accept': 'application/json' }
			})
			.then(function(response) { return response.json(); })
			.then(function(response) {
				var data = config.transform ? config.transform(response) : response.data || response;
				if (Array.isArray(data)) {
					self._handleLiveUpdate(data, response);
				}
				self._liveBinding.lastUpdate = new Date().toISOString();
				callback(true);
			})
			.catch(function(error) {
				attempt++;
				if (attempt < retryAttempts) {
					setTimeout(doFetch, retryDelay);
				} else {
					if (typeof config.onError === 'function') {
						config.onError(error);
					}
					callback(false);
				}
			});
		};

		doFetch();
	};

	/**
	 * Initialize WebSocket live binding using shared Funky.WebSocket
	 */
	TableInstance.prototype._initWebSocketBinding = function(config) {
		var self = this;
		var liveConfig = this.config.liveBinding;

		// Require Funky.WebSocket
		if (!Funky.WebSocket) {
			console.warn('[Funky.Table] Funky.WebSocket required for websocket binding');
			return;
		}

		// Get channels from config
		var channels = config.channels || config.channel;
		if (!channels) {
			console.warn('[Funky.Table] WebSocket channel(s) required');
			return;
		}

		// Normalize to array
		if (!Array.isArray(channels)) {
			channels = [channels];
		}

		// Store unsubscribe functions for cleanup
		this._liveBinding.wsUnsubscribes = [];
		this._liveBinding.wsChannels = channels;

		// Handler for WebSocket messages
		var messageHandler = function(message) {
			if (self._liveBinding.paused) return;
			self._handleWebSocketMessage(message);
		};

		// Subscribe to each channel
		channels.forEach(function(channel) {
			var unsubscribe = Funky.WebSocket.subscribe(channel, messageHandler);
			if (unsubscribe) {
				self._liveBinding.wsUnsubscribes.push(unsubscribe);
			}
		});

		// Handler for connection status changes
		var statusHandler = function(data) {
			if (data.status === 'connected') {
				self._setLiveConnected(true);
				if (typeof liveConfig.onConnect === 'function') {
					liveConfig.onConnect();
				}
			} else if (data.status === 'disconnected' || data.status === 'reconnecting') {
				self._setLiveConnected(false);
				if (data.status === 'disconnected' && typeof liveConfig.onDisconnect === 'function') {
					liveConfig.onDisconnect('Connection closed');
				}
			}
		};

		// Listen for connection status changes
		Funky.WebSocket.on('status_changed', statusHandler);
		this._liveBinding.wsStatusHandler = statusHandler;

		// Set initial connection state based on current WebSocket status
		this._setLiveConnected(Funky.WebSocket.isConnected());

		this._liveBinding.source = 'websocket';

		// Reconnect function now just checks if WebSocket is initialized
		this._liveBinding.reconnect = function() {
			if (!Funky.WebSocket.isInitialized()) {
				Funky.WebSocket.init();
			}
			if (!Funky.WebSocket.isConnected()) {
				Funky.WebSocket.connect();
			}
		};
	};

	/**
	 * Handle WebSocket message
	 */
	TableInstance.prototype._handleWebSocketMessage = function(message) {
		var config = this.config.liveBinding;

		// Skip pong messages
		if (message.type === 'pong') return;

		// Handle different message types
		switch (message.type) {
			case 'update':
			case 'insert':
				this._handleRowUpdate(message.data);
				break;
			case 'delete':
				this._handleRowDelete(message.id || (message.data && message.data.id));
				break;
			case 'refresh':
				this._loadData();
				break;
			case 'batch':
				this._handleBatchUpdate(message.updates || []);
				break;
			default:
				// Transform and handle as data update
				var data = config.transform ? config.transform(message) : message;
				if (Array.isArray(data)) {
					this._handleLiveUpdate(data);
				}
		}
	};

	/**
	 * Initialize EventSource (SSE) live binding
	 */
	TableInstance.prototype._initEventSourceBinding = function(config) {
		var self = this;
		var liveConfig = this.config.liveBinding;

		if (!config.url) {
			console.warn('[Funky.Table] EventSource URL required');
			return;
		}

		var eventSource = new EventSource(config.url, {
			withCredentials: config.withCredentials || false
		});

		eventSource.onopen = function() {
			self._setLiveConnected(true);
			if (typeof liveConfig.onConnect === 'function') {
				liveConfig.onConnect();
			}
		};

		// Listen to specific event types
		var eventTypes = config.eventTypes || ['message'];
		eventTypes.forEach(function(eventType) {
			eventSource.addEventListener(eventType, function(event) {
				if (self._liveBinding.paused) return;

				try {
					var data = JSON.parse(event.data);
					self._handleSSEEvent(eventType, data);
				} catch (e) {
					console.warn('[Funky.Table] Failed to parse SSE data:', e);
				}
			});
		});

		eventSource.onerror = function(error) {
			self._setLiveConnected(false);
			if (typeof liveConfig.onError === 'function') {
				liveConfig.onError(error);
			}
			if (typeof liveConfig.onDisconnect === 'function') {
				liveConfig.onDisconnect('SSE connection error');
			}
		};

		this._liveBinding.eventSource = eventSource;
		this._liveBinding.source = 'eventsource';
	};

	/**
	 * Handle SSE event
	 */
	TableInstance.prototype._handleSSEEvent = function(eventType, data) {
		switch (eventType) {
			case 'update':
			case 'insert':
				this._handleRowUpdate(data);
				break;
			case 'delete':
				this._handleRowDelete(data.id);
				break;
			default:
				if (Array.isArray(data)) {
					this._handleLiveUpdate(data);
				} else if (data.data) {
					this._handleLiveUpdate(data.data);
				}
		}
	};

	/**
	 * Handle live data update
	 */
	TableInstance.prototype._handleLiveUpdate = function(newData, meta) {
		var config = this.config.liveBinding;
		var self = this;

		if (!Array.isArray(newData)) {
			newData = [newData];
		}

		// Filter updates
		if (typeof config.filter === 'function') {
			newData = newData.filter(config.filter);
		}

		// Merge strategies
		var changes = { updated: [], inserted: [], deleted: [] };
		var mergeStrategy = config.mergeStrategy || 'smart';

		switch (mergeStrategy) {
			case 'replace':
				// Replace all data
				this.data = newData;
				changes.updated = newData;
				break;

			case 'merge':
				// Merge by ID
				newData.forEach(function(item) {
					var existingIndex = -1;
					for (var i = 0; i < self.data.length; i++) {
						if (self.data[i].id === item.id) {
							existingIndex = i;
							break;
						}
					}

					if (existingIndex !== -1) {
						Object.assign(self.data[existingIndex], item);
						changes.updated.push(item);
					} else {
						self.data.push(item);
						changes.inserted.push(item);
					}
				});
				break;

			case 'smart':
			default:
				// Smart merge - detect changes
				var existingIds = this.data.map(function(d) { return String(d.id); });
				var newIds = newData.map(function(d) { return String(d.id); });

				// Find inserts and updates
				newData.forEach(function(item) {
					var existingIndex = existingIds.indexOf(String(item.id));
					if (existingIndex === -1) {
						self.data.push(item);
						changes.inserted.push(item);
					} else {
						// Check for updates
						var existing = self.data[existingIndex];
						if (JSON.stringify(existing) !== JSON.stringify(item)) {
							Object.assign(existing, item);
							changes.updated.push(item);
						}
					}
				});

				// Find deletes (if meta indicates full dataset)
				if (meta && meta.complete) {
					self.data = self.data.filter(function(item) {
						if (newIds.indexOf(String(item.id)) === -1) {
							changes.deleted.push(item);
							return false;
						}
						return true;
					});
				}
				break;
		}

		// Update totals if provided
		if (meta && meta.recordsTotal !== undefined) {
			this.totalRecords = meta.recordsTotal;
		}
		if (meta && meta.recordsFiltered !== undefined) {
			this.filteredRecords = meta.recordsFiltered;
		}

		// Re-render
		this._applyClientFilters();
		this._renderData();

		// Highlight updated rows
		if (config.highlightUpdates) {
			this._highlightRows(
				changes.updated.concat(changes.inserted),
				config.highlightDuration || 2000
			);
		}

		// Emit event
		this._emit('liveUpdate', changes);

		// Callback
		if (typeof config.onUpdate === 'function') {
			config.onUpdate(changes);
		}
	};

	/**
	 * Handle single row update
	 */
	TableInstance.prototype._handleRowUpdate = function(rowData) {
		var config = this.config.liveBinding || {};
		var self = this;

		// Filter
		if (typeof config.filter === 'function' && !config.filter(rowData)) {
			return;
		}

		// Find and update or insert
		var existingIndex = -1;
		for (var i = 0; i < this.data.length; i++) {
			if (this.data[i].id === rowData.id) {
				existingIndex = i;
				break;
			}
		}

		var isInsert = existingIndex === -1;

		if (isInsert) {
			this.data.unshift(rowData); // Insert at top
		} else {
			Object.assign(this.data[existingIndex], rowData);
		}

		// Re-render
		this._applyClientFilters();
		this._renderData();

		// Highlight
		if (config.highlightUpdates) {
			this._highlightRows([rowData], config.highlightDuration || 2000);
		}

		// Emit event
		this._emit('liveUpdate', {
			updated: isInsert ? [] : [rowData],
			inserted: isInsert ? [rowData] : [],
			deleted: []
		});

		if (typeof config.onUpdate === 'function') {
			config.onUpdate({
				updated: isInsert ? [] : [rowData],
				inserted: isInsert ? [rowData] : [],
				deleted: []
			});
		}
	};

	/**
	 * Handle row delete
	 */
	TableInstance.prototype._handleRowDelete = function(id) {
		var config = this.config.liveBinding || {};

		var deleted = null;
		this.data = this.data.filter(function(d) {
			if (String(d.id) === String(id)) {
				deleted = d;
				return false;
			}
			return true;
		});

		if (!deleted) return;

		// Remove row from DOM
		this._removeRowFromDom(id);

		// Update counts
		this.totalRecords = Math.max(0, this.totalRecords - 1);
		this.filteredRecords = Math.max(0, this.filteredRecords - 1);

		// Update info
		this._updateInfo();

		// Emit event
		this._emit('liveUpdate', { updated: [], inserted: [], deleted: [deleted] });

		if (typeof config.onUpdate === 'function') {
			config.onUpdate({ updated: [], inserted: [], deleted: [deleted] });
		}
	};

	/**
	 * Handle batch update
	 */
	TableInstance.prototype._handleBatchUpdate = function(updates) {
		var self = this;

		updates.forEach(function(update) {
			switch (update.type) {
				case 'update':
				case 'insert':
					// Queue updates, don't re-render each time
					var existingIndex = -1;
					for (var i = 0; i < self.data.length; i++) {
						if (self.data[i].id === update.data.id) {
							existingIndex = i;
							break;
						}
					}
					if (existingIndex !== -1) {
						Object.assign(self.data[existingIndex], update.data);
					} else {
						self.data.push(update.data);
					}
					break;
				case 'delete':
					self.data = self.data.filter(function(d) {
						return String(d.id) !== String(update.id);
					});
					break;
			}
		});

		// Re-render once after all updates
		this._applyClientFilters();
		this._renderData();
	};

	/**
	 * Remove row from DOM
	 */
	TableInstance.prototype._removeRowFromDom = function(id) {
		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (!tableEl) return;
		
		var tr = tableEl.querySelector('tr[data-id="' + id + '"]');
		if (tr) {
			// Animate out
			var D = Funky.Dom;
			D.one(tr).classAdd('funky-row-removing');
			setTimeout(function() {
				if (tr.parentNode) {
					tr.parentNode.removeChild(tr);
				}
			}, 300);
		}
	};

	/**
	 * Highlight rows temporarily
	 */
	TableInstance.prototype._highlightRows = function(rows, duration) {
		var self = this;

		rows.forEach(function(row) {
			var tr = self.element.querySelector('tr[data-id="' + row.id + '"]');
			if (!tr) return;

			Funky.Dom.one(tr).classAdd('funky-row-updated');

			setTimeout(function() {
				Funky.Dom.one(tr).classRemove('funky-row-updated');
			}, duration);
		});
	};

	/**
	 * Set live connection status
	 */
	TableInstance.prototype._setLiveConnected = function(connected) {
		if (!this._liveBinding) return;

		this._liveBinding.connected = connected;

		// Update UI indicator
		var indicator = this.container.querySelector('.funky-live-indicator');
		if (indicator) {
			Funky.Dom.one(indicator)
				.classRemove('funky-live-connected', 'funky-live-disconnected')
				.classAdd(connected ? 'funky-live-connected' : 'funky-live-disconnected');
		}

		// Emit event
		this._emit(connected ? 'liveConnected' : 'liveDisconnected', {});
	};

	/**
	 * Create live status indicator
	 */
	TableInstance.prototype._createLiveIndicator = function() {
		var config = this.config.liveBinding;
		if (!config || !config.enabled) return;
		if (config.showIndicator === false) return;

		var D = Funky.Dom;

		var indicator = D.create('span')
			.classAdd('funky-live-indicator')
			.classAdd('funky-live-disconnected')
			.attr('title', 'Live updates')
			.append(D.create('span').classAdd('funky-live-dot'))
			.append(D.create('span').classAdd('funky-live-label').text('Live'));

		// Add to header actions
		var headerActions = D.one(this.container).one('.funky-table-header-actions');
		if (headerActions) {
			headerActions.append(indicator);
		} else {
			// Add before table
			D.one(this.container).prepend(indicator);
		}
	};

	// =========================================================================
	// Responsive (Phase 17)
	// =========================================================================

	/**
	 * Default breakpoints
	 */
	var DEFAULT_BREAKPOINTS = [
		{ name: 'mobile', width: 480 },
		{ name: 'mobile-l', width: 640 },
		{ name: 'tablet', width: 768 },
		{ name: 'tablet-l', width: 1024 },
		{ name: 'laptop', width: 1280 },
		{ name: 'desktop', width: 10000 }
	];

	/**
	 * Determine current breakpoint based on container width
	 * @param {boolean} force - Force recalculation even if breakpoint hasn't changed
	 */
	TableInstance.prototype._determineBreakpoint = function(force) {
		if (!this.config.responsive) return;

		// Use wrapper element for width detection (container may be replaced)
		var widthElement = this.wrapper && this.wrapper.el ? this.wrapper.el : this.container;
		var containerWidth = widthElement.offsetWidth || window.innerWidth;
		
		// Skip if container has no width (still hidden)
		if (containerWidth === 0) return;
		
		if (this.config.debug) {
			console.log('[Funky.Table] _determineBreakpoint containerWidth:', containerWidth, 'force:', !!force);
		}
		
		// Support responsive as object { enabled: true, breakpoints: [...] } or just breakpoints at config level
		var responsiveConfig = typeof this.config.responsive === 'object' ? this.config.responsive : {};
		var breakpoints = responsiveConfig.breakpoints || this.config.breakpoints || DEFAULT_BREAKPOINTS;
		
		// Ensure breakpoints is an array
		if (!Array.isArray(breakpoints)) {
			breakpoints = DEFAULT_BREAKPOINTS;
		}
		
		var newBreakpoint = 'desktop';

		// Sort breakpoints by width descending
		var sorted = breakpoints.slice().sort(function(a, b) {
			return b.width - a.width;
		});

		for (var i = 0; i < sorted.length; i++) {
			if (containerWidth <= sorted[i].width) {
				newBreakpoint = sorted[i].name;
			}
		}

		if (force || newBreakpoint !== this.currentBreakpoint) {
			this.currentBreakpoint = newBreakpoint;
			this._updateResponsiveColumns();

			if (this.config.debug) {
				console.log('[Funky.Table] Breakpoint changed:', newBreakpoint, '(' + containerWidth + 'px)', force ? '(forced)' : '');
			}

			this._emit('breakpointChange', { breakpoint: newBreakpoint, width: containerWidth });
		}
	};

	/**
	 * Handle window resize
	 */
	TableInstance.prototype._handleResize = function() {
		var self = this;

		// Debounce resize
		if (this._resizeTimeout) {
			clearTimeout(this._resizeTimeout);
		}

		this._resizeTimeout = setTimeout(function() {
			self._determineBreakpoint();
		}, 100);
	};

	/**
	 * Update visible columns based on breakpoint
	 */
	TableInstance.prototype._updateResponsiveColumns = function() {
		if (!this.config.responsive) return;

		if (this.config.debug) {
			console.log('[Funky.Table] _updateResponsiveColumns called, breakpoint:', this.currentBreakpoint);
			console.log('[Funky.Table] tbody rows before:', this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr').length : 0);
		}

		var self = this;
		var breakpoint = this.currentBreakpoint;
		// Use this.columns (processed) not this.config.columns (original)
		var columns = this.columns;

		// Get minimum priority for this breakpoint
		var maxPriority = this._getMaxPriorityForBreakpoint(breakpoint);

		if (this.config.debug) {
			console.log('[Funky.Table] maxPriority for breakpoint:', maxPriority);
			console.log('[Funky.Table] Column priorities:', columns.map(function(c) { 
				return { name: c.name || c.data, priority: c.responsivePriority, visible: c.visible }; 
			}));
		}

		var columnsToShow = [];
		var columnsToHide = [];
		var manuallyHiddenColumns = [];  // Columns hidden via column visibility toggle

		columns.forEach(function(col, index) {
			// Checkbox, select and control columns always show
			if (col.type === 'checkbox' || col.name === '_control' || col.name === '_select') {
				columnsToShow.push(index);
				return;
			}
			
			// Check if column is manually hidden via column visibility
			// These columns should stay hidden and not be touched by responsive
			if (col.visible === false) {
				manuallyHiddenColumns.push(index);
				return;
			}

			// Check explicit responsive config
			if (col.responsive && typeof col.responsive === 'object') {
				if (col.responsive[breakpoint] === false) {
					columnsToHide.push(index);
					return;
				}
			}

			// Check priority - columns without explicit responsivePriority always show
			// Lower priority numbers = more important = stay visible longer
			// Higher priority numbers = less important = hide first
			var colPriority = col.responsivePriority;
			if (colPriority === undefined || colPriority === null) {
				// No priority set - always show
				columnsToShow.push(index);
			} else if (colPriority > maxPriority) {
				// Priority exceeds breakpoint threshold - hide (less important)
				columnsToHide.push(index);
			} else {
				columnsToShow.push(index);
			}
		});

		// Store visibility info (include manually hidden in hidden count for control column)
		this.visibleColumns = columnsToShow;
		this.hiddenColumns = columnsToHide;
		this.manuallyHiddenColumns = manuallyHiddenColumns;

		if (this.config.debug) {
			console.log('[Funky.Table] Responsive: columnsToShow:', columnsToShow, 'columnsToHide:', columnsToHide, 'manuallyHidden:', manuallyHiddenColumns);
			console.log('[Funky.Table] Total columns:', columns.length, 'visible:', columnsToShow.length, 'hidden:', columnsToHide.length, 'manuallyHidden:', manuallyHiddenColumns.length);
		}

		// Apply visibility (only for responsive columns, not manually hidden ones)
		this._applyColumnVisibility(columnsToShow, columnsToHide);

		if (this.config.debug) {
			console.log('[Funky.Table] After _applyColumnVisibility, tbody rows:', this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr').length : 0);
		}

		// Show control column if ANY columns are hidden (responsive OR manual)
		var totalHidden = columnsToHide.length + manuallyHiddenColumns.length;
		this._updateControlColumn(totalHidden > 0);

		// Re-render aggregation row to update hidden columns
		if (this._aggregations) {
			this._renderAggregations();
		}

		// Collapse all expanded details rows when breakpoint changes
		this._collapseAllDetails();

		if (this.config.debug) {
			console.log('[Funky.Table] After _collapseAllDetails, tbody rows:', this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr').length : 0);
		}
	};

	/**
	 * Get breakpoint priority number
	 */
	TableInstance.prototype._getBreakpointPriority = function(breakpoint) {
		var priorities = {
			'desktop': 1,
			'laptop': 2,
			'tablet-l': 3,
			'tablet': 4,
			'mobile-l': 5,
			'mobile': 6
		};
		return priorities[breakpoint] || 1;
	};

	/**
	 * Get maximum priority to show at breakpoint
	 * Priority scale: 1-10 (lower = more important = stays visible longer)
	 * Columns with no responsivePriority always remain visible
	 */
	TableInstance.prototype._getMaxPriorityForBreakpoint = function(breakpoint) {
		// Threshold = maximum priority value to SHOW at this breakpoint
		// Lower priority number = more important = stays visible longer
		// Columns with priority > threshold will be hidden
		// At desktop (widest), threshold is high - show all columns
		// At mobile (narrowest), threshold is low - only priority 1-2 shown
		var thresholds = {
			'desktop': 10000,   // Show all (priority 1-10000)
			'laptop': 6,        // Show priority 1-6
			'tablet-l': 5,      // Show priority 1-5
			'tablet': 4,        // Show priority 1-4
			'mobile-l': 3,      // Show priority 1-3
			'mobile': 2         // Show priority 1-2
		};
		return thresholds[breakpoint] || 10000;
	};

	/**
	 * Apply column visibility to DOM
	 */
	TableInstance.prototype._applyColumnVisibility = function(show, hide) {
		var D = Funky.Dom;
		var self = this;

		// Update column state
		var columns = this.config.columns;
		columns.forEach(function(col, index) {
			col._responsive_hidden = hide.indexOf(index) !== -1;
		});

		// Check if any columns are being hidden (responsive mode active)
		var hasHiddenColumns = hide.length > 0;

		// Headers - update visibility and widths
		if (this._headerRow) {
			var headers = this._headerRow.querySelectorAll('th');
			for (var i = 0; i < headers.length; i++) {
				var th = headers[i];
				var index = parseInt(th.getAttribute('data-column-index'), 10);
				if (!isNaN(index)) {
					if (hide.indexOf(index) !== -1) {
						th.classList.add('funky-table-hidden');
					} else {
						th.classList.remove('funky-table-hidden');
						// When responsive mode is active, clear fixed widths so columns can expand
						// When back to desktop, restore original widths
						if (hasHiddenColumns) {
							// Store original width if not already stored
							if (!th.hasAttribute('data-original-width') && th.style.width) {
								th.setAttribute('data-original-width', th.style.width);
							}
							th.style.width = '';
						} else {
							// Restore original width if we stored one
							var originalWidth = th.getAttribute('data-original-width');
							if (originalWidth) {
								th.style.width = originalWidth;
							}
						}
					}
				}
			}
		}

		// Body cells
		if (this.tbody && this.tbody.el) {
			var rows = this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)');
			for (var r = 0; r < rows.length; r++) {
				var cells = rows[r].querySelectorAll('td');
				for (var c = 0; c < cells.length; c++) {
					var td = cells[c];
					var colIndex = parseInt(td.getAttribute('data-column-index'), 10);
					if (!isNaN(colIndex)) {
						if (hide.indexOf(colIndex) !== -1) {
							td.classList.add('funky-table-hidden');
						} else {
							td.classList.remove('funky-table-hidden');
						}
					}
				}
			}
		}

		// Footer cells
		if (this._tfoot) {
			var footerCells = this._tfoot.querySelectorAll('td');
			for (var f = 0; f < footerCells.length; f++) {
				var ftd = footerCells[f];
				var fIndex = parseInt(ftd.getAttribute('data-column-index'), 10);
				if (!isNaN(fIndex)) {
					if (hide.indexOf(fIndex) !== -1) {
						ftd.classList.add('funky-table-hidden');
					} else {
						ftd.classList.remove('funky-table-hidden');
					}
				}
			}
		}
	};

	/**
	 * Update control column visibility
	 */
	TableInstance.prototype._updateControlColumn = function(show) {
		var controlHeader = this._headerRow ? this._headerRow.querySelector('th.funky-table-control-header') : null;
		var controlCells = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('td.funky-table-control-cell') : [];

		if (show) {
			if (controlHeader) controlHeader.classList.remove('funky-table-hidden');
			for (var i = 0; i < controlCells.length; i++) {
				controlCells[i].classList.remove('funky-table-hidden');
			}
		} else {
			if (controlHeader) controlHeader.classList.add('funky-table-hidden');
			for (var j = 0; j < controlCells.length; j++) {
				controlCells[j].classList.add('funky-table-hidden');
			}
		}
	};

	/**
	 * Handle control button click to expand/collapse details
	 */
	TableInstance.prototype._handleControlClick = function(e) {
		var btn = e.target.closest('.funky-table-control-btn');
		if (!btn) return;

		e.stopPropagation();

		var row = btn.closest('tr');
		if (!row) return;

		var rowIndex = parseInt(row.getAttribute('data-index'), 10);
		var isExpanded = row.classList.contains('funky-table-row-expanded');

		if (isExpanded) {
			this._collapseDetails(row);
		} else {
			this._expandDetails(row, rowIndex);
		}
	};

	/**
	 * Expand details row
	 */
	TableInstance.prototype._expandDetails = function(row, rowIndex) {
		var D = Funky.Dom;
		var self = this;
		var rowData = this.displayData ? this.displayData[rowIndex] : this.data[rowIndex];

		if (!rowData) return;

		// Mark as expanded
		row.classList.add('funky-table-row-expanded');
		var btn = row.querySelector('.funky-table-control-btn');
		if (btn) {
			btn.setAttribute('aria-expanded', 'true');
			btn.innerHTML = '<i class="fas fa-minus"></i>';
		}

		// Create details row
		var detailsRow = D.create('tr')
			.classAdd('funky-table-details-row')
			.attr('data-parent-index', rowIndex);

		// Details cell spans all visible columns
		var visibleCount = (this.visibleColumns ? this.visibleColumns.length : this.config.columns.length);
		var detailsCell = D.create('td')
			.classAdd('funky-table-details-cell')
			.attr('colspan', visibleCount);

		detailsRow.append(detailsCell);

		// Build details content from hidden columns
		var detailsList = D.create('ul')
			.classAdd('funky-table-details-list');

		detailsCell.append(detailsList);

		var columns = this.config.columns;
		columns.forEach(function(col, index) {
			if (!col._responsive_hidden) return;
			if (col.name === '_control' || col.type === 'checkbox') return;

			var value = self._getNestedValue(rowData, col.data);
			var displayValue = self._renderCellContent(value, col, rowData, rowIndex);

			var li = D.create('li')
				.classAdd('funky-table-details-item');

			var titleSpan = D.create('span')
				.classAdd('funky-table-details-title')
				.text((col.title || col.data) + ': ');

			var dataSpan = D.create('span')
				.classAdd('funky-table-details-data');

			// Handle HTML content
			if (typeof displayValue === 'string' && displayValue.indexOf('<') !== -1) {
				dataSpan.el.innerHTML = displayValue;
			} else {
				dataSpan.text(displayValue !== null && displayValue !== undefined ? displayValue : '');
			}

			li.append(titleSpan).append(dataSpan);
			detailsList.append(li);
		});

		// Insert after row
		if (row.nextSibling) {
			row.parentNode.insertBefore(detailsRow.el, row.nextSibling);
		} else {
			row.parentNode.appendChild(detailsRow.el);
		}

		// Announce for accessibility
		if (Funky.Announce) {
			Funky.Announce.polite('Row details expanded');
		}
	};

	/**
	 * Collapse details row
	 */
	TableInstance.prototype._collapseDetails = function(row) {
		var rowIndex = row.getAttribute('data-index');

		// Mark as collapsed
		row.classList.remove('funky-table-row-expanded');
		var btn = row.querySelector('.funky-table-control-btn');
		if (btn) {
			btn.setAttribute('aria-expanded', 'false');
			btn.innerHTML = '<i class="fas fa-plus"></i>';
		}

		// Remove details row
		var detailsRow = row.parentNode.querySelector(
			'.funky-table-details-row[data-parent-index="' + rowIndex + '"]'
		);
		if (detailsRow) {
			detailsRow.parentNode.removeChild(detailsRow);
		}

		// Announce for accessibility
		if (Funky.Announce) {
			Funky.Announce.polite('Row details collapsed');
		}
	};

	/**
	 * Collapse all expanded rows
	 */
	TableInstance.prototype._collapseAllDetails = function() {
		if (!this.tbody || !this.tbody.el) return;

		var self = this;
		var expanded = this.tbody.el.querySelectorAll('.funky-table-row-expanded');
		for (var i = 0; i < expanded.length; i++) {
			self._collapseDetails(expanded[i]);
		}
	};

	// =========================================================================
	// Buttons (Phase 15)
	// =========================================================================

	/**
	 * Initialize buttons
	 */
	TableInstance.prototype._initButtons = function() {
		if (!this.config.buttons) return;
		
		// Must have at least one button type enabled
		var hasItems = this.config.buttons.items && this.config.buttons.items.length > 0;
		var hasExport = this.config.buttons.export && this.config.buttons.export.length > 0;
		var hasColvis = this.config.buttons.colvis === true;
		
		if (!hasItems && !hasExport && !hasColvis) return;

		var container = this.config.buttons.container;
		if (typeof container === 'string') {
			container = document.querySelector(container);
		}
		if (!container) {
			container = this._createButtonContainer();
		}

		this._buttonContainer = container;
		this._buttons = [];

		// Load saved column visibility
		this._loadColumnVisibility();

		var self = this;
		
		// Create custom buttons first
		if (hasItems) {
			this.config.buttons.items.forEach(function(config) {
				if (config) { // Filter out null entries
					self._createButton(config, container);
				}
			});
		}
		
		// Add export buttons
		if (hasExport) {
			var exportFormats = this.config.buttons.export;
			exportFormats.forEach(function(format) {
				var exportConfig = {
					type: 'export',
					exportType: format.toLowerCase(),
					text: '<i class="fas fa-file-' + (format === 'xlsx' ? 'excel' : format) + '"></i> ' + format.toUpperCase(),
					className: 'btn-funky btn-funky-secondary',
					title: 'Export as ' + format.toUpperCase()
				};
				self._createButton(exportConfig, container);
			});
		}
		
		// Add column visibility button
		if (hasColvis) {
			var colvisConfig = {
				type: 'columnVisibility',
				text: '<i class="fas fa-columns"></i> Columns',
				className: 'btn-funky btn-funky-secondary',
				title: 'Toggle column visibility'
			};
			self._createButton(colvisConfig, container);
		}

		// Update states initially
		this._updateButtonStates();
	};

	/**
	 * Create default button container
	 */
	TableInstance.prototype._createButtonContainer = function() {
		var D = Funky.Dom;
		
		// Use the toolbar if it exists (preferred)
		if (this.toolbar && this.toolbar.el) {
			var leftGroup = this.toolbar.el.querySelector('.funky-table-toolbar-left');
			if (leftGroup) return leftGroup;
		}
		
		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (!tableEl) return null;
		
		// Use the wrapper we created
		var wrapperEl = this.wrapper ? this.wrapper.el : null;
		if (!wrapperEl) {
			wrapperEl = tableEl.parentNode;
		}
		if (!wrapperEl) return null;
		
		var container = D.create('div')
			.classAdd('funky-table-buttons')
			.classAdd('btn-group')
			.classAdd('mb-3');

		// Prepend to wrapper instead of insertBefore
		wrapperEl.insertBefore(container.el, wrapperEl.firstChild);

		return container.el;
	};

	/**
	 * Create individual button
	 */
	TableInstance.prototype._createButton = function(config, container) {
		var self = this;
		var D = Funky.Dom;

		if (config.type === 'separator') {
			var sep = D.create('div')
				.classAdd('btn-group-separator')
				.style({ width: '1px', background: 'var(--pro-border-color)' });
			D.one(container).append(sep);
			return;
		}

		var btn = D.create('button')
			.classAdd('btn')
			.classAdd(config.className || 'btn-outline-secondary')
			.attr('type', 'button');
		
		// ID attribute
		if (config.id) {
			btn.attr('id', config.id);
		}
		
		// Disabled state
		if (config.disabled) {
			btn.attr('disabled', 'disabled');
		}

		// Icon
		if (config.icon) {
			var icon = D.create('i').classAdd(config.icon);
			btn.append(icon);
			if (config.text) {
				btn.append(D.create('span').text(' ' + config.text));
			}
		} else if (config.text && config.text.indexOf('<') !== -1) {
			// Text contains HTML (like icons)
			btn.html(config.text);
		} else {
			btn.text(config.text || 'Button');
		}

		// Tooltip
		if (config.title) {
			btn.attr('title', config.title);
		}

		// Store reference
		var buttonInfo = {
			element: btn.el,
			config: config
		};
		this._buttons.push(buttonInfo);

		// Click handler
		btn.on('click', function(e) {
			e.preventDefault();
			self._handleButtonClick(config, e);
		});

		// Special button types
		if (config.type === 'columnVisibility') {
			this._setupColumnVisibilityButton(btn, config, container);
			return; // Don't append directly, handled by dropdown setup
		}

		// Dropdown button
		if (config.dropdown && Array.isArray(config.dropdown)) {
			this._setupDropdownButton(btn, config, container);
			return; // Don't append directly, handled by dropdown setup
		}

		D.one(container).append(btn);

		return btn;
	};
	
	/**
	 * Setup dropdown button with menu items
	 */
	TableInstance.prototype._setupDropdownButton = function(btn, config, container) {
		var D = Funky.Dom;
		var self = this;
		
		// Create dropdown wrapper
		var dropdownWrapper = D.create('div')
			.classAdd('dropdown', 'd-inline-block');
		
		// Add button with dropdown toggle
		btn.attr('data-bs-toggle', 'dropdown');
		btn.attr('aria-expanded', 'false');
		dropdownWrapper.append(btn);
		
		// Create dropdown menu
		var menu = D.create('ul').classAdd('dropdown-menu');
		
		config.dropdown.forEach(function(item) {
			var li = D.create('li');
			var a = D.create('a')
				.classAdd('dropdown-item')
				.attr('href', '#');
			
			if (item.text && item.text.indexOf('<') !== -1) {
				a.html(item.text);
			} else {
				a.text(item.text || 'Item');
			}
			
			a.on('click', function(e) {
				e.preventDefault();
				if (typeof item.action === 'function') {
					item.action.call(null, e, self);
				}
			});
			
			li.append(a);
			menu.append(li);
		});
		
		dropdownWrapper.append(menu);
		D.one(container).append(dropdownWrapper);
		
		return dropdownWrapper;
	};

	/**
	 * Handle button click
	 */
	TableInstance.prototype._handleButtonClick = function(config, e) {
		switch (config.type) {
			case 'export':
				this._handleExport(config);
				break;
			case 'columnVisibility':
				// Handled by dropdown
				break;
			case 'custom':
			default:
				// Call action function for custom type or any button with an action
				if (typeof config.action === 'function') {
					config.action.call(null, e, this);
				}
				break;
		}
	};

	/**
	 * Update button states (enabled/disabled)
	 */
	TableInstance.prototype._updateButtonStates = function() {
		var self = this;

		if (!this._buttons) return;

		this._buttons.forEach(function(btnInfo) {
			if (typeof btnInfo.config.enabled === 'function') {
				var isEnabled = btnInfo.config.enabled(self);
				btnInfo.element.disabled = !isEnabled;
				Funky.Dom.one(btnInfo.element).classToggle('disabled', !isEnabled);
			}
		});
	};

	// =========================================================================
	// Export (Phase 15)
	// =========================================================================

	/**
	 * Handle export
	 */
	TableInstance.prototype._handleExport = function(config) {
		var format = config.format || config.exportType || 'csv';

		// Server-side export
		if (config.serverExport) {
			this._serverExport(config);
			return;
		}

		// Client-side export
		switch (format) {
			case 'csv':
				this._exportCSV(config);
				break;
			case 'xlsx':
				this._exportXLSX(config);
				break;
			case 'json':
				this._exportJSON(config);
				break;
		}
	};

	/**
	 * Client-side CSV export
	 */
	TableInstance.prototype._exportCSV = function(config) {
		config = config || {};
		var self = this;
		var rows = [];
		var columns = this.config.columns.filter(function(col) {
			return col.visible !== false && col.type !== 'checkbox' && col.exportable !== false;
		});

		// Header row
		var headers = columns.map(function(col) {
			return self._escapeCSV(col.title || col.data);
		});
		rows.push(headers.join(','));

		// Data rows
		this.data.forEach(function(row) {
			var values = columns.map(function(col) {
				var value = self._getNestedValue(row, col.data);

				// Apply export renderer if provided
				if (typeof col.exportRender === 'function') {
					value = col.exportRender(value, row);
				} else if (col.type === 'date' && value) {
					value = self._formatExportDate(value);
				} else if (col.type === 'money' && value !== null) {
					value = parseFloat(value).toFixed(2);
				}

				return self._escapeCSV(value);
			});
			rows.push(values.join(','));
		});

		var csv = rows.join('\n');
		var filename = (config.filename || this.config.tableName || 'export') + '_' + this._getTimestamp() + '.csv';

		this._downloadFile(csv, filename, 'text/csv;charset=utf-8');

		// Also call legacy callback if present
		if (typeof this.config.onExportCSV === 'function') {
			this.config.onExportCSV(this.searchQuery, this);
		}
	};

	/**
	 * Escape value for CSV
	 */
	TableInstance.prototype._escapeCSV = function(value) {
		if (value === null || value === undefined) return '';

		var str = String(value);

		// Escape quotes and wrap if contains special chars
		if (str.indexOf('"') !== -1 || str.indexOf(',') !== -1 || str.indexOf('\n') !== -1) {
			str = '"' + str.replace(/"/g, '""') + '"';
		}

		return str;
	};

	/**
	 * Client-side XLSX export (requires SheetJS)
	 */
	TableInstance.prototype._exportXLSX = function(config) {
		config = config || {};

		if (typeof XLSX === 'undefined') {
			console.error('[Funky.Table] XLSX library not loaded');
			if (Funky.Notify) {
				Funky.Notify.error('Excel export not available');
			}
			return;
		}

		var self = this;
		var columns = this.config.columns.filter(function(col) {
			return col.visible !== false && col.type !== 'checkbox' && col.exportable !== false;
		});

		// Build worksheet data
		var wsData = [];

		// Headers
		var headers = columns.map(function(col) {
			return col.title || col.data;
		});
		wsData.push(headers);

		// Data
		this.data.forEach(function(row) {
			var values = columns.map(function(col) {
				var value = self._getNestedValue(row, col.data);

				if (typeof col.exportRender === 'function') {
					value = col.exportRender(value, row);
				}

				return value;
			});
			wsData.push(values);
		});

		// Create workbook
		var ws = XLSX.utils.aoa_to_sheet(wsData);
		var wb = XLSX.utils.book_new();
		XLSX.utils.book_append_sheet(wb, ws, config.sheetName || 'Data');

		// Download
		var filename = (config.filename || this.config.tableName || 'export') + '_' + this._getTimestamp() + '.xlsx';
		XLSX.writeFile(wb, filename);

		// Also call legacy callback if present
		if (typeof this.config.onExportExcel === 'function') {
			this.config.onExportExcel(this.searchQuery, this);
		}
	};

	/**
	 * JSON export
	 */
	TableInstance.prototype._exportJSON = function(config) {
		config = config || {};
		var columns = this.config.columns.filter(function(col) {
			return col.visible !== false && col.type !== 'checkbox' && col.exportable !== false;
		});

		var self = this;
		var exportData = this.data.map(function(row) {
			var obj = {};
			columns.forEach(function(col) {
				var key = col.data;
				obj[key] = self._getNestedValue(row, col.data);
			});
			return obj;
		});

		var json = JSON.stringify(exportData, null, 2);
		var filename = (config.filename || this.config.tableName || 'export') + '_' + this._getTimestamp() + '.json';

		this._downloadFile(json, filename, 'application/json');
	};

	/**
	 * Server-side export
	 */
	TableInstance.prototype._serverExport = function(config) {
		var params = {};

		// Copy extra ajax data
		if (this.config.extraAjaxData) {
			for (var key in this.config.extraAjaxData) {
				if (this.config.extraAjaxData.hasOwnProperty(key)) {
					params[key] = this.config.extraAjaxData[key];
				}
			}
		}

		params.search = this.searchQuery || '';
		params.sort = this.sortColumn || '';
		params.sort_dir = this.sortDirection || '';
		params.format = config.format || 'xlsx';

		var url = config.serverUrl || this.config.ajaxUrl + '/export';
		var queryParts = [];

		for (var k in params) {
			if (params.hasOwnProperty(k)) {
				var value = params[k];
				if (Array.isArray(value)) {
					value.forEach(function(v) {
						queryParts.push(encodeURIComponent(k) + '[]=' + encodeURIComponent(v));
					});
				} else {
					queryParts.push(encodeURIComponent(k) + '=' + encodeURIComponent(value));
				}
			}
		}

		var queryString = queryParts.join('&');

		// Open in new window/tab
		window.open(url + '?' + queryString, '_blank');
	};

	/**
	 * Download file helper
	 */
	TableInstance.prototype._downloadFile = function(content, filename, mimeType) {
		var blob = new Blob([content], { type: mimeType });
		var url = URL.createObjectURL(blob);

		var link = document.createElement('a');
		link.href = url;
		link.download = filename;
		link.style.display = 'none';

		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);

		URL.revokeObjectURL(url);
	};

	/**
	 * Get timestamp for filename
	 */
	TableInstance.prototype._getTimestamp = function() {
		var now = new Date();
		var pad = function(n) { return n < 10 ? '0' + n : n; };

		return now.getFullYear() +
		       pad(now.getMonth() + 1) +
		       pad(now.getDate()) + '_' +
		       pad(now.getHours()) +
		       pad(now.getMinutes()) +
		       pad(now.getSeconds());
	};

	/**
	 * Format date for export
	 */
	TableInstance.prototype._formatExportDate = function(value) {
		if (!value) return '';

		var date = new Date(value);
		if (isNaN(date.getTime())) return value;

		var pad = function(n) { return n < 10 ? '0' + n : n; };

		return date.getFullYear() + '-' +
		       pad(date.getMonth() + 1) + '-' +
		       pad(date.getDate()) + ' ' +
		       pad(date.getHours()) + ':' +
		       pad(date.getMinutes());
	};

	// =========================================================================
	// Column Visibility (Phase 15)
	// =========================================================================

	/**
	 * Setup column visibility dropdown
	 */
	TableInstance.prototype._setupColumnVisibilityButton = function(btn, config, container) {
		var self = this;
		var D = Funky.Dom;

		// Create dropdown
		var dropdown = D.create('div')
			.classAdd('funky-column-visibility-dropdown')
			.classAdd('dropdown-menu')
			.style({ minWidth: '200px', padding: '0.5rem' });

		// Use processed columns array (includes control column if responsive)
		// This ensures indices match the actual DOM
		this.columns.forEach(function(col, index) {
			// Skip control column and checkbox columns
			if (col.type === 'checkbox' || col.name === '_control') return;
			if (col.hideable === false) return;

			var item = D.create('label')
				.classAdd('dropdown-item')
				.classAdd('d-flex')
				.classAdd('align-items-center')
				.style({ cursor: 'pointer', userSelect: 'none' });

			var checkbox = D.create('input')
				.attr('type', 'checkbox')
				.attr('data-column-index', index)
				.classAdd('form-check-input')
				.classAdd('me-2');

			if (col.visible !== false) {
				checkbox.attr('checked', 'checked');
			}

			var label = D.create('span').text(col.title || col.data);

			item.append(checkbox).append(label);

			checkbox.on('change', function() {
				self._toggleColumnVisibility(index, this.checked);
			});

			dropdown.append(item);
		});

		// Create dropdown wrapper
		var dropdownWrapper = D.create('div')
			.classAdd('dropdown')
			.classAdd('d-inline-block');

		btn.classAdd('dropdown-toggle');
		btn.attr('data-bs-toggle', 'dropdown');
		btn.attr('aria-expanded', 'false');

		// Add button and dropdown to wrapper
		dropdownWrapper.append(btn);
		dropdownWrapper.append(dropdown);

		D.one(container).append(dropdownWrapper);
	};

	/**
	 * Toggle column visibility
	 */
	TableInstance.prototype._toggleColumnVisibility = function(columnIndex, visible) {
		// Use processed columns array (includes control column if responsive)
		var column = this.columns[columnIndex];
		if (!column) return;

		column.visible = visible;
		
		// Also update original config columns if this column exists there
		if (this.config.columns) {
			var configCol = this.config.columns.find(function(c) {
				return c.data === column.data;
			});
			if (configCol) {
				configCol.visible = visible;
			}
		}

		// Update header using data-column-index attribute
		if (this._headerRow) {
			var headerCell = this._headerRow.querySelector('th[data-column-index="' + columnIndex + '"]');
			if (headerCell) {
				headerCell.style.display = visible ? '' : 'none';
			}
		}

		// Update all body cells using data-column-index attribute
		if (this.tbody && this.tbody.el) {
			var bodyCells = this.tbody.el.querySelectorAll('td[data-column-index="' + columnIndex + '"]');
			for (var i = 0; i < bodyCells.length; i++) {
				bodyCells[i].style.display = visible ? '' : 'none';
			}
		}

		// Update footer if exists
		if (this._tfoot) {
			var footerCells = this._tfoot.querySelectorAll('td[data-column-index="' + columnIndex + '"]');
			for (var j = 0; j < footerCells.length; j++) {
				footerCells[j].style.display = visible ? '' : 'none';
			}
		}

		// Store preference
		this._saveColumnVisibility();
		
		// Recalculate responsive layout
		if (this.config.responsive) {
			this._determineBreakpoint(true);
		}

		// Emit event
		this._emit('columnVisibility', {
			columnIndex: columnIndex,
			column: column,
			visible: visible
		});
	};

	/**
	 * Save column visibility to localStorage
	 */
	TableInstance.prototype._saveColumnVisibility = function() {
		if (!this.config.stateStorage) return;
		if (!this.config.tableName) return;

		var key = 'funky_table_columns_' + this.config.tableName;
		var visibility = {};

		this.config.columns.forEach(function(col) {
			if (col.data) {
				visibility[col.data] = col.visible !== false;
			}
		});

		try {
			localStorage.setItem(key, JSON.stringify(visibility));
		} catch (e) {
			// localStorage not available
		}
	};

	/**
	 * Load column visibility from localStorage
	 */
	TableInstance.prototype._loadColumnVisibility = function() {
		if (!this.config.stateStorage) return;
		if (!this.config.tableName) return;

		var key = 'funky_table_columns_' + this.config.tableName;

		try {
			var saved = localStorage.getItem(key);
			if (saved) {
				var visibility = JSON.parse(saved);
				var self = this;

				this.config.columns.forEach(function(col) {
					if (col.data && visibility.hasOwnProperty(col.data)) {
						col.visible = visibility[col.data];
					}
				});
			}
		} catch (e) {
			// localStorage not available
		}
	};

	// =========================================================================
	// Animations (Phase 16)
	// =========================================================================

	/**
	 * Default animation config
	 */
	var DEFAULT_ANIMATION_CONFIG = {
		enabled: true,
		highlightDuration: 2000,
		removeDuration: 300,
		insertDuration: 300,
		highlightClass: 'funky-table-row-highlight',
		removeClass: 'funky-table-row-removing',
		insertClass: 'funky-table-row-inserting'
	};

	/**
	 * Initialize animations
	 */
	TableInstance.prototype._initAnimations = function() {
		// Animations are enabled by default
		// Config can override via this.config.animations
	};

	/**
	 * Get animation config with defaults
	 */
	TableInstance.prototype._getAnimationConfig = function() {
		var config = {};
		var defaults = DEFAULT_ANIMATION_CONFIG;
		var userConfig = this.config.animations || {};

		for (var key in defaults) {
			if (defaults.hasOwnProperty(key)) {
				config[key] = userConfig.hasOwnProperty(key) ? userConfig[key] : defaults[key];
			}
		}

		return config;
	};

	/**
	 * Highlight a row by ID
	 * @param {string|number} id - Row ID
	 * @param {string} type - 'update', 'create', 'success', 'warning', 'error'
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.highlightRow = function(id, type) {
		var config = this._getAnimationConfig();
		if (!config.enabled) return this;

		var row = this._findRowById(id);
		if (!row) return this;

		var D = Funky.Dom;
		var baseClass = config.highlightClass;
		var typeClass = baseClass + '--' + (type || 'update');

		// Remove existing highlight classes
		D.one(row)
			.classRemove(baseClass)
			.classRemove(baseClass + '--update')
			.classRemove(baseClass + '--create')
			.classRemove(baseClass + '--success')
			.classRemove(baseClass + '--warning')
			.classRemove(baseClass + '--error');

		// Force reflow to restart animation
		void row.offsetWidth;

		// Add highlight
		D.one(row).classAdd(baseClass).classAdd(typeClass);

		// Remove after duration
		var self = this;
		setTimeout(function() {
			if (row && row.parentNode) {
				D.one(row).classRemove(baseClass).classRemove(typeClass);
			}
		}, config.highlightDuration);

		return this;
	};

	/**
	 * Highlight multiple rows
	 * @param {Array} ids - Array of row IDs
	 * @param {string} type - Highlight type
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.highlightRows = function(ids, type) {
		var self = this;
		ids.forEach(function(id) {
			self.highlightRow(id, type);
		});
		return this;
	};

	/**
	 * Find row element by ID
	 * @param {string|number} id - Row ID
	 * @returns {HTMLElement|null}
	 */
	TableInstance.prototype._findRowById = function(id) {
		if (!this.tbody || !this.tbody.el) return null;

		var rows = this.tbody.el.querySelectorAll('tr[data-id]');
		for (var i = 0; i < rows.length; i++) {
			if (rows[i].getAttribute('data-id') == id) {
				return rows[i];
			}
		}
		return null;
	};

	/**
	 * Remove row with animation
	 * @param {string|number} id - Row ID
	 * @param {Function} callback - Called after removal complete
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.removeRowAnimated = function(id, callback) {
		var row = this._findRowById(id);
		if (!row) {
			if (callback) callback();
			return this;
		}

		var config = this._getAnimationConfig();
		var D = Funky.Dom;

		if (!config.enabled) {
			this._removeRowFromDomAnimated(row);
			this._removeFromData(id);
			if (callback) callback();
			return this;
		}

		var self = this;

		// Add removing class for animation
		D.one(row)
			.classAdd(config.removeClass)
			.style({
				transition: 'all ' + config.removeDuration + 'ms ease-out',
				opacity: '0',
				transform: 'translateX(-20px)'
			});

		// Wait for animation
		setTimeout(function() {
			self._removeRowFromDomAnimated(row);
			self._removeFromData(id);

			// Update pagination info
			self._updateInfo();
			self._updatePagination();

			if (callback) callback();
		}, config.removeDuration);

		return this;
	};

	/**
	 * Remove multiple rows with staggered animation
	 * @param {Array} ids - Array of row IDs
	 * @param {Function} callback - Called after all removed
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.removeRowsAnimated = function(ids, callback) {
		var self = this;
		var config = this._getAnimationConfig();
		var staggerDelay = 50;

		if (!config.enabled || ids.length === 0) {
			ids.forEach(function(id) {
				var row = self._findRowById(id);
				if (row) {
					self._removeRowFromDomAnimated(row);
					self._removeFromData(id);
				}
			});
			if (callback) callback();
			return this;
		}

		var completed = 0;

		ids.forEach(function(id, index) {
			setTimeout(function() {
				self.removeRowAnimated(id, function() {
					completed++;
					if (completed === ids.length && callback) {
						callback();
					}
				});
			}, index * staggerDelay);
		});

		return this;
	};

	/**
	 * Remove row from DOM (animation version)
	 * @param {HTMLElement} row - Row element
	 */
	TableInstance.prototype._removeRowFromDomAnimated = function(row) {
		if (row && row.parentNode) {
			row.parentNode.removeChild(row);
		}
	};

	/**
	 * Remove from internal data
	 * @param {string|number} id - Row ID
	 */
	TableInstance.prototype._removeFromData = function(id) {
		var idField = this.config.idField || 'id';
		this.data = this.data.filter(function(item) {
			return item[idField] != id;
		});
		this.totalRecords = Math.max(0, this.totalRecords - 1);
	};

	/**
	 * Insert row with animation
	 * @param {Object} rowData - Row data
	 * @param {Object} options - Insert options
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.insertRowAnimated = function(rowData, options) {
		options = options || {};
		var position = options.position || 'top';
		var highlight = options.highlight !== false;

		var config = this._getAnimationConfig();
		var idField = this.config.idField || 'id';
		var D = Funky.Dom;

		// Add to data
		if (position === 'top') {
			this.data.unshift(rowData);
		} else {
			this.data.push(rowData);
		}
		this.totalRecords++;

		// Create row
		var dataIndex = position === 'top' ? 0 : this.data.length - 1;
		var rowEl = this._renderRow(rowData, dataIndex).el;

		if (config.enabled) {
			// Start invisible
			D.one(rowEl)
				.classAdd(config.insertClass)
				.style({
					opacity: '0',
					transform: 'translateY(-10px)'
				});
		}

		// Insert into DOM
		if (position === 'top') {
			if (this.tbody && this.tbody.el && this.tbody.el.firstChild) {
				this.tbody.el.insertBefore(rowEl, this.tbody.el.firstChild);
			} else if (this.tbody && this.tbody.el) {
				this.tbody.el.appendChild(rowEl);
			}
		} else {
			if (this.tbody && this.tbody.el) {
				this.tbody.el.appendChild(rowEl);
			}
		}

		// Animate in
		if (config.enabled) {
			var self = this;
			// Force reflow
			void rowEl.offsetWidth;

			D.one(rowEl).style({
				transition: 'all ' + config.insertDuration + 'ms ease-out',
				opacity: '1',
				transform: 'translateY(0)'
			});

			setTimeout(function() {
				D.one(rowEl)
					.classRemove(config.insertClass)
					.style({ transition: '', transform: '' });

				// Highlight after insert animation
				if (highlight) {
					self.highlightRow(rowData[idField], 'create');
				}
			}, config.insertDuration);
		}

		// Apply responsive visibility to new row
		if (this.config.responsive) {
			var controlColumnVisible = this.hiddenColumns && this.hiddenColumns.length > 0;
			
			// Hide/show control cell based on whether there are hidden columns
			var controlCell = rowEl.querySelector('td.funky-table-control-cell');
			if (controlCell) {
				if (controlColumnVisible) {
					controlCell.classList.remove('funky-table-hidden');
				} else {
					controlCell.classList.add('funky-table-hidden');
				}
			}
			
			// Hide columns that are responsively hidden
			if (this.hiddenColumns && this.hiddenColumns.length > 0) {
				var cells = rowEl.querySelectorAll('td');
				for (var c = 0; c < cells.length; c++) {
					var td = cells[c];
					var colIndex = parseInt(td.getAttribute('data-column-index'), 10);
					if (!isNaN(colIndex) && this.hiddenColumns.indexOf(colIndex) !== -1) {
						td.classList.add('funky-table-hidden');
					}
				}
			}
		}

		// Update pagination and info
		this._updateInfo();
		this._updatePagination();

		return this;
	};

	/**
	 * Update row with animation
	 * @param {Object} rowData - Updated row data
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.updateRowAnimated = function(rowData) {
		var idField = this.config.idField || 'id';
		var id = rowData[idField];

		// Update data
		var index = this._findDataIndexById(id);
		if (index !== -1) {
			for (var key in rowData) {
				if (rowData.hasOwnProperty(key)) {
					this.data[index][key] = rowData[key];
				}
			}
		}

		// Update DOM
		var existingRow = this._findRowById(id);
		if (existingRow) {
			var newRow = this._renderRow(this.data[index] || rowData, index).el;

			// Copy over row index
			newRow.setAttribute('data-index', existingRow.getAttribute('data-index'));

			// Replace in DOM
			existingRow.parentNode.replaceChild(newRow, existingRow);

			// Highlight
			this.highlightRow(id, 'update');
		}

		return this;
	};

	/**
	 * Find data index by ID
	 * @param {string|number} id - Row ID
	 * @returns {number}
	 */
	TableInstance.prototype._findDataIndexById = function(id) {
		var idField = this.config.idField || 'id';
		for (var i = 0; i < this.data.length; i++) {
			if (this.data[i][idField] == id) {
				return i;
			}
		}
		return -1;
	};

	// =========================================================================
	// WebSocket Integration (Phase 16)
	// =========================================================================

	/**
	 * Initialize WebSocket listeners
	 */
	TableInstance.prototype._initWebSocket = function() {
		if (!this.config.websocket || !this.config.websocket.enabled) return;
		if (!Funky.Events) {
			console.warn('[Funky.Table] Funky.Events required for WebSocket integration');
			return;
		}

		var wsConfig = this.config.websocket;
		var events = wsConfig.events || {};
		var self = this;

		// Store event handlers for cleanup
		this._wsHandlers = {};

		// Create event
		if (events.create) {
			this._wsHandlers.create = function(data) {
				self._handleWebSocketCreate(data);
			};
			Funky.Events.on(events.create, this._wsHandlers.create);
		}

		// Update event
		if (events.update) {
			this._wsHandlers.update = function(data) {
				self._handleWebSocketUpdate(data);
			};
			Funky.Events.on(events.update, this._wsHandlers.update);
		}

		// Delete event
		if (events.delete) {
			this._wsHandlers.delete = function(data) {
				self._handleWebSocketDelete(data);
			};
			Funky.Events.on(events.delete, this._wsHandlers.delete);
		}

		// Bulk refresh event
		if (events.refresh) {
			this._wsHandlers.refresh = function(data) {
				self.reload();
			};
			Funky.Events.on(events.refresh, this._wsHandlers.refresh);
		}
	};

	/**
	 * Handle WebSocket create event
	 * @param {Object} data - Event data
	 */
	TableInstance.prototype._handleWebSocketCreate = function(data) {
		var rowData = this._extractRowData(data);
		if (!rowData) return;

		// Check if matches current filters
		if (this.config.websocket.filterCheck) {
			if (!this.config.websocket.filterCheck(rowData, this.getFilters())) {
				return;
			}
		}

		this.insertRowAnimated(rowData, {
			position: 'top',
			highlight: true
		});

		// Emit event
		this._emit('rowCreated', { data: rowData });
	};

	/**
	 * Handle WebSocket update event
	 * @param {Object} data - Event data
	 */
	TableInstance.prototype._handleWebSocketUpdate = function(data) {
		var rowData = this._extractRowData(data);
		if (!rowData) return;

		var idField = this.config.idField || 'id';
		var id = rowData[idField];

		// Check if row exists in current view
		var existingIndex = this._findDataIndexById(id);
		if (existingIndex === -1) {
			// Row not in current view - ignore
			return;
		}

		this.updateRowAnimated(rowData);

		// Emit event
		this._emit('rowUpdated', { data: rowData });
	};

	/**
	 * Handle WebSocket delete event
	 * @param {Object} data - Event data
	 */
	TableInstance.prototype._handleWebSocketDelete = function(data) {
		var idField = this.config.idField || 'id';
		var id = data[idField] || data.id || data;

		this.removeRowAnimated(id);

		// Emit event
		this._emit('rowDeleted', { id: id });
	};

	/**
	 * Extract row data from WebSocket message
	 * @param {Object} data - Event data
	 * @returns {Object|null}
	 */
	TableInstance.prototype._extractRowData = function(data) {
		// Handle nested data (e.g., { trade: {...} })
		var tableName = this.config.tableName;
		if (tableName && data[tableName]) {
			return data[tableName];
		}

		// Handle singular form (trades -> trade)
		var singular = tableName ? tableName.replace(/s$/, '') : null;
		if (singular && data[singular]) {
			return data[singular];
		}

		// Assume data is the row itself
		return data;
	};

	/**
	 * Cleanup WebSocket handlers
	 */
	TableInstance.prototype._destroyWebSocket = function() {
		if (!this._wsHandlers || !Funky.Events) return;

		var events = this.config.websocket && this.config.websocket.events || {};

		if (events.create && this._wsHandlers.create) {
			Funky.Events.off(events.create, this._wsHandlers.create);
		}
		if (events.update && this._wsHandlers.update) {
			Funky.Events.off(events.update, this._wsHandlers.update);
		}
		if (events.delete && this._wsHandlers.delete) {
			Funky.Events.off(events.delete, this._wsHandlers.delete);
		}
		if (events.refresh && this._wsHandlers.refresh) {
			Funky.Events.off(events.refresh, this._wsHandlers.refresh);
		}

		this._wsHandlers = null;
	};

	// =========================================================================
	// Accessibility - Phase 19
	// =========================================================================

	/**
	 * Default accessibility configuration
	 */
	var DEFAULT_A11Y_CONFIG = {
		enabled: true,
		announceLoading: true,
		announceSort: true,
		announcePageChange: true,
		announceSelection: true,
		keyboardNavigation: true,
		ariaLabel: null,
		rowLabel: null
	};

	/**
	 * Get accessibility config
	 */
	TableInstance.prototype._getA11yConfig = function() {
		var config = {};
		for (var key in DEFAULT_A11Y_CONFIG) {
			if (DEFAULT_A11Y_CONFIG.hasOwnProperty(key)) {
				config[key] = DEFAULT_A11Y_CONFIG[key];
			}
		}
		var userConfig = this.config.accessibility || {};
		for (var uKey in userConfig) {
			if (userConfig.hasOwnProperty(uKey)) {
				config[uKey] = userConfig[uKey];
			}
		}
		return config;
	};

	/**
	 * Initialize accessibility features
	 */
	TableInstance.prototype._initAccessibility = function() {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.enabled) return;

		// Store current focus position
		this._focusedCell = { row: 0, col: 0 };
		this._focusTrapEnabled = false;

		// Add ARIA attributes
		this._addAriaAttributes();

		// Create live region for announcements
		this._createLiveRegion();

		// Init keyboard navigation
		if (a11yConfig.keyboardNavigation) {
			this._initKeyboardNavigation();
		}
	};

	/**
	 * Generate unique ID for ARIA relationships
	 */
	TableInstance.prototype._generateId = function(suffix) {
		var tableId = this.id || 'table-' + (this._instanceId || Date.now());
		return tableId + '-' + suffix;
	};

	/**
	 * Get table description for screen readers
	 */
	TableInstance.prototype._getTableDescription = function() {
		var visibleColumns = this.config.columns.filter(function(col) {
			return col.visible !== false;
		});

		return 'Interactive data table with ' + visibleColumns.length + ' columns. ' +
			   'Use arrow keys to navigate cells. ' +
			   'Press Enter to select a row. ' +
			   'Press Space to toggle row selection.';
	};

	/**
	 * Add ARIA attributes to table structure
	 */
	TableInstance.prototype._addAriaAttributes = function() {
		var wrapper = this.wrapper;
		var table = this.tableEl ? this.tableEl.el : null;
		var a11yConfig = this._getA11yConfig();

		// Guard against missing table element
		if (!table) {
			if (this.config.debug) {
				console.warn('[Funky.Table] Cannot add ARIA attributes - table element not found');
			}
			return;
		}

		// Table role
		table.setAttribute('role', 'grid');
		table.setAttribute('aria-label', a11yConfig.ariaLabel || this.config.ariaLabel || (this.config.tableName ? this.config.tableName + ' data table' : 'Data table'));
		table.setAttribute('aria-describedby', this._generateId('description'));
		table.setAttribute('aria-busy', 'false');

		// Multi-select support
		if (this.config.selectable === 'multi' || (this.config.selection && this.config.selection.mode === 'multi')) {
			table.setAttribute('aria-multiselectable', 'true');
		}

		// Create description element
		var description = D.create('div')
			.attr('id', this._generateId('description'))
			.classAdd('visually-hidden')
			.text(this._getTableDescription());
		if (wrapper) {
			wrapper.prepend(description);
		}

		// Header row
		var headerRow = this.thead ? this.thead.el.querySelector('tr') : null;
		if (headerRow) {
			headerRow.setAttribute('role', 'row');

			var headerCells = headerRow.querySelectorAll('th');
			var self = this;
			headerCells.forEach(function(th, index) {
				th.setAttribute('role', 'columnheader');
				th.setAttribute('scope', 'col');
				th.setAttribute('aria-colindex', index + 1);

				// Create hidden column description
				var colDesc = D.create('span')
					.attr('id', self._generateId('col-' + index))
					.classAdd('visually-hidden')
					.text(th.textContent || 'Column ' + (index + 1));
				
				// Safely append - use native DOM if D.one returns null
				var thWrapper = D.one(th);
				if (thWrapper && thWrapper.append) {
					thWrapper.append(colDesc);
				} else if (colDesc.el) {
					th.appendChild(colDesc.el);
				}

				// Sortable columns
				if (th.classList.contains('sortable')) {
					th.setAttribute('aria-sort', 'none');
				}
			});
		}

		// Thead
		var thead = table.querySelector('thead');
		if (thead) {
			thead.setAttribute('role', 'rowgroup');
		}

		// Tbody
		var tbody = this.tbody ? this.tbody.el : null;
		if (tbody) {
			tbody.setAttribute('role', 'rowgroup');
		}
	};

	/**
	 * Update ARIA sort attribute
	 */
	TableInstance.prototype._updateAriaSortState = function() {
		var headerRow = this.thead ? this.thead.el.querySelector('tr') : null;
		if (!headerRow) return;

		var headerCells = headerRow.querySelectorAll('th[aria-sort]');
		var self = this;

		headerCells.forEach(function(th) {
			var columnData = th.getAttribute('data-column');
			var sortState = 'none';

			if (columnData === self.sortColumn) {
				sortState = self.sortDirection === 'asc' ? 'ascending' : 'descending';
			}

			th.setAttribute('aria-sort', sortState);
		});
	};

	/**
	 * Add ARIA attributes to data row
	 */
	TableInstance.prototype._addRowAriaAttributes = function(row, rowData, rowIndex) {
		var idField = this.config.idField || 'id';
		var rowId = rowData[idField];

		row.setAttribute('role', 'row');
		row.setAttribute('tabindex', rowIndex === 0 ? '0' : '-1');
		row.setAttribute('aria-rowindex', rowIndex + 1);

		// Selection state - check both legacy 'select' and 'selection' config
		var isSelectable = (this.config.selectable && this.config.selectable !== 'none') ||
		                   (this.config.selection && this.config.selection.mode !== 'none');
		if (isSelectable) {
			var isSelected = this.selectedIds && this.selectedIds.has(String(rowId));
			row.setAttribute('aria-selected', isSelected ? 'true' : 'false');
		}

		// Row label for screen readers
		var rowLabel = this._getRowLabel(rowData);
		if (rowLabel) {
			row.setAttribute('aria-label', rowLabel);
		}

		// Cell attributes
		var cells = row.querySelectorAll('td');
		var self = this;
		cells.forEach(function(td, cellIndex) {
			td.setAttribute('role', 'gridcell');
			td.setAttribute('aria-colindex', cellIndex + 1);
		});
	};

	/**
	 * Get row label from rowLabel config or generate from data
	 */
	TableInstance.prototype._getRowLabel = function(rowData) {
		var a11yConfig = this._getA11yConfig();

		if (typeof a11yConfig.rowLabel === 'function') {
			return a11yConfig.rowLabel(rowData);
		}

		if (typeof a11yConfig.rowLabel === 'string') {
			return this._getNestedValue(rowData, a11yConfig.rowLabel);
		}

		// Try common fields
		return rowData.name || rowData.title || rowData.label || null;
	};

	/**
	 * Update row selection ARIA state
	 */
	TableInstance.prototype._updateRowAriaSelection = function(row, isSelected) {
		if (row) {
			row.setAttribute('aria-selected', isSelected ? 'true' : 'false');
		}
	};

	// =========================================================================
	// Accessibility - Keyboard Navigation
	// =========================================================================

	/**
	 * Setup keyboard navigation
	 */
	TableInstance.prototype._initKeyboardNavigation = function() {
		var self = this;
		var tableEl = this.tableEl ? this.tableEl.el : null;
		var wrapperEl = this.wrapper ? this.wrapper.el : null;
		var containerEl = this.tableContainer ? this.tableContainer.el : null;
		if (!tableEl) {
			return;
		}

		// Main keyboard handler - attach to wrapper to ensure we capture all keyboard events
		// Events bubble up from focused rows -> tbody -> table -> container -> wrapper
		var a11yKeydownHandler = function(e) {
			var activeEl = document.activeElement;
			// Check if focus is within the table structure (table, container, or wrapper)
			var isInTable = (tableEl.contains(activeEl) || activeEl === tableEl);
			var isInContainer = (containerEl && (containerEl.contains(activeEl) || activeEl === containerEl));
			
			
			if (isInTable || isInContainer) {
				self._handleA11yKeyDown(e);
			}
		};
		
		// Attach to wrapper for better event capture
		var targetEl = wrapperEl || tableEl;
		targetEl.addEventListener('keydown', a11yKeydownHandler);
		this._cleanups.push(function() {
			targetEl.removeEventListener('keydown', a11yKeydownHandler);
		});

		// Click handler to update _focusedCell.row when user clicks a row
		var clickHandler = function(e) {
			var row = e.target.closest('tr[role="row"]');
			var tbodyEl = self.tbody ? self.tbody.el : null;
			if (row && tbodyEl && row.parentNode === tbodyEl) {
				var rows = Array.prototype.slice.call(tbodyEl.querySelectorAll('tr:not(.funky-table-details-row)'));
				var index = rows.indexOf(row);
				if (index !== -1) {
					self._focusedCell.row = index;
				}
			}
		};
		targetEl.addEventListener('click', clickHandler);
		this._cleanups.push(function() {
			targetEl.removeEventListener('click', clickHandler);
		});

		// Focus management - use wrapper for consistent event handling
		var focusInHandler = function(e) {
			// Only handle if focus is on table element or inside it
			if (e.target === tableEl || tableEl.contains(e.target)) {
				self._handleFocusIn(e);
			}
		};
		targetEl.addEventListener('focusin', focusInHandler);
		this._cleanups.push(function() {
			targetEl.removeEventListener('focusin', focusInHandler);
		});

		// Clear focus styling when focus leaves table entirely
		var focusOutHandler = function(e) {
			// Check if focus is moving outside the wrapper
			if (!targetEl.contains(e.relatedTarget)) {
				self._clearFocusStyling();
			}
		};
		targetEl.addEventListener('focusout', focusOutHandler);
		this._cleanups.push(function() {
			targetEl.removeEventListener('focusout', focusOutHandler);
		});
	};

	/**
	 * Handle keyboard events for accessibility
	 */
	TableInstance.prototype._handleA11yKeyDown = function(e) {
		var key = e.key;
		var handled = false;
		var self = this;

		// Set keyboard navigation flag for arrow keys
		var isArrowKey = ['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'PageUp', 'PageDown'].indexOf(key) !== -1;
		if (isArrowKey) {
			this._keyboardNavigating = true;
			// Clear flag after navigation completes
			setTimeout(function() {
				self._keyboardNavigating = false;
			}, 50);
		}

		switch (key) {
			case 'ArrowDown':
				handled = this._moveFocus(1, 0);
				break;

			case 'ArrowUp':
				handled = this._moveFocus(-1, 0);
				break;

			case 'ArrowRight':
				handled = this._moveFocus(0, 1);
				break;

			case 'ArrowLeft':
				handled = this._moveFocus(0, -1);
				break;

			case 'Home':
				if (e.ctrlKey) {
					handled = this._focusFirstRow();
				} else {
					handled = this._focusFirstCell();
				}
				break;

			case 'End':
				if (e.ctrlKey) {
					handled = this._focusLastRow();
				} else {
					handled = this._focusLastCell();
				}
				break;

			case 'PageDown':
				handled = this._moveFocus(10, 0);
				break;

			case 'PageUp':
				handled = this._moveFocus(-10, 0);
				break;

			case 'Enter':
				handled = this._activateFocusedRow();
				break;

			case ' ':
				handled = this._toggleFocusedRowSelection();
				break;

			case 'a':
				if (e.ctrlKey || e.metaKey) {
					handled = this._selectAllRows();
				}
				break;

			case 'Escape':
				handled = this._clearSelectionAndFocus();
				break;
		}

		if (handled) {
			e.preventDefault();
			e.stopPropagation();
		}
	};

	/**
	 * Move focus by delta rows/columns
	 */
	TableInstance.prototype._moveFocus = function(rowDelta, colDelta) {
		var rows = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)') : [];
		if (rows.length === 0) return false;

		var newRow = Math.max(0, Math.min(rows.length - 1, this._focusedCell.row + rowDelta));
		var numCols = this.config.columns.filter(function(c) { return c.visible !== false; }).length;
		var newCol = Math.max(0, Math.min(numCols - 1, this._focusedCell.col + colDelta));

		this._setFocus(newRow, newCol);
		return true;
	};

	/**
	 * Set focus to specific cell
	 */
	TableInstance.prototype._setFocus = function(rowIndex, colIndex) {
		var rows = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)') : [];
		if (rowIndex < 0 || rowIndex >= rows.length) return;

		// Set flag to prevent _handleFocusIn from interfering
		this._settingFocus = true;

		// Remove focus from previous
		var prevRow = rows[this._focusedCell.row];
		if (prevRow) {
			prevRow.setAttribute('tabindex', '-1');
			D.one(prevRow).classRemove('funky-table-row-focused');
		}

		// Update focus position
		this._focusedCell.row = rowIndex;
		this._focusedCell.col = colIndex;

		// Set focus on new row
		var newRow = rows[rowIndex];
		var self = this;
		if (newRow) {
			newRow.setAttribute('tabindex', '0');
			D.one(newRow).classAdd('funky-table-row-focused');
			newRow.focus();

			// Scroll into view if needed
			this._scrollRowIntoView(newRow);

			// Announce for screen readers
			this._announceRow(newRow, rowIndex);
		}

		// Clear flag after a tick to allow focusin to complete
		setTimeout(function() {
			self._settingFocus = false;
		}, 0);
	};

	/**
	 * Clear focus styling from all rows (when focus leaves table)
	 */
	TableInstance.prototype._clearFocusStyling = function() {
		var tbodyEl = this.tbody ? this.tbody.el : null;
		if (!tbodyEl) return;
		
		var rows = tbodyEl.querySelectorAll('.funky-table-row-focused');
		rows.forEach(function(row) {
			D.one(row).classRemove('funky-table-row-focused');
		});
	};

	/**
	 * Scroll row into view
	 */
	TableInstance.prototype._scrollRowIntoView = function(row) {
		if (!row) return;

		var wrapperEl = this.wrapper ? this.wrapper.el : null;
		if (!wrapperEl) return;
		
		var rowRect = row.getBoundingClientRect();
		var wrapperRect = wrapperEl.getBoundingClientRect();

		// Check if row is above visible area
		if (rowRect.top < wrapperRect.top) {
			row.scrollIntoView({ block: 'start', behavior: 'smooth' });
		}
		// Check if row is below visible area
		else if (rowRect.bottom > wrapperRect.bottom) {
			row.scrollIntoView({ block: 'end', behavior: 'smooth' });
		}
	};

	/**
	 * Focus first row
	 */
	TableInstance.prototype._focusFirstRow = function() {
		this._setFocus(0, this._focusedCell.col);
		return true;
	};

	/**
	 * Focus last row
	 */
	TableInstance.prototype._focusLastRow = function() {
		var rows = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)') : [];
		this._setFocus(rows.length - 1, this._focusedCell.col);
		return true;
	};

	/**
	 * Focus first cell in current row
	 */
	TableInstance.prototype._focusFirstCell = function() {
		this._setFocus(this._focusedCell.row, 0);
		return true;
	};

	/**
	 * Focus last cell in current row
	 */
	TableInstance.prototype._focusLastCell = function() {
		var numCols = this.config.columns.filter(function(c) { return c.visible !== false; }).length;
		this._setFocus(this._focusedCell.row, numCols - 1);
		return true;
	};

	/**
	 * Activate focused row (trigger row click)
	 */
	TableInstance.prototype._activateFocusedRow = function() {
		var rows = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)') : [];
		var row = rows[this._focusedCell.row];
		if (!row) return false;

		var rowIndex = parseInt(row.getAttribute('data-index'), 10);
		var rowData = this.data[rowIndex];

		if (rowData && typeof this.config.onRowClick === 'function') {
			this.config.onRowClick(rowData, row);
		}

		return true;
	};

	/**
	 * Toggle selection of focused row
	 */
	TableInstance.prototype._toggleFocusedRowSelection = function() {
		var rows = this.tbody && this.tbody.el ? this.tbody.el.querySelectorAll('tr:not(.funky-table-details-row)') : [];
		var row = rows[this._focusedCell.row];
		if (!row) return false;

		var id = row.getAttribute('data-id');
		if (id) {
			var isSelected = this._selectedIds.indexOf(id) !== -1;
			if (isSelected) {
				this._deselectRow(id, row);
			} else {
				this._selectRow(id, row);
			}
		}

		return true;
	};

	/**
	 * Select all rows (Ctrl+A)
	 */
	TableInstance.prototype._selectAllRows = function() {
		if (this.config.selection && this.config.selection.mode === 'multi') {
			this.selectAll();
			return true;
		}
		return false;
	};

	/**
	 * Clear selection, focus styling, and exit table focus
	 */
	TableInstance.prototype._clearSelectionAndFocus = function() {
		var self = this;
		
		// Clear row focus styling
		this._clearFocusStyling();
		
		// Reset focused cell tracking
		this._focusedCell = { row: 0, col: 0 };
		
		// Remove tabindex from all rows, reset to first row
		var tbodyEl = this.tbody ? this.tbody.el : null;
		if (tbodyEl) {
			var rows = tbodyEl.querySelectorAll('tr:not(.funky-table-details-row)');
			rows.forEach(function(row, index) {
				row.setAttribute('tabindex', index === 0 ? '0' : '-1');
			});
		}
		
		// Temporarily remove focusable elements in wrapper from tab order
		// EXCEPT for footer (pagination) which should remain tabbable
		var wrapperEl = this.wrapper ? this.wrapper.el : null;
		if (wrapperEl) {
			var focusableSelector = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';
			var focusables = wrapperEl.querySelectorAll(focusableSelector);
			var originalTabindexes = [];
			
			focusables.forEach(function(el, i) {
				// Skip elements inside the footer (pagination, info)
				if (el.closest('.funky-table-footer')) {
					return;
				}
				originalTabindexes.push({
					el: el,
					tabindex: el.getAttribute('tabindex')
				});
				el.setAttribute('tabindex', '-1');
			});
			
			// Restore all tabindexes after 5 seconds
			setTimeout(function() {
				originalTabindexes.forEach(function(item) {
					if (item.tabindex === null) {
						item.el.removeAttribute('tabindex');
					} else {
						item.el.setAttribute('tabindex', item.tabindex);
					}
				});
			}, 5000);
		}
		
		// Blur the active element to exit table
		if (document.activeElement) {
			document.activeElement.blur();
		}
		
		return true;
	};

	// =========================================================================
	// Accessibility - Screen Reader Announcements
	// =========================================================================

	/**
	 * Create live region for announcements
	 */
	TableInstance.prototype._createLiveRegion = function() {
		var liveRegion = D.create('div')
			.attr('id', this._generateId('live'))
			.attr('role', 'status')
			.attr('aria-live', 'polite')
			.attr('aria-atomic', 'true')
			.classAdd('visually-hidden');

		if (this.wrapper) {
			this.wrapper.append(liveRegion);
		}
		this._liveRegion = liveRegion.el;
	};

	/**
	 * Announce message to screen readers
	 */
	TableInstance.prototype._announce = function(message) {
		if (!this._liveRegion) return;

		// Clear then set (forces announcement)
		this._liveRegion.textContent = '';

		var self = this;
		setTimeout(function() {
			// Check if still valid (table may have been destroyed)
			if (self._liveRegion) {
				self._liveRegion.textContent = message;
			}
		}, 50);
	};

	/**
	 * Announce row information
	 */
	TableInstance.prototype._announceRow = function(row, rowIndex) {
		var announcement = 'Row ' + (rowIndex + 1);

		// Add row label if available
		var dataIndex = parseInt(row.getAttribute('data-index'), 10);
		var rowData = this.data[dataIndex];
		if (rowData) {
			var label = this._getRowLabel(rowData);
			if (label) {
				announcement += ', ' + label;
			}
		}

		// Add selection state
		if (row.getAttribute('aria-selected') === 'true') {
			announcement += ', selected';
		}

		this._announce(announcement);
	};

	/**
	 * Announce data loading
	 */
	TableInstance.prototype._announceLoading = function() {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.announceLoading) return;

		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (tableEl) tableEl.setAttribute('aria-busy', 'true');
		this._announce('Loading data, please wait');
	};

	/**
	 * Announce data loaded
	 */
	TableInstance.prototype._announceDataLoaded = function() {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.announceLoading) return;

		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (tableEl) tableEl.setAttribute('aria-busy', 'false');

		var message = this.totalRecords + ' items loaded';

		if (this.searchQuery) {
			message += ', filtered by "' + this.searchQuery + '"';
		}

		if (this.config.serverSide) {
			var totalPages = Math.ceil(this.totalRecords / this.pageLength);
			message += ', showing page ' + this.currentPage + ' of ' + totalPages;
		}

		this._announce(message);
	};

	/**
	 * Announce selection change
	 */
	TableInstance.prototype._announceSelectionChange = function() {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.announceSelection) return;

		var count = this._selectedIds ? this._selectedIds.length : 0;
		var message = count === 0
			? 'No items selected'
			: count + ' item' + (count === 1 ? '' : 's') + ' selected';

		this._announce(message);
	};

	/**
	 * Announce sort change
	 */
	TableInstance.prototype._announceSortChange = function(columnTitle, direction) {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.announceSort) return;

		var message = 'Sorted by ' + columnTitle + ' ' +
					  (direction === 'asc' ? 'ascending' : 'descending');
		this._announce(message);
	};

	/**
	 * Announce page change
	 */
	TableInstance.prototype._announcePageChange = function() {
		var a11yConfig = this._getA11yConfig();
		if (!a11yConfig.announcePageChange) return;

		var totalPages = Math.ceil(this.totalRecords / this.pageLength);
		var message = 'Page ' + this.currentPage + ' of ' + totalPages;
		this._announce(message);
	};

	// =========================================================================
	// Accessibility - Focus Management
	// =========================================================================

	/**
	 * Handle focus entering table
	 */
	TableInstance.prototype._handleFocusIn = function(e) {
		// Skip if _setFocus is handling focus programmatically
		if (this._settingFocus) {
			return;
		}

		var tableEl = this.tableEl ? this.tableEl.el : null;
		var tbodyEl = this.tbody ? this.tbody.el : null;
		
		// If focus landed on the table element itself (via Tab), move to first row
		if (e.target === tableEl && tbodyEl) {
			var rows = tbodyEl.querySelectorAll('tr:not(.funky-table-details-row)');
			if (rows.length > 0) {
				// Focus the previously focused row, or first row
				var targetRow = Math.min(this._focusedCell.row, rows.length - 1);
				targetRow = Math.max(0, targetRow);
				// Use setTimeout to avoid re-triggering focusin immediately
				var self = this;
				setTimeout(function() {
					self._setFocus(targetRow, self._focusedCell.col);
				}, 0);
				return;
			}
		}
		
		// Track which row received focus - only for styling purposes
		// IMPORTANT: Don't update _focusedCell.row here - it causes race conditions with keyboard nav
		// _setFocus is the sole source of truth for _focusedCell.row
		// Click handling is done via a separate click listener
		var row = e.target.closest('tr[role="row"]');
		if (row && row.parentNode === tbodyEl) {
			// Just update focus styling - don't touch _focusedCell.row
			D.one(row).classAdd('funky-table-row-focused');
			// Remove from other rows
			var allRows = tbodyEl.querySelectorAll('tr:not(.funky-table-details-row)');
			allRows.forEach(function(r) {
				if (r !== row) {
					D.one(r).classRemove('funky-table-row-focused');
				}
			});
		}
	};

	/**
	 * Restore focus after data reload
	 */
	TableInstance.prototype._restoreFocus = function() {
		// Guard: ensure _focusedCell is initialized
		if (!this._focusedCell) {
			this._focusedCell = { row: 0, col: 0 };
		}
		
		var tbodyEl = this.tbody ? this.tbody.el : null;
		if (!tbodyEl) return;
		
		var rows = tbodyEl.querySelectorAll('tr:not(.funky-table-details-row)');
		if (rows.length === 0) return;

		// Clamp focus position to valid range
		this._focusedCell.row = Math.min(this._focusedCell.row, rows.length - 1);
		this._focusedCell.row = Math.max(0, this._focusedCell.row);

		// Only restore if table had focus before
		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (tableEl && (document.activeElement === tableEl || tableEl.contains(document.activeElement))) {
			this._setFocus(this._focusedCell.row, this._focusedCell.col);
		}
	};

	/**
	 * Focus trap for modal context
	 */
	TableInstance.prototype.trapFocus = function(enabled) {
		this._focusTrapEnabled = enabled;
		var tableEl = this.tableEl ? this.tableEl.el : null;
		if (!tableEl) return;

		if (enabled) {
			var self = this;
			this._focusTrapHandler = function(e) {
				self._handleFocusTrap(e);
			};
			tableEl.addEventListener('keydown', this._focusTrapHandler);
		} else if (this._focusTrapHandler) {
			tableEl.removeEventListener('keydown', this._focusTrapHandler);
			this._focusTrapHandler = null;
		}
	};

	/**
	 * Handle focus trap Tab key
	 */
	TableInstance.prototype._handleFocusTrap = function(e) {
		if (e.key !== 'Tab') return;

		var wrapperEl = this.wrapper ? this.wrapper.el : null;
		if (!wrapperEl) return;
		
		var focusableElements = wrapperEl.querySelectorAll(
			'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), ' +
			'textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
		);

		var firstFocusable = focusableElements[0];
		var lastFocusable = focusableElements[focusableElements.length - 1];

		if (e.shiftKey && document.activeElement === firstFocusable) {
			lastFocusable.focus();
			e.preventDefault();
		} else if (!e.shiftKey && document.activeElement === lastFocusable) {
			firstFocusable.focus();
			e.preventDefault();
		}
	};

	/**
	 * Cleanup accessibility handlers
	 */
	TableInstance.prototype._destroyAccessibility = function() {
		if (this._focusTrapHandler) {
			var tableEl = this.tableEl ? this.tableEl.el : null;
			if (tableEl) tableEl.removeEventListener('keydown', this._focusTrapHandler);
			this._focusTrapHandler = null;
		}

		if (this._liveRegion && this._liveRegion.parentNode) {
			this._liveRegion.parentNode.removeChild(this._liveRegion);
			this._liveRegion = null;
		}
	};

	// =========================================================================
	// Public API - Conditional Formatting
	// =========================================================================

	/**
	 * Add formatting rule dynamically
	 */
	TableInstance.prototype.addFormattingRule = function(rule) {
		if (!this._formattingRules) {
			this._formattingRules = [];
		}

		this._formattingRules.push(rule);
		this._clearFormattingCache();
		this._loadData();

		return this;
	};

	/**
	 * Remove formatting rule by ID
	 */
	TableInstance.prototype.removeFormattingRule = function(ruleId) {
		if (!this._formattingRules) return this;

		this._formattingRules = this._formattingRules.filter(function(r) {
			return r.id !== ruleId;
		});

		this._clearFormattingCache();
		this._loadData();

		return this;
	};

	/**
	 * Update existing rule
	 */
	TableInstance.prototype.updateFormattingRule = function(ruleId, updates) {
		if (!this._formattingRules) return this;

		for (var i = 0; i < this._formattingRules.length; i++) {
			if (this._formattingRules[i].id === ruleId) {
				for (var key in updates) {
					if (updates.hasOwnProperty(key)) {
						this._formattingRules[i][key] = updates[key];
					}
				}
				break;
			}
		}

		this._clearFormattingCache();
		this._loadData();

		return this;
	};

	/**
	 * Get all formatting rules
	 */
	TableInstance.prototype.getFormattingRules = function() {
		return this._formattingRules ? this._formattingRules.slice() : [];
	};

	/**
	 * Clear all formatting rules
	 */
	TableInstance.prototype.clearFormattingRules = function() {
		this._formattingRules = [];
		this._clearFormattingCache();
		this._loadData();

		return this;
	};

	/**
	 * Enable/disable a formatting rule
	 */
	TableInstance.prototype.setFormattingRuleEnabled = function(ruleId, enabled) {
		if (!this._formattingRules) return this;

		for (var i = 0; i < this._formattingRules.length; i++) {
			if (this._formattingRules[i].id === ruleId) {
				this._formattingRules[i].enabled = enabled;
				break;
			}
		}

		this._loadData();

		return this;
	};

	// =========================================================================
	// Public API - Sorting
	// =========================================================================

	/**
	 * Get or set sort order
	 * @param {Array} [newOrder] - Array of [columnIndex, direction] or [[col, dir], ...]
	 * @returns {Array|this}
	 */
	TableInstance.prototype.order = function(newOrder) {
		// Getter
		if (newOrder === undefined) {
			return this.sortOrder.map(function(s) {
				return [s.column, s.dir];
			});
		}

		// Setter
		this.sortOrder = [];
		var self = this;

		if (Array.isArray(newOrder)) {
			// Single order like [0, 'asc'] or multi like [[0, 'asc'], [1, 'desc']]
			var orders = Array.isArray(newOrder[0]) ? newOrder : [newOrder];

			orders.forEach(function(o) {
				if (Array.isArray(o) && o.length >= 2) {
					self.sortOrder.push({
						column: o[0],
						dir: o[1] || 'asc'
					});
				}
			});
		}

		this._updateSortIndicators();
		this._loadData();

		return this;
	};

	/**
	 * Clear all sorting
	 */
	TableInstance.prototype.clearSort = function() {
		this.sortOrder = [];
		this._updateSortIndicators();
		this._loadData();
		return this;
	};

	// =========================================================================
	// Public API - Selection Methods
	// =========================================================================

	/**
	 * Get selected row IDs
	 * @returns {Array} Selected IDs
	 */
	TableInstance.prototype.getSelectedIds = function() {
		return Array.from(this.selectedIds);
	};

	/**
	 * Get selected row data
	 * @returns {Array} Selected row objects
	 */
	TableInstance.prototype.getSelectedData = function() {
		var self = this;
		return this.data.filter(function(row) {
			return self.selectedIds.has(String(row.id));
		});
	};

	/**
	 * Select rows by ID
	 * @param {Array|string|number} ids - ID(s) to select
	 * @returns {this}
	 */
	TableInstance.prototype.select = function(ids) {
		var self = this;
		var idArray = Array.isArray(ids) ? ids : [ids];

		// Filter to only IDs that exist in data
		var validIds = idArray.filter(function(id) {
			return self._getRowDataById(id) !== null;
		});

		// In single selection mode, clear previous selection first
		if (this.config.selectable === 'single') {
			this.selectedIds.clear();
			// Only select the last valid ID in the array for single mode
			if (validIds.length > 0) {
				this.selectedIds.add(String(validIds[validIds.length - 1]));
			}
		} else {
			validIds.forEach(function(id) {
				self.selectedIds.add(String(id));
			});
		}

		this._updateSelectionUI();
		this._emitSelectionChange();
		return this;
	};

	/**
	 * Deselect rows by ID
	 * @param {Array|string|number} ids - ID(s) to deselect
	 * @returns {this}
	 */
	TableInstance.prototype.deselect = function(ids) {
		var self = this;
		var idArray = Array.isArray(ids) ? ids : [ids];

		// Track deselected data for callback
		var deselectedData = [];

		idArray.forEach(function(id) {
			var strId = String(id);
			if (self.selectedIds.has(strId)) {
				var rowData = self._getRowDataById(id);
				if (rowData) {
					deselectedData.push(rowData);
				}
				self.selectedIds.delete(strId);
			}
		});

		this._updateSelectionUI();
		this._emitSelectionChange();

		// Fire onDeselect callback if rows were actually deselected
		if (deselectedData.length > 0 && typeof this.config.onDeselect === 'function') {
			this.config.onDeselect(deselectedData, this);
		}

		return this;
	};

	/**
	 * Select all rows
	 * @returns {this}
	 */
	TableInstance.prototype.selectAll = function() {
		this._handleSelectAll(true);
		return this;
	};

	/**
	 * Deselect all rows
	 * @returns {this}
	 */
	TableInstance.prototype.deselectAll = function() {
		this._clearSelection();
		return this;
	};

	/**
	 * Toggle selection for row
	 * @param {string|number} id - Row ID
	 * @returns {this}
	 */
	TableInstance.prototype.toggleSelect = function(id) {
		if (this.selectedIds.has(String(id))) {
			this.deselect(id);
		} else {
			this.select(id);
		}
		return this;
	};

	// =========================================================================
	// Public API - Context Menu Methods
	// =========================================================================

	/**
	 * Programmatically show context menu for a row
	 * @param {string|number} rowId - Row ID
	 * @param {number} x - X coordinate
	 * @param {number} y - Y coordinate
	 * @returns {this}
	 */
	TableInstance.prototype.showContextMenu = function(rowId, x, y) {
		if (!this._contextMenuConfig || !this._contextMenuConfig.enabled) return this;

		var row = this._getRowDataById(rowId);
		if (!row) return this;

		var selectedRows = this.getSelectedData();
		var items = this._buildContextMenuItems(row, selectedRows);

		this._openContextMenu(x, y, items, row, selectedRows);

		return this;
	};

	/**
	 * Close any open context menu
	 * @returns {this}
	 */
	TableInstance.prototype.closeContextMenu = function() {
		if (this._activeContextMenu) {
			this._activeContextMenu.close();
			this._activeContextMenu = null;
		}
		this._clearContextMenuActiveRow();
		return this;
	};

	/**
	 * Add context menu item dynamically
	 * @param {Object} item - Menu item configuration
	 * @returns {this}
	 */
	TableInstance.prototype.addContextMenuItem = function(item) {
		if (!this._contextMenuConfig) return this;

		if (!this._contextMenuConfig.items) {
			this._contextMenuConfig.items = [];
		}

		this._contextMenuConfig.items.push(item);

		return this;
	};

	/**
	 * Remove context menu item by ID
	 * @param {string} itemId - Item ID to remove
	 * @returns {this}
	 */
	TableInstance.prototype.removeContextMenuItem = function(itemId) {
		if (!this._contextMenuConfig || !this._contextMenuConfig.items) return this;

		this._contextMenuConfig.items = this._contextMenuConfig.items.filter(function(item) {
			return item.id !== itemId;
		});

		return this;
	};

	/**
	 * Enable/disable context menu
	 * @param {boolean} enabled - Enable state
	 * @returns {this}
	 */
	TableInstance.prototype.setContextMenuEnabled = function(enabled) {
		if (this._contextMenuConfig) {
			this._contextMenuConfig.enabled = enabled;
		}
		return this;
	};

	// =========================================================================
	// Public API - Filter Methods
	// =========================================================================

	/**
	 * Set filter value programmatically
	 * @param {string} filterName - Filter identifier (param name)
	 * @param {*} value - Filter value
	 * @returns {this}
	 */
	TableInstance.prototype.setFilter = function(filterName, value) {
		if (!this.config.extraAjaxData) {
			this.config.extraAjaxData = {};
		}
		this.config.extraAjaxData[filterName] = value;
		this.currentPage = 1;
		this._loadData();
		return this;
	};

	/**
	 * Clear a specific filter
	 * @param {string} filterName - Filter identifier (param name)
	 * @returns {this}
	 */
	TableInstance.prototype.clearFilter = function(filterName) {
		if (this.config.extraAjaxData) {
			delete this.config.extraAjaxData[filterName];
		}
		this.currentPage = 1;
		this._loadData();
		return this;
	};

	/**
	 * Clear all filters
	 * @returns {this}
	 */
	TableInstance.prototype.clearAllFilters = function() {
		var self = this;

		// Clear extraAjaxData
		if (this.config.extraAjaxData) {
			var keys = Object.keys(this.config.extraAjaxData);
			for (var i = 0; i < keys.length; i++) {
				delete this.config.extraAjaxData[keys[i]];
			}
		}

		// Reset date range picker
		if (this._dateRangePicker && this._dateRangePicker.setRange) {
			var defaultRange = this._getDefaultDateRange('last7days');
			this._dateRangePicker.setRange(defaultRange.start, defaultRange.end);
		}

		// Reset ComboBox filters
		if (this._clientFilterEl && Funky.ComboBox) {
			var instance = Funky.ComboBox.getInstance(this._clientFilterEl);
			if (instance && instance.clear) instance.clear();
		}

		if (this._customFilters) {
			for (var j = 0; j < this._customFilters.length; j++) {
				var f = this._customFilters[j];
				var comboInstance = Funky.ComboBox && Funky.ComboBox.getInstance(f.element);
				if (comboInstance && comboInstance.clear) {
					comboInstance.clear();
				} else if (f.element.tagName === 'SELECT') {
					f.element.selectedIndex = 0;
				} else if (f.element.tagName === 'INPUT') {
					f.element.value = '';
				}
			}
		}

		// Clear search
		this.clearSearch();

		this._loadData();
		return this;
	};

	/**
	 * Get current filter values
	 * @returns {Object} Current filter values from extraAjaxData
	 */
	TableInstance.prototype.getFilters = function() {
		var result = {};
		if (this.config.extraAjaxData) {
			var keys = Object.keys(this.config.extraAjaxData);
			for (var i = 0; i < keys.length; i++) {
				result[keys[i]] = this.config.extraAjaxData[keys[i]];
			}
		}
		return result;
	};

	// =========================================================================
	// Compatibility Methods
	// =========================================================================

	/**
	 * Setup global search (compatibility with DataTables wrapper)
	 * @param {string} searchInputSelector - Selector for search input
	 */
	TableInstance.prototype.setupGlobalSearch = function(searchInputSelector) {
		var input = document.querySelector(searchInputSelector);
		if (!input) return;

		var self = this;
		input.addEventListener('keyup', function() {
			self.search(input.value);
		});
	};

	/**
	 * Setup date range filter (compatibility)
	 * @param {string} dateRangeSelector - Selector for date range picker
	 * @param {string} columnSelectSelector - Selector for column select
	 * @param {Object} extraAjaxData - Extra AJAX data (unused, for compatibility)
	 * @param {Array} dateColumns - Array of column definitions
	 */
	TableInstance.prototype.setupDateRangeFilter = function(dateRangeSelector, columnSelectSelector, extraAjaxData, dateColumns) {
		this._initDateRangeFilter({
			selector: dateRangeSelector,
			columnSelector: columnSelectSelector,
			columns: dateColumns
		});
	};

	/**
	 * Setup client filter (compatibility)
	 * @param {string} selectSelector - Selector for client select
	 * @param {Object} extraAjaxData - Extra AJAX data (unused, for compatibility)
	 */
	TableInstance.prototype.setupClientFilter = function(selectSelector, extraAjaxData) {
		this._initClientFilter({
			selector: selectSelector,
			paramName: 'client_id',
			mode: 'multi',
			remote: {
				url: '/api/clients',
				searchParam: 'search',
				transform: function(client) {
					return { id: client.id, name: client.name + ' (' + client.code + ')' };
				}
			}
		});
	};

	// =========================================================================
	// Public API - Advanced Filter Methods (Phase 11)
	// =========================================================================

	/**
	 * Open advanced filter modal
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.openAdvancedFilter = function() {
		if (this._advancedFilter) {
			this._advancedFilter.open();
		}
		return this;
	};

	/**
	 * Get current advanced filter parameters
	 * @returns {Object}
	 */
	TableInstance.prototype.getAdvancedFilters = function() {
		if (this._advancedFilter && this._advancedFilter.getParams) {
			return this._advancedFilter.getParams();
		}

		// Fallback: return filter fields from extraAjaxData
		var result = {};
		var self = this;
		if (this.config.advancedFilter && this.config.advancedFilter.fields) {
			var fields = this.config.advancedFilter.fields;
			var allFields = [].concat(
				fields.multiSelect || [],
				fields.range || [],
				fields.date || []
			);

			allFields.forEach(function(field) {
				if (self.config.extraAjaxData[field] !== undefined) {
					result[field] = self.config.extraAjaxData[field];
				}
				// Include range suffixes
				['_min', '_max', '_from', '_to'].forEach(function(suffix) {
					var key = field + suffix;
					if (self.config.extraAjaxData[key] !== undefined) {
						result[key] = self.config.extraAjaxData[key];
					}
				});
			});
		}
		return result;
	};

	/**
	 * Set advanced filter parameters programmatically
	 * @param {Object} params - Filter parameters
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.setAdvancedFilters = function(params) {
		if (this._advancedFilter && this._advancedFilter.loadFromParams) {
			this._advancedFilter.loadFromParams(params);
		} else {
			this._applyAdvancedFilters(params);
		}
		return this;
	};

	/**
	 * Clear all advanced filters
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.clearAdvancedFilters = function() {
		if (this._advancedFilter) {
			this._advancedFilter.clearFilters();
		}
		this._clearAdvancedFilters();
		return this;
	};

	/**
	 * Save current filters as template
	 * @param {string} name - Template name
	 * @returns {Promise}
	 */
	TableInstance.prototype.saveFilterTemplate = function(name) {
		if (this._advancedFilter && this._advancedFilter.saveFilter) {
			return this._advancedFilter.saveFilter(name);
		}
		return Promise.reject(new Error('AdvancedFilter not initialized'));
	};

	/**
	 * Load filter template by name
	 * @param {string} name - Template name
	 * @returns {Promise}
	 */
	TableInstance.prototype.loadFilterTemplate = function(name) {
		if (this._advancedFilter && this._advancedFilter.loadSavedFilter) {
			return this._advancedFilter.loadSavedFilter(name);
		}
		return Promise.reject(new Error('AdvancedFilter not initialized'));
	};

	/**
	 * Get shareable filter URL
	 * @returns {string}
	 */
	TableInstance.prototype.getFilterUrl = function() {
		var params = this.getAdvancedFilters();
		var encoded = btoa(JSON.stringify(params));
		return window.location.origin + window.location.pathname + '#filter=' + encoded;
	};

	/**
	 * Copy filter URL to clipboard
	 * @returns {Promise}
	 */
	TableInstance.prototype.copyFilterUrl = function() {
		var url = this.getFilterUrl();
		var self = this;

		if (navigator.clipboard && navigator.clipboard.writeText) {
			return navigator.clipboard.writeText(url).then(function() {
				if (Funky.Announce) {
					Funky.Announce.success('Filter URL copied to clipboard');
				}
				self._emit('filterUrlCopied', { url: url });
			});
		}

		// Fallback for older browsers
		var textarea = document.createElement('textarea');
		textarea.value = url;
		textarea.style.position = 'fixed';
		textarea.style.opacity = '0';
		document.body.appendChild(textarea);
		textarea.select();
		try {
			document.execCommand('copy');
			if (Funky.Announce) {
				Funky.Announce.success('Filter URL copied to clipboard');
			}
			this._emit('filterUrlCopied', { url: url });
		} catch (e) {
			console.warn('[Funky.Table] Failed to copy URL:', e);
		}
		document.body.removeChild(textarea);
		return Promise.resolve();
	};

	// =========================================================================
	// Public API - Column Profile Methods (Phase 12)
	// =========================================================================

	/**
	 * Get all column profiles
	 * @returns {Array}
	 */
	TableInstance.prototype.getProfiles = function() {
		return this._columnProfiles ? this._columnProfiles.profiles.slice() : [];
	};

	/**
	 * Get active profile
	 * @returns {Object|null}
	 */
	TableInstance.prototype.getActiveProfile = function() {
		return this._columnProfiles ? this._columnProfiles.activeProfile : null;
	};

	/**
	 * Apply profile by name
	 * @param {string} profileName - Profile name
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.applyProfile = function(profileName) {
		this._applyProfileByName(profileName);
		return this;
	};

	/**
	 * Save current column state as profile
	 * @param {string} name - Profile name
	 * @param {string} [description] - Profile description
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.saveProfile = function(name, description) {
		var self = this;

		var visibleColumns = this.config.columns
			.filter(function(col) { return self._isColumnVisible(col.data); })
			.map(function(col) { return col.data; });

		this._addProfile({
			name: name,
			description: description || '',
			columns: visibleColumns,
			columnWidths: this._getColumnWidths(),
			columnOrder: this._getColumnOrder()
		});

		return this;
	};

	/**
	 * Delete a profile by name
	 * @param {string} name - Profile name
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.deleteProfile = function(name) {
		if (!this._columnProfiles) return this;

		this._columnProfiles.profiles = this._columnProfiles.profiles.filter(function(p) {
			return p.name !== name || p.predefined;
		});

		this._saveProfilesToStorage();
		this._rebuildProfileMenu();

		return this;
	};

	/**
	 * Export profiles as JSON
	 * @returns {string}
	 */
	TableInstance.prototype.exportProfiles = function() {
		return JSON.stringify(this._columnProfiles ? this._columnProfiles.profiles : []);
	};

	/**
	 * Import profiles from JSON
	 * @param {string} json - JSON string
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.importProfiles = function(json) {
		try {
			var profiles = JSON.parse(json);
			var self = this;
			profiles.forEach(function(p) {
				self._addProfile(p, false);
			});
			this._rebuildProfileMenu();
		} catch (e) {
			console.error('[Funky.Table] Failed to import profiles:', e);
		}
		return this;
	};

	/**
	 * Toggle column visibility
	 * @param {string} colData - Column data key
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.toggleColumn = function(colData) {
		var isVisible = this._isColumnVisible(colData);
		this._setColumnVisible(colData, !isVisible);
		this._render();
		this._emit('columnToggle', { column: colData, visible: !isVisible });
		return this;
	};

	/**
	 * Show a column
	 * @param {string} colData - Column data key
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.showColumn = function(colData) {
		this._setColumnVisible(colData, true);
		this._render();
		this._emit('columnToggle', { column: colData, visible: true });
		return this;
	};

	/**
	 * Hide a column
	 * @param {string} colData - Column data key
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.hideColumn = function(colData) {
		this._setColumnVisible(colData, false);
		this._render();
		this._emit('columnToggle', { column: colData, visible: false });
		return this;
	};

	/**
	 * Get visible columns
	 * @returns {Array}
	 */
	TableInstance.prototype.getVisibleColumns = function() {
		var self = this;
		return this.config.columns
			.filter(function(col) { return self._isColumnVisible(col.data); })
			.map(function(col) { return col.data; });
	};

	/**
	 * Set visible columns
	 * @param {Array} columns - Array of column data keys
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.setVisibleColumns = function(columns) {
		var self = this;
		this.config.columns.forEach(function(col) {
			var visible = columns.indexOf(col.data) !== -1;
			self._setColumnVisible(col.data, visible);
		});
		this._render();
		this._rebuildProfileMenu();
		return this;
	};

	// =========================================================================
	// Public API - Aggregation Methods (Phase 13)
	// =========================================================================

	/**
	 * Get calculated aggregations
	 * @returns {Object}
	 */
	TableInstance.prototype.getAggregations = function() {
		return this._aggregations ? this._aggregations.calculated : {};
	};

	/**
	 * Get specific aggregation value
	 * @param {string} column - Column data key
	 * @param {string} [type] - Aggregation type (for columns with multiple)
	 * @returns {*}
	 */
	TableInstance.prototype.getAggregation = function(column, type) {
		var aggs = this.getAggregations();
		var colAgg = aggs[column];

		if (!colAgg) return null;

		// If array, find by type
		if (Array.isArray(colAgg)) {
			var found = colAgg.find(function(a) { return a.type === type; });
			return found ? found.value : null;
		}

		return colAgg.value;
	};

	/**
	 * Recalculate aggregations
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.recalculateAggregations = function() {
		if (this._aggregations) {
			this._calculateAggregations();
		}
		return this;
	};

	/**
	 * Add aggregation to column
	 * @param {string} column - Column data key
	 * @param {Object} config - Aggregation config { type, format, label }
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.addAggregation = function(column, config) {
		if (!this._aggregations) {
			this.config.aggregations = this.config.aggregations || { enabled: true, columns: {} };
			this._initAggregations();
		}

		if (!this._aggregations.config.columns) {
			this._aggregations.config.columns = {};
		}

		var existing = this._aggregations.config.columns[column];

		if (existing && !Array.isArray(existing)) {
			// Convert to array
			this._aggregations.config.columns[column] = [existing, config];
		} else if (Array.isArray(existing)) {
			existing.push(config);
		} else {
			this._aggregations.config.columns[column] = config;
		}

		this._calculateAggregations();
		return this;
	};

	/**
	 * Remove aggregation from column
	 * @param {string} column - Column data key
	 * @param {string} [type] - Aggregation type to remove (optional, removes all if not specified)
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.removeAggregation = function(column, type) {
		if (!this._aggregations) return this;

		var existing = this._aggregations.config.columns[column];

		if (type && Array.isArray(existing)) {
			this._aggregations.config.columns[column] = existing.filter(function(a) {
				return a.type !== type;
			});

			if (this._aggregations.config.columns[column].length === 0) {
				delete this._aggregations.config.columns[column];
			}
		} else {
			delete this._aggregations.config.columns[column];
		}

		delete this._aggregations.calculated[column];
		this._calculateAggregations();
		return this;
	};

	/**
	 * Show/hide aggregation footer/header
	 * @param {boolean} show - Whether to show
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.showAggregations = function(show) {
		if (this._aggregationFooter) {
			this._aggregationFooter.style.display = show ? '' : 'none';
		}
		if (this._aggregationHeader) {
			this._aggregationHeader.style.display = show ? '' : 'none';
		}
		return this;
	};

	/**
	 * Export aggregations as simple object
	 * @returns {Object}
	 */
	TableInstance.prototype.exportAggregations = function() {
		var result = {};
		var aggs = this.getAggregations();

		Object.keys(aggs).forEach(function(column) {
			var colAgg = aggs[column];

			if (Array.isArray(colAgg)) {
				result[column] = {};
				colAgg.forEach(function(a) {
					result[column][a.type] = a.value;
				});
			} else {
				result[column] = colAgg.value;
			}
		});

		return result;
	};

	// =========================================================================
	// Public API - LiveBinding Methods (Phase 14)
	// =========================================================================

	/**
	 * Check if live binding is connected
	 * @returns {boolean}
	 */
	TableInstance.prototype.isLiveConnected = function() {
		return this._liveBinding ? this._liveBinding.connected : false;
	};

	/**
	 * Pause live binding
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.pauseLiveBinding = function() {
		if (!this._liveBinding) return this;

		this._liveBinding.paused = true;

		if (this._liveBinding.pollInterval) {
			clearInterval(this._liveBinding.pollInterval);
			this._liveBinding.pollInterval = null;
		}

		// Unsubscribe from shared WebSocket channels (don't close the shared connection)
		if (this._liveBinding.wsUnsubscribes) {
			this._liveBinding.wsUnsubscribes.forEach(function(unsubscribe) {
				if (typeof unsubscribe === 'function') {
					unsubscribe();
				}
			});
			this._liveBinding.wsUnsubscribes = [];
		}

		// Remove status handler
		if (this._liveBinding.wsStatusHandler && Funky.WebSocket) {
			Funky.WebSocket.off('status_changed', this._liveBinding.wsStatusHandler);
			this._liveBinding.wsStatusHandler = null;
		}

		if (this._liveBinding.eventSource) {
			this._liveBinding.eventSource.close();
		}

		this._emit('livePaused', {});

		return this;
	};

	/**
	 * Resume live binding
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.resumeLiveBinding = function() {
		if (!this._liveBinding || !this._liveBinding.paused) return this;

		this._liveBinding.paused = false;
		this._liveBinding.destroyed = false;

		var config = this.config.liveBinding;

		// Reinitialize based on source
		switch (this._liveBinding.source) {
			case 'ajax':
				this._initAjaxLiveBinding(config.ajax || {});
				break;
			case 'websocket':
				if (this._liveBinding.reconnect) {
					this._liveBinding.reconnect();
				} else {
					this._initWebSocketBinding(config.websocket || {});
				}
				break;
			case 'eventsource':
				this._initEventSourceBinding(config.eventsource || {});
				break;
		}

		this._emit('liveResumed', {});

		return this;
	};

	/**
	 * Force immediate refresh
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.refreshLive = function() {
		if (!this._liveBinding) return this;

		if (this._liveBinding.fetchData) {
			this._liveBinding.fetchData();
		} else {
			this._loadData();
		}

		return this;
	};

	/**
	 * Push update (for custom source)
	 * @param {Object|Array} data - Row data or array of rows
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.pushUpdate = function(data) {
		if (Array.isArray(data)) {
			this._handleLiveUpdate(data);
		} else {
			this._handleRowUpdate(data);
		}
		return this;
	};

	/**
	 * Push delete (for custom source)
	 * @param {string|number} id - Row ID to delete
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.pushDelete = function(id) {
		this._handleRowDelete(id);
		return this;
	};

	/**
	 * Destroy live binding
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.destroyLiveBinding = function() {
		if (!this._liveBinding) return this;

		this._liveBinding.destroyed = true;
		this._liveBinding.paused = true;

		if (this._liveBinding.pollInterval) {
			clearInterval(this._liveBinding.pollInterval);
		}

		if (this._liveBinding.heartbeatInterval) {
			clearInterval(this._liveBinding.heartbeatInterval);
		}

		// Unsubscribe from shared WebSocket channels
		if (this._liveBinding.wsUnsubscribes) {
			this._liveBinding.wsUnsubscribes.forEach(function(unsubscribe) {
				if (typeof unsubscribe === 'function') {
					unsubscribe();
				}
			});
		}

		// Remove status handler
		if (this._liveBinding.wsStatusHandler && Funky.WebSocket) {
			Funky.WebSocket.off('status_changed', this._liveBinding.wsStatusHandler);
		}

		if (this._liveBinding.eventSource) {
			this._liveBinding.eventSource.close();
		}

		// Remove indicator
		var indicator = this.container.querySelector('.funky-live-indicator');
		if (indicator && indicator.parentNode) {
			indicator.parentNode.removeChild(indicator);
		}

		this._liveBinding = null;

		this._emit('liveDestroyed', {});

		return this;
	};

	/**
	 * Get live binding status
	 * @returns {Object}
	 */
	TableInstance.prototype.getLiveStatus = function() {
		if (!this._liveBinding) {
			return { enabled: false };
		}

		return {
			enabled: true,
			connected: this._liveBinding.connected,
			paused: this._liveBinding.paused,
			source: this._liveBinding.source,
			lastUpdate: this._liveBinding.lastUpdate
		};
	};

	// =========================================================================
	// Public API - Export & Buttons Methods (Phase 15)
	// =========================================================================

	/**
	 * Export current data
	 * @param {string} format - 'csv', 'xlsx', or 'json'
	 * @param {Object} options - Export options
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.export = function(format, options) {
		var config = {
			format: format || 'csv',
			filename: this.config.tableName || 'export'
		};

		if (options) {
			for (var key in options) {
				if (options.hasOwnProperty(key)) {
					config[key] = options[key];
				}
			}
		}

		this._handleExport(config);
		return this;
	};

	/**
	 * Add custom button
	 * @param {Object} config - Button configuration
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.addButton = function(config) {
		if (!this._buttonContainer) {
			this._buttonContainer = this._createButtonContainer();
			this._buttons = [];
		}

		this._createButton(config, this._buttonContainer);
		return this;
	};

	/**
	 * Remove button by text
	 * @param {string} text - Button text
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.removeButton = function(text) {
		if (!this._buttons) return this;

		var self = this;
		this._buttons = this._buttons.filter(function(btn) {
			if (btn.config.text === text) {
				if (btn.element.parentNode) {
					btn.element.parentNode.removeChild(btn.element);
				}
				return false;
			}
			return true;
		});

		return this;
	};

	/**
	 * Set column visibility
	 * @param {number} columnIndex - Column index
	 * @param {boolean} visible - Visibility state
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.setColumnVisibility = function(columnIndex, visible) {
		this._toggleColumnVisibility(columnIndex, visible);
		return this;
	};

	/**
	 * Get visible columns
	 * @returns {Array}
	 */
	TableInstance.prototype.getVisibleColumns = function() {
		return this.config.columns.filter(function(col) {
			return col.visible !== false;
		});
	};

	/**
	 * Get button by text
	 * @param {string} text - Button text
	 * @returns {Object|null}
	 */
	TableInstance.prototype.getButton = function(text) {
		if (!this._buttons) return null;

		for (var i = 0; i < this._buttons.length; i++) {
			if (this._buttons[i].config.text === text) {
				return this._buttons[i];
			}
		}

		return null;
	};

	/**
	 * Enable/disable button by text
	 * @param {string} text - Button text
	 * @param {boolean} enabled - Enabled state
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.setButtonEnabled = function(text, enabled) {
		var btn = this.getButton(text);
		if (btn) {
			btn.element.disabled = !enabled;
			Funky.Dom.one(btn.element).classToggle('disabled', !enabled);
		}
		return this;
	};

	// =========================================================================
	// Public API - Data Methods
	// =========================================================================

	/**
	 * Set table data (Bindable Interface)
	 */
	TableInstance.prototype.setData = function(data) {
		var rows = Array.isArray(data) ? data : (data && data.data) || [];
		this._setClientData(rows);
		return this;
	};

	/**
	 * Get table data (Bindable Interface)
	 */
	TableInstance.prototype.getData = function() {
		return this.data.slice();
	};

	/**
	 * Add rows (Bindable Interface)
	 */
	TableInstance.prototype.addData = function(data) {
		var self = this;
		var rows = Array.isArray(data) ? data : [data];
		var config = this._getAnimationConfig();

		if (config.enabled && rows.length <= 5) {
			// Use animated insert for small batches
			rows.forEach(function(row) {
				self.insertRowAnimated(row, { position: 'top', highlight: true });
			});
		} else {
			// Bulk add without animation
			this.data = rows.concat(this.data);
			this.totalRecords = this.data.length;
			this._applyClientFilters();
			this._renderData();
		}
		return this;
	};

	/**
	 * Remove rows by ID (Bindable Interface)
	 */
	TableInstance.prototype.removeData = function(ids) {
		var self = this;
		var idArray = Array.isArray(ids) ? ids : [ids];
		var config = this._getAnimationConfig();

		if (config.enabled && idArray.length <= 5) {
			// Use animated removal for small batches
			this.removeRowsAnimated(idArray);
		} else {
			// Bulk remove without animation
			var idsSet = {};
			idArray.forEach(function(id) { idsSet[String(id)] = true; });

			this.data = this.data.filter(function(row) {
				return !idsSet[String(row.id)];
			});

			this.totalRecords = this.data.length;
			this._applyClientFilters();
			this._renderData();
		}
		return this;
	};

	/**
	 * Update row by ID (Bindable Interface)
	 * @param {string|number} id - Row ID
	 * @param {Object} updates - Update data
	 * @returns {TableInstance}
	 */
	TableInstance.prototype.updateData = function(id, updates) {
		var idField = this.config.idField || 'id';
		var index = this._findDataIndexById(id);

		if (index !== -1) {
			var rowData = {};
			for (var key in this.data[index]) {
				if (this.data[index].hasOwnProperty(key)) {
					rowData[key] = this.data[index][key];
				}
			}
			for (var uKey in updates) {
				if (updates.hasOwnProperty(uKey)) {
					rowData[uKey] = updates[uKey];
				}
			}
			rowData[idField] = id; // Ensure ID preserved
			this.updateRowAnimated(rowData);
		}

		return this;
	};

	/**
	 * Clear all data (Bindable Interface)
	 */
	TableInstance.prototype.clearData = function() {
		this.data = [];
		this.displayData = [];
		this.totalRecords = 0;
		this.filteredRecords = 0;
		this._renderData();
		return this;
	};

	/**
	 * Reload data from server
	 */
	TableInstance.prototype.reload = function(resetPaging) {
		if (resetPaging) {
			this.currentPage = 1;
		}
		this._loadData();
		return this;
	};

	/**
	 * Get or set search value
	 * @param {string} [query] - Search query
	 * @returns {string|this}
	 */
	TableInstance.prototype.search = function(query) {
		// Getter
		if (query === undefined) {
			return this.searchQuery || '';
		}

		// Setter - update input if exists
		if (this.searchInput && this.searchInput.el) {
			this.searchInput.el.value = query;
		}

		this._handleSearchInput(query);
		return this;
	};

	/**
	 * Clear search
	 * @returns {this}
	 */
	TableInstance.prototype.clearSearch = function() {
		return this.search('');
	};

	/**
	 * Draw/refresh the table
	 */
	TableInstance.prototype.draw = function(resetPaging) {
		if (resetPaging === true || resetPaging === 'full-reset') {
			this.currentPage = 1;
		}
		this._loadData();
		return this;
	};

	/**
	 * Recalculate responsive layout
	 * Call this after showing a hidden table or changing container dimensions
	 * @returns {this}
	 */
	TableInstance.prototype.recalculate = function() {
		this._determineBreakpoint(true);
		return this;
	};

	/**
	 * Get or set current page
	 * @param {number} [pageNum] - Page number (1-based)
	 * @returns {Object|this} Page info object or this for chaining
	 */
	TableInstance.prototype.page = function(pageNum) {
		// Getter
		if (pageNum === undefined) {
			return {
				page: this.currentPage,
				pages: this._getTotalPages(),
				start: (this.currentPage - 1) * this.config.pageLength,
				end: Math.min(this.currentPage * this.config.pageLength, this.filteredRecords),
				length: this.config.pageLength,
				recordsTotal: this.totalRecords,
				recordsFiltered: this.filteredRecords
			};
		}

		// Setter
		this._goToPage(pageNum);
		return this;
	};

	/**
	 * Get or set page length
	 * @param {number} [length] - New page length
	 * @returns {number|this} Current page length or this for chaining
	 */
	TableInstance.prototype.pageLength = function(length) {
		if (length === undefined) {
			return this.config.pageLength;
		}

		this.config.pageLength = length;
		this.currentPage = 1;

		// Update select if exists
		var select = this.wrapper.el.querySelector('.funky-table-length-select');
		if (select) {
			select.value = length;
			// Update ComboBox if used
			var combo = Funky.ComboBox && Funky.ComboBox.getInstance(select);
			if (combo) {
				combo.setValue(length);
			}
		}

		this._loadData();
		return this;
	};

	// =========================================================================
	// Public API
	// =========================================================================

	/**
	 * Destroy the table instance
	 */
	TableInstance.prototype.destroy = function() {
		this._unbindEvents();

		// Clear keyboard handlers
		if (this._keyboardUnregisters && this._keyboardUnregisters.length) {
			this._keyboardUnregisters.forEach(function(unregister) {
				if (typeof unregister === 'function') {
					unregister();
				}
			});
			this._keyboardUnregisters = [];
		}

		// Clear timeouts
		if (this.searchTimeout) {
			clearTimeout(this.searchTimeout);
		}

		// Cleanup visibility observer
		if (this._visibilityObserver) {
			this._visibilityObserver.disconnect();
			this._visibilityObserver = null;
		}

		// Cleanup live binding (WebSocket, SSE, polling)
		this.destroyLiveBinding();

		// Cleanup accessibility
		this._destroyAccessibility();

		// Cleanup WebSocket PubSub handlers
		this._destroyWebSocket();

		// Remove from registry
		var containerId = this.container.id || this.id;
		_instances.unregister(containerId);

		// Remove DOM
		if (this.wrapper && this.wrapper.el && this.wrapper.el.parentNode) {
			this.wrapper.el.parentNode.removeChild(this.wrapper.el);
		}

		this.isDestroyed = true;

		// Emit event
		if (P && P.emit) {
			P.emit('funky:table:destroy', { id: this.id });
		}

		if (this.config.debug) {
			console.log('[Funky.Table] Destroyed:', this.id);
		}
	};

	// =========================================================================
	// Static Methods
	// =========================================================================

	/**
	 * Initialize a table
	 * @param {string|HTMLElement} selector - Selector or element
	 * @param {Object} options - Configuration
	 * @returns {TableInstance}
	 */
	Table.init = function(selector, options) {
		var element = typeof selector === 'string'
			? document.querySelector(selector)
			: selector;

		if (!element) {
			console.error('[Funky.Table] Element not found:', selector);
			return null;
		}

		// Check for existing instance by element
		var existingInstance = _instances.getByElement(element);
		if (existingInstance) {
			return existingInstance;
		}

		var instance = new TableInstance(element, options);
		return instance;
	};

	/**
	 * Get instance by ID or element
	 * @param {string|HTMLElement} idOrElement
	 * @returns {TableInstance|null}
	 */
	Table.getInstance = function(idOrElement) {
		if (typeof idOrElement === 'string') {
			// Try as ID first
			var byId = _instances.get(idOrElement);
			if (byId) return byId;
			// Try as selector
			var element = document.querySelector(idOrElement);
			return element ? _instances.getByElement(element) : null;
		}
		return idOrElement ? _instances.getByElement(idOrElement) : null;
	};

	/**
	 * Destroy a table instance
	 * @param {string|HTMLElement} idOrElement
	 */
	Table.destroy = function(idOrElement) {
		var instance = Table.getInstance(idOrElement);
		if (instance) {
			instance.destroy();
		}
	};

	/**
	 * Destroy all table instances
	 */
	Table.destroyAll = function() {
		_instances.destroyAll();
	};

	/**
	 * Get all instances as a Map
	 * @returns {Map}
	 */
	Table.getAll = function() {
		return _instances.getMap();
	};

	/**
	 * Instances registry (Map-like interface)
	 * Returns a live Map of current instances
	 * @type {Map}
	 */
	Object.defineProperty(Table, 'instances', {
		get: function() {
			return _instances.getMap ? _instances.getMap() : new Map();
		},
		enumerable: true,
		configurable: true
	});

	// =========================================================================
	// Register Module
	// =========================================================================

	Funky.register('Table', Table);

})(window, document);
