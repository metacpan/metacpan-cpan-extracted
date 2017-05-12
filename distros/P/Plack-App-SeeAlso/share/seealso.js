/**
 * @fileoverview
 * JavaScript client for the SeeAlso Linkserver protocol, including several
 * display styles to display the results of a SeeAlso Linkserver in HTML.
 *
 * More information and examples on how to use this client can be
 * found in the README file of this distribution.

 * Copyright (c) 2008-2009 Jakob Voss (GBV).
 * Dual licensed under the General Public License (GPL.txt)
 * and the license and Affero General Public License (AGPL.txt).
 *
 * This library is compatible with <a href="http://jquery.com">jQuery</a>
 * but does not need it.
 *
 * See also the <a href="http://search.cpan.org/dist/SeeAlso-Server/">Perl module</a>.
 *
 * @link     http://ws.gbv.de/seealso/
 * @author   Jakob Voss
 * @version  0.6.9f
 */


/**
* Creates a SeeAlso Simple Response.
* @class Represents a SeeAlso Simple Response.
*
* @param {mixed} [content] content of the response (see {@link #set} for details).
*/
function SeeAlsoResponse(content) {
    this.set(content);
}

/**
 * Sets the whole response content.
 *
 * <p>You can either set the identifier value only:
 * <pre>response.set("id123");</pre>
 * or pass a JSON string:<br />
 * <pre>response.set("['id123',['label1'],['descr1'],['uri1']");</pre>
 * or pass a JSON array object<br />
 * <pre>response.set(['id123',['label1'],['descr1'],['uri1']);</pre></p>
 *
 * @param {mixed} value either an identifier string or an array or a JSON string
 */
