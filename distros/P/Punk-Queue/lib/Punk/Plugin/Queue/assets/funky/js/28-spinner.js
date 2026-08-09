/**
 * Funky.Spinner - Loading Spinner Component
 * Versatile loading spinners with multiple styles
 * @module Funky.Spinner
 * @version 1.0.4
 */
(function(window) {
  'use strict';

  // Ensure Funky registry exists
  if (!window.Funky || !window.Funky.register) {
    console.error('[Funky.Spinner] Registry not found. Load namespace.js first.');
    return;
  }

  var Funky = window.Funky;

  // Guard against double registration
  if (Funky.Spinner) {
    return;
  }

  /**
   * Spinner Component
   */
  var Spinner = {
    /**
     * Default configuration
     */
    defaults: {
      style: 'border',         // border, grow, dots, pulse, ring
      size: 'md',              // xs, sm, md, lg, xl
      variant: 'primary',      // primary, secondary, success, warning, danger, info, light, dark
      text: '',                // Optional loading text
      srText: 'Loading...',    // Screen reader text
      fadeIn: true,            // Animate spinner appearance
      fadeDuration: 200        // Fade duration in ms
    },

    /** Active spinners map */
    _active: new Map(),

    /** Overlay element */
    _overlay: null,

    /**
     * Create a spinner element
     * @param {Object} options - Spinner options
     * @returns {HTMLElement} Spinner element
     */
    create: function(options) {
      var opts = Object.assign({}, this.defaults, options);
      
      var wrapper = document.createElement('div');
      wrapper.className = 'funky-spinner-inline';
      
      var spinner = this._createSpinnerElement(opts);
      wrapper.appendChild(spinner);
      
      if (opts.text) {
        var text = document.createElement('span');
        text.className = 'funky-spinner-text';
        text.textContent = opts.text;
        wrapper.appendChild(text);
      }
      
      return wrapper;
    },

    /**
     * Create the core spinner element
     * @private
     */
    _createSpinnerElement: function(opts) {
      var spinner;
      
      if (opts.style === 'dots') {
        spinner = document.createElement('div');
        spinner.className = 'funky-spinner funky-spinner-dots';
        for (var i = 0; i < 3; i++) {
          var dot = document.createElement('span');
          dot.className = 'dot';
          spinner.appendChild(dot);
        }
      } else {
        spinner = document.createElement('div');
        spinner.className = 'funky-spinner funky-spinner-' + opts.style;
      }
      
      // Add size class
      spinner.classList.add('funky-spinner-' + opts.size);
      
      // Add variant class
      if (opts.variant) {
        spinner.classList.add('funky-spinner-' + opts.variant);
      }
      
      // Screen reader text
      var srText = document.createElement('span');
      srText.className = 'funky-spinner-sr';
      srText.textContent = opts.srText || 'Loading...';
      spinner.appendChild(srText);
      
      spinner.setAttribute('role', 'status');
      spinner.setAttribute('aria-live', 'polite');
      
      return spinner;
    },

    /**
     * Show spinner in a container
     * @param {string|HTMLElement} container - Container selector or element
     * @param {Object} options - Spinner options
     * @returns {Object} Controller with hide method
     */
    show: function(container, options) {
      var self = this;
      var el = typeof container === 'string' 
        ? document.querySelector(container) 
        : container;

      if (!el) {
        console.warn('[Spinner] Container not found:', container);
        return null;
      }

      // Remove existing spinner in this container immediately (no animation)
      if (this._active.has(el)) {
        var existing = this._active.get(el);
        if (existing && existing.wrapper && existing.wrapper.parentNode) {
          existing.wrapper.parentNode.removeChild(existing.wrapper);
        }
        this._active.delete(el);
      }

      var opts = Object.assign({}, this.defaults, options);

      // Ensure container is positioned
      var position = window.getComputedStyle(el).position;
      if (position === 'static') {
        el.style.position = 'relative';
      }

      // Create wrapper
      var wrapper = document.createElement('div');
      wrapper.className = 'funky-spinner-wrapper';
      
      var spinner = this._createSpinnerElement(opts);
      wrapper.appendChild(spinner);
      
      if (opts.text) {
        var text = document.createElement('span');
        text.className = 'funky-spinner-text';
        text.textContent = opts.text;
        wrapper.appendChild(text);
      }

      el.appendChild(wrapper);
      el.classList.add('funky-spinner-container', 'loading');

      var controller = {
        element: el,
        wrapper: wrapper,
        options: opts,
        hide: function() {
          self.hide(el);
        }
      };

      this._active.set(el, controller);

      return controller;
    },

    /**
     * Hide spinner in a container
     * @param {string|HTMLElement} container - Container selector or element
     */
    hide: function(container) {
      var el = typeof container === 'string' 
        ? document.querySelector(container) 
        : container;

      if (!el) return;

      var controller = this._active.get(el);
      if (!controller) return;

      el.classList.remove('loading');
      
      // Remove wrapper after transition
      setTimeout(function() {
        if (controller.wrapper && controller.wrapper.parentNode) {
          controller.wrapper.parentNode.removeChild(controller.wrapper);
        }
        el.classList.remove('funky-spinner-container');
      }, controller.options.fadeDuration);

      this._active.delete(el);
    },

    /**
     * Show full-page overlay spinner
     * @param {Object} options - Spinner options
     * @returns {Object} Controller with hide method
     */
    overlay: function(options) {
      var self = this;
      
      // Hide existing overlay
      this.hideOverlay();

      var opts = Object.assign({}, this.defaults, { size: 'lg' }, options);

      var overlay = document.createElement('div');
      overlay.className = 'funky-spinner-overlay';
      
      var spinner = this._createSpinnerElement(opts);
      overlay.appendChild(spinner);
      
      if (opts.text) {
        var text = document.createElement('span');
        text.className = 'funky-spinner-text';
        text.textContent = opts.text;
        overlay.appendChild(text);
      }

      document.body.appendChild(overlay);
      this._overlay = overlay;

      // Trigger reflow for transition
      overlay.offsetHeight;
      overlay.classList.add('show');

      return {
        hide: function() {
          self.hideOverlay();
        }
      };
    },

    /**
     * Hide full-page overlay spinner
     */
    hideOverlay: function() {
      if (!this._overlay) return;

      var overlay = this._overlay;
      overlay.classList.remove('show');

      setTimeout(function() {
        if (overlay.parentNode) {
          overlay.parentNode.removeChild(overlay);
        }
      }, 200);

      this._overlay = null;
    },

    /**
     * Wrap an async operation with spinner
     * @param {string|HTMLElement} container - Container (null for overlay)
     * @param {Function} asyncFn - Async function returning a Promise
     * @param {Object} options - Spinner options
     * @returns {Promise}
     */
    wrap: function(container, asyncFn, options) {
      var self = this;
      var controller;

      if (container) {
        controller = this.show(container, options);
      } else {
        controller = this.overlay(options);
      }

      return Promise.resolve()
        .then(function() {
          return asyncFn();
        })
        .then(function(result) {
          if (controller) controller.hide();
          return result;
        })
        .catch(function(err) {
          if (controller) controller.hide();
          throw err;
        });
    },

    /**
     * Check if a container has active spinner
     * @param {string|HTMLElement} container
     * @returns {boolean}
     */
    isLoading: function(container) {
      var el = typeof container === 'string' 
        ? document.querySelector(container) 
        : container;
      return el ? this._active.has(el) : false;
    },

    /**
     * Hide all active spinners
     */
    hideAll: function() {
      var self = this;
      this._active.forEach(function(controller, el) {
        self.hide(el);
      });
      this.hideOverlay();
    }
  };

  // ==========================================================================
  // EXPORT
  // ==========================================================================

  Funky.register('Spinner', Spinner);

})(window);
