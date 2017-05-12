/* Generated at 2011-09-19 11:41:19.0 CST6CDT */

var JSAN = { "use": function () {} };


/* /home/autarch/projects/Silki/share/js-source/DOM/Ready.js */

if ( typeof DOM == "undefined" ) {
    DOM = {};
}

DOM.Ready = {};

DOM.Ready.VERSION = "0.16";

DOM.Ready.finalTimeout = 15;
DOM.Ready.timerInterval = 50;

DOM.Ready._checkDOMReady = function () {
    if ( DOM.Ready._isReady ) {
        return DOM.Ready._isReady;
    }

    if (    typeof document.getElementsByTagName != "undefined"
         && typeof document.getElementById != "undefined"
         && ( document.getElementsByTagName("body")[0] !== null
              || document.body !== null ) ) {

        DOM.Ready._isReady = 1;
    }

    return DOM.Ready._isReady;

};

/* See near the end of the module for where _isDone could be set. */
DOM.Ready._checkDOMDone = function () {
    if ( DOM.Ready._isDone ) {
        return DOM.Ready._isDone;
    }

    /* Safari and Opera(?) only */

    /*@cc_on
       /*@if (@_win32)
    try {
        document.documentElement.doScroll("left");
        DOM.Ready._isDone = 1;
    } catch (e) {}
          @else @*/
    if ( document.readyState
         && ( /interactive|complete|loaded/.test( document.readyState ) )
       ) {
        DOM.Ready._isDone = 1;
    }
      /*@end
    @*/

    return DOM.Ready._isDone;
};

/* Works for Mozilla, and possibly nothing else */
if ( document.addEventListener ) {
    document.addEventListener(
        "DOMContentLoaded", function () { DOM.Ready._isDone = 1; }, false );
}

DOM.Ready.onDOMReady = function (callback) {
    if ( DOM.Ready._checkDOMReady() ) {
        callback();
    }
    else {
        DOM.Ready._onDOMReadyCallbacks.push(callback);
    }
};

DOM.Ready.onDOMDone = function (callback) {
    if ( DOM.Ready._checkDOMDone() ) {
        callback();
    }
    else {
        DOM.Ready._onDOMDoneCallbacks.push(callback);
    }
};

DOM.Ready.onIdReady = function ( id, callback ) {
    if ( DOM.Ready._checkDOMReady() ) {
        var elt = document.getElementById(id);
        if (elt) {
            callback(elt);
            return;
        }
    }

    var callback_array = DOM.Ready._onIdReadyCallbacks[id];
    if ( ! callback_array ) {
        callback_array = [];
    }
    callback_array.push(callback);

    DOM.Ready._onIdReadyCallbacks[id] = callback_array;
};

DOM.Ready._runDOMReadyCallbacks = function () {
    for ( var i = 0; i < DOM.Ready._onDOMReadyCallbacks.length; i++ ) {
        DOM.Ready._onDOMReadyCallbacks[i]();
    }

    DOM.Ready._onDOMReadyCallbacks = [];
};

DOM.Ready._runDOMDoneCallbacks = function () {
    for ( var i = 0; i < DOM.Ready._onDOMDoneCallbacks.length; i++ ) {
        DOM.Ready._onDOMDoneCallbacks[i]();
    }

    DOM.Ready._onDOMDoneCallbacks = [];
};

DOM.Ready._runIdCallbacks = function () {
    for ( var id in DOM.Ready._onIdReadyCallbacks ) {
        // protect against changes to Object (ala prototype's extend)
        if ( ! DOM.Ready._onIdReadyCallbacks.hasOwnProperty(id) ) {
            continue;
        }

        var elt = document.getElementById(id);

        if (elt) {
            for ( var i = 0; i < DOM.Ready._onIdReadyCallbacks[id].length; i++) {
                DOM.Ready._onIdReadyCallbacks[id][i](elt);
            }

            delete DOM.Ready._onIdReadyCallbacks[id];
        }
    }
};

DOM.Ready._runReadyCallbacks = function () {
    if ( DOM.Ready._inRunReadyCallbacks ) {
        return;
    }

    DOM.Ready._inRunReadyCallbacks = 1;

    if ( DOM.Ready._checkDOMReady() ) {
        DOM.Ready._runDOMReadyCallbacks();

        DOM.Ready._runIdCallbacks();
    }

    if ( DOM.Ready._checkDOMDone() ) {
        DOM.Ready._runDOMDoneCallbacks();
    }

    DOM.Ready._timePassed += DOM.Ready._lastTimerInterval;

    if ( ( DOM.Ready._timePassed / 1000 ) >= DOM.Ready.finalTimeout ) {
        DOM.Ready._stopTimer();
    }

    DOM.Ready._inRunReadyCallbacks = 0;
};

DOM.Ready._startTimer = function () {
    DOM.Ready._lastTimerInterval = DOM.Ready.timerInterval;
    DOM.Ready._intervalId = setInterval( DOM.Ready._runReadyCallbacks, DOM.Ready.timerInterval );
};

DOM.Ready._stopTimer = function () {
    clearInterval( DOM.Ready._intervalId );
    DOM.Ready._intervalId = null;
};

DOM.Ready._resetClass = function () {
    DOM.Ready._stopTimer();

    DOM.Ready._timePassed = 0;

    DOM.Ready._isReady = 0;
    DOM.Ready._isDone = 0;

    DOM.Ready._onDOMReadyCallbacks = [];
    DOM.Ready._onDOMDoneCallbacks = [];
    DOM.Ready._onIdReadyCallbacks = {};

    DOM.Ready._startTimer();
};

DOM.Ready._resetClass();

DOM.Ready.runCallbacks = function () { DOM.Ready._runReadyCallbacks(); };


/*

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>.

=head1 CREDITS

This library was inspired by Brother Cake's domFunction, though it
is entirely new code.

=head1 COPYRIGHT

Copyright (c) 2005-2006 Dave Rolsky.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as the Perl programming language (your choice of
GPL or the Perl Artistic license).

*/


/* /home/autarch/projects/Silki/share/js-source/DOM/Utils.js */

if ( typeof( DOM ) == 'undefined' ) {
    DOM = {};
}

