/* Misc. utility functions */

function interpretUnicodeEntities(text) {
	return text.replace(/&#(\d+);/g,
		function (str, m1, offset, s) {
			return String.fromCharCode(m1);
		}
	);
}

function toUnicodeEntities(str) {
        // Convert wide characters to decimal entities (Unicode)
        // Adapted from http://rishida.net/scripts/uniview/conversion.js
        var charCodes = new Array();
        var has_wide = false;
        var width = 0;
        for (var i = 0; i < str.length; i++) {
            var b = str.charCodeAt(i);
            if (b < 0 || b > 0xFFFF) continue;
            if (width > 0) {
                if (0xDC00 <= b && b <= 0xDFFF) {
                    charCodes.push(0x10000 + ((width - 0xD800) << 10) + (b - 0xDC00));
                    width = 0;
                    has_wide = true;
                    continue;
                }
            }
            if (0xD800 <= b && b <= 0xDBFF) {
                width = b;
            }
            else {
                charCodes.push(b);
                if (b > 0x7E) has_wide = true;
            }
        }

        if (! has_wide)
            return str;

        var new_str = '';
        for (var i = 0; i < charCodes.length; i++) {
            var b = charCodes[i];
            if (b < 0x7F)
                new_str += String.fromCharCode(b);
            else
                new_str += '&#' + b + ';';
        }
        return new_str;
}

function arrayToBoolHash(arr) {
	var hash = new Object();
	for (var i = 0; i < arr.length; i++) {
		hash[ arr[i] ] = true;
	}
	return hash;
}

function keysAsArray (obj) {
	var arr = new Array();
	for (var key in obj)
		arr.push(key);
	arr.sort();
	return arr;
}

function arrayAsObject (arr) {
	var obj = new Object();
	for (var i in arr)
		obj[arr[i]] = 1;
	return obj;
}

Node.prototype.removeChildren = function() {
	while (this.hasChildNodes())
		this.removeChild( this.lastChild );
};

Node.prototype.addEventListenerChained = function () {
    this.addEventListener(arguments[0], arguments[1], arguments[2]);
    return this;
}

Object.extend = function (destination, source) {
    for (var property in source)
        destination[property] = source[property];
    return destination;
}

function cloneDeep (value) {
    if (value == null)
        return value;
    var type = typeof(value);
    if (type == 'object') {
        var newValue = new Object();
        for (var i in value)
            newValue[i] = cloneDeep(value[i]);
        return newValue;
    }
    else if (type == 'string') {
        return value;
    }
    else {
        dd("cloneDeep() returning type " + type + " '" + value + "' without cloning");
        return value;
    }
}

/*
Function: dd
	Debug display

Description:
	Logs the debug message to the Debug panel.  Will also show the message in the 'last_error' label, and will fade out this text over the course of 2.5 seconds.

Arguments:
	text - what you want to display
*/

var errorFadeInterval, errorFadeLevel;
var errorFadeLevels = 10;

function dd (text) {
        var win = window;
        var doc = document;
	var debug_list = doc.getElementById('debug_list');
        if (! debug_list && window.opener) {
            try {
                win = window.opener;
                doc = win.document;
                debug_list = doc.getElementById('debug_list');
            }
            catch (ex) {
            }
        }
	debug_list.appendChild($$('listitem', {
            label: text,
            ondblclick: 'alert(this.getAttribute("label"))'
        }));

	// Set value of last_status, and start fading it out
	doc.getElementById('last_error').setAttribute('value', text);
	errorFadeLevel = errorFadeLevels;

        // Can't call errorFade with the right document context
        if (win != window) return;

	if (errorFadeInterval) window.clearInterval( errorFadeInterval );
	errorFadeInterval = window.setInterval( errorFade, 250 );
}

function errorFade () {
	var opacity = (errorFadeLevel-- / errorFadeLevels);	
	var label = document.getElementById('last_error');
	label.style.opacity = opacity;

	// No more to fade; already out
	if (! errorFadeLevel) {
		if (errorFadeInterval) window.clearInterval( errorFadeInterval );
		label.value = '';
		label.style.opacity = 1;
	}
}

function _ (text) {
    return document.createTextNode(text);
}

function $ (id) {
	return document.getElementById(id);
}

function $$ (type, params, children) {
    var element = document.createElement(type);
    if (params) {
        for (var key in params) {
            element.setAttribute(key, params[key]);
        }
    }
    if (children) {
        for (var i = 0; i < children.length; i++) {
            element.appendChild(children[i]);
        }
    }
    return element;
}

/*
Function: Date.toRecentTimeString
	Format time according to how recently the date elapsed
*/

