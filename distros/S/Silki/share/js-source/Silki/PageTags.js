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