DOM.Utils = {
    EXPORT: [ '$' ]
   ,'$' : function () {
        var elements = new Array();

        for (var i = 0; i < arguments.length; i++) {
            var element = arguments[i];

            if (typeof element == 'string')
                element = document.getElementById(element)
                    || document.getElementsByName(element)[0]
//                    || document.getElementsByTagName(element)[0]
                    || undefined
                ;

            if (arguments.length == 1)
                return element;

            elements.push( element );
        }

        return elements;
    }
};

/* Needed to get this working without real exporting */
window["$"] = DOM.Utils["$"];
$ = window["$"];

document.getElementsByClass = function(className) {
    var children = document.getElementsByTagName('*') || document.all;
    var elements = new Array();

    for (var i = 0; i < children.length; i++) {
        var child = children[i];
        var classNames = child.className.split(' ');
        for (var j = 0; j < classNames.length; j++) {
            if (classNames[j] == className) {
              elements.push(child);
              break;
            }
        }
    }

    return elements;
};
document.getElementsByClassName = document.getElementsByClass;


/* /home/autarch/projects/Silki/share/js-source/Silki/FileView.js */

JSAN.use('DOM.Utils');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.FileView = function () {
    var iframe = $("file-view-iframe");

    if ( ! iframe ) {
        return;
    }

    /* This should really calculate how much space is available after
     accounting for header and footer, but that is annoying to do (should
     steal or use jquery's version) */
    iframe.height = window.innerHeight * 0.7;
};


/* /home/autarch/projects/Silki/share/js-source/Silki/PageEdit.js */

JSAN.use('DOM.Utils');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.PageEdit = function () {
    this.form = $("form-and-preview");

    if ( ! this.form ) {
        return;
    }

    this.toolbar = new Silki.PageEdit.Preview ();
    this.toolbar = new Silki.PageEdit.Toolbar ();
};


/* /home/autarch/projects/Silki/share/js-source/HTTP/Request.js */

if ( typeof( Method ) == "undefined" ) {
    Method = {};
}

if ( typeof( Method["bind"] ) == "undefined" ) {
    Method.bind = function ( method, object ) {
        return function() {
            method.apply(object, arguments);
        }
    };
}

if ( typeof( HTTP ) == "undefined" ) {
    HTTP = {};
}

if ( typeof( HTTP.Request ) == "undefined" ) {
    HTTP.Request = function ( options ) {
        if ( !options ) options = {};

        this.options = {};
        for ( var i in options ) {
            this.setOption( i, options[i] );
        }

        if ( this.getOption( "method" ) == undefined ) {
            this.setOption( "method", "post" );
        }

        if ( this.getOption( "asynchronous" ) == undefined ) {
            this.setOption( "asynchronous", true );
        }

        if ( this.getOption( "parameters" ) == undefined ) {
            this.setOption( "parameters", "" );
        }

        if ( this.getOption( "transport" ) == undefined ) {
            this.setOption( "transport", HTTP.Request.Transport );
        }

        if ( this.getOption( "uri" ) )
            this.request();
    };

    HTTP.Request.EventNames = [
        "uninitialized"
       ,"loading"
       ,"loaded"
       ,"interactive"
       ,"complete"
    ];

    HTTP.Request.prototype.getOption = function( name ) {
        if ( typeof( name ) != "string" ) {
            return;
        }
        return this.options[name.toLowerCase()];
    };

    HTTP.Request.prototype.setOption = function( name, value ) {
        if ( typeof( name ) != "string" ) {
            return;
        }

        name = name.toLowerCase();

        this.options[name] = value;

        if ( name == "transport" ) {
            if ( typeof( value ) != "function" ) {
                this.options.transport = HTTP.Request.Transport;
            }
        }
    };

    HTTP.Request.prototype.request = function ( uri ) {
        if ( ! uri ) uri = this.getOption( "uri" );
        if ( ! uri ) return;

        var parameters = this.getOption( "parameters" );

        var method = this.getOption( "method" );
        if ( method == "get" ) {
            uri += "?" + parameters;
        }

        this.transport = new (this.getOption( "transport" ))();

        var async = this.getOption( "asynchronous" );
        this.transport.open( method ,uri ,async );

        if ( async ) {
            this.transport.onreadystatechange = Method.bind(
                this.onStateChange, this
            );

            setTimeout(
                Method.bind(
                    function() { this.respondToReadyState(1) }
                   ,this
                )
               ,10
           );
        }

        this.setRequestHeaders();

        if ( method == "post" ) {
            var body = this.getOption( "postbody" );
            if ( ! body ) body = parameters;

            this.transport.send( body );
        }
        else {
            this.transport.send( null );
        }
    };

    HTTP.Request.prototype.setRequestHeaders = function() {
        this.transport.setRequestHeader( "X-Requested-With", "HTTP.Request" );
        this.transport.setRequestHeader( "X-HTTP-Request-Version", HTTP.Request.VERSION );

        if (this.getOption( "method" ) == "post") {
            this.transport.setRequestHeader( "Content-type", "application/x-www-form-urlencoded" );

            /* Force "Connection: close" for Mozilla browsers to work around
             * a bug where XMLHttpReqeuest sends an incorrect Content-length
             * header. See Mozilla Bugzilla #246651.
             */
            if (this.transport.overrideMimeType) {
                this.transport.setRequestHeader( "Connection", "close" );
            }
        }

/* TODO Add support for this back in later
        if (this.options.requestHeaders)
            requestHeaders.push.apply(requestHeaders, this.options.requestHeaders);
*/
    };

    // XXX This confuses me a little ... how are undefined and 0 considered a success?
    HTTP.Request.prototype.isSuccess = function () {
        return this.transport.status == undefined
            || this.transport.status == 0
            || (this.transport.status >= 200 && this.transport.status < 300);
    };

    HTTP.Request.prototype.onStateChange = function() {
        var readyState = this.transport.readyState;
        if (readyState != 1) {
            this.respondToReadyState( this.transport.readyState );
        }
    };

    HTTP.Request.prototype.respondToReadyState = function( readyState ) {
        var event = HTTP.Request.EventNames[readyState];

        if (event == "complete") {
            var func = this.getOption( "on" + this.transport.status );
            if ( ! func ) {
                if ( this.isSuccess() ) {
                    func = this.getOption( "onsuccess" );
                }
                else {
                    func = this.getOption( "onfailure" );
                }
            }

            if ( func ) {
                ( func )( this.transport );
            }
        }

        if ( this.getOption( "on" + event ) )
            ( this.getOption( "on" + event ) )( this.transport );

        /* Avoid memory leak in MSIE: clean up the oncomplete event handler */
        if (event == "complete") {
            this.transport.onreadystatechange = function (){};
        }
    };

    HTTP.Request.VERSION = 0.03;
}