Date.prototype.toRecentTimeString = function () {
	var now = new Date();
	var diff = Math.floor( (now.valueOf() - this.valueOf()) / 1000 );

	var in_future = diff < 0 ? true : false;
	if (in_future)
		diff = Math.abs(diff);

	// Calc the number of days since epoch for now and this
	var day_ms = 24 * 60 * 60 * 1000;
	var now_days = Math.floor(now.valueOf() / day_ms);
	var this_days = Math.floor(this.valueOf() / day_ms);

	var duration = TimeDiffDuration(diff);

	var format;
	if (duration.year)
		format = '%d-%b-%Y';  // 13-Nov-2005
	else if (duration.mon)
		format = '%d-%b';     // 20-Sep
	else if (duration.week)
		format = '%a %d-%b %l:%M %p';  // Mon 03-Nov 4:39 PM
	else if (this_days + 1 == now_days)
		format = (in_future ? 'Tomorrow' : 'Yesterday') + ' %l:%M %p';     // Yesterday 2:43 AM
	else if (duration.day)
		format = '%a %l:%M %p';     // Tue 2:43 AM
	else if (duration.hr)
		format = '%l:%M %p';  // 6:20 PM
	else if (duration.min)
		format = Math.floor(duration.min) + ' min' + (in_future ? '' : ' ago');
	else if (duration.sec)
		format = Math.floor(duration.sec) + ' sec' + (in_future ? '' : ' ago');
	else 
		format = 'Now';

	var formatted = this.strftime(format);

	// Since the %p will always have space-padded numbers, let's remove the padding

	// Remove preceding spaces
	formatted = formatted.replace(/^\s+/, '');

	// Remove multi spaces
	formatted = formatted.replace(/\s{2,}/, ' ');

	return formatted;
};

/*
Function: Date.toRelativeString

Arguments:
	succinct - boolean wether to be succinct in describing the time.  If false, it'll append ' ago' to the time description.

see DateTimeRelativeString
*/

Date.prototype.toRelativeString = function(succinct) {
	// Get the difference between now and this date in seconds
	var diff = Math.floor( (new Date().valueOf() - this.valueOf()) / 1000 );

	return TimeDiffToRelativeString(succinct, Math.abs(diff)) + (succinct || diff < 0 ? '' : ' ago');
};

/*
Function: TimeDiffToRelativeString

Description:
	If you pass succinct as true, only displays one time description (instead of '5 hrs 2 mins', it'll just say '5 hrs').
	Numbers will have one decimal place unless it's minutes or seconds

Arguments:
	succinct - boolean wether to be succinct in describing the time
	diff - seconds between now and the date

Returns:
	string - description like '1 year 2 days 5 hours'
*/

var toRelativeString_names = [
	[ 'year',   52 * 7 * 24 * 60 * 60 ],
	[ 'mon',  30 * 24 * 60 * 60 ],
	[ 'week',   7 * 24 * 60 * 60 ],
	[ 'day',    24 * 60 * 60 ],
	[ 'hr',   60 * 60 ],
	[ 'min', 60 ],
	[ 'sec', 1 ]
];

function TimeDiffDuration (diff, dontShow) {
	var duration = new Object();
	for (var i = 0; i < toRelativeString_names.length; i++) {
		var name = toRelativeString_names[i];
		if (dontShow && dontShow[ name[1] ]) continue;
		if (diff > name[1]) {
			var qty = diff / name[1];
			duration[name[0]] = qty;

			var qty_floored = Math.floor(qty);
			diff -= name[1] * qty_floored;
		}
	}
	return duration;
}

function TimeDiffToRelativeString (succinct, diff) {
	// Create a string like "1 year 2 mons" or "1 day 20 secs"
	var result = '', displayedNames = 0;
	// Get the duration object sans week labels
	var duration = TimeDiffDuration(diff, { week: 1 });
	for (var name in duration) {
		var qty = duration[name];
		if (name == 'sec' || name == 'min')
			qty = Math.floor(qty);
		else
			// Allow one decimal place
			qty = Math.floor( 10 * qty ) / 10;

		result += (result == '' ? '' : ' ') + qty + ' ' + name + (qty > 1 ? 's' : '');
		if (++displayedNames == (succinct ? 1 : 2)) break;
	}
	return result;
};


/*
Function: CanonicalizeStringDuration
*/

var CanonicalizeStringDuration_patterns = [
	[ /y(ear|)s?/i,   52 * 7 * 24 * 60 * 60 ],
	[ /m(on|onth|)s?/i,  30 * 24 * 60 * 60 ],
	[ /w(eek|)s?/i,   7 * 24 * 60 * 60 ],
	[ /d(ay|)s?/i,    24 * 60 * 60 ],
	[ /h(r|our|)s?/i,   60 * 60 ],
	[ /m(in|inute|)s?/i, 60 ],
	[ /s(ec|econd|)s?/i, 1 ]
];

