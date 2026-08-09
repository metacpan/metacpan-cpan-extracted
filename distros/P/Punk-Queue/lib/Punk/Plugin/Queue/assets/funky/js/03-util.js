/**
 * Funky Utilities - Centralized utility functions
 * 
 * Common helpers used across multiple components:
 * - escapeHtml: XSS prevention
 * - formatNumber: Locale-aware number display
 * - abbreviateNumber: Compact K/M/B notation
 * - formatFileSize: Human-readable bytes
 * - toDom: Convert any content type to DOM nodes
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Util] Registry not found. Load namespace.js first.');
		return;
	}

	// Prevent double-registration
	if (Funky.isRegistered('Util')) {
		return;
	}

	var Util = {
		/**
		 * Escape HTML entities to prevent XSS attacks
		 * @param {string} text - Text to escape
		 * @returns {string} Escaped HTML string
		 */
		escapeHtml: function(text) {
			if (text == null) return '';
			var map = {
				'&': '&amp;',
				'<': '&lt;',
				'>': '&gt;',
				'"': '&quot;',
				"'": '&#039;'
			};
			return String(text).replace(/[&<>"']/g, function(m) { return map[m]; });
		},

		/**
		 * Format number with locale-aware separators
		 * @param {number} num - Number to format
		 * @param {number|Object} options - Decimal places (number) or Intl.NumberFormat options
		 * @returns {string} Formatted number string
		 */
		formatNumber: function(num, options) {
			if (num == null || isNaN(num)) return '';
			var opts;
			if (typeof options === 'number') {
				// Shorthand: second param is decimal places
				opts = {
					minimumFractionDigits: options,
					maximumFractionDigits: options
				};
			} else {
				var defaults = { maximumFractionDigits: 2 };
				opts = Object.assign({}, defaults, options);
			}
			return new Intl.NumberFormat(undefined, opts).format(num);
		},

		/**
		 * Abbreviate large numbers (1K, 1M, 1B, 1T)
		 * @param {number} num - Number to abbreviate
		 * @param {number} decimals - Decimal places (default: 1)
		 * @returns {string} Abbreviated number string
		 */
		abbreviateNumber: function(num, decimals) {
			if (num == null || isNaN(num)) return '';
			decimals = decimals !== undefined ? decimals : 1;

			var absNum = Math.abs(num);
			if (absNum < 1000) return String(num);

			var units = ['', 'K', 'M', 'B', 'T'];
			var unitIndex = Math.floor(Math.log10(absNum) / 3);
			unitIndex = Math.min(unitIndex, units.length - 1);

			var scaled = num / Math.pow(1000, unitIndex);
			return scaled.toFixed(decimals).replace(/\.0+$/, '') + units[unitIndex];
		},

		/**
		 * Format bytes into human-readable file size
		 * @param {number} bytes - File size in bytes
		 * @param {number} decimals - Decimal places (default: 2)
		 * @returns {string} Formatted file size (e.g., "1.5 MB")
		 */
		formatFileSize: function(bytes, decimals) {
			if (bytes == null || isNaN(bytes) || bytes === 0) return '0 Bytes';
			decimals = decimals !== undefined ? decimals : 2;

			var k = 1024;
			var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
			var i = Math.floor(Math.log(bytes) / Math.log(k));
			i = Math.min(i, sizes.length - 1);

			return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
		},

		/**
		 * Convert any content type to DOM node(s)
		 * Normalizes strings, HTML, DOM elements, Funky.Dom wrappers, and Funky.VDom nodes
		 * 
		 * @param {string|Node|Object|Array} content - Content to convert
		 * @returns {Node|DocumentFragment} DOM node ready for appendChild
		 * 
		 * @example
		 * // All of these work:
		 * Funky.Util.toDom('Hello world');                    // Text node
		 * Funky.Util.toDom('<strong>Bold</strong>');          // Parsed HTML
		 * Funky.Util.toDom(document.createElement('div'));    // Passthrough
		 * Funky.Util.toDom(D.div().text('Hello'));            // Dom wrapper
		 * Funky.Util.toDom(VDom.h('div', {}, 'Hello'));       // VDom node
		 * Funky.Util.toDom([item1, item2, item3]);            // DocumentFragment
		 */
		toDom: function(content) {
			// Null/undefined → empty text node
			if (content == null) {
				return document.createTextNode('');
			}

			// Already a DOM Node → return as-is
			if (content instanceof Node) {
				return content;
			}

			// Array → convert each item and wrap in DocumentFragment
			if (Array.isArray(content)) {
				var fragment = document.createDocumentFragment();
				for (var i = 0; i < content.length; i++) {
					var child = this.toDom(content[i]);
					if (child) {
						fragment.appendChild(child);
					}
				}
				return fragment;
			}

			// Funky.Dom wrapper (has .el property that is a Node)
			if (content.el instanceof Node) {
				return content.el;
			}

			// Funky.VDom node (has _isVNode flag)
			if (content._isVNode === true) {
				// Use VDom.render if available
				if (Funky.VDom && typeof Funky.VDom.render === 'function') {
					return Funky.VDom.render(content);
				}
				// Fallback: basic VNode rendering
				return this._renderVNode(content);
			}

			// String → check if HTML or plain text
			if (typeof content === 'string') {
				var trimmed = content.trim();
				// Check if it looks like HTML (starts with < and ends with >)
				if (trimmed.charAt(0) === '<' && trimmed.charAt(trimmed.length - 1) === '>') {
					var temp = document.createElement('div');
					temp.innerHTML = content;
					// If single element, return it; otherwise return fragment
					if (temp.childNodes.length === 1) {
						return temp.firstChild;
					}
					var fragment = document.createDocumentFragment();
					while (temp.firstChild) {
						fragment.appendChild(temp.firstChild);
					}
					return fragment;
				}
				// Plain text
				return document.createTextNode(content);
			}

			// Number/boolean → convert to text
			if (typeof content === 'number' || typeof content === 'boolean') {
				return document.createTextNode(String(content));
			}

			// Unknown type → empty text node
			console.warn('[Funky.Util.toDom] Unknown content type:', typeof content, content);
			return document.createTextNode('');
		},

		/**
		 * Basic VNode rendering fallback (when VDom not loaded)
		 * @private
		 */
		_renderVNode: function(vnode) {
			if (vnode.type === '#text') {
				return document.createTextNode(vnode.text || '');
			}

			var el = document.createElement(vnode.tag || 'div');

			// Apply props
			if (vnode.props) {
				var props = vnode.props;
				for (var key in props) {
					if (!props.hasOwnProperty(key)) continue;
					var value = props[key];

					if (key === 'class' || key === 'className') {
						el.className = value;
					} else if (key === 'style' && typeof value === 'object') {
						for (var styleProp in value) {
							el.style[styleProp] = value[styleProp];
						}
					} else if (key.indexOf('on') === 0) {
						// Event handlers
						var eventName = key.slice(2).toLowerCase();
						el.addEventListener(eventName, value);
					} else if (key.indexOf('data-') === 0 || key.indexOf('aria-') === 0) {
						el.setAttribute(key, value);
					} else {
						el.setAttribute(key, value);
					}
				}
			}

			// Render children
			if (vnode.children) {
				for (var i = 0; i < vnode.children.length; i++) {
					var child = vnode.children[i];
					if (child != null) {
						el.appendChild(this._renderVNode(child));
					}
				}
			}

			return el;
		},

		// =========================================================================
		// WCAG CONTRAST CHECKER
		// =========================================================================

		/**
		 * Parse CSS color to RGB object
		 * Supports: hex (#RGB, #RRGGBB), rgb(), rgba(), named colors
		 * @param {string} color - CSS color string
		 * @returns {Object} {r, g, b} values 0-255
		 */
		parseColor: function(color) {
			if (!color) return null;

			color = color.trim().toLowerCase();

			// Hex color (#RGB or #RRGGBB)
			if (color.charAt(0) === '#') {
				var hex = color.slice(1);
				// Expand shorthand (#RGB → #RRGGBB)
				if (hex.length === 3) {
					hex = hex.charAt(0) + hex.charAt(0) + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2);
				}
				return {
					r: parseInt(hex.slice(0, 2), 16),
					g: parseInt(hex.slice(2, 4), 16),
					b: parseInt(hex.slice(4, 6), 16)
				};
			}

			// rgb() or rgba()
			var rgbMatch = color.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
			if (rgbMatch) {
				return {
					r: parseInt(rgbMatch[1], 10),
					g: parseInt(rgbMatch[2], 10),
					b: parseInt(rgbMatch[3], 10)
				};
			}

			// Named colors (common subset)
			var namedColors = {
				'white': {r: 255, g: 255, b: 255},
				'black': {r: 0, g: 0, b: 0},
				'red': {r: 255, g: 0, b: 0},
				'green': {r: 0, g: 128, b: 0},
				'blue': {r: 0, g: 0, b: 255},
				'yellow': {r: 255, g: 255, b: 0},
				'cyan': {r: 0, g: 255, b: 255},
				'magenta': {r: 255, g: 0, b: 255},
				'gray': {r: 128, g: 128, b: 128},
				'grey': {r: 128, g: 128, b: 128}
			};

			return namedColors[color] || null;
		},

		/**
		 * Calculate relative luminance per WCAG formula
		 * https://www.w3.org/WAI/GL/wiki/Relative_luminance
		 * @param {number} r - Red value 0-255
		 * @param {number} g - Green value 0-255
		 * @param {number} b - Blue value 0-255
		 * @returns {number} Relative luminance 0-1
		 */
		relativeLuminance: function(r, g, b) {
			// Convert to 0-1 range
			var rsRGB = r / 255;
			var gsRGB = g / 255;
			var bsRGB = b / 255;

			// Apply gamma correction
			var rLinear = rsRGB <= 0.03928 ? rsRGB / 12.92 : Math.pow((rsRGB + 0.055) / 1.055, 2.4);
			var gLinear = gsRGB <= 0.03928 ? gsRGB / 12.92 : Math.pow((gsRGB + 0.055) / 1.055, 2.4);
			var bLinear = bsRGB <= 0.03928 ? bsRGB / 12.92 : Math.pow((bsRGB + 0.055) / 1.055, 2.4);

			// Calculate luminance
			return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
		},

		/**
		 * Calculate contrast ratio between two colors
		 * https://www.w3.org/WAI/GL/wiki/Contrast_ratio
		 * @param {string} color1 - Foreground color
		 * @param {string} color2 - Background color
		 * @returns {number} Contrast ratio 1-21
		 */
		contrastRatio: function(color1, color2) {
			var rgb1 = this.parseColor(color1);
			var rgb2 = this.parseColor(color2);

			if (!rgb1 || !rgb2) {
				console.warn('[Funky.Util.contrastRatio] Invalid color:', color1, color2);
				return 0;
			}

			var lum1 = this.relativeLuminance(rgb1.r, rgb1.g, rgb1.b);
			var lum2 = this.relativeLuminance(rgb2.r, rgb2.g, rgb2.b);

			// Ensure lighter color is in numerator
			var lighter = Math.max(lum1, lum2);
			var darker = Math.min(lum1, lum2);

			return (lighter + 0.05) / (darker + 0.05);
		},

		/**
		 * Check if contrast meets WCAG standards
		 * @param {string} foreground - Foreground color (text)
		 * @param {string} background - Background color
		 * @param {Object} options - Options
		 * @param {string} options.level - 'AA' or 'AAA' (default: 'AA')
		 * @param {boolean} options.largeText - Is text large (18pt+ or 14pt+ bold)? (default: false)
		 * @returns {Object} { ratio, passAA, passAALarge, passAAA, passAAALarge }
		 *
		 * @example
		 * var result = Funky.Util.checkContrast('#333', '#fff');
		 * // { ratio: 12.63, passAA: true, passAALarge: true, passAAA: true, passAAALarge: true }
		 *
		 * var result = Funky.Util.checkContrast('#777', '#fff');
		 * // { ratio: 4.47, passAA: false, passAALarge: true, passAAA: false, passAAALarge: false }
		 */
		checkContrast: function(foreground, background, options) {
			var opts = options || {};
			var ratio = this.contrastRatio(foreground, background);

			// WCAG 2.1 Level AA requirements
			var AA_NORMAL = 4.5;  // Normal text (under 18pt or 14pt bold)
			var AA_LARGE = 3.0;   // Large text (18pt+ or 14pt+ bold)

			// WCAG 2.1 Level AAA requirements
			var AAA_NORMAL = 7.0;
			var AAA_LARGE = 4.5;

			var passAA = ratio >= (opts.largeText ? AA_LARGE : AA_NORMAL);
			var passAALarge = ratio >= AA_LARGE;
			var passAAA = ratio >= (opts.largeText ? AAA_LARGE : AAA_NORMAL);
			var passAAALarge = ratio >= AAA_LARGE;

			return {
				ratio: Math.round(ratio * 100) / 100,  // Round to 2 decimals
				passAA: passAA,
				passAALarge: passAALarge,
				passAAA: passAAA,
				passAAALarge: passAAALarge,
				// Grouped passes object for easier access
				passes: {
					AA: passAA,
					AALarge: passAALarge,
					AAA: passAAA,
					AAALarge: passAAALarge
				}
			};
		}
	};

	// Register with Funky namespace
	Funky.register('Util', Util);

})(window);
