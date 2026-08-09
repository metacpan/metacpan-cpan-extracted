/**
 * Funky.Modal - Native Modal System
 * 
 * Replaces Bootstrap Modal JavaScript while keeping Bootstrap CSS styling.
 * Provides show/hide/toggle API with events, focus trapping, and backdrop handling.
 * 
 * Usage:
 *   // Static methods
 *   Funky.Modal.show('#myModal');
 *   Funky.Modal.hide('#myModal');
 *   Funky.Modal.toggle('#myModal');
 *   
 *   // Instance methods
 *   var modal = new Funky.Modal('#myModal', { backdrop: 'static' });
 *   modal.show();
 *   modal.hide();
 *   modal.dispose();
 *   
 *   // Events (via Funky.PubSub - uses colons)
 *   P.on('funky:modal:show', function(data) { console.log('Modal showing:', data.id); });
 *   P.on('funky:modal:shown', function(data) { console.log('Modal shown:', data.id); });
 *
 *   // Events (via DOM CustomEvent - uses dots)
 *   D.one('#myModal').on('funky.modal.hidden', function() { ... });
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Modal] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Modal')) {
		return;
	}

	// Shortcuts
	var D = Funky.Dom;
	var P = Funky.PubSub;

	// Store modal instances: { modalId: ModalInstance }
	var instances = {};

	// Track open modals for stacking
	var openModals = [];

	// Default options
	var DEFAULTS = {
		backdrop: true,      // true | false | 'static'
		keyboard: true,      // Close on ESC
		focus: true          // Focus modal on show
	};

	// =========================================================================
	// PRESENCE INTEGRATION
	// =========================================================================

	var _presenceEnabled = false;
	var _presenceConfig = {
		warnOnConflict: true,
		showPresenceIndicator: true
	};
	var _modalChannels = {};  // { modalId: channel }

	/**
	 * Generate presence channel for a modal
	 * @param {Modal} instance - Modal instance
	 * @returns {string|null} Channel name
	 */
	function getModalChannel(instance) {
		var el = instance.el;
		var options = instance.options;

		// Use explicit channel if provided
		if (options.presenceChannel) {
			return options.presenceChannel;
		}

		// Check data attribute
		var channelAttr = el.getAttribute('data-presence-channel');
		if (channelAttr) {
			return channelAttr;
		}

		// Generate from modal context
		var recordId = options.recordId || el.getAttribute('data-record-id');
		var modalType = options.modalType || el.getAttribute('data-modal-type') || 'modal';

		if (recordId) {
			return 'modal:' + modalType + ':' + recordId;
		}

		return null;
	}

	/**
	 * Join presence channel when modal opens
	 * @param {Modal} instance - Modal instance
	 * @private
	 */
	function joinModalPresence(instance) {
		if (!_presenceEnabled || !Funky.Presence) return;

		var channel = getModalChannel(instance);
		if (!channel) return;

		_modalChannels[instance.id] = channel;

		var options = instance.options;
		var status = options.presenceStatus ||
					 (options.readonly ? 'viewing' : 'editing');

		Funky.Presence.join(channel, {
			status: status,
			metadata: {
				modalType: options.modalType || instance.el.getAttribute('data-modal-type') || 'modal',
				modalTitle: instance.el.querySelector('.modal-title')?.textContent || '',
				recordId: options.recordId || instance.el.getAttribute('data-record-id')
			}
		});

		// Store channel reference on instance
		instance._presenceChannel = channel;

		// Add presence indicator if configured
		if (_presenceConfig.showPresenceIndicator) {
			addPresenceIndicator(instance);
		}
	}

	/**
	 * Leave presence channel when modal closes
	 * @param {Modal} instance - Modal instance
	 * @private
	 */
	function leaveModalPresence(instance) {
		if (!_presenceEnabled || !Funky.Presence) return;

		var channel = instance._presenceChannel;
		if (!channel) return;

		Funky.Presence.leave(channel);
		delete _modalChannels[instance.id];
		instance._presenceChannel = null;

		// Remove presence indicator
		removePresenceIndicator(instance);
	}

	/**
	 * Check for editing conflicts before opening modal
	 * @param {Modal} instance - Modal instance
	 * @returns {boolean} True if safe to proceed
	 */
	function checkModalConflict(instance) {
		if (!_presenceEnabled || !Funky.Presence || !_presenceConfig.warnOnConflict) {
			return true;
		}

		// Check if warning is disabled for this modal
		if (instance.options.warnOnConflict === false) {
			return true;
		}

		var channel = getModalChannel(instance);
		if (!channel) return true;

		var otherUsers = Funky.Presence.getOtherUsers(channel);
		var editingUsers = otherUsers.filter(function(u) {
			return u.status === 'editing';
		});

		if (editingUsers.length > 0) {
			var names = editingUsers.map(function(u) { return u.name; }).join(', ');
			var verb = editingUsers.length === 1 ? ' is' : ' are';
			return confirm(
				names + verb + ' currently editing this record. ' +
				'Opening it may cause conflicts. Continue anyway?'
			);
		}

		return true;
	}

	/**
	 * Add presence indicator to modal header
	 * @param {Modal} instance - Modal instance
	 * @private
	 */
	function addPresenceIndicator(instance) {
		if (!_presenceEnabled || !Funky.Presence) return;

		var channel = instance._presenceChannel;
		if (!channel) return;

		var header = instance.el.querySelector('.modal-header');
		if (!header) return;

		// Check if indicator already exists
		if (header.querySelector('.modal__presence')) return;

		// Create presence indicator container
		var indicator = document.createElement('div');
		indicator.className = 'modal__presence';

		// Use Presence UI component if available
		if (Funky.Presence.createAvatarStack) {
			instance._presenceUI = Funky.Presence.createAvatarStack(indicator, channel, {
				maxAvatars: 3,
				excludeSelf: true,
				showCount: false
			});
		}

		// Insert after title
		var title = header.querySelector('.modal-title');
		if (title && title.nextSibling) {
			header.insertBefore(indicator, title.nextSibling);
		} else if (title) {
			title.parentNode.appendChild(indicator);
		} else {
			header.insertBefore(indicator, header.firstChild);
		}
	}

	/**
	 * Remove presence indicator from modal header
	 * @param {Modal} instance - Modal instance
	 * @private
	 */
	function removePresenceIndicator(instance) {
		if (instance._presenceUI) {
			instance._presenceUI.destroy();
			instance._presenceUI = null;
		}

		var header = instance.el.querySelector('.modal-header');
		if (!header) return;

		var indicator = header.querySelector('.modal__presence');
		if (indicator) {
			indicator.parentNode.removeChild(indicator);
		}
	}

	// CSS transition duration (should match Bootstrap's .modal.fade and slide animations)
	// Use Funky.Animate for duration management
	var Animate = Funky.Animate;

	// Focusable elements selector - use FocusManager's constant if available
	var FOCUSABLE_SELECTORS = (Funky.FocusManager && Funky.FocusManager.FOCUSABLE_SELECTORS) || [
		'a[href]',
		'button:not([disabled])',
		'input:not([disabled]):not([type="hidden"])',
		'select:not([disabled])',
		'textarea:not([disabled])',
		'[tabindex]:not([tabindex="-1"])'
	].join(', ');

	/**
	 * Get element from selector or element
	 * @param {string|HTMLElement} target
	 * @returns {HTMLElement|null}
	 */
	function getElement(target) {
		if (!target) return null;
		if (typeof target === 'string') {
			return document.querySelector(target);
		}
		return target.el || target; // Handle ElementWrapper or raw element
	}

	/**
	 * Dispatch custom event on element
	 * @param {HTMLElement} element
	 * @param {string} eventName
	 * @param {Object} detail
	 */
	function dispatchEvent(element, eventName, detail) {
		var event = new CustomEvent(eventName, {
			bubbles: true,
			cancelable: true,
			detail: detail || {}
		});
		return element.dispatchEvent(event);
	}

	/**
	 * Get scrollbar width
	 * @returns {number}
	 */
	function getScrollbarWidth() {
		var scrollDiv = document.createElement('div');
		scrollDiv.style.cssText = 'width:100px;height:100px;overflow:scroll;position:absolute;top:-9999px;';
		document.body.appendChild(scrollDiv);
		var width = scrollDiv.offsetWidth - scrollDiv.clientWidth;
		document.body.removeChild(scrollDiv);
		return width;
	}

	/**
	 * Modal Constructor
	 * @param {string|HTMLElement} target - Modal element or selector
	 * @param {Object} options
	 */
	function Modal(target, options) {
		var element = getElement(target);
		if (!element) {
			console.error('[Funky.Modal] Element not found:', target);
			return;
		}

		this.el = element;
		this.id = element.id || 'modal-' + Date.now();
		this.options = Object.assign({}, DEFAULTS, options || {});
		this.backdrop = null;
		this.isShown = false;
		this.isTransitioning = false;
		this.triggerElement = null;
		this.boundClickHandler = this._handleBackdropClick.bind(this);
		this._focusTrapCleanup = null; // Cleanup function for FocusManager.trapFocus
		this._keyboardUnregister = null; // Cleanup function for Funky.Keyboard

		// Store instance
		instances[this.id] = this;

		// Read options from data attributes
		this._readDataAttributes();
	}

	Modal.prototype = {
		/**
		 * Read options from data attributes
		 * @private
		 */
		_readDataAttributes: function() {
			var el = this.el;
			
			// data-bs-backdrop for Bootstrap compatibility
			var backdropAttr = el.getAttribute('data-bs-backdrop') || el.getAttribute('data-backdrop');
			if (backdropAttr === 'static') {
				this.options.backdrop = 'static';
			} else if (backdropAttr === 'false') {
				this.options.backdrop = false;
			}

			// data-bs-keyboard
			var keyboardAttr = el.getAttribute('data-bs-keyboard') || el.getAttribute('data-keyboard');
			if (keyboardAttr === 'false') {
				this.options.keyboard = false;
			}
		},

		/**
		 * Show the modal
		 */
		show: function() {
			var self = this;

			if (this.isShown || this.isTransitioning) {
				return;
			}

			// Check for presence conflicts before opening
			if (!checkModalConflict(this)) {
				return;
			}

			// Store trigger element for focus return (fallback if FocusManager unavailable)
			this.triggerElement = document.activeElement;

			// Push current focus to FocusManager history for proper escape navigation
			if (Funky.FocusManager && this.triggerElement && this.triggerElement !== document.body) {
				// Clean history and add current element before switching to modal
				var history = Funky.FocusManager;
				if (history.getHistoryLength) {
					// We'll push via focusAndPush when focusing the modal content
				}
			}

			// Emit show event (before animation)
			var showEvent = dispatchEvent(this.el, 'funky.modal.show', { modal: this, id: this.id });
			P.emit('funky:modal:show', { modal: this, id: this.id, element: this.el });

			// Allow cancellation
			if (!showEvent) {
				return;
			}

			this.isShown = true;
			this.isTransitioning = true;

			// Add to open modals stack
			openModals.push(this);

			// Lock body scroll
			this._lockScroll();

			// Create backdrop
			if (this.options.backdrop) {
				this._createBackdrop();
			}

			// Show modal
			this.el.style.display = 'block';
			this.el.removeAttribute('aria-hidden');
			this.el.setAttribute('aria-modal', 'true');
			this.el.setAttribute('role', 'dialog');

			// Force reflow for transition
			void this.el.offsetHeight;

			// Add show class
			D.wrap(this.el).classAdd('show');

			// Join presence channel
			joinModalPresence(this);

			// Bind click events
			this.el.addEventListener('click', this.boundClickHandler);

			// Set up focus trap using FocusManager if available, otherwise use fallback
			if (Funky.FocusManager && Funky.FocusManager.trapFocus) {
				this._focusTrapCleanup = Funky.FocusManager.trapFocus(this.el, {
					autoFocus: false // We handle initial focus ourselves
				});
			} else {
				// Fallback focus trap for Tab key when FocusManager not available
				var modalInstance = this;
				this._boundTrapFocus = function(e) {
					if (e.key === 'Tab') {
						modalInstance._trapFocus(e);
					}
				};
				this.el.addEventListener('keydown', this._boundTrapFocus);
			}

			// Register keyboard shortcuts via Funky.Keyboard
			if (Funky.Keyboard && this.options.keyboard) {
				var modalInstance = this;
				// Push modal scope so Escape handler becomes active
				Funky.Keyboard.pushScope('modal');
				this._keyboardUnregister = Funky.Keyboard.register({
					key: 'escape',
					scope: 'modal',
					allowInInput: true,
					priority: 10, // Higher than Morph.to() internal handler (0)
					handler: function() {
						// Only close if this modal is the topmost open modal
						if (modalInstance.isShown && !modalInstance.isTransitioning) {
							var topModal = openModals[openModals.length - 1];
							if (topModal === modalInstance) {
								modalInstance.hide();
							}
						}
					},
					description: 'Close modal',
					group: 'Modal',
					preventDefault: true
				});
			} else if (this.options.keyboard) {
				// Fallback escape handler when Funky.Keyboard is not available
				var modalInstance = this;
				this._escapeHandler = function(e) {
					if (e.key === 'Escape' && modalInstance.isShown) {
						e.preventDefault();
						modalInstance.hide();
					}
				};
				document.addEventListener('keydown', this._escapeHandler);
			}

			// Get transition duration (respects animations preference)
			var duration = Animate.getDuration(this.el, Animate.DURATION.NORMAL);

			// Focus modal (using FocusManager if available)
			if (this.options.focus) {
				setTimeout(function() {
					self._focusFirstElement();
				}, duration);
			}

			// After transition
			setTimeout(function() {
				self.isTransitioning = false;
				dispatchEvent(self.el, 'funky.modal.shown', { modal: self, id: self.id });
				P.emit('funky:modal:shown', { modal: self, id: self.id, element: self.el });
			}, duration);
		},

		/**
		 * Hide the modal
		 */
		hide: function() {
			var self = this;

			if (!this.isShown || this.isTransitioning) {
				return;
			}

			// Leave presence channel
			leaveModalPresence(this);

			// Emit hide event (before animation)
			var hideEvent = dispatchEvent(this.el, 'funky.modal.hide', { modal: this, id: this.id });
			P.emit('funky:modal:hide', { modal: this, id: this.id, element: this.el });

			// Allow cancellation
			if (!hideEvent) {
				return;
			}

			this.isTransitioning = true;

			// Remove show class
			D.wrap(this.el).classRemove('show');

			// Unbind click events
			this.el.removeEventListener('click', this.boundClickHandler);

			// Clean up focus trap
			if (this._focusTrapCleanup) {
				this._focusTrapCleanup();
				this._focusTrapCleanup = null;
			} else if (this._boundTrapFocus) {
				this.el.removeEventListener('keydown', this._boundTrapFocus);
				this._boundTrapFocus = null;
			}

			// Clean up keyboard shortcuts and pop scope
			if (this._keyboardUnregister) {
				this._keyboardUnregister();
				this._keyboardUnregister = null;
				// Pop the modal scope we pushed in show()
				if (Funky.Keyboard && Funky.Keyboard.popScope) {
					Funky.Keyboard.popScope();
				}
			}
			// Clean up fallback escape handler
			if (this._escapeHandler) {
				document.removeEventListener('keydown', this._escapeHandler);
				this._escapeHandler = null;
			}

			// Get transition duration (respects animations preference)
			var duration = Animate.getDuration(this.el, Animate.DURATION.NORMAL);

			// After transition
			setTimeout(function() {
				self.el.style.display = 'none';
				self.el.setAttribute('aria-hidden', 'true');
				self.el.removeAttribute('aria-modal');

				// Remove backdrop
				self._removeBackdrop();

				// Remove from open modals stack
				var index = openModals.indexOf(self);
				if (index > -1) {
					openModals.splice(index, 1);
				}

				// Unlock body scroll if no more modals
				if (openModals.length === 0) {
					self._unlockScroll();
				}

				self.isShown = false;
				self.isTransitioning = false;

				// Return focus via FocusManager (pops history) or fallback to triggerElement
				if (Funky.FocusManager && Funky.FocusManager.popFocus) {
					var restored = Funky.FocusManager.popFocus();
					// Fallback to triggerElement if FocusManager has no history
					if (!restored && self.triggerElement && typeof self.triggerElement.focus === 'function') {
						try {
							self.triggerElement.focus();
						} catch (e) {
							// Element may no longer be in DOM
						}
					}
				} else if (self.triggerElement && typeof self.triggerElement.focus === 'function') {
					try {
						self.triggerElement.focus();
					} catch (e) {
						// Element may no longer be in DOM
					}
				}

				dispatchEvent(self.el, 'funky.modal.hidden', { modal: self, id: self.id });
				P.emit('funky:modal:hidden', { modal: self, id: self.id, element: self.el });
			}, duration);
		},

		/**
		 * Toggle modal visibility
		 */
		toggle: function() {
			if (this.isShown) {
				this.hide();
			} else {
				this.show();
			}
		},

		/**
		 * Dispose modal instance
		 */
		dispose: function() {
			// Clean up presence
			leaveModalPresence(this);

			if (this.isShown) {
				this.hide();
			}

			this.el.removeEventListener('click', this.boundClickHandler);

			// Clean up fallback focus trap if still active
			if (this._boundTrapFocus) {
				this.el.removeEventListener('keydown', this._boundTrapFocus);
				this._boundTrapFocus = null;
			}

			// Clean up keyboard shortcuts if still active
			if (this._keyboardUnregister) {
				this._keyboardUnregister();
				this._keyboardUnregister = null;
			}
			// Clean up fallback escape handler
			if (this._escapeHandler) {
				document.removeEventListener('keydown', this._escapeHandler);
				this._escapeHandler = null;
			}

			delete instances[this.id];
		},

		/**
		 * Create backdrop element
		 * @private
		 */
		_createBackdrop: function() {
			var self = this;

			this.backdrop = document.createElement('div');
			this.backdrop.className = 'modal-backdrop fade';
			this.backdrop.setAttribute('aria-hidden', 'true');

			document.body.appendChild(this.backdrop);

			// Force reflow for transition
			void this.backdrop.offsetHeight;

			// Add show class
			this.backdrop.classList.add('show');
		},

		/**
		 * Remove backdrop element
		 * @private
		 */
		_removeBackdrop: function() {
			var self = this;

			if (!this.backdrop) {
				return;
			}

			this.backdrop.classList.remove('show');

			var backdrop = this.backdrop;
			var duration = Animate.getDuration(this.el, Animate.DURATION.NORMAL);
			setTimeout(function() {
				if (backdrop && backdrop.parentNode) {
					backdrop.parentNode.removeChild(backdrop);
				}
			}, duration);

			this.backdrop = null;
		},

		/**
		 * Handle backdrop click
		 * @private
		 */
		_handleBackdropClick: function(e) {
			// Check for close button click (data-funky-modal-close)
			var closeBtn = e.target.closest('[data-funky-modal-close]');
			if (closeBtn) {
				e.preventDefault();
				this.hide();
				return;
			}

			// Only close if clicking the modal background (not dialog content)
			if (e.target === this.el) {
				if (this.options.backdrop === 'static') {
					// Shake animation for static backdrop
					D.wrap(this.el).classAdd('modal-static');
					var self = this;
					setTimeout(function() {
						D.wrap(self.el).classRemove('modal-static');
					}, 300);
				} else if (this.options.backdrop) {
					this.hide();
				}
			}
		},

		/**
		 * Lock body scroll
		 * @private
		 */
		_lockScroll: function() {
			// Only lock on first modal (current modal already added to openModals)
			if (openModals.length > 1) {
				return;
			}

			var scrollbarWidth = getScrollbarWidth();
			document.body.style.overflow = 'hidden';
			document.body.style.paddingRight = scrollbarWidth + 'px';
			document.body.classList.add('modal-open');
		},

		/**
		 * Unlock body scroll
		 * @private
		 */
		_unlockScroll: function() {
			document.body.style.overflow = '';
			document.body.style.paddingRight = '';
			document.body.classList.remove('modal-open');
		},

		/**
		 * Focus first focusable element in modal
		 * Uses FocusManager.focusAndPush if available for escape navigation
		 * @private
		 */
		_focusFirstElement: function() {
			var focusable = this.el.querySelectorAll(FOCUSABLE_SELECTORS);
			var dialog = this.el.querySelector('.modal-dialog');
			var targetElement = null;
			var modalTitle = this.el.querySelector('.modal-title');
			var label = modalTitle ? modalTitle.textContent : 'Modal';

			// Try to focus first element in modal body (skip close button)
			var body = this.el.querySelector('.modal-body');
			if (body) {
				var bodyFocusable = body.querySelectorAll(FOCUSABLE_SELECTORS);
				if (bodyFocusable.length > 0) {
					targetElement = bodyFocusable[0];
				}
			}

			// Fall back to first focusable element
			if (!targetElement && focusable.length > 0) {
				targetElement = focusable[0];
			} else if (!targetElement && dialog) {
				// Make dialog focusable if nothing else
				dialog.setAttribute('tabindex', '-1');
				targetElement = dialog;
			}

			// Focus using FocusManager if available (pushes trigger to history)
			if (targetElement) {
				if (Funky.FocusManager && Funky.FocusManager.focusAndPush) {
					Funky.FocusManager.focusAndPush(targetElement, { label: label });
				} else {
					targetElement.focus();
				}
			}
		},

		/**
		 * Trap focus within modal
		 * @private
		 */
		_trapFocus: function(e) {
			var focusable = this.el.querySelectorAll(FOCUSABLE_SELECTORS);
			if (focusable.length === 0) return;

			var first = focusable[0];
			var last = focusable[focusable.length - 1];

			if (e.shiftKey && document.activeElement === first) {
				e.preventDefault();
				last.focus();
			} else if (!e.shiftKey && document.activeElement === last) {
				e.preventDefault();
				first.focus();
			}
		}
	};

	// =========================================================================
	// Static Methods
	// =========================================================================

	/**
	 * Get or create modal instance
	 * @param {string|HTMLElement} target
	 * @param {Object} options
	 * @returns {Modal}
	 */
	Modal.getOrCreateInstance = function(target, options) {
		var element = getElement(target);
		if (!element) return null;

		var id = element.id;
		if (id && instances[id]) {
			// Check if the cached instance's element is still in the DOM
			// If not, dispose the old instance and create a new one
			if (!instances[id].el || !instances[id].el.isConnected) {
				instances[id].dispose();
			} else {
				return instances[id];
			}
		}

		return new Modal(element, options);
	};

	/**
	 * Get existing instance (for Bootstrap compatibility)
	 * @param {string|HTMLElement} target
	 * @returns {Modal|null}
	 */
	Modal.getInstance = function(target) {
		var element = getElement(target);
		if (!element || !element.id) return null;
		return instances[element.id] || null;
	};

	/**
	 * Show modal (static convenience method)
	 * @param {string|HTMLElement} target
	 * @param {Object} options
	 */
	Modal.show = function(target, options) {
		var modal = Modal.getOrCreateInstance(target, options);
		if (modal) {
			modal.show();
		}
	};

	/**
	 * Hide modal (static convenience method)
	 * @param {string|HTMLElement} target
	 */
	Modal.hide = function(target) {
		var modal = Modal.getInstance(target);
		if (modal) {
			modal.hide();
		}
	};

	/**
	 * Toggle modal (static convenience method)
	 * @param {string|HTMLElement} target
	 * @param {Object} options
	 */
	Modal.toggle = function(target, options) {
		var modal = Modal.getOrCreateInstance(target, options);
		if (modal) {
			modal.toggle();
		}
	};

	/**
	 * Hide all open modals
	 */
	Modal.hideAll = function() {
		// Copy array to avoid modification during iteration
		var modals = openModals.slice();
		modals.forEach(function(modal) {
			modal.hide();
		});
	};

	/**
	 * Get all open modals
	 * @returns {Modal[]}
	 */
	Modal.getOpenModals = function() {
		return openModals.slice();
	};

	/**
	 * Check if any modals are currently open
	 * Used by FocusManager/Keyboard for escape hierarchy
	 * @returns {boolean}
	 */
	Modal.hasOpenModals = function() {
		return openModals && openModals.length > 0;
	};

	/**
	 * Destroy a modal instance by ID or element
	 * @param {string|HTMLElement} target - Modal ID or element
	 */
	Modal.destroy = function(target) {
		var modal = Modal.getInstance(target);
		if (modal) {
			modal.dispose();
		}
	};

	/**
	 * Destroy all modal instances
	 */
	Modal.destroyAll = function() {
		Object.keys(instances).forEach(function(id) {
			if (instances[id] && instances[id].dispose) {
				instances[id].dispose();
			}
		});
	};

	/**
	 * Clean up orphaned backdrops and reset modal state
	 */
	Modal.cleanupBackdrops = function() {
		document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
			backdrop.parentNode.removeChild(backdrop);
		});

		// Clear open modals tracking
		openModals.length = 0;

		// Reset all modal instances' state
		Object.keys(instances).forEach(function(id) {
			var instance = instances[id];
			if (instance) {
				instance.isShown = false;
				instance.isTransitioning = false;
			}
		});

		// Also ensure body scroll is unlocked
		document.body.style.overflow = '';
		document.body.style.paddingRight = '';
		document.body.classList.remove('modal-open');
	};

	// =========================================================================
	// PRESENCE INTEGRATION - Static Methods
	// =========================================================================

	/**
	 * Enable presence tracking for modals
	 * @param {Object} options - Configuration options
	 * @param {boolean} options.warnOnConflict - Warn when someone else is editing (default: true)
	 * @param {boolean} options.showPresenceIndicator - Show avatar stack in header (default: true)
	 */
	Modal.enablePresence = function(options) {
		if (!Funky.Presence) {
			console.warn('[Modal] Funky.Presence not available');
			return;
		}

		options = options || {};
		_presenceEnabled = true;
		_presenceConfig = {
			warnOnConflict: options.warnOnConflict !== false,
			showPresenceIndicator: options.showPresenceIndicator !== false
		};

		console.log('[Modal] Presence tracking enabled');
	};

	/**
	 * Disable presence tracking for modals
	 */
	Modal.disablePresence = function() {
		_presenceEnabled = false;

		// Leave all modal channels
		var modalIds = Object.keys(_modalChannels);
		for (var i = 0; i < modalIds.length; i++) {
			var channel = _modalChannels[modalIds[i]];
			if (Funky.Presence) {
				Funky.Presence.leave(channel);
			}
		}
		_modalChannels = {};

		console.log('[Modal] Presence tracking disabled');
	};

	/**
	 * Check if presence tracking is enabled
	 * @returns {boolean}
	 */
	Modal.isPresenceEnabled = function() {
		return _presenceEnabled;
	};

	// =========================================================================
	// Modal Generators
	// =========================================================================

	/**
	 * Create a modal element programmatically
	 * @param {Object} config - Modal configuration
	 * @param {string} config.id - Modal ID (required)
	 * @param {string} [config.title] - Modal title
	 * @param {string|HTMLElement} [config.body] - Modal body content
	 * @param {string} [config.size] - Modal size: 'sm', 'lg', 'xl', 'fullscreen'
	 * @param {boolean} [config.scrollable=true] - Make body scrollable
	 * @param {boolean} [config.centered=false] - Vertically center modal
	 * @param {boolean} [config.slidePanel=false] - Use slide panel style
	 * @param {string} [config.slidePanelSize] - Slide panel size: 'sm', 'lg', 'xl'
	 * @param {Array} [config.footerButtons] - Footer buttons [{text, class, id, close, onClick}]
	 * @param {boolean} [config.showClose=true] - Show close button in header
	 * @returns {HTMLElement} The modal element
	 */
	Modal.init = function(config) {
		if (!config.id) {
			console.error('[Funky.Modal] init() requires an id');
			return null;
		}

		// Remove existing modal with same ID
		var existing = document.getElementById(config.id);
		if (existing) {
			existing.parentNode.removeChild(existing);
			delete instances[config.id];
		}

		var D = Funky.Dom;

		// Build modal classes
		var modalClasses = 'modal fade';
		if (config.slidePanel) {
			modalClasses += ' modal-slide-panel';
			if (config.slidePanelSize) {
				modalClasses += ' modal-slide-panel-' + config.slidePanelSize;
			}
		}

		// Build dialog classes
		var dialogClasses = 'modal-dialog';
		if (config.size) {
			dialogClasses += ' modal-' + config.size;
		}
		if (config.fullscreen) {
			dialogClasses += ' modal-fullscreen';
		}
		if (config.scrollable !== false) {
			dialogClasses += ' modal-dialog-scrollable';
		}
		if (config.centered) {
			dialogClasses += ' modal-dialog-centered';
		}

		// Build header
		var headerChildren = [];
		if (config.title) {
			headerChildren.push(
				D.create('h5').class('modal-title').id(config.id + 'Label').html(config.title)
			);
		}
		if (config.showClose !== false) {
			headerChildren.push(
				D.button().attr('type', 'button').class('btn-close').data('funky-modal-close', '').aria('label', 'Close')
			);
		}

		// Build footer buttons
		var footerChildren = [];
		if (config.footerButtons && config.footerButtons.length) {
			for (var i = 0; i < config.footerButtons.length; i++) {
				var btn = config.footerButtons[i];
				var button = D.button()
					.attr('type', 'button')
					.class(btn.class || 'btn btn-secondary')
					.html(btn.text || 'Button');
				
				if (btn.id) {
					button.id(btn.id);
				}
				if (btn.close) {
					button.data('funky-modal-close', '');
				}
				footerChildren.push(button);
			}
		}

		// Build content
		var contentChildren = [];
		
		// Header
		if (headerChildren.length) {
			var header = D.div().class('modal-header');
			for (var h = 0; h < headerChildren.length; h++) {
				header.child(headerChildren[h]);
			}
			contentChildren.push(header);
		}

		// Body
		var body = D.div().class('modal-body');
		if (config.body) {
			if (typeof config.body === 'string') {
				body.html(config.body);
			} else if (config.body.nodeType) {
				body.child(D.wrap(config.body));
			} else if (config.body.el) {
				body.child(config.body);
			}
		}
		if (config.bodyId) {
			body.id(config.bodyId);
		}
		contentChildren.push(body);

		// Footer
		if (footerChildren.length) {
			var footer = D.div().class('modal-footer');
			for (var f = 0; f < footerChildren.length; f++) {
				footer.child(footerChildren[f]);
			}
			contentChildren.push(footer);
		}

		// Build modal structure
		var content = D.div().class('modal-content');
		for (var c = 0; c < contentChildren.length; c++) {
			content.child(contentChildren[c]);
		}

		var dialog = D.div().class(dialogClasses).child(content);

		var modal = D.div()
			.class(modalClasses)
			.id(config.id)
			.attr('tabindex', '-1')
			.aria('labelledby', config.id + 'Label')
			.aria('hidden', 'true')
			.child(dialog)
			.get();

		// Append to body
		document.body.appendChild(modal);

		// Bind footer button click handlers
		if (config.footerButtons) {
			for (var b = 0; b < config.footerButtons.length; b++) {
				var btnConfig = config.footerButtons[b];
				if (btnConfig.id && btnConfig.onClick) {
					(function(handler) {
						var btnEl = document.getElementById(btnConfig.id);
						if (btnEl) {
							btnEl.addEventListener('click', handler);
						}
					})(btnConfig.onClick);
				}
			}
		}

		return modal;
	};

	/**
	 * @deprecated Use Modal.init() instead
	 */
	Modal.create = function(config) {
		return Modal.init(config);
	};

	/**
	 * Create and show a confirmation modal
	 * @param {Object} config - Configuration
	 * @param {string} config.title - Modal title
	 * @param {string} config.message - Confirmation message
	 * @param {string} [config.confirmText='Confirm'] - Confirm button text
	 * @param {string} [config.cancelText='Cancel'] - Cancel button text
	 * @param {string} [config.confirmClass='btn btn-primary'] - Confirm button class
	 * @param {string} [config.cancelClass='btn btn-secondary'] - Cancel button class
	 * @param {boolean} [config.danger=false] - Use danger styling
	 * @param {Function} config.onConfirm - Callback when confirmed
	 * @param {Function} [config.onCancel] - Callback when cancelled
	 * @returns {Modal} The modal instance
	 */
	Modal.confirm = function(config) {
		var id = 'funkyConfirmModal_' + Date.now();
		var confirmClass = config.confirmClass || (config.danger ? 'btn btn-danger' : 'btn btn-primary');

		var modal = Modal.create({
			id: id,
			title: config.title || 'Confirm',
			body: '<p>' + (config.message || 'Are you sure?') + '</p>',
			centered: true,
			footerButtons: [
				{
					text: config.cancelText || 'Cancel',
					class: config.cancelClass || 'btn btn-secondary',
					close: true
				},
				{
					text: config.confirmText || 'Confirm',
					class: confirmClass,
					id: id + '_confirm'
				}
			]
		});

		// Bind confirm handler
		var confirmBtn = document.getElementById(id + '_confirm');
		if (confirmBtn) {
			confirmBtn.addEventListener('click', function() {
				Modal.hide('#' + id);
				if (config.onConfirm) {
					config.onConfirm();
				}
			});
		}

		// Bind cancel handler to modal hidden event
		if (config.onCancel) {
			modal.addEventListener('funky.modal.hidden', function handler() {
				modal.removeEventListener('funky.modal.hidden', handler);
				// Only call onCancel if confirm wasn't clicked
				if (!confirmBtn._confirmed) {
					config.onCancel();
				}
			});
		}

		// Track confirm click
		if (confirmBtn) {
			var origHandler = confirmBtn.onclick;
			confirmBtn.addEventListener('click', function() {
				confirmBtn._confirmed = true;
			});
		}

		// Show and return instance
		var instance = Modal.getOrCreateInstance('#' + id);
		instance.show();
		return instance;
	};

	/**
	 * Create and show an alert modal
	 * @param {Object} config - Configuration
	 * @param {string} config.title - Modal title
	 * @param {string} config.message - Alert message
	 * @param {string} [config.buttonText='OK'] - Button text
	 * @param {string} [config.buttonClass='btn btn-primary'] - Button class
	 * @param {string} [config.type] - Alert type: 'success', 'warning', 'danger', 'info'
	 * @param {Function} [config.onClose] - Callback when closed
	 * @returns {Modal} The modal instance
	 */
	Modal.alert = function(config) {
		var id = 'funkyAlertModal_' + Date.now();
		
		// Build message with icon based on type
		var iconMap = {
			success: '<i class="fas fa-check-circle text-success me-2"></i>',
			warning: '<i class="fas fa-exclamation-triangle text-warning me-2"></i>',
			danger: '<i class="fas fa-times-circle text-danger me-2"></i>',
			info: '<i class="fas fa-info-circle text-info me-2"></i>'
		};
		var icon = config.type && iconMap[config.type] ? iconMap[config.type] : '';
		var body = '<p>' + icon + (config.message || '') + '</p>';

		var modal = Modal.create({
			id: id,
			title: config.title || 'Alert',
			body: body,
			centered: true,
			footerButtons: [
				{
					text: config.buttonText || 'OK',
					class: config.buttonClass || 'btn btn-primary',
					close: true
				}
			]
		});

		// Bind close handler
		if (config.onClose) {
			modal.addEventListener('funky.modal.hidden', function handler() {
				modal.removeEventListener('funky.modal.hidden', handler);
				config.onClose();
			});
		}

		// Show and return instance
		var instance = Modal.getOrCreateInstance('#' + id);
		instance.show();
		return instance;
	};

	/**
	 * Create and show a prompt modal with input
	 * @param {Object} config - Configuration
	 * @param {string} config.title - Modal title
	 * @param {string} [config.message] - Message above input
	 * @param {string} [config.placeholder] - Input placeholder
	 * @param {string} [config.defaultValue] - Default input value
	 * @param {string} [config.inputType='text'] - Input type
	 * @param {string} [config.submitText='Submit'] - Submit button text
	 * @param {string} [config.cancelText='Cancel'] - Cancel button text
	 * @param {Function} config.onSubmit - Callback with input value
	 * @param {Function} [config.onCancel] - Callback when cancelled
	 * @returns {Modal} The modal instance
	 */
	Modal.prompt = function(config) {
		var id = 'funkyPromptModal_' + Date.now();
		var inputId = id + '_input';

		var body = '';
		if (config.message) {
			body += '<p>' + config.message + '</p>';
		}
		body += '<input type="' + (config.inputType || 'text') + '" class="form-control" id="' + inputId + '"';
		if (config.placeholder) {
			body += ' placeholder="' + config.placeholder + '"';
		}
		if (config.defaultValue) {
			body += ' value="' + config.defaultValue + '"';
		}
		body += '>';

		var modal = Modal.create({
			id: id,
			title: config.title || 'Input',
			body: body,
			centered: true,
			footerButtons: [
				{
					text: config.cancelText || 'Cancel',
					class: 'btn btn-secondary',
					close: true
				},
				{
					text: config.submitText || 'Submit',
					class: 'btn btn-primary',
					id: id + '_submit'
				}
			]
		});

		// Focus input when shown
		modal.addEventListener('funky.modal.shown', function() {
			var input = document.getElementById(inputId);
			if (input) {
				input.focus();
				input.select();
			}
		});

		// Handle submit
		var submitBtn = document.getElementById(id + '_submit');
		if (submitBtn) {
			submitBtn.addEventListener('click', function() {
				var input = document.getElementById(inputId);
				var value = input ? input.value : '';
				submitBtn._submitted = true;
				Modal.hide('#' + id);
				if (config.onSubmit) {
					config.onSubmit(value);
				}
			});
		}

		// Handle enter key in input
		var inputEl = document.getElementById(inputId);
		if (inputEl) {
			inputEl.addEventListener('keydown', function(e) {
				if (e.key === 'Enter') {
					e.preventDefault();
					submitBtn.click();
				}
			});
		}

		// Bind cancel handler
		if (config.onCancel) {
			modal.addEventListener('funky.modal.hidden', function handler() {
				modal.removeEventListener('funky.modal.hidden', handler);
				if (!submitBtn._submitted) {
					config.onCancel();
				}
			});
		}

		// Show and return instance
		var instance = Modal.getOrCreateInstance('#' + id);
		instance.show();
		return instance;
	};

	/**
	 * Initialize modal triggers (data-funky-modal attribute)
	 * @param {string|HTMLElement} container - Container to search within (default: document)
	 */
	Modal.initTriggers = function(container) {
		var root = container ? getElement(container) : document;
		var triggers = root.querySelectorAll('[data-funky-modal]');

		triggers.forEach(function(trigger) {
			// Avoid double-binding
			if (trigger._funkyModalBound) return;
			trigger._funkyModalBound = true;

			trigger.addEventListener('click', function(e) {
				e.preventDefault();
				var target = trigger.getAttribute('data-funky-modal');
				Modal.show(target);
			});
		});
	};

	// =========================================================================
	// Auto-initialize
	// =========================================================================

	// Initialize triggers on DOM ready
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			Modal.initTriggers();
		});
	} else {
		Modal.initTriggers();
	}

	// Register with Funky namespace
	Funky.register('Modal', Modal);

})(window);
