/**
 * Funky SPA - Single Page Application Navigation
 * Vanilla JavaScript (no jQuery dependency for core functionality)
 * 
 * Intercepts internal navigation, loads content via AJAX,
 * updates URL with History API, and reinitializes page-specific JS.
 * @module Funky.SPA
 */
(function(window, document) {
	'use strict';

	// Registry guard - prevent double registration
	if (typeof Funky !== 'undefined' && Funky.isRegistered && Funky.isRegistered('SPA')) {
		return;
	}

	// ============================================
	// SPA CONFIGURATION
	// ============================================
	var SPA = {
		config: {
			contentSelector: '#spaContent',
			loadingSelector: '#spaLoading',
			titleSelector: 'title',
			// Links to exclude from SPA handling
			excludePatterns: [
				/^https?:\/\//, // External links
				/^mailto:/, // Email links
				/^tel:/, // Phone links
				/^javascript:/, // JS links
				/\.(pdf|zip|csv|xlsx?)$/i, // File downloads
				/\/api\//, // API endpoints
				/\/logout/ // Logout (needs full reload)
			],
			// Selectors for elements that should not trigger SPA navigation
			excludeSelectors: [
				'[data-no-spa]',
				'[target="_blank"]',
				'[download]',
				'.no-spa'
			],

			// Idle detection options
			enableIdleDetection: true,      // Enable idle detection
			idleTimeout: 300000,            // 5 minutes until idle
			awayTimeout: 60000,             // 1 minute until away (when hidden)
			staleDataThreshold: 300000,     // Refresh data if away > 5 min

			// Callbacks
			onIdle: null,
			onActive: null,
			onAway: null,
			onReturn: null,

			// History API options
			disableHistory: false  // If true, skip pushState/replaceState/popstate (for iframes)
		},

		// Page-specific initialization functions registry
		pageInitializers: {},

		// Page-specific cleanup functions registry
		pageCleanup: {},

		// Current page identifier
		currentPage: null,

		// Flag to prevent double initialization
		initialized: false,

		// Handler references for cleanup
		_clickHandler: null,
		_popstateHandler: null,
		_modalShowHandler: null,
		_modalHiddenHandler: null,

		// Presence integration state
		_presenceEnabled: false,
		_currentPresenceChannel: null,
		_presenceOptions: null,
		_beforeUnloadHandler: null,
		_visibilityChangeHandler: null
	};

	// ============================================
	// INITIALIZATION
	// ============================================

	/**
	 * Initialize the SPA system
	 * Safe to call multiple times - will only init once
	 */
	SPA.init = function() {
		if (SPA.initialized) {
			return;
		}

		// Check if we have the required elements
		if (!document.querySelector(SPA.config.contentSelector)) {
			console.warn('[SPA] Content container not found:', SPA.config.contentSelector);
			return;
		}

		// Bind navigation handlers
		SPA.bindNavigation();

		// Handle browser back/forward (skip if history is disabled, e.g., in iframes)
		if (!SPA.config.disableHistory) {
			SPA.bindPopState();

			// Store initial state (may be updated later if this is a sub-route)
			if (window.history && window.history.replaceState) {
				window.history.replaceState({ url: window.location.href, title: document.title },
					document.title,
					window.location.href
				);
			}
		}

		// Get current page from body or content
		SPA.currentPage = SPA.detectCurrentPage();

		// Fix modal stacking issues
		SPA.fixModalStacking();

		// Initialize idle detection for resource optimization
		SPA._initIdleDetector();

		SPA.initialized = true;
		console.log('[SPA] Initialized successfully');

		// Note: SubRouter.handleInitialLoad() is called after page scripts register their handlers
		// This happens in handlePageLoad() or can be called manually by pages
	};

	// ============================================
	// NAVIGATION BINDING
	// ============================================

	/**
	 * Bind click handlers for navigation
	 * Uses event delegation on document for efficiency
	 */
	SPA.bindNavigation = function() {
		// Store handler reference for cleanup
		SPA._clickHandler = function(event) {
			// Check for modifier keys (open in new tab)
			if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
				return;
			}

			// Find the closest anchor element
			var link = event.target.closest('a[href]');

			if (!link) {
				return;
			}

			// Check if this link should be handled by SPA
			if (!SPA.shouldHandleLink(link)) {
				return;
			}

			// Prevent default navigation
			event.preventDefault();

			console.log('[SPA] Navigating to:', link.href);

			// Navigate via SPA
			SPA.navigate(link.href);
		};
		document.addEventListener('click', SPA._clickHandler, false);

		console.log('[SPA] Navigation handlers bound');
	};

	/**
	 * Bind popstate handler for browser back/forward
	 */
	SPA.bindPopState = function() {
		// Track the last URL to detect hash-only changes
		var lastUrl = window.location.href.split('#')[0];

		// Store handler reference for cleanup
		SPA._popstateHandler = function(event) {
			var currentUrl = window.location.href.split('#')[0];

			// If only the hash changed (same base URL), let browser handle natively
			if (currentUrl === lastUrl && window.location.hash) {
				return;
			}

			lastUrl = currentUrl;

			// Check for sub-route navigation first
			if (SPA.SubRouter && SPA.SubRouter.handlePopstate(event.state)) {
				// SubRouter handled it - don't reload the page
				return;
			}

			// Standard SPA navigation
			if (event.state && event.state.url) {
				// Restore title from state if available
				if (event.state.title) {
					document.title = event.state.title;
				}
				SPA.loadPage(event.state.url, false);
			} else {
				// Fallback: reload the current URL
				SPA.loadPage(window.location.href, false);
			}
		};
		window.addEventListener('popstate', SPA._popstateHandler, false);
	};

	/**
	 * Determine if a link should be handled by the SPA
	 * @param {HTMLElement} link - The anchor element
	 * @returns {boolean}
	 */
	SPA.shouldHandleLink = function(link) {
		// Guard against null/undefined
		if (!link || typeof link.getAttribute !== 'function') {
			return false;
		}
		var href = link.getAttribute('href');

		// No href or empty
		if (!href || href === '' || href === '#') {
			return false;
		}

		// Hash-only links (same-page anchors) - let browser handle natively
		if (href.charAt(0) === '#') {
			return false;
		}

		// Check exclude patterns
		for (var i = 0; i < SPA.config.excludePatterns.length; i++) {
			if (SPA.config.excludePatterns[i].test(href)) {
				return false;
			}
		}

		// Check exclude selectors
		for (var j = 0; j < SPA.config.excludeSelectors.length; j++) {
			if (link.matches(SPA.config.excludeSelectors[j])) {
				return false;
			}
		}

		// Check for modifier keys (open in new tab)
		// This is handled at click time, not here

		// Check if same origin
		try {
			var url = new URL(href, window.location.origin);
			if (url.origin !== window.location.origin) {
				return false;
			}
			
			// Same-page hash navigation - let browser handle natively
			// This catches links like "/about#section" when already on /about
			if (url.pathname === window.location.pathname && 
				url.search === window.location.search &&
				url.hash) {
				return false;
			}
		} catch (e) {
			return false;
		}

		return true;
	};

	// ============================================
	// PAGE LOADING
	// ============================================

	/**
	 * Navigate to a URL via SPA
	 * @param {string} url - The URL to navigate to
	 */
	SPA.navigate = function(url) {
		// Guard against null/empty URL
		if (!url || typeof url !== 'string') {
			return;
		}

		// Normalize URL for comparison
		var normalizedUrl = new URL(url, window.location.origin).href;

		// Don't navigate to the same page (without hash difference)
		if (normalizedUrl === window.location.href) {
			return;
		}

		// Check if this is just a hash change on the same page
		try {
			var currentUrl = new URL(window.location.href);
			var targetUrl = new URL(url, window.location.origin);

			// Same path, just different hash - let browser handle natively
			if (currentUrl.origin === targetUrl.origin &&
				currentUrl.pathname === targetUrl.pathname &&
				currentUrl.search === targetUrl.search &&
				targetUrl.hash) {
				// Update URL and scroll to element (skip if history disabled)
				if (!SPA.config.disableHistory) {
					window.history.pushState({ url: url }, '', url);
				}
				var element = document.querySelector(targetUrl.hash);
				if (element) {
					element.scrollIntoView({ behavior: 'smooth' });
				}
				return;
			}
		} catch (e) {
			// URL parsing failed, proceed with normal navigation
		}

		// When history is disabled, never push state
		var shouldPushState = !SPA.config.disableHistory;
		SPA.loadPage(url, shouldPushState);
	};

	/**
	 * Load a page via AJAX
	 * @param {string} url - The URL to load
	 * @param {boolean} pushState - Whether to push to history
	 */
	SPA.loadPage = function(url, pushState) {
		// Guard against concurrent loads of the same URL
		if (SPA._loadingUrl === url) {
			return;
		}
		SPA._loadingUrl = url;

		// Check if we have a URL-to-pageId mapping from previous loads
		var targetPageId = SPA._urlToPageId && SPA._urlToPageId[url];

		// Check Funky.Pages cache first
		if (targetPageId && Funky.Pages && Funky.Pages.cache.has(targetPageId)) {
			var cached = Funky.Pages.cache.get(targetPageId);
			if (cached) {
				SPA.loadFromCache(url, pushState, targetPageId, cached);
				return;
			}
		}

		// Cache miss - fetch from server
		SPA.loadFromServer(url, pushState);
	};

	// URL to pageId mapping for cache lookups
	SPA._urlToPageId = {};

	/**
	 * Extract page ID from URL
	 * @param {string} url
	 * @returns {string|null}
	 */
	SPA.extractPageIdFromUrl = function(url) {
		try {
			var path = new URL(url, window.location.origin).pathname;

			// Convert path to page ID:
			// - Strip leading slashes
			// - Replace remaining slashes with underscores (for nested routes)
			// - Default to 'dashboard' for root
			var pageId = path.replace(/^\/+/, '').replace(/\//g, '_');
			return pageId || 'dashboard';
		} catch (e) {
			return null;
		}
	};

	/**
	 * Load page from cache
	 * @param {string} url
	 * @param {boolean} pushState
	 * @param {string} pageId
	 * @param {Object} cached
	 */
	SPA.loadFromCache = function(url, pushState, pageId, cached) {
		// Show brief loading indicator
		SPA.showLoading();

		// Unmount current page
		var currentPageId = SPA.currentPage;
		if (currentPageId && Funky.Pages && Funky.Pages.has(currentPageId)) {
			Funky.Pages.unmount(currentPageId);
		} else {
			SPA.cleanupCurrentPage();
		}

		// Start transition
		var content = document.querySelector(SPA.config.contentSelector);

		// Try PageAnimate exit animation if available
		var currentPageEl = content ? content.querySelector('[data-page]') : null;
		var currentPageName = currentPageEl ? currentPageEl.getAttribute('data-page') : null;

		if (content && currentPageName && window.Funky && window.Funky.PageAnimate) {
			// Use PageAnimate for exit
			Funky.PageAnimate.exit(currentPageEl, currentPageName, function() {
				continueLoadFromCache();
			});
		} else if (content) {
			// Fallback to existing behavior
			content.classList.remove('spa-content-visible', 'spa-transitioning-in');
			content.classList.add('spa-transitioning-out');
			// Brief delay for transition
			requestAnimationFrame(continueLoadFromCache);
		}

		function continueLoadFromCache() {
			// Inject cached HTML
			if (content) {
				content.innerHTML = cached.html;
				content.dataset.page = pageId;

				// Try PageAnimate enter animation if available
				var newPageEl = content.querySelector('[data-page]');
				var newPageName = newPageEl ? newPageEl.getAttribute('data-page') : null;

				if (newPageName && window.Funky && window.Funky.PageAnimate) {
					// Use PageAnimate for enter
					Funky.PageAnimate.enter(newPageEl, newPageName);
					// Mark content as visible
					setTimeout(function() {
						content.classList.add('spa-content-visible');
					}, 50);
				} else {
					// Fallback to existing behavior
					content.classList.remove('spa-transitioning-out');
					content.classList.add('spa-transitioning-in');
				}
			}

			// Update page title from cached breadcrumbTitle
			var breadcrumbTitle = cached.state && cached.state.breadcrumbTitle;
			if (breadcrumbTitle) {
				document.title = 'Funky Frame - ' + breadcrumbTitle;
				var pageTitleEl = document.querySelector('.page-title');
				if (pageTitleEl) {
					pageTitleEl.textContent = breadcrumbTitle;
				}
			}

			// Update URL with correct title (skip if history disabled)
			if (pushState && !SPA.config.disableHistory && window.history && window.history.pushState) {
				window.history.pushState({ url: url, title: document.title },
					document.title,
					url
				);
			}

			// Update navigation
			SPA.updateNavigation(url);
			SPA.currentPage = pageId;

			// Mount the page (calls init with cached state)
			if (Funky.Pages && Funky.Pages.has(pageId)) {
				Funky.Pages.mount(pageId, cached);
			} else {
				// Fallback: execute scripts in cached HTML
				SPA.initializePage();
			}

			// Check for sub-route activation after page init
			if (SPA.SubRouter) {
				requestAnimationFrame(function() {
					SPA.SubRouter.handleInitialLoad();
				});
			}

			// Update presence channel for new page
			if (SPA._presenceEnabled) {
				var opts = SPA._presenceOptions || {};
				var presencePath = new URL(url, window.location.origin).pathname;
				if (opts.trackQueryParams) {
					presencePath += new URL(url, window.location.origin).search;
				}
				SPA._joinPageChannel(presencePath);
			}

			// Dispatch spa:pageload event for breadcrumb and other components
			var pageloadEvent = new CustomEvent('funky.spa.pageload', {
				detail: {
					page: pageId,
					url: url,
					managed: Funky.Pages && Funky.Pages.isManaged(pageId),
					cached: true
				}
			});
			document.dispatchEvent(pageloadEvent);

			// Complete transition
			requestAnimationFrame(function() {
				if (content) {
					content.classList.remove('spa-transitioning-in');
					content.classList.add('spa-content-visible');
				}
				SPA.hideLoading();
			});

			// Clear loading flag
			SPA._loadingUrl = null;
		}
	};

	/**
	 * Load page from server (original fetch logic)
	 * @param {string} url
	 * @param {boolean} pushState
	 */
	SPA.loadFromServer = function(url, pushState) {
		// Show loading indicator
		SPA.showLoading();

		// Start exit transition
		var content = document.querySelector(SPA.config.contentSelector);

		// Try PageAnimate exit animation if available
		var currentPageEl = content ? content.querySelector('[data-page]') : null;
		var currentPageName = currentPageEl ? currentPageEl.getAttribute('data-page') : null;

		if (content && currentPageName && window.Funky && window.Funky.PageAnimate) {
			// Use PageAnimate for exit
			Funky.PageAnimate.exit(currentPageEl, currentPageName, function() {
				// Cleanup current page
				SPA.cleanupCurrentPage();
				performFetch();
			});
		} else {
			// Fallback to existing behavior
			if (content) {
				content.classList.remove('spa-content-visible', 'spa-transitioning-in');
				content.classList.add('spa-transitioning-out');
			}
			// Cleanup current page
			SPA.cleanupCurrentPage();
			performFetch();
		}

		function performFetch() {

		// Fetch the page
		fetch(url, {
				method: 'GET',
				headers: {
					'X-Requested-With': 'XMLHttpRequest',
					'Accept': 'text/html'
				},
				credentials: 'same-origin'
			})
			.then(function(response) {
				if (!response.ok) {
					throw new Error('Network response was not ok: ' + response.status);
				}
				return response.text();
			})
			.then(function(html) {
				SPA.handlePageLoad(html, url, pushState);
			})
			.catch(function(error) {
				console.error('[SPA] Load failed:', error);
				// Fallback to traditional navigation (skip in test sandbox to prevent iframe navigation)
				if (!window.FUNKY_TEST_SANDBOX) {
					window.location.href = url;
				}
			})
			.finally(function() {
				SPA.hideLoading();
				SPA._loadingUrl = null;
			});
		}
	};

	/**
	 * Handle the loaded page HTML
	 * @param {string} html - The HTML content
	 * @param {string} url - The URL that was loaded
	 * @param {boolean} pushState - Whether to push to history
	 */
	SPA.handlePageLoad = function(html, url, pushState) {
		// Parse the HTML
		var parser = new DOMParser();
		var doc = parser.parseFromString(html, 'text/html');

		// Get current content container
		var currentContent = document.querySelector(SPA.config.contentSelector);

		if (!currentContent) {
			// Fallback: if we can't find current content container, do full reload
			console.warn('[SPA] Current content container not found, falling back to full reload');
			// Skip navigation in test sandbox to prevent iframe navigation
			if (!window.FUNKY_TEST_SANDBOX) {
				window.location.href = url;
			}
			return;
		}

		// Try to extract content from response
		// If it's a full page response (has the content selector), use that
		// Otherwise, the response IS the content (AJAX response without layout)
		var newContent = doc.querySelector(SPA.config.contentSelector);
		var newHTML;
		var newTitle;
		var newPageData;

		if (newContent) {
			// Full page response - extract content from wrapper
			newHTML = newContent.innerHTML;
			newTitle = doc.querySelector('title');
			newPageData = newContent.dataset.page;
		} else {
			// AJAX response - the body IS the content
			newHTML = doc.body.innerHTML;
			// Try to get title from a meta tag or title element that might exist
			newTitle = doc.querySelector('title');
			// Try to get page data from first element with data-page
			var pageEl = doc.querySelector('[data-page]');
			newPageData = pageEl ? pageEl.dataset.page : null;
		}

		// Update page title from <title> element
		if (newTitle) {
			document.title = newTitle.textContent;
		}

		// Update page header title from data-breadcrumb-title attribute
		var breadcrumbEl = newContent ? newContent.querySelector('[data-breadcrumb-title]') : null;
		if (!breadcrumbEl) {
			// Fallback: check in the full doc body
			breadcrumbEl = doc.querySelector('[data-breadcrumb-title]');
		}
		var currentPageTitle = document.querySelector('.page-title');
		if (currentPageTitle && breadcrumbEl) {
			var pageTitle = breadcrumbEl.getAttribute('data-breadcrumb-title');
			if (pageTitle) {
				currentPageTitle.textContent = pageTitle;
			}
		}

		// Replace content
		currentContent.innerHTML = newHTML;

		// Update data-page attribute
		if (newPageData) {
			currentContent.dataset.page = newPageData;
		}

		// Try PageAnimate enter animation if available
		var newPageEl = currentContent.querySelector('[data-page]');
		var newPageName = newPageEl ? newPageEl.getAttribute('data-page') : null;

		if (newPageName && window.Funky && window.Funky.PageAnimate) {
			// Use PageAnimate for enter
			requestAnimationFrame(function() {
				Funky.PageAnimate.enter(newPageEl, newPageName);
				// Mark content as visible
				setTimeout(function() {
					currentContent.classList.add('spa-content-visible');
				}, 50);
			});
		} else {
			// Fallback to existing behavior
			currentContent.classList.remove('spa-transitioning-out');
			currentContent.classList.add('spa-transitioning-in');

			// Trigger enter animation after a brief delay to allow DOM to settle
			requestAnimationFrame(function() {
				requestAnimationFrame(function() {
					currentContent.classList.remove('spa-transitioning-in');
					currentContent.classList.add('spa-content-visible');
				});
			});
		}

		// Update URL (skip if history disabled)
		if (pushState && !SPA.config.disableHistory && window.history && window.history.pushState) {
			window.history.pushState({ url: url, title: document.title },
				document.title,
				url
			);
		}

		// Update navigation active states
		SPA.updateNavigation(url);

		// Detect and store new page
		SPA.currentPage = SPA.detectCurrentPage();

		// Scroll to top
		window.scrollTo(0, 0);

		// Initialize new page
		SPA.initializePage();

		// Check for sub-route activation after page init
		if (SPA.SubRouter) {
			requestAnimationFrame(function() {
				SPA.SubRouter.handleInitialLoad();
			});
		}

		// Update presence channel for new page
		if (SPA._presenceEnabled) {
			var opts = SPA._presenceOptions || {};
			var presencePath = new URL(url, window.location.origin).pathname;
			if (opts.trackQueryParams) {
				presencePath += new URL(url, window.location.origin).search;
			}
			SPA._joinPageChannel(presencePath);
		}

		// Cache the page for future navigation (if Pages is available)
		var pageId = SPA.currentPage;
		if (Funky.Pages && pageId) {
			// Cache the inner HTML and breadcrumb title
			var breadcrumbTitle = breadcrumbEl ? breadcrumbEl.getAttribute('data-breadcrumb-title') : null;
			Funky.Pages.cache.set(pageId, newHTML, { scrollY: 0, breadcrumbTitle: breadcrumbTitle });

			// Store URL-to-pageId mapping for cache lookups
			SPA._urlToPageId[url] = pageId;

			// Dispatch spa:pagecached event
			var cachedEvent = new CustomEvent('funky.spa.page-cached', {
				detail: { page: pageId, url: url }
			});
			document.dispatchEvent(cachedEvent);

			// If the page registered itself but didn't mount, mount it now
			if (Funky.Pages.has(pageId) && !Funky.Pages.isManaged(pageId)) {
				Funky.Pages.mount(pageId);
			}
		}

		// Clear loading flag
		SPA._loadingUrl = null;
	};

	// ============================================
	// PAGE INITIALIZATION & CLEANUP
	// ============================================

	/**
	 * Detect the current page identifier
	 * @returns {string|null}
	 */
	SPA.detectCurrentPage = function() {
		// Try to get from body data attribute
		var body = document.body;
		if (body.dataset.page) {
			return body.dataset.page;
		}

		// Try to get from content container
		var content = document.querySelector(SPA.config.contentSelector);
		if (content && content.dataset.page) {
			return content.dataset.page;
		}

		// Fallback: derive from URL path
		return SPA.extractPageIdFromUrl(window.location.href);
	};

	/**
	 * Cleanup the current page before loading new one
	 */
	SPA.cleanupCurrentPage = function() {
		var page = SPA.currentPage;

		// Dispatch beforeload event for API request cancellation
		var beforeLoadEvent = new CustomEvent('funky.spa.before-load', {
			detail: { page: page, url: window.location.href }
		});
		document.dispatchEvent(beforeLoadEvent);

		// Use Funky.Pages unmount if page is registered there
		if (page && Funky.Pages && Funky.Pages.has(page)) {
			Funky.Pages.unmount(page);
		} else if (page && SPA.pageCleanup[page]) {
			// Run page-specific cleanup if registered via legacy method
			try {
				SPA.pageCleanup[page]();
			} catch (e) {
				console.error('[SPA] Cleanup error for page:', page, e);
			}
		}

		// Check for Funky.register'd modules with destroy method (e.g., Funky.docs)
		if (page && Funky[page] && typeof Funky[page].destroy === 'function') {
			try {
				Funky[page].destroy();
				console.log('[SPA] Destroyed Funky.' + page);
			} catch (e) {
				console.error('[SPA] Error destroying Funky.' + page, e);
			}
		}

		// Generic cleanup
		SPA.genericCleanup();
	};

	/**
	 * Generic cleanup for common libraries
	 */
	SPA.genericCleanup = function() {
		// Destroy DataTables
		if (typeof jQuery !== 'undefined' && jQuery.fn.DataTable) {
			jQuery('.dataTable').each(function() {
				if (jQuery.fn.DataTable.isDataTable(this)) {
					jQuery(this).DataTable().destroy();
				}
			});
		}

		// Destroy ComboBox instances (only inside SPA content area, not global ones like timezone selector)
		if (window.Funky && Funky.Forms && Funky.Forms.destroyComboBox) {
			Funky.Forms.destroyComboBox('#spaContent');
		}

		// Destroy DateRangePicker
		if (typeof jQuery !== 'undefined') {
			jQuery('input[data-daterangepicker]').each(function() {
				var picker = jQuery(this).data('daterangepicker');
				if (picker) {
					picker.remove();
				}
			});
		}

		// Close any open modals
		if (typeof Funky !== 'undefined' && Funky.Modal) {
			Funky.Modal.hideAll();
		}

		// Clean up orphaned modal backdrops
		document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
			backdrop.parentNode.removeChild(backdrop);
		});

		// Remove dynamically created modals (appended to body by JS)
		// These are created by components like AdvancedFilter and need to be removed on navigation
		var dynamicModals = [
			'#advancedFilterModal',
			'#saveFilterModal',
			'#manageFiltersModal'
		];
		dynamicModals.forEach(function(selector) {
			var modal = document.querySelector(selector);
			if (modal) {
				// Dispose Funky.Modal instance first
				if (typeof Funky !== 'undefined' && Funky.Modal) {
					var instance = Funky.Modal.getInstance(modal);
					if (instance) {
						instance.dispose();
					}
				}
				modal.parentNode.removeChild(modal);
			}
		});

		// Remove modal-open class from body if no modals are open
		if (!document.querySelector('.modal.show')) {
			document.body.classList.remove('modal-open');
			document.body.style.removeProperty('overflow');
			document.body.style.removeProperty('padding-right');
		}

		// Clear any intervals/timeouts stored on window
		if (window.spaIntervals) {
			window.spaIntervals.forEach(function(id) {
				clearInterval(id);
			});
			window.spaIntervals = [];
		}

		if (window.spaTimeouts) {
			window.spaTimeouts.forEach(function(id) {
				clearTimeout(id);
			});
			window.spaTimeouts = [];
		}

		// Reset loading state
		document.body.classList.remove('spa-loading');
	};

	/**
	 * Initialize the newly loaded page
	 */
	SPA.initializePage = function() {
		var page = SPA.currentPage;

		// Run generic initialization
		SPA.genericInit();

		// Run page-specific initialization if registered (legacy method)
		if (page && SPA.pageInitializers[page]) {
			try {
				SPA.pageInitializers[page]();
			} catch (e) {
				console.error('[SPA] Init error for page:', page, e);
			}
		}

		// Dispatch custom event for other scripts
		var isManaged = Funky.Pages && page && Funky.Pages.isManaged(page);
		var event = new CustomEvent('funky.spa.pageload', {
			detail: {
				page: page,
				url: window.location.href,
				managed: isManaged // true if page uses Funky.Pages lifecycle
			}
		});
		document.dispatchEvent(event);
	};

	/**
	 * Generic initialization for common libraries
	 */
	SPA.genericInit = function() {
		// Re-run any inline scripts in the new content
		SPA.executeScripts();

		// Initialize tooltips
		if (window.Funky && Funky.Tooltip) {
			Funky.Tooltip.init('#spaContent');
		}

		// Initialize popovers
		if (window.Funky && Funky.Popover) {
			Funky.Popover.init('#spaContent');
		}

		// Initialize ComboBox on all select elements (via Funky.Forms if available)
		if (window.Funky && Funky.Forms && Funky.Forms.initComboBox) {
			Funky.Forms.initComboBox('#spaContent');
		}
	};

	/**
	 * Execute inline scripts in the loaded content
	 * Uses DOM insertion to execute scripts (CSP-safe)
	 * External scripts are skipped - they should use spa:pageload event for re-init
	 */
	SPA.executeScripts = function() {
		var content = document.querySelector(SPA.config.contentSelector);
		if (!content) return;

		var scripts = content.querySelectorAll('script');
		var scriptsArray = Array.from(scripts);

		scriptsArray.forEach(function(oldScript) {
			// Skip external scripts - they should listen for spa:pageload event
			if (oldScript.src) {
				oldScript.parentNode.removeChild(oldScript);
				return;
			}

			var scriptContent = oldScript.textContent;

			// Skip empty scripts
			if (!scriptContent.trim()) {
				return;
			}

			// Replace top-level let/const with var to avoid redeclaration errors
			var processedContent = scriptContent
				.replace(/(^|[\n\r;{}])\s*const\s+/g, '$1var ')
				.replace(/(^|[\n\r;{}])\s*let\s+/g, '$1var ');

			// Create a new script element
			var newScript = document.createElement('script');
			newScript.textContent = processedContent;

			// Copy any data attributes
			Array.from(oldScript.attributes).forEach(function(attr) {
				if (attr.name !== 'src') {
					newScript.setAttribute(attr.name, attr.value);
				}
			});

			// Remove old script
			oldScript.parentNode.removeChild(oldScript);

			// Append new script to document head (this executes it)
			try {
				document.head.appendChild(newScript);
			} catch (e) {
				console.error('[SPA] Script execution error:', e);
			}

			// Clean up - remove from head after execution
			document.head.removeChild(newScript);
		});
	};

	// ============================================
	// NAVIGATION STATE
	// ============================================

	/**
	 * Update navigation active states
	 * @param {string} url - The current URL
	 */
	SPA.updateNavigation = function(url) {
		var path = new URL(url, window.location.origin).pathname;

		// Remove all active states
		document.querySelectorAll('.sidebar-nav .nav-link.active').forEach(function(el) {
			el.classList.remove('active');
		});

		document.querySelectorAll('.sidebar-nav .nav-group.has-active').forEach(function(el) {
			el.classList.remove('has-active');
		});

		// Find and activate the matching link
		var links = document.querySelectorAll('.sidebar-nav .nav-link[href]');
		links.forEach(function(link) {
			var linkPath = link.getAttribute('href');
			if (linkPath === path) {
				link.classList.add('active');

				// Also activate parent group
				var group = link.closest('.nav-group');
				if (group) {
					group.classList.add('has-active');
					// Expand the group
					if (!group.classList.contains('expanded')) {
						group.classList.add('expanded');
					}
				}
			}
		});
	};

	// ============================================
	// LOADING INDICATOR
	// ============================================

	/**
	 * Show loading indicator (progress bar + content spinner)
	 */
	SPA.showLoading = function() {
		// Show progress bar (immediate, subtle feedback)
		var progressBar = document.getElementById('spaProgress');
		if (progressBar) {
			progressBar.classList.remove('complete');
			progressBar.classList.add('active');
		}

		// Delay showing content spinner for longer loads (300ms)
		SPA.loadingTimeout = setTimeout(function() {
			// Create content spinner if it doesn't exist
			var contentSpinner = document.querySelector('.spa-content-loading');
			if (!contentSpinner) {
				contentSpinner = document.createElement('div');
				contentSpinner.className = 'spa-content-loading';
				contentSpinner.innerHTML = '<div class="spa-loading-spinner"><div class="spinner-ring"></div><span class="spinner-text">Loading...</span></div>';
			}

			// Insert into spaContent
			var spaContent = document.querySelector('#spaContent');
			if (spaContent && !spaContent.contains(contentSpinner)) {
				spaContent.appendChild(contentSpinner);
			}

			// Show the spinner
			if (contentSpinner) {
				contentSpinner.classList.add('active');
			}
		}, 300);

		// Also add loading state to body (keeps pointer-events disabled)
		document.body.classList.add('spa-loading');
	};

	/**
	 * Hide loading indicator
	 */
	SPA.hideLoading = function() {
		// Clear the spinner timeout
		if (SPA.loadingTimeout) {
			clearTimeout(SPA.loadingTimeout);
			SPA.loadingTimeout = null;
		}

		// Complete progress bar animation
		var progressBar = document.getElementById('spaProgress');
		if (progressBar) {
			progressBar.classList.add('complete');
			// Remove after transition
			setTimeout(function() {
				progressBar.classList.remove('active', 'complete');
			}, 200);
		}

		// Hide content spinner
		var contentSpinner = document.querySelector('.spa-content-loading');
		if (contentSpinner) {
			contentSpinner.classList.remove('active');
		}

		document.body.classList.remove('spa-loading');
	};

	// ============================================
	// PUBLIC API
	// ============================================

	/**
	 * Register a page initializer
	 * @param {string} page - Page identifier
	 * @param {function} fn - Initialization function
	 */
	SPA.registerPage = function(page, fn) {
		SPA.pageInitializers[page] = fn;
	};

	/**
	 * Register a page cleanup function
	 * @param {string} page - Page identifier
	 * @param {function} fn - Cleanup function
	 */
	SPA.registerCleanup = function(page, fn) {
		SPA.pageCleanup[page] = fn;
	};

	/**
	 * Register an interval that should be cleared on page change
	 * @param {number} id - Interval ID from setInterval
	 */
	SPA.registerInterval = function(id) {
		window.spaIntervals = window.spaIntervals || [];
		window.spaIntervals.push(id);
		return id;
	};

	/**
	 * Register a timeout that should be cleared on page change
	 * @param {number} id - Timeout ID from setTimeout
	 */
	SPA.registerTimeout = function(id) {
		window.spaTimeouts = window.spaTimeouts || [];
		window.spaTimeouts.push(id);
		return id;
	};

	/**
	 * Manually trigger navigation (for programmatic use)
	 * @param {string} url - URL to navigate to
	 */
	SPA.go = function(url) {
		SPA.navigate(url);
	};

	/**
	 * Refresh the current page via AJAX
	 */
	SPA.refresh = function() {
		SPA.loadPage(window.location.href, false);
	};

	// ============================================
	// MODAL Z-INDEX FIX
	// Move modals to body level when shown to escape
	// stacking context created by #spaContent transforms
	// ============================================

	/**
	 * Fix modal stacking by moving modals to body when shown
	 */
	SPA.fixModalStacking = function() {
		// Store handler references for cleanup
		SPA._modalShowHandler = function(event) {
			var modal = event.target;

			// Only move if modal is inside #spaContent
			if (modal.closest('#spaContent')) {
				// Store original parent to restore later if needed
				modal._spaOriginalParent = modal.parentNode;
				modal._spaOriginalNextSibling = modal.nextSibling;

				// Move to body
				document.body.appendChild(modal);
			}
		};

		SPA._modalHiddenHandler = function(event) {
			var modal = event.target;

			// If we moved this modal, we could restore it, but it's not necessary
			// since SPA navigation will reload the content anyway
		};

		// Listen for Funky.Modal show events
		document.addEventListener('funky.modal.show', SPA._modalShowHandler);

		// Optionally restore modal position after hidden (not strictly necessary)
		document.addEventListener('funky.modal.hidden', SPA._modalHiddenHandler);
	};

	// ============================================
	// IDLE DETECTION INTEGRATION
	// ============================================

	/**
	 * Initialize idle detection for resource optimization
	 * Called automatically during SPA.init() if enableIdleDetection is true
	 * @private
	 */
	SPA._initIdleDetector = function() {
		if (!SPA.config.enableIdleDetection) {
			return;
		}

		if (!Funky.IdleDetector) {
			console.warn('[SPA] IdleDetector not available');
			return;
		}

		// Initialize IdleDetector with SPA-specific options
		Funky.IdleDetector.init({
			idleTimeout: SPA.config.idleTimeout,
			awayTimeout: SPA.config.awayTimeout,
			trackVisibility: true,

			onIdle: function(data) {
				SPA._onUserIdle(data);
			},

			onActive: function(data) {
				SPA._onUserActive(data);
			},

			onAway: function(data) {
				SPA._onUserAway(data);
			},

			onReturn: function(data) {
				SPA._onUserReturn(data);
			}
		});

		SPA._idleDetectorInitialized = true;
		console.log('[SPA] IdleDetector initialized');
	};

	/**
	 * Handle user becoming idle
	 * @private
	 */
	SPA._onUserIdle = function(data) {
		// Add CSS class to pause animations
		document.documentElement.classList.add('user-idle');

		// Emit event for other components
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:spa:idle', data);
		}

		// Call user callback if provided
		if (SPA.config.onIdle && typeof SPA.config.onIdle === 'function') {
			try {
				SPA.config.onIdle(data);
			} catch (e) {
				console.error('[SPA] onIdle callback error:', e);
			}
		}

		console.log('[SPA] User idle');
	};

	/**
	 * Handle user becoming active
	 * @private
	 */
	SPA._onUserActive = function(data) {
		// Remove CSS class to resume animations
		document.documentElement.classList.remove('user-idle');

		// Emit event for other components
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:spa:active', data);
		}

		// Call user callback if provided
		if (SPA.config.onActive && typeof SPA.config.onActive === 'function') {
			try {
				SPA.config.onActive(data);
			} catch (e) {
				console.error('[SPA] onActive callback error:', e);
			}
		}

		console.log('[SPA] User active');
	};

	/**
	 * Handle user going away (tab hidden)
	 * @private
	 */
	SPA._onUserAway = function(data) {
		// Add away class
		document.documentElement.classList.add('user-away');

		// Emit event
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:spa:away', data);
		}

		// Call user callback if provided
		if (SPA.config.onAway && typeof SPA.config.onAway === 'function') {
			try {
				SPA.config.onAway(data);
			} catch (e) {
				console.error('[SPA] onAway callback error:', e);
			}
		}

		console.log('[SPA] User away');
	};

	/**
	 * Handle user returning (tab visible)
	 * @private
	 */
	SPA._onUserReturn = function(data) {
		// Remove away class
		document.documentElement.classList.remove('user-away');

		// Refresh stale data if away too long
		if (data.awayDuration > SPA.config.staleDataThreshold) {
			SPA._refreshStaleData();
		}

		// Emit event
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:spa:return', data);
		}

		// Call user callback if provided
		if (SPA.config.onReturn && typeof SPA.config.onReturn === 'function') {
			try {
				SPA.config.onReturn(data);
			} catch (e) {
				console.error('[SPA] onReturn callback error:', e);
			}
		}

		console.log('[SPA] User returned after', data.awayDuration, 'ms');
	};

	/**
	 * Refresh stale data after long absence
	 * Emits event for pages to handle their own refresh logic
	 * @private
	 */
	SPA._refreshStaleData = function() {
		console.log('[SPA] Refreshing stale data');

		// Emit event for components to refresh
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:spa:refresh-stale', {
				page: SPA.currentPage,
				url: window.location.href
			});
		}

		// Dispatch DOM event
		var event = new CustomEvent('funky.spa.refresh-stale', {
			detail: {
				page: SPA.currentPage,
				url: window.location.href
			}
		});
		document.dispatchEvent(event);
	};

	/**
	 * Check if user is currently idle
	 * @returns {boolean}
	 */
	SPA.isUserIdle = function() {
		return Funky.IdleDetector && Funky.IdleDetector.isIdle();
	};

	/**
	 * Check if user is away (tab hidden)
	 * @returns {boolean}
	 */
	SPA.isUserAway = function() {
		return Funky.IdleDetector && Funky.IdleDetector.isAway();
	};

	/**
	 * Get time since last activity
	 * @returns {number} Milliseconds
	 */
	SPA.getIdleTime = function() {
		return Funky.IdleDetector ? Funky.IdleDetector.getIdleTime() : 0;
	};

	/**
	 * Manually trigger activity (reset idle timer)
	 */
	SPA.triggerActivity = function() {
		if (Funky.IdleDetector) {
			Funky.IdleDetector.triggerActivity();
		}
	};

	// ============================================
	// PRESENCE INTEGRATION
	// ============================================

	/**
	 * Join a page presence channel
	 * @param {string} path - Page path
	 * @private
	 */
	SPA._joinPageChannel = function(path) {
		if (!SPA._presenceEnabled || !Funky.Presence) return;

		var opts = SPA._presenceOptions || {};
		var channel = opts.channelPrefix + path;

		// Leave previous channel if different
		if (SPA._currentPresenceChannel && SPA._currentPresenceChannel !== channel) {
			Funky.Presence.leave(SPA._currentPresenceChannel);
		}

		// Join new channel
		SPA._currentPresenceChannel = channel;
		Funky.Presence.join(channel, {
			status: opts.defaultStatus,
			metadata: {
				title: document.title,
				url: window.location.href
			}
		});

		console.log('[SPA] Joined presence channel:', channel);
	};

	/**
	 * Enable presence tracking for SPA navigation
	 * Automatically joins/leaves page channels as user navigates
	 * @param {Object} options - Presence options
	 * @param {string} options.channelPrefix - Prefix for page channels (default: 'page:')
	 * @param {string} options.defaultStatus - Default status when joining (default: 'viewing')
	 * @param {boolean} options.trackQueryParams - Include query params in channel (default: false)
	 */
	SPA.enablePresence = function(options) {
		if (!Funky.Presence) {
			console.warn('[SPA] Funky.Presence not available');
			return;
		}

		options = options || {};
		SPA._presenceEnabled = true;

		SPA._presenceOptions = {
			channelPrefix: options.channelPrefix || 'page:',
			defaultStatus: options.defaultStatus || 'viewing',
			trackQueryParams: options.trackQueryParams || false
		};

		// Set up beforeunload handler
		SPA._beforeUnloadHandler = function() {
			if (SPA._presenceEnabled && SPA._currentPresenceChannel && Funky.Presence) {
				Funky.Presence.leave(SPA._currentPresenceChannel);
			}
		};
		window.addEventListener('beforeunload', SPA._beforeUnloadHandler);

		// Set up visibility change handler for away status
		SPA._visibilityChangeHandler = function() {
			if (!SPA._presenceEnabled || !Funky.Presence) return;

			if (document.visibilityState === 'hidden') {
				Funky.Presence.setStatus('away');
			} else if (document.visibilityState === 'visible') {
				Funky.Presence.setStatus('online');
			}
		};
		document.addEventListener('visibilitychange', SPA._visibilityChangeHandler);

		// Join current page immediately
		var path = window.location.pathname;
		if (options.trackQueryParams) {
			path += window.location.search;
		}
		SPA._joinPageChannel(path);

		console.log('[SPA] Presence tracking enabled');
	};

	/**
	 * Disable presence tracking
	 */
	SPA.disablePresence = function() {
		// Leave current channel
		if (SPA._currentPresenceChannel && Funky.Presence) {
			Funky.Presence.leave(SPA._currentPresenceChannel);
		}

		// Remove event handlers
		if (SPA._beforeUnloadHandler) {
			window.removeEventListener('beforeunload', SPA._beforeUnloadHandler);
			SPA._beforeUnloadHandler = null;
		}

		if (SPA._visibilityChangeHandler) {
			document.removeEventListener('visibilitychange', SPA._visibilityChangeHandler);
			SPA._visibilityChangeHandler = null;
		}

		SPA._presenceEnabled = false;
		SPA._currentPresenceChannel = null;
		SPA._presenceOptions = null;

		console.log('[SPA] Presence tracking disabled');
	};

	/**
	 * Get current presence channel
	 * @returns {string|null}
	 */
	SPA.getCurrentPresenceChannel = function() {
		return SPA._currentPresenceChannel;
	};

	/**
	 * Check if presence tracking is enabled
	 * @returns {boolean}
	 */
	SPA.isPresenceEnabled = function() {
		return SPA._presenceEnabled;
	};

	// ============================================
	// DESTROY / CLEANUP
	// ============================================

	/**
	 * Destroy SPA instance and cleanup all event listeners
	 * Call this when SPA is no longer needed
	 */
	SPA.destroy = function() {
		if (!SPA.initialized) return;

		// Remove click handler
		if (SPA._clickHandler) {
			document.removeEventListener('click', SPA._clickHandler, false);
			SPA._clickHandler = null;
		}

		// Remove popstate handler
		if (SPA._popstateHandler) {
			window.removeEventListener('popstate', SPA._popstateHandler, false);
			SPA._popstateHandler = null;
		}

		// Remove modal handlers
		if (SPA._modalShowHandler) {
			document.removeEventListener('funky.modal.show', SPA._modalShowHandler);
			SPA._modalShowHandler = null;
		}

		if (SPA._modalHiddenHandler) {
			document.removeEventListener('funky.modal.hidden', SPA._modalHiddenHandler);
			SPA._modalHiddenHandler = null;
		}

		// Cleanup IdleDetector
		if (SPA._idleDetectorInitialized && Funky.IdleDetector) {
			Funky.IdleDetector.destroy();
			SPA._idleDetectorInitialized = false;
		}

		// Cleanup presence tracking
		if (SPA._presenceEnabled) {
			SPA.disablePresence();
		}

		// Remove idle CSS classes
		document.documentElement.classList.remove('user-idle', 'user-away');

		// Reset state
		SPA.initialized = false;
		SPA.currentPage = null;
		SPA.pageInitializers = {};
		SPA.pageCleanup = {};

		console.log('[SPA] Destroyed successfully');
	};

	// ============================================
	// SUBROUTER - Sub-path routing for components
	// ============================================

	/**
	 * SubRouter enables components to manage URL sub-paths and query params
	 * while maintaining full History API integration.
	 *
	 * @example
	 * // Register a handler
	 * SPA.SubRouter.register('/docs', {
	 *     activate: function(context) {
	 *         loadDoc(context.subPath);
	 *         return { docId: context.subPath };
	 *     },
	 *     restore: function(state, context) {
	 *         loadDoc(state.docId || context.subPath);
	 *     }
	 * });
	 *
	 * // Push a sub-route
	 * SPA.SubRouter.push('/docs', 'architecture', { docId: 'architecture' });
	 * // URL → /docs/architecture
	 */
	SPA.SubRouter = (function() {

		// Use ConfigRegistry for handler storage with validation
		var handlers = Funky.Registry ? Funky.Registry.create('SubRouterHandlers', {
			validate: function(handler) {
				if (!handler || typeof handler !== 'object') return false;
				if (typeof handler.activate !== 'function') {
					console.error('[SPA.SubRouter] Handler must have activate function');
					return false;
				}
				if (typeof handler.restore !== 'function') {
					console.error('[SPA.SubRouter] Handler must have restore function');
					return false;
				}
				return true;
			}
		}) : null;

		// Fallback if Registry not available
		var _handlers = {};

		/**
		 * Parse URL to extract base path, sub-path, and query params
		 * Only matches registered base paths
		 * @private
		 * @param {string} url - URL to parse
		 * @returns {Object|null} Parsed info or null if no handler matches
		 */
		function parseUrl(url) {
			try {
				var parsed = new URL(url, window.location.origin);
				var pathname = parsed.pathname;

				// Get registered base paths
				var basePaths = handlers ? handlers.list() : Object.keys(_handlers);

				// Find matching base path (longest match wins)
				var matchedBase = null;
				var matchedLength = 0;

				for (var i = 0; i < basePaths.length; i++) {
					var base = basePaths[i];
					var handler = handlers ? handlers.get(base) : _handlers[base];

					// Check if handler uses queryOnly mode (no path-based sub-routes)
					if (handler && handler.queryOnly) {
						// Only match exact base path (with or without trailing slash)
						if (pathname === base || pathname === base + '/') {
							if (base.length > matchedLength) {
								matchedBase = base;
								matchedLength = base.length;
							}
						}
					} else {
						// Check if pathname starts with base path (exact or with trailing content)
						if (pathname === base || pathname === base + '/' || pathname.indexOf(base + '/') === 0) {
							if (base.length > matchedLength) {
								matchedBase = base;
								matchedLength = base.length;
							}
						}
					}
				}

				if (!matchedBase) {
					return null;
				}

				// Extract sub-path from URL path segment (e.g., /docs/architecture -> architecture)
				var subPath = '';
				if (pathname.length > matchedBase.length) {
					subPath = pathname.substring(matchedBase.length + 1); // +1 to skip the /
				}

				// Parse query params
				var params = {};
				parsed.searchParams.forEach(function(value, key) {
					params[key] = value;
				});

				return {
					basePath: matchedBase,
					subPath: subPath,
					params: params,
					fullPath: pathname,
					search: parsed.search
				};
			} catch (e) {
				console.error('[SPA.SubRouter] Error parsing URL:', e);
				return null;
			}
		}

		/**
		 * Build URL from components
		 * @private
		 * @param {string} basePath - Base path
		 * @param {string} subPath - Sub-path
		 * @param {Object} [params] - Query parameters
		 * @returns {string} Full URL path
		 */
		function buildUrl(basePath, subPath, params) {
			var url = basePath;

			// SubPath goes in path segment: /docs/architecture
			if (subPath) {
				url += '/' + subPath;
			}

			// Params go to query string
			if (params && typeof params === 'object') {
				var searchParams = new URLSearchParams();
				for (var key in params) {
					if (params.hasOwnProperty(key) && params[key] !== undefined && params[key] !== null) {
						searchParams.set(key, params[key]);
					}
				}
				var search = searchParams.toString();
				if (search) {
					url += '?' + search;
				}
			}

			return url;
		}

		/**
		 * Emit sub-route event
		 * @private
		 * @param {string} type - Event type (push, replace, popstate)
		 * @param {Object} detail - Event detail
		 */
		function emitEvent(type, detail) {
			detail.type = type;

			// CustomEvent on document
			var event = new CustomEvent('funky.spa.subroute', {
				detail: detail
			});
			document.dispatchEvent(event);

			// PubSub event
			if (Funky.PubSub) {
				Funky.PubSub.emit('funky:spa:subroute', detail);
			}
		}

		return {
			/**
			 * Register a sub-route handler for a base path
			 * @param {string} basePath - Base path (e.g., '/docs', '/playground')
			 * @param {Object} handler - Handler object
			 * @param {Function} handler.activate - Called on navigation (context) => state
			 * @param {Function} handler.restore - Called on popstate (state, context)
			 * @param {Function} [handler.deactivate] - Called before navigating away
			 */
			register: function(basePath, handler) {
				if (!basePath || typeof basePath !== 'string') {
					console.error('[SPA.SubRouter] Invalid basePath:', basePath);
					return false;
				}

				// Normalize base path (ensure leading slash, no trailing slash)
				if (basePath.charAt(0) !== '/') {
					basePath = '/' + basePath;
				}
				if (basePath.length > 1 && basePath.charAt(basePath.length - 1) === '/') {
					basePath = basePath.slice(0, -1);
				}

				if (handlers) {
					return handlers.register(basePath, handler);
				} else {
					// Fallback validation
					if (!handler || typeof handler.activate !== 'function' || typeof handler.restore !== 'function') {
						console.error('[SPA.SubRouter] Handler must have activate and restore functions');
						return false;
					}
					_handlers[basePath] = handler;
					return true;
				}
			},

			/**
			 * Unregister a sub-route handler
			 * @param {string} basePath - Base path to unregister
			 */
			unregister: function(basePath) {
				if (handlers) {
					return handlers.unregister(basePath);
				} else {
					if (_handlers.hasOwnProperty(basePath)) {
						delete _handlers[basePath];
						return true;
					}
					return false;
				}
			},

			/**
			 * Check if a handler is registered for a base path
			 * @param {string} basePath - Base path to check
			 * @returns {boolean}
			 */
			has: function(basePath) {
				if (handlers) {
					return handlers.has(basePath);
				}
				return _handlers.hasOwnProperty(basePath);
			},

			/**
			 * Get handler for a base path
			 * @param {string} basePath - Base path
			 * @returns {Object|null} Handler or null
			 */
			getHandler: function(basePath) {
				if (handlers) {
					return handlers.get(basePath);
				}
				return _handlers.hasOwnProperty(basePath) ? _handlers[basePath] : null;
			},

			/**
			 * Push a new sub-route state (creates history entry)
			 * @param {string} basePath - Base path
			 * @param {string} subPath - Sub-path to append
			 * @param {Object} [state] - State to store in history
			 * @param {Object} [params] - Query parameters
			 */
			push: function(basePath, subPath, state, params) {
				var handler = this.getHandler(basePath);
				if (!handler) {
					console.warn('[SPA.SubRouter] No handler registered for:', basePath);
					return;
				}

				var url = buildUrl(basePath, subPath, params);

				var historyState = {
					url: url,
					title: document.title,
					isSubRoute: true,
					basePath: basePath,
					subPath: subPath,
					params: params || {},
					subState: state || {}
				};

				// Skip history manipulation if disabled (e.g., in iframes)
				if (!SPA.config.disableHistory && window.history && window.history.pushState) {
					window.history.pushState(historyState, document.title, url);
				}

				emitEvent('push', {
					basePath: basePath,
					subPath: subPath,
					params: params || {},
					state: state || {}
				});
			},

			/**
			 * Replace current sub-route state (no new history entry)
			 * @param {string} basePath - Base path
			 * @param {string} subPath - Sub-path to append
			 * @param {Object} [state] - State to store in history
			 * @param {Object} [params] - Query parameters
			 */
			replace: function(basePath, subPath, state, params) {
				var handler = this.getHandler(basePath);
				if (!handler) {
					console.warn('[SPA.SubRouter] No handler registered for:', basePath);
					return;
				}

				var url = buildUrl(basePath, subPath, params);

				var historyState = {
					url: url,
					title: document.title,
					isSubRoute: true,
					basePath: basePath,
					subPath: subPath,
					params: params || {},
					subState: state || {}
				};

				// Skip history manipulation if disabled (e.g., in iframes)
				if (!SPA.config.disableHistory && window.history && window.history.replaceState) {
					window.history.replaceState(historyState, document.title, url);
				}

				emitEvent('replace', {
					basePath: basePath,
					subPath: subPath,
					params: params || {},
					state: state || {}
				});
			},

			/**
			 * Update query params only (replaces state, no new history entry)
			 * @param {string} basePath - Base path
			 * @param {Object} params - Query parameters to set
			 */
			setParams: function(basePath, params) {
				var current = this.getCurrent(basePath);
				if (!current) {
					console.warn('[SPA.SubRouter] Cannot setParams - not on a sub-route for:', basePath);
					return;
				}

				this.replace(basePath, current.subPath, current.state, params);
			},

			/**
			 * Get current sub-route state for a base path
			 * @param {string} basePath - Base path to check
			 * @returns {Object|null} { subPath, params, state } or null
			 */
			getCurrent: function(basePath) {
				var parsed = parseUrl(window.location.href);

				if (!parsed || parsed.basePath !== basePath) {
					return null;
				}

				// Try to get state from history.state
				var historyState = window.history.state;
				var state = {};
				if (historyState && historyState.isSubRoute && historyState.basePath === basePath) {
					state = historyState.subState || {};
				}

				return {
					subPath: parsed.subPath,
					params: parsed.params,
					state: state
				};
			},

			/**
			 * Handle popstate for sub-routes
			 * Called by SPA's popstate handler
			 * @param {Object} historyState - The history.state object
			 * @returns {boolean} True if handled, false if not a sub-route
			 */
			handlePopstate: function(historyState) {
				if (!historyState || !historyState.isSubRoute) {
					return false;
				}

				var handler = this.getHandler(historyState.basePath);
				if (!handler) {
					return false;
				}

				// Check if the CURRENTLY DISPLAYED page matches the target basePath
				// We can't use window.location.pathname because it's already updated by popstate
				// Instead, use SPA.currentPage which tracks what page content is actually showing
				var currentPageId = SPA.currentPage;
				var targetPageId = historyState.basePath.replace(/^\//, ''); // Remove leading slash

				// If the currently displayed page content doesn't match the target, let SPA handle it
				if (currentPageId !== targetPageId) {
					// We're navigating to a different page - let SPA do a full page load
					return false;
				}

				var context = {
					subPath: historyState.subPath,
					params: historyState.params || {},
					fromPopstate: true
				};

				try {
					handler.restore(historyState.subState || {}, context);
				} catch (e) {
					console.error('[SPA.SubRouter] Error in restore handler:', e);
				}

				emitEvent('popstate', {
					basePath: historyState.basePath,
					subPath: historyState.subPath,
					params: historyState.params || {},
					state: historyState.subState || {}
				});

				return true;
			},

			/**
			 * Handle initial page load or direct URL access
			 * Checks if current URL matches a registered sub-route and activates it
			 * @returns {boolean} True if a sub-route was activated
			 */
			handleInitialLoad: function() {
				var parsed = parseUrl(window.location.href);

				if (!parsed) {
					return false;
				}

				var handler = this.getHandler(parsed.basePath);
				if (!handler) {
					return false;
				}

				var context = {
					subPath: parsed.subPath,
					params: parsed.params,
					fromPopstate: false
				};

				try {
					var state = handler.activate(context);

					// Store state in history for back/forward navigation (skip if history disabled)
					if (!SPA.config.disableHistory) {
						var historyState = {
							url: window.location.href,
							title: document.title,
							isSubRoute: true,
							basePath: parsed.basePath,
							subPath: parsed.subPath,
							params: parsed.params,
							subState: state || {}
						};

						if (window.history && window.history.replaceState) {
							window.history.replaceState(historyState, document.title, window.location.href);
						}
					}

					return true;
				} catch (e) {
					console.error('[SPA.SubRouter] Error in activate handler:', e);
					return false;
				}
			},

			/**
			 * Parse a URL (exposed for testing)
			 * @private
			 * @param {string} url - URL to parse
			 * @returns {Object|null}
			 */
			_parseUrl: parseUrl,

			/**
			 * Check if handler exists (for testing)
			 * @private
			 * @param {string} basePath - Base path
			 * @returns {boolean}
			 */
			_hasHandler: function(basePath) {
				return this.has(basePath);
			},

			/**
			 * Reset all handlers (for testing)
			 * @private
			 */
			_reset: function() {
				if (handlers) {
					handlers.clear();
				} else {
					_handlers = {};
				}
			}
		};
	})();

	// ============================================
	// REGISTER WITH FUNKY
	// ============================================

	if (typeof Funky !== 'undefined' && Funky.register) {
		Funky.register('SPA', SPA);
	}

	// ============================================
	// AUTO-INITIALIZE
	// ============================================

	// Initialize when DOM is ready
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			SPA.init();
		});
	} else {
		SPA.init();
	}

})(window, document);
