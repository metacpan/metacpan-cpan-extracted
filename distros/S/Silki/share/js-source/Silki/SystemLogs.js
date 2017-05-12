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
