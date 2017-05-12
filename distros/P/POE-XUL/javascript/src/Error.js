// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------

// See also 
// /usr/local/firefox-2.0.0.3/chrome/classic/skin/classic/global/netError.css
var $error;

function POEXUL_Error () {

    if( POEXUL_Error.singleton ) 
        return POEXUL_Error.singleton;

    this.msg = '';

    $error = this;
}

var _ = POEXUL_Error.prototype;


// ------------------------------------------------------------------
_.element = function (force) {
    var el = $( 'POEXUL-Error' );
    if( force ) 
        return el;
    if( el && el.setTitle )
        return el;
    return;
}

// ------------------------------------------------------------------
_.title = function ( msg ) {
    var el = this.element();
    if( el ) {
        el.setTitle( msg );
        this.show();
    }
    else {
        this.msg = msg;
        $application.status( msg );
    }
}

// ------------------------------------------------------------------
_.message = function ( msg ) {
    var el = this.element();
    if( el ) {
        el.setMessage( msg );
        this.show();
    }
    else {
        this.title( msg );
    }
}

// ------------------------------------------------------------------
_.show = function () {
    var el = this.element(1);
    if( el ) {
        Element.show( el )
    }
    else {
        this.title( this.msg );
    }
}

// ------------------------------------------------------------------
_.hide = function () {
    var el = this.element(1);
    if( el ) {
        Element.hide( el )
    }
    else {
        this.title( '' );
    }
}

