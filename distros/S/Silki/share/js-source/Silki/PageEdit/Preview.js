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
