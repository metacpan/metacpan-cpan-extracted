function activate_datepicker() {
    var opts = {
        dateFormat: 'yy-mm-dd',
        constrainInput: false,
        showButtonPanel: true,
        changeMonth: true,
        changeYear: true,
        showOtherMonths: true,
        showOn: 'none',
        selectOtherMonths: true
    };
    jQuery(".conditioned-by-admin-vals input.datepicker").focus(function() {
        var val = jQuery(this).val();
        if ( !val.match(/[a-z]/i) ) {
            jQuery(this).datepicker('show');
        }
    });
    jQuery(".conditioned-by-admin-vals input.datepicker:not(.withtime)").datepicker(opts);
    jQuery(".conditioned-by-admin-vals input.datepicker.withtime").datetimepicker( jQuery.extend({}, opts, {
        stepHour: 1,
        // We fake this by snapping below for the minute slider
        //stepMinute: 5,
        hourGrid: 6,
        minuteGrid: 15,
        showSecond: false,
        timeFormat: 'HH:mm:ss'
    }) ).each(function(index, el) {
        var tp = jQuery.datepicker._get( jQuery.datepicker._getInst(el), 'timepicker');
        if (!tp) return;
        if (tp._base_injectTimePicker) return; // avoid recursion

        // Hook after _injectTimePicker so we can modify the minute_slider
        // right after it's first created
        tp._base_injectTimePicker = tp._injectTimePicker;
        tp._injectTimePicker = function() {
            this._base_injectTimePicker.apply(this, arguments);

            // Now that we have minute_slider, modify it to be stepped for mouse movements
            var slider = jQuery.data(this.minute_slider[0], "ui-slider");
            slider._base_normValueFromMouse = slider._normValueFromMouse;
            slider._normValueFromMouse = function() {
                var value           = this._base_normValueFromMouse.apply(this, arguments);
                var old_step        = this.options.step;
                this.options.step   = 5;
                var aligned         = this._trimAlignValue( value );
                this.options.step   = old_step;
                return aligned;
            };
        };
    });
}

