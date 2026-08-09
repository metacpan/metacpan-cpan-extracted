/**
 * Funky Namespace - Secure Namespace Foundation
 * 
 * Creates a frozen window.Funky namespace with a register() function
 * that locks components using Object.defineProperty to prevent override attacks.
 * 
 * ⚠️ THIS MUST BE LOADED BEFORE ANY OTHER FUNKY COMPONENTS
 */
(function(window) {
	'use strict';

	// Prevent re-initialization
	if (window.Funky) {
		console.warn('[Funky] Namespace already initialized');
		return;
	}

	// Create the Funky namespace object
	var Funky = Object.create(null);

	/**
	 * Register a component on the Funky namespace
	 * Once registered, components cannot be overwritten or deleted
	 * 
	 * @param {string} name - Component name (e.g., 'Audio', 'Toast', 'Api')
	 * @param {*} component - The component to register (object, function, class, etc.)
	 * @returns {boolean} - True if registration successful, false if already exists
	 */
	Funky.register = function(name, component) {
		if (typeof name !== 'string' || !name) {
			console.error('[Funky] Invalid component name:', name);
			return false;
		}

		if (name === 'register') {
			console.error('[Funky] Cannot override register function');
			return false;
		}

		if (Object.prototype.hasOwnProperty.call(Funky, name)) {
			console.warn('[Funky] Component already registered:', name);
			return false;
		}

		// Define the property as non-writable, non-configurable (locked)
		Object.defineProperty(Funky, name, {
			value: component,
			writable: false,
			configurable: false,
			enumerable: true
		});

		console.log('[Funky] Registered component:', name);
		return true;
	};

	/**
	 * Check if a component is registered
	 * 
	 * @param {string} name - Component name
	 * @returns {boolean}
	 */
	Funky.has = function(name) {
		return Object.prototype.hasOwnProperty.call(Funky, name);
	};

	// Alias for has()
	Funky.isRegistered = Funky.has;

	/**
	 * Get list of all registered component names
	 * 
	 * @returns {string[]}
	 */
	Funky.list = function() {
		var internalKeys = ['register', 'has', 'list', 'version', 'isRegistered'];
		return Object.keys(Funky).filter(function(key) {
			return internalKeys.indexOf(key) === -1;
		});
	};

	/**
	 * Version info
	 */
	Funky.version = '1.0.2';

	// Lock the register, has, list, and version properties
	Object.defineProperty(Funky, 'register', {
		writable: false,
		configurable: false
	});

	Object.defineProperty(Funky, 'has', {
		writable: false,
		configurable: false
	});

	Object.defineProperty(Funky, 'isRegistered', {
		writable: false,
		configurable: false
	});

	Object.defineProperty(Funky, 'list', {
		writable: false,
		configurable: false
	});

	Object.defineProperty(Funky, 'version', {
		writable: false,
		configurable: false
	});

	// Attach to window and lock it
	Object.defineProperty(window, 'Funky', {
		value: Funky,
		writable: false,
		configurable: false,
		enumerable: true
	});

	console.log('[Funky] Registry initialized v' + Funky.version);

})(window);
