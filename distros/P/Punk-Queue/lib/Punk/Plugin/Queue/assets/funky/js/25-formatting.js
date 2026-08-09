/**
 * Funky Format - Number and Currency Formatting
 * 
 * Provides consistent formatting for:
 * - Numbers with locale-aware formatting
 * - Compact notation (K, M, B)
 * - Currency formatting
 * - Percentage formatting
 * - Automatic formatting via data attributes
 * 
 * Usage:
 *   Funky.Format.number(1234567.89);        // "1,234,567.89"
 *   Funky.Format.compact(1234567);          // "1.23M"
 *   Funky.Format.currency(1234.56, 'USD');  // "$1,234.56"
 *   Funky.Format.percentage(0.1234);        // "12.34%"
 *   Funky.Format.change(5.25);              // "+5.25%" (with color class)
 * 
 * Auto-format elements:
 *   <span data-format="number" data-value="1234567">Loading...</span>
 *   <span data-format="currency" data-value="1234.56" data-currency="GBP">Loading...</span>
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Format] Registry not found. Load namespace.js first.');
		return;
	}

	/**
	 * Default configuration
	 */
	var config = {
		locale: 'en-GB',
		defaultCurrency: 'GBP',
		decimalPlaces: 2,
		compactThreshold: 1000
	};

	/**
	 * FunkyFormat object
	 */
	var FunkyFormat = {

		/**
		 * Configure format settings
		 * @param {Object} options - Configuration options
		 */
		configure: function(options) {
			Object.assign(config, options);
		},

		/**
		 * Format a number with locale separators
		 * @param {number|string} value - The value to format
		 * @param {number} [decimals] - Number of decimal places
		 * @returns {string} Formatted number
		 */
		number: function(value, decimals) {
			var num = parseFloat(value);
			if (isNaN(num)) return '-';

			var decimalPlaces = decimals !== undefined ? decimals : config.decimalPlaces;

			return num.toLocaleString(config.locale, {
				minimumFractionDigits: decimalPlaces,
				maximumFractionDigits: decimalPlaces
			});
		},

		/**
		 * Format a number in compact notation (K, M, B)
		 * @param {number|string} value - The value to format
		 * @param {number} [decimals=2] - Number of decimal places
		 * @returns {string} Formatted compact number
		 */
		compact: function(value, decimals) {
			var num = parseFloat(value);
			if (isNaN(num)) return '-';

			var decimalPlaces = decimals !== undefined ? decimals : 2;
			var absNum = Math.abs(num);
			var suffix = '';
			var divisor = 1;

			if (absNum >= 1e9) {
				suffix = 'B';
				divisor = 1e9;
			} else if (absNum >= 1e6) {
				suffix = 'M';
				divisor = 1e6;
			} else if (absNum >= config.compactThreshold) {
				suffix = 'K';
				divisor = 1e3;
			}

			if (divisor > 1) {
				return (num / divisor).toFixed(decimalPlaces) + suffix;
			}

			return this.number(num, decimalPlaces);
		},

		/**
		 * Format a value as currency
		 * @param {number|string} value - The value to format
		 * @param {string} [currency] - Currency code (e.g., 'USD', 'GBP')
		 * @param {Object} [options] - Additional Intl.NumberFormat options
		 * @returns {string} Formatted currency string
		 */
		currency: function(value, currency, options) {
			var num = parseFloat(value);
			if (isNaN(num)) return '-';

			var currencyCode = currency || config.defaultCurrency;

			var formatOptions = Object.assign({
				style: 'currency',
				currency: currencyCode,
				minimumFractionDigits: 2,
				maximumFractionDigits: 2
			}, options || {});

			try {
				return num.toLocaleString(config.locale, formatOptions);
			} catch (e) {
				// Fallback for unsupported currencies
				return currencyCode + ' ' + this.number(num, 2);
			}
		},

		/**
		 * Format a value as percentage
		 * @param {number|string} value - The value to format (0.1 = 10%)
		 * @param {number} [decimals=2] - Number of decimal places
		 * @param {boolean} [isDecimal=true] - Whether input is decimal (0.1) or percentage (10)
		 * @returns {string} Formatted percentage string
		 */
		percentage: function(value, decimals, isDecimal) {
			var num = parseFloat(value);
			if (isNaN(num)) return '-';

			var decimalPlaces = decimals !== undefined ? decimals : 2;
			var shouldMultiply = isDecimal !== false;

			if (shouldMultiply) {
				num = num * 100;
			}

			return num.toFixed(decimalPlaces) + '%';
		},

		/**
		 * Format a change value with sign and color class
		 * @param {number|string} value - The change value
		 * @param {number} [decimals=2] - Number of decimal places
		 * @param {boolean} [asPercentage=true] - Format as percentage
		 * @returns {Object} Object with formatted value and colorClass
		 */
		change: function(value, decimals, asPercentage) {
			var num = parseFloat(value);
			if (isNaN(num)) {
				return { formatted: '-', colorClass: '', value: 0 };
			}

			var decimalPlaces = decimals !== undefined ? decimals : 2;
			var showPercent = asPercentage !== false;

			var sign = num > 0 ? '+' : '';
			var colorClass = num > 0 ? 'text-success' : (num < 0 ? 'text-danger' : 'text-muted');
			var formatted = sign + num.toFixed(decimalPlaces) + (showPercent ? '%' : '');

			return {
				formatted: formatted,
				colorClass: colorClass,
				value: num
			};
		},

		/**
		 * Format a date/time value
		 * @param {string|Date} value - The date value
		 * @param {Object} [options] - Intl.DateTimeFormat options
		 * @returns {string} Formatted date string
		 */
		date: function(value, options) {
			if (!value) return '-';

			var date = value instanceof Date ? value : new Date(value);
			if (isNaN(date.getTime())) return '-';

			var formatOptions = Object.assign({
				year: 'numeric',
				month: 'short',
				day: 'numeric'
			}, options || {});

			return date.toLocaleDateString(config.locale, formatOptions);
		},

		/**
		 * Format a date/time value with time
		 * @param {string|Date} value - The date value
		 * @param {Object} [options] - Intl.DateTimeFormat options
		 * @returns {string} Formatted datetime string
		 */
		datetime: function(value, options) {
			if (!value) return '-';

			var date = value instanceof Date ? value : new Date(value);
			if (isNaN(date.getTime())) return '-';

			var formatOptions = Object.assign({
				year: 'numeric',
				month: 'short',
				day: 'numeric',
				hour: '2-digit',
				minute: '2-digit'
			}, options || {});

			return date.toLocaleString(config.locale, formatOptions);
		},

		/**
		 * Format bytes to human readable size
		 * @param {number|string} bytes - Number of bytes
		 * @param {number} [decimals=2] - Number of decimal places
		 * @returns {string} Formatted size string
		 */
		fileSize: function(bytes, decimals) {
			var num = parseFloat(bytes);
			if (isNaN(num) || num === 0) return '0 Bytes';

			var decimalPlaces = decimals !== undefined ? decimals : 2;
			var k = 1024;
			var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
			var i = Math.floor(Math.log(num) / Math.log(k));

			return parseFloat((num / Math.pow(k, i)).toFixed(decimalPlaces)) + ' ' + sizes[i];
		},

		/**
		 * Auto-format elements with data-format attribute
		 * @param {string|Element} [container] - Container to search within
		 */
		autoFormat: function(container) {
			var self = this;
			var containerEl = container
				? (typeof container === 'string' ? document.querySelector(container) : container)
				: document;

			var elements = containerEl.querySelectorAll('[data-format]');
			elements.forEach(function(el) {
				var formatType = el.dataset.format;
				var value = el.dataset.value;
				var formatted = '-';

				switch (formatType) {
					case 'number':
						var numDecimals = el.dataset.decimals ? parseInt(el.dataset.decimals, 10) : undefined;
						formatted = self.number(value, numDecimals);
						break;

					case 'compact':
						var compactDecimals = el.dataset.decimals ? parseInt(el.dataset.decimals, 10) : undefined;
						formatted = self.compact(value, compactDecimals);
						break;

					case 'currency':
						var currency = el.dataset.currency;
						formatted = self.currency(value, currency);
						break;

					case 'percentage':
						var percDecimals = el.dataset.decimals ? parseInt(el.dataset.decimals, 10) : undefined;
						var isDecimal = el.dataset.decimal !== 'false';
						formatted = self.percentage(value, percDecimals, isDecimal);
						break;

					case 'change':
						var changeDecimals = el.dataset.decimals ? parseInt(el.dataset.decimals, 10) : undefined;
						var result = self.change(value, changeDecimals);
						formatted = result.formatted;
						el.classList.add(result.colorClass);
						break;

					case 'date':
						formatted = self.date(value);
						break;

					case 'datetime':
						formatted = self.datetime(value);
						break;

					case 'filesize':
						var sizeDecimals = el.dataset.decimals ? parseInt(el.dataset.decimals, 10) : undefined;
						formatted = self.fileSize(value, sizeDecimals);
						break;
				}

				el.textContent = formatted;
			});
		}
	};

	// Auto-format on document ready
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			Funky.Format.autoFormat();
		});
	} else {
		Funky.Format.autoFormat();
	}

	// Listen for SPA page loads (DOM event)
	document.addEventListener('funky.spa.pageload', function() {
		Funky.Format.autoFormat();
	});

	// Register with Funky namespace
	Funky.register('Format', FunkyFormat);

})(window);
