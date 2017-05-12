// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------

var $blocker;

function POEXUL_Blocker () {

    if( POEXUL_Blocker.singleton ) 
        return POEXUL_Blocker.singleton;

    this.msg = '';

    $blocker = this;
}

var _ = POEXUL_Blocker.prototype;


// ------------------------------------------------------------------
_.element = function () {
    var el = $( 'POEXUL-Blocker' );
    if( el && el.block )
        return el;
//    else 
//        fb_log( "Can't find POEXUL-Blocker" );
    return;
}

// ------------------------------------------------------------------
_.block = function ( ) {
    var el = this.element();
    if( el ) {
        el.block();
    }
}

// ------------------------------------------------------------------
_.unblock = function ( ) {
    var el = this.element();
    if( el ) {
        el.unblock();
    }
}

