/**
 * Funky.LiveBinding - Reactive Data Binding Component
 * Automatically updates DOM elements when data changes
 * @module Funky.LiveBinding
 * @version 1.0.4
 */
(function(window) {
  'use strict';

  // Ensure Funky registry exists
  if (!window.Funky || !window.Funky.register) {
    console.error('[Funky.LiveBinding] Registry not found. Load namespace.js first.');
    return;
  }

  var Funky = window.Funky;

  // Guard against double registration
  if (Funky.LiveBinding) {
    return;
  }

  // ============================================================================
  // BINDING CLASS
  // ============================================================================

  /**
   * Binding instance
   * @param {HTMLElement} element - Target element
   * @param {Object} options - Binding configuration
   */
  function Binding(element, options) {
    this.id = 'lb_' + (++Binding._idCounter);
    this.element = element;
    this.options = Object.assign({}, LiveBinding.defaults, options);
    this.source = null;           // Source adapter instance
    this.data = null;             // Current data
    this.loading = true;          // Loading state
    this.error = null;            // Error state
    this.destroyed = false;
    this.paused = false;
    this.debounceTimer = null;
    this.lastUpdate = 0;
    
    // VNode tracking for efficient diffing
    this._previousVNode = null;
    this._appendedVNodes = null;

    // Mark element
    element.setAttribute('data-live-binding-id', this.id);

    this._init();
  }

  Binding._idCounter = 0;

  /**
   * Initialize the binding
   */
  Binding.prototype._init = function() {
    var self = this;
    var opts = this.options;

    // Show loading state
    if (opts.showLoading && !opts.append) {
      this._showLoading();
    }

    // Create source adapter
    this.source = LiveBinding._createAdapter(opts.source, opts, function(data) {
      self._onData(data);
    }, function(error) {
      self._onError(error);
    });

    if (!this.source) {
      console.error('[LiveBinding] Unknown source:', opts.source);
      return;
    }

    // Initial fetch
    this.source.fetch();
  };

  /**
   * Handle incoming data
   */
  Binding.prototype._onData = function(data) {
    if (this.destroyed || this.paused) return;

    var self = this;
    var opts = this.options;

    // Debounce high-frequency updates
    if (opts.debounce > 0) {
      var now = Date.now();
      if (now - this.lastUpdate < opts.debounce) {
        clearTimeout(this.debounceTimer);
        this.debounceTimer = setTimeout(function() {
          self._processData(data);
        }, opts.debounce);
        return;
      }
    }

    this._processData(data);
  };

  /**
   * Process and render data
   */
  Binding.prototype._processData = function(data) {
    var opts = this.options;

    // Hide loading state on first data
    if (this.loading) {
      this._hideLoading();
    }

    // Apply transform
    if (typeof opts.transform === 'function') {
      try {
        data = opts.transform(data);
      } catch (e) {
        console.error('[LiveBinding] Transform error:', e);
        this._onError(e);
        return;
      }
    }

    this.data = data;
    this.loading = false;
    this.error = null;
    this.lastUpdate = Date.now();

    // Render
    this._render(data);

    // Screen reader announcement (if enabled)
    if (opts.announce && Funky.Announce) {
      var message = null;
      if (typeof opts.announceMessage === 'function') {
        message = opts.announceMessage(data);
      } else if (typeof opts.announceMessage === 'string') {
        message = opts.announceMessage;
      } else if (Array.isArray(data)) {
        message = data.length + ' items loaded';
      }
      if (message) {
        Funky.Announce.polite(message);
      }
    }

    // Callback
    if (typeof opts.onUpdate === 'function') {
      opts.onUpdate(data, this);
    }
  };

  /**
   * Render data to element
   */
  Binding.prototype._render = function(data) {
    var opts = this.options;
    var element = this.element;
    var html;

    // Use render function if provided
    if (typeof opts.render === 'function') {
      html = opts.render(data, element);
      if (html !== undefined) {
        this._setContent(html);
      }
      return;
    }

    // Use template
    if (opts.template) {
      html = LiveBinding._renderTemplate(opts.template, data);
    } else if (data !== null && data !== undefined) {
      // Simple value
      html = String(data);
    } else {
      html = opts.fallback || '';
    }

    this._setContent(html);
  };

  /**
   * Set element content - detects VNodes vs strings
   */
  Binding.prototype._setContent = function(content) {
    var element = this.element;

    // Detect content type: VNode vs HTML string
    if (content && content._isVNode) {
      // Virtual DOM path - use diffing
      this._setVNodeContent(content);
    } else {
      // String/HTML path - existing behavior (backward compatible)
      this._setHtmlContent(content);
    }

    // Add updated class briefly for animations
    element.classList.add('live-binding-updated');
    setTimeout(function() {
      element.classList.remove('live-binding-updated');
    }, 300);
  };

  /**
   * Set VNode content with efficient diffing
   */
  Binding.prototype._setVNodeContent = function(vnode) {
    var element = this.element;
    var opts = this.options;

    // Ensure Funky.Dom is available
    if (!Funky.Dom) {
      console.warn('[LiveBinding] Funky.Dom not available, falling back to render');
      element.replaceChildren(this._renderVNodeFallback(vnode));
      return;
    }

    if (opts.append) {
      // Append mode - render and add
      var rendered = Funky.Dom.render(vnode);

      // Respect max items limit
      if (opts.max > 0) {
        while (element.children.length >= opts.max) {
          if (opts.prepend) {
            element.removeChild(element.lastChild);
          } else {
            element.removeChild(element.firstChild);
          }
        }
      }

      if (opts.prepend) {
        element.insertBefore(rendered, element.firstChild);
      } else {
        element.appendChild(rendered);
      }

      // Track appended vnodes for potential future diffing
      this._appendedVNodes = this._appendedVNodes || [];
      this._appendedVNodes.push(vnode);

    } else {
      // Replace mode - use diffing if we have previous vnode
      if (this._previousVNode) {
        var patches = Funky.Dom.diff(this._previousVNode, vnode);
        Funky.Dom.patch(element, patches);
      } else {
        // First render - clear and render fresh
        element.replaceChildren(Funky.Dom.render(vnode));
      }

      // Store for next diff
      this._previousVNode = vnode;
    }
  };

  /**
   * Fallback VNode render if Funky.Dom not loaded
   */
  Binding.prototype._renderVNodeFallback = function(vnode) {
    // Basic fallback - just create element from vnode
    if (vnode.type === 'text') {
      return document.createTextNode(vnode.value || '');
    }
    if (vnode.type === 'html') {
      var wrapper = document.createElement('div');
      wrapper.innerHTML = vnode.value || '';
      var frag = document.createDocumentFragment();
      while (wrapper.firstChild) {
        frag.appendChild(wrapper.firstChild);
      }
      return frag;
    }
    // For element/fragment, need Funky.Dom
    return document.createTextNode('[VNode render error]');
  };

  /**
   * Set HTML string content (original behavior)
   */
  Binding.prototype._setHtmlContent = function(html) {
    var opts = this.options;
    var element = this.element;

    // Clear VNode tracking when switching to HTML mode
    this._previousVNode = null;
    this._appendedVNodes = null;

    if (opts.append) {
      // Append mode
      var wrapper = document.createElement('div');
      wrapper.innerHTML = html;

      // Respect max items
      if (opts.max > 0) {
        while (element.children.length >= opts.max) {
          if (opts.prepend) {
            element.removeChild(element.lastChild);
          } else {
            element.removeChild(element.firstChild);
          }
        }
      }

      while (wrapper.firstChild) {
        if (opts.prepend) {
          element.insertBefore(wrapper.firstChild, element.firstChild);
        } else {
          element.appendChild(wrapper.firstChild);
        }
      }
    } else {
      element.innerHTML = html;
    }
  };

  /**
   * Show loading state
   */
  Binding.prototype._showLoading = function() {
    var opts = this.options;
    var element = this.element;

    if (opts.loadingContent) {
      element.replaceChildren(Funky.Util.toDom(opts.loadingContent));
    } else if (Funky.Skeleton && opts.loadingSkeleton) {
      Funky.Skeleton.show(element, opts.loadingSkeleton);
    } else if (Funky.Spinner) {
      Funky.Spinner.show(element, { size: 'sm' });
    }

    element.classList.add('live-binding-loading');
  };

  /**
   * Hide loading state
   */
  Binding.prototype._hideLoading = function() {
    var element = this.element;

    if (Funky.Skeleton) {
      Funky.Skeleton.hide(element);
    }
    if (Funky.Spinner) {
      Funky.Spinner.hide(element);
    }

    element.classList.remove('live-binding-loading');
  };

  /**
   * Handle error
   */
  Binding.prototype._onError = function(error) {
    var opts = this.options;

    this.error = error;
    this.loading = false;
    this._hideLoading();

    if (opts.errorContent) {
      this.element.replaceChildren(Funky.Util.toDom(opts.errorContent));
    } else if (opts.fallback) {
      this.element.replaceChildren(Funky.Util.toDom(opts.fallback));
    }

    this.element.classList.add('live-binding-error');

    // Announce error to screen readers
    if (Funky.Announce) {
      var message = error && error.message ? error.message : 'Failed to load content';
      Funky.Announce.assertive('Error: ' + message);
    }

    if (typeof opts.onError === 'function') {
      opts.onError(error, this);
    }
  };

  /**
   * Manual refresh
   */
  Binding.prototype.refresh = function() {
    if (this.destroyed) return;
    if (this.source && this.source.fetch) {
      this.source.fetch();
    }
  };

  /**
   * Pause updates
   */
  Binding.prototype.pause = function() {
    this.paused = true;
    if (this.source && this.source.pause) {
      this.source.pause();
    }
  };

  /**
   * Resume updates
   */
  Binding.prototype.resume = function() {
    this.paused = false;
    if (this.source && this.source.resume) {
      this.source.resume();
    }
  };

  /**
   * Destroy binding
   */
  Binding.prototype.destroy = function() {
    if (this.destroyed) return;

    this.destroyed = true;
    this.paused = true;

    // Cleanup source
    if (this.source && this.source.destroy) {
      this.source.destroy();
    }

    // Clear timers
    clearTimeout(this.debounceTimer);
    
    // Clear VNode tracking
    this._previousVNode = null;
    this._appendedVNodes = null;

    // Remove from registry
    LiveBinding._bindings.delete(this.id);

    // Clean element
    this.element.removeAttribute('data-live-binding-id');
    this.element.classList.remove('live-binding-loading', 'live-binding-error', 'live-binding-updated');
    this._hideLoading();
  };

  // ============================================================================
  // LIVE BINDING MODULE
  // ============================================================================

  var LiveBinding = {
    /**
     * Default configuration
     */
    defaults: {
      source: 'cache',            // cache, websocket, event, api
      debounce: 0,                // Debounce ms (0 = disabled)
      template: null,             // Mustache-style template
      transform: null,            // Data transform function
      render: null,               // Custom render function
      append: false,              // Append new data instead of replace
      prepend: false,             // Prepend when appending
      max: 0,                     // Max items when appending (0 = unlimited)
      showLoading: true,          // Show loading state
      loadingContent: null,       // Custom loading HTML
      loadingSkeleton: null,      // Skeleton options
      fallback: '',               // Fallback content
      errorContent: null,         // Error content HTML
      onUpdate: null,             // Update callback
      onError: null,              // Error callback
      announce: false,            // Announce updates to screen readers
      announceMessage: null       // Custom announcement function(data) or string
    },

    /** Active bindings registry */
    _bindings: new Map(),

    /** Source adapters */
    _adapters: {},

    /** Paused state */
    _paused: false,

    /**
     * Create a binding
     * @param {string|HTMLElement} selector - Target element
     * @param {Object} options - Binding configuration
     * @returns {Binding}
     */
    bind: function(selector, options) {
      var element = typeof selector === 'string'
        ? document.querySelector(selector)
        : selector;

      if (!element) {
        console.warn('[LiveBinding] Element not found:', selector);
        return null;
      }

      // Destroy existing binding on this element
      var existingId = element.getAttribute('data-live-binding-id');
      if (existingId && this._bindings.has(existingId)) {
        this._bindings.get(existingId).destroy();
      }

      var binding = new Binding(element, options);
      this._bindings.set(binding.id, binding);

      return binding;
    },

    /**
     * Initialize declarative bindings
     * @param {string|HTMLElement} scope - Container scope
     */
    init: function(scope) {
      var container = scope
        ? (typeof scope === 'string' ? document.querySelector(scope) : scope)
        : document;

      if (!container) return;

      var elements = container.querySelectorAll('[data-live-bind]');
      var self = this;

      elements.forEach(function(el) {
        var bindSpec = el.getAttribute('data-live-bind');
        var options = self._parseDeclarative(el, bindSpec);
        self.bind(el, options);
      });
    },

    /**
     * Parse declarative binding specification
     * @private
     */
    _parseDeclarative: function(element, spec) {
      // Format: "source:param1:param2" e.g. "cache:trade:count" or "websocket:prices:GBPUSD"
      var parts = spec.split(':');
      var source = parts[0];
      var options = { source: source };

      // Parse source-specific parts
      switch (source) {
        case 'cache':
          options.entity = parts[1];
          options.property = parts[2];
          break;
        case 'websocket':
          options.channel = parts[1];
          options.key = parts[2];
          break;
        case 'event':
          options.event = parts.slice(1).join(':');
          break;
        case 'api':
          options.url = parts.slice(1).join(':');
          break;
      }

      // Parse data attributes
      var query = element.getAttribute('data-live-query');
      if (query) {
        try { options.query = JSON.parse(query); } catch(e) {}
      }

      var template = element.getAttribute('data-live-template');
      if (template) options.template = template;

      var interval = element.getAttribute('data-live-interval');
      if (interval) options.interval = parseInt(interval, 10);

      var debounce = element.getAttribute('data-live-debounce');
      if (debounce) options.debounce = parseInt(debounce, 10);

      if (element.hasAttribute('data-live-append')) options.append = true;
      if (element.hasAttribute('data-live-prepend')) {
        options.append = true;
        options.prepend = true;
      }

      var max = element.getAttribute('data-live-max');
      if (max) options.max = parseInt(max, 10);

      var fallback = element.getAttribute('data-live-fallback');
      if (fallback) options.fallback = fallback;

      return options;
    },

    /**
     * Destroy all bindings in a container
     * @param {string|HTMLElement} container
     */
    destroyAll: function(container) {
      var el = typeof container === 'string'
        ? document.querySelector(container)
        : container;

      if (!el) return;

      var self = this;
      this._bindings.forEach(function(binding) {
        if (el.contains(binding.element)) {
          binding.destroy();
        }
      });
    },

    /**
     * Pause all bindings
     */
    pause: function() {
      this._paused = true;
      this._bindings.forEach(function(binding) {
        binding.pause();
      });
    },

    /**
     * Resume all bindings
     */
    resume: function() {
      this._paused = false;
      this._bindings.forEach(function(binding) {
        binding.resume();
      });
    },

    /**
     * Register a source adapter
     * @param {string} name - Adapter name
     * @param {Function} factory - Adapter factory function
     */
    registerAdapter: function(name, factory) {
      this._adapters[name] = factory;
    },

    /**
     * Create a source adapter
     * @private
     */
    _createAdapter: function(source, options, onData, onError) {
      var factory = this._adapters[source];
      if (!factory) return null;
      return factory(options, onData, onError);
    },

    /**
     * Render a mustache-style template (basic - replaced by TemplateEngine)
     * @private
     */
    _renderTemplate: function(template, data) {
      return TemplateEngine.render(template, data);
    }
  };

  // ============================================================================
  // TEMPLATE ENGINE
  // ============================================================================

  var TemplateEngine = {
    /**
     * Compile and render template
     * @param {string} template - Template string
     * @param {*} data - Data to render
     * @returns {string} Rendered HTML
     */
    render: function(template, data) {
      if (typeof data !== 'object' || data === null) {
        // Simple value replacement
        return template.replace(/\{\{\.?\}\}/g, this._escape(String(data)));
      }

      var result = template;

      // Process sections (conditionals and loops) first
      result = this._processSections(result, data);

      // Process inverted sections (if-not)
      result = this._processInvertedSections(result, data);

      // Process partials
      result = this._processPartials(result, data);

      // Process variables with formatters
      result = this._processVariables(result, data);

      return result;
    },

    /**
     * Process sections: {{#key}}...{{/key}}
     * Works as conditional for scalars, loop for arrays
     */
    _processSections: function(template, data) {
      var self = this;
      var regex = /\{\{#(\w+(?:\.\w+)*)\}\}([\s\S]*?)\{\{\/\1\}\}/g;

      return template.replace(regex, function(match, path, content) {
        var value = self._getValue(data, path);

        // Falsy - hide section
        if (!value) {
          return '';
        }

        // Array - iterate
        if (Array.isArray(value)) {
          return value.map(function(item, index) {
            // Add loop context
            var ctx;
            if (typeof item === 'object' && item !== null) {
              ctx = Object.assign({}, item);
            } else {
              ctx = { '.': item };
            }
            ctx['@index'] = index;
            ctx['@first'] = index === 0;
            ctx['@last'] = index === value.length - 1;
            ctx['@odd'] = index % 2 === 1;
            ctx['@even'] = index % 2 === 0;
            return self.render(content, ctx);
          }).join('');
        }

        // Object - use as context
        if (typeof value === 'object') {
          return self.render(content, value);
        }

        // Truthy scalar - render once
        return self.render(content, data);
      });
    },

    /**
     * Process inverted sections: {{^key}}...{{/key}}
     * Renders when value is falsy or empty array
     */
    _processInvertedSections: function(template, data) {
      var self = this;
      var regex = /\{\{\^(\w+(?:\.\w+)*)\}\}([\s\S]*?)\{\{\/\1\}\}/g;

      return template.replace(regex, function(match, path, content) {
        var value = self._getValue(data, path);

        // Show if falsy or empty array
        if (!value || (Array.isArray(value) && value.length === 0)) {
          return self.render(content, data);
        }

        return '';
      });
    },

    /**
     * Process partials: {{>partialName}}
     * Looks up registered partial templates
     */
    _processPartials: function(template, data) {
      var self = this;
      var regex = /\{\{>(\w+)\}\}/g;

      return template.replace(regex, function(match, name) {
        var partial = self._partials[name];
        if (partial) {
          return self.render(partial, data);
        }
        console.warn('[LiveBinding:Template] Partial not found:', name);
        return '';
      });
    },

    /**
     * Process variables: {{key}}, {{key|formatter}}, {{{raw}}}
     */
    _processVariables: function(template, data) {
      var self = this;

      // Unescaped variables: {{{key}}} or {{&key}}
      template = template.replace(/\{\{\{(\w+(?:\.\w+)*(?:\|[^}]+)?)\}\}\}|\{\{&(\w+(?:\.\w+)*(?:\|[^}]+)?)\}\}/g,
        function(match, p1, p2) {
          var path = p1 || p2;
          return String(self._getFormattedValue(data, path));
        }
      );

      // Escaped variables: {{key}} or {{key|formatter:arg1:arg2}}
      // Also matches special loop context: {{.}}, {{@index}}, {{@first}}, etc.
      template = template.replace(/\{\{(\.|\@\w+|\w+(?:\.\w+)*(?:\|[^}]+)?)\}\}/g, function(match, path) {
        // Skip if it looks like a section marker
        if (path.charAt(0) === '#' || path.charAt(0) === '/' || path.charAt(0) === '^' || path.charAt(0) === '>') {
          return match;
        }
        var value = self._getFormattedValue(data, path);
        return self._escape(String(value));
      });

      return template;
    },

    /**
     * Get value with optional formatter
     */
    _getFormattedValue: function(data, path) {
      var parts = path.split('|');
      var valuePath = parts[0];
      var value = this._getValue(data, valuePath);

      // Apply formatters
      for (var i = 1; i < parts.length; i++) {
        var formatterSpec = parts[i].split(':');
        var formatterName = formatterSpec[0];
        var args = formatterSpec.slice(1);

        var formatter = this._formatters[formatterName];
        if (formatter) {
          value = formatter.apply(null, [value].concat(args));
        } else {
          console.warn('[LiveBinding:Template] Formatter not found:', formatterName);
        }
      }

      return value !== undefined && value !== null ? value : '';
    },

    /**
     * Get nested value from object
     */
    _getValue: function(data, path) {
      if (path === '.' || path === 'this') {
        // In loop context, '.' might be stored as a property
        if (data && typeof data === 'object' && data['.'] !== undefined) {
          return data['.'];
        }
        return data;
      }
      // Handle @context variables
      if (path.charAt(0) === '@') {
        return data[path];
      }
      return path.split('.').reduce(function(obj, key) {
        return obj && obj[key] !== undefined ? obj[key] : undefined;
      }, data);
    },

    /**
     * HTML escape
     */
    _escape: function(str) {
      var map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;'
      };
      return String(str).replace(/[&<>"']/g, function(m) { return map[m]; });
    },

    /**
     * Registered partials
     */
    _partials: {},

    /**
     * Register a partial template
     * @param {string} name - Partial name
     * @param {string} template - Partial template
     */
    registerPartial: function(name, template) {
      this._partials[name] = template;
    },

    /**
     * Built-in formatters
     */
    _formatters: {
      // String formatters
      upper: function(v) { return String(v).toUpperCase(); },
      lower: function(v) { return String(v).toLowerCase(); },
      capitalize: function(v) {
        var s = String(v);
        return s.charAt(0).toUpperCase() + s.slice(1);
      },
      trim: function(v) { return String(v).trim(); },
      truncate: function(v, len) {
        var s = String(v);
        var n = parseInt(len, 10) || 50;
        return s.length > n ? s.slice(0, n) + '...' : s;
      },

      // Number formatters
      number: function(v, decimals) {
        var n = parseFloat(v);
        if (isNaN(n)) return v;
        var d = parseInt(decimals, 10);
        return isNaN(d) ? n.toLocaleString() : n.toFixed(d);
      },
      currency: function(v, symbol) {
        var n = parseFloat(v);
        if (isNaN(n)) return v;
        return (symbol || '£') + n.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
      },
      percent: function(v, decimals) {
        var n = parseFloat(v);
        if (isNaN(n)) return v;
        var d = parseInt(decimals, 10) || 0;
        return (n * 100).toFixed(d) + '%';
      },
      round: function(v) {
        return Math.round(parseFloat(v) || 0);
      },

      // Date formatters
      date: function(v, format) {
        var d = new Date(v);
        if (isNaN(d.getTime())) return v;

        // Use Funky.Format if available
        if (Funky.Format && Funky.Format.date) {
          return Funky.Format.date(d, format);
        }

        return d.toLocaleDateString();
      },
      time: function(v) {
        var d = new Date(v);
        if (isNaN(d.getTime())) return v;
        return d.toLocaleTimeString();
      },
      relative: function(v) {
        var d = new Date(v);
        if (isNaN(d.getTime())) return v;
        var now = Date.now();
        var diff = now - d.getTime();
        var secs = Math.floor(diff / 1000);
        if (secs < 60) return 'just now';
        if (secs < 3600) return Math.floor(secs / 60) + 'm ago';
        if (secs < 86400) return Math.floor(secs / 3600) + 'h ago';
        return Math.floor(secs / 86400) + 'd ago';
      },

      // Utility formatters
      json: function(v) {
        try { return JSON.stringify(v); } catch(e) { return String(v); }
      },
      default: function(v, fallback) {
        return (v !== null && v !== undefined && v !== '') ? v : fallback;
      },
      pluralize: function(v, singular, plural) {
        var n = parseFloat(v);
        return n === 1 ? singular : (plural || singular + 's');
      },
      join: function(v, sep) {
        return Array.isArray(v) ? v.join(sep || ', ') : v;
      },

      // Conditional formatters
      ifTruthy: function(v, yes, no) {
        return v ? (yes || v) : (no || '');
      },
      ifEquals: function(v, compare, yes, no) {
        return String(v) === String(compare) ? (yes || v) : (no || '');
      }
    },

    /**
     * Register a custom formatter
     * @param {string} name - Formatter name
     * @param {Function} fn - Formatter function
     */
    registerFormatter: function(name, fn) {
      if (typeof fn === 'function') {
        this._formatters[name] = fn;
      }
    },

    /**
     * Compile template to function (optimization)
     * @param {string} template - Template string
     * @returns {Function} Compiled template function
     */
    compile: function(template) {
      var self = this;
      return function(data) {
        return self.render(template, data);
      };
    }
  };

  // Expose template engine on LiveBinding
  LiveBinding.Template = TemplateEngine;

  // ============================================================================
  // SOURCE ADAPTERS
  // ============================================================================

  // ---------------------------------------------------------------------------
  // CACHE ADAPTER
  // Binds to Funky.Cache - updates when cache values change
  // ---------------------------------------------------------------------------
  LiveBinding.registerAdapter('cache', function(options, onData, onError) {
    var entity = options.entity || options.key;
    var property = options.property;
    var interval = options.interval;
    var listener = null;
    var pollTimer = null;
    var destroyed = false;

    function getValue() {
      if (!Funky.Cache) {
        console.warn('[LiveBinding:Cache] Funky.Cache not available');
        return null;
      }

      var store = Funky.Cache.get(entity);
      if (store === undefined || store === null) {
        return null;
      }

      if (property) {
        return store[property];
      }

      return store;
    }

    function handleUpdate() {
      if (destroyed) return;
      try {
        var data = getValue();
        onData(data);
      } catch (e) {
        onError(e);
      }
    }

    // Subscribe to cache events
    if (Funky.Events) {
      listener = function(data) {
        if (data.key === entity) {
          handleUpdate();
        }
      };
      Funky.PubSub.on('funky:cache:set', listener);
      Funky.PubSub.on('funky:cache:delete', listener);
    }

    // Optional polling for caches that don't emit events
    if (interval && interval > 0) {
      pollTimer = setInterval(handleUpdate, interval);
    }

    return {
      fetch: handleUpdate,
      pause: function() {
        if (pollTimer) {
          clearInterval(pollTimer);
          pollTimer = null;
        }
      },
      resume: function() {
        if (interval && interval > 0 && !pollTimer) {
          pollTimer = setInterval(handleUpdate, interval);
        }
      },
      destroy: function() {
        destroyed = true;
        if (listener && Funky.PubSub) {
          Funky.PubSub.off('funky:cache:set', listener);
          Funky.PubSub.off('funky:cache:invalidate', listener);
        }
        if (pollTimer) {
          clearInterval(pollTimer);
        }
      }
    };
  });

  // ---------------------------------------------------------------------------
  // WEBSOCKET ADAPTER
  // Binds to Funky.WebSocket channels - real-time streaming
  // ---------------------------------------------------------------------------
  LiveBinding.registerAdapter('websocket', function(options, onData, onError) {
    var channel = options.channel;
    var key = options.key;
    var bufferMs = options.buffer || 0;
    var listener = null;
    var buffer = [];
    var bufferTimer = null;
    var destroyed = false;
    var lastMessage = null;

    if (!Funky.WebSocket) {
      console.warn('[LiveBinding:WebSocket] Funky.WebSocket not available');
      return null;
    }

    if (!channel) {
      console.error('[LiveBinding:WebSocket] Channel required');
      return null;
    }

    function processMessage(data) {
      // Filter by key if specified
      if (key && data && typeof data === 'object') {
        if (data.key !== undefined && data.key !== key) {
          return;
        }
        if (data[key] !== undefined) {
          data = data[key];
        }
      }

      lastMessage = data;

      if (bufferMs > 0) {
        buffer.push(data);
        if (!bufferTimer) {
          bufferTimer = setTimeout(function() {
            if (!destroyed) {
              onData(options.bufferMode === 'all' ? buffer : buffer[buffer.length - 1]);
              buffer = [];
            }
            bufferTimer = null;
          }, bufferMs);
        }
      } else {
        onData(data);
      }
    }

    function handleMessage(event) {
      if (destroyed) return;
      try {
        var data = event.data || event;
        processMessage(data);
      } catch (e) {
        onError(e);
      }
    }

    // Subscribe to channel
    listener = handleMessage;
    Funky.WebSocket.subscribe(channel, listener);

    return {
      fetch: function() {
        if (lastMessage !== null) {
          onData(lastMessage);
        }
      },
      pause: function() {
        destroyed = true;
      },
      resume: function() {
        destroyed = false;
      },
      destroy: function() {
        destroyed = true;
        if (listener) {
          Funky.WebSocket.unsubscribe(channel, listener);
        }
        if (bufferTimer) {
          clearTimeout(bufferTimer);
        }
      }
    };
  });

  // ---------------------------------------------------------------------------
  // EVENT ADAPTER
  // Binds to Funky.Events - custom event stream
  // ---------------------------------------------------------------------------
  LiveBinding.registerAdapter('event', function(options, onData, onError) {
    var eventName = options.event;
    var listener = null;
    var lastData = options.initial !== undefined ? options.initial : null;
    var destroyed = false;

    if (!Funky.Events) {
      console.warn('[LiveBinding:Event] Funky.Events not available');
      return null;
    }

    if (!eventName) {
      console.error('[LiveBinding:Event] Event name required');
      return null;
    }

    function handleEvent(data) {
      if (destroyed) return;
      try {
        lastData = data;
        onData(data);
      } catch (e) {
        onError(e);
      }
    }

    // Subscribe to event
    listener = handleEvent;
    Funky.PubSub.on(eventName, listener);

    return {
      fetch: function() {
        if (lastData !== null) {
          onData(lastData);
        }
      },
      emit: function(data) {
        Funky.PubSub.emit(eventName, data);
      },
      pause: function() {
        destroyed = true;
      },
      resume: function() {
        destroyed = false;
      },
      destroy: function() {
        destroyed = true;
        if (listener) {
          Funky.PubSub.off(eventName, listener);
        }
      }
    };
  });

  // ---------------------------------------------------------------------------
  // API ADAPTER
  // Binds to REST API with polling
  // ---------------------------------------------------------------------------
  LiveBinding.registerAdapter('api', function(options, onData, onError) {
    var url = options.url;
    var method = options.method || 'GET';
    var interval = options.interval || 0;
    var headers = options.headers || {};
    var body = options.body;
    var pollTimer = null;
    var destroyed = false;
    var abortController = null;
    var lastData = null;
    var retryCount = 0;
    var maxRetries = options.maxRetries || 3;
    var retryDelay = options.retryDelay || 1000;

    if (!url) {
      console.error('[LiveBinding:API] URL required');
      return null;
    }

    function fetchData() {
      if (destroyed) return;

      // Abort previous request
      if (abortController) {
        abortController.abort();
      }
      abortController = new AbortController();

      var fetchOptions = {
        method: method,
        headers: Object.assign({
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }, headers),
        signal: abortController.signal
      };

      if (body && method !== 'GET') {
        fetchOptions.body = typeof body === 'string' ? body : JSON.stringify(body);
      }

      // Build URL with query params
      var fetchUrl = url;
      if (options.query && method === 'GET') {
        var params = new URLSearchParams(options.query);
        fetchUrl += (url.includes('?') ? '&' : '?') + params.toString();
      }

      fetch(fetchUrl, fetchOptions)
        .then(function(response) {
          if (!response.ok) {
            throw new Error('HTTP ' + response.status);
          }
          return response.json();
        })
        .then(function(data) {
          if (destroyed) return;
          retryCount = 0;
          lastData = data;
          onData(data);
        })
        .catch(function(error) {
          if (destroyed || error.name === 'AbortError') return;

          // Retry logic
          if (retryCount < maxRetries) {
            retryCount++;
            setTimeout(fetchData, retryDelay * retryCount);
          } else {
            onError(error);
          }
        });
    }

    function startPolling() {
      if (interval > 0 && !pollTimer) {
        pollTimer = setInterval(fetchData, interval);
      }
    }

    function stopPolling() {
      if (pollTimer) {
        clearInterval(pollTimer);
        pollTimer = null;
      }
    }

    startPolling();

    return {
      fetch: fetchData,
      pause: function() {
        stopPolling();
      },
      resume: function() {
        startPolling();
      },
      destroy: function() {
        destroyed = true;
        stopPolling();
        if (abortController) {
          abortController.abort();
        }
      },
      lastData: function() {
        return lastData;
      }
    };
  });

  // ---------------------------------------------------------------------------
  // COMPUTED ADAPTER
  // Combines multiple sources with computed value
  // ---------------------------------------------------------------------------
  LiveBinding.registerAdapter('computed', function(options, onData, onError) {
    var sources = options.sources || [];
    var compute = options.compute;
    var values = {};
    var adapters = [];
    var destroyed = false;

    if (!compute || typeof compute !== 'function') {
      console.error('[LiveBinding:Computed] Compute function required');
      return null;
    }

    function updateComputed() {
      if (destroyed) return;
      try {
        var result = compute(values);
        onData(result);
      } catch (e) {
        onError(e);
      }
    }

    // Create adapters for each source
    sources.forEach(function(sourceConfig, index) {
      var key = sourceConfig.as || ('source' + index);
      var adapter = LiveBinding._createAdapter(
        sourceConfig.source,
        sourceConfig,
        function(data) {
          values[key] = data;
          updateComputed();
        },
        onError
      );
      if (adapter) {
        adapters.push(adapter);
      }
    });

    return {
      fetch: function() {
        adapters.forEach(function(a) { a.fetch(); });
      },
      pause: function() {
        adapters.forEach(function(a) { if (a.pause) a.pause(); });
      },
      resume: function() {
        adapters.forEach(function(a) { if (a.resume) a.resume(); });
      },
      destroy: function() {
        destroyed = true;
        adapters.forEach(function(a) { if (a.destroy) a.destroy(); });
        adapters = [];
      }
    };
  });

  // ============================================================================
  // COMPONENT BINDING
  // ============================================================================

  /**
   * Known component registries to check for instances
   * Components must expose _instances object keyed by element ID
   */
  var COMPONENT_REGISTRIES = [
    // Core
    'ActionBar',
    'Modal',
    'Tabs',
    'Tooltip',
    'Popover',
    
    // Components - Data Display
    'DataTables',
    'Charts',
    'StatsBar',
    'Diff',
    'AuditViewer',
    'Highlight',
    
    // Components - Navigation & Layout
    'Sidenav',
    'SidenavPanel',
    'SlidePanel',
    'Stepper',
    'Tabbed',
    'Breadcrumb',
    'Wizard',
    'ContextMenu',
    
    // Components - Data Management
    'Kanban',
    'TreeView',
    'VirtualisedList',
    'FileManager',
    'AdvancedFilter',
    'FilterToolbar',
    'BulkActions',
    'ColumnProfiles',
    
    // Components - Forms & Modals
    'FormModal',
    'ViewModal',
    'Import',
    'TradeWizard',
    
    // Components - Feedback
    'Toast',
    'Spinner',
    'Skeleton',
    'EmptyState',
    'WipOverlay',
    
    // Components - Media
    'Audio',
    'Video',
    'Slider',
    'Typewriter',
    
    // Components - Utilities
    'Clipboard',
    'Preferences',
    'StickyHeader',
    'Truncate',
    'Wysimark'
  ];

  /**
   * Get component instance from element
   * Checks various Funky component registries
   * @param {HTMLElement} element
   * @returns {Object|null} Component instance
   */
  function getComponentInstance(element) {
    var id = element.id;
    if (!id) return null;

    // Check all known component registries
    for (var i = 0; i < COMPONENT_REGISTRIES.length; i++) {
      var registryName = COMPONENT_REGISTRIES[i];
      var registry = Funky[registryName];
      if (registry && registry._instances && registry._instances[id]) {
        return registry._instances[id];
      }
    }

    // Fallback: check data attribute for instance reference
    var instanceRef = element.getAttribute('data-funky-instance');
    if (instanceRef && window[instanceRef]) {
      return window[instanceRef];
    }

    return null;
  }

  /**
   * Component adapters registry
   */
  var ComponentAdapters = {};

  // ---------------------------------------------------------------------------
  // GENERIC BINDABLE ADAPTER
  // Works with any component implementing setData()
  // ---------------------------------------------------------------------------
  ComponentAdapters.generic = {
    supports: function(element) {
      var instance = getComponentInstance(element);
      return instance && typeof instance.setData === 'function';
    },

    bind: function(element, options) {
      var instance = getComponentInstance(element);

      return {
        update: function(data) {
          if (instance.setData) {
            instance.setData(data);
          }
        },

        append: function(data) {
          if (instance.addData) {
            instance.addData(data);
          } else if (instance.setData && instance.getData) {
            // Fallback: get + concat + set
            var existing = instance.getData() || [];
            var newData = Array.isArray(data) ? data : [data];
            instance.setData(existing.concat(newData));
          }
        },

        remove: function(keys) {
          if (instance.removeData) {
            instance.removeData(keys);
          }
        },

        clear: function() {
          if (instance.clearData) {
            instance.clearData();
          } else if (instance.setData) {
            instance.setData(Array.isArray(instance.getData && instance.getData()) ? [] : null);
          }
        },

        getData: function() {
          return instance.getData ? instance.getData() : null;
        },

        getInstance: function() {
          return instance;
        },

        destroy: function() {
          // Nothing to clean up for generic adapter
        }
      };
    }
  };

  // ---------------------------------------------------------------------------
  // DATATABLE SMART UPDATE ADAPTER
  // Enhanced adapter with diff-based row updates
  // ---------------------------------------------------------------------------
  ComponentAdapters['datatable-smart'] = {
    supports: function(element) {
      return element.tagName === 'TABLE' && element.id &&
             Funky.DataTables && Funky.DataTables._instances[element.id];
    },

    bind: function(element, options) {
      var instance = Funky.DataTables._instances[element.id];
      var keyField = options.keyField || 'id';
      var currentData = [];

      return {
        update: function(data) {
          var rows = Array.isArray(data) ? data : (data.data || data.rows || []);

          if (options.smartUpdate && currentData.length > 0) {
            // Calculate diff
            var existingMap = {};
            currentData.forEach(function(row) {
              if (row[keyField] !== undefined) {
                existingMap[row[keyField]] = row;
              }
            });

            var toAdd = [];
            var toUpdate = [];
            var seenKeys = new Set();

            rows.forEach(function(row) {
              var key = row[keyField];
              seenKeys.add(key);
              if (existingMap[key]) {
                if (JSON.stringify(existingMap[key]) !== JSON.stringify(row)) {
                  toUpdate.push(row);
                }
              } else {
                toAdd.push(row);
              }
            });

            var toRemove = currentData.filter(function(row) {
              return !seenKeys.has(row[keyField]);
            }).map(function(row) {
              return row[keyField];
            });

            // Apply incremental updates if methods available
            var needsFullRefresh = false;

            if (toUpdate.length > 0) {
              if (instance.updateRows) {
                instance.updateRows(toUpdate);
              } else {
                needsFullRefresh = true;
              }
            }

            if (toRemove.length > 0) {
              if (instance.removeData) {
                instance.removeData(toRemove);
              } else {
                needsFullRefresh = true;
              }
            }

            if (toAdd.length > 0) {
              if (instance.addData) {
                instance.addData(toAdd);
              } else {
                needsFullRefresh = true;
              }
            }

            // Fallback to full refresh
            if (needsFullRefresh) {
              instance.setData(rows);
            }
          } else {
            instance.setData(rows);
          }

          currentData = rows;
        },

        append: function(data) {
          var rows = Array.isArray(data) ? data : [data];
          if (instance.addData) {
            instance.addData(rows);
          } else {
            instance.setData(currentData.concat(rows));
          }
          currentData = currentData.concat(rows);
        },

        getData: function() {
          return currentData;
        },

        getInstance: function() {
          return instance;
        },

        destroy: function() {
          currentData = [];
        }
      };
    }
  };

  // ---------------------------------------------------------------------------
  // FORM TWO-WAY ADAPTER
  // Two-way form adapter with input sync
  // ---------------------------------------------------------------------------
  ComponentAdapters['form-twoway'] = {
    supports: function(element) {
      return element.tagName === 'FORM' || element.classList.contains('funky-form');
    },

    bind: function(element, options) {
      var form = element.tagName === 'FORM' ? element : element.querySelector('form') || element;
      var listeners = [];

      // Set up two-way sync
      if (options.twoWay && options.onInput) {
        var handler = function(e) {
          var target = e.target;
          var name = target.name || target.id;
          if (!name) return;

          var value;
          if (target.type === 'checkbox') {
            value = target.checked;
          } else if (target.type === 'radio') {
            value = target.checked ? target.value : null;
          } else if (target.tagName === 'SELECT' && target.multiple) {
            value = Array.from(target.selectedOptions).map(function(o) { return o.value; });
          } else {
            value = target.value;
          }

          options.onInput(name, value, target);
        };

        form.addEventListener('input', handler);
        form.addEventListener('change', handler);
        listeners.push(['input', handler], ['change', handler]);
      }

      return {
        update: function(data) {
          if (!data || typeof data !== 'object') return;

          Object.keys(data).forEach(function(key) {
            var value = data[key];
            var field = form.elements[key] ||
                        form.querySelector('[name="' + key + '"]') ||
                        form.querySelector('#' + key);

            if (!field) return;

            if (field.type === 'checkbox') {
              field.checked = Boolean(value);
            } else if (field.type === 'radio') {
              var radios = form.querySelectorAll('[name="' + key + '"]');
              radios.forEach(function(r) {
                r.checked = (r.value === String(value));
              });
            } else if (field.tagName === 'SELECT' && field.multiple && Array.isArray(value)) {
              Array.from(field.options).forEach(function(opt) {
                opt.selected = value.includes(opt.value);
              });
            } else {
              field.value = value !== null && value !== undefined ? value : '';
            }
          });
        },

        getData: function() {
          var data = {};
          var elements = form.elements;

          for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            var name = el.name || el.id;
            if (!name) continue;

            if (el.type === 'checkbox') {
              data[name] = el.checked;
            } else if (el.type === 'radio') {
              if (el.checked) data[name] = el.value;
            } else if (el.tagName === 'SELECT' && el.multiple) {
              data[name] = Array.from(el.selectedOptions).map(function(o) { return o.value; });
            } else {
              data[name] = el.value;
            }
          }

          return data;
        },

        clear: function() {
          form.reset();
        },

        destroy: function() {
          listeners.forEach(function(l) {
            form.removeEventListener(l[0], l[1]);
          });
          listeners = [];
        }
      };
    }
  };

  /**
   * Bind a component to a data source
   * @param {string|HTMLElement} selector - Component or selector
   * @param {Object} options - Binding options
   * @returns {Object} Component binding instance
   */
  LiveBinding.bindComponent = function(selector, options) {
    var element = typeof selector === 'string'
      ? document.querySelector(selector)
      : selector;

    if (!element) {
      console.warn('[LiveBinding] Component not found:', selector);
      return null;
    }

    options = options || {};

    // Try specialised adapters first, then generic
    var adapter = null;
    var adapterName = options.adapter || null;

    if (adapterName && ComponentAdapters[adapterName]) {
      adapter = ComponentAdapters[adapterName];
    } else {
      // Auto-detect: prefer specialised, fallback to generic
      for (var type in ComponentAdapters) {
        if (type !== 'generic' && ComponentAdapters[type].supports(element)) {
          adapter = ComponentAdapters[type];
          adapterName = type;
          break;
        }
      }
      // Fallback to generic
      if (!adapter && ComponentAdapters.generic.supports(element)) {
        adapter = ComponentAdapters.generic;
        adapterName = 'generic';
      }
    }

    if (!adapter) {
      console.warn('[LiveBinding] No adapter found for:', selector);
      return null;
    }

    // Create component adapter
    var componentAdapter = adapter.bind(element, options);

    // Create source binding
    var binding = this.bind(element, Object.assign({}, options, {
      showLoading: options.showLoading !== undefined ? options.showLoading : false,
      render: function(data) {
        if (options.append) {
          if (componentAdapter.append) {
            componentAdapter.append(data);
          } else {
            componentAdapter.update(data);
          }
        } else {
          componentAdapter.update(data);
        }
        // Return undefined to prevent element innerHTML update
      }
    }));

    if (!binding) return null;

    // Extend binding with component methods
    var origDestroy = binding.destroy.bind(binding);

    Object.assign(binding, {
      component: componentAdapter,
      adapterName: adapterName,

      destroy: function() {
        if (componentAdapter.destroy) {
          componentAdapter.destroy();
        }
        origDestroy();
      }
    });

    return binding;
  };

  /**
   * Register a custom component adapter
   * @param {string} name - Adapter name
   * @param {Object} adapter - Adapter with supports() and bind() methods
   */
  LiveBinding.registerComponent = function(name, adapter) {
    if (adapter && typeof adapter.supports === 'function' && typeof adapter.bind === 'function') {
      ComponentAdapters[name] = adapter;
    }
  };

  // Expose helpers
  LiveBinding.getComponentInstance = getComponentInstance;
  LiveBinding._componentAdapters = ComponentAdapters;
  LiveBinding._componentRegistries = COMPONENT_REGISTRIES;

  /**
   * Register a component registry for LiveBinding to check
   * @param {string} registryName - The name of the Funky component registry (e.g., 'MyComponent')
   */
  LiveBinding.registerRegistry = function(registryName) {
    if (registryName && COMPONENT_REGISTRIES.indexOf(registryName) === -1) {
      COMPONENT_REGISTRIES.push(registryName);
    }
  };

  /**
   * Register multiple component registries
   * @param {Array<string>} registries - Array of registry names
   */
  LiveBinding.registerRegistries = function(registries) {
    if (Array.isArray(registries)) {
      registries.forEach(function(name) {
        LiveBinding.registerRegistry(name);
      });
    }
  };

  // ============================================================================
  // SPA INTEGRATION
  // ============================================================================

  // Auto-cleanup on page navigation
  if (Funky.PubSub) {
    Funky.PubSub.on('funky:spa:before-navigate', function() {
      LiveBinding.destroyAll(document.getElementById('content') || document.body);
    });
  }

  // Pause when page hidden
  var _visibilityListenerAdded = false;
  var _visibilityHandler = function() {
    if (document.hidden) {
      LiveBinding.pause();
    } else {
      LiveBinding.resume();
    }
  };
  document.addEventListener('visibilitychange', _visibilityHandler);
  _visibilityListenerAdded = true;

  /**
   * Destroy LiveBinding and remove all listeners
   * Call this to fully clean up the module
   */
  LiveBinding.destroy = function() {
    // Remove visibility listener
    if (_visibilityListenerAdded) {
      document.removeEventListener('visibilitychange', _visibilityHandler);
      _visibilityListenerAdded = false;
    }
    // Destroy all bindings
    LiveBinding.destroyAll();
  };

  // ============================================================================
  // EXPORT
  // ============================================================================

  Funky.register('LiveBinding', LiveBinding);

})(window);