if ( typeof( HTTP.Request.Transport ) == "undefined" ) {
    if ( window.XMLHttpRequest ) {
        HTTP.Request.Transport = window.XMLHttpRequest;
    }
    // This tests for ActiveXObject in IE5+
    else if ( window.ActiveXObject && window.clipboardData ) {
        var msxmls = new Array(
            "Msxml2.XMLHTTP.5.0"
           ,"Msxml2.XMLHTTP.4.0"
           ,"Msxml2.XMLHTTP.3.0"
           ,"Msxml2.XMLHTTP"
           ,"Microsoft.XMLHTTP"
        );
        for ( var i = 0; i < msxmls.length; i++ ) {
            try {
                new ActiveXObject(msxmls[i]);
                HTTP.Request.Transport = function () {
                    return new ActiveXObject(msxmls[i]);
                };
                break;
            }
            catch(e) {
            }
        }
    }

    if ( typeof( HTTP.Request.Transport ) == "undefined" ) {
        // This is where we add DIV/IFRAME support masquerading as an XMLHttpRequest object
    }

    if ( typeof( HTTP.Request.Transport ) == "undefined" ) {
        throw new Error("Unable to locate XMLHttpRequest or other HTTP transport mechanism");
    }
}


/* /home/autarch/projects/Silki/share/js-source/Silki/PageEdit/Preview.js */

JSAN.use('DOM.Utils');
JSAN.use('HTTP.Request');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.PageEdit.Preview = function () {
    this.form  = $("edit-form");
    this.preview  = $("preview");
    this.textarea = $("page-content");

    if ( ! ( this.form && this.preview && this.textarea ) ) {
        return;
    }

    this.uri = this.form.action.replace( /(\/pages)?$/, '/html' );

    this.last_content = this.textarea.value;

    this._interval_id = setInterval( this._maybeUpdatePreviewFunc(), 1000 );
};

Silki.PageEdit.Preview.prototype._maybeUpdatePreviewFunc = function () {
    var self = this;

    var func = function (e) {
        if ( ! self.textarea.value.length ) {
            this.preview.innerHTML = "";
        }

        if ( self.textarea.value == self.last_content ) {
            return;
        }

        if ( self._updating ) {
            return;
        }

        self.last_content = self.textarea.value;

        self._fetchPreview();
    };

    return func;
};

Silki.PageEdit.Preview.prototype._fetchPreview = function () {
    this._updating = true;

    var self = this;

    var on_success = function (trans) {
        self._updatePreview(trans);
    };

    new HTTP.Request( {
        "uri":        this.uri,
        "method":     "post",
        "parameters": "x-tunneled-method=GET;content=" + encodeURIComponent( this.textarea.value ),
        "onSuccess":  on_success,
        "onFailure":  function () { self._updating = false; }
    } );
};

Silki.PageEdit.Preview.prototype._updatePreview = function (trans) {
    var resp = eval( "(" + trans.responseText + ")" );

    if ( resp.html ) {
        this.preview.innerHTML = resp.html;
    }

    this._updating = false;
}


/* /home/autarch/projects/Silki/share/js-source/DOM/Element.js */

try {
    JSAN.use( 'DOM.Utils' );
} catch (e) {
    throw "DOM.Element requires JSAN to be loaded";
}

if ( typeof( DOM ) == 'undefined' ) {
    DOM = {};
}

DOM.Element = {
    hide: function() {
        for (var i = 0; i < arguments.length; i++) {
            var element = $(arguments[i]);
            if ( element && element.nodeType == 1 ) {
                element.style.display = 'none';
            }
        }
    }

   ,show: function() {
        for (var i = 0; i < arguments.length; i++) {
            var element = $(arguments[i]);
            if ( element && element.nodeType == 1 ) {
                element.style.display = '';
            }
        }
    }

   ,toggle: function() {
        for (var i = 0; i < arguments.length; i++) {
            var element = $(arguments[i]);
            if ( element && element.nodeType == 1 )
                element.style.display =
                    (element.style.display == 'none' ? '' : 'none');
        }
    }

   ,remove: function() {
        for (var i = 0; i < arguments.length; i++) {
            element = $(arguments[i]);
            if ( element )
                element.parentNode.removeChild(element);
        }
    }

   ,getHeight: function(element) {
        element = $(element);
        if ( !element ) return;
        return element.offsetHeight;
    }

   ,hasClassName: function(element, className) {
        element = $(element);
        if ( !element || element.nodeType != 1 ) return;
        var a = element.className.split(' ');
        for (var i = 0; i < a.length; i++) {
            if (a[i] == className)
                return true;
        }
        return false;
    }

   ,addClassName: function(element, className) {
        element = $(element);
        if ( !element || element.nodeType != 1 ) return;
        DOM.Element.removeClassName(element, className);
        element.className += ' ' + className;
    }

   ,removeClassName: function(element, className) {
        element = $(element);
        if ( !element || element.nodeType != 1 ) return;

        var newClassnames = new Array();
        var a = element.className.split(' ');
        for (var i = 0; i < a.length; i++) {
            if (a[i] != className) {
                newClassnames.push( a[i] );
            }
        }
        element.className = newClassnames.join(' ');
    }

   ,cleanWhitespace: function() {
        var element = $(element);
        if ( !element ) return;
        for (var i = 0; i < element.childNodes.length; i++) {
            var node = element.childNodes[i];
            if (node.nodeType == 3 && !/\S/.test(node.nodeValue))
                DOM.Element.remove(node);
        }
    }
};


/* /home/autarch/projects/Silki/share/js-source/DOM/Events.js */

