/**
 * Funky.ActionRegistry
 * 
 * Factory for creating action registry instances.
 * Uses Funky.Registry internally for storage.
 * Used by QuickNav, BulkActions, ContextMenu, etc.
 * 
 * @example
 * var registry = Funky.ActionRegistry.create({
 *   schema: { icon: 'fas fa-circle' },
 *   onAdd: function(action) { render(); }
 * });
 * 
 * @version 1.0.4
 */
(function(global) {
  'use strict';

  if (!global.Funky || !global.Funky.register) {
    console.error('[Funky.ActionRegistry] Registry not found.');
    return;
  }

  if (global.Funky.isRegistered && global.Funky.isRegistered('ActionRegistry')) {
    return;
  }

  var Funky = global.Funky;

  // Instance counter for unique registry names
  var instanceCounter = 0;

  // Default schema
  var DEFAULT_SCHEMA = {
    icon: 'fas fa-circle',
    label: '',
    order: 50,
    hidden: false,
    disabled: false,
    className: ''
  };

  /**
   * ActionRegistry instance constructor
   * Uses Funky.Registry internally for action storage
   * @param {Object} options - Configuration
   */
  function Registry(options) {
    var self = this;
    this.id = 'action-registry-' + (++instanceCounter);
    this._schema = Object.assign({}, DEFAULT_SCHEMA, options.schema || {});
    this._onAdd = options.onAdd || null;
    this._onRemove = options.onRemove || null;
    this._onUpdate = options.onUpdate || null;
    this._onClear = options.onClear || null;

    // Create internal registry with callbacks
    this._registry = Funky.Registry.create('actionRegistry-' + instanceCounter, {
      defaults: this._schema,
      onRegister: function(key, item) {
        if (self._onAdd) {
          self._onAdd(item);
        }
      },
      onUnregister: function(key) {
        if (self._onRemove) {
          self._onRemove(key);
        }
      }
    });
  }

  Registry.prototype = {
    /**
     * Add an action
     * @param {Object} action - Action config (requires id)
     * @returns {boolean} Success
     */
    add: function(action) {
      if (!action || !action.id) {
        console.error('[ActionRegistry] Action requires id');
        return false;
      }

      // Merge with schema defaults and ensure label
      var fullAction = Object.assign({}, this._schema, action);
      fullAction.label = fullAction.label || action.id;

      this._registry.register(action.id, fullAction);
      return true;
    },

    /**
     * Remove an action
     * @param {string} id - Action ID
     * @returns {boolean} Success
     */
    remove: function(id) {
      if (!this._registry.has(id)) return false;
      this._registry.unregister(id);
      return true;
    },

    /**
     * Update an action
     * @param {string} id - Action ID
     * @param {Object} updates - Properties to update
     * @returns {boolean} Success
     */
    update: function(id, updates) {
      var existing = this._registry.get(id);
      if (!existing) return false;

      // Merge updates into existing action
      var updated = Object.assign({}, existing, updates);
      this._registry.register(id, updated);

      if (this._onUpdate) {
        this._onUpdate(id, updates);
      }

      return true;
    },

    /**
     * Get an action by ID
     * @param {string} id - Action ID
     * @returns {Object|null}
     */
    get: function(id) {
      return this._registry.get(id) || null;
    },

    /**
     * Get all actions
     * @returns {Array}
     */
    getAll: function() {
      var obj = this._registry.all();
      return Object.keys(obj).map(function(key) {
        return obj[key];
      });
    },

    /**
     * Get sorted visible actions
     * @returns {Array}
     */
    getSorted: function() {
      return this.getAll()
        .filter(function(a) { return !a.hidden; })
        .sort(function(a, b) { return a.order - b.order; });
    },

    /**
     * Hide an action
     * @param {string} id - Action ID
     * @returns {boolean} Success
     */
    hide: function(id) {
      return this.update(id, { hidden: true });
    },

    /**
     * Show an action
     * @param {string} id - Action ID
     * @returns {boolean} Success
     */
    show: function(id) {
      return this.update(id, { hidden: false });
    },

    /**
     * Clear all actions
     */
    clear: function() {
      this._registry.clear();

      if (this._onClear) {
        this._onClear();
      }
    },

    /**
     * Check if action exists
     * @param {string} id - Action ID
     * @returns {boolean}
     */
    has: function(id) {
      return this._registry.has(id);
    },

    /**
     * Get action count
     * @returns {number}
     */
    count: function() {
      return this._registry.count();
    },

    /**
     * Get list of action IDs
     * @returns {Array<string>}
     */
    list: function() {
      return this._registry.list();
    },

    /**
     * Destroy this registry instance
     */
    destroy: function() {
      this._registry.clear();
      this._onAdd = null;
      this._onRemove = null;
      this._onUpdate = null;
      this._onClear = null;
    }
  };

  // Instance registry for factory
  var _instances = Funky.Registry.createInstanceRegistry('ActionRegistry');

  // Factory
  var ActionRegistry = {
    /**
     * Create a new registry instance (primary factory method)
     * @param {Object} options - Configuration
     * @returns {Registry}
     */
    init: function(options) {
      var instance = new Registry(options || {});
      _instances.register(instance.id, instance);
      return instance;
    },

    /**
     * @deprecated Use ActionRegistry.init() instead
     */
    create: function(options) {
      if (Funky.debug) {
        console.warn('[Funky.ActionRegistry] create() is deprecated. Use init() instead.');
      }
      return ActionRegistry.init(options);
    },

    /**
     * Get existing instance by ID
     * @param {string} id - Instance ID
     * @returns {Registry|undefined}
     */
    getInstance: function(id) {
      return _instances.get(id);
    },

    /**
     * Destroy instance by ID
     * @param {string} id - Instance ID
     */
    destroy: function(id) {
      var instance = _instances.get(id);
      if (instance) {
        instance.destroy();
        _instances.unregister(id);
      }
    },

    /**
     * Destroy all instances
     */
    destroyAll: function() {
      _instances.destroyAll();
    },

    // Expose constructor for instanceof checks
    Registry: Registry
  };

  Funky.register('ActionRegistry', ActionRegistry);

})(window);
