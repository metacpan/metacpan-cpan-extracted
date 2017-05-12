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