(function () {
	if(typeof DOM == "undefined") DOM = {};
	DOM.Events = {};

    DOM.Events.VERSION = "0.02";
	DOM.Events.EXPORT = [];
	DOM.Events.EXPORT_OK = ["addListener", "removeListener"];
	DOM.Events.EXPORT_TAGS = {
		":common": DOM.Events.EXPORT,
		":all": [].concat(DOM.Events.EXPORT, DOM.Events.EXPORT_OK)
	};

	// list of event listeners set by addListener
	// offset 0 is null to prevent 0 from being used as a listener identifier
	var listenerList = [null];

	DOM.Events.addListener = function(elt, ev, func, makeCompatible) {
		var usedFunc = func;
        var id = listenerList.length;
		if(makeCompatible == true || makeCompatible == undefined) {
			usedFunc = makeCompatibilityWrapper(elt, ev, func);
		}
		if(elt.addEventListener) {
			elt.addEventListener(ev, usedFunc, false);
			listenerList[id] = [elt, ev, usedFunc];
			return id;
		}
		else if(elt.attachEvent) {
			elt.attachEvent("on" + ev, usedFunc);
			listenerList[id] = [elt, ev, usedFunc];
			return id;
		}
		else return false;
	};

	DOM.Events.removeListener = function() {
		var elt, ev, func;
		if(arguments.length == 1 && listenerList[arguments[0]]) {
			elt  = listenerList[arguments[0]][0];
			ev   = listenerList[arguments[0]][1];
			func = listenerList[arguments[0]][2];
			delete listenerList[arguments[0]];
		}
		else if(arguments.length == 3) {
			elt  = arguments[0];
			ev   = arguments[1];
			func = arguments[2];
		}
		else return;

		if(elt.removeEventListener) {
			elt.removeEventListener(ev, func, false);
		}
		else if(elt.detachEvent) {
			elt.detachEvent("on" + ev, func);
		}
	};

    var rval;

    function makeCompatibilityWrapper(elt, ev, func) {
        return function (e) {
            rval = true;
            if(e == undefined && window.event != undefined)
                e = window.event;
            if(e.target == undefined && e.srcElement != undefined)
                e.target = e.srcElement;
            if(e.currentTarget == undefined)
                e.currentTarget = elt;
            if(e.relatedTarget == undefined) {
                if(ev == "mouseover" && e.fromElement != undefined)
                    e.relatedTarget = e.fromElement;
                else if(ev == "mouseout" && e.toElement != undefined)
                    e.relatedTarget = e.toElement;
            }
            if(e.pageX == undefined) {
                if(document.body.scrollTop != undefined) {
                    e.pageX = e.clientX + document.body.scrollLeft;
                    e.pageY = e.clientY + document.body.scrollTop;
                }
                if(document.documentElement != undefined
                && document.documentElement.scrollTop != undefined) {
                    if(document.documentElement.scrollTop > 0
                    || document.documentElement.scrollLeft > 0) {
                        e.pageX = e.clientX + document.documentElement.scrollLeft;
                        e.pageY = e.clientY + document.documentElement.scrollTop;
                    }
                }
            }
            if(e.stopPropagation == undefined)
                e.stopPropagation = IEStopPropagation;
            if(e.preventDefault == undefined)
                e.preventDefault = IEPreventDefault;
            if(e.cancelable == undefined) e.cancelable = true;
            func(e);
            return rval;
        };
    }

    function IEStopPropagation() {
        if(window.event) window.event.cancelBubble = true;
    }

    function IEPreventDefault() {
        rval = false;
    }

	function cleanUpIE () {
		for(var i=0; i<listenerList.length; i++) {
			var listener = listenerList[i];
			if(listener) {
				var elt = listener[0];
                var ev = listener[1];
                var func = listener[2];
				elt.detachEvent("on" + ev, func);
			}
		}
        listenerList = null;
	}

	if(!window.addEventListener && window.attachEvent) {
		window.attachEvent("onunload", cleanUpIE);
	}

})();

/**

=head1 AUTHOR

Justin Constantino, <F<goflyapig@gmail.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Justin Constantino.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public Licence.

*/

/* /home/autarch/projects/Silki/share/js-source/Textarea.js */

Textarea = function (textarea) {
    if ( textarea.tagName != "TEXTAREA" ) {
        throw "Textarea requires a textarea as its constructor argument";
    }

    /* IE just does not work yet */
    if ( document.selection && document.selection.createRange ) {
        return;
    }

    this.textarea = textarea;
};

if ( document.selection && document.selection.createRange ) {
    Textarea.prototype.selectedText = function () {
        var text = document.selection.createRange().text;

        if ( typeof text == "undefined" ) {
            return "";
        }

        return text;
    };

    Textarea.prototype.replaceSelectedText = function (text) {
        this.textarea.focus();

        var range = document.selection.createRange();
        range.text = text;

        range.select();
    };

    Textarea.prototype.caretPosition = function () {
        this.textarea.focus();
        return this.textarea.selectionStart;
    };

    Textarea.prototype.selectText = function ( start, end ) {
        this.textarea.focus();

        var range = this._makeNewRange( start, end );
    };

    Textarea.prototype.moveCaret = function (offset) {
        var pos = this.caretPosition() + offset;

        var range = this._makeNewRange( pos, pos );
        range.select();
    };

    Textarea.prototype._makeNewRange = function ( start, end ) {
        this.textarea.focus();

        var range = document.selection.createRange();
        range.collapse(true);
        range.moveEnd( "character", start );
        range.moveStart( "character", end );

        return range();
    };
}
else {
    Textarea.prototype.selectedText = function () {
        var start = this.textarea.selectionStart;
        var end = this.textarea.selectionEnd;

        var text = this.textarea.value.substring( start, end );

        if ( typeof text == "undefined" ) {
            return "";
        }

        return text;
    };

    Textarea.prototype.replaceSelectedText = function (text) {
        var start = this.textarea.selectionStart;
        var end = this.textarea.selectionEnd;

        var scroll = this.textarea.scrollTop;

        this.textarea.value =
            this.textarea.value.substring( 0, start )
            + text
            + this.textarea.value.substring( end, this.textarea.value.length );

        this.textarea.focus();

        this.textarea.selectionStart = start + text.length;
        this.textarea.selectionEnd = start + text.length;
        this.textarea.scrollTop = scroll;
    };

    Textarea.prototype.caretPosition = function () {
        return this.textarea.selectionStart;
    };

    Textarea.prototype.selectText = function ( start, end ) {
        this.textarea.selectionStart = start;
        this.textarea.selectionEnd = end;
    };

    Textarea.prototype.moveCaret = function (offset) {
        var new_pos = this.caretPosition() + offset;

        this.textarea.setSelectionRange( new_pos, new_pos );
    };
}