function CanonicalizeStringDuration (str) {
	var matches = /^\s*(\d+)\s+([a-z]+)\s*$/i.exec(str);
	if (matches) {
		for (var i = 0; i < CanonicalizeStringDuration_patterns.length; i++) {
			var arr = CanonicalizeStringDuration_patterns[i];
			if (arr[0].test(matches[2])) {
				return arr[1] * matches[1];
			}
		}
	}
	return null;
}

/*
Function: ValidateDateTime
	Given a string representation of a date and time, parse it into a standardized Date object

Description:

Arguments:
	input - the string
	in_past - bool for if the time represents the past or future
*/

// Sunday - Saturday
var ValidateDateTime_days = [
	/Sun(?:day|)/i,
	/Mon(?:day|)/i,
	/Tues?(?:day|)/i,
	/Wed(?:nesday|)/i,
	/Thur?s?(?:day|)/i,
	/Fri(?:day|)/i,
	/Sat(?:urday|)/i,
	/Tomorrow/i,
	/Yesterday/i
];

function ValidateDateTime (input, in_past) {
	// Find a date (if present)

	var now = new Date();

	var replacement_date = new Date(input);
	if (replacement_date.toLocaleString() == 'Invalid Date')
		replacement_date = new Date( now.valueOf() );
	else {
		return replacement_date;
	}
	var found_date = false;

	// 2006-11-30 or 4/8/2006
	matches = /\s*(\d+)[/-](\d+)[/-](\d+)\s*/.exec(input);
	if (matches) {
		// Assume YYYY-MM-DD
		var y = matches[1];
		var m = matches[2];
		var d = matches[3];
		// Convert if MM-DD-YYYY
		if (d.length == 4) {
			var t = y;
			y = d;
			d = t;
		}

		replacement_date = new Date(y, m - 1, d);
		found_date = true;

		// Remove what was found in regex pattern
		input = input.slice( 0, matches.index ) + input.slice( matches.index + matches[0].length );
	}

	for (var day = 0; day < ValidateDateTime_days.length; day++) {
		matches = ValidateDateTime_days[day].exec(input);
		if (matches) {
			if (found_date) {
				// do nothing but remove it from the string
				input = input.slice( 0, matches.index ) + input.slice( matches.index + matches[0].length );
			}
			else {
				// Find number of days in the future, relative to today
				var cur_day = replacement_date.getDay(); // 0 == Sunday
				var offset;
				if (day == 7) // tomorrow
					offset = 1;
				else if (day == 8) // yesterday
					offset = -1;
				else if (in_past) {
					if (day >= cur_day)
						offset = -1 * (cur_day + (7 - day));
					else
						offset = day - cur_day;
				}
				else {
					if (day >= cur_day)
						offset = day - cur_day;
					else
						offset = day + 7 - cur_day;
				}
					
				// Step into the future that many days
				replacement_date = new Date(replacement_date.valueOf() + (24 * 60 * 60 * 1000 * offset));
				found_date = true;
			}
		}
	}

	// Find a time in the input
	
	var time_re = /\s*(\d+):?(\d\d|):?(\d\d|) *(a\.?m|p\.?m|)\.?\s*/i;
	var matches = time_re.exec(input);
	if (matches) {
		var h = matches[1];
		h *= 1;
		var m = matches[2];
		if (m == '') m = 0;
		var s = matches[3];
		if (s == '') s = 0;
		var ampm = matches[4];
		if (ampm != '') {
			// Normalize the ampm
			ampm = /^a/i.test(ampm) ? 'am' : 'pm';

			if (ampm == 'am' && h == 12)
				h = 0;
			else if (ampm == 'pm')
				h += 12;
		}

		replacement_date.setHours(h, m, s);

		// If I'm now in the past, go forward one day
		if (! found_date && replacement_date.valueOf() < now.valueOf() && ! in_past)
			replacement_date = new Date(replacement_date.valueOf() + (24 * 60 * 60 * 1000));

		// Remove what was found in regex pattern
		input = input.slice( 0, matches.index ) + input.slice( matches.index + matches[0].length );
	}

	// If nothing specified, make it one hour in the future
	if (! found_date && replacement_date.valueOf() == now.valueOf())
		replacement_date = new Date(replacement_date.valueOf() + (60 * 60 * 1000));

	return replacement_date;
}

/* 
Function: ClearListbox
	Clears listbox of contents
*/

