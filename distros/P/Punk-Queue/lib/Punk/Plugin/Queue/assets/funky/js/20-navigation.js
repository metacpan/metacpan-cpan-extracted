/**
 * Funky Navigation - Sidebar navigation utilities
 * Handles scroll position persistence across page loads
 * 
 * Usage:
 *   Funky.Navigation.saveScrollPosition();
 *   Funky.Navigation.restoreScrollPosition();
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Navigation] Registry not found. Load namespace.js first.');
		return;
	}

	var SCROLL_STORAGE_KEY = 'funky_nav_scroll_position';

	// Track cleanup functions for re-initialization
	var _cleanups = [];
	var _initialized = false;

	var Navigation = {
		/**
		 * Update --header-height CSS variable based on actual header size
		 */
		updateHeaderHeight: function() {
			var header = document.querySelector('.top-header');
			if (header) {
				var height = header.offsetHeight;
				document.documentElement.style.setProperty('--header-height', height + 'px');
			}
		},

		/**
		 * Restore scroll position immediately to avoid flash
		 */
		restoreScrollPosition: function() {
			var sidebarNav = document.querySelector('.sidebar-nav');
			if (!sidebarNav) return;

			var savedPosition = sessionStorage.getItem(SCROLL_STORAGE_KEY);
			if (savedPosition !== null) {
				var scrollPos = parseInt(savedPosition, 10);
				sidebarNav.scrollTop = scrollPos;
				// Force reflow and try again to ensure it sticks
				setTimeout(function() {
					sidebarNav.scrollTop = scrollPos;
				}, 0);
				// One more time after a short delay for good measure
				setTimeout(function() {
					sidebarNav.scrollTop = scrollPos;
				}, 50);
			}
		},

		/**
		 * Save scroll position
		 */
		saveScrollPosition: function() {
			var sidebarNav = document.querySelector('.sidebar-nav');
			if (sidebarNav) {
				sessionStorage.setItem(SCROLL_STORAGE_KEY, sidebarNav.scrollTop);
			}
		},

		/**
		 * Clean up event listeners (for re-initialization)
		 */
		cleanup: function() {
			_cleanups.forEach(function(fn) {
				try { fn(); } catch (e) { /* ignore */ }
			});
			_cleanups = [];
		},

		/**
		 * Initialize navigation scroll persistence
		 * Can be called multiple times (cleans up previous listeners)
		 */
		init: function() {
			var self = this;
			var sidebarNav = document.querySelector('.sidebar-nav');
			if (!sidebarNav) return;

			// Clean up previous listeners if re-initializing
			this.cleanup();

			// Save scroll position before navigating away (delegated to sidebarNav)
			var clickHandler = function(e) {
				var link = e.target.closest('.nav-link');
				if (link) {
					self.saveScrollPosition();
				}
			};
			sidebarNav.addEventListener('click', clickHandler);
			_cleanups.push(function() {
				sidebarNav.removeEventListener('click', clickHandler);
			});

			// Also save on any sidebar scroll (debounced)
			var scrollTimeout;
			var scrollHandler = function() {
				clearTimeout(scrollTimeout);
				scrollTimeout = setTimeout(function() {
					self.saveScrollPosition();
				}, 100);
			};
			sidebarNav.addEventListener('scroll', scrollHandler);
			_cleanups.push(function() {
				sidebarNav.removeEventListener('scroll', scrollHandler);
				clearTimeout(scrollTimeout);
			});

			// Save before page unload (only add once)
			if (!_initialized) {
				var unloadHandler = function() {
					self.saveScrollPosition();
				};
				window.addEventListener('beforeunload', unloadHandler);

				// Set header height on init and resize
				self.updateHeaderHeight();
				var resizeHandler = function() {
					self.updateHeaderHeight();
				};
				window.addEventListener('resize', resizeHandler);

				_initialized = true;
			}
		}
	};

	// Restore as early as possible
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			Navigation.updateHeaderHeight();
			Navigation.restoreScrollPosition();
		});
	} else {
		Navigation.updateHeaderHeight();
		Navigation.restoreScrollPosition();
	}

	// Also restore after full page load
	window.addEventListener('load', function() {
		Navigation.restoreScrollPosition();
	});

	// Setup save handlers after DOM is ready
	document.addEventListener('DOMContentLoaded', function() {
		Navigation.init();
	});

	// Register with Funky namespace
	Funky.register('Navigation', Navigation);

})(window);
