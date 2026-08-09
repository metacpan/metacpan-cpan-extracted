/**
 * Funky Sparkline - Lightweight SVG Sparkline Charts
 * 
 * Mini trend indicators for stat cards and inline data visualization:
 * - Line sparklines with fill
 * - Bar sparklines
 * - Auto-trend detection (positive/negative/neutral)
 * - Auto-initialization via data attributes
 * 
 * Usage:
 *   Funky.Charts.line(container, [1,2,3,4,5], { width: 80, height: 30 });
 *   Funky.Charts.bar(container, [1,2,3,4,5], { color: 'positive' });
 * 
 * Auto-init:
 *   <span data-sparkline="line" data-values="1,2,3,4,5"></span>
 *   <span data-sparkline="bar" data-values="5,4,3,2,1" data-color="negative"></span>
 * 
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Charts] Registry not found. Load namespace.js first.');
		return;
	}

	var FunkySparkline = {
		/**
		 * Create a line sparkline
		 * @param {HTMLElement} container - Container element
		 * @param {Array<number>} data - Array of numeric values
		 * @param {Object} options - Sparkline options
		 */
		line: function(container, data, options) {
			options = options || {};
			if (!container || !data || data.length < 2) return;

			var width = options.width || 80;
			var height = options.height || 30;
			var strokeWidth = options.strokeWidth || 2;
			var trend = this.getTrend(data);
			var colorClass = options.color || trend;

			var min = Math.min.apply(null, data);
			var max = Math.max.apply(null, data);
			var range = max - min || 1;

			// Calculate points
			var points = data.map(function(value, i) {
				var x = (i / (data.length - 1)) * width;
				var y = height - ((value - min) / range) * (height - strokeWidth * 2) - strokeWidth;
				return x + ',' + y;
			}).join(' ');

			// Create area path (for fill)
			var areaPoints = data.map(function(value, i) {
				var x = (i / (data.length - 1)) * width;
				var y = height - ((value - min) / range) * (height - strokeWidth * 2) - strokeWidth;
				return (i === 0 ? 'L' : ' L') + x + ',' + y;
			}).join('');

			var areaPath = 'M0,' + height + ' ' + areaPoints + ' L' + width + ',' + height + ' Z';

			// Generate accessible label
			var trendLabel = trend === 'positive' ? 'upward' : (trend === 'negative' ? 'downward' : 'stable');
			var ariaLabel = options.ariaLabel || 'Sparkline chart showing ' + trendLabel + ' trend from ' + data[0] + ' to ' + data[data.length - 1];

			var svg = '<svg width="' + width + '" height="' + height + '" viewBox="0 0 ' + width + ' ' + height + '" preserveAspectRatio="none" role="img" aria-label="' + ariaLabel + '">' +
				'<path class="sparkline-area ' + colorClass + '" d="' + areaPath + '"/>' +
				'<polyline class="sparkline-line ' + colorClass + '" points="' + points + '" fill="none"/>' +
				'</svg>';

			container.innerHTML = svg;
		},

		/**
		 * Create a bar sparkline
		 * @param {HTMLElement} container - Container element
		 * @param {Array<number>} data - Array of numeric values
		 * @param {Object} options - Sparkline options
		 */
		bar: function(container, data, options) {
			options = options || {};
			if (!container || !data || data.length < 1) return;

			var width = options.width || 80;
			var height = options.height || 30;
			var gap = options.gap || 2;
			var trend = this.getTrend(data);
			var colorClass = options.color || trend;

			var min = Math.min.apply(null, data.concat([0]));
			var max = Math.max.apply(null, data);
			var range = max - min || 1;

			var barWidth = (width - gap * (data.length - 1)) / data.length;

			var bars = data.map(function(value, i) {
				var barHeight = ((value - min) / range) * height;
				var x = i * (barWidth + gap);
				var y = height - barHeight;
				return '<rect class="sparkline-bar ' + colorClass + '" x="' + x + '" y="' + y + '" width="' + barWidth + '" height="' + barHeight + '"/>';
			}).join('');

			// Generate accessible label
			var trendLabel = trend === 'positive' ? 'upward' : (trend === 'negative' ? 'downward' : 'stable');
			var ariaLabel = options.ariaLabel || 'Bar sparkline chart showing ' + trendLabel + ' trend with ' + data.length + ' data points';

			var svg = '<svg width="' + width + '" height="' + height + '" viewBox="0 0 ' + width + ' ' + height + '" role="img" aria-label="' + ariaLabel + '">' +
				bars +
				'</svg>';

			container.innerHTML = svg;
		},

		/**
		 * Determine trend from data (positive, negative, neutral)
		 */
		getTrend: function(data) {
			if (!data || data.length < 2) return 'neutral';
			var first = data[0];
			var last = data[data.length - 1];
			if (last > first) return 'positive';
			if (last < first) return 'negative';
			return 'neutral';
		},

		/**
		 * Auto-initialize sparklines from data attributes
		 */
		autoInit: function(container) {
			var self = this;
			container = container || document;
			var elements = container.querySelectorAll('[data-sparkline]');

			elements.forEach(function(el) {
				var type = el.getAttribute('data-sparkline') || 'line';
				var dataStr = el.getAttribute('data-values');
				if (!dataStr) return;

				var data = dataStr.split(',').map(function(v) {
					return parseFloat(v.trim());
				}).filter(function(v) {
					return !isNaN(v);
				});

				if (data.length < 2) return;

				var options = {
					width: parseInt(el.getAttribute('data-width')) || 80,
					height: parseInt(el.getAttribute('data-height')) || 30,
					color: el.getAttribute('data-color')
				};

				if (type === 'bar') {
					self.bar(el, data, options);
				} else {
					self.line(el, data, options);
				}
			});
		}
	};

	// Auto-init on document ready
	document.addEventListener('DOMContentLoaded', function() {
		FunkySparkline.autoInit();
	});

	// Re-init after SPA navigation
	document.addEventListener('funky.spa.pageload', function() {
		FunkySparkline.autoInit();
	});

	// Re-init after AJAX updates
	document.addEventListener('funky.content-updated', function(e) {
		var container = e.detail && e.detail.container ? e.detail.container : document;
		FunkySparkline.autoInit(container);
	});

	// Register with Funky namespace
	Funky.register('Charts', FunkySparkline);

})(window);