function ClearListbox (listId) {
	var list = document.getElementById(listId);
	var listitems = list.childNodes;

	for (var i = listitems.length - 1; i >= 0; i--) {
		if (listitems[i].tagName == 'listitem')
			list.removeChild( listitems[i] );
	}
}

/* 
Function: SortPrioritized
	Sort an array with some items taking precendence or pushed to end

Arguments:
	arr - the array to be sorted in place
	param - object with up to two properities
		start
		end
			Both are an array of keys

Description:
	SortPrioritized([ 'the', 'end', 'of', 'my', 'world' ], { start: [ 'world' ], end: '['of', 'my'] });
	will result in the array being sorted so that 'world' is first, 'of' and 'my' are last (in that order), and any other keys are sorted as normal <=>.  Results in [ 'world', 'end', 'the', 'of', 'my' ];

*/

function SortPrioritized (arr, param) {
	Sorter.sortPrioritized(arr, param);
	return;
/*
	// Hash the start/end arrays for quick access
	var start = new Object();
	if (param.start)
		for (var i = 0; i < param.start.length; i++)
			start[ param.start[i] ] = i + 1;

	var end = new Object();
	if (param.end)
		for (var i = 0; i < param.end.length; i++)
			end[ param.end[i] ] = i + 1;

	var sorter = function (a,b) {
		// Handle start first
		if (start[a] && ! start[b]) {
			return -1;
		}
		else if (start[a] && start[b]) {
			if (start[a] < start[b])
				return -1;
			else
				return 1;
		}
		else if (! start[a] && start[b]) {
			return 1;
		}

		// Next handle end
		if (end[a] && ! end[b]) {
			return 1;
		}
		else if (end[a] && end[b]) {
			if (end[a] < end[b])
				return -1;
			else
				return 1;
		}
		else if (! end[a] && end[b]) {
			return -1;
		}

		// Default ascending sorter
		if (a < b)
			return -1;
		else if (a > b)
			return 1;
		else
			return 0;
	};

	arr.sort(sorter);
*/
}

/*
Function: SortListbox
   Utility function to sort a <listbox> Document element

Description:
	The easiest way to sort a listbox is to delete it's contents and recreate them one at a time presorted.  This however may cause the screen to redraw, and can be slow.  A better way is to sort it in place using the least necessary number of deletions/insertions.  The assumption is that the data about a row is stored in another datastructure in memory, accessed off of some key.
	This function requires that every row in the listbox (<listitem>) have a 'key' attribute which will be passed to the objFunc() to obtain the object.
	A list of metadata will be constructed that contains the current position, key and object of every row in the list.  Then, the sortFunc() will be used to sort this metadata list.  Finally, the sorted meta list is compared with the actual <listbox>, and any out-of-place rows will be removed from their old position and put into sort order.  This means that ideally that the number of delete/insert's will be the same as the number of rows that changed (i.e., one row changed order, so only one row is deleted/inserted).

Arguments:
	listId - the 'id' of the <listbox> that has 'key' or 'id' attribute on every <listitem>
	objFunc - a function to calculate the object based upon the key/id
	sortParam - either a function or an array
		function: basic sort routine (a,b) where a,b are objects with properties 'pos', 'obj', and 'key'
		array: list of pairs representing key and (n)desc/asc describing how to multisort the objects.  nasc/ndesc are numeric comparisons; otherwise, it's string comparisons.

Returns:
	nothing
*/

function SortListbox (listId, objFunc, sortParam) {
	var list = document.getElementById(listId);
	var listitems = list.childNodes;

	// Get list of Objects which can be used for comparision
	var meta = new Array();

	// Find the index of the first listitem
	var i = 0;
	while (listitems[i].nodeName != 'listitem') {
		i++;
		if (! listitems[i]) return;
	}
	var startindex = i;
	for (; i < listitems.length; i++) {
		var key = listitems[i].getAttribute('key');
		if (key == null)
			key = listitems[i].getAttribute('id');
		meta.push({
			pos: i,
			obj: objFunc(key),
			key: key
		});
	}

	// Do the sort on the meta array
	if (typeof sortParam == 'function')
		meta.sort( sortParam );
	else if (sortParam instanceof Array) {
		// Create multisort function from param
		var sortFunc = function (a,b) {
			var ret = 0;
			for (var n = 0; n < sortParam.length; n += 2) {
				var key = sortParam[n];
				var a_val = a.obj[key];
				var b_val = b.obj[key];

				// Support numeric comparisons by casting into Number
				if (dir == 'nasc' || dir == 'ndesc') {
					a_val *= 1;
					b_val *= 1;
				}

				if (a_val == b_val) {
					ret = 0;
					continue;
				}

				var dir = sortParam[n+1];
				if (a_val > b_val)
					ret = (dir == 'asc' || dir == 'nasc') ? 1 : -1;
				else 
					ret = (dir == 'asc' || dir == 'nasc') ? -1 : 1;
				break;
			}
			return ret;
		};
		meta.sort( sortFunc );
	}
	else {
		dd( "Didn't recognized sort typeof " + (typeof sortParam) );
	}

	// Check each entry in actual list and replace where in wrong order
	for (var i = 0; i < meta.length; i++) {
		var j = i + startindex;
		// Compare key of listitem at same sorted order as meta key
		if (listitems[j].getAttribute('key') != meta[i].key) {
			var old_pos = meta[i].pos;
			list.insertBefore( list.removeChild( listitems[old_pos] ), listitems[j] );

			// Since I've just inserted a new object above the current, I need to 
			// increment the rememberd position of all objects that have been offset by this move
			for (var x = i + 1; x < meta.length; x++)
				if (meta[x].pos < old_pos) meta[x].pos++;
		}
	}
};

