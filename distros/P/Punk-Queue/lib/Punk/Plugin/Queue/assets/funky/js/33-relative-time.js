/**
 * Funky.RelativeTime
 * 
 * Auto-updating relative time display.
 * Converts ISO datetimes to "2 hours ago" format.
 * 
 * @example
 * <time datetime="2025-12-24T10:30:00Z" data-relative>10:30 AM</time>
 */
(function(window) {
    'use strict';

    // Ensure Funky registry exists
    if (!window.Funky || !window.Funky.register) {
        console.error('[Funky.RelativeTime] Registry not found. Load namespace.js first.');
        return;
    }

    var D = Funky.Dom;
    var E = Funky.Events;

    var SELECTOR = 'time[data-relative]';
    var instances = [];

    // Timer state
    var refreshTimer = null;
    var isPaused = false;
    var lastRefresh = 0;
    var visibilityListenerAdded = false;

    // Observer state
    var observer = null;
    var dataTableIntegrationSetup = false;

    // Time constants
    var SECOND = 1000;
    var MINUTE = 60 * SECOND;
    var HOUR = 60 * MINUTE;
    var DAY = 24 * HOUR;
    var WEEK = 7 * DAY;

    // Configuration
    var config = {
        refreshInterval: 60000,
        thresholdDays: 30,
        showSeconds: false,  // Show "X seconds ago" for 5-59s
        locale: (typeof navigator !== 'undefined' && navigator.language) || 'en-US',
        formats: {
            justNow: 'just now',
            yesterday: 'yesterday',
            tomorrow: 'tomorrow'
        }
    };

    // Intl formatters (initialized lazily)
    var rtf = null;
    var dtfShort = null;
    var dtfFull = null;

    /**
     * Initialize Intl formatters
     */
    function initFormatters() {
        if (typeof Intl === 'undefined') return;

        if (!rtf && Intl.RelativeTimeFormat) {
            try {
                rtf = new Intl.RelativeTimeFormat(config.locale, { numeric: 'auto' });
            } catch (e) {
                // Fallback if locale not supported
            }
        }

        if (!dtfShort && Intl.DateTimeFormat) {
            try {
                dtfShort = new Intl.DateTimeFormat(config.locale, {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                });
            } catch (e) {
                // Fallback
            }
        }

        if (!dtfFull && Intl.DateTimeFormat) {
            try {
                dtfFull = new Intl.DateTimeFormat(config.locale, {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: 'numeric',
                    minute: 'numeric'
                });
            } catch (e) {
                // Fallback
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // Time Calculation
    // ─────────────────────────────────────────────────────────────────

    /**
     * Calculate relative time from a date
     * @param {Date|string} date - Date to compare
     * @returns {Object|null} { value, unit, isPast, special?, absolute?, date? }
     */
    function getRelativeTime(date) {
        if (typeof date === 'string') {
            date = new Date(date);
        }

        if (!date || isNaN(date.getTime())) {
            return null;
        }

        var now = new Date();
        var diff = now.getTime() - date.getTime();
        var isPast = diff > 0;
        var absDiff = Math.abs(diff);

        // Less than a minute
        if (absDiff < MINUTE) {
            var seconds = Math.floor(absDiff / SECOND);
            
            // Always show "just now" for < 5 seconds
            if (seconds < 5) {
                return { value: 0, unit: 'second', isPast: isPast, special: 'justNow' };
            }
            
            // Show seconds if enabled (via config or element override)
            if (config.showSeconds || config._elementShowSeconds) {
                return { value: seconds, unit: 'second', isPast: isPast };
            }
            
            // Default: "just now" for anything under a minute
            return { value: 0, unit: 'second', isPast: isPast, special: 'justNow' };
        }

        // Less than an hour
        if (absDiff < HOUR) {
            return { value: Math.floor(absDiff / MINUTE), unit: 'minute', isPast: isPast };
        }

        // Less than a day
        if (absDiff < DAY) {
            return { value: Math.floor(absDiff / HOUR), unit: 'hour', isPast: isPast };
        }

        // Check for yesterday/tomorrow
        var daysDiff = Math.floor(absDiff / DAY);
        if (daysDiff === 1) {
            return { 
                value: 1, 
                unit: 'day', 
                isPast: isPast, 
                special: isPast ? 'yesterday' : 'tomorrow' 
            };
        }

        // Less than a week
        if (absDiff < WEEK) {
            return { value: daysDiff, unit: 'day', isPast: isPast };
        }

        // Within threshold
        if (daysDiff < config.thresholdDays) {
            return { value: Math.floor(absDiff / WEEK), unit: 'week', isPast: isPast };
        }

        // Beyond threshold - return absolute date
        return { absolute: true, date: date };
    }

    // ─────────────────────────────────────────────────────────────────
    // Formatting
    // ─────────────────────────────────────────────────────────────────

    /**
     * Format relative time object to string
     * @param {Object} relative - From getRelativeTime()
     * @returns {string}
     */
    function formatRelative(relative) {
        if (!relative) return '';

        // Handle absolute dates (beyond threshold)
        if (relative.absolute) {
            if (dtfShort) {
                return dtfShort.format(relative.date);
            }
            return relative.date.toLocaleDateString();
        }

        // Handle special cases
        if (relative.special && config.formats[relative.special]) {
            return config.formats[relative.special];
        }

        // Use Intl.RelativeTimeFormat if available
        if (rtf) {
            var value = relative.isPast ? -relative.value : relative.value;
            return rtf.format(value, relative.unit);
        }

        // ES5 fallback
        return formatRelativeFallback(relative);
    }

    /**
     * ES5 fallback for relative time formatting
     * @param {Object} relative
     * @returns {string}
     */
    function formatRelativeFallback(relative) {
        var value = relative.value;
        var unit = relative.unit;
        var plural = value !== 1 ? 's' : '';

        if (relative.isPast) {
            if (value === 0 && unit === 'second') {
                return config.formats.justNow;
            }
            return value + ' ' + unit + plural + ' ago';
        } else {
            return 'in ' + value + ' ' + unit + plural;
        }
    }

    /**
     * Format full date for tooltip
     * @param {string|Date} datetime - ISO datetime or Date
     * @returns {string}
     */
    function formatFullDate(datetime) {
        var date = typeof datetime === 'string' ? new Date(datetime) : datetime;
        
        if (!date || isNaN(date.getTime())) {
            return String(datetime);
        }

        if (dtfFull) {
            return dtfFull.format(date);
        }

        return date.toLocaleString();
    }

    // ─────────────────────────────────────────────────────────────────
    // Timer System
    // ─────────────────────────────────────────────────────────────────

    /**
     * Start the global refresh timer
     */
    function startTimer() {
        if (refreshTimer) return;

        refreshTimer = setInterval(function() {
            if (!isPaused) {
                refreshAll();
            }
        }, config.refreshInterval);
    }

    /**
     * Stop the global refresh timer
     */
    function stopTimer() {
        if (refreshTimer) {
            clearInterval(refreshTimer);
            refreshTimer = null;
        }
    }

    /**
     * Refresh all tracked elements
     */
    function refreshAll() {
        var now = Date.now();

        for (var i = instances.length - 1; i >= 0; i--) {
            var el = instances[i];

            // Remove if not in DOM
            if (!document.contains(el)) {
                instances.splice(i, 1);
                continue;
            }

            // Skip if refresh disabled
            if (el._refreshDisabled) continue;

            // Check custom interval
            var interval = el._refreshInterval || config.refreshInterval;
            var elLastRefresh = el._lastRefresh || 0;

            if (now - elLastRefresh >= interval) {
                processElement(el);
                el._lastRefresh = now;
            }
        }

        lastRefresh = now;

        // Stop timer if no instances left
        if (instances.length === 0) {
            stopTimer();
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // Page Visibility API
    // ─────────────────────────────────────────────────────────────────

    /**
     * Handle visibility change
     */
    function handleVisibilityChange() {
        if (document.hidden) {
            isPaused = true;
            E.emit(document, 'funky.relative-time.hidden', {
                instanceCount: instances.length
            });
        } else {
            isPaused = false;
            // Refresh immediately when tab becomes visible
            refreshAll();
            E.emit(document, 'funky.relative-time.visible', {
                instanceCount: instances.length
            });
        }
    }

    /**
     * Set up visibility listener
     */
    function setupVisibilityListener() {
        if (visibilityListenerAdded) return;
        
        if (typeof document.hidden !== 'undefined') {
            document.addEventListener('visibilitychange', handleVisibilityChange);
            visibilityListenerAdded = true;
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MutationObserver
    // ─────────────────────────────────────────────────────────────────

    /**
     * Start observing DOM for new elements
     */
    function startObserver() {
        if (observer) return;
        if (typeof MutationObserver === 'undefined') return;

        observer = new MutationObserver(function(mutations) {
            var shouldInit = false;

            for (var i = 0; i < mutations.length; i++) {
                var mutation = mutations[i];

                // Check added nodes
                for (var j = 0; j < mutation.addedNodes.length; j++) {
                    var node = mutation.addedNodes[j];
                    if (node.nodeType !== 1) continue; // Element nodes only

                    // Check if the node itself matches
                    if (node.matches && node.matches(SELECTOR)) {
                        shouldInit = true;
                        break;
                    }

                    // Check descendants
                    if (node.querySelectorAll && node.querySelectorAll(SELECTOR).length > 0) {
                        shouldInit = true;
                        break;
                    }
                }

                if (shouldInit) break;
            }

            if (shouldInit) {
                // Debounce to batch rapid additions
                clearTimeout(observer._debounce);
                observer._debounce = setTimeout(function() {
                    init();
                }, 50);
            }
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    /**
     * Stop observing
     */
    function stopObserver() {
        if (observer) {
            clearTimeout(observer._debounce);
            observer.disconnect();
            observer = null;
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // DataTable Integration
    // ─────────────────────────────────────────────────────────────────

    /**
     * Set up DataTable integration
     */
    function setupDataTableIntegration() {
        if (dataTableIntegrationSetup) return;
        dataTableIntegrationSetup = true;

        // Listen for DataTable draw events (Funky.DataTables)
        document.addEventListener('funky.datatable.draw', function(e) {
            var tableId = e.detail && e.detail.tableId;
            if (tableId) {
                var table = document.getElementById(tableId);
                if (table) {
                    init(table);
                }
            } else {
                init();
            }
        });

        // Also listen for jQuery DataTables if available
        if (typeof $ !== 'undefined' && $.fn && $.fn.dataTable) {
            $(document).on('draw.dt', function(e, settings) {
                var tableEl = settings.nTable;
                if (tableEl) {
                    init(tableEl);
                }
            });
        }
    }

    /**
     * Escape HTML for safe insertion
     * @param {string} str
     * @returns {string}
     */
    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    /**
     * DataTable column renderer for relative time
     * @param {Object} [options]
     * @param {string} [options.format] - 'relative', 'absolute', 'both'
     * @param {boolean} [options.refresh] - Enable auto-refresh (default: true)
     * @returns {Function} DataTables render function
     */
    function dtRenderer(options) {
        options = options || {};
        var refresh = options.refresh !== false;

        return function(data, type, row) {
            // For sorting/filtering, return raw value
            if (type === 'sort' || type === 'filter') {
                return data;
            }

            if (!data) return '';

            var refreshAttr = refresh ? '' : ' data-refresh="false"';
            var html = '<time datetime="' + escapeHtml(data) + '" data-relative' + refreshAttr + '>';

            // Initial content before JS runs
            html += escapeHtml(data);
            html += '</time>';

            return html;
        };
    }

    // ─────────────────────────────────────────────────────────────────
    // LiveBinding Integration
    // ─────────────────────────────────────────────────────────────────

    /**
     * Create a time element bound to a LiveBinding value
     * @param {Object} options
     * @param {string} options.source - LiveBinding source ('api', 'state', 'event')
     * @param {string} [options.url] - API URL for 'api' source
     * @param {string} [options.event] - Event name for 'event' source
     * @param {string} [options.path] - Data path to datetime value
     * @returns {HTMLElement}
     */
    function createBound(options) {
        var el = document.createElement('time');
        el.setAttribute('data-relative', '');

        if (!Funky.LiveBinding) {
            console.warn('[RelativeTime] LiveBinding not available');
            return el;
        }

        // Bind the datetime attribute
        Funky.LiveBinding.bind(el, {
            source: options.source,
            url: options.url,
            event: options.event,
            attribute: 'datetime',
            path: options.path,
            onUpdate: function(value) {
                el.setAttribute('datetime', value);
                processElement(el);
            }
        });

        return el;
    }

    /**
     * Bind element to reactive state
     * @param {HTMLElement} el - Time element
     * @param {Object} state - State object with datetime property
     * @param {string} path - Path to datetime value
     */
    function bindToState(el, state, path) {
        if (!Funky.LiveBinding) {
            console.warn('[RelativeTime] LiveBinding not available');
            return;
        }

        Funky.LiveBinding.bind(el, {
            source: 'state',
            state: state,
            path: path,
            attribute: 'datetime',
            onUpdate: function(value) {
                el.setAttribute('datetime', value);
                processElement(el);
            }
        });

        // Track for cleanup
        if (!el._relativeTime) {
            el._relativeTime = true;
            el._lastRefresh = Date.now();
            instances.push(el);
        }
    }

    /**
     * Update multiple elements from data array
     * @param {string} containerSelector - Container selector
     * @param {Array} data - Array of { selector: string, datetime: string }
     */
    function batchUpdate(containerSelector, data) {
        var container = document.querySelector(containerSelector);
        if (!container) return;

        for (var i = 0; i < data.length; i++) {
            var item = data[i];
            var el = container.querySelector(item.selector);
            if (el && el.matches && el.matches(SELECTOR)) {
                el.setAttribute('datetime', item.datetime);
                processElement(el);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // Element Processing
    // ─────────────────────────────────────────────────────────────────

    /**
     * Process a single time element
     * @param {HTMLElement} el - The <time> element
     */
    function processElement(el) {
        var datetime = el.getAttribute('datetime');
        if (!datetime) return;

        // Parse refresh configuration from data attribute
        var refreshAttr = el.getAttribute('data-refresh');
        if (refreshAttr === 'false') {
            el._refreshDisabled = true;
        } else if (refreshAttr && !isNaN(parseInt(refreshAttr, 10))) {
            el._refreshInterval = parseInt(refreshAttr, 10);
        }

        // Check for per-element seconds display override
        var secondsAttr = el.getAttribute('data-seconds');
        if (secondsAttr === 'true') {
            config._elementShowSeconds = true;
        } else if (secondsAttr === 'false') {
            config._elementShowSeconds = false;
        } else {
            config._elementShowSeconds = null;
        }

        var relative = getRelativeTime(datetime);
        
        // Clear element override
        config._elementShowSeconds = null;
        var newText = formatRelative(relative);
        var oldText = el.textContent;

        if (newText && oldText !== newText) {
            el.textContent = newText;

            // Emit update event
            E.emit(el, 'funky.relative-time.update', {
                datetime: datetime,
                oldText: oldText,
                newText: newText,
                isAbsolute: relative && relative.absolute
            });
        }

        // Track threshold crossing (relative to absolute)
        var wasRelative = el._wasRelative;
        var isAbsolute = relative && relative.absolute;

        if (wasRelative && isAbsolute) {
            // Crossed threshold from relative to absolute
            E.emit(el, 'funky.relative-time.threshold', {
                datetime: datetime,
                text: newText
            });
        }

        el._wasRelative = !isAbsolute;

        // Add tooltip with full date/time
        if (!el.hasAttribute('title')) {
            var fullDate = formatFullDate(datetime);
            el.setAttribute('title', fullDate);
        }

        // Update aria-label for accessibility
        var fullDate = formatFullDate(datetime);
        el.setAttribute('aria-label', fullDate);
    }

    // ─────────────────────────────────────────────────────────────────
    // Initialization
    // ─────────────────────────────────────────────────────────────────

    /**
     * Initialize RelativeTime on elements
     * @param {HTMLElement|string} [scope] - Container or selector
     * @returns {number} Number of elements initialized
     */
    function init(scope) {
        initFormatters();

        var container = document;
        if (scope) {
            if (typeof scope === 'string') {
                container = document.querySelector(scope) || document;
            } else {
                container = scope;
            }
        }

        var elements = container.querySelectorAll(SELECTOR);
        var count = 0;
        var now = Date.now();

        for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            if (el._relativeTime) continue; // Already initialized

            el._relativeTime = true;
            el._lastRefresh = now;
            el._wasRelative = true; // Assume starts as relative
            instances.push(el);
            processElement(el);
            count++;
        }

        // Start timer if we have instances and timer not running
        if (instances.length > 0 && !refreshTimer) {
            startTimer();
            setupVisibilityListener();
        }

        // Start observer and DataTable integration on first init
        if (instances.length > 0 && !observer) {
            startObserver();
            setupDataTableIntegration();
        }

        // Emit init event
        if (count > 0) {
            E.emit(document, 'funky.relative-time.init', {
                count: count,
                scope: scope ? String(scope) : 'document'
            });
        }

        return count;
    }

    /**
     * Public format function (no element)
     * @param {Date|string} date
     * @param {Object} [options]
     * @returns {string}
     */
    function format(date, options) {
        initFormatters();
        var relative = getRelativeTime(date);
        return formatRelative(relative);
    }

    /**
     * Configure global settings
     * @param {Object} opts
     */
    function configure(opts) {
        if (!opts) return;

        for (var key in opts) {
            if (opts.hasOwnProperty(key)) {
                if (key === 'formats' && typeof opts.formats === 'object') {
                    for (var fkey in opts.formats) {
                        if (opts.formats.hasOwnProperty(fkey)) {
                            config.formats[fkey] = opts.formats[fkey];
                        }
                    }
                } else {
                    config[key] = opts[key];
                }
            }
        }

        // Reset formatters if locale changed
        if (opts.locale) {
            rtf = null;
            dtfShort = null;
            dtfFull = null;
            initFormatters();
        }

        // Auto-adjust refresh for seconds display
        if (opts.showSeconds === true && !opts.refreshInterval) {
            config.refreshInterval = 1000; // 1 second refresh for accurate seconds
        }

        // Restart timer if interval changed or showSeconds changed
        if ((opts.refreshInterval || opts.showSeconds !== undefined) && refreshTimer) {
            stopTimer();
            startTimer();
        }
    }

    /**
     * Manually refresh all elements
     */
    function refresh() {
        refreshAll();
    }

    /**
     * Pause auto-refresh
     */
    function pause() {
        if (isPaused) return;
        isPaused = true;

        E.emit(document, 'funky.relative-time.pause', {
            instanceCount: instances.length
        });
    }

    /**
     * Resume auto-refresh
     */
    function resume() {
        if (!isPaused) return;
        isPaused = false;
        refreshAll(); // Immediate refresh

        E.emit(document, 'funky.relative-time.resume', {
            instanceCount: instances.length
        });
    }

    /**
     * Check if currently paused
     * @returns {boolean}
     */
    function isPausedState() {
        return isPaused;
    }

    /**
     * Remove an element from tracking
     * @param {HTMLElement} el
     */
    function untrack(el) {
        var index = instances.indexOf(el);
        if (index > -1) {
            instances.splice(index, 1);
        }
        delete el._relativeTime;
        delete el._lastRefresh;
        delete el._refreshDisabled;
        delete el._refreshInterval;
    }

    /**
     * Get all tracked instances
     * @returns {HTMLElement[]}
     */
    function getInstances() {
        return instances.slice();
    }

    /**
     * Destroy all instances
     */
    function destroyAll() {
        stopTimer();
        stopObserver();

        // Remove visibility change listener
        if (visibilityListenerAdded) {
            document.removeEventListener('visibilitychange', handleVisibilityChange);
            visibilityListenerAdded = false;
        }

        for (var i = 0; i < instances.length; i++) {
            var el = instances[i];
            delete el._relativeTime;
            delete el._lastRefresh;
            delete el._refreshDisabled;
            delete el._refreshInterval;
        }
        instances = [];
    }

    // ─────────────────────────────────────────────────────────────────
    // Auto-Init
    // ─────────────────────────────────────────────────────────────────

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            init();
            setupExternalListeners();
        });
    } else {
        init();
        setupExternalListeners();
    }

    // ─────────────────────────────────────────────────────────────────
    // SPA Navigation
    // ─────────────────────────────────────────────────────────────────

    // Funky SPA events
    document.addEventListener('funky.spa.pageload', function() {
        setTimeout(function() {
            init();
        }, 50);
    });

    // Generic page load (third-party framework)
    document.addEventListener('page:load', function() {
        setTimeout(function() {
            init();
        }, 50);
    });

    // Turbolinks/Hotwire support (third-party framework)
    document.addEventListener('turbo:load', function() {
        setTimeout(function() {
            init();
        }, 50);
    });

    // ─────────────────────────────────────────────────────────────────
    // External Event Listeners
    // ─────────────────────────────────────────────────────────────────

    var externalListenersSetup = false;

    /**
     * Set up external event listeners
     */
    function setupExternalListeners() {
        if (externalListenersSetup) return;
        externalListenersSetup = true;

        // Listen for manual refresh requests
        E.on(document, 'funky.relative-time.refresh-request', function() {
            refresh();
        });

        // Listen for datetime updates from other components
        E.on(document, 'funky.relative-time.set', function(e) {
            var data = e.detail || {};
            if (data.element && data.datetime) {
                var el = typeof data.element === 'string'
                    ? document.querySelector(data.element)
                    : data.element;
                if (el) {
                    el.setAttribute('datetime', data.datetime);
                    processElement(el);
                }
            }
        });

        // Listen for bulk datetime updates
        E.on(document, 'funky.relative-time.batch-set', function(e) {
            var items = e.detail && e.detail.items || [];
            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                var el = typeof item.element === 'string'
                    ? document.querySelector(item.element)
                    : item.element;
                if (el && item.datetime) {
                    el.setAttribute('datetime', item.datetime);
                    processElement(el);
                }
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────
    // Register Component
    // ─────────────────────────────────────────────────────────────────

    /**
     * Get instance data for an element
     * @param {HTMLElement|string} el - Element or selector
     * @returns {Object|null} Instance data or null
     */
    function getInstance(el) {
        if (typeof el === 'string') {
            el = document.querySelector(el);
        }
        if (!el || instances.indexOf(el) === -1) {
            return null;
        }
        return {
            element: el,
            timestamp: el._relativeTime,
            lastRefresh: el._lastRefresh,
            refreshDisabled: el._refreshDisabled
        };
    }

    Funky.register('RelativeTime', {
        init: init,
        format: format,
        configure: configure,
        refresh: refresh,
        pause: pause,
        resume: resume,
        isPaused: isPausedState,
        untrack: untrack,
        destroy: untrack,  // Alias for consistency
        getInstances: getInstances,
        getInstance: getInstance,
        destroyAll: destroyAll,

        // LiveBinding APIs
        createBound: createBound,
        bindToState: bindToState,
        batchUpdate: batchUpdate,

        // DataTable support
        dtRenderer: dtRenderer
    });

})(window);
