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