/* 
Function: SortContainer
   Generic function to sort any container

Description:
  Should be able to be a replacement for SortListbox() with childType = 'listitem' and uniqKeyAttr = 'key'
*/

function SortContainer (container, childType, uniqKeyAttr, objFunc, sortParam) {
	var children = container.childNodes;

	// Get list of Objects which can be used for comparision
	var meta = new Array();

	// Find the index of the first child
	var i = 0;
	while (children[i].nodeName != childType) {
		i++;
		if (! children[i]) return;
	}
	var startindex = i;
	for (; i < children.length; i++) {
		var key = children[i].getAttribute(uniqKeyAttr);
		meta.push({
			pos: i,
			obj: objFunc(key),
			key: key
		});
	}

	// Do the sort on the meta array
	if (typeof sortParam == 'function')
		meta.sort( sortParam );
	else if (sortParam instanceof Array) {
		// Create multisort function from param
		var sortFunc = function (a,b) {
			var ret = 0;
			for (var n = 0; n < sortParam.length; n += 2) {
				var key = sortParam[n];
				var a_val = a.obj[key];
				var b_val = b.obj[key];

				// Support numeric comparisons by casting into Number
				if (dir == 'nasc' || dir == 'ndesc') {
					a_val *= 1;
					b_val *= 1;
				}

				if (a_val == b_val) {
					ret = 0;
					continue;
				}

				var dir = sortParam[n+1];
				if (a_val > b_val)
					ret = (dir == 'asc' || dir == 'nasc') ? 1 : -1;
				else 
					ret = (dir == 'asc' || dir == 'nasc') ? -1 : 1;
				break;
			}
			return ret;
		};
		meta.sort( sortFunc );
	}
	else {
		dd( "Didn't recognized sort typeof " + (typeof sortParam) );
	}

	// Check each entry in actual container and replace where in wrong order
	for (var i = 0; i < meta.length; i++) {
		var j = i + startindex;
		// Compare key of container at same sorted order as meta key
		if (children[j].getAttribute('key') != meta[i].key) {
			var old_pos = meta[i].pos;
			container.insertBefore( container.removeChild( children[old_pos] ), children[j] );

			// Since I've just inserted a new object above the current, I need to 
			// increment the rememberd position of all objects that have been offset by this move
			for (var x = i + 1; x < meta.length; x++)
				if (meta[x].pos < old_pos) meta[x].pos++;
		}
	}
};

/**********************************************************************
 *
 * yaml_dumper.js
 * $Id: yaml_dumper.js,v 1.12 2002/10/28 22:20:29 eserte Exp $
 *
 * (c) 2002 Slaven Rezic. 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl.
 *
 **********************************************************************/

// detect javascript implementation
var YAML_JS;
if (typeof VM != "undefined") {
    YAML_JS = "njs";
} else if (typeof navigator != "undefined" && navigator.appName == "Netscape") {
    if (navigator.appVersion.indexOf("4.") == 0) { // no check for 3.
	YAML_JS = "js1.3"; // ???
    } else {
	YAML_JS = "js1.4";
    }
} else {
    // mozilla standalone?
    YAML_JS = "js1.4"; // XXX differentiate!
}

// Context constants
var YAML_KEY = 3;
var YAML_FROMARRAY = 5;
var YAML_VALUE = "\x07YAML\x07VALUE\x07";