SeeAlsoResponse.prototype.set = function(value) {
    this.identifier = "";
    this.labels = [];
    this.descriptions = [];
    this.uris = [];
    if (typeof value == "object") {
        if (typeof value[0] == "string") 
            this.identifier = value[0];
        if (typeof value[1] == "object") {
            var d = typeof value[2] == "object" ? value[2] : "";
            var u = typeof value[3] == "object" ? value[3] : "";
            if (typeof value[3] != "object") value[3] = [];
            for (var i=0; i<value[1].length; i++) {
                this.add(value[1][i], d ? d[i] : "", u ? u[i] : "");
            }
        }
    } else if (typeof value == "string") {
        if (/^\s*\[/.test(value)) {
            this.set(JSON.parse(value));
        } else {
            this.identifier = value;
        }
    }
};

/**
 * Returns the JSON representation of this response.
 *
 * @param  {String} [callback] callback method
 * @return {String} response in JSON format, optionally wrapped with a
 *                  callback method call.
 */
SeeAlsoResponse.prototype.toJSON = function(callback) {
    if (! /^[a-zA-Z0-9\._\[\]]+$/.test(callback) ) callback = "";
    var json = JSON.stringify( 
        [ this.identifier, this.labels, this.descriptions, this.uris ]
    );
    return callback ? callback + "(" + json + ");" : json;
};

/**
 * Adds an item to the response.
 * @param {String} label a response label (empty string by default)
 * @param {String} description a response description (empty string by default)
 * @param {String} uri a response uri (empty string by default)
 */
SeeAlsoResponse.prototype.add = function(label, description, uri) {
    this.labels.push( typeof label == "string" ? label : "" );
    this.descriptions.push( typeof description == "string" ? description : "" );
    this.uris.push( typeof uri == "string" ? uri : "" );
};

/**
 * Gets an item of the response.
 * <p>The return value is either an object with properties 'label', 
 * 'description', and 'uri', or an empty object.</p>
 * @returns an item (as object) of the <em>n</em>th label, description, and uri
 * @param {Integer} i index, starting from 0
 * @type Object
 */
SeeAlsoResponse.prototype.get = function(i) {
    if (!(i>=0 && i<this.labels.length)) return {};
    return {
        label:       this.labels[i], 
        description: this.descriptions[i],
        uri:         this.uris[i]
    };
};

/**
 * Gives the number of items in the response.
 * @return {Integer} the number of items of this response.
 */
SeeAlsoResponse.prototype.size = function() { 
    return this.labels.length; 
};

/**
 * Get the query parameter.
 * @return {String} the query parameter of this response
 */
SeeAlsoResponse.prototype.getQuery = function() {
   return this.identifier; 
}

/**
 * Create a display style to process and display a {@link SeeAlsoResponse}.
 * @class Style to display a SeeAlsoResponse in HTML.
 *
 * @param [p] additional display parameters
 * @param {String|Function} [p.preHTML=""]
 *        HTML fragment before all items (if any)
 * @param {String|Function} [p.postHTML=""]
 *        HTML fragment after all items (if any)
 * @param {String} [p.delimHTML=", "]
 *        HTML fragment between items
 * @param {Function} [p.itemHTML]
 *        function that creates HTML for one item
 * @param [p.emptyHTML=""]
 *        HTML to return if the response is empty
 * @param {Integer} [p.maxItems=10]
 *        maximum number of items to show (negative: inf)
 * @param {String|Function} [p.moreHTML]
 *        HTML fragment to append if maximum number is exceeded
 * @param {Function|Object} [p.itemAttr]
 *        additional HTML attributes for each item
 * @param [p.linkTarget]
 *        target attribut for links (for instance "new" to open a new window)
 * @param [p.responseFilter]
 *        function to filter the whole response before displaying (not tested)
 * @param [p.itemFilter]
 *        function to filter each item before displaying (not tested)
 */
function SeeAlsoView(p) {
    p = (typeof p == "object") ? p : {};

    this.preHTML = (typeof p.preHTML == "string" || typeof p.preHTML == "function")
        ? p.preHTML : "";
    this.postHTML = (typeof p.postHTML == "string" || typeof p.postHTML == "function")
        ? p.postHTML : "";
    this.delimHTML = typeof p.delimHTML == "string" ? p.delimHTML : ", ";
    this.itemHTML = typeof p.itemHTML == "function" ? p.itemHTML : this.defaultItemHTML;
    this.emptyHTML = (typeof p.emptyHTML == "string" || typeof p.emptyHTML == "function")
        ? p.emptyHTML : "";
    this.maxItems = typeof p.maxItems == "number" ? p.maxItems : 10;
    this.moreHTML = typeof p.moreHTML != "undefined" ? p.moreHTML : " ...";

    this.linkTarget = typeof p.linkTarget == "string" ? p.linkTarget : "";

    if (typeof p.itemAttr != "undefined") {
        if (typeof p.itemAttr == "object") {
            this.itemAttr = function (item) { return p.itemAttr; }
        } else if (typeof p.itemAttr == "function") {
            this.itemAttr = p.itemAttr;
        }
    }

    if (typeof p.itemFilter == "function") this.itemFilter = p.itemFilter;
    if (typeof p.responseFilter == "function") this.responseFilter = p.responseFilter;
}


/**
 * Default method to create HTML from one item
 */
SeeAlsoView.prototype.defaultItemHTML = function(item) {
    var label = item.label != "" ? item.label : item.uri;
    if (label == "") return "";
    var html, attr = {}, elem;

    if (item.uri) {
        elem = "a";
        attr['href'] = item.uri;
        if (this.linkTarget) attr['target'] = this.linkTarget;
        // TODO: not tested!
        if (item.description != "") attr['title'] = item.description;
    }

    if (typeof this.itemAttr == "function") {
        var ia = this.itemAttr(item);
        for (key in ia) attr[key] = ia[key];
    }

    // add 'span' element only if needed
    if (!elem) { for (i in attr) { elem = "span"; break; } }

    if (elem) {
        html = '<'+elem;
        for (p in attr) {
            html += ' ' + p + '="' + this.escapeHTML(attr[p]) + '"';
        }
        html += '>' + this.escapeHTML(label) + '</'+elem+'>';
    } else {
        html = this.escapeHTML(label);
    }
    return html;
}

/**
 * Create an HTML string to display a given response.
 *
 * @see SeeAlsoResponse#set
 * @returns an HTML string
 * @type String
 */
SeeAlsoView.prototype.makeHTML = function(response) {
    if (!(response instanceof SeeAlsoResponse)) {
        response = new SeeAlsoResponse(response)
    }

    if (typeof this.responseFilter == "function")
        response = this.responseFilter(response);

    // TODO: itemFilter

    if (!response || typeof response != "object" || !response.size()) {
        return (typeof this.emptyHTML == "function"
            ? this.emptyHTML(response.identifier) : this.emptyHTML);
    }

    var html = typeof this.preHTML == "function"
        ? this.preHTML(response) : this.preHTML;
    for(var i=0; i<response.size(); i++) {
        if (this.maxItems >= 0 && i >= this.maxItems) {
            html += typeof this.moreHTML == "function"
                ? this.moreHTML(response) : this.moreHTML;
            break;
        }
        if (i>0) {
            html += this.delimHTML;
        }
        html += this.itemHTML( response.get(i) );
    }
    html += typeof this.postHTML == "function"
        ? this.postHTML(response) : this.postHTML;
    return html;
};

/**
 * Display a list of response items in a given HTML element.
 *
 * @param element HTML DOM element or ID
 * @param response {@link SeeAlsoResponse} or response string/object
 */
SeeAlsoView.prototype.display = function(element, response) {
    var html = this.makeHTML(response);
    if (typeof element == "string") {
        element = document.getElementById(element);
    }
    if (!element) return;

    // TODO: IE completely kills leading whitespace when innerHTML is used.
    // if ( /^\s/.test( html ) ) createTextNode( html.match(/^\s*/)[0] ) ...
    element.innerHTML = html;

    // Display all parent containers (may be hidden by default)
    // Note that containers will be shown as block elements only!
    if ((response && response.size()) || html) {
        while ((element = element.parentNode)) {
            if (this.getClasses(element)["seealso-container"])
                element.style.display = '';
        }
    }
};


/**
 * Utility method to escape selected characters (&, ", <, and >) in a string.
 * @param  {string} a string
 * @return {string} the string with HTML entities for &, ", <, >.
 */
SeeAlsoView.prototype.escapeHTML = function(s) {
    return s.replace(/&/g,"&amp;").replace(/"/g,"&quot;")
            .replace(/</g,"&lt;").replace(/>/g,"&gt;");
}

/**
 * Ultility method to get the CSS classes of a HTML DOM element as hash.
 * @param elem
 * @return {array}
 */
SeeAlsoView.prototype.getClasses = function(elem) {
    var classes = {};
    if (elem && elem.className) {
        var c = elem.className.split(/\s+/);
        for ( var i = 0, length = c.length; i < length; i++ ) {
            if (c[i].length > 0) {
                classes[c[i]] = c[i];
            }
        }
    }
    return classes;
}


/**
 * @class Source of SeeAlso responses.
 * Create a Source that delivers {@link SeeAlsoResponse} objects.
 */
function SeeAlsoSource(query) {
    if (typeof query == "function") {
        this._queryMethod = function(id, callback) {
            callback( query(id) );
        }
    }
    /**
     * Either return a SeeAlsoResponse or call the callback method
     */
    this.query = function( identifier, callback ) {
        identifier = this.normalizeIdentifier(identifier);
        if (this._queryMethod) {
            if (typeof callback == "function") {
                if (identifier != "") {
                    this._queryMethod(identifier, callback);
                } else {
                    callback( new SeeAlsoResponse([identifier]) );
                }
                return undefined;
            } else {
                if (identifier != "") return this._queryMethod(identifier);
            }
        }
        return new SeeAlsoResponse([identifier]);
    }

    /**
     * Perform a query and display the response at a given DOM 
     * element with a given view (default is {@link SeeAlsoCSV}).
     */
    this.queryDisplay = function(identifier, element, view) {
        if (!view) view = new SeeAlsoCSV();
        this.query( identifier,
            function(data) {
                view.display(element, data);
            }
        );
    }

    /**
     * Normalized and/or checks an identifier. If this returns an
     * empty string, the SeeAlso response will also be empty.
     */
    this.normalizeIdentifier = function(identifier) {
        return identifier;
    }
}


/**
 * Create a Caching Proxy for another {@link SeeAlsoSource}.
 * If an identifier has been queried before, a copy of the
 * SeeAlsoResponse from the cache is returned instead of 
 * directly querying the SeeAlsoSource again.
 *
 * @class Caching Proxy for a SeeAlsoSource.
 * @extends SeeAlsoSource
 * @param {SeeAlsoSource}
 */
function SeeAlsoCache(source) {
    this.source = source;
    this.cache = {};

    this._queryMethod = function( identifier, callback ) {
        if (this.cache[identifier]) {
            callback(this.cache[identifier]);
        } else {
            var cache = this.cache;
            this.source.query( identifier, function(data) {
                cache[identifier] = data;
                callback(data);
            });
        }
    };
}

SeeAlsoCache.prototype = new SeeAlsoSource;


/**
 * Create a proxy that wraps another {@link SeeAlsoSource}.
 * You can use the proxy to filter a responses item per item.
 *
 * @class Proxy for a SeeAlsoSource.
 * @extends SeeAlsoSource
 *
 * @see {@link SeeAlsoDisplay} and its parameter p.itemFilter
 *
 * @param {SeeAlsoSource} source a SeeAlsoSource
 * @param {Function} filter a function that gets an item (with
 *                   fields 'label', 'url', and 'uri') and
 *                   returns a (modified) item - or nothing to
 *                   remove the item.
 */
function SeeAlsoItemFilter(source, filter) {
    this.source = source;
    this._queryMethod = function( identifier, callback ) {
        this.source.query( identifier, function(data) {
                var r = new SeeAlsoResponse();
                r.identifier = data.identifier;
                for(var i=0; i<data.size(); i++) {
                    var item = filter(data.get(i));
                    if (item) r.add(item.label, item.description, item.uri);
                }
                callback(r);
            }
        );
    }
}

SeeAlsoItemFilter.prototype = new SeeAlsoSource;


/**
* @class A {@link SeeAlsoSource} that gets its responses from a server via HTTP.
* @extends SeeAlsoSource
* @param {String} url the base URL
*/
function SeeAlsoService( url ) {
    /**
     * The base url of this service
     */
    this.url = url;

    /**
     * Get the query URL for a given identifier (including callback parameter)
     *
     * @todo check whether URL escaping is needed / check identifier
     */
    this.queryURL = function(identifier, callback) {
        var url = this.url + (this.url.indexOf('?') == -1 ? '?' : '&');
        if (url.indexOf("format=") == -1) url += "format=seealso&";
        url += "id=" + identifier;
        if (callback) url += "&callback=" + callback;
        return url;
    }

    /**
     * Creates and returns a {@link SeeAlsoResponse} object.
     * You can override this method with a wrapper.
     */
    this.createResponse = function(data, identifier) {
        return new SeeAlsoResponse(data);
    }

    /**
     * Perform a query and run a callback method with the JSON response.
     * You can define the type of JSON request by setting {@link #jsonRequest}.
     * The {@link #createResponse} method of this SeeAlsoService is called to
     * create the {@link SeeAlsoResponse}.
     *
     * @param {String}   identifier
     * @param {Function} callback
     */
    this._queryMethod = function(identifier, callback) {
        var me = this;
        // TODO: check identifier before submit
        this.jsonRequest(
            this.queryURL(identifier,'?'),
            function (data) {
                callback (
                    me.createResponse(data, identifier)
                );
            }
        );
    }
}

SeeAlsoService.prototype = new SeeAlsoSource();


/**
 * Performs a HTTP query to get a SeeAlso Response in JSON format.
 * The question mark in <tt>callback=?</tt> is replaced by a
 * callback function if existing.
 *
 * <p>To get around the cross site scripting limitations of JavaScript 
 * a <tt>&lt;script&gt;</tt> tag is dynamically added to the page. 
 * Please note that this is a serious security problem! The SeeAlso 
 * service that you call may access the content of your page and cookies.
 * Don't call any services that you don't trust. A solution is to
 * either use a proxy at the domain of your page or use an implementation 
 * of <a href="http://www.json.org/JSONRequest.html">JSONRequest</a>
 * like <a href="http://www.json.com/2007/09/10/crosssafe/">CrossSafe</a>.</p>
 *
 * @param {String} url
 * @param {Function} callback
 */
SeeAlsoService.prototype.jsonRequest = function(url, callback) {
    jsc = typeof jsc == "undefined" ? (new Date).getTime() : jsc+1;
    var jsonp = "jsonp" + jsc; // this should also prevent caching

    var jsre = /=\?(&|$)/g; // TODO: what if no callback was specified?!
    var head = document.getElementsByTagName("head")[0];
    var script = document.createElement("script");
    script.src = url.replace(jsre, "=" + jsonp + "&");
    script.type = "text/javascript";
    script.charset = "UTF-8";

    window[ jsonp ] = function(data){
        callback( data );
        window[ jsonp ] = undefined; // GC
        try{ delete window[ jsonp ]; } catch(e){}
        if ( head ) script.parentNode.removeChild( script ); // yet another IE bug
    };

    head.appendChild(script);
};

// if jQuery is included <em>before</em> seealso, it is used to perform
// JSON requests. Support of <tt>JSONRequest.get</tt> will be added.
/*
SeeAlsoService.prototype.jsonRequest = function(url, callback) {
    JSONRequest.get(url, function (id,object,error) { 
        if (object) { callback( new SeeAlsoResponse(object) ); }
    }
};
*/
if (typeof jQuery != "undefined" && typeof jQuery.getJSON == "function") {
    SeeAlsoService.prototype.jsonRequest = function(url, callback) {
        $.getJSON( url, 
            function(data) { callback( new SeeAlsoResponse(data) ); }
        );
    }
};



/**
 * @class Display a {@link SeeAlsoResult} as unordered list (&lt;ul&gt;).
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 */
function SeeAlsoUL(p) {
    p = (typeof p == "object") ? p : {};
    p.preHTML = (typeof p.preHTML != "undefined") ?  p.preHTML + "<ul>" : "<ul>";
    p.postHTML = (typeof p.postHTML != "undefined") ?  p.postHTML + "</ul>" : "</ul>";
    p.delimHTML = "";
    this.innerItemHTML = typeof p.itemHTML == "function" ? p.itemHTML : this.defaultItemHTML;

    p.itemHTML = function(item) { 
        return "<li>" +  this.innerItemHTML(item) + "</li>";
    }
    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoUL.prototype = new SeeAlsoView;


/**
 * @class Display a {@link SeeAlsoResult} as ordered list (&lt;ol&gt;).
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 */
function SeeAlsoOL(p) {
    p = (typeof p == "object") ? p : {};
    p.preHTML = (typeof p.preHTML != "undefined") ?  p.preHTML + "<ol>" : "<ol>";
    p.postHTML = (typeof p.postHTML != "undefined") ?  p.postHTML + "</ol>" : "</ol>";
    p.delimHTML = "";
    this.innerItemHTML = typeof p.itemHTML == "function" ? p.itemHTML : this.defaultItemHTML;

    p.itemHTML = function(item) { 
        return "<li>" +  this.innerItemHTML(item) + "</li>";
    }
    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoOL.prototype = new SeeAlsoView;


/**
 * @class Display a {@link SeeAlsoResult} as comma seperated list.
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 */
function SeeAlsoCSV(p) {
    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoCSV.prototype = new SeeAlsoView;


/**
 * @class Display a {@link SeeAlsoResult} as grouped list, sorded by description.
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 * @param [p.innerView]  instance of a {@link SeeAlsoView} to display parts of a list (default: {@link SeeAlsoUL})
 */
function SeeAlsoGroupedList(p) {
    p = typeof p == "object" ? p : {};
    this.innerView = p.innerView ? p.innerView : new SeeAlsoUL();
    p.innerView = null;

    // TODO: set this parameters via p
    this.preGrouptitle = "<b>";
    this.postGrouptitle = ":</b> ";
    this.emptyGrouptitle = "";

    this.makeHTML = function(response) {
        if (!(response instanceof SeeAlsoResponse)) {
            response = new SeeAlsoResponse(response)
        }
        // TODO: support emptyHTML, maxItems etc.
        var html = "";
        var grouped = {};
        for(var i=0; i<response.size(); i++) {
            var item = response.get(i);
            if (!grouped[item.description]) {
                grouped[item.description] = new SeeAlsoResponse(response.getQuery());
            }
            grouped[item.description].add( item.label, item.description, item.uri );
        }
        for (var descr in grouped) {
            var r = grouped[descr];
            var item = r.get(0);
            if (item.description != "") {
                html += this.preGrouptitle + this.escapeHTML(item.description) + this.postGrouptitle;
            } else {
                html += this.emptyGrouptitle;
            }
            html += this.innerView.makeHTML(r);
        }
        return html;
    }

    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoGroupedList.prototype = new SeeAlsoView;


/**
 * URL is in the item.uri, dimension is in the description.
 *
 * @class Display an image.
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 */
function SeeAlsoIMG(p) {
    p = typeof p == "object" ? p : {};

    this.width = 1 * p.width;
    this.height = 1 * p.height;

    p.itemHTML = function(item) {
        var html = "";
        var attr = "";
        if (item.uri) {
            var dim = item.description.match(/^(\d+)x(\d+)$/);
            if (dim) {
                var w = dim[1], h = dim[2];
                if (!w || !h) {
                    attr = "";
                } else {
                    var width = w, height = h;
                    if (this.width && !this.height) {
                        width = this.width;
                        height = h * (this.width / w);
                    } else if (this.height) {
                        height = this.height;
                        width = w * (this.height / h);
                    }
                    attr = 'width="' + width + '" height="' + height + '"';
                }
            }
            html = '<img src="' + this.escapeHTML(item.uri)
                 + '" alt="' + this.escapeHTML(item.label) + '" ' + attr + '></img>';
        }
        return html;
    }

    SeeAlsoView.prototype.constructor.call(this, p);
}
SeeAlsoIMG.prototype = new SeeAlsoView;


/**
 * @class Experimental SeeAlsoView to display a tag cloud.
 * @extends SeeAlsoView
 * @param [p] additional display parameters (see {@link SeeAlsoView} for details)
 */
function SeeAlsoCloud(p) {
    p = typeof p == "object" ? p : {};

    if (typeof p.delimHTML == "undefined") p.delimHTML = " ";
    p.maxItems = -1; // inf

    // this.sort = true;

    this.display = function(element, response) {
        var min=0, max=0, i, item;
        for(i=0; i<response.size(); i++) {
            var v = 1 * response.get(i).description;
            if (v < min) min = v;
            if (v > max) max = v;
        }
        // sort (TODO: make this a method of SeeAlsoResponse)
        var sorted = [];
        for(i=0; i<response.size(); i++) {
            item = response.get(i);
            sorted.push( [ item.label, item.description, item.uri ] );
        }
        sorted.sort( function(a,b) {
                a = a[0].toLowerCase(); b = b[0].toLowerCase();
                if (a > b ) return 1; else if (a < b) return -1; else return 0;
        });

        var r = new SeeAlsoResponse([response.identifier]);
        for(i=0; i<sorted.length; i++) {
            item = sorted[i];
            r.add( item[0], item[1], item[2] );
        }

        this.itemAttr = function (item) {
            var v = 1 * item.description;
            // calculate font size. TODO: use a given number of different sizes instead
            var size = Math.round((150.0*(1.0+(1.5*v-max/2)/max)));
            return { 'style': "font-size: "+size+"%" };
        };
        SeeAlsoView.prototype.display.call(this, element, r);
    }

    SeeAlsoView.prototype.constructor.call(this, p);
}
SeeAlsoCloud.prototype = new SeeAlsoView();


/**
 * @class Combines a number of {@link SeeAlsoService}s and
 * {@link SeeAlsoView}s together with some helper methods to
 * query the services and display the results.
 *
 * @param [p] hash with array of services and/or array of views
 */
function SeeAlsoCollection(p) {
    p = (typeof p == "object") ? p : {};
    /**
     * Directory of named services ({@link SeeAlsoService})
     */
    this.services = p.services ? p.services : {};
    /**
     * Directory of named views ({@link SeeAlsoView})
     */
    this.views = p.views ? p.views : {
        'seealso-csv' : new SeeAlsoCSV(),
        'seealso-ul' : new SeeAlsoUL(),
        'seealso-ol' : new SeeAlsoOL(),
        'seealso-img' : new SeeAlsoIMG(),
        'seealso-cloud' : new SeeAlsoCloud(),
        'seealso-grouped' : new SeeAlsoGroupedList()
    };
    /**
     * Default view ({@link SeeAlsoView}) that is used if no specific view is given.
     */
    this.defaultView = new SeeAlsoCSV();
}

/**
 * Replace all existing tags by querying all services.
 * Please don't use empty HTML tags (<tag/>) because IE
 * is too stupid to properly support them.
 * @param root element to start from (default is the document root)
 */
SeeAlsoCollection.prototype.replaceTags = function (root) {
    if (root) {
        if (typeof root == "string") {
            root = document.getElementById(root) || document;
        }
    } else {
        root = document;
    }
    var all = root.getElementsByTagName('*');
    var i, tags=[], length=all.length;

    // cycle through all tags in the document that use this service
    for (i = 0; i < length; i++) {
        var elem = all[i];

        var tag = this.parseTag(elem, this);
        if (!tag) continue;

        if (tag.tooltip) {
            var collection = this;
            elem.onfocus = elem.onmouseover = function() {
                var node = this;

                // check whether tooltip content is already loaded
                for(var c=node.firstChild; c!=null; c=c.nextSibling) {
                    if (c.tagName == "SPAN") return;
                }

                tag = collection.parseTag(node, collection);
                if (!tag || !tag.tooltip) return;

                // create a span element for tooltip content
                var span = document.createElement("span");
                if (tag.tooltip == "right") {
                    node.appendChild(span);
                } else {
                    node.insertBefore(span, node.firstChild);
                }

                tag.service.queryDisplay(tag.identifier, span, tag.view);
            }
        } else { // collect tags - they will change the DOM we are iterating!
            tag["element"] = elem;
            tags.push(tag);
        }
    }

    // query the services
    for(i in tags) {
        var tag = tags[i];
        tag.service.queryDisplay( tag.identifier, tag.element, tag.view );
    }
};

/**
 * Parse the attributes of an HTML tag to find out service, view, and identifier.
 * Returns a hash with 'service', 'view', 'identifier', and 'tooltip' or null.
 * The second parameter must be a SeeAlsoCollection
 */
SeeAlsoCollection.prototype.parseTag = function (elem, collection) {
    if (!collection) collection = this;

    // parse classes and title attribute (as identifier)
    var identifier = "", classes = SeeAlsoView.prototype.getClasses(elem);
    for (var c in classes) {
        identifier = elem.getAttribute("title") || "";
        identifier = identifier.replace(/^\s+|\s+$/g,"");
        break;
    }
    if (identifier == "") return;

    // parse service and view (and tooltip)
    var service, view, tooltip=false;
    for (var c in classes) {
        if (!service && collection.services[c]) {
            service = collection.services[c];
        } else if (!view && collection.views[c]) {
            view = collection.views[c];
        } else if(c == "tooltip") {
            tooltip = "over";
        } else if(c == "tooltip-right") {
            tooltip = "right";
        }
    }
    if (!view) view = collection.defaultView;
    if (!service || !view) return;

    return {
        "identifier": identifier,
        "service": service,
        "view": view,
        "tooltip": tooltip
    };
};

/**
 * Call {@link #replaceTags} when the HTML page has been loaded.
 * This is compatible with <tt>&lt;body onload=""&gt;</tt>
 * @param id of the root element to search for tags (default is document root)
 */
SeeAlsoCollection.prototype.replaceTagsOnLoad = function(root) {
    var me = this;
    function callReplaceTags() { 
       me.replaceTags(root);
    }
    if(typeof window.addEventListener != 'undefined') {
        window.addEventListener('load', callReplaceTags, false);
    } else if(typeof document.addEventListener != 'undefined') {
        document.addEventListener('load', callReplaceTags, false);
    } else if(typeof window.attachEvent != 'undefined') {
        window.attachEvent('onload', callReplaceTags);
    }
};

/**
 * SeeAlso needs JSON.stringify and JSON.parse
 */
if (!this.JSON) { var JSON = function () {
    function f(n) { return n < 10 ? '0' + n : n; }
    var m = { '\b': '\\b', '\t': '\\t', '\n': '\\n',
              '\f': '\\f', '\r': '\\r', '"' : '\\"', '\\': '\\\\' };
    Date.prototype.toJSON = function () {
        return this.getUTCFullYear()   + '-' +
                f(this.getUTCMonth() + 1) + '-' +
                f(this.getUTCDate())      + 'T' +
                f(this.getUTCHours())     + ':' +
                f(this.getUTCMinutes())   + ':' +
                f(this.getUTCSeconds())   + 'Z';
    };
    function stringify(value) {
        var a,i,k,l,r = /["\\\x00-\x1f\x7f-\x9f]/g,v;
        switch (typeof value) {
        case 'string':
            return '"' + (r.test(value) ?
                value.replace(r, function (a) {
                    var c = m[a];
                    if (c) return c;
                    c = a.charCodeAt();
                    return '\\u00' + Math.floor(c / 16).toString(16) +
                                            (c % 16).toString(16);
                }) : value) + '"';
        case 'number':
            return isFinite(value) ? String(value) : 'null';
        case 'boolean':
        case 'null':
            return String(value);
        case 'object':
            if (!value) return 'null';
            if (typeof value.toJSON === 'function') {
                return stringify(value.toJSON());
            }
            a = [];
            if (typeof value.length === 'number' &&
                    !(value.propertyIsEnumerable('length'))) {
                l = value.length;
                for (i = 0; i < l; i += 1) {
                    a.push(stringify(value[i]) || 'null');
                }
                return '[' + a.join(',') + ']';
            }
            for (k in value) {
                if (typeof k === 'string') {
                    v = stringify(value[k], whitelist);
                    if (v) {
                        a.push(stringify(k) + ':' + v);
                    }
                }
            }
            return '{' + a.join(',') + '}';
        }
        return '';
    }
    return {
        stringify: stringify,
        parse: function (text) {
            if (/^[\],:{}\s]*$/.test(text.replace(/\\./g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                return eval('(' + text + ')');
            }
        }
    };
}(); } // JSON