Textarea.prototype.previousLine = function () {
    var text = this.textarea.value;

    var last_line_end = text.lastIndexOf( "\n", this.caretPosition() - 1);

    if ( ! last_line_end ) {
        return "";
    }
    else {
        var prev_line_start = text.lastIndexOf( "\n", last_line_end - 1 ) + 1;
        return text.substr( prev_line_start, last_line_end - prev_line_start );
    }
}

Textarea.prototype.caretIsMidLine = function () {
    var pos = this.caretPosition();

    if ( pos == 0 ) {
        return false;
    }

    var char_before = this.textarea.value.substr( pos - 1, 1 );
    if ( char_before == "\n" || char_before == "" ) {
        return false;
    }
    else {
        return true;
    }
};

Textarea.prototype.moveCaretToBeginningOfLine = function () {
    var pos = this.textarea.value.lastIndexOf( "\n", this.caretPosition() );

    if ( pos == -1 ) {
        this.moveCaret( -1 * this.caretPosition() );
        return;
    }

    if ( pos == this.caretPosition() ) {
        /* If we take the char before and the char after the caret
         * and they're both newlines, then that means the caret is
         * currently at the head of an empty line. If, however, the
         * character before the caret's position is _not_ a newline,
         * it means we're at the end of a line. */
        if ( this.textarea.value.substr( this.caretPosition() -1, 2 ) != "\n\n" ) {
            this.moveCaret( -1 * this.caretPosition() );
        }
        return;
    }

    this.moveCaret( ( pos - this.caretPosition() ) + 1 );
};


/* /home/autarch/projects/Silki/share/js-source/Silki/PageEdit/Toolbar.js */

JSAN.use('DOM.Element');
JSAN.use('DOM.Events');
JSAN.use('DOM.Utils');
JSAN.use('Textarea');

Silki.PageEdit.Toolbar = function () {
    /* Not really working yet */
    return;

    this.textarea = new Textarea ( $("page-content") );

    if ( ! this.textarea ) {
        return;
    }

    for ( var i = 0; i < Silki.PageEdit.Toolbar._Buttons.length; i++ ) {
        var button_def = Silki.PageEdit.Toolbar._Buttons[i];

        var button = $( button_def[0] + "-button" );

        if ( ! button ) {
            continue;
        }

        if ( typeof button_def[1] == "function" ) {
            this._instrumentButton( button, button_def[1] );
        }
        else {
            var open = button_def[1];
            var close = button_def[2];

            var func = this._makeTagTextFunction( open, close );

            this._instrumentButton( button, func );
        }
    }

    DOM.Element.show( $("toolbar") );
};

Silki.PageEdit.Toolbar.prototype._makeTagTextFunction = function ( open, close ) {
    var self = this;

    var func = function () {
        var text = self.textarea.selectedText();

        var result = text.match( /^(\s+)?(.+?)(\s+)?$/ );

        var new_text;
        if ( result && result[0] ) {
            new_text =
                ( typeof result[1] != "undefined" ? result[1] : "" )
                + open + result[2] + close +
                ( typeof result[3] != "undefined" ? result[3] : "" );
        }
        else {
            new_text = open + text + close;
        }

        self.textarea.replaceSelectedText(new_text);

        if ( ! text.length ) {
            self.textarea.moveCaret( close.length * -1 );
        }
    };

    return func;
};

Silki.PageEdit.Toolbar.prototype._instrumentButton = function ( button, func ) {
    var self = this;

    var on_click = function () {
        /* get selected text */
       func.apply(self);
    };

    DOM.Events.addListener( button, "click", on_click );
};

Silki.PageEdit.Toolbar._insertBulletList = function () {
    this._insertBullet("*");
};

Silki.PageEdit.Toolbar._insertNumberList = function () {
    this._insertBullet("1.");
};

Silki.PageEdit.Toolbar.prototype._insertBullet = function (bullet) {
    var insert;
    var old_pos;

    if ( this.textarea.caretIsMidLine() ) {
        insert = bullet + " ";
        old_pos = this.textarea.caretPosition();
    }
    else {
        insert = bullet + " \n\n";
    }

    if ( ! this.textarea.previousLine().match(/^\n?$/) ) {
        insert = "\n" + insert;
    }

    this.textarea.moveCaretToBeginningOfLine();

    this.textarea.replaceSelectedText(insert);

    if (old_pos) {
        this.textarea.moveCaret( ( old_pos - this.textarea.caretPosition() ) + insert.length );
    }
    else {
        this.textarea.moveCaret(-2);
    }
};

Silki.PageEdit.Toolbar._makeInsertHeaderFunction = function (header) {
    var func = function () {
        var old_pos;

        var insert = header + " ";

        if ( this.textarea.caretIsMidLine() ) {
            old_pos = this.textarea.caretPosition();
        }
        else {
            insert = insert + "\n\n";
        }

        this.textarea.moveCaretToBeginningOfLine();

        this.textarea.replaceSelectedText(insert);

        if (old_pos) {
            this.textarea.moveCaret( ( old_pos - this.textarea.caretPosition() ) + insert.length );
        }
        else {
            this.textarea.moveCaret(-2);
        }
    };

    return func;
};

Silki.PageEdit.Toolbar._Buttons = [ [ "h2", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('##') ],
                            [ "h3", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('###') ],
                            [ "h4", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('####') ],
                            [ "bold", "**", "**" ],
                            [ "italic", "*", "*" ],
                            [ "bullet-list", Silki.PageEdit.Toolbar._insertBulletList ],
                            [ "number-list", Silki.PageEdit.Toolbar._insertNumberList ]
                          ];


/* /home/autarch/projects/Silki/share/js-source/DOM/Find.js */

if ( typeof DOM == "undefined") DOM = {};