// Common YAML character sets
var YAML_ESCAPE_CHAR;
if (YAML_JS == "njs") { // workaround njs 0.2.5 bug (?)
    YAML_ESCAPE_CHAR = "[";
    for(var i=0x00; i<=0x08; i++) { YAML_ESCAPE_CHAR += String.fromCharCode(i); }
    for(var i=0x0b; i<=0x1f; i++) { YAML_ESCAPE_CHAR += String.fromCharCode(i); }
    YAML_ESCAPE_CHAR += "]";
} else {
    YAML_ESCAPE_CHAR = "[\\x00-\\x08\\x0b-\\x1f]";
}
var YAML_FOLD_CHAR = ">";
var YAML_BLOCK_CHAR = "|";

YAML_Indent         = 2;
YAML_UseHeader      = true;
YAML_UseVersion     = true;
YAML_SortKeys       = true;
YAML_AnchorPrefix   = "";
YAML_UseCode        = false;
YAML_DumpCode       = "";
YAML_LoadCode       = "";
YAML_ForceBlock     = false;
YAML_UseBlock       = false;
YAML_UseFold        = false;
YAML_CompressSeries = true;
//XXX NYI  YAML_InlineSeries   = false;
YAML_UseAliases     = true;
YAML_Purity         = false;
YAML_DateClass      = "";

function YAML() {
    this.stream         = "";
    this.level          = 0;
    this.anchor         = 1;
    this.Indent         = YAML_Indent;
    this.UseHeader      = YAML_UseHeader;
    this.UseVersion     = YAML_UseVersion;
    this.SortKeys       = YAML_SortKeys;
    this.AnchorPrefix   = YAML_AnchorPrefix;
    this.DumpCode       = YAML_DumpCode;
    this.LoadCode       = YAML_LoadCode;
    this.ForceBlock     = YAML_ForceBlock;
    this.UseBlock       = YAML_UseBlock;
    this.UseFold        = YAML_UseFold;
    this.CompressSeries = YAML_CompressSeries;
    //XXX NYI    this.InlineSeries   = YAML_InlineSeries;
    this.UseAliases     = YAML_UseAliases;
    this.Purity         = YAML_Purity;
    this.DateClass      = YAML_DateClass;

    // methods
    this.dump  = YAML_dump;
    this.dump1 = YAML_dump1;
    this._emit_header = YAML_emit_header;
    this._emit_node = YAML_emit_node;
    this._emit_mapping = YAML_emit_mapping;
    this._emit_sequence = YAML_emit_sequence;
    this._emit_str = YAML_emit_str;
    this._emit_key = YAML_emit_key;
    this._emit_nested = YAML_emit_nested;
    this._emit_simple = YAML_emit_simple;
    this._emit_double = YAML_emit_double;
    this._emit_single = YAML_emit_single;
    this._emit_function = YAML_emit_function;
    this._emit_regexp = YAML_emit_regexp;
    this.is_valid_implicit = YAML_is_valid_implicit;
    this.indent = YAML_indent;
}

function YAMLDump() {
    var o = new YAML();
    return o.dump(arguments);
}

function YAML_dump1(arg) {
    return this.dump([arg]);
}

function YAML_dump(args) {
    this.stream   = "";
    this.document = 0;

    for(var doc_i = 0; doc_i < args.length; doc_i++) {
	var doc = args[doc_i];
	this.document++;
	this.transferred = {};
	this.id_refcnt   = {};
	this.id_anchor   = {};
	this.anchor      = 1;
	this.level       = 0;
	this.offset      = [0 - this.Indent];
	this._emit_header(doc);
	this._emit_node(doc);
    }

    return this.stream;
}

function YAML_emit_header(node) {
    if (!this.UseHeader && this.document == 1) {
	// XXX croak like in the perl version?
	this.headless = true;
	return;
    }
    this.stream += "---";
    if (this.UseVersion) {
	this.stream += " #YAML:1.0";
    }
}

function YAML_emit_node(node, context) {
    if (typeof context == "undefined") context = 0;

    if        (typeof node == "undefined" || node == null) {
	return this._emit_str(null);
    } else if (typeof node == "#array") { // njs array
	return this._emit_sequence(node);
    } else if (typeof node == "object") { // mozilla array & object
	var is_a_mapping = false;
	var is_empty = true;
	for (var i in node) {
	    is_empty = false;
	    if (isNaN(i)) {
		is_a_mapping = true;
		break;
	    }
	}
	if (!is_empty) {
	    if (is_a_mapping) {
		return this._emit_mapping(node, context);
	    } else {
		return this._emit_sequence(node);
	    }
	} else {
	    if (typeof node.length != "undefined") {
		return this._emit_sequence(node, context);
	    } else {
		return this._emit_mapping(node, context);
	    }
	}
    } else if (typeof node == "function") {
	if (String(node).indexOf("/") == 0) {
	    return this._emit_regexp(node);
	} else {
	    return this._emit_function(node);
	}
    } else if (typeof node == "string" || typeof node == "boolean") {
	return this._emit_str(node);
    } else {
	return this._emit_str(String(node));
    }
}

