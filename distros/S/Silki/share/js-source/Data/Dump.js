if (typeof(Data) == 'undefined') Data = {};

Data.Dump = function () {
    return this;
}

Data.Dump.dump = function (obj) {
    return (new Data.Dump).dump(obj);
}

Data.Dump.EXPORT = [ 'Dump' ];

Data.Dump.VERSION = '0.02';

Data.Dump.Dump = function () {
    return Data.Dump.prototype.Dump.apply(
        new Data.Dump, arguments
    );
}

Data.Dump.prototype = {};

Data.Dump.ESC = {
    "\t": "\\t",
    "\n": "\\n",
    "\f": "\\f"
};

Data.Dump.nodeTypes = {
    1: "ELEMENT_NODE",
    2: "ATTRIBUTE_NODE",
    3: "TEXT_NODE",
    4: "CDATA_SECTION_NODE",
    5: "ENTITY_REFERENCE_NODE",
    6: "ENTITY_NODE",
    7: "PROCESSING_INSTRUCTION_NODE",
    8: "COMMENT_NODE",
    9: "DOCUMENT_NODE",
    10: "DOCUMENT_TYPE_NODE",
    11: "DOCUMENT_FRAGMENT_NODE",
    12: "NOTATION_NODE"
};

Data.Dump.prototype.Dump = function () {
    if (arguments.length > 1)
        return this._dump(arguments);
    else if (arguments.length == 1)
        return this._dump(arguments[0]);
    else
        return "()";
}

Data.Dump.prototype._dump = function (obj) {
    var out;
    switch (this._typeof(obj)) {
        case 'object':
            var pairs = new Array;

            for (var prop in obj) {
                if (obj.hasOwnProperty(prop)) { //hide inherited properties
		    pairs.push(prop + ': ' + this._dump(obj[prop]));
                }
            }

            out = '{' + this._format_list(pairs) + '}';
            break;

        case 'string':
            for (var prop in Data.Dump.ESC) {
                if (Data.Dump.ESC.hasOwnProperty(prop)) {
                    obj = obj.replace(prop, Data.Dump.ESC[prop]);
                }
            }

	    // Escape UTF-8 Strings
            if (obj.match(/^[\x00-\x7f]*$/)) {
                out = '"' + obj + '"';
            }
            else {
                out = "unescape('"+escape(obj)+"')";
            }
            break;

        case 'array':
            var elems = new Array;

            for (var i=0; i<obj.length; i++) {
                elems.push( this._dump(obj[i]) );
            }

            out = '[' + this._format_list(elems) + ']';
            break;

        case 'date':
	    // firefox returns GMT strings from toUTCString()...
	    var utc_string = obj.toUTCString().replace(/GMT/,'UTC');
            out = 'new Date("' + utc_string + '")';
            break;

	case 'element':
	    // DOM element
	    out = this._dump_dom(obj);
	    break;

        default:
            out = obj;
    }

    out = String(out).replace(/\n/g, '\n    ');
    out = out.replace(/\n    (.*)$/,"\n$1");

    return out;
}

Data.Dump.prototype._format_list = function (list) {
    if (!list.length) return '';
    var nl = list.toString().length > 60 ? '\n' : ' ';
    return nl + list.join(',' + nl) + nl;
}

Data.Dump.prototype._typeof = function (obj) {
    if (Array.prototype.isPrototypeOf(obj)) return 'array';
    if (Date.prototype.isPrototypeOf(obj)) return 'date';
    if (typeof(obj.nodeType) != 'undefined') return 'element';
    return typeof(obj);
}

Data.Dump.prototype._dump_dom = function (obj) {
    return '"' + Data.Dump.nodeTypes[obj.nodeType] + '"';
}

