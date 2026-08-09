/**
 * Funky.Registry - Generic Registry Utility
 * 
 * Provides two types of registries:
 * 1. ConfigRegistry - For key→value mappings (sounds, widget types, configurations)
 * 2. InstanceRegistry - For tracking component instances with lifecycle management
 * 
 * @module Funky.Registry
 * @version 1.0.4
 * @requires Funky (namespace.js must load first)
 * 
 * @example Config Registry
 * var sounds = Funky.Registry.create('sounds', { defaults: { volume: 1.0 } });
 * sounds.register('success', { file: 'success.mp3' });
 * sounds.get('success'); // { file: 'success.mp3', volume: 1.0 }
 * 
 * @example Instance Registry
 * var instances = Funky.Registry.createInstanceRegistry('MyComponent');
 * instances.register('id-1', instanceObj);
 * instances.getByElement(containerEl);
 * instances.destroyAll();
 */
(function(window) {
    'use strict';

    // Guard against missing namespace
    if (typeof Funky === 'undefined' || !Funky.register) {
        console.error('[Funky.Registry] Namespace not found. Load namespace.js first.');
        return;
    }

    // Guard against double registration
    if (Funky.isRegistered && Funky.isRegistered('Registry')) {
        return;
    }

    // =========================================================================
    // CONFIG REGISTRY
    // =========================================================================

    /**
     * ConfigRegistry - For key→value mappings with optional defaults and validation
     * @constructor
     * @param {string} name - Registry name (for debugging)
     * @param {Object} options - Configuration options
     * @param {Object} [options.defaults] - Default properties merged into registered items
     * @param {Function} [options.validate] - Validation function (item) => boolean
     * @param {Function} [options.onRegister] - Callback when item registered (key, item)
     * @param {Function} [options.onUnregister] - Callback when item unregistered (key)
     */
    function ConfigRegistry(name, options) {
        this._name = name || 'unnamed';
        this._items = {};
        this._defaults = options.defaults || {};
        this._validate = options.validate || null;
        this._onRegister = options.onRegister || null;
        this._onUnregister = options.onUnregister || null;
    }

    ConfigRegistry.prototype = {
        /**
         * Register an item
         * @param {string} key - Unique identifier
         * @param {*} item - Item to register (will be merged with defaults if object)
         * @returns {boolean} Success
         */
        register: function(key, item) {
            if (!key || typeof key !== 'string') {
                console.error('[Funky.Registry:' + this._name + '] Invalid key:', key);
                return false;
            }

            // Validate if validator provided
            if (this._validate && !this._validate(item)) {
                console.error('[Funky.Registry:' + this._name + '] Validation failed for:', key);
                return false;
            }

            // Merge with defaults if item is an object
            var finalItem;
            if (item && typeof item === 'object' && !Array.isArray(item)) {
                finalItem = {};
                for (var dk in this._defaults) {
                    if (this._defaults.hasOwnProperty(dk)) {
                        finalItem[dk] = this._defaults[dk];
                    }
                }
                for (var ik in item) {
                    if (item.hasOwnProperty(ik)) {
                        finalItem[ik] = item[ik];
                    }
                }
            } else {
                finalItem = item;
            }

            this._items[key] = finalItem;

            if (this._onRegister) {
                this._onRegister(key, finalItem);
            }

            return true;
        },

        /**
         * Get an item by key
         * @param {string} key - Item key
         * @returns {*} Item or null if not found
         */
        get: function(key) {
            return this._items.hasOwnProperty(key) ? this._items[key] : null;
        },

        /**
         * Check if key exists
         * @param {string} key - Item key
         * @returns {boolean}
         */
        has: function(key) {
            return this._items.hasOwnProperty(key);
        },

        /**
         * Get all keys
         * @returns {string[]}
         */
        list: function() {
            return Object.keys(this._items);
        },

        /**
         * Get all items as object
         * @returns {Object}
         */
        all: function() {
            var result = {};
            for (var key in this._items) {
                if (this._items.hasOwnProperty(key)) {
                    result[key] = this._items[key];
                }
            }
            return result;
        },

        /**
         * Unregister an item
         * @param {string} key - Item key
         * @returns {boolean} True if item existed and was removed
         */
        unregister: function(key) {
            if (!this._items.hasOwnProperty(key)) {
                return false;
            }

            delete this._items[key];

            if (this._onUnregister) {
                this._onUnregister(key);
            }

            return true;
        },

        /**
         * Clear all items
         */
        clear: function() {
            var keys = Object.keys(this._items);
            for (var i = 0; i < keys.length; i++) {
                this.unregister(keys[i]);
            }
        },

        /**
         * Get count of registered items
         * @returns {number}
         */
        count: function() {
            return Object.keys(this._items).length;
        },

        /**
         * Iterate over all items
         * @param {Function} fn - Callback (item, key)
         */
        forEach: function(fn) {
            for (var key in this._items) {
                if (this._items.hasOwnProperty(key)) {
                    fn(this._items[key], key);
                }
            }
        }
    };

    // =========================================================================
    // INSTANCE REGISTRY
    // =========================================================================

    /**
     * InstanceRegistry - For tracking component instances with lifecycle management
     * @constructor
     * @param {string} name - Component name (for debugging)
     */
    function InstanceRegistry(name) {
        this._name = name || 'unnamed';
        this._instances = {};
    }

    InstanceRegistry.prototype = {
        /**
         * Register an instance
         * @param {string} id - Instance ID
         * @param {Object} instance - Instance object (should have container/el property)
         * @returns {boolean} Success
         */
        register: function(id, instance) {
            if (!id || typeof id !== 'string') {
                console.error('[Funky.Registry:' + this._name + '] Invalid instance id:', id);
                return false;
            }

            if (!instance) {
                console.error('[Funky.Registry:' + this._name + '] Invalid instance for id:', id);
                return false;
            }

            this._instances[id] = instance;
            return true;
        },

        /**
         * Unregister an instance
         * @param {string} id - Instance ID
         * @returns {boolean} True if instance existed and was removed
         */
        unregister: function(id) {
            if (!this._instances.hasOwnProperty(id)) {
                return false;
            }

            delete this._instances[id];
            return true;
        },

        /**
         * Get instance by ID
         * @param {string} id - Instance ID
         * @returns {Object|null}
         */
        get: function(id) {
            return this._instances.hasOwnProperty(id) ? this._instances[id] : null;
        },

        /**
         * Check if instance exists
         * @param {string} id - Instance ID
         * @returns {boolean}
         */
        has: function(id) {
            return this._instances.hasOwnProperty(id);
        },

        /**
         * Find instance by container element
         * Searches for instances where container, el, or element matches
         * @param {HTMLElement} element - DOM element to search for
         * @returns {Object|null}
         */
        getByElement: function(element) {
            if (!element) return null;

            // Unwrap Funky.Dom wrapper if needed
            var rawEl = element.el ? element.el : element;

            for (var id in this._instances) {
                if (this._instances.hasOwnProperty(id)) {
                    var instance = this._instances[id];

                    // Check various container property names
                    var container = instance.container || instance.el || instance.element;

                    // Unwrap if it's a Funky.Dom wrapper
                    if (container && container.el) {
                        container = container.el;
                    }

                    if (container === rawEl) {
                        return instance;
                    }
                }
            }

            return null;
        },

        /**
         * Get all instances as array
         * @returns {Object[]}
         */
        getAll: function() {
            var result = [];
            for (var id in this._instances) {
                if (this._instances.hasOwnProperty(id)) {
                    result.push(this._instances[id]);
                }
            }
            return result;
        },

        /**
         * Get count of instances
         * @returns {number}
         */
        count: function() {
            return Object.keys(this._instances).length;
        },

        /**
         * Iterate over all instances
         * @param {Function} fn - Callback (instance, id)
         */
        forEach: function(fn) {
            for (var id in this._instances) {
                if (this._instances.hasOwnProperty(id)) {
                    fn(this._instances[id], id);
                }
            }
        },

        /**
         * Destroy all instances
         * Calls destroy() on each instance if available, then clears registry
         */
        destroyAll: function() {
            var ids = Object.keys(this._instances);
            for (var i = 0; i < ids.length; i++) {
                var id = ids[i];
                var instance = this._instances[id];

                // Call destroy if available
                if (instance && typeof instance.destroy === 'function') {
                    try {
                        instance.destroy();
                    } catch (e) {
                        console.error('[Funky.Registry:' + this._name + '] Error destroying instance:', id, e);
                    }
                }

                delete this._instances[id];
            }
        },

        /**
         * List all instance IDs
         * @returns {string[]}
         */
        list: function() {
            return Object.keys(this._instances);
        },

        /**
         * Get instances as a Map
         * @returns {Map}
         */
        getMap: function() {
            var map = new Map();
            for (var id in this._instances) {
                if (this._instances.hasOwnProperty(id)) {
                    map.set(id, this._instances[id]);
                }
            }
            return map;
        }
    };

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    var Registry = {
        /**
         * Create a config registry
         * @param {string} name - Registry name
         * @param {Object} [options] - Configuration options
         * @returns {ConfigRegistry}
         */
        create: function(name, options) {
            return new ConfigRegistry(name, options || {});
        },

        /**
         * Create an instance registry for component instance tracking
         * @param {string} name - Component name
         * @returns {InstanceRegistry}
         */
        createInstanceRegistry: function(name) {
            return new InstanceRegistry(name);
        },

        /**
         * Version info
         */
        version: '1.0.0'
    };

    // Register with Funky namespace
    Funky.register('Registry', Registry);

    console.log('[Funky.Registry] v' + Registry.version + ' initialized');

})(window);