function YAML_emit_mapping(value, context) {
    var keys = new Array;
    for(var key in value) {
	keys[keys.length] = key;
    }

    if (keys.length == 0) { // empty hash
	this.stream += " {}\n";
	return;
    }

    if (context == YAML_FROMARRAY && this.CompressSeries) {
        this.stream += " ";
	this.offset[this.level+1] = this.offset[this.level] + 2;
    } else {
        context = 0;
	if (!this.headless) {
	    this.stream += "\n";
	    this.headless = false;
	}
	this.offset[this.level+1] = this.offset[this.level] + this.Indent;
    }
    
    if (this.SortKeys) {
	keys.sort(YAML_cmp_strings);
    }
	
    this.level++;
    for(var key_i = 0; key_i < keys.length; key_i++) {
	var key = keys[key_i];
        this._emit_key(key, context);
        context = 0;
        this.stream += ":";
        this._emit_node(value[key]);
    }
    this.level--;
}

function YAML_emit_sequence(value) {
    if (value.length == 0) {
	this.stream += " []\n";
	return;
    }

    if (!this.headless) {
	this.stream += "\n";
	this.headless = false;
    }

    // XXX NYI InlineSeries

    this.offset[this.level + 1] = this.offset[this.level] + this.Indent;
    this.level++;
    for(var i = 0; i < value.length; i++) {
	this.stream += YAML_x(" ", this.offset[this.level]);
	this.stream += "-";
	this._emit_node(value[i], YAML_FROMARRAY);
    }
    this.level--;
}

function YAML_emit_key(value, context) {
    if (context != YAML_FROMARRAY) {
	this.stream += YAML_x(" ", this.offset[this.level]);
    }
    this._emit_str(value, YAML_KEY);
}

function YAML_emit_str(value, type) {
    if (typeof type == "undefined") type = 0;

    // Use heuristics to find the best scalar emission style.
    this.offset[this.level + 1] = this.offset[this.level] + this.Indent;
    this.level++;

    if (value != null &&
	typeof value != "boolean" &&
	value.match(new RegExp(YAML_ESCAPE_CHAR)) == null &&
	(value.length > 50 || value.match(/\n[ \f\n\r\t\v]/) != null ||
	 (this.ForceBlock && type != YAML_KEY)
	 )
	) {
	this.stream += (type == YAML_KEY ? "? " : " ");
	if ((this.UseFold && !this.ForceBlock) ||
	    value.match(/^[^ \f\n\r\t\v][^\n]{76}/) != null
	    ) {
            if (this.is_valid_implicit(value)) {
                this.stream += "! ";
            }
            this._emit_nested(YAML_FOLD_CHAR, value);
        } else {
            this._emit_nested(YAML_BLOCK_CHAR, value);
        }
        this.stream += "\n";
    } else {
	if (type != YAML_KEY) {
	    this.stream += " ";
	}
        if        (value != null && value == YAML_VALUE) {
            this.stream += "=";
        } else if (YAML_is_valid_implicit(value)) {
            this._emit_simple(value);
        } else if (value.match(new RegExp(YAML_ESCAPE_CHAR + "|\\n|\\'")) != null) {
            this._emit_double(value);
        } else {
            this._emit_single(value);
        }
	if (type != YAML_KEY) {
	    this.stream += "\n";
	}
    }
    
    this.level--;
}

