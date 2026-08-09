/**
 * Funky.Badge
 * 
 * Generic badge utility for attaching count/status indicators to any element.
 * Can be used standalone or by other components (QuickNav, Tabs, DataTables, etc.)
 * 
 * @example
 * // Attach badge to element
 * Funky.Badge.attach('#notifications-btn', { value: 5, type: 'count' });
 * 
 * // Update badge
 * Funky.Badge.update('#notifications-btn', { value: 10, animate: true });
 * 
 * // Remove badge
 * Funky.Badge.remove('#notifications-btn');
 * 
 * // Auto-update from PubSub
 * Funky.Badge.subscribe('#notifications-btn', 'app:notifications:count');
 */
(function(global) {
  'use strict';

  // Ensure Funky registry exists
  if (!global.Funky || !global.Funky.register) {
    console.error('[Funky.Badge] Registry not found. Load namespace.js first.');
    return;
  }

  // Prevent duplicate registration
  if (global.Funky.isRegistered && global.Funky.isRegistered('Badge')) {
    return;
  }

  var Funky = global.Funky;
  var D = Funky.Dom;
  var PubSub = Funky.PubSub;

  // =========================================================================
  // Constants
  // =========================================================================

  var BADGE_CLASS = 'funky-badge';
  var BADGE_TYPES = ['count', 'dot', 'warning', 'success', 'info'];
  var DATA_ATTR = 'data-funky-badge';

  // =========================================================================
  // Subscription Tracking
  // =========================================================================

  var subscriptions = {};
  var subscriptionId = 0;

  // =========================================================================
  // Utility Functions
  // =========================================================================

  /**
   * Check if user prefers reduced motion
   * Uses Funky.MediaQuery for shared listener
   * @returns {boolean}
   */
  function prefersReducedMotion() {
    if (Funky.MediaQuery) {
      return Funky.MediaQuery.matches('reduced-motion');
    }
    // Fallback if MediaQuery not loaded
    return window.matchMedia && 
           window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  /**
   * Get element from selector or element
   * @param {string|Element|Object} target - Selector, DOM element, or Funky.Dom element
   * @returns {Object|null} Funky.Dom element or null
   */
  function getElement(target) {
    if (!target) return null;

    // Already a Funky.Dom element
    if (target.classAdd && target.findOne) {
      return target;
    }

    // DOM element
    if (target.nodeType) {
      return D.one(target);
    }

    // Selector string
    if (typeof target === 'string') {
      return D.one(target);
    }

    return null;
  }

  /**
   * Normalize badge options
   * @param {number|string|Object} options - Badge value or options object
   * @returns {Object} Normalized options
   */
  function normalizeOptions(options) {
    // Handle simple values
    if (typeof options === 'number' || typeof options === 'string') {
      return { value: options, type: 'count', animate: true, max: 99, position: 'top-right', className: '' };
    }

    // Handle object options
    return {
      value: options.value,
      type: options.type || 'count',
      animate: options.animate !== false,
      max: options.max || 99,
      position: options.position || 'top-right',
      className: options.className || ''
    };
  }

  /**
   * Get display text for badge
   * @param {Object} options - Normalized badge options
   * @returns {string} Display text
   */
  function getBadgeText(options) {
    switch (options.type) {
      case 'dot':
        return '';
      case 'warning':
        return options.value !== undefined ? String(options.value) : '!';
      case 'success':
        return options.value !== undefined ? String(options.value) : '✓';
      case 'info':
        return options.value !== undefined ? String(options.value) : 'i';
      default: // count
        if (options.value === undefined || options.value === null) return '';
        var num = Number(options.value);
        if (isNaN(num)) return String(options.value);
        return num > options.max ? options.max + '+' : String(num);
    }
  }

  /**
   * Create badge element
   * @param {Object} options - Normalized badge options
   * @returns {Object} Funky.Dom badge element
   */
  function createBadgeElement(options) {
    var badge = D.create('span')
      .classAdd(BADGE_CLASS)
      .classAdd(BADGE_CLASS + '--' + options.type)
      .classAdd(BADGE_CLASS + '--' + options.position);

    if (options.className) {
      badge.classAdd(options.className);
    }

    // Add text content
    var text = getBadgeText(options);
    if (text) {
      badge.text(text);
    }

    // Large badge for overflow numbers
    if (options.type === 'count' && options.value > options.max) {
      badge.classAdd(BADGE_CLASS + '--large');
    }

    return badge;
  }

  // =========================================================================
  // Public API
  // =========================================================================

  var Badge = {
    /**
     * Attach a badge to an element
     * @param {string|Element|Object} target - Target element or selector
     * @param {number|string|Object} options - Badge value or options
     * @returns {Object} Badge for chaining
     */
    attach: function(target, options) {
      var el = getElement(target);
      if (!el) {
        console.warn('[Badge] Target element not found');
        return this;
      }

      // Normalize options
      var opts = normalizeOptions(options);

      // Check if badge should be shown
      // Allow dot, warning, success, info types without a value (they have defaults)
      var typesWithDefaults = ['dot', 'warning', 'success', 'info'];
      if (opts.value === undefined && opts.value !== 0 && typesWithDefaults.indexOf(opts.type) === -1) {
        return this;
      }

      // Remove existing badge first
      this.remove(el);

      // Ensure element has relative positioning for badge placement
      var position = el.css('position');
      if (position === 'static' || !position) {
        el.style({ position: 'relative' });
      }

      // Create and append badge
      var badge = createBadgeElement(opts);
      badge.appendTo(el);

      // Mark element as having a badge
      el.attr(DATA_ATTR, opts.type);

      // Emit event
      PubSub.emit('funky:badge:attached', {
        element: el.get(),
        value: opts.value,
        type: opts.type
      });

      return this;
    },

    /**
     * Update an existing badge
     * @param {string|Element|Object} target - Target element or selector
     * @param {number|string|Object} options - New badge value or options
     * @returns {Object} Badge for chaining
     */
    update: function(target, options) {
      var el = getElement(target);
      if (!el) return this;

      var opts = normalizeOptions(options);

      // Find existing badge
      var existingBadge = el.findOne('.' + BADGE_CLASS);
      var oldValue = null;

      if (existingBadge) {
        oldValue = existingBadge.text();
        existingBadge.remove();
      }

      // If value is null/undefined and not a type with defaults, just remove
      var typesWithDefaults = ['dot', 'warning', 'success', 'info'];
      if (opts.value === undefined && opts.value !== 0 && typesWithDefaults.indexOf(opts.type) === -1) {
        this.remove(el);
        return this;
      }

      // Create new badge
      var badge = createBadgeElement(opts);

      // Animate if value changed
      if (opts.animate && oldValue !== getBadgeText(opts) && !prefersReducedMotion()) {
        badge.classAdd(BADGE_CLASS + '--animate');
      }

      badge.appendTo(el);
      el.attr(DATA_ATTR, opts.type);

      // Emit event
      PubSub.emit('funky:badge:updated', {
        element: el.get(),
        value: opts.value,
        type: opts.type,
        previousValue: oldValue
      });

      return this;
    },

    /**
     * Remove badge from an element
     * @param {string|Element|Object} target - Target element or selector
     * @returns {Object} Badge for chaining
     */
    remove: function(target) {
      var el = getElement(target);
      if (!el) return this;

      var badge = el.findOne('.' + BADGE_CLASS);
      if (badge) {
        badge.remove();
      }

      el.attr(DATA_ATTR, null);

      // Emit event
      PubSub.emit('funky:badge:removed', {
        element: el.get()
      });

      return this;
    },

    /**
     * Check if element has a badge
     * @param {string|Element|Object} target - Target element or selector
     * @returns {boolean}
     */
    has: function(target) {
      var el = getElement(target);
      if (!el) return false;
      return el.attr(DATA_ATTR) !== null;
    },

    /**
     * Get badge value from element
     * @param {string|Element|Object} target - Target element or selector
     * @returns {string|null} Badge text or null
     */
    getValue: function(target) {
      var el = getElement(target);
      if (!el) return null;

      var badge = el.findOne('.' + BADGE_CLASS);
      return badge ? badge.text() : null;
    },

    /**
     * Get badge type from element
     * @param {string|Element|Object} target - Target element or selector
     * @returns {string|null} Badge type or null
     */
    getType: function(target) {
      var el = getElement(target);
      if (!el) return null;
      return el.attr(DATA_ATTR);
    },

    /**
     * Subscribe element to PubSub event for auto-updating
     * @param {string|Element|Object} target - Target element or selector
     * @param {string} eventName - PubSub event name (colon notation)
     * @param {Object} [options] - Default badge options (type, max, position)
     * @returns {string} Subscription ID for unsubscribing
     */
    subscribe: function(target, eventName, options) {
      var self = this;
      var el = getElement(target);
      if (!el) {
        console.warn('[Badge] Target element not found for subscription');
        return null;
      }

      var id = 'badge-sub-' + (++subscriptionId);
      var defaultOpts = options || {};

      var handler = function(data) {
        // Extract value from data
        var value;
        if (typeof data === 'object') {
          value = data.count !== undefined ? data.count : 
                  data.value !== undefined ? data.value : data;
        } else {
          value = data;
        }

        // Merge with default options
        var opts = {
          value: value,
          type: defaultOpts.type || 'count',
          animate: defaultOpts.animate !== false,
          max: defaultOpts.max || 99,
          position: defaultOpts.position || 'top-right'
        };

        self.update(el, opts);
      };

      PubSub.on(eventName, handler);

      subscriptions[id] = {
        element: el,
        event: eventName,
        handler: handler
      };

      return id;
    },

    /**
     * Unsubscribe from PubSub event
     * @param {string} subscriptionId - ID returned from subscribe()
     * @returns {Object} Badge for chaining
     */
    unsubscribe: function(subscriptionId) {
      var sub = subscriptions[subscriptionId];
      if (sub) {
        PubSub.off(sub.event, sub.handler);
        delete subscriptions[subscriptionId];
      }
      return this;
    },

    /**
     * Unsubscribe all subscriptions for an element
     * @param {string|Element|Object} target - Target element or selector
     * @returns {Object} Badge for chaining
     */
    unsubscribeAll: function(target) {
      var el = getElement(target);
      if (!el) return this;

      var targetEl = el.get();
      var self = this;

      Object.keys(subscriptions).forEach(function(id) {
        var sub = subscriptions[id];
        if (sub.element.get() === targetEl) {
          self.unsubscribe(id);
        }
      });

      return this;
    },

    /**
     * Clear all badge subscriptions
     * @returns {Object} Badge for chaining
     */
    clearSubscriptions: function() {
      var self = this;
      Object.keys(subscriptions).forEach(function(id) {
        self.unsubscribe(id);
      });
      return this;
    },

    // Expose constants for external use
    CLASS: BADGE_CLASS,
    TYPES: BADGE_TYPES
  };

  // Register with Funky
  Funky.register('Badge', Badge);

})(window);
