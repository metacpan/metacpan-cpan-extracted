/**
 * Funky Toast - Toast Notification System
 * 
 * Native toast notification system with success, error, warning, info types.
 * Uses Bootstrap CSS classes but NO Bootstrap JavaScript.
 * Also supports confirmation dialogs with Yes/No buttons.
 * 
 * Usage:
 *   Funky.Toast.success('Saved successfully');
 *   Funky.Toast.error('Something went wrong', 'Error Title');
 *   Funky.Toast.warning('Please check your input');
 *   Funky.Toast.info('FYI...');
 *   Funky.Toast.confirm({
 *     message: 'Are you sure?',
 *     onConfirm: function() { ... }
 *   });
 * 
 * @version 1.0.4 - Removed Bootstrap JS dependency
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Toast] Registry not found. Load namespace.js first.');
		return;
	}

	/**
	 * FunkyToast Constructor
	 */
	function FunkyToast() {
		this.container = null;
		this.toasts = {};  // Track active toasts by ID
		this.initContainer();
	}

	/**
	 * Use Funky.Animate for duration management
	 */
	var Animate = Funky.Animate;

	/**
	 * Initialize toast container
	 */
	FunkyToast.prototype.initContainer = function() {
		// Check if container already exists
		var container = document.getElementById('funky-toast-container');

		if (!container) {
			// Create container using Funky.Dom
			var D = Funky.Dom;
			container = D.div()
				.id('funky-toast-container')
				.class('toast-container position-fixed top-0 end-0 p-3')
				.style({ 'z-index': '9999' })
				.get();
			document.body.appendChild(container);
		}

		this.container = container;
	};

	/**
	 * Show a toast with CSS transitions (no Bootstrap JS)
	 * @private
	 * @param {HTMLElement} toastEl - The toast element
	 * @param {number|null} duration - Auto-hide duration in ms (null = no auto-hide)
	 * @param {Function} onHidden - Optional callback when toast is hidden
	 */
	FunkyToast.prototype._showToast = function(toastEl, duration, onHidden) {
		var self = this;
		var toastId = toastEl.id;
		var D = Funky.Dom;

		// Store toast reference with hide function
		this.toasts[toastId] = {
			el: toastEl,
			hide: function() {
				self._hideToast(toastId, onHidden);
			}
		};

		// Add fade class for CSS transition
		D.wrap(toastEl).classAdd('fade');

		// Force reflow before adding show class
		// eslint-disable-next-line no-unused-expressions
		toastEl.offsetHeight;

		// Add show class to trigger CSS transition
		D.wrap(toastEl).classAdd('show showing');

		// Remove 'showing' after transition completes
		var transitionDuration = Animate.getDuration(toastEl, Animate.DURATION.FAST);
		setTimeout(function() {
			D.wrap(toastEl).classRemove('showing');
		}, transitionDuration);

		// Set up auto-hide if duration provided
		if (duration && duration > 0) {
			setTimeout(function() {
				self._hideToast(toastId, onHidden);
			}, duration);
		}
	};

	/**
	 * Hide a toast with CSS transitions
	 * @private
	 * @param {string} toastId - The toast ID
	 * @param {Function} onHidden - Optional callback when toast is hidden
	 */
	FunkyToast.prototype._hideToast = function(toastId, onHidden) {
		var self = this;
		var toast = this.toasts[toastId];
		if (!toast) return;

		var toastEl = toast.el;
		var D = Funky.Dom;

		// Add hiding class, remove show class
		D.wrap(toastEl).classAdd('hiding').classRemove('show');

		// After transition, remove element
		var transitionDuration = Animate.getDuration(toastEl, Animate.DURATION.FAST);
		setTimeout(function() {
			if (toastEl.parentNode) {
				toastEl.parentNode.removeChild(toastEl);
			}
			delete self.toasts[toastId];
			if (onHidden && typeof onHidden === 'function') {
				onHidden();
			}
		}, transitionDuration);
	};

	/**
	 * Handle close button click
	 * @private
	 * @param {string} toastId - The toast ID
	 * @param {Function} onCancel - Optional cancel callback
	 */
	FunkyToast.prototype._handleClose = function(toastId, onCancel) {
		var toast = this.toasts[toastId];
		if (toast) {
			toast.hide();
			if (onCancel && typeof onCancel === 'function') {
				onCancel();
			}
		}
	};

	/**
	 * Show a toast notification
	 * @param {Object} options - Toast options
	 * @param {string|Node|Object} options.message - Toast message (string, HTML, DOM, Dom wrapper, or VDom)
	 * @param {string} options.type - Toast type: 'success', 'error', 'warning', 'info'
	 * @param {string|Node|Object} options.title - Optional title (defaults based on type)
	 * @param {number} options.duration - Duration in ms (default: 5000)
	 */
	FunkyToast.prototype.show = function(options) {
		var defaults = {
			message: '',
			type: 'info',
			title: '',
			duration: 5000
		};

		var opts = Object.assign({}, defaults, options);

		// Set default titles based on type
		if (!opts.title) {
			var titles = {
				success: 'Success',
				error: 'Error',
				warning: 'Warning',
				info: 'Info'
			};
			opts.title = titles[opts.type] || 'Notification';
		}

		// Create toast element using Funky.Dom
		var D = Funky.Dom;
		var toastId = 'toast-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);

		// Icon classes based on type
		var iconClasses = {
			success: 'fas fa-check-circle',
			error: 'fas fa-exclamation-circle',
			warning: 'fas fa-exclamation-triangle',
			info: 'fas fa-info-circle'
		};

		// Build title element - use toDom for flexible content
		var titleEl = D.create('strong').class('me-auto ms-2').get();
		titleEl.appendChild(Funky.Util.toDom(opts.title));

		// Build body element - use toDom for flexible content
		var bodyEl = D.div().class('toast-body').get();
		bodyEl.appendChild(Funky.Util.toDom(opts.message));

		var self = this;
		// Use role="alert" with aria-live="assertive" for urgent messages (error, warning)
		// Use role="status" with aria-live="polite" for informational messages (info, success)
		var isUrgent = opts.type === 'error' || opts.type === 'warning';
		var toast = D.div()
			.id(toastId)
			.class('toast funky-toast funky-toast-' + opts.type)
			.attr('role', isUrgent ? 'alert' : 'status')
			.aria('live', isUrgent ? 'assertive' : 'polite')
			.aria('atomic', 'true')
			.child(
				D.div().class('toast-header').child(
					D.icon(iconClasses[opts.type] || iconClasses.info),
					{ el: titleEl },
					D.button()
						.attr('type', 'button')
						.class('btn-close')
						.data('funky-toast-close', toastId)
						.aria('label', 'Close')
				),
				{ el: bodyEl }
			)
			.get();

		// Append to container
		this.container.appendChild(toast);

		// Attach close button handler
		var closeBtn = toast.querySelector('[data-funky-toast-close]');
		if (closeBtn) {
			closeBtn.addEventListener('click', function() {
				self._handleClose(toastId);
			});
		}

		// Show toast with native CSS transitions
		this._showToast(toast, opts.duration);

		return toast;
	};

	/**
	 * Show success toast
	 * @param {string} message - Success message
	 * @param {string|Object} titleOrOptions - Optional title string or options object
	 */
	FunkyToast.prototype.success = function(message, titleOrOptions) {
		var opts = { message: message, type: 'success' };
		if (typeof titleOrOptions === 'object' && titleOrOptions !== null) {
			Object.assign(opts, titleOrOptions);
		} else if (titleOrOptions) {
			opts.title = titleOrOptions;
		}
		return this.show(opts);
	};

	/**
	 * Show error toast
	 * @param {string} message - Error message
	 * @param {string|Object} titleOrOptions - Optional title string or options object
	 */
	FunkyToast.prototype.error = function(message, titleOrOptions) {
		var opts = { message: message, type: 'error', duration: 7000 };
		if (typeof titleOrOptions === 'object' && titleOrOptions !== null) {
			Object.assign(opts, titleOrOptions);
		} else if (titleOrOptions) {
			opts.title = titleOrOptions;
		}
		return this.show(opts);
	};

	/**
	 * Show warning toast
	 * @param {string} message - Warning message
	 * @param {string|Object} titleOrOptions - Optional title string or options object
	 */
	FunkyToast.prototype.warning = function(message, titleOrOptions) {
		var opts = { message: message, type: 'warning', duration: 6000 };
		if (typeof titleOrOptions === 'object' && titleOrOptions !== null) {
			Object.assign(opts, titleOrOptions);
		} else if (titleOrOptions) {
			opts.title = titleOrOptions;
		}
		return this.show(opts);
	};

	/**
	 * Show info toast
	 * @param {string} message - Info message
	 * @param {string|Object} titleOrOptions - Optional title string or options object
	 */
	FunkyToast.prototype.info = function(message, titleOrOptions) {
		var opts = { message: message, type: 'info' };
		if (typeof titleOrOptions === 'object' && titleOrOptions !== null) {
			Object.assign(opts, titleOrOptions);
		} else if (titleOrOptions) {
			opts.title = titleOrOptions;
		}
		return this.show(opts);
	};

	/**
	 * Show confirmation toast with Yes/No buttons
	 * @param {Object} options - Confirmation options
	 * @param {string|Node|Object} options.message - Confirmation message (string, HTML, DOM, Dom wrapper, or VDom)
	 * @param {string|Node|Object} options.title - Optional title (default: 'Confirm')
	 * @param {Function} options.onConfirm - Callback when confirmed
	 * @param {Function} options.onCancel - Optional callback when cancelled
	 * @param {string} options.confirmText - Confirm button text (default: 'Yes')
	 * @param {string} options.cancelText - Cancel button text (default: 'No')
	 */
	FunkyToast.prototype.confirm = function(options) {
		var self = this;
		var defaults = {
			message: '',
			title: 'Confirm',
			onConfirm: null,
			onCancel: null,
			confirmText: 'Yes',
			cancelText: 'No'
		};

		var opts = Object.assign({}, defaults, options);

		// Create toast element using Funky.Dom
		var D = Funky.Dom;
		var toastId = 'toast-confirm-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);

		// Build title element - use toDom for flexible content
		var titleEl = D.create('strong').class('me-auto ms-2').get();
		titleEl.appendChild(Funky.Util.toDom(opts.title));

		// Build message element - use toDom for flexible content
		var messageEl = D.div().class('mb-3').get();
		messageEl.appendChild(Funky.Util.toDom(opts.message));

		var toast = D.div()
			.id(toastId)
			.class('toast funky-toast funky-toast-confirm')
			.attr('role', 'alert')
			.aria('live', 'assertive')
			.aria('atomic', 'true')
			.child(
				D.div().class('toast-header').child(
					D.icon('fas fa-question-circle'),
					{ el: titleEl },
					D.button()
						.attr('type', 'button')
						.class('btn-close')
						.data('funky-toast-close', toastId)
						.aria('label', 'Close')
				),
				D.div().class('toast-body').child(
					{ el: messageEl },
					D.div().class('d-flex gap-2 justify-content-end').child(
						D.button()
							.attr('type', 'button')
							.class('btn btn-sm btn-secondary toast-cancel')
							.text(opts.cancelText),
						D.button()
							.attr('type', 'button')
							.class('btn btn-sm btn-danger toast-confirm')
							.text(opts.confirmText)
					)
				)
			)
			.get();

		// Append to container
		this.container.appendChild(toast);

		// Handle confirm button
		var confirmBtn = toast.querySelector('.toast-confirm');
		confirmBtn.addEventListener('click', function() {
			self._hideToast(toastId);
			if (opts.onConfirm && typeof opts.onConfirm === 'function') {
				opts.onConfirm();
			}
		});

		// Handle cancel button
		var cancelBtn = toast.querySelector('.toast-cancel');
		cancelBtn.addEventListener('click', function() {
			self._hideToast(toastId);
			if (opts.onCancel && typeof opts.onCancel === 'function') {
				opts.onCancel();
			}
		});

		// Handle close button (same as cancel)
		var closeBtn = toast.querySelector('[data-funky-toast-close]');
		if (closeBtn) {
			closeBtn.addEventListener('click', function() {
				self._handleClose(toastId, opts.onCancel);
			});
		}

		// Show toast with no auto-hide (confirmation requires user action)
		this._showToast(toast, null);

		return toast;
	};

	// =========================================================================
	// BINDABLE INTERFACE
	// =========================================================================

	/**
	 * Add notification data (Bindable Interface)
	 * Used for streaming notifications from LiveBinding or WebSocket
	 * @param {Object|Array} data - Notification(s) to display
	 * @param {string} data.message - Notification message (required)
	 * @param {string} data.type - Type: 'success', 'error', 'warning', 'info'
	 * @param {string} data.title - Optional title
	 * @param {number} data.duration - Optional duration in ms
	 */
	FunkyToast.prototype.addData = function(data) {
		var self = this;
		var notifications = Array.isArray(data) ? data : [data];

		notifications.forEach(function(notification) {
			if (!notification || !notification.message) {
				console.warn('[Funky.Toast] addData: Missing message in notification');
				return;
			}

			self.show({
				message: notification.message,
				type: notification.type || 'info',
				title: notification.title,
				duration: notification.duration
			});
		});
	};

	/**
	 * Hide all active toasts and destroy container
	 */
	FunkyToast.prototype.destroyAll = function() {
		var self = this;

		// Hide all active toasts
		Object.keys(this.toasts).forEach(function(toastId) {
			self._hideToast(toastId);
		});

		// Remove container if empty after cleanup
		if (this.container && this.container.parentNode) {
			this.container.parentNode.removeChild(this.container);
			this.container = null;
		}
	};

	/**
	 * Hide all active toasts (but keep container)
	 */
	FunkyToast.prototype.hideAll = function() {
		var self = this;
		Object.keys(this.toasts).forEach(function(toastId) {
			self._hideToast(toastId);
		});
	};

	// Create instance
	var toastInstance = new FunkyToast();

	// Register with Funky namespace
	Funky.register('Toast', toastInstance);

})(window);
