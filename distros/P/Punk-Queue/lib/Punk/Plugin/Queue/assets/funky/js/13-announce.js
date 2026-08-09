/**
 * Funky.Announce - Screen Reader Announcements
 *
 * Provides ARIA live regions for announcing dynamic content changes to screen readers.
 *
 * Features:
 * - Polite announcements (won't interrupt)
 * - Assertive announcements (interrupts immediately)
 * - Auto-creates live regions if missing
 * - Integrates with existing #spa-announcer and #alert-announcer
 *
 * Usage:
 *   // Polite announcement (updates, loading states)
 *   Funky.Announce.polite('Loading complete');
 *
 *   // Assertive announcement (errors, urgent alerts)
 *   Funky.Announce.assertive('Error: Please check your input');
 *
 *   // Clear all announcements
 *   Funky.Announce.clear();
 *
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Announce] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Announce')) {
		return;
	}

	// =========================================================================
	// CORE ANNOUNCE OBJECT
	// =========================================================================

	var Announce = {
		// Live region elements
		politeRegion: null,
		assertiveRegion: null,
		initialized: false,
		// Track pending timeouts for clearing
		_pendingTimeouts: [],

		/**
		 * Initialize announce system
		 * Finds or creates ARIA live regions
		 */
		init: function() {
			if (this.initialized) return;

			// Find or create polite region (non-interrupting announcements)
			this.politeRegion = document.getElementById('spa-announcer');
			if (!this.politeRegion) {
				this.politeRegion = this.createLiveRegion('spa-announcer', 'polite');
				console.log('[Funky.Announce] Created polite live region');
			}

			// Find or create assertive region (interrupting announcements)
			this.assertiveRegion = document.getElementById('alert-announcer');
			if (!this.assertiveRegion) {
				this.assertiveRegion = this.createLiveRegion('alert-announcer', 'assertive');
				console.log('[Funky.Announce] Created assertive live region');
			}

			this.initialized = true;
		},

		/**
		 * Create ARIA live region
		 * @param {string} id - Element ID
		 * @param {string} politeness - 'polite' or 'assertive'
		 * @returns {HTMLElement} Created live region element
		 */
		createLiveRegion: function(id, politeness) {
			var region = document.createElement('div');
			region.id = id;
			region.className = 'visually-hidden';
			region.setAttribute('aria-live', politeness);
			region.setAttribute('aria-atomic', 'true');
			region.setAttribute('role', politeness === 'assertive' ? 'alert' : 'status');

			// Append to body
			document.body.appendChild(region);

			return region;
		},

		/**
		 * Announce message politely (won't interrupt screen reader)
		 * Use for: updates, loading states, confirmations
		 * @param {string} message - Message to announce
		 */
		polite: function(message) {
			if (!this.initialized) this.init();
			if (!message) return;

			this.announce(this.politeRegion, message);
		},

		/**
		 * Announce message assertively (interrupts screen reader)
		 * Use for: errors, urgent alerts, critical information
		 * @param {string} message - Message to announce
		 */
		assertive: function(message) {
			if (!this.initialized) this.init();
			if (!message) return;

			this.announce(this.assertiveRegion, message);
		},

		/**
		 * Internal announce function
		 * @param {HTMLElement} region - Live region element
		 * @param {string} message - Message to announce
		 */
		announce: function(region, message) {
			var self = this;
			if (!region) {
				console.warn('[Funky.Announce] Live region not found');
				return;
			}

			// Cancel any pending announcements to prevent race conditions
			for (var i = 0; i < this._pendingTimeouts.length; i++) {
				clearTimeout(this._pendingTimeouts[i]);
			}
			this._pendingTimeouts = [];

			// Clear previous content
			region.textContent = '';

			// Small delay ensures screen readers notice the change
			// Some screen readers need the content to change from empty to text
			var timeoutId = setTimeout(function() {
				region.textContent = message;
				// Remove from pending list
				var idx = self._pendingTimeouts.indexOf(timeoutId);
				if (idx > -1) {
					self._pendingTimeouts.splice(idx, 1);
				}
			}, 50);

			// Track this timeout for potential clearing
			this._pendingTimeouts.push(timeoutId);
		},

		/**
		 * Clear all announcements
		 */
		clear: function() {
			// Cancel any pending announcements
			for (var i = 0; i < this._pendingTimeouts.length; i++) {
				clearTimeout(this._pendingTimeouts[i]);
			}
			this._pendingTimeouts = [];

			if (this.politeRegion) {
				this.politeRegion.textContent = '';
			}
			if (this.assertiveRegion) {
				this.assertiveRegion.textContent = '';
			}
		}
	};

	// =========================================================================
	// AUTO-INIT
	// =========================================================================

	// Auto-init on DOM ready
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			Announce.init();
		});
	} else {
		// DOM already loaded
		Announce.init();
	}

	// =========================================================================
	// Register with Funky namespace
	// =========================================================================

	Funky.register('Announce', Announce);

	console.log('[Funky.Announce] v1.0.0 initialized');

})(window);