DOM.Find = {

  VERSION: 1.00,

  EXPORT: [ 'checkAttributes','getElementsByAttributes', 'geba' ],

  checkAttributes: function(hash,el){

      // Check that passed arguments make sense

      if( el === undefined || el === null )
        throw("Second argument to checkAttributes should be a DOM node or the ID of a DOM Node");

      if( el.constructor === String )
        el = document.getElementById(el);

      if( el === null || !el.nodeType ) // Make sure el is a Node
        throw("Second argument to checkAttributes should be a DOM node or the ID of a DOM Node");

      if(! (hash instanceof Object))
        throw("First argument to checkAttributes should be an Object of attribute/test pairs. See the documentation for more information.");

      // If we're still here, check the test pairs

      for(key in hash){

        /*
          Prepare the "pointer"
        */

        // Check to make sure property chain is valled
        // Provides easy declaration of nested propteries
        // Example: {'style.position':'absolute'}

        var pointer = el      // pointer
        var last    = null;   // last pointer used to aplly() later

        var pieces  = key.split('.');                   // break up the property chain

        for(var i=0; i<pieces.length; i++){             // loop property chain
          // There can be no match
          // if the attribute does not exist
          if(!pointer[pieces[i]]) return false;         // test the pointer exists
          // Save the current pointer
          last    = pointer;                            // backup current pointer
          // Develope the pointer
          pointer = pointer[pieces[i]];                 // stack the pointer
        }

        // Check if the pointer is actually a function
        // Provides easy declaration of methods
        // Example: {'hasChildNodes':true}
        // Example: {'firstChild.hasChildNodes':true}

        // Does not work in IE
        // IE returns Object instead of Function
        if( pointer instanceof Function )
          try {
            pointer = pointer.apply(last);
          }catch(error){
            throw("First agrument to checkAttributes included a Function Refrence which caused an ERROR: " +  error);
          }

        /*
          Test "pointer" against "value"
        */

        // Perform one of 3 tests
        // Regex, Function, Scalar

        // Check against a regex
        if( hash[key] instanceof RegExp ){
          if( !hash[key].test( pointer ) )
             return false;

        // Check against a function
        }else if( hash[key] instanceof Function ){
          if( !hash[key]( pointer ) )
            return false;

        // Or check against a scalar value
        }else if( hash[key] != pointer ){
          return false;
        }

      }

      return true;
  },

  getElementsByAttributes: function( searchAttributes, startAt, resultsLimit, depthLimit ) {

     // if we haven't been deep enough yet
     if(depthLimit !== undefined && depthLimit <= 0) return [];

     // if no startAt is provided use document as default
     if(startAt === undefined){
       startAt = document;

     // if startAt is a string convert it to a domref
     }else if(typeof startAt == 'string'){
       startAt = document.getElementById(startAt);
     }

     // check the startAt element
     var results = DOM.Find.checkAttributes(searchAttributes, startAt) ? [ startAt ] : [];

     // return the results right away if they only want 1 result
     if(resultsLimit == 1 && results.length > 0) return results;

     // Scan the childNodes of startAt
     if (startAt.childNodes)
       for( var i = 0; i < startAt.childNodes.length; i++){
         // concat onto results any childNodes that match
         results = results.concat(
            DOM.Find.getElementsByAttributes( searchAttributes, startAt.childNodes[i], (resultsLimit) ? resultsLimit - results.length : undefined, (depthLimit) ? depthLimit -1 : undefined )
         )
         if (resultsLimit !== undefined && results.length >= resultsLimit) break;
       }

     return results;
  }

}

/*

=head1 AUTHOR

Daniel, Aquino <mr.danielaquino@gmail.com>.

=head1 COPYRIGHT

  Copyright (c) 2007 Daniel Aquino.
  Released under the Perl Licence:
  http://dev.perl.org/licenses/

*/


/* /home/autarch/projects/Silki/share/js-source/Silki/PageTags.js */

JSAN.use('DOM.Events');
JSAN.use('DOM.Find');
JSAN.use('HTTP.Request');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.PageTags = function () {
    var form = $("tags-form");

    if (! form) {
        return;
    }

    this._form = form;

    this._instrumentForm();
    this._instrumentDeleteURIs();
};

Silki.PageTags.prototype._instrumentForm = function () {
    var self = this;

    DOM.Events.addListener(
        this._form,
        "submit",
        function (e) {
            e.preventDefault();
            e.stopPropagation();

            self._submitForm();
        }
    );
};

Silki.PageTags.prototype._submitForm = function () {
    var tags = this._form.tags.value;

    if ( ! tags && tags.length ) {
        return;
    }

    var self = this;

    var on_success = function (trans) {
        self._form.tags.value = "";
        self._updateTagList(trans);
    };

    new HTTP.Request( {
        "uri":        this._form.action,
        "parameters": "tags=" + encodeURIComponent(tags),
        "onSuccess":  on_success
    } );
};

Silki.PageTags.prototype._parameters = function () {
    return "tags=" + encodeURIComponent( this.text.value );
};

Silki.PageTags.prototype._updateTagList = function (trans) {
    var resp = eval( "(" + trans.responseText + ")" );

    var list = $("tags-list");

    list.parentNode.innerHTML = resp.tag_list_html;

    this._instrumentDeleteURIs();

    return;
};

Silki.PageTags.prototype._instrumentDeleteURIs = function () {
    var anchors = DOM.Find.getElementsByAttributes(
        {
            tagName:   "A",
            className: /\bdelete-tag\b/
        },
        $("tags-list")
    );

    if ( ! anchors.length ) {
        return;
    }

    for ( var i = 0; i < anchors.length; i++ ) {
        var func = this._makeDeleteTagFunction();

        DOM.Events.addListener(
            anchors[i],
            "click",
            func
        );
    }
};

Silki.PageTags.prototype._makeDeleteTagFunction = function (anchor) {
    var self = this;

    var func = function (e) {
        e.preventDefault();
        e.stopPropagation();

        var on_success = function (trans) { self._updateTagList(trans); };

        new HTTP.Request( {
            "uri":       e.currentTarget.href,
            "method":    "DELETE",
            "onSuccess": on_success
        } );
    };

    return func;
};

/* /home/autarch/projects/Silki/share/js-source/Silki/URI.js */

Silki.URI = {};

Silki.URI.dynamicURI = function (path) {
    var uri = Silki.URI._dynamicURIRoot == "/" ? "" : Silki.URI._dynamicURIRoot;

    if ( uri.length ) {
        uri = uri + "/" + path;
    }
    else {
        uri = path;
    }

    return uri;
};

Silki.URI.staticURI = function (path) {
    var uri = Silki.URI._staticURIRoot == "/" ? "" : Silki.URI._staticURIRoot;

    if ( uri.length ) {
        uri = uri + "/" + path;
    }
    else {
        uri = path;
    }

    return uri;
};


/* /home/autarch/projects/Silki/share/js-source/Silki/ProcessStatus.js */

