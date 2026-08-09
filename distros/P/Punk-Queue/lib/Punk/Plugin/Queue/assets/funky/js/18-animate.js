/**
 * Funky.Animate - Unified Animation System
 *
 * Provides low-level animation primitives with accessibility-first design.
 *
 * Features:
 * - Duration/easing management with accessibility checks
 * - Class-based animation API
 * - Transform utilities (fade, slide, scale, shake)
 * - Composition (sequence, parallel, stagger)
 * - Component mixin pattern
 * - Lifecycle events
 *
 * Usage:
 *   // Simple animation
 *   Funky.Animate.fade('#element', 'in');
 *   Funky.Animate.slide('#element', 'in', { from: 'right' });
 *
 *   // Composition
 *   Funky.Animate.sequence([
 *     { element: '#step1', options: { class: 'fade-in' } },
 *     { element: '#step2', options: { class: 'slide-in-right' } }
 *   ]).start();
 *
 *   // Component mixin
 *   Funky.Animate.mixin(myComponent, {
 *     show: { class: 'fade-in', duration: 300 },
 *     hide: { class: 'fade-out', duration: 200 }
 *   });
 *
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Animate] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Animate')) {
		return;
	}

	// Shortcuts
	var D = Funky.Dom;
	var P = Funky.PubSub;

	// Helper to add/remove space-separated classes (classList.add/remove don't support spaces)
	function addClasses(el, classStr) {
		if (!classStr) return;
		classStr.split(/\s+/).filter(Boolean).forEach(function(c) {
			el.classList.add(c);
		});
	}

	function removeClasses(el, classStr) {
		if (!classStr) return;
		classStr.split(/\s+/).filter(Boolean).forEach(function(c) {
			el.classList.remove(c);
		});
	}

	// =========================================================================
	// CORE ANIMATE OBJECT
	// =========================================================================

	var Animate = {
		// Predefined durations
		DURATION: {
			FAST: 150,      // UI components (tabs, tooltips, popovers)
			NORMAL: 300,    // Modals, navigation
			SLOW: 600       // Page transitions
		},

		// Easing curves
		EASING: {
			LINEAR: 'linear',
			EASE: 'ease',
			EASE_IN: 'ease-in',
			EASE_OUT: 'ease-out',
			EASE_IN_OUT: 'ease-in-out',
			EASE_IN_QUAD: 'cubic-bezier(0.55, 0.085, 0.68, 0.53)',
			EASE_OUT_QUAD: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
			EASE_IN_OUT_QUAD: 'cubic-bezier(0.455, 0.03, 0.515, 0.955)'
		},

		/**
		 * Global animation speed multiplier for WCAG compliance
		 * Allows users to adjust all animation speeds via user preferences.
		 *
		 * Values:
		 * - 0.5 = half speed (slower animations)
		 * - 1.0 = normal speed (default)
		 * - 2.0 = double speed (faster animations)
		 *
		 * TODO: Integrate with user preferences system
		 * Example integration:
		 *   // In user settings save handler:
		 *   Funky.Animate.speedMultiplier = parseFloat(userSettings.animationSpeed) || 1.0;
		 *
		 * @type {number}
		 */
		speedMultiplier: 1.0,

		/**
		 * Get animation duration with accessibility checks
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {number} defaultMs - Default duration in milliseconds
		 * @returns {number} Duration in milliseconds (0 if animations disabled)
		 */
		getDuration: function(element, defaultMs) {
			// Guard against null/undefined input
			if (!element) return 0;

			var wrapped = D.one(element);
			// D.one returns ElementWrapper - check if underlying element exists
			if (!wrapped || !wrapped.el) return 0;

			// Get raw DOM element from wrapper
			var el = wrapped.el;

			// Guard against non-DOM elements (must have classList)
			if (!el.classList) return 0;

			// Check global animations preference
			var animationsOff = document.documentElement.getAttribute('data-animations') === 'off';

			// Check prefers-reduced-motion
			var prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

			// Check element has fade class
			var hasFade = el.classList.contains('fade');

			if (animationsOff || prefersReduced || !hasFade) {
				return 0;
			}

			// Check for custom duration on element
			var customDuration = el.getAttribute('data-animate-duration');
			if (customDuration) {
				return Math.round(parseInt(customDuration, 10) * this.speedMultiplier);
			}

			return Math.round((defaultMs || 300) * this.speedMultiplier);
		},

		/**
		 * Core animation function
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {Object} options - Animation options
		 * @returns {Object} Animation instance with cancel method
		 */
		animate: function(element, options) {
			var wrapped = D.one(element);
			// D.one returns ElementWrapper - check if underlying element exists
			if (!wrapped || !wrapped.el) return null;

			// Get raw DOM element from wrapper
			var el = wrapped.el;

			var defaults = {
				class: '',              // Animation class to add
				duration: null,         // Duration in ms (null = auto-detect)
				easing: null,           // Easing curve
				delay: 0,               // Delay before start
				onStart: null,          // Callback when animation starts
				onEnd: null             // Callback when animation ends
			};

			var opts = Object.assign({}, defaults, options);
			var duration = opts.duration !== null && opts.duration !== undefined
				? opts.duration
				: this.getDuration(el, this.DURATION.NORMAL);

			// Animation instance with cancellation support
			var animation = {
				element: el,
				cancelled: false,

				cancel: function() {
					this.cancelled = true;
					removeClasses(el, opts.class);
					if (this.timeoutId) clearTimeout(this.timeoutId);
					if (this.delayTimeoutId) clearTimeout(this.delayTimeoutId);
				}
			};

			// Start animation after delay
			animation.delayTimeoutId = setTimeout(function() {
				if (animation.cancelled) return;

				// Apply custom duration/easing via inline styles if specified
				if (opts.duration) {
					el.style.animationDuration = opts.duration + 'ms';
				}
				if (opts.easing) {
					el.style.animationTimingFunction = opts.easing;
				}

				// Add animation class
				addClasses(el, opts.class);

				// Trigger start callback
				if (opts.onStart) {
					try {
						opts.onStart.call(el, el);
					} catch (e) {
						console.error('[Funky.Animate] onStart callback error:', e);
					}
				}

				// Emit start event
				P.emit('funky:animate:start', { element: el, class: opts.class });

				// Remove class and trigger callback after duration
				if (duration > 0) {
					animation.timeoutId = setTimeout(function() {
						if (animation.cancelled) return;

						removeClasses(el, opts.class);

						// Clear inline styles
						el.style.animationDuration = '';
						el.style.animationTimingFunction = '';

						// Trigger end callback
						if (opts.onEnd) {
							try {
								opts.onEnd.call(el, el);
							} catch (e) {
								console.error('[Funky.Animate] onEnd callback error:', e);
							}
						}

						// Emit end event
						P.emit('funky:animate:end', { element: el, class: opts.class });
					}, duration);
				} else {
					// Zero duration - immediately complete
					removeClasses(el, opts.class);

					// Trigger end callback
					if (opts.onEnd) {
						try {
							opts.onEnd.call(el, el);
						} catch (e) {
							console.error('[Funky.Animate] onEnd callback error:', e);
						}
					}

					// Emit end event
					P.emit('funky:animate:end', { element: el, class: opts.class });
				}
			}, opts.delay);

			return animation;
		},

		/**
		 * Fade animation
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {string} direction - 'in' or 'out'
		 * @param {Object} options - Animation options
		 * @returns {Object} Animation instance
		 */
		fade: function(element, direction, options) {
			var defaults = { duration: this.DURATION.NORMAL };
			var opts = Object.assign({}, defaults, options);
			var animClass = direction === 'in' ? 'fade-in' : 'fade-out';
			return this.animate(element, Object.assign({}, opts, { class: animClass }));
		},

		/**
		 * Slide animation
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {string} direction - 'in' or 'out'
		 * @param {Object} options - Animation options (from: 'right', 'left', 'top', 'bottom')
		 * @returns {Object} Animation instance
		 */
		slide: function(element, direction, options) {
			var defaults = {
				duration: this.DURATION.NORMAL,
				from: 'right'  // right, left, top, bottom
			};
			var opts = Object.assign({}, defaults, options);
			var animClass = 'slide-' + direction + '-' + opts.from;
			return this.animate(element, Object.assign({}, opts, { class: animClass }));
		},

		/**
		 * Scale animation
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {string} direction - 'in' or 'out'
		 * @param {Object} options - Animation options
		 * @returns {Object} Animation instance
		 */
		scale: function(element, direction, options) {
			var defaults = { duration: this.DURATION.FAST };
			var opts = Object.assign({}, defaults, options);
			var animClass = direction === 'in' ? 'scale-in' : 'scale-out';
			return this.animate(element, Object.assign({}, opts, { class: animClass }));
		},

		/**
		 * Shake animation (attention seeker)
		 * @param {string|HTMLElement} element - Element or selector
		 * @param {Object} options - Animation options
		 * @returns {Object} Animation instance
		 */
		shake: function(element, options) {
			var defaults = { duration: 500 };
			var opts = Object.assign({}, defaults, options);
			return this.animate(element, Object.assign({}, opts, { class: 'shake' }));
		},

		/**
		 * Sequence animations (run one after another)
		 * @param {Array} animations - Array of {element, options} objects
		 * @returns {Object} Sequence control with start() and cancel() methods
		 */
		sequence: function(animations) {
			var current = 0;
			var instances = [];
			var self = this;

			var sequenceControl = {
				cancelled: false,

				cancel: function() {
					this.cancelled = true;
					instances.forEach(function(instance) {
						if (instance && instance.cancel) instance.cancel();
					});
				},

				start: function() {
					var ctrl = this;

					function runNext() {
						if (ctrl.cancelled || current >= animations.length) return;

						var anim = animations[current++];
						var instance = self.animate(anim.element, Object.assign({}, anim.options, {
							onEnd: function() {
								if (anim.options && anim.options.onEnd) {
									anim.options.onEnd.call(this);
								}
								runNext();
							}
						}));

						instances.push(instance);
					}

					runNext();
					return this;
				}
			};

			return sequenceControl;
		},

		/**
		 * Parallel animations (run simultaneously)
		 * @param {Array} animations - Array of {element, options} objects
		 * @returns {Object} Parallel control with start() and cancel() methods
		 */
		parallel: function(animations) {
			var instances = [];
			var self = this;

			var parallelControl = {
				cancelled: false,

				cancel: function() {
					this.cancelled = true;
					instances.forEach(function(instance) {
						if (instance && instance.cancel) instance.cancel();
					});
				},

				start: function() {
					var ctrl = this;

					animations.forEach(function(anim) {
						if (ctrl.cancelled) return;
						var instance = self.animate(anim.element, anim.options);
						instances.push(instance);
					});

					return this;
				}
			};

			return parallelControl;
		},

		/**
		 * Stagger animations (animate list with delay between items)
		 * @param {string|NodeList|Array} elements - Elements to animate
		 * @param {Object} options - Animation options (stagger: delay in ms)
		 * @returns {Object} Stagger control with cancel() method
		 */
		stagger: function(elements, options) {
			var defaults = {
				class: 'fade-in-up',
				duration: this.DURATION.NORMAL,
				stagger: 100,
				onComplete: null
			};

			var opts = Object.assign({}, defaults, options);
			var els = D.all(elements);
			// Defensive check
			if (!els || typeof els.each !== 'function') {
				console.error('[Funky.Animate.stagger] D.all did not return a valid ElementList', {
					elements: elements,
					els: els,
					D: D,
					allType: typeof D.all
				});
				return { cancel: function() {} };
			}

			var instances = [];
			var completed = 0;
			var self = this;

			var staggerControl = {
				cancelled: false,

				cancel: function() {
					this.cancelled = true;
					instances.forEach(function(instance) {
						if (instance && instance.cancel) instance.cancel();
					});
				}
			};

			els.each(function(wrapper, index) {
				var delay = index * opts.stagger;

				var instance = self.animate(this, {
					class: opts.class,
					duration: opts.duration,
					delay: delay,
					onEnd: function() {
						completed++;
						if (completed === els.length && opts.onComplete) {
							opts.onComplete();
						}
					}
				});

				instances.push(instance);
			});

			return staggerControl;
		},

		/**
		 * Mixin animation methods into a component
		 * @param {Object} component - Component instance
		 * @param {Object} config - Animation configuration
		 * @returns {Object} Component with animation methods added
		 */
		mixin: function(component, config) {
			var defaults = {
				show: { class: 'fade-in', duration: 300 },
				hide: { class: 'fade-out', duration: 200 },
				element: null
			};

			var opts = Object.assign({}, defaults, config);
			var element = opts.element || component.element;
			var self = this;

			// Add animation methods to component instance
			component.animateShow = function(options) {
				var animOpts = Object.assign({}, opts.show, options);
				component._currentAnimation = self.animate(element, animOpts);
				return component._currentAnimation;
			};

			component.animateHide = function(options) {
				var animOpts = Object.assign({}, opts.hide, options);
				component._currentAnimation = self.animate(element, animOpts);
				return component._currentAnimation;
			};

			component.animateToggle = function(show, options) {
				return show ? component.animateShow(options) : component.animateHide(options);
			};

			component._currentAnimation = null;

			component.cancelAnimation = function() {
				if (component._currentAnimation && component._currentAnimation.cancel) {
					component._currentAnimation.cancel();
					component._currentAnimation = null;
				}
			};

			return component;
		},

		/**
		 * Wrap existing component methods with animation
		 * @param {Object} component - Component instance
		 * @param {Object} config - Animation configuration
		 * @returns {Object} Component with wrapped methods
		 */
		wrap: function(component, config) {
			var originalShow = component.show;
			var originalHide = component.hide;

			this.mixin(component, config);

			if (originalShow) {
				component.show = function() {
					var args = arguments;
					var self = this;

					this.animateShow({
						onEnd: function() {
							if (originalShow) {
								originalShow.apply(self, args);
							}
						}
					});

					return this;
				};
			}

			if (originalHide) {
				component.hide = function() {
					var args = arguments;
					var self = this;

					this.animateHide({
						onEnd: function() {
							if (originalHide) {
								originalHide.apply(self, args);
							}
						}
					});

					return this;
				};
			}

			return component;
		}
	};

	// =========================================================================
	// Register with Funky namespace
	// =========================================================================

	Funky.register('Animate', Animate);

	console.log('[Funky.Animate] v1.0.0 initialized');

})(window);