function naturalSort(a, b, lang) {
    if (window.Intl) {
        if(lang === "") lang = navigator.language;
        return window.Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(a.toString(), b.toString());
    }

    /*
     * Natural Sort algorithm for Javascript - Version 0.7 - Released under MIT license
     * Author: Jim Palmer (based on chunking idea from Dave Koelle)
     * http://www.overset.com/2008/09/01/javascript-natural-sort-algorithm-with-unicode-support/
     */
    var re = /(^-?[0-9]+(\.?[0-9]*)[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
        sre = /(^[ ]*|[ ]*$)/g,
        dre = /(^([\w ]+,?[\w ]+)?[\w ]+,?[\w ]+\d+:\d+(:\d+)?[\w ]?|^\d{1,4}[\/\-]\d{1,4}[\/\-]\d{1,4}|^\w+, \w+ \d+, \d{4})/,
        hre = /^0x[0-9a-f]+$/i,
        ore = /^0/,
        i = function(s) { return (''+s).toLowerCase() || ''+s },
        // convert all to strings strip whitespace
        x = i(a).replace(sre, '') || '',
        y = i(b).replace(sre, '') || '',
        // chunk/tokenize
        xN = x.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        yN = y.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        // numeric, hex or date detection
        xD = parseInt(x.match(hre)) || (xN.length != 1 && x.match(dre) && Date.parse(x)),
        yD = parseInt(y.match(hre)) || xD && y.match(dre) && Date.parse(y) || null,
        oFxNcL, oFyNcL;
    // first try and sort Hex codes or Dates
    if (yD)
        if ( xD < yD ) return -1;
    else if ( xD > yD ) return 1;
    // natural sorting through split numeric strings and default strings
    for(var cLoc=0, numS=Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
        // find floats not starting with '0', string or 0 if not defined (Clint Priest)
        oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
        oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
        // handle numeric vs string comparison - number < string - (Kyle Adams)
        if (isNaN(oFxNcL) !== isNaN(oFyNcL)) { return (isNaN(oFxNcL)) ? 1 : -1; }
        // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
        else if (typeof oFxNcL !== typeof oFyNcL) {
            oFxNcL += '';
            oFyNcL += '';
        }
        if (oFxNcL < oFyNcL) return -1;
        if (oFxNcL > oFyNcL) return 1;
    }
    return 0;
}

function parseIP(ip) {
    var reIPv4 = /^(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))$/;
    var reIPv6 = /^(?:(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/;
    if (reIPv4.test(ip)) {
        return ip.split('.').map(function(ip_part) { while (ip_part.length < 3) ip_part = '0' +ip_part; return ip_part; }).join('.');
    } else if (reIPv6.test(ip)) {
        // replace ipv4 address if any
        var ipv4 = ip.match(/(.*:)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$)/);
        if (ipv4) {
            var ip = ipv4[1];
            ipv4 = ipv4[2].match(/[0-9]+/g);
            for (var i = 0;i < 4;i ++) {
                var byte = parseInt(ipv4[i],10);
                ipv4[i] = ("0" + byte.toString(16)).substr(-2);
            }
            ip += ipv4[0] + ipv4[1] + ':' + ipv4[2] + ipv4[3];
        }

        // take care of leading and trailing ::
        ip = ip.replace(/^:|:$/g, '');

        var ipv6 = ip.split(':');

        for (var i = 0; i < ipv6.length; i ++) {
            var hex = ipv6[i];
            if (hex != "") {
                // normalize leading zeros
                ipv6[i] = ("0000" + hex).substr(-4);
            }
            else {
                // normalize grouped zeros ::
                hex = [];
                for (var j = ipv6.length; j <= 8; j ++) {
                    hex.push('0000');
                }
                ipv6[i] = hex.join(':');
            }
        }

        return ipv6.join(':');
    }
    return ip;
}

function get_selector(name, type, render_type, rt_v5) {
    var selector;
    if (type == 'Text' || type == 'Wikitext') {
        selector = 'textarea[name="' + name + '"]';
    } else if ((type == 'Select' && render_type == 'List') || type == 'Image' || type == 'Binary' || (rt_v5 >= 0 && (type == 'Combobox' || type == 'Date' || type == 'DateTime'))) {
        selector = 'input[name="' + name + '"]';
    } else {
        selector = '#' + name;
    }
    selector = selector.replace(/:/g,'\\:');
    return selector;
}

function get_cf_current_form_values(selector, type, render_type, single) {
    var values = Array();
    if ((type == 'Select' && render_type == 'List') || type == 'Boolean') {
        var all_vals = jQuery(selector);
        jQuery.each(all_vals, function(id, val) {
            if (jQuery(val).is(':checked')) {
                values.push(jQuery(val).val());
            }
        });
    } else if (type == 'Image' || type == 'Binary') {
        var val = jQuery(selector).val();
        if (val) {
            values.push(val);
        }
        if (!(single) || values.length == 0) {
            var delete_selector = selector.replace('Upload', 'DeleteValueIds');
            var delete_vals = jQuery(delete_selector);
            jQuery.each(delete_vals, function(id, val) {
                if (jQuery(val).not(':checked')) {
                    values.push(jQuery(val).next('a').text().trim());
                }
            });
        }
    } else {
        var vals = jQuery(selector).val();
        if (!jQuery.isArray(vals)) {
            values = Array(vals);
        } else {
            values = vals;
        }
    }

    if (type == 'IPAddress') {
        for (var i=0; i<values.length; i++) {
            values[i] = parseIP(values[i]);
        }
    }

    return values;
}

function condition_is_met(condition_vals, cf_condition_vals, condition_op, lang) {
    lang = (typeof lang !== 'undefined') ? lang : 'en';
    var condition_met = false;

    if (condition_op == "isn't" || condition_op == "doesn't match" || condition_op == "between") {
        condition_met = true;
    }

    if (cf_condition_vals.length) {
        for (var i=0; i<cf_condition_vals.length; i++) {
            for (var j=0; j<condition_vals.length; j++) {
                if (condition_op == "is" || condition_op == "isn't") {
                    if (cf_condition_vals[i] == condition_vals[j]) {
                        return !condition_met;
                    }
                } else if (condition_op == "matches" || condition_op == "doesn't match") {
                    var regexp = RegExp(condition_vals[j].replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), "i");
                    if (regexp.test(cf_condition_vals[i])) {
                        return !condition_met;
                    }
                } else if (condition_op == "less than") {
                    if (naturalSort(cf_condition_vals[i], condition_vals[j], lang) <= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "greater than") {
                    if (naturalSort(cf_condition_vals[i], condition_vals[j], lang) >= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "between") {
                    var comp = naturalSort(cf_condition_vals[i], condition_vals[j], lang);
                    if (j == 0 && comp < 0) {
                        return !condition_met;
                    } else if (j == 1 && comp > 0) {
                        return !condition_met;
                    }
                }
            }
        }
    }

    return condition_met;
}
