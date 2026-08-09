/**
 * Funky.EmptyState - Empty State Placeholder Component
 * Theme-aware, density-aware empty state placeholders with presets
 * @module Funky.EmptyState
 * @version 1.0.4
 */
(function(window) {
  'use strict';

  // Ensure Funky registry exists
  if (!window.Funky || !window.Funky.register) {
    console.error('[Funky.EmptyState] Registry not found. Load namespace.js first.');
    return;
  }

  var Funky = window.Funky;

  // Guard against double registration
  if (Funky.EmptyState) {
    return;
  }

  // ==========================================================================
  // PRESET DEFINITIONS
  // ==========================================================================

  var PRESETS = {
    'no-results': {
      icon: 'fa-search',
      title: 'No results found',
      message: 'Try different search terms or adjust your filters'
    },
    'no-data': {
      icon: 'fa-inbox',
      title: 'No data yet',
      message: 'Data will appear here once available'
    },
    'error': {
      icon: 'fa-exclamation-triangle',
      title: 'Something went wrong',
      message: 'Please try again later',
      variant: 'danger'
    },
    'offline': {
      icon: 'fa-wifi-slash',
      title: "You're offline",
      message: 'Check your internet connection',
      variant: 'warning'
    },
    'empty-list': {
      icon: 'fa-list',
      title: 'Nothing here yet',
      message: 'Add items to get started'
    },
    'empty-table': {
      icon: 'fa-table',
      title: 'No records',
      message: 'Create your first record to get started'
    },
    'access-denied': {
      icon: 'fa-lock',
      title: 'Access denied',
      message: "You don't have permission to view this content",
      variant: 'danger'
    },
    'coming-soon': {
      icon: 'fa-rocket',
      title: 'Coming soon',
      message: 'This feature is under development',
      variant: 'info'
    }
  };

  // ==========================================================================
  // DEFAULTS
  // ==========================================================================

  var DEFAULTS = {
    type: null,
    icon: 'fa-inbox',
    title: 'No data',
    message: '',
    action: null,
    secondaryAction: null,
    size: 'md',
    variant: null,
    animate: true,
    className: ''
  };

  // ==========================================================================
  // INTERNAL TRACKING
  // ==========================================================================

  // Track active empty states by container element
  var activeStates = new WeakMap();

  // ==========================================================================
  // HELPER FUNCTIONS
  // ==========================================================================

  /**
   * Get element from selector or element
   */
  function getElement(selectorOrElement) {
    if (typeof selectorOrElement === 'string') {
      return document.querySelector(selectorOrElement);
    }
    return selectorOrElement;
  }

  /**
   * Check if icon is a URL (image)
   */
  function isImageUrl(icon) {
    return icon && (
      icon.startsWith('http://') ||
      icon.startsWith('https://') ||
      icon.startsWith('/') ||
      icon.startsWith('data:')
    );
  }

  /**
   * Generate unique ID
   */
  function generateId() {
    return 'empty-state-' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * Escape HTML to prevent XSS
   */
  function escapeHtml(str) {
    if (!str) return '';
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  /**
   * Merge options with defaults and preset
   */
  function mergeOptions(options) {
    var merged = Object.assign({}, DEFAULTS, options);

    // Apply preset if specified
    if (merged.type && PRESETS[merged.type]) {
      var preset = PRESETS[merged.type];
      // Preset provides base, options override
      merged = Object.assign({}, DEFAULTS, preset, options);
    }

    return merged;
  }

  // ==========================================================================
  // HTML GENERATION
  // ==========================================================================

  /**
   * Generate empty state HTML
   */
  function generateHtml(options) {
    var D = Funky.Dom;
    var opts = mergeOptions(options);
    var id = generateId();

    var classes = ['funky-empty-state'];
    classes.push('funky-empty-state-' + opts.size);

    if (opts.variant) {
      classes.push('funky-empty-state-variant-' + opts.variant);
    }

    if (opts.animate) {
      classes.push('animate-in');
    }

    if (opts.className) {
      classes.push(opts.className);
    }

    var container = D.div().attr('id', id).class(classes.join(' ')).attr('role', 'status');

    // Icon (decorative - hidden from screen readers)
    if (opts.icon) {
      var iconDiv = D.div().class('funky-empty-state-icon').aria('hidden', 'true');
      if (isImageUrl(opts.icon)) {
        iconDiv.child(D.img().attr('src', opts.icon).attr('alt', ''));
      } else {
        iconDiv.child(D.icon('fas ' + opts.icon));
      }
      container.child(iconDiv);
    }

    // Title
    if (opts.title) {
      container.child(D.h4().class('funky-empty-state-title').text(opts.title));
    }

    // Message
    if (opts.message) {
      container.child(D.p().class('funky-empty-state-message').text(opts.message));
    }

    // Actions
    if (opts.action || opts.secondaryAction) {
      var actionsDiv = D.div().class('funky-empty-state-actions');

      // Primary action button
      if (opts.action) {
        var btnClass = 'btn btn-' + (opts.action.variant || 'primary') + ' funky-empty-state-action';
        var btn = D.button().attr('type', 'button').class(btnClass);
        if (opts.action.icon) {
          btn.child(D.icon('fas ' + opts.action.icon + ' me-1').aria('hidden', 'true'));
        }
        btn.child(D.text(opts.action.text));
        actionsDiv.child(btn);
      }

      // Secondary action link
      if (opts.secondaryAction) {
        if (opts.secondaryAction.href) {
          actionsDiv.child(
            D.a().attr('href', opts.secondaryAction.href).class('funky-empty-state-secondary').text(opts.secondaryAction.text)
          );
        } else {
          actionsDiv.child(
            D.button().attr('type', 'button').class('funky-empty-state-secondary').text(opts.secondaryAction.text)
          );
        }
      }

      container.child(actionsDiv);
    }

    return { element: container.get(), id: id, options: opts };
  }

  // ==========================================================================
  // PUBLIC API
  // ==========================================================================

  var EmptyState = {
    _instances: {}  // Instance registry by container ID for LiveBinding
  };

  /**
   * Show empty state in container
   * @param {string|Element} container - Container selector or element
   * @param {Object} options - Configuration options
   * @returns {Object} Instance with id and destroy method
   */
  EmptyState.show = function(container, options) {
    var el = getElement(container);
    if (!el) {
      console.warn('EmptyState.show: Container not found:', container);
      return null;
    }

    // Hide existing if present
    EmptyState.hide(container);

    // Generate and insert
    var result = generateHtml(options || {});
    el.innerHTML = '';
    el.appendChild(result.element);

    // Store reference
    var instance = {
      id: result.id,
      element: el.querySelector('#' + result.id),
      options: result.options,
      destroy: function() {
        EmptyState.hide(container);
      }
    };

    activeStates.set(el, instance);

    // Register in instance registry for LiveBinding
    if (el.id) {
      EmptyState._instances[el.id] = instance;
    }

    // Bind action handlers
    if (result.options.action && result.options.action.onClick) {
      var actionBtn = el.querySelector('.funky-empty-state-action');
      if (actionBtn) {
        actionBtn.addEventListener('click', result.options.action.onClick);
      }
    }

    if (result.options.secondaryAction && result.options.secondaryAction.onClick) {
      var secondaryBtn = el.querySelector('.funky-empty-state-secondary');
      if (secondaryBtn) {
        secondaryBtn.addEventListener('click', result.options.secondaryAction.onClick);
      }
    }

    return instance;
  };

  /**
   * Hide empty state from container
   * @param {string|Element} container - Container selector or element
   */
  EmptyState.hide = function(container) {
    var el = getElement(container);
    if (!el) return;

    var instance = activeStates.get(el);
    if (instance && instance.element) {
      instance.element.remove();
    }

    // Clean up instance registry
    if (el.id && EmptyState._instances[el.id]) {
      delete EmptyState._instances[el.id];
    }

    activeStates.delete(el);
  };

  /**
   * Check if empty state is showing
   * @param {string|Element} container - Container selector or element
   * @returns {boolean}
   */
  EmptyState.isShowing = function(container) {
    var el = getElement(container);
    if (!el) return false;
    return activeStates.has(el);
  };

  /**
   * Get HTML string for empty state (manual insertion)
   * @param {Object} options - Configuration options
   * @returns {string} HTML string
   */
  EmptyState.html = function(options) {
    var result = generateHtml(options || {});
    // Convert element to HTML string
    return result.element ? result.element.outerHTML : '';
  };

  /**
   * Register a custom preset
   * @param {string} name - Preset name
   * @param {Object} config - Preset configuration
   */
  EmptyState.registerPreset = function(name, config) {
    if (!name || typeof name !== 'string') {
      console.warn('EmptyState.registerPreset: Invalid preset name');
      return;
    }
    PRESETS[name] = config;
  };

  /**
   * Get all available presets
   * @returns {Object} Preset definitions
   */
  EmptyState.getPresets = function() {
    return Object.assign({}, PRESETS);
  };

  /**
   * Get preset names
   * @returns {Array} Array of preset names
   */
  EmptyState.getPresetNames = function() {
    return Object.keys(PRESETS);
  };

  // ==========================================================================
  // BINDABLE INTERFACE
  // ==========================================================================

  /**
   * Set empty state data (Bindable Interface)
   * Updates the empty state content in a specific container
   * @param {string} containerId - Container element ID
   * @param {Object} data - Empty state configuration
   * @param {string} data.type - Preset type (e.g., 'no-results', 'error')
   * @param {string} data.icon - Icon class or image URL
   * @param {string} data.title - Title text
   * @param {string} data.message - Message text
   * @param {Object} data.action - Primary action button config
   * @param {Object} data.secondaryAction - Secondary action config
   * @param {string} data.size - Size: 'sm', 'md', 'lg'
   * @param {string} data.variant - Variant: 'danger', 'warning', 'info'
   * @returns {Object|null} Instance or null if container not found
   */
  EmptyState.setData = function(containerId, data) {
    var container = document.getElementById(containerId);
    if (!container) {
      console.warn('[Funky.EmptyState] setData: Container not found:', containerId);
      return null;
    }
    
    // Show empty state with new data (this replaces any existing)
    return EmptyState.show(container, data);
  };

  /**
   * Get current empty state data (Bindable Interface)
   * @param {string} containerId - Container element ID
   * @returns {Object|null} Current options or null if not showing
   */
  EmptyState.getData = function(containerId) {
    var instance = EmptyState._instances[containerId];
    if (instance) {
      return instance.options;
    }
    return null;
  };

  // ==========================================================================
  // EXPORT
  // ==========================================================================

  // Register with Funky securely
  Funky.register('EmptyState', EmptyState);

})(window);
