/**
 * Funky.Dom - Direct DOM Manipulation
 * 
 * Fast, chainable DOM manipulation and element creation with zero overhead.
 * The primary tool for most DOM operations in Funky applications.
 * 
 * NOTE: For virtual DOM with diff/patch, use Funky.VDom instead.
 * - Funky.Dom: Direct DOM manipulation (this module) - fast, zero overhead
 * - Funky.VDom: Virtual DOM with diff/patch - for reactive data-bound UIs
 * 
 * @example
 * var D = Funky.Dom;
 * 
 * // Select and manipulate existing elements
 * D.one('.card').classAdd('active').show();
 * D.all('.item').classRemove('hidden');
 * 
 * // Convert existing DOM to VNode for diffing (if using VDom)
 * var vnode = D.one('.card').virtualise();
 */
(function(window) {
    'use strict';

    // Guard against double registration
    if (typeof Funky !== 'undefined' && Funky.isRegistered && Funky.isRegistered('Dom')) {
        return;
    }

    // Registry dependency check
    if (!window.Funky || !window.Funky.register) {
        console.error('[Funky.Dom] Registry not found. Load namespace.js first.');
        return;
    }

    // =========================================================================
    // ElementWrapper - Single Element
    // =========================================================================

    /**
     * Wrapper for a single DOM element with chainable methods
     * @param {HTMLElement} element
     */
    function ElementWrapper(element) {
        this.el = element;
    }

    ElementWrapper.prototype = {
        // =====================================================================
        // Class Manipulation
        // =====================================================================

        /**
         * Add one or more classes
         * @param {string} value - Space-separated class names
         * @returns {ElementWrapper}
         */
        classAdd: function() {
            if (!this.el) return this;
            
            for (var i = 0; i < arguments.length; i++) {
                var value = arguments[i];
                if (value) {
                    var classes = String(value).trim().split(/\s+/);
                    for (var j = 0; j < classes.length; j++) {
                        if (classes[j]) {
                            this.el.classList.add(classes[j]);
                        }
                    }
                }
            }
            return this;
        },

        /**
         * Remove one or more classes
         * @param {...string} values - Class names (space-separated or multiple args)
         * @returns {ElementWrapper}
         */
        classRemove: function() {
            if (!this.el) return this;
            
            for (var i = 0; i < arguments.length; i++) {
                var value = arguments[i];
                if (value) {
                    var classes = String(value).trim().split(/\s+/);
                    for (var j = 0; j < classes.length; j++) {
                        if (classes[j]) {
                            this.el.classList.remove(classes[j]);
                        }
                    }
                }
            }
            return this;
        },

        /**
         * Toggle a class, optionally based on condition
         * @param {string} value - Class name
         * @param {boolean} [condition] - Force add/remove
         * @returns {ElementWrapper}
         */
        classToggle: function(value, condition) {
            if (value && this.el) {
                if (arguments.length > 1) {
                    this.el.classList.toggle(value, condition);
                } else {
                    this.el.classList.toggle(value);
                }
            }
            return this;
        },

        /**
         * Check if element has a class
         * @param {string} value - Class name
         * @returns {boolean}
         */
        hasClass: function(value) {
            return this.el ? this.el.classList.contains(value) : false;
        },

        /**
         * Check if element has a class (alias for hasClass, follows classAdd/classRemove naming)
         * @param {string} value - Class name
         * @returns {boolean}
         */
        classHas: function(value) {
            return this.el ? this.el.classList.contains(value) : false;
        },

        // =====================================================================
        // Attribute Manipulation
        // =====================================================================

        /**
         * Get or set an attribute
         * @param {string} name - Attribute name
         * @param {*} [value] - Attribute value (omit to get)
         * @returns {ElementWrapper|string}
         */
        attr: function(name, value) {
            if (this.el) {
                // Handle object of attributes
                if (typeof name === 'object' && name !== null) {
                    for (var key in name) {
                        if (name.hasOwnProperty(key)) {
                            var val = name[key];
                            if (val == null || val === false) {
                                this.el.removeAttribute(key);
                            } else {
                                this.el.setAttribute(key, val === true ? '' : val);
                            }
                        }
                    }
                    return this;
                }
                // Single attribute getter
                if (arguments.length === 1) {
                    return this.el.getAttribute(name);
                }
                // Single attribute setter
                if (value == null || value === false) {
                    this.el.removeAttribute(name);
                } else {
                    this.el.setAttribute(name, value === true ? '' : value);
                }
            }
            return this;
        },

        /**
         * Remove an attribute
         * @param {string} name - Attribute name
         * @returns {ElementWrapper}
         */
        attrRemove: function(name) {
            if (this.el) {
                this.el.removeAttribute(name);
            }
            return this;
        },

        /**
         * Toggle an attribute based on condition
         * @param {string} name - Attribute name
         * @param {boolean} condition - Add if true, remove if false
         * @param {*} [value] - Attribute value (defaults to '')
         * @returns {ElementWrapper}
         */
        attrToggle: function(name, condition, value) {
            if (this.el) {
                if (condition) {
                    this.el.setAttribute(name, arguments.length > 2 ? value : '');
                } else {
                    this.el.removeAttribute(name);
                }
            }
            return this;
        },

        /**
         * Get or set a data attribute
         * @param {string} name - Data attribute name (without 'data-' prefix)
         * @param {*} [value] - Value to set (omit to get)
         * @returns {ElementWrapper|string}
         */
        data: function(name, value) {
            if (this.el) {
                // Convert kebab-case to camelCase for dataset API
                // e.g., 'bs-dismiss' -> 'bsDismiss'
                var camelName = name.replace(/-([a-z])/g, function(g) { return g[1].toUpperCase(); });
                if (arguments.length === 1) {
                    var val = this.el.dataset[camelName];
                    return val !== undefined ? val : null;
                }
                this.el.dataset[camelName] = value;
            }
            return this;
        },

        // =====================================================================
        // Style & Visibility
        // =====================================================================

        /**
         * Set inline styles
         * @param {Object|string} styles - Style object or property name
         * @param {string} [value] - Value when first arg is property name
         * @returns {ElementWrapper}
         */
        style: function(styles, value) {
            if (this.el && styles) {
                // Support both .style('prop', 'val') and .style({ prop: 'val' })
                if (typeof styles === 'string') {
                    // Use setProperty for CSS custom properties (--var)
                    if (styles.indexOf('--') === 0) {
                        this.el.style.setProperty(styles, value);
                    } else {
                        this.el.style[styles] = value;
                    }
                } else {
                    var keys = Object.keys(styles);
                    for (var i = 0; i < keys.length; i++) {
                        var key = keys[i];
                        if (key.indexOf('--') === 0) {
                            this.el.style.setProperty(key, styles[key]);
                        } else {
                            this.el.style[key] = styles[key];
                        }
                    }
                }
            }
            return this;
        },

        /**
         * Get computed style value
         * @param {string} prop - CSS property name
         * @returns {string}
         */
        css: function(prop) {
            return this.el ? getComputedStyle(this.el)[prop] : '';
        },

        /**
         * Hide element by setting display: none
         * @returns {ElementWrapper}
         */
        hide: function() {
            if (this.el) {
                this.el.style.display = 'none';
            }
            return this;
        },

        /**
         * Show element by removing display: none
         * @param {string} [displayValue] - Display value to use (default: '')
         * @returns {ElementWrapper}
         */
        show: function(displayValue) {
            if (this.el) {
                this.el.style.display = displayValue || '';
            }
            return this;
        },

        /**
         * Toggle visibility
         * @param {boolean} [condition] - Force show/hide
         * @returns {ElementWrapper}
         */
        toggle: function(condition) {
            if (this.el) {
                if (arguments.length > 0) {
                    this.el.classList.toggle('funky-hidden', !condition);
                } else {
                    this.el.classList.toggle('funky-hidden');
                }
            }
            return this;
        },

        // =====================================================================
        // Events
        // =====================================================================

        /**
         * Add event listener
         * @param {string} event - Event name
         * @param {Function} handler - Event handler
         * @param {Object} [options] - Event options
         * @returns {ElementWrapper}
         */
        on: function(event, handler, options) {
            if (this.el) {
                this.el.addEventListener(event, handler, options);
            }
            return this;
        },

        /**
         * Remove event listener
         * @param {string} event - Event name
         * @param {Function} handler - Event handler
         * @param {Object} [options] - Event options
         * @returns {ElementWrapper}
         */
        off: function(event, handler, options) {
            if (this.el) {
                this.el.removeEventListener(event, handler, options);
            }
            return this;
        },

        /**
         * Trigger a custom event
         * @param {string} event - Event name
         * @param {*} [detail] - Event detail data
         * @returns {ElementWrapper}
         */
        trigger: function(event, detail) {
            if (this.el) {
                this.el.dispatchEvent(new CustomEvent(event, { detail: detail, bubbles: true }));
            }
            return this;
        },

        // =====================================================================
        // Content
        // =====================================================================

        /**
         * Get or set innerHTML
         * @param {string} [content] - HTML content (omit to get)
         * @returns {ElementWrapper|string}
         */
        html: function(content) {
            if (this.el) {
                if (arguments.length === 0) {
                    return this.el.innerHTML;
                }
                this.el.innerHTML = content;
            }
            return this;
        },

        /**
         * Get or set textContent
         * @param {string} [content] - Text content (omit to get)
         * @returns {ElementWrapper|string}
         */
        text: function(content) {
            if (this.el) {
                if (arguments.length === 0) {
                    return this.el.textContent;
                }
                this.el.textContent = content;
            }
            return this;
        },

        /**
         * Get or set input value
         * @param {*} [value] - Value to set (omit to get)
         * @returns {ElementWrapper|*}
         */
        val: function(value) {
            if (this.el) {
                if (arguments.length === 0) {
                    return this.el.value;
                }
                this.el.value = value;
            }
            return this;
        },

        // =====================================================================
        // DOM Manipulation
        // =====================================================================

        /**
         * Append child element(s)
         * Accepts multiple arguments: VNode, Element, ElementWrapper, or string
         * @param {...*} children - One or more children to append
         * @returns {ElementWrapper}
         */
        append: function() {
            if (!this.el) return this;
            
            for (var i = 0; i < arguments.length; i++) {
                var child = arguments[i];
                if (child == null) continue;
                
                // Accept string - convert to text node
                if (typeof child === 'string' || typeof child === 'number') {
                    child = document.createTextNode(String(child));
                }
                // Accept VNode (render it)
                else if (child._isVNode || (child && typeof child.build === 'function')) {
                    if (typeof child.build === 'function') {
                        child = child.build();
                    }
                    child = Funky.VDom ? Funky.VDom.render(child) : child;
                }
                // Accept ElementWrapper
                else if (child instanceof ElementWrapper) {
                    child = child.el;
                }
                // Accept objects with .el property (like D.text())
                else if (child && child.el) {
                    child = child.el;
                }
                this.el.appendChild(child);
            }
            return this;
        },

        /**
         * Prepend child element
         * Accepts multiple arguments: VNode, Element, ElementWrapper, or string
         * @param {...*} children - One or more children to prepend
         * @returns {ElementWrapper}
         */
        prepend: function() {
            if (!this.el) return this;
            
            // Prepend in reverse order so first argument ends up first
            for (var i = arguments.length - 1; i >= 0; i--) {
                var child = arguments[i];
                if (child == null) continue;
                
                // Accept string - convert to text node
                if (typeof child === 'string' || typeof child === 'number') {
                    child = document.createTextNode(String(child));
                }
                // Accept VNode (render it)
                else if (child._isVNode || (child && typeof child.build === 'function')) {
                    if (typeof child.build === 'function') {
                        child = child.build();
                    }
                    child = Funky.VDom ? Funky.VDom.render(child) : child;
                }
                // Accept ElementWrapper
                else if (child instanceof ElementWrapper) {
                    child = child.el;
                }
                // Accept objects with .el property
                else if (child && child.el) {
                    child = child.el;
                }
                this.el.insertBefore(child, this.el.firstChild);
            }
            return this;
        },

        /**
         * Remove element from DOM
         * @returns {ElementWrapper}
         */
        remove: function() {
            if (this.el && this.el.parentNode) {
                this.el.parentNode.removeChild(this.el);
            }
            return this;
        },

        /**
         * Clear all child content
         * @returns {ElementWrapper}
         */
        empty: function() {
            if (this.el) {
                this.el.innerHTML = '';
            }
            return this;
        },

        /**
         * Replace element content with VNode or HTML
         * @param {*} content - VNode, Builder, or HTML string
         * @returns {ElementWrapper}
         */
        replaceContent: function(content) {
            if (this.el) {
                this.el.innerHTML = '';
                if (content._isVNode || (content && typeof content.build === 'function')) {
                    if (typeof content.build === 'function') {
                        content = content.build();
                    }
                    this.el.appendChild(Funky.VDom ? Funky.VDom.render(content) : content);
                } else if (typeof content === 'string') {
                    this.el.innerHTML = content;
                } else if (content instanceof ElementWrapper) {
                    this.el.appendChild(content.el);
                } else if (content instanceof Element) {
                    this.el.appendChild(content);
                }
            }
            return this;
        },

        // =====================================================================
        // Traversal
        // =====================================================================

        /**
         * Get parent element
         * @returns {ElementWrapper|null}
         */
        parent: function() {
            return this.el && this.el.parentElement 
                ? new ElementWrapper(this.el.parentElement) 
                : null;
        },

        /**
         * Find descendant elements
         * @param {string} selector
         * @returns {ElementList}
         */
        find: function(selector) {
            if (this.el) {
                var elements = Array.prototype.slice.call(this.el.querySelectorAll(selector));
                return new ElementList(elements);
            }
            return new ElementList([]);
        },

        /**
         * Find single descendant
         * @param {string} selector
         * @returns {ElementWrapper|null}
         */
        findOne: function(selector) {
            if (this.el) {
                var found = this.el.querySelector(selector);
                return found ? new ElementWrapper(found) : null;
            }
            return null;
        },

        /**
         * Alias for findOne - find single descendant
         * @param {string} selector
         * @returns {ElementWrapper|null}
         */
        one: function(selector) {
            return this.findOne(selector);
        },

        /**
         * Get closest ancestor matching selector
         * @param {string} selector
         * @returns {ElementWrapper|null}
         */
        closest: function(selector) {
            if (this.el) {
                var found = this.el.closest(selector);
                return found ? new ElementWrapper(found) : null;
            }
            return null;
        },

        /**
         * Get next sibling element
         * @param {string} [selector] - Optional selector to filter
         * @returns {ElementWrapper|null}
         */
        next: function(selector) {
            if (!this.el) return null;
            var sibling = this.el.nextElementSibling;
            if (!sibling) return null;
            if (selector && !sibling.matches(selector)) {
                // Keep looking for matching sibling
                while (sibling && !sibling.matches(selector)) {
                    sibling = sibling.nextElementSibling;
                }
                if (!sibling) return null;
            }
            return new ElementWrapper(sibling);
        },

        /**
         * Get previous sibling element
         * @param {string} [selector] - Optional selector to filter
         * @returns {ElementWrapper|null}
         */
        prev: function(selector) {
            if (!this.el) return null;
            var sibling = this.el.previousElementSibling;
            if (!sibling) return null;
            if (selector && !sibling.matches(selector)) {
                // Keep looking for matching sibling
                while (sibling && !sibling.matches(selector)) {
                    sibling = sibling.previousElementSibling;
                }
                if (!sibling) return null;
            }
            return new ElementWrapper(sibling);
        },

        /**
         * Get all sibling elements
         * @param {string} [selector] - Optional selector to filter siblings
         * @returns {ElementList}
         */
        siblings: function(selector) {
            if (!this.el || !this.el.parentNode) {
                return new ElementList([]);
            }
            var parent = this.el.parentNode;
            var children = Array.prototype.slice.call(parent.children);
            var self = this.el;
            var siblings = children.filter(function(child) {
                if (child === self) return false;
                if (selector && !child.matches(selector)) return false;
                return true;
            });
            return new ElementList(siblings);
        },

        /**
         * Get index of this element among its siblings
         * @returns {number} Index (0-based), or -1 if not found
         */
        index: function() {
            if (!this.el || !this.el.parentNode) return -1;
            var children = this.el.parentNode.children;
            for (var i = 0; i < children.length; i++) {
                if (children[i] === this.el) return i;
            }
            return -1;
        },

        /**
         * Clone this element
         * @param {boolean} [deep=true] - Clone children too
         * @returns {ElementWrapper}
         */
        clone: function(deep) {
            if (!this.el) return new ElementWrapper(null);
            var cloned = this.el.cloneNode(deep !== false);
            return new ElementWrapper(cloned);
        },

        /**
         * Replace this element with new content
         * @param {HTMLElement|ElementWrapper|string} content - Replacement content
         * @returns {ElementWrapper} The new element wrapper
         */
        replaceWith: function(content) {
            if (!this.el || !this.el.parentNode) return this;
            
            var newEl;
            if (typeof content === 'string') {
                // HTML string
                var temp = document.createElement('div');
                temp.innerHTML = content;
                newEl = temp.firstElementChild;
            } else if (content instanceof ElementWrapper) {
                newEl = content.el;
            } else if (content && content._isVNode) {
                // VNode - render it
                newEl = Funky.VDom ? Funky.VDom.render(content) : content;
            } else if (content && typeof content.build === 'function') {
                // VDom Builder
                var vnode = content.build();
                newEl = Funky.VDom ? Funky.VDom.render(vnode) : vnode;
            } else {
                newEl = content;
            }
            
            if (newEl) {
                this.el.parentNode.replaceChild(newEl, this.el);
                return new ElementWrapper(newEl);
            }
            return this;
        },

        /**
         * Wrap this element with another element
         * @param {HTMLElement|ElementWrapper|string} wrapper - Wrapper element or tag name
         * @returns {ElementWrapper} This element (for chaining)
         */
        wrapWith: function(wrapper) {
            if (!this.el || !this.el.parentNode) return this;
            
            var wrapperEl;
            if (typeof wrapper === 'string') {
                // Tag name or HTML
                if (wrapper.charAt(0) === '<') {
                    var temp = document.createElement('div');
                    temp.innerHTML = wrapper;
                    wrapperEl = temp.firstElementChild;
                } else {
                    wrapperEl = document.createElement(wrapper);
                }
            } else if (wrapper instanceof ElementWrapper) {
                wrapperEl = wrapper.el;
            } else {
                wrapperEl = wrapper;
            }
            
            if (wrapperEl) {
                this.el.parentNode.insertBefore(wrapperEl, this.el);
                wrapperEl.appendChild(this.el);
            }
            return this;
        },

        /**
         * Remove the parent element, keeping this element in its place
         * @returns {ElementWrapper} This element (for chaining)
         */
        unwrap: function() {
            if (!this.el) return this;
            var parent = this.el.parentNode;
            if (!parent || !parent.parentNode) return this;
            
            // Move all siblings out before the parent
            var grandparent = parent.parentNode;
            while (parent.firstChild) {
                grandparent.insertBefore(parent.firstChild, parent);
            }
            // Remove the now-empty parent
            grandparent.removeChild(parent);
            return this;
        },

        /**
         * Check if element has no children or text content
         * @returns {boolean}
         */
        isEmpty: function() {
            if (!this.el) return true;
            // Check for element children
            if (this.el.children && this.el.children.length > 0) return false;
            // Check for text content (trim whitespace)
            var text = this.el.textContent || '';
            return text.trim() === '';
        },

        // =====================================================================
        // VNode Conversion
        // =====================================================================

        /**
         * Convert this element to a VNode representation
         * Useful for capturing existing DOM for future diffing
         * @param {boolean} [deep=true] - Include children
         * @returns {VNode}
         */
        virtualise: function(deep) {
            if (!this.el) {
                return null;
            }
            return virtualiseElement(this.el, deep !== false);
        },

        /**
         * Get the raw DOM element
         * @returns {HTMLElement|null}
         */
        raw: function() {
            return this.el;
        },

        /**
         * Check if wrapper contains a valid element
         * @returns {boolean}
         */
        exists: function() {
            return this.el !== null && this.el !== undefined;
        }
    };

    // =========================================================================
    // ElementList - Multiple Elements
    // =========================================================================

    /**
     * Wrapper for multiple DOM elements with chainable methods
     * @param {Array} elements
     */
    function ElementList(elements) {
        this.elements = elements || [];
        this.length = this.elements.length;
    }

    ElementList.prototype = {
        /**
         * Iterate over elements
         * @param {Function} callback - Function(wrapper, index)
         * @returns {ElementList}
         */
        each: function(callback) {
            for (var i = 0; i < this.elements.length; i++) {
                callback.call(this.elements[i], new ElementWrapper(this.elements[i]), i);
            }
            return this;
        },

        /**
         * Get first element
         * @returns {ElementWrapper|null}
         */
        first: function() {
            return this.elements.length > 0 ? new ElementWrapper(this.elements[0]) : null;
        },

        /**
         * Get last element
         * @returns {ElementWrapper|null}
         */
        last: function() {
            return this.elements.length > 0 
                ? new ElementWrapper(this.elements[this.elements.length - 1]) 
                : null;
        },

        /**
         * Get element at index
         * @param {number} index
         * @returns {ElementWrapper|null}
         */
        get: function(index) {
            return this.elements[index] ? new ElementWrapper(this.elements[index]) : null;
        },

        /**
         * Get element at index (alias for get)
         * @param {number} index
         * @returns {ElementWrapper|null}
         */
        at: function(index) {
            return this.elements[index] ? new ElementWrapper(this.elements[index]) : null;
        },

        /**
         * Filter elements
         * @param {Function} callback - Function(wrapper, index) returning boolean
         * @returns {ElementList}
         */
        filter: function(callback) {
            var filtered = [];
            for (var i = 0; i < this.elements.length; i++) {
                if (callback.call(this.elements[i], new ElementWrapper(this.elements[i]), i)) {
                    filtered.push(this.elements[i]);
                }
            }
            return new ElementList(filtered);
        },

        /**
         * Map elements to array
         * @param {Function} callback - Function(wrapper, index)
         * @returns {Array}
         */
        map: function(callback) {
            var result = [];
            for (var i = 0; i < this.elements.length; i++) {
                result.push(callback.call(this.elements[i], new ElementWrapper(this.elements[i]), i));
            }
            return result;
        },

        /**
         * Convert all elements to VNodes
         * @param {boolean} [deep=true] - Include children
         * @returns {Array<VNode>}
         */
        virtualise: function(deep) {
            var result = [];
            var includeChildren = deep !== false;
            for (var i = 0; i < this.elements.length; i++) {
                result.push(virtualiseElement(this.elements[i], includeChildren));
            }
            return result;
        }
    };

    // Add chainable methods to ElementList that apply to all elements
    var chainableMethods = [
        'classAdd', 'classRemove', 'classToggle', 
        'attrRemove', 'attrToggle', 
        'hide', 'show', 'toggle',
        'remove', 'empty'
    ];

    for (var m = 0; m < chainableMethods.length; m++) {
        (function(method) {
            ElementList.prototype[method] = function() {
                var args = arguments;
                for (var i = 0; i < this.elements.length; i++) {
                    var wrapper = new ElementWrapper(this.elements[i]);
                    wrapper[method].apply(wrapper, args);
                }
                return this;
            };
        })(chainableMethods[m]);
    }

    // Add on/off to ElementList
    ElementList.prototype.on = function(event, handler, options) {
        for (var i = 0; i < this.elements.length; i++) {
            this.elements[i].addEventListener(event, handler, options);
        }
        return this;
    };

    ElementList.prototype.off = function(event, handler, options) {
        for (var i = 0; i < this.elements.length; i++) {
            this.elements[i].removeEventListener(event, handler, options);
        }
        return this;
    };

    // =========================================================================
    // VNode Conversion Utility
    // =========================================================================

    /**
     * Convert a DOM element to a VNode representation
     * @param {HTMLElement} element
     * @param {boolean} deep - Include children
     * @returns {VNode}
     */
    function virtualiseElement(element, deep) {
        // Text node
        if (element.nodeType === 3) {
            return {
                type: 'text',
                value: element.textContent,
                _isVNode: true
            };
        }

        // Not an element node
        if (element.nodeType !== 1) {
            return null;
        }

        // Build attributes object
        var attrs = {};
        var attributes = element.attributes;
        for (var i = 0; i < attributes.length; i++) {
            var attr = attributes[i];
            attrs[attr.name] = attr.value;
        }

        // Handle inline styles
        if (element.style && element.style.cssText) {
            var styleObj = {};
            var styleText = element.style.cssText;
            var styleParts = styleText.split(';');
            for (var s = 0; s < styleParts.length; s++) {
                var part = styleParts[s].trim();
                if (part) {
                    var colonIndex = part.indexOf(':');
                    if (colonIndex > -1) {
                        var prop = part.substring(0, colonIndex).trim();
                        var val = part.substring(colonIndex + 1).trim();
                        // Convert to camelCase
                        prop = prop.replace(/-([a-z])/g, function(match, letter) {
                            return letter.toUpperCase();
                        });
                        styleObj[prop] = val;
                    }
                }
            }
            if (Object.keys(styleObj).length > 0) {
                attrs.style = styleObj;
            }
        }

        // Build children array
        var children = [];
        if (deep) {
            var childNodes = element.childNodes;
            for (var c = 0; c < childNodes.length; c++) {
                var childVNode = virtualiseElement(childNodes[c], true);
                if (childVNode) {
                    children.push(childVNode);
                }
            }
        }

        return {
            type: 'element',
            tag: element.tagName.toLowerCase(),
            attrs: attrs,
            children: children,
            key: attrs.key || attrs['data-key'] || null,
            _isVNode: true
        };
    }

    // =========================================================================
    // Element Creation
    // =========================================================================

    /**
     * Create a new element with tag name and optional options
     * @param {string} tag - HTML tag name
     * @param {Object} [options] - Optional configuration
     * @param {string} [options.className] - CSS class name(s)
     * @param {string} [options.id] - Element ID
     * @param {Object} [options.attrs] - Additional attributes
     * @returns {ElementWrapper|null}
     */
    function createElement(tag, options) {
        // Guard against null/empty tag names
        if (!tag || typeof tag !== 'string') {
            return null;
        }
        // If tag looks like HTML (starts with <), parse it
        if (tag.charAt(0) === '<') {
            var temp = document.createElement('div');
            temp.innerHTML = tag;
            return new ElementWrapper(temp.firstElementChild);
        }
        var wrapper = new ElementWrapper(document.createElement(tag));

        // Apply options if provided
        if (options) {
            if (options.className) {
                wrapper.el.className = options.className;
            }
            if (options.id) {
                wrapper.el.id = options.id;
            }
            if (options.attrs) {
                Object.keys(options.attrs).forEach(function(key) {
                    wrapper.attr(key, options.attrs[key]);
                });
            }
        }

        return wrapper;
    }

    /**
     * Create an icon element with automatic ARIA handling
     * @param {string} iconClass - Icon class (e.g., 'fas fa-check')
     * @param {Object|string} [options] - Options object or additional class string
     * @param {string} options.class - Additional classes
     * @param {string} options['aria-label'] - Semantic label (makes icon meaningful)
     * @returns {ElementWrapper}
     *
     * @example
     * // Decorative icon (default) - hidden from screen readers
     * D.icon('fas fa-check')
     * // <i class="fas fa-check" aria-hidden="true"></i>
     *
     * // Semantic icon - readable by screen readers
     * D.icon('fas fa-check', { 'aria-label': 'Completed' })
     * // <i class="fas fa-check" role="img" aria-label="Completed"></i>
     *
     * // Backwards compatible - additional class as string
     * D.icon('fas fa-check', 'text-success')
     * // <i class="fas fa-check text-success" aria-hidden="true"></i>
     */
    function createIcon(iconClass, options) {
        var el = document.createElement('i');
        var opts = typeof options === 'string' ? { class: options } : (options || {});

        // Build class name
        el.className = iconClass + (opts.class ? ' ' + opts.class : '');

        // Determine if icon is semantic or decorative
        var ariaLabel = opts['aria-label'];

        if (ariaLabel) {
            // Semantic icon - has meaning for screen readers
            el.setAttribute('role', 'img');
            el.setAttribute('aria-label', ariaLabel);
        } else {
            // Decorative icon - hidden from screen readers
            el.setAttribute('aria-hidden', 'true');
        }

        return new ElementWrapper(el);
    }

    /**
     * Create a text node wrapped in ElementWrapper-compatible object
     * @param {string} content - Text content
     * @returns {Object} Object with .el property for consistency
     */
    function createText(content) {
        var textNode = document.createTextNode(content == null ? '' : String(content));
        // Return object with .el for consistency with ElementWrapper
        return { el: textNode };
    }

    // =========================================================================
    // Utility Functions (mirroring VDom API)
    // =========================================================================

    /**
     * Dynamic class name builder
     * @param {...(string|Object|Array)} args - Class names, objects with boolean values, or arrays
     * @returns {string}
     */
    function classes() {
        var result = [];
        for (var i = 0; i < arguments.length; i++) {
            var arg = arguments[i];
            if (!arg) continue;
            if (typeof arg === 'string') {
                result.push(arg);
            } else if (Array.isArray(arg)) {
                var nested = classes.apply(null, arg);
                if (nested) result.push(nested);
            } else if (typeof arg === 'object') {
                var keys = Object.keys(arg);
                for (var k = 0; k < keys.length; k++) {
                    if (arg[keys[k]]) result.push(keys[k]);
                }
            }
        }
        return result.join(' ');
    }

    /**
     * Conditional helper - returns element if condition is true
     * @param {boolean} condition
     * @param {*} thenValue - Value/function if true
     * @param {*} [elseValue] - Value/function if false
     * @returns {*}
     */
    function when(condition, thenValue, elseValue) {
        if (condition) {
            return typeof thenValue === 'function' ? thenValue() : thenValue;
        }
        return elseValue ? (typeof elseValue === 'function' ? elseValue() : elseValue) : null;
    }

    /**
     * Iterate over array and return elements
     * @param {Array} items - Array to iterate
     * @param {Function} renderFn - Function(item, index) returning element
     * @returns {Array}
     */
    function each(items, renderFn) {
        if (!items || !items.length) return [];
        var result = [];
        for (var i = 0; i < items.length; i++) {
            var el = renderFn(items[i], i);
            if (el) result.push(el);
        }
        return result;
    }

    // =========================================================================
    // Accessibility Helpers
    // =========================================================================

    /**
     * Create screen reader only text (visually hidden)
     * @param {string} textContent - Text for screen readers
     * @returns {ElementWrapper}
     *
     * @example
     * D.srOnly('Opens in new window')
     * // <span class="visually-hidden">Opens in new window</span>
     */
    function createSrOnly(textContent) {
        var el = document.createElement('span');
        el.className = 'visually-hidden';
        el.textContent = textContent || '';
        return new ElementWrapper(el);
    }

    /**
     * Create an ARIA live region for screen reader announcements
     * @param {string} [mode='polite'] - 'polite' or 'assertive'
     * @param {string} [initialContent] - Initial content
     * @returns {ElementWrapper}
     *
     * @example
     * D.liveRegion('polite')
     * // <div aria-live="polite" aria-atomic="true" class="visually-hidden"></div>
     *
     * D.liveRegion('assertive')
     * // <div aria-live="assertive" aria-atomic="true" role="alert" class="visually-hidden"></div>
     */
    function createLiveRegion(mode, initialContent) {
        var el = document.createElement('div');
        el.className = 'visually-hidden';
        el.setAttribute('aria-live', mode === 'assertive' ? 'assertive' : 'polite');
        el.setAttribute('aria-atomic', 'true');

        if (mode === 'assertive') {
            el.setAttribute('role', 'alert');
        } else {
            el.setAttribute('role', 'status');
        }

        if (initialContent) {
            el.textContent = initialContent;
        }

        return new ElementWrapper(el);
    }

    /**
     * Create an accessible form label
     * @param {string} forId - ID of associated input
     * @param {string} labelText - Label text
     * @param {Object} [options] - Options
     * @param {boolean} options.required - Show required indicator
     * @param {boolean} options.hidden - Make label visually hidden
     * @returns {ElementWrapper}
     *
     * @example
     * D.label('email', 'Email Address')
     * // <label for="email">Email Address</label>
     *
     * D.label('email', 'Email', { required: true })
     * // <label for="email">Email <span class="text-danger" aria-hidden="true">*</span><span class="visually-hidden"> (required)</span></label>
     */
    function createLabel(forId, labelText, options) {
        var opts = options || {};
        var el = document.createElement('label');
        el.setAttribute('for', forId);

        if (opts.hidden) {
            el.className = 'visually-hidden';
        }

        el.appendChild(document.createTextNode(labelText));

        if (opts.required) {
            var star = document.createElement('span');
            star.className = 'text-danger';
            star.setAttribute('aria-hidden', 'true');
            star.textContent = ' *';
            el.appendChild(star);

            var srRequired = document.createElement('span');
            srRequired.className = 'visually-hidden';
            srRequired.textContent = ' (required)';
            el.appendChild(srRequired);
        }

        return new ElementWrapper(el);
    }

    /**
     * Create a complete accessible form field
     * @param {Object} config - Field configuration
     * @param {string} config.id - Field ID (required)
     * @param {string} config.label - Label text (required)
     * @param {string} [config.type='text'] - Input type
     * @param {string} [config.name] - Input name (defaults to id)
     * @param {string} [config.value] - Input value
     * @param {string} [config.placeholder] - Placeholder text
     * @param {boolean} [config.required] - Required field
     * @param {string} [config.description] - Help text
     * @param {string} [config.error] - Error message
     * @param {string} [config.class] - Additional classes for input
     * @returns {ElementWrapper}
     *
     * @example
     * D.formField({
     *   id: 'email',
     *   type: 'email',
     *   label: 'Email Address',
     *   required: true,
     *   description: 'We will never share your email'
     * })
     */
    function createFormField(config) {
        var fieldId = config.id;
        var descId = fieldId + '-desc';
        var errorId = fieldId + '-error';
        var describedBy = [];

        if (config.description) describedBy.push(descId);
        if (config.error) describedBy.push(errorId);

        // Container
        var container = document.createElement('div');
        container.className = 'mb-3';

        // Label
        var labelEl = createLabel(fieldId, config.label, { required: config.required });
        container.appendChild(labelEl.el);

        // Input
        var input = document.createElement('input');
        input.setAttribute('type', config.type || 'text');
        input.setAttribute('id', fieldId);
        input.setAttribute('name', config.name || fieldId);
        input.className = 'form-control' + (config.class ? ' ' + config.class : '');

        if (config.value != null) input.setAttribute('value', config.value);
        if (config.placeholder) input.setAttribute('placeholder', config.placeholder);

        if (config.required) {
            input.setAttribute('required', '');
            input.setAttribute('aria-required', 'true');
        }

        if (config.error) {
            input.setAttribute('aria-invalid', 'true');
            input.classList.add('is-invalid');
        }

        if (describedBy.length > 0) {
            input.setAttribute('aria-describedby', describedBy.join(' '));
        }

        container.appendChild(input);

        // Description
        if (config.description) {
            var desc = document.createElement('div');
            desc.className = 'form-text';
            desc.setAttribute('id', descId);
            desc.textContent = config.description;
            container.appendChild(desc);
        }

        // Error
        if (config.error) {
            var error = document.createElement('div');
            error.className = 'invalid-feedback d-block';
            error.setAttribute('id', errorId);
            error.setAttribute('role', 'alert');
            error.textContent = config.error;
            container.appendChild(error);
        }

        return new ElementWrapper(container);
    }

    /**
     * Create an action button (type="button") with proper accessibility
     * @param {string} buttonText - Button text
     * @param {Object} [options] - Options
     * @param {string} options.icon - Icon classes
     * @param {string} options.class - Additional classes
     * @param {boolean} options.disabled - Disabled state
     * @param {boolean} options.loading - Loading state
     * @returns {ElementWrapper}
     *
     * @example
     * D.actionButton('Save', { icon: 'fas fa-save', class: 'btn btn-primary' })
     */
    function createActionButton(buttonText, options) {
        var opts = options || {};
        var el = document.createElement('button');
        el.setAttribute('type', 'button');

        if (opts.class) {
            el.className = opts.class;
        }

        if (opts.disabled || opts.loading) {
            el.setAttribute('disabled', '');
            el.setAttribute('aria-disabled', 'true');
        }

        if (opts.loading) {
            el.setAttribute('aria-busy', 'true');
            var spinner = createIcon('fas fa-spinner fa-spin');
            el.appendChild(spinner.el);
            el.appendChild(document.createTextNode(' '));
            el.appendChild(document.createTextNode(opts.loadingText || buttonText));
        } else {
            if (opts.icon) {
                var iconEl = createIcon(opts.icon);
                el.appendChild(iconEl.el);
                el.appendChild(document.createTextNode(' '));
            }
            el.appendChild(document.createTextNode(buttonText));
        }

        return new ElementWrapper(el);
    }

    /**
     * Create a submit button with proper accessibility
     * @param {string} buttonText - Button text
     * @param {Object} [options] - Options
     * @returns {ElementWrapper}
     */
    function createSubmitButton(buttonText, options) {
        var opts = options || {};
        var el = document.createElement('button');
        el.setAttribute('type', 'submit');

        if (opts.class) {
            el.className = opts.class;
        }

        if (opts.disabled || opts.loading) {
            el.setAttribute('disabled', '');
            el.setAttribute('aria-disabled', 'true');
        }

        if (opts.loading) {
            el.setAttribute('aria-busy', 'true');
            var spinner = createIcon('fas fa-spinner fa-spin');
            el.appendChild(spinner.el);
            el.appendChild(document.createTextNode(' '));
            el.appendChild(document.createTextNode(opts.loadingText || 'Submitting...'));
        } else {
            if (opts.icon) {
                var iconEl = createIcon(opts.icon);
                el.appendChild(iconEl.el);
                el.appendChild(document.createTextNode(' '));
            }
            el.appendChild(document.createTextNode(buttonText));
        }

        return new ElementWrapper(el);
    }

    /**
     * Create an icon-only button (requires aria-label)
     * @param {string} iconClass - Icon classes
     * @param {Object} options - Options (aria-label required)
     * @param {string} options['aria-label'] - Required accessible label
     * @param {string} options.class - Additional classes
     * @param {boolean} options.disabled - Disabled state
     * @returns {ElementWrapper}
     *
     * @example
     * D.iconButton('fas fa-trash', { 'aria-label': 'Delete item', class: 'btn btn-danger' })
     */
    function createIconButton(iconClass, options) {
        var opts = options || {};

        if (!opts['aria-label']) {
            console.error('[Funky.Dom] iconButton requires aria-label option for accessibility');
        }

        var el = document.createElement('button');
        el.setAttribute('type', 'button');

        if (opts['aria-label']) {
            el.setAttribute('aria-label', opts['aria-label']);
        }

        if (opts.class) {
            el.className = opts.class;
        }

        if (opts.disabled) {
            el.setAttribute('disabled', '');
            el.setAttribute('aria-disabled', 'true');
        }

        if (opts.title) {
            el.setAttribute('title', opts.title);
        }

        var iconEl = createIcon(iconClass);
        el.appendChild(iconEl.el);

        return new ElementWrapper(el);
    }

    /**
     * Create a skip target element with data attributes for Funky.SkipLink integration
     * The SkipLink component will automatically discover this target and create navigation
     *
     * @param {string} targetName - Skip target name (used in data-skip-target)
     * @param {string} label - Label for the skip link (shown in keyboard help)
     * @param {Object} [options] - Options
     * @param {number} options.order - Sort order for F-key shortcuts (default: 999)
     * @param {string} options.tag - HTML tag to create (default: 'div')
     * @param {string} options.id - Element ID (defaults to 'skip-' + targetName)
     * @returns {ElementWrapper}
     *
     * @example
     * // Create a skip target for the SkipLink component
     * D.skipTarget('intro', 'Introduction', { order: 1 })
     * // <div id="skip-intro" data-skip-target="intro" data-skip-label="Introduction" data-skip-order="1"></div>
     *
     * // As a section
     * D.skipTarget('content', 'Main Content', { tag: 'section', order: 2 })
     * // <section id="skip-content" data-skip-target="content" data-skip-label="Main Content" data-skip-order="2"></section>
     */
    function createSkipTarget(targetName, label, options) {
        var opts = options || {};
        var el = document.createElement(opts.tag || 'div');
        el.setAttribute('id', opts.id || 'skip-' + targetName);
        el.setAttribute('data-skip-target', targetName);
        el.setAttribute('data-skip-label', label);
        if (opts.order != null) {
            el.setAttribute('data-skip-order', opts.order);
        }
        return new ElementWrapper(el);
    }

    /**
     * Create an accessible search box with associated label
     * @param {Object} config - Search configuration
     * @param {string} config.id - Input ID (required)
     * @param {string} [config.label='Search'] - Label text
     * @param {string} [config.placeholder] - Placeholder text
     * @param {string} [config.name] - Input name (defaults to id)
     * @param {string} [config.class] - Additional classes for input
     * @param {boolean} [config.hideLabel=false] - Visually hide label
     * @param {string} [config.buttonText] - Submit button text (omit for no button)
     * @param {string} [config.buttonIcon] - Submit button icon (default: 'fas fa-search')
     * @returns {ElementWrapper}
     *
     * @example
     * D.searchBox({ id: 'site-search', placeholder: 'Search...' })
     * // <form role="search" class="search-form">
     * //   <label for="site-search" class="visually-hidden">Search</label>
     * //   <input type="search" id="site-search" role="searchbox" ...>
     * // </form>
     */
    function createSearchBox(config) {
        var searchId = config.id;
        var labelText = config.label || 'Search';

        // Form with role="search"
        var form = document.createElement('form');
        form.setAttribute('role', 'search');
        form.className = 'search-form' + (config.formClass ? ' ' + config.formClass : '');

        // Label (visually hidden by default)
        var labelEl = document.createElement('label');
        labelEl.setAttribute('for', searchId);
        labelEl.className = config.hideLabel !== false ? 'visually-hidden' : '';
        labelEl.textContent = labelText;
        form.appendChild(labelEl);

        // Input wrapper for styling
        var inputWrapper = document.createElement('div');
        inputWrapper.className = 'search-input-wrapper';

        // Search input
        var input = document.createElement('input');
        input.setAttribute('type', 'search');
        input.setAttribute('id', searchId);
        input.setAttribute('name', config.name || searchId);
        input.setAttribute('role', 'searchbox');
        input.className = 'form-control' + (config.class ? ' ' + config.class : '');

        if (config.placeholder) {
            input.setAttribute('placeholder', config.placeholder);
        }
        if (config.value) {
            input.setAttribute('value', config.value);
        }

        inputWrapper.appendChild(input);

        // Optional submit button
        if (config.buttonText || config.buttonIcon !== false) {
            var btn = document.createElement('button');
            btn.setAttribute('type', 'submit');
            btn.className = 'btn btn-search';

            var iconClass = config.buttonIcon || 'fas fa-search';
            var iconEl = createIcon(iconClass);
            btn.appendChild(iconEl.el);

            if (config.buttonText) {
                btn.appendChild(document.createTextNode(' ' + config.buttonText));
            } else {
                // Icon-only button needs aria-label
                btn.setAttribute('aria-label', labelText);
            }

            inputWrapper.appendChild(btn);
        }

        form.appendChild(inputWrapper);

        return new ElementWrapper(form);
    }

    /**
     * Create an accessible progress bar
     * @param {Object} config - Progress configuration
     * @param {number} config.value - Current value (0-100 or within min/max)
     * @param {number} [config.min=0] - Minimum value
     * @param {number} [config.max=100] - Maximum value
     * @param {string} [config.label] - Accessible label (required for screen readers)
     * @param {boolean} [config.showValue=false] - Show percentage text
     * @param {string} [config.class] - Additional classes
     * @param {string} [config.id] - Element ID
     * @returns {ElementWrapper}
     *
     * @example
     * D.progressBar({ value: 75, label: 'Upload progress' })
     * // <div role="progressbar" aria-valuenow="75" aria-valuemin="0" aria-valuemax="100" aria-label="Upload progress">
     * //   <div class="progress-fill" style="width: 75%"></div>
     * // </div>
     */
    function createProgressBar(config) {
        var value = config.value || 0;
        var min = config.min != null ? config.min : 0;
        var max = config.max != null ? config.max : 100;
        var percent = ((value - min) / (max - min)) * 100;

        var container = document.createElement('div');
        container.setAttribute('role', 'progressbar');
        container.setAttribute('aria-valuenow', value);
        container.setAttribute('aria-valuemin', min);
        container.setAttribute('aria-valuemax', max);
        container.className = 'progress' + (config.class ? ' ' + config.class : '');

        if (config.id) {
            container.setAttribute('id', config.id);
        }

        if (config.label) {
            container.setAttribute('aria-label', config.label);
        } else {
            console.warn('[Funky.Dom] progressBar should have a label for accessibility');
        }

        // Progress fill
        var fill = document.createElement('div');
        fill.className = 'progress-bar';
        fill.style.width = percent + '%';

        if (config.showValue) {
            fill.textContent = Math.round(percent) + '%';
        }

        container.appendChild(fill);

        return new ElementWrapper(container);
    }

    /**
     * Create an accessible loading indicator
     * @param {Object} [config] - Loading configuration
     * @param {string} [config.label='Loading'] - Accessible label
     * @param {string} [config.size] - Size class (e.g., 'sm', 'lg')
     * @param {boolean} [config.inline=false] - Inline spinner
     * @param {string} [config.class] - Additional classes
     * @returns {ElementWrapper}
     *
     * @example
     * D.loadingIndicator({ label: 'Loading results' })
     * // <div role="status" aria-busy="true" aria-label="Loading results" class="loading-indicator">
     * //   <span class="spinner" aria-hidden="true"></span>
     * //   <span class="visually-hidden">Loading results</span>
     * // </div>
     */
    function createLoadingIndicator(config) {
        var opts = config || {};
        var labelText = opts.label || 'Loading';

        var container = document.createElement('div');
        container.setAttribute('role', 'status');
        container.setAttribute('aria-busy', 'true');
        container.setAttribute('aria-label', labelText);
        container.className = 'loading-indicator' + (opts.class ? ' ' + opts.class : '');

        if (opts.inline) {
            container.classList.add('loading-inline');
        }

        // Spinner icon
        var spinnerClass = 'fas fa-spinner fa-spin';
        if (opts.size === 'sm') {
            spinnerClass += ' fa-sm';
        } else if (opts.size === 'lg') {
            spinnerClass += ' fa-lg';
        } else if (opts.size === 'xl') {
            spinnerClass += ' fa-2x';
        }

        var spinner = createIcon(spinnerClass);
        container.appendChild(spinner.el);

        // Visually hidden text for screen readers
        var srText = document.createElement('span');
        srText.className = 'visually-hidden';
        srText.textContent = labelText;
        container.appendChild(srText);

        return new ElementWrapper(container);
    }

    /**
     * Create an accessible alert box
     * @param {string} message - Alert message
     * @param {Object} [config] - Alert configuration
     * @param {string} [config.type='info'] - Alert type: 'info', 'success', 'warning', 'error'
     * @param {boolean} [config.dismissible=false] - Show dismiss button
     * @param {string} [config.icon] - Custom icon class
     * @param {string} [config.class] - Additional classes
     * @param {string} [config.id] - Element ID
     * @returns {ElementWrapper}
     *
     * @example
     * D.alertBox('Form submitted successfully', { type: 'success', dismissible: true })
     * // <div role="alert" class="alert alert-success">
     * //   <i class="fas fa-check-circle" aria-hidden="true"></i>
     * //   Form submitted successfully
     * //   <button type="button" aria-label="Dismiss alert">×</button>
     * // </div>
     */
    function createAlertBox(message, config) {
        var opts = config || {};
        var type = opts.type || 'info';

        // Map types to Bootstrap classes and icons
        var typeMap = {
            info: { class: 'alert-info', icon: 'fas fa-info-circle' },
            success: { class: 'alert-success', icon: 'fas fa-check-circle' },
            warning: { class: 'alert-warning', icon: 'fas fa-exclamation-triangle' },
            error: { class: 'alert-danger', icon: 'fas fa-exclamation-circle' }
        };

        var typeConfig = typeMap[type] || typeMap.info;

        var container = document.createElement('div');
        container.setAttribute('role', 'alert');
        container.className = 'alert ' + typeConfig.class + (opts.class ? ' ' + opts.class : '');

        if (opts.id) {
            container.setAttribute('id', opts.id);
        }

        if (opts.dismissible) {
            container.classList.add('alert-dismissible');
        }

        // Icon
        var iconClass = opts.icon || typeConfig.icon;
        var iconEl = createIcon(iconClass);
        container.appendChild(iconEl.el);
        container.appendChild(document.createTextNode(' '));

        // Message
        container.appendChild(document.createTextNode(message));

        // Dismiss button
        if (opts.dismissible) {
            var closeBtn = document.createElement('button');
            closeBtn.setAttribute('type', 'button');
            closeBtn.setAttribute('aria-label', 'Dismiss alert');
            closeBtn.className = 'btn-close';
            closeBtn.setAttribute('data-bs-dismiss', 'alert');
            container.appendChild(closeBtn);
        }

        return new ElementWrapper(container);
    }

    /**
     * Create an accessible modal dialog
     * @param {Object} config - Dialog configuration
     * @param {string} config.id - Dialog ID (required)
     * @param {string} config.title - Dialog title (required for accessibility)
     * @param {string|HTMLElement} [config.content] - Dialog body content
     * @param {Array} [config.buttons] - Footer button configurations
     * @param {boolean} [config.closeButton=true] - Show close button in header
     * @param {string} [config.size] - Size: 'sm', 'lg', 'xl', 'fullscreen'
     * @param {boolean} [config.centered=false] - Vertically centered
     * @param {string} [config.class] - Additional classes for dialog
     * @returns {ElementWrapper}
     *
     * @example
     * D.dialog({
     *   id: 'confirm-dialog',
     *   title: 'Confirm Action',
     *   content: 'Are you sure you want to proceed?',
     *   buttons: [
     *     { text: 'Cancel', class: 'btn btn-secondary', dismiss: true },
     *     { text: 'Confirm', class: 'btn btn-primary', id: 'confirm-btn' }
     *   ]
     * })
     */
    function createDialog(config) {
        var dialogId = config.id;
        var titleId = dialogId + '-title';

        // Backdrop
        var backdrop = document.createElement('div');
        backdrop.className = 'modal fade';
        backdrop.setAttribute('id', dialogId);
        backdrop.setAttribute('tabindex', '-1');
        backdrop.setAttribute('role', 'dialog');
        backdrop.setAttribute('aria-labelledby', titleId);
        backdrop.setAttribute('aria-modal', 'true');

        // Dialog container
        var dialogContainer = document.createElement('div');
        var sizeClass = config.size ? ' modal-' + config.size : '';
        var centeredClass = config.centered ? ' modal-dialog-centered' : '';
        dialogContainer.className = 'modal-dialog' + sizeClass + centeredClass;
        dialogContainer.setAttribute('role', 'document');

        // Content wrapper
        var content = document.createElement('div');
        content.className = 'modal-content' + (config.class ? ' ' + config.class : '');

        // Header
        var header = document.createElement('div');
        header.className = 'modal-header';

        var title = document.createElement('h5');
        title.className = 'modal-title';
        title.setAttribute('id', titleId);
        title.textContent = config.title;
        header.appendChild(title);

        if (config.closeButton !== false) {
            var closeBtn = document.createElement('button');
            closeBtn.setAttribute('type', 'button');
            closeBtn.className = 'btn-close';
            closeBtn.setAttribute('data-bs-dismiss', 'modal');
            closeBtn.setAttribute('aria-label', 'Close');
            header.appendChild(closeBtn);
        }

        content.appendChild(header);

        // Body
        var body = document.createElement('div');
        body.className = 'modal-body';

        if (config.content) {
            if (typeof config.content === 'string') {
                body.textContent = config.content;
            } else if (config.content instanceof HTMLElement) {
                body.appendChild(config.content);
            } else if (config.content instanceof ElementWrapper) {
                body.appendChild(config.content.el);
            }
        }

        content.appendChild(body);

        // Footer with buttons
        if (config.buttons && config.buttons.length > 0) {
            var footer = document.createElement('div');
            footer.className = 'modal-footer';

            for (var i = 0; i < config.buttons.length; i++) {
                var btnConfig = config.buttons[i];
                var btn = document.createElement('button');
                btn.setAttribute('type', 'button');
                btn.className = btnConfig.class || 'btn btn-secondary';

                if (btnConfig.id) {
                    btn.setAttribute('id', btnConfig.id);
                }

                if (btnConfig.dismiss) {
                    btn.setAttribute('data-bs-dismiss', 'modal');
                }

                if (btnConfig.icon) {
                    var btnIcon = createIcon(btnConfig.icon);
                    btn.appendChild(btnIcon.el);
                    btn.appendChild(document.createTextNode(' '));
                }

                btn.appendChild(document.createTextNode(btnConfig.text));
                footer.appendChild(btn);
            }

            content.appendChild(footer);
        }

        dialogContainer.appendChild(content);
        backdrop.appendChild(dialogContainer);

        return new ElementWrapper(backdrop);
    }

    // =========================================================================
    // Add Methods to ElementWrapper for Creation Chaining
    // =========================================================================

    /**
     * Set element ID
     * @param {string} value
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.id = function(value) {
        if (this.el && value != null) {
            this.el.id = value;
        }
        return this;
    };

    /**
     * Set element class (replaces existing)
     * @param {string} value
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.class = function(value) {
        if (this.el && value != null) {
            this.el.className = value;
        }
        return this;
    };

    /**
     * Set aria-* attribute
     * @param {string} name - Aria attribute name (without 'aria-' prefix)
     * @param {*} value
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.aria = function(name, value) {
        return this.attr('aria-' + name, value);
    };

    /**
     * Append multiple children
     * @param {...(ElementWrapper|HTMLElement|string|Array)} children
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.child = function() {
        if (!this.el) return this;
        for (var i = 0; i < arguments.length; i++) {
            var child = arguments[i];
            if (!child) continue;
            if (child instanceof ElementWrapper) {
                this.el.appendChild(child.el);
            } else if (child instanceof DocumentFragment) {
                // Handle DocumentFragment (e.g., from D.fragment())
                this.el.appendChild(child);
            } else if (child instanceof HTMLElement || child instanceof Text) {
                this.el.appendChild(child);
            } else if (child.el && (child.el instanceof HTMLElement || child.el instanceof Text)) {
                // Object with .el property (e.g., D.text() result)
                this.el.appendChild(child.el);
            } else if (typeof child === 'string' || typeof child === 'number') {
                this.el.appendChild(document.createTextNode(String(child)));
            } else if (Array.isArray(child)) {
                this.child.apply(this, child);
            } else if (child._isVNode || (child && typeof child.build === 'function')) {
                // VNode from Funky.VDom
                if (typeof child.build === 'function') {
                    child = child.build();
                }
                this.el.appendChild(Funky.VDom ? Funky.VDom.render(child) : child);
            }
        }
        return this;
    };

    /**
     * Append this element to a parent
     * @param {HTMLElement|string|ElementWrapper} parent - Element, selector, or ElementWrapper
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.appendTo = function(parent) {
        if (this.el) {
            var target;
            if (typeof parent === 'string') {
                target = document.querySelector(parent);
            } else if (parent && parent.el) {
                // Handle ElementWrapper
                target = parent.el;
            } else {
                target = parent;
            }
            if (target && target.appendChild) target.appendChild(this.el);
        }
        return this;
    };

    /**
     * Get the raw DOM element
     * Alias for .el for API consistency
     * @returns {HTMLElement}
     */
    ElementWrapper.prototype.get = function() {
        return this.el;
    };

    /**
     * Set unique key (stored as data-key for compatibility)
     * @param {string|number} value
     * @returns {ElementWrapper}
     */
    ElementWrapper.prototype.key = function(value) {
        return this.data('key', value);
    };

    // =========================================================================
    // Public API
    // =========================================================================

    var Dom = {
        /**
         * Select all matching elements
         * @param {string|NodeList|Array|HTMLElement} selector - CSS selector, NodeList, Array, or single element
         * @param {HTMLElement} [context] - Root element (defaults to document)
         * @returns {ElementList}
         */
        all: function(selector, context) {
            var elements;

            // Handle different input types
            if (typeof selector === 'string') {
                // Guard against empty selector
                if (!selector) {
                    return new ElementList([]);
                }
                // CSS selector string
                var root = context || document;
                elements = Array.prototype.slice.call(root.querySelectorAll(selector));
            } else if (selector && selector.nodeType) {
                // Single HTMLElement
                elements = [selector];
            } else if (selector && selector.length !== undefined) {
                // NodeList or Array
                elements = Array.prototype.slice.call(selector);
            } else {
                // Invalid input
                elements = [];
            }

            return new ElementList(elements);
        },

        /**
         * Select single element
         * @param {string|HTMLElement} selector - CSS selector or HTMLElement
         * @param {HTMLElement} [context] - Root element (defaults to document)
         * @returns {ElementWrapper} - Returns ElementWrapper (chainable even when no element found)
         */
        one: function(selector, context) {
            // If selector is already an HTMLElement, wrap it
            if (selector && selector.nodeType) {
                return new ElementWrapper(selector);
            }
            // Guard against null/empty selectors - return empty wrapper for chainability
            if (!selector || typeof selector !== 'string') {
                return new ElementWrapper(null);
            }
            var root = context || document;
            var el = root.querySelector(selector);
            // Always return wrapper for chainability (el may be null)
            return new ElementWrapper(el);
        },

        /**
         * Wrap existing element
         * @param {HTMLElement} element
         * @returns {ElementWrapper}
         */
        wrap: function(element) {
            return new ElementWrapper(element);
        },

        /**
         * Create element by tag name
         * @param {string} tag - HTML tag name
         * @returns {ElementWrapper}
         */
        create: createElement,

        /**
         * Create icon element with automatic ARIA
         * @param {string} iconClass - Icon class
         * @param {Object|string} [options] - Options or additional classes
         * @returns {ElementWrapper}
         */
        icon: createIcon,

        /**
         * Create a text node
         * @param {string} content - Text content
         * @returns {Object} Object with .el property
         */
        text: createText,

        /**
         * Parse raw HTML string and return element
         * @param {string} html - HTML string to parse
         * @returns {ElementWrapper}
         */
        raw: function(html) {
            if (!html || typeof html !== 'string') {
                return new ElementWrapper(document.createTextNode(''));
            }
            // Use createElement which already handles HTML parsing
            return createElement(html.charAt(0) === '<' ? html : '<span>' + html + '</span>');
        },

        // =====================================================================
        // Accessibility Helpers
        // =====================================================================

        /**
         * Create screen reader only text
         * @param {string} textContent - Text for screen readers
         * @returns {ElementWrapper}
         */
        srOnly: createSrOnly,

        /**
         * Create ARIA live region
         * @param {string} [mode='polite'] - 'polite' or 'assertive'
         * @param {string} [initialContent] - Initial content
         * @returns {ElementWrapper}
         */
        liveRegion: createLiveRegion,

        /**
         * Create accessible form label
         * @param {string} forId - ID of associated input
         * @param {string} labelText - Label text
         * @param {Object} [options] - Options
         * @returns {ElementWrapper}
         */
        label: createLabel,

        /**
         * Create complete accessible form field
         * @param {Object} config - Field configuration
         * @returns {ElementWrapper}
         */
        formField: createFormField,

        /**
         * Create action button (type="button")
         * @param {string} buttonText - Button text
         * @param {Object} [options] - Options
         * @returns {ElementWrapper}
         */
        actionButton: createActionButton,

        /**
         * Create submit button (type="submit")
         * @param {string} buttonText - Button text
         * @param {Object} [options] - Options
         * @returns {ElementWrapper}
         */
        submitButton: createSubmitButton,

        /**
         * Create icon-only button (requires aria-label)
         * @param {string} iconClass - Icon classes
         * @param {Object} options - Options with aria-label
         * @returns {ElementWrapper}
         */
        iconButton: createIconButton,

        /**
         * Create skip target for Funky.SkipLink component integration
         * @param {string} targetName - Skip target name
         * @param {string} label - Label for keyboard help
         * @param {Object} [options] - Options (order, tag, id)
         * @returns {ElementWrapper}
         */
        skipTarget: createSkipTarget,

        /**
         * Create an accessible search box with label and role="search"
         * @param {Object} config - Search configuration
         * @returns {ElementWrapper}
         */
        searchBox: createSearchBox,

        /**
         * Create an accessible progress bar with ARIA attributes
         * @param {Object} config - Progress configuration
         * @returns {ElementWrapper}
         */
        progressBar: createProgressBar,

        /**
         * Create an accessible loading indicator
         * @param {Object} [config] - Loading configuration
         * @returns {ElementWrapper}
         */
        loadingIndicator: createLoadingIndicator,

        /**
         * Create an accessible alert box with role="alert"
         * @param {string} message - Alert message
         * @param {Object} [config] - Alert configuration
         * @returns {ElementWrapper}
         */
        alertBox: createAlertBox,

        /**
         * Create an accessible modal dialog
         * @param {Object} config - Dialog configuration
         * @returns {ElementWrapper}
         */
        dialog: createDialog,

        /**
         * Create a document fragment with multiple children
         * @param {...(ElementWrapper|HTMLElement|string)} children - Children to append
         * @returns {DocumentFragment}
         */
        fragment: function() {
            var frag = document.createDocumentFragment();
            for (var i = 0; i < arguments.length; i++) {
                var child = arguments[i];
                if (!child) continue;
                if (child instanceof ElementWrapper) {
                    frag.appendChild(child.el);
                } else if (child instanceof HTMLElement || child instanceof Text || child instanceof DocumentFragment) {
                    frag.appendChild(child);
                } else if (child && child.el) {
                    frag.appendChild(child.el);
                } else if (typeof child === 'string' || typeof child === 'number') {
                    frag.appendChild(document.createTextNode(String(child)));
                }
            }
            return frag;
        },

        /**
         * Convert DOM element to VNode
         * Static version of virtualise
         * @param {HTMLElement} element
         * @param {boolean} [deep=true] - Include children
         * @returns {VNode}
         */
        virtualise: function(element, deep) {
            return virtualiseElement(element, deep !== false);
        },

        // Utility functions (matching VDom API)
        classes: classes,
        when: when,
        each: each,

        // Expose classes for advanced usage
        ElementWrapper: ElementWrapper,
        ElementList: ElementList
    };

    // =========================================================================
    // Tag Factory Methods
    // =========================================================================

    var tags = [
        // Structure
        'div', 'span', 'section', 'article', 'header', 'footer', 'main', 'nav', 'aside',
        // Text
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'a', 'strong', 'em', 'small', 'code', 'pre', 'blockquote',
        // Lists
        'ul', 'ol', 'li', 'dl', 'dt', 'dd',
        // Tables
        'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th', 'caption',
        // Forms
        'form', 'input', 'button', 'select', 'option', 'optgroup', 'textarea', 'label', 'fieldset', 'legend',
        // Media
        'img', 'video', 'audio', 'source', 'picture', 'canvas', 'svg', 'iframe',
        // Other
        'i', 'br', 'hr', 'kbd', 'mark', 'time', 'abbr', 'cite', 'figure', 'figcaption'
    ];

    for (var t = 0; t < tags.length; t++) {
        (function(tag) {
            if (tag === 'button') {
                // Button gets type="button" by default to prevent accidental form submissions
                // Use D.submitButton() for submit buttons, or .attr('type', 'submit') to override
                Dom[tag] = function() {
                    var el = createElement(tag);
                    el.attr('type', 'button');
                    return el;
                };
            } else {
                Dom[tag] = function() {
                    return createElement(tag);
                };
            }
        })(tags[t]);
    }

    // Register module
    Funky.register('Dom', Dom);

})(window);
