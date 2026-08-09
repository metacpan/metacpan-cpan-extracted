/**
 * Funky.Date - Date Utility Module
 *
 * Provides date manipulation, comparison, formatting, and calendar grid generation.
 * Extracted from Calendar.js DateEngine for reuse across components.
 *
 * @module Funky.Date
 * @version 1.0.4
 *
 * @example
 * // Comparisons
 * Funky.Date.isSameDay(date1, date2);
 * Funky.Date.isToday(date);
 * Funky.Date.isInRange(date, start, end);
 *
 * // Boundaries
 * Funky.Date.startOfDay(date);
 * Funky.Date.startOfMonth(date);
 *
 * // Arithmetic
 * Funky.Date.addDays(date, 5);
 * Funky.Date.addMonths(date, -1);
 *
 * // Calendar grid
 * var grid = Funky.Date.generateMonthGrid(date, 0);
 *
 * // Formatting
 * Funky.Date.toDateString(date); // '2025-01-15'
 * Funky.Date.format(date, { month: 'long', day: 'numeric' });
 */
(function(window) {
    'use strict';

    // Ensure Funky registry exists
    if (!window.Funky || !window.Funky.register) {
        console.error('[Funky.Date] Registry not found. Load namespace.js first.');
        return;
    }

    var Funky = window.Funky;

    // Guard against double registration
    if (Funky.Date) {
        return;
    }

    // =========================================================================
    // POLYFILLS (ES5 compatibility)
    // =========================================================================

    if (!String.prototype.padStart) {
        String.prototype.padStart = function(targetLength, padString) {
            targetLength = targetLength >> 0;
            padString = String(padString || ' ');
            if (this.length >= targetLength) {
                return String(this);
            }
            targetLength = targetLength - this.length;
            if (targetLength > padString.length) {
                padString += padString.repeat(Math.ceil(targetLength / padString.length));
            }
            return padString.slice(0, targetLength) + String(this);
        };
    }

    if (!String.prototype.repeat) {
        String.prototype.repeat = function(count) {
            if (this == null) throw new TypeError('can\'t convert ' + this + ' to object');
            var str = '' + this;
            count = +count;
            if (count < 0) throw new RangeError('repeat count must be non-negative');
            if (count === Infinity) throw new RangeError('repeat count must be less than infinity');
            count = Math.floor(count);
            if (str.length === 0 || count === 0) return '';
            var result = '';
            while (count > 0) {
                if (count & 1) result += str;
                count >>>= 1;
                str += str;
            }
            return result;
        };
    }

    // =========================================================================
    // COMPARISON METHODS
    // =========================================================================

    /**
     * Check if two dates are the same day (ignoring time)
     * @param {Date} date1 - First date
     * @param {Date} date2 - Second date
     * @returns {boolean} True if same day
     */
    function isSameDay(date1, date2) {
        if (!date1 || !date2) return false;
        return date1.getFullYear() === date2.getFullYear() &&
               date1.getMonth() === date2.getMonth() &&
               date1.getDate() === date2.getDate();
    }

    /**
     * Check if date is today
     * @param {Date} date - Date to check
     * @returns {boolean} True if today
     */
    function isToday(date) {
        if (!date) return false;
        return isSameDay(date, new Date());
    }

    /**
     * Check if date is in the same month as reference
     * @param {Date} date - Date to check
     * @param {Date} reference - Reference date
     * @returns {boolean} True if same month and year
     */
    function isSameMonth(date, reference) {
        if (!date || !reference) return false;
        return date.getFullYear() === reference.getFullYear() &&
               date.getMonth() === reference.getMonth();
    }

    /**
     * Check if a date falls on a weekend (Saturday or Sunday)
     * @param {Date} date - Date to check
     * @returns {boolean} True if weekend
     */
    function isWeekend(date) {
        if (!date) return false;
        var day = date.getDay();
        return day === 0 || day === 6;
    }

    /**
     * Check if date1 is before date2
     * @param {Date} date1 - First date
     * @param {Date} date2 - Second date
     * @returns {boolean} True if date1 < date2
     */
    function isBefore(date1, date2) {
        if (!date1 || !date2) return false;
        return date1.getTime() < date2.getTime();
    }

    /**
     * Check if date1 is after date2
     * @param {Date} date1 - First date
     * @param {Date} date2 - Second date
     * @returns {boolean} True if date1 > date2
     */
    function isAfter(date1, date2) {
        if (!date1 || !date2) return false;
        return date1.getTime() > date2.getTime();
    }

    /**
     * Check if date is within a range (inclusive)
     * @param {Date} date - Date to check
     * @param {Date} start - Range start
     * @param {Date} end - Range end
     * @returns {boolean} True if date is within range
     */
    function isInRange(date, start, end) {
        if (!date) return false;
        if (!start && !end) return true;

        var time = date.getTime();

        if (start && end) {
            return time >= start.getTime() && time <= end.getTime();
        }
        if (start) {
            return time >= start.getTime();
        }
        if (end) {
            return time <= end.getTime();
        }

        return true;
    }

    /**
     * Compare two dates
     * @param {Date} date1 - First date
     * @param {Date} date2 - Second date
     * @returns {number} -1 if date1 < date2, 0 if equal, 1 if date1 > date2
     */
    function compare(date1, date2) {
        if (!date1 || !date2) return 0;
        var t1 = date1.getTime();
        var t2 = date2.getTime();
        if (t1 < t2) return -1;
        if (t1 > t2) return 1;
        return 0;
    }

    // =========================================================================
    // BOUNDARY METHODS
    // =========================================================================

    /**
     * Get start of day (00:00:00.000)
     * @param {Date} date - Input date
     * @returns {Date} New date at start of day
     */
    function startOfDay(date) {
        if (!date) return null;
        var d = new Date(date);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    /**
     * Get end of day (23:59:59.999)
     * @param {Date} date - Input date
     * @returns {Date} New date at end of day
     */
    function endOfDay(date) {
        if (!date) return null;
        var d = new Date(date);
        d.setHours(23, 59, 59, 999);
        return d;
    }

    /**
     * Get start of month (first day at 00:00:00.000)
     * @param {Date} date - Input date
     * @returns {Date} New date at start of month
     */
    function startOfMonth(date) {
        if (!date) return null;
        return new Date(date.getFullYear(), date.getMonth(), 1, 0, 0, 0, 0);
    }

    /**
     * Get end of month (last day at 23:59:59.999)
     * @param {Date} date - Input date
     * @returns {Date} New date at end of month
     */
    function endOfMonth(date) {
        if (!date) return null;
        var d = new Date(date.getFullYear(), date.getMonth() + 1, 0);
        d.setHours(23, 59, 59, 999);
        return d;
    }

    /**
     * Get start of week
     * @param {Date} date - Input date
     * @param {number} [weekStarts=0] - Week start day (0=Sunday, 1=Monday)
     * @returns {Date} New date at start of week
     */
    function startOfWeek(date, weekStarts) {
        if (!date) return null;
        weekStarts = weekStarts || 0;
        var d = new Date(date);
        var day = d.getDay();
        var diff = (day - weekStarts + 7) % 7;
        d.setDate(d.getDate() - diff);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    /**
     * Get end of week
     * @param {Date} date - Input date
     * @param {number} [weekStarts=0] - Week start day (0=Sunday, 1=Monday)
     * @returns {Date} New date at end of week
     */
    function endOfWeek(date, weekStarts) {
        if (!date) return null;
        var start = startOfWeek(date, weekStarts);
        var end = new Date(start);
        end.setDate(end.getDate() + 6);
        end.setHours(23, 59, 59, 999);
        return end;
    }

    // =========================================================================
    // ARITHMETIC METHODS
    // =========================================================================

    /**
     * Add days to a date
     * @param {Date} date - Input date
     * @param {number} days - Days to add (negative to subtract)
     * @returns {Date} New date with days added
     */
    function addDays(date, days) {
        if (!date) return null;
        var d = new Date(date);
        d.setDate(d.getDate() + days);
        return d;
    }

    /**
     * Add months to a date
     * @param {Date} date - Input date
     * @param {number} months - Months to add (negative to subtract)
     * @returns {Date} New date with months added
     */
    function addMonths(date, months) {
        if (!date) return null;
        var d = new Date(date);
        var originalDay = d.getDate();
        d.setMonth(d.getMonth() + months);

        // Handle month-end edge case (e.g., Jan 31 + 1 month = Feb 28)
        if (d.getDate() !== originalDay) {
            d.setDate(0); // Go to last day of previous month
        }

        return d;
    }

    /**
     * Add years to a date
     * @param {Date} date - Input date
     * @param {number} years - Years to add (negative to subtract)
     * @returns {Date} New date with years added
     */
    function addYears(date, years) {
        if (!date) return null;
        var d = new Date(date);
        d.setFullYear(d.getFullYear() + years);
        return d;
    }

    /**
     * Get number of days in a month
     * @param {Date} date - Any date in the target month
     * @returns {number} Number of days in the month
     */
    function daysInMonth(date) {
        if (!date) return 0;
        return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
    }

    /**
     * Clone a date
     * @param {Date} date - Date to clone
     * @returns {Date} New Date object
     */
    function clone(date) {
        if (!date) return null;
        return new Date(date);
    }

    // =========================================================================
    // GRID GENERATION
    // =========================================================================

    /**
     * Generate month grid (6 weeks × 7 days = 42 cells)
     * @param {Date} date - Any date in the target month
     * @param {number} [weekStarts=0] - Week start day (0=Sunday, 1=Monday)
     * @returns {Array} Array of week arrays, each containing day objects
     */
    function generateMonthGrid(date, weekStarts) {
        if (!date) return [];
        weekStarts = weekStarts || 0;

        var firstOfMonth = startOfMonth(date);
        var gridStart = startOfWeek(firstOfMonth, weekStarts);

        var weeks = [];
        var current = new Date(gridStart);
        var today = new Date();

        // Generate 6 weeks (ensures consistent grid height)
        for (var w = 0; w < 6; w++) {
            var week = [];

            for (var d = 0; d < 7; d++) {
                week.push({
                    date: new Date(current),
                    day: current.getDate(),
                    month: current.getMonth(),
                    year: current.getFullYear(),
                    isToday: isSameDay(current, today),
                    isCurrentMonth: isSameMonth(current, date),
                    isWeekend: isWeekend(current),
                    dateString: toDateString(current),
                    isoString: current.toISOString()
                });

                current = addDays(current, 1);
            }

            weeks.push(week);
        }

        return weeks;
    }

    /**
     * Generate week grid (7 days with time slots)
     * @param {Date} date - Any date in the target week
     * @param {Object} [options] - Options { weekStarts, startHour, endHour, slotDuration }
     * @returns {Object} { days: Array, slots: Array }
     */
    function generateWeekGrid(date, options) {
        if (!date) return { days: [], slots: [] };
        options = options || {};
        var weekStarts = options.weekStarts || 0;
        var startHour = options.startHour || 0;
        var endHour = options.endHour || 24;
        var slotDuration = options.slotDuration || 30;

        var weekStart = startOfWeek(date, weekStarts);
        var today = new Date();

        // Generate days
        var days = [];
        var current = new Date(weekStart);

        for (var d = 0; d < 7; d++) {
            days.push({
                date: new Date(current),
                day: current.getDate(),
                dayOfWeek: current.getDay(),
                isToday: isSameDay(current, today),
                isWeekend: isWeekend(current),
                dateString: toDateString(current)
            });

            current = addDays(current, 1);
        }

        // Generate time slots
        var slots = [];
        var totalMinutes = (endHour - startHour) * 60;
        var slotCount = Math.ceil(totalMinutes / slotDuration);

        for (var s = 0; s < slotCount; s++) {
            var minutes = startHour * 60 + s * slotDuration;
            var hour = Math.floor(minutes / 60);
            var minute = minutes % 60;

            slots.push({
                hour: hour,
                minute: minute,
                time: formatTime(hour, minute),
                isHourStart: minute === 0
            });
        }

        return { days: days, slots: slots };
    }

    /**
     * Generate day grid (time slots for single day)
     * @param {Date} date - Target date
     * @param {Object} [options] - Options { startHour, endHour, slotDuration }
     * @returns {Object} { day, slots }
     */
    function generateDayGrid(date, options) {
        if (!date) return { day: null, slots: [] };
        options = options || {};
        var startHour = options.startHour || 0;
        var endHour = options.endHour || 24;
        var slotDuration = options.slotDuration || 30;

        var today = new Date();
        var day = {
            date: new Date(date),
            day: date.getDate(),
            dayOfWeek: date.getDay(),
            isToday: isSameDay(date, today),
            isWeekend: isWeekend(date),
            dateString: toDateString(date)
        };

        // Generate time slots
        var slots = [];
        var totalMinutes = (endHour - startHour) * 60;
        var slotCount = Math.ceil(totalMinutes / slotDuration);

        for (var s = 0; s < slotCount; s++) {
            var minutes = startHour * 60 + s * slotDuration;
            var hour = Math.floor(minutes / 60);
            var minute = minutes % 60;

            // Create slot datetime
            var slotDate = new Date(date);
            slotDate.setHours(hour, minute, 0, 0);

            slots.push({
                hour: hour,
                minute: minute,
                time: formatTime(hour, minute),
                datetime: slotDate,
                isHourStart: minute === 0,
                isPast: slotDate < new Date()
            });
        }

        return { day: day, slots: slots };
    }

    /**
     * Get visible range for a view
     * @param {Date} date - Reference date
     * @param {string} [view='month'] - View type ('month', 'week', 'day')
     * @param {number} [weekStarts=0] - Week start day
     * @returns {Object} { start: Date, end: Date }
     */
    function getViewRange(date, view, weekStarts) {
        if (!date) return { start: null, end: null };
        var start, end;

        switch (view) {
            case 'week':
                start = startOfWeek(date, weekStarts);
                end = endOfWeek(date, weekStarts);
                break;
            case 'day':
                start = startOfDay(date);
                end = endOfDay(date);
                break;
            default: // month
                // Include days from adjacent months shown in the grid
                var firstOfMonth = startOfMonth(date);
                start = startOfWeek(firstOfMonth, weekStarts);

                var lastOfMonth = endOfMonth(date);
                end = endOfWeek(lastOfMonth, weekStarts);
        }

        return { start: start, end: end };
    }

    // =========================================================================
    // FORMATTING METHODS
    // =========================================================================

    /**
     * Convert date to YYYY-MM-DD string
     * @param {Date} date - Date to format
     * @returns {string} Date string in YYYY-MM-DD format
     */
    function toDateString(date) {
        if (!date) return '';
        var y = date.getFullYear();
        var m = String(date.getMonth() + 1).padStart(2, '0');
        var d = String(date.getDate()).padStart(2, '0');
        return y + '-' + m + '-' + d;
    }

    /**
     * Convert date to HH:MM or HH:MM:SS string
     * @param {Date} date - Date to format
     * @param {boolean} [includeSeconds=false] - Include seconds
     * @returns {string} Time string
     */
    function toTimeString(date, includeSeconds) {
        if (!date) return '';
        var h = String(date.getHours()).padStart(2, '0');
        var m = String(date.getMinutes()).padStart(2, '0');
        if (includeSeconds) {
            var s = String(date.getSeconds()).padStart(2, '0');
            return h + ':' + m + ':' + s;
        }
        return h + ':' + m;
    }

    /**
     * Format time as HH:MM from hour and minute values
     * @param {number} hour - Hour (0-23)
     * @param {number} minute - Minute (0-59)
     * @returns {string} Formatted time string
     */
    function formatTime(hour, minute) {
        return String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
    }

    /**
     * Format date with locale and options using Intl.DateTimeFormat
     * @param {Date} date - Date to format
     * @param {Object} [options] - Intl.DateTimeFormat options
     * @param {string} [locale='en-US'] - Locale string
     * @returns {string} Formatted date string
     */
    function format(date, options, locale) {
        if (!date) return '';
        locale = locale || 'en-US';
        try {
            return new Intl.DateTimeFormat(locale, options).format(date);
        } catch (e) {
            return date.toLocaleDateString();
        }
    }

    // =========================================================================
    // PARSING METHODS
    // =========================================================================

    /**
     * Parse various date inputs to Date object
     * @param {Date|string|number} value - Value to parse
     * @returns {Date|null} Parsed Date or null if invalid
     */
    function parse(value) {
        if (!value) return null;
        if (value instanceof Date) return new Date(value);

        // Handle timestamp (detect seconds vs milliseconds)
        if (typeof value === 'number') {
            // Heuristic: timestamps in seconds are typically 10-digit numbers (like 1700000000 for year 2023)
            // Timestamps in milliseconds are 13-digit numbers (like 1700000000000)
            // Boundary: 10 billion (10^10) is roughly year 2286 in seconds, or ~115 days after epoch in ms
            // Values >= 10 billion are definitely milliseconds (no reasonable seconds timestamp that large)
            // Values < 10 billion could be seconds OR milliseconds near epoch
            // For ambiguous small values, prefer treating as milliseconds (modern JS convention)
            var absValue = Math.abs(value);
            if (absValue >= 10000000000) {
                // Definitely milliseconds (10+ digits)
                // value unchanged
            } else if (absValue >= 1000000000) {
                // 10-digit number: likely seconds (covers years 2001-2286)
                value = value * 1000;
            } else {
                // Less than 1 billion: ambiguous
                // Could be seconds (pre-2001) or milliseconds (near epoch)
                // Treat as milliseconds to correctly handle values like -86400000 (Dec 31, 1969)
                // value unchanged
            }
            var d = new Date(value);
            return isNaN(d.getTime()) ? null : d;
        }

        // Handle string
        if (typeof value === 'string') {
            var date = new Date(value);
            return isNaN(date.getTime()) ? null : date;
        }

        return null;
    }

    // =========================================================================
    // LOCALIZATION METHODS
    // =========================================================================

    /**
     * Get localized day names
     * @param {string} [locale='en-US'] - Locale string
     * @param {string} [format='short'] - Format: 'narrow', 'short', 'long'
     * @param {number} [weekStarts=0] - Week start day (0=Sunday, 1=Monday)
     * @returns {Array<string>} Array of 7 day names
     */
    function getDayNames(locale, format, weekStarts) {
        locale = locale || 'en-US';
        format = format || 'short';
        weekStarts = weekStarts || 0;

        var formatter = new Intl.DateTimeFormat(locale, { weekday: format });
        var days = [];

        // Start from a known Sunday (Jan 4, 1970 was a Sunday)
        var baseDate = new Date(1970, 0, 4);

        for (var i = 0; i < 7; i++) {
            var dayIndex = (i + weekStarts) % 7;
            var date = new Date(baseDate);
            date.setDate(date.getDate() + dayIndex);
            days.push(formatter.format(date));
        }

        return days;
    }

    /**
     * Get localized month names
     * @param {string} [locale='en-US'] - Locale string
     * @param {string} [format='long'] - Format: 'narrow', 'short', 'long'
     * @returns {Array<string>} Array of 12 month names
     */
    function getMonthNames(locale, format) {
        locale = locale || 'en-US';
        format = format || 'long';

        var formatter = new Intl.DateTimeFormat(locale, { month: format });
        var months = [];

        for (var i = 0; i < 12; i++) {
            months.push(formatter.format(new Date(2000, i, 1)));
        }

        return months;
    }

    // =========================================================================
    // WEEK NUMBER METHODS
    // =========================================================================

    /**
     * Get ISO week number (1-53)
     * @param {Date} date - Date to check
     * @returns {number} ISO week number
     */
    function getWeekNumber(date) {
        if (!date) return 0;
        var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        var dayNum = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dayNum);
        var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    }

    /**
     * Get number of ISO weeks in a year (52 or 53)
     * @param {number} year - Year to check
     * @returns {number} Number of weeks in year
     */
    function getWeeksInYear(year) {
        var d = new Date(year, 11, 31);
        var week = getWeekNumber(d);
        return week === 1 ? 52 : week;
    }

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    var DateUtil = {
        // Comparison
        isSameDay: isSameDay,
        isToday: isToday,
        isSameMonth: isSameMonth,
        isWeekend: isWeekend,
        isBefore: isBefore,
        isAfter: isAfter,
        isInRange: isInRange,
        compare: compare,

        // Boundaries
        startOfDay: startOfDay,
        endOfDay: endOfDay,
        startOfMonth: startOfMonth,
        endOfMonth: endOfMonth,
        startOfWeek: startOfWeek,
        endOfWeek: endOfWeek,

        // Arithmetic
        addDays: addDays,
        addMonths: addMonths,
        addYears: addYears,
        daysInMonth: daysInMonth,
        clone: clone,

        // Grid generation
        generateMonthGrid: generateMonthGrid,
        generateWeekGrid: generateWeekGrid,
        generateDayGrid: generateDayGrid,
        getViewRange: getViewRange,

        // Formatting
        toDateString: toDateString,
        toTimeString: toTimeString,
        formatTime: formatTime,
        format: format,

        // Parsing
        parse: parse,

        // Localization
        getDayNames: getDayNames,
        getMonthNames: getMonthNames,

        // Week numbers
        getWeekNumber: getWeekNumber,
        getWeeksInYear: getWeeksInYear
    };

    // Register with Funky
    Funky.register('Date', DateUtil);

})(window);
