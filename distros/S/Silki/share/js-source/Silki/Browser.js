if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.Browser = function () {
    if ( Silki.Browser._Singleton ) {
        return Silki.Browser._Singleton;
    }

    var ua = navigator.userAgent;

    this.isIE     = !! window.attachEvent && ! window.opera;
    this.isOpera  = !! window.opera;
    this.isWebKit = !! ( ua.indexOf('AppleWebKit/') > -1 );
    this.isGecko  = !! ( ua.indexOf('Gecko') > -1 && ua.indexOf('KHTML') == -1 );
    this.isKHTML  = !! ( ua.indexOf('KHTML') > -1 );

    this.requiresPngFilter = this._requiresPngFilter();

    Silki.Browser._Singleton = this;
};

Silki.Browser._Singleton = null;

Silki.Browser.prototype._requiresPngFilter = function () {
    if ( ! this.isIE ) {
        return false;
    }

    var version = navigator.appVersion.split("MSIE");
    var version_num = parseFloat( version[1] );

    if ( version_num >= 5.5 && version_num < 7 ) {
        return true;
    }

    return false;
};