JSAN.use('DOM.Element');
JSAN.use('Silki.URI');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.ProcessStatus = function () {
    var status = $("process-status");
    var complete = $("process-complete");

    if ( ! ( status && complete ) ) {
        return;
    }

    var process_id = ( /js-process-id-(\d+)/.exec( status.className) )[1];
    if ( ! process_id ) {
        return;
    }

    var process_type = ( /js-process-type-(\w+)/.exec( status.className ) )[1];
    if ( ! process_type ) {
        return;
    }

    this._process_id = process_id;
    this._process_type = process_type;
    this._uri = Silki.URI.dynamicURI( "/process/" + this._process_id );
    this._status_div = status;
    this._complete_div = complete;
    this._last_status = "";
    this._last_status_change = ( new Date() ).getTime();
    this._spinner = '<img src="' + Silki.URI.staticURI( "/images/small-spinner.gif" ) + '" />';

    this._setupInterval();
};

Silki.ProcessStatus.prototype._setupInterval = function () {
    var self = this;
    var func = function () { self._getProcessStatus(); };

    this._interval_id = setInterval( func, 1000 );
};

Silki.ProcessStatus.prototype._getProcessStatus = function () {
    /* Processing large tarballs can take a lot of time. */
    if ( ( new Date() ).getTime() - this._last_status_change > ( 60 * 20 * 1000 ) ) {
        this._status_div.innerHTML = this._process_type + " appears to have stalled on the server. Giving up.";
        return;
    }

    var self = this;

    var on_success = function (trans) {
        self._updateStatus(trans);
    };

    var on_failure = function (trans) {
        self._handleFailure();
    };

    new HTTP.Request( {
        "uri":       this._uri,
        "method":    "get",
        "onSuccess": on_success,
        "onFailure": on_failure
    } );
};

Silki.ProcessStatus.prototype._updateStatus = function (trans) {
    var process = eval( "(" + trans.responseText + ")" );

    if ( process.is_complete ) {
        clearInterval( this._interval_id );

        if ( process.was_successful ) {
            this._status_div.innerHTML = this._process_type + " is complete.";

            this._complete_div.innerHTML = this._complete_div.innerHTML.replace( "@result@", process.final_result );

            DOM.Element.show( this._complete_div );
        }
        else {
            this._status_div.innerHTML = this._process_type + " failed.";
        }
    }
    else if ( process.status.length ) {
        if ( this._last_status != process.status ) {
            this._last_status_change = ( new Date() ).getTime();
            this._last_status = process.status;
        }

        this._status_div.innerHTML = this._spinner + " " + this._process_type + " is in progress - " + process.status + ".";
    }
};

Silki.ProcessStatus.prototype._handleFailure = function (trans) {
    clearInterval( this._interval_id );

    this._status_div.innerHTML = "Cannot retrieve process status from server.";
};


/* /home/autarch/projects/Silki/share/js-source/Silki/QuickSearch.js */

JSAN.use('DOM.Events');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.QuickSearch = function () {
    var input = $("quick-search-input");

    if ( ! input ) {
        return;
    }

    var match = input.className.match( /js-default-text-(\w+)/ );
    var default_val = match[1];

    DOM.Events.addListener( input,
                            "focus",
                            function () {
                                if ( input.value == default_val ) {
                                    input.value = "";
                                }
                            }
                          );
};

/* /home/autarch/projects/Silki/share/js-source/Silki/SystemLogs.js */

JSAN.use('DOM.Element');
JSAN.use('DOM.Events');
JSAN.use('DOM.Find');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.SystemLogs = function () {
    var table = $("system-logs");

    if ( ! table ) {
        return;
    }

    var toggles = DOM.Find.getElementsByAttributes(
        {
            "tagName": "A",
            "className": "toggle-more"
        },
        table
    );

    for ( var i = 0; i < toggles.length; i++ ) {
        var matches = toggles[i].id.match( /toggle-more-(\d+)/ );

        if ( ! matches && matches[1] ) {
            continue;
        }

        var pre = $( "more-" + matches[1] );

        if ( ! pre ) {
            continue;
        }

        DOM.Events.addListener(
            toggles[i],
            "click",
            this._makeToggleFunction(pre)
        );
    }
};

Silki.SystemLogs.prototype._makeToggleFunction = function (pre) {
    var p = pre;

    var func = function (e) {
        e.preventDefault();
        e.stopPropagation();

        DOM.Element.toggle(p);
    };

    return func;
};


/* /home/autarch/projects/Silki/share/js-source/HTTP/Cookies.js */

// HTTP.Cookies by Burak Gürsoy <burak[at]cpan[dot]org>
if (!HTTP) var HTTP = {};

HTTP.Cookies = function () {
   this._reset();
}

// expire time calculation
HTTP.Cookies.Date = function () {
   this._init();
}

HTTP.Cookies.VERSION     = '1.11';
HTTP.Cookies.ERRORLEVEL  = 1;
HTTP.Cookies.Date.FORMAT = {
   's' :  1,
   'm' : 60,
   'h' : 60 * 60,
   'd' : 60 * 60 * 24,
   'M' : 60 * 60 * 24 * 30,
   'y' : 60 * 60 * 24 * 365
};

HTTP.Cookies.prototype._reset = function () {
   this['JAR']     = ''; // data cache
   this['CHANGED'] =  0; // cookies altered?
}

// Get the value of the named cookie. Usage: password = cookie.read('password');
HTTP.Cookies.prototype.read = function (name) {
	if(!name) return this._fatal('read', 'Cookie name is missing');
   if(this.CHANGED) this._reset();
   // first populate the internal cache, then return the named cookie
   var value = '';
   this._parse();
   for ( var cookie in this.JAR ) {
      if ( cookie == name ) {
         value = this.JAR[cookie];
         break;
      }
	}
   return value ? value : '';
}

