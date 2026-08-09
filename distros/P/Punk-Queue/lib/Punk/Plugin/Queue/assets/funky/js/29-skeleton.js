/**
 * Funky.Skeleton - Loading Placeholder Component
 * Animated skeleton placeholders for perceived performance
 * @module Funky.Skeleton
 * @version 1.0.4
 */
(function(window) {
  'use strict';

  // Ensure Funky registry exists
  if (!window.Funky || !window.Funky.register) {
    console.error('[Funky.Skeleton] Registry not found. Load namespace.js first.');
    return;
  }

  var Funky = window.Funky;

  // Guard against double registration
  if (Funky.Skeleton) {
    return;
  }

  /**
   * Skeleton Component
   */
  var Skeleton = {
    /**
     * Default configuration
     */
    defaults: {
      type: 'text',           // text, table, card, list, avatar, custom
      rows: 3,                // Number of rows (for table, list, text)
      columns: 4,             // Number of columns (for table)
      count: 3,               // Number of items (for cards)
      avatar: false,          // Show avatar in list
      header: true,           // Show header row in table
      image: true,            // Show image in card
      lines: 3,               // Lines of text
      size: 'md',             // Avatar size: sm, md, lg
      template: null,         // Custom HTML template
      fadeOut: true,          // Animate skeleton removal
      fadeDuration: 200       // Fade duration in ms
    },

    /** Active skeletons map */
    _active: new Map(),

    /**
     * Show skeleton in a container
     * @param {string|HTMLElement} container - Container selector or element
     * @param {Object} options - Configuration options
     * @returns {Object} Controller with hide method
     */
    show: function(container, options) {
      var self = this;
      var el = typeof container === 'string' 
        ? document.querySelector(container) 
        : container;

      if (!el) {
        console.warn('[Skeleton] Container not found:', container);
        return null;
      }

      var opts = Object.assign({}, this.defaults, options);

      // Generate skeleton element based on type
      var skeletonEl = this._generateSkeleton(opts);

      // Store original content
      var originalContent = el.innerHTML;
      var originalDisplay = el.style.display;

      // Create skeleton wrapper
      var wrapper = document.createElement('div');
      wrapper.className = 'funky-skeleton-wrapper';
      wrapper.setAttribute('aria-hidden', 'true');  // Hide from screen readers
      if (typeof skeletonEl === 'string') {
        // Handle custom template or fallback
        wrapper.innerHTML = skeletonEl;
      } else {
        wrapper.appendChild(skeletonEl);
      }

      // Replace content with skeleton
      el.innerHTML = '';
      el.appendChild(wrapper);
      el.classList.add('funky-skeleton-loading');
      el.setAttribute('aria-busy', 'true');  // Indicate loading state

      // Announce loading to screen readers
      if (Funky.Announce) {
        Funky.Announce.polite('Loading content');
      }

      // Store reference
      var controller = {
        element: el,
        wrapper: wrapper,
        originalContent: originalContent,
        originalDisplay: originalDisplay,
        options: opts,
        hide: function() {
          self.hide(el);
        }
      };

      this._active.set(el, controller);

      return controller;
    },

    /**
     * Hide skeleton and restore/show content
     * @param {string|HTMLElement} container - Container selector or element
     * @param {string} newContent - Optional new content to show
     */
    hide: function(container, newContent) {
      var self = this;
      var el = typeof container === 'string' 
        ? document.querySelector(container) 
        : container;

      if (!el) return;

      var controller = this._active.get(el);
      if (!controller) return;

      var wrapper = controller.wrapper;
      var opts = controller.options;

      if (opts.fadeOut && wrapper) {
        wrapper.classList.add('funky-skeleton-fade-out');
        
        setTimeout(function() {
          self._completeHide(el, controller, newContent);
        }, opts.fadeDuration);
      } else {
        this._completeHide(el, controller, newContent);
      }
    },

    /**
     * Complete the hide operation
     * @private
     */
    _completeHide: function(el, controller, newContent) {
      el.classList.remove('funky-skeleton-loading');
      el.removeAttribute('aria-busy');  // Clear loading state

      if (newContent !== undefined) {
        el.innerHTML = newContent;
      } else if (controller.originalContent) {
        el.innerHTML = controller.originalContent;
      }

      // Announce content loaded to screen readers
      if (Funky.Announce) {
        Funky.Announce.polite('Content loaded');
      }

      this._active.delete(el);
    },

    /**
     * Wrap an async operation with skeleton
     * @param {string|HTMLElement} container - Container
     * @param {Function} asyncFn - Async function returning a Promise
     * @param {Object} options - Skeleton options
     * @returns {Promise}
     */
    wrap: function(container, asyncFn, options) {
      var self = this;
      var controller = this.show(container, options);

      return Promise.resolve()
        .then(function() {
          return asyncFn();
        })
        .then(function(result) {
          self.hide(container);
          return result;
        })
        .catch(function(err) {
          self.hide(container);
          throw err;
        });
    },

    /**
     * Initialize declarative skeletons
     * @param {string|HTMLElement} scope - Optional scope container
     */
    init: function(scope) {
      var container = scope 
        ? (typeof scope === 'string' ? document.querySelector(scope) : scope)
        : document;

      if (!container) return;

      var elements = container.querySelectorAll('[data-skeleton]');
      
      elements.forEach(function(el) {
        var type = el.dataset.skeleton;
        var options = {
          type: type,
          rows: parseInt(el.dataset.skeletonRows, 10) || undefined,
          columns: parseInt(el.dataset.skeletonCols, 10) || undefined,
          count: parseInt(el.dataset.skeletonCount, 10) || undefined,
          avatar: el.hasAttribute('data-skeleton-avatar'),
          header: el.dataset.skeletonHeader !== 'false',
          image: el.dataset.skeletonImage !== 'false',
          lines: parseInt(el.dataset.skeletonLines, 10) || undefined
        };

        // Clean undefined values
        Object.keys(options).forEach(function(key) {
          if (options[key] === undefined) delete options[key];
        });

        Skeleton.show(el, options);
      });
    },

    /**
     * Generate skeleton HTML based on type
     * @private
     */
    _generateSkeleton: function(opts) {
      switch (opts.type) {
        case 'table':
          return this._generateTable(opts);
        case 'card':
          return this._generateCards(opts);
        case 'list':
          return this._generateList(opts);
        case 'text':
          return this._generateText(opts);
        case 'avatar':
          return this._generateAvatar(opts);
        case 'custom':
          return opts.template || '';
        default:
          return this._generateText(opts);
      }
    },

    /**
     * Generate table skeleton
     * @private
     */
    _generateTable: function(opts) {
      var D = Funky.Dom;
      var rows = opts.rows || 5;
      var cols = opts.columns || 4;
      
      var table = D.table().class('funky-skeleton-table');

      // Header
      if (opts.header !== false) {
        var thead = D.create('thead');
        var headerRow = D.tr();
        for (var h = 0; h < cols; h++) {
          headerRow.child(D.th().child(D.div().class('funky-skeleton')));
        }
        thead.child(headerRow);
        table.child(thead);
      }

      // Body
      var tbody = D.create('tbody');
      for (var r = 0; r < rows; r++) {
        var row = D.tr();
        for (var c = 0; c < cols; c++) {
          row.child(D.td().child(D.div().class('funky-skeleton')));
        }
        tbody.child(row);
      }
      table.child(tbody);

      return table.el;
    },

    /**
     * Generate card skeleton(s)
     * @private
     */
    _generateCards: function(opts) {
      var D = Funky.Dom;
      var count = opts.count || 3;
      var container = D.div().class('funky-skeleton-cards');

      for (var i = 0; i < count; i++) {
        var card = D.div().class('funky-skeleton-card');
        if (opts.image !== false) {
          card.child(D.div().class('funky-skeleton-card-image funky-skeleton'));
        }
        card.child(
          D.div().class('funky-skeleton-card-body').child(
            D.div().class('funky-skeleton funky-skeleton-card-title'),
            D.div().class('funky-skeleton funky-skeleton-card-text'),
            D.div().class('funky-skeleton funky-skeleton-card-text')
          )
        );
        container.child(card);
      }

      return container.get();
    },

    /**
     * Generate list skeleton
     * @private
     */
    _generateList: function(opts) {
      var D = Funky.Dom;
      var rows = opts.rows || 5;
      var container = D.div().class('funky-skeleton-list');

      for (var i = 0; i < rows; i++) {
        var item = D.div().class('funky-skeleton-list-item');
        if (opts.avatar) {
          item.child(D.div().class('funky-skeleton funky-skeleton-avatar md'));
        }
        item.child(
          D.div().class('funky-skeleton-list-content').child(
            D.div().class('funky-skeleton funky-skeleton-list-title'),
            D.div().class('funky-skeleton funky-skeleton-list-subtitle')
          )
        );
        container.child(item);
      }

      return container.get();
    },

    /**
     * Generate text skeleton
     * @private
     */
    _generateText: function(opts) {
      var D = Funky.Dom;
      var lines = opts.lines || opts.rows || 3;
      var container = D.div().class('funky-skeleton-text-block');
      var widths = ['long', 'medium', 'long', 'short', 'medium'];

      for (var i = 0; i < lines; i++) {
        var width = widths[i % widths.length];
        container.child(D.div().class('funky-skeleton funky-skeleton-text ' + width));
      }

      return container.get();
    },

    /**
     * Generate avatar skeleton
     * @private
     */
    _generateAvatar: function(opts) {
      var D = Funky.Dom;
      var size = opts.size || 'md';
      return D.div().class('funky-skeleton funky-skeleton-avatar ' + size).get();
    },

    /**
     * Check if a container has active skeleton
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
     * Hide all active skeletons
     */
    hideAll: function() {
      var self = this;
      this._active.forEach(function(controller, el) {
        self.hide(el);
      });
    },

    /**
     * Get instance (controller) for a container
     * @param {string|HTMLElement} container - Container selector or element
     * @returns {Object|null} Controller object
     */
    getInstance: function(container) {
      var el = typeof container === 'string'
        ? document.querySelector(container)
        : container;
      return el ? this._active.get(el) || null : null;
    },

    /**
     * Destroy skeleton (alias for hide)
     * @param {string|HTMLElement} container - Container selector or element
     */
    destroy: function(container) {
      this.hide(container);
    },

    /**
     * Destroy all skeletons (alias for hideAll)
     */
    destroyAll: function() {
      this.hideAll();
    }
  };

  // ==========================================================================
  // EXPORT
  // ==========================================================================

  Funky.register('Skeleton', Skeleton);

})(window);