function YAML_is_valid_implicit(value) {
    if (   value == null
	|| typeof value == "number"       // !int or !float (never reached)
	|| typeof value == "boolean"      // !int or !float (never reached)
	|| value.match(/^(-?[0-9]+)$/) != null       // !int
	|| value.match(/^-?[0-9]+\.[0-9]+$/) != null    // !float
	|| value.match(/^-?[0-9]+e[+-][0-9]+$/) != null // !float
	   ) {
	return true;
    }
    if (   value.match(new RegExp(YAML_ESCAPE_CHAR)) != null
	|| value.match(/(^[ \f\n\r\t\v]|\:( |$)|\#( |$)|[ \f\n\r\t\v]$)/) != null
	|| value.indexOf("\n") >= 0
	) {
	return false;
    }
    if (value.charAt(0).match(/[A-Za-z0-9_]/) != null) { // !str
	return true;
    }
    return false;
}

function YAML_emit_nested(indicator, value) {
    this.stream += indicator;

    var end = value.length - 1;
    var newlines_end = 0;
    while(end >= 0 && value.charAt(end) == "\n") {
	newlines_end++;
	if (newlines_end > 1) break;
	end--;
    }

    var chomp = (newlines_end > 0 ? (newlines_end > 1 ? "+" : "") : "-");
    if (value == null) {
	value = "~";
    }
    this.stream += chomp;
    if (value.match(/^[ \f\n\r\t\v]/) != null) {
	this.stream += this.Indent;
    }
    if (indicator == YAML_FOLD_CHAR) {
        value = YAML_fold(value);
	if (chomp != "+") {
	    value = YAML_chop(value);
	}
    }
    this.stream += this.indent(value);
}

function YAML_emit_simple(value) {
    if (typeof value == "boolean") {
	this.stream += value ? "+" : "-";
    } else {
	this.stream += value == null ? "~" : value;
    }
}

function YAML_emit_double(value) {
    var escaped = YAML_escape(value);
    escaped = escaped.replace(/\"/g, "\\\"");
    this.stream += "\"" + escaped + "\"";
}

function YAML_emit_single(value) {
    this.stream += "'" + value + "'";
}

function YAML_emit_function(value) {
    this.offset[this.level + 1] = this.offset[this.level] + this.Indent;
    this.level++;
    this.stream += " !javascript/code: ";
    this._emit_nested(YAML_BLOCK_CHAR, String(value));
    this.stream += "\n";
    this.level--;
}

function YAML_emit_regexp(value) {
    this.offset[this.level + 1] = this.offset[this.level] + this.Indent;
    this.level++;
    this.stream += " !javascript/regexp:";
    this.level--; // XXX somewhat hackish
    var rx = {MODIFIERS: (value.global ? "g" : "")
	                 + (value.ignoreCase ? "i" : "")
	                 + (value.multiline ? "m" : ""),
	      REGEXP:    value.source
    };
    this._emit_mapping(rx,0);
}

function YAML_indent(text) {
    if (text.length == 0) return text;
    if (text.charAt(text.length-1) == "\n")
	text = text.substr(0, text.length-1);
    var indent = YAML_x(" ", this.offset[this.level]);

    if (YAML_JS == "js1.3") {
	var text_a = text.split("\n");
	var res = [];
	for(var i = 0; i < text_a.length; i++) {
	    res[res.length] = text_a[i].replace(/^/, indent);
	} 
	text = res.join("\n");
    } else {
	var rx = (YAML_JS == "njs" ? new RegExp("^(.)", "g") : new RegExp("^(.)", "gm"));
	text = text.replace(rx, indent+"$1");
    }

    text = "\n" + text;
    return text;
}

function YAML_fold(text) {
    var folded = "";
    text = text.replace(/^([^ \f\n\r\t\v].*)\n(?=[^ \f\n\r\t\v])/g, RegExp.$1 + "\n\n");
    while (text.length > 0) {
        if        (text.match(/^([^\n]{0,76})(\n|\Z)/) != null) {
	    text = text.replace(/^([^\n]{0,76})(\n|\Z)/, "");
            folded += RegExp.$1;
        } else if (text.match(/^(.{0,76})[ \f\n\r\t\v]/) != null) { 
	    text = text.replace(/^(.{0,76})[ \f\n\r\t\v]/, "");
            folded += RegExp.$1;
        } else {
	    // XXX croak?
	    text = text.replace(/(.*?)([ \f\n\r\t\v]|\Z)/, "");
            folded += RegExp.$1;
        }
        folded += "\n";
    }
    return folded;
}

YAML_escapes =
    ["\\z",   "\\x01", "\\x02", "\\x03", "\\x04", "\\x05", "\\x06", "\\a",
     "\\x08", "\\t",   "\\n",   "\\v",   "\\f",   "\\r",   "\\x0e", "\\x0f",
     "\\x10", "\\x11", "\\x12", "\\x13", "\\x14", "\\x15", "\\x16", "\\x17",
     "\\x18", "\\x19", "\\x1a", "\\e",   "\\x1c", "\\x1d", "\\x1e", "\\x1f",
    ];

function YAML_escape(text) {
    text = text.replace(/\\/g, "\\\\");
    var new_text = "";
    for(var i = 0; i < text.length; i++) {
	if (text.charCodeAt(i) <= 0x1f) {
	    new_text += YAML_escapes[text.charCodeAt(i)];
	} else {
	    new_text += text.charAt(i);
	}
    }
    return new_text;
}

function YAML_x(s,n) {
    var ret = "";
    for (var i=1; i<=n; i++) {
	ret += s;
    }
    return ret;
}

function YAML_chop(s) {
    return s.substr(0, s.length-1);
}

function YAML_cmp_strings(a,b) {
    a = String(a);
    b = String(b);
    if (a < b) return -1;
    if (a > b) return +1;
    return 0;
}