// Create a new cookie or overwrite existing.
// Usage: cookie.write('password', 'secret', '1m');
HTTP.Cookies.prototype.write = function (name, value, expires, path, domain, secure) {
	if(!name) return this._fatal('write', 'Cookie name is missing');
	if(typeof value == 'undefined') value = ''; // workaround
   if (!expires) expires = '';
   if (expires == '_epoch') {
      expires = new Date(0);
   }
   else if (expires != -1) {
      var cdate = new HTTP.Cookies.Date;
      var Now   = new Date;
      Now.setTime(Now.getTime() + cdate.parse(expires));
      expires = Now.toGMTString();
   }
   var extra = '';
   if(expires) extra += '; expires=' + expires;
   if(path   ) extra += '; path='    + path;
   if(domain ) extra += '; domain='  + domain;
   if(secure ) extra += '; secure='  + secure;
   // name can be non-alphanumeric
   var new_cookie  = escape(name) + '=' + escape(value) + extra;
   document.cookie = new_cookie;
   this.CHANGED    = 1; // reset the object in the next call to read()
}

// Delete the named cookie. Usage: cookie.remove('password');
HTTP.Cookies.prototype.remove = function (name, path, domain, secure) {
	if(!name) return this._fatal('remove', 'Cookie name is missing');
   this.write(name, '', '_epoch', path, domain, secure);
}

// cookie.obliterate()
HTTP.Cookies.prototype.obliterate = function () {
   var names = this.names();
   for ( var i = 0; i < names.length; i++ ) {
		if ( !names[i] ) continue;
      this.remove( names[i] );
	}
}

// var cnames = cookie.names()
HTTP.Cookies.prototype.names = function () {
   this._parse();
   var names = [];
   for ( var cookie in this.JAR ) {
		if ( !cookie ) continue;
      names.push(cookie);
	}
	return names;
}

HTTP.Cookies.prototype._parse = function () {
   if(this.JAR) return;
	this.JAR  = {};
   var NAME  = 0; // field id
   var VALUE = 1; // field id
   var array = document.cookie.split(';');
   for ( var element = 0; element < array.length; element++ ) {
      var pair = array[element].split('=');
      pair[NAME] = pair[NAME].replace(/^\s+/, '');
      pair[NAME] = pair[NAME].replace(/\s+$/, '');
      // populate
      this.JAR[ unescape(pair[NAME]) ] = unescape( pair[VALUE] );
   }
}

HTTP.Cookies.prototype._fatal = function (caller, error) {
   var title = 'HTTP.Cookies fatal error';
   switch(HTTP.Cookies.ERRORLEVEL) {
      case 1:
         alert( title + "\n\n"  + caller + ': ' + error );
         break;
      default:
         break;
   }
}

HTTP.Cookies.Date.prototype._fatal = function (caller, error) {
   var title = "HTTP.Cookies.Date fatal error";
   switch(HTTP.Cookies.ERRORLEVEL) {
      case 1:
         alert( title + "\n\n"  + caller + ': ' + error );
         break;
      default:
         break;
   }
}

// HTTP.Cookies.Date Section begins here

HTTP.Cookies.Date.prototype._init = function () {
   this.FORMAT = HTTP.Cookies.Date.FORMAT;
}

HTTP.Cookies.Date.prototype.parse = function (x) {
   if(!x || x == 'now') return 0;
   var NUMBER = 1;
   var LETTER = 2;
   var date = x.match(/^(.+?)(\w)$/i);

   if ( !date ) {
		return this._fatal(
			       'parse',
			       'expires parameter (' + x + ') is not valid'
			    );
	}

   var is_num = this.is_num(  date[NUMBER] );
   var of     = this.is_date( date[NUMBER], date[LETTER] );
   return (is_num && of) ? of : 0;
}

HTTP.Cookies.Date.prototype.is_date = function (num, x) {
   if (!x || x.length != 1) return 0;
   var ar = [];
   return (ar = x.match(/^(s|m|h|d|w|M|y)$/) ) ? num * 1000 * this.FORMAT[ ar[0] ] : 0;
}

HTTP.Cookies.Date.prototype.is_num = function (x) {
   if (x.length == 0) return;
   var ok = 1;
   for (var i = 0; i < x.length; i++) {
      if ( "0123456789.-+".indexOf( x.charAt(i) ) == -1 ) {
         ok--;
         break;
      }
   }
   return ok;
}


/* /home/autarch/projects/Silki/share/js-source/Silki/User.js */

JSAN.use('HTTP.Cookies');
JSAN.use('HTTP.Request');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.User = function (user_id) {
    if ( typeof user_id == "undefined" ) {
        var cookies = new HTTP.Cookies ();
        var user_cookie = cookies.read("Silki-user");
        var match = user_cookie.match( /user_id\&(\d+)/ );

        if ( match && match[1] ) {
            user_id = match[1];
        }
        else {
            user_id = "guest";
        }
    }

    this._userId = user_id;
};

Silki.User.prototype.getWikis = function () {
    if ( typeof this._wikis != "undefined" ) {
        return this._wikis;
    }

    var req = new HTTP.Request ( { "method":       "get",
                                   "uri":          this._uri("wikis"),
                                   "asynchronous": 0
                                 }
                               );

    if ( req.isSuccess() ) {
        var results = eval( "(" + req.transport.responseText + ")" );
        this._wikis = results;
    }
    else {
        this._wikis = [];
    }

    return this._wikis;
};

Silki.User.prototype._uri = function (view) {
    var uri = "/user/" + this._userId;

    if ( typeof view != "undefined" ) {
        uri = uri + "/" + view;
    }

    return uri;
};


Silki.User.prototype._handleSuccess = function (trans) {
    var results = eval( "(" + trans.responseText + ")" );

    this._wikis = results;
};

Silki.User.prototype._handleFailure = function (trans) {
    this._wikis = [];
};


/* /home/autarch/projects/Silki/share/js-source/Silki.js */

JSAN.use('DOM.Ready');
JSAN.use('Silki.FileView');

/* These three need to be loaded in this order so Silki.PageEdit can define
   itself first */
JSAN.use('Silki.PageEdit');
JSAN.use('Silki.PageEdit.Preview');
JSAN.use('Silki.PageEdit.Toolbar');

JSAN.use('Silki.PageTags');
JSAN.use('Silki.ProcessStatus');
JSAN.use('Silki.QuickSearch');
JSAN.use('Silki.SystemLogs');
JSAN.use('Silki.URI');
JSAN.use('Silki.User');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.instrumentAll = function () {
    new Silki.FileView ();
    new Silki.PageEdit ();
    new Silki.PageTags ();
    new Silki.ProcessStatus ();
    new Silki.QuickSearch ();
    new Silki.SystemLogs ();
};

DOM.Ready.onDOMDone( Silki.instrumentAll );
