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
