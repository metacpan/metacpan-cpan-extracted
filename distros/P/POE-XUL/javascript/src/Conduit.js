// ------------------------------------------------------------------
// Portions of this code based on works copyright 2003-2004 Ran Eilam.
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------
function POEXUL_Conduit ( uri ) {

    this.queue = [];
    this.version = 1;
    this.SID = '';
    this.URI = uri || '/xul';
    this.requestCount = 0;
    this.ETB  = String.fromCharCode( 0x17 );
    this.FS  = String.fromCharCode( 0x1C );
    this.GS  = String.fromCharCode( 0x1D );
    this.RS  = String.fromCharCode( 0x1E );
    this.US  = String.fromCharCode( 0x1F );
    this.blockRE = RegExp( "^("+this.GS+"|"+this.US+")([^"+this.ETB+"]+)("+this.ETB+")" + this.FS + "?" );
    this.recRE = RegExp( "^([^"+this.RS+this.FS+"]+)("+this.FS+")" );
}

var _ = POEXUL_Conduit.prototype;

// ------------------------------------------------------------------
_.setSID = function ( SID ) {
    this.SID = SID;
}

// ------------------------------------------------------------------
_.getSID = function ( ) {
    return this.SID;
}

// ------------------------------------------------------------------
// Add the info we know about to the request to the request
_.setupRequest = function ( req ) {

    if( this.SID ) {
        req.SID = this.SID;
    }
    req.version = this.version;
    req.reqN = ++this.requestCount;
}

// ------------------------------------------------------------------
// Starts a new request
_.request = function ( req, callback ) {

    if( this.req ) {
        this.defer( req, callback );
        return;
    }

    this.setupRequest( req );

    if( req.event == 'Click' ) {
        if( $blocker ) 
            $blocker.block();
        else
            fb_log( "no blocker" );
    }

    window.status = '';
    this.time = Date.now();

    if( ! req.app ) {
        $application.crash( "I need an application name!" );
    }

    // Add a note to any affinity proxy or whatnot
    var headers = [ 'X-XUL-Event', req.event, 
                    'X-XUL-App', req.app ];

    var self = this;
    // window.status = this.URI;
    this.req = new Ajax.Request( this.URI, {
            requestHeaders: headers,
            parameters: req,
            onSuccess: function ( tr, json ) { self.onSuccess( tr, json, callback ) },
            onFailure: function ( tr, json ) { self.onFailure( tr, json ) },
            onException: function ( tr, e ) { self.onException( tr, e ) }
        } );
    this.req.event = req.event;
}

// ------------------------------------------------------------------
// Failed!
_.onFailure = function ( transport, json ) {

    if( $blocker )
        $blocker.unblock();
    var ct = transport.getResponseHeader( 'Content-Type' );
    if( ct.match( 'text/' ) ) {
        $application.crash( transport.responseText );
    }
    else if( json && ! transport.responseText ) {
        $application.crash( "Failed: " + json );
    }
    else {
        $application.crash( "Failed: " + transport.responseText );
    }
}

// ------------------------------------------------------------------
// Browser failure!
_.onException = function ( transport, e ) {
    if( $blocker )
        $blocker.unblock();
    // $application.crash( "Exception: " + e.toString );
    throw( e );
}

// ------------------------------------------------------------------
// Success!
_.onSuccess = function ( transport, json, callback ) {
    
    if( $blocker )
        $blocker.unblock();

    if( !transport ) 
        return $application.crash( "Why no transport" );

    if( transport.status != 200 ) {
        return $application.crash( "Transport failure status=" + 
                                        transport.statusText + 
                                        " (" + transport.status + ")" );
    }

    if( !json ) {
        // fb_time( "parseResponse" );
        json = this.parseResponse( transport );
        // fb_timeEnd( "parseResponse" );
    }

    if( json ) {
        callback( json );
        this.done();
    }
}

// ------------------------------------------------------------------
_.parseResponse = function ( transport ) {

    var ct = transport.getResponseHeader( 'Content-Type' );
    if( ct.substr(0, 16) == 'application/json' ) {
        return this.parseJSON( transport );
    }
    else if( ct == 'application/vnd.poe-xul' ) {
        return this.parsePOEXUL( transport );
    }
    else {
        $application.crash( "We require json response, not " + ct );
        return;        
    }
}

_.parseJSON = function ( transport ) {
    var text = transport.responseText;

    var size = transport.getResponseHeader( 'Content-Length' );
    if( 0 && text.length != parseInt( size ) ) {
        $application.crash( "XMLHttpRequest error: didn't receive the entire response got=" +
                            text.length.toString() + " vs expected=" +
                                size );
        return;
    }
    var json;
    try { 
        var text = transport.responseText;
        // fb_log( "text.length=" + text.length );
        // fb_log( "Content-Length=" + transport.getResponseHeader( 'Content-Length' ) );
        json = eval( "(" + text + ")" );
    }
    catch (ex) {
        $application.exception( "JSON", [ ex ] );
    }
    return json;
}

_.parsePOEXUL = function ( transport ) {
    if( transport.responseText.length == 0 )
        return [];
    var recs = transport.responseText.split( this.RS );
    var ret = [];
    var l = recs.length;
    var match;
    // fb_log( recs );
    for( var q=0; q<l ; q++ ) {
        var rec = recs[q];
        // fb_log( "1='%s'", rec );
        if( -1 == rec.indexOf( this.ETB ) ) {      
            // optimize if no hash or array is present
            ret.push( rec.split( this.FS ) );
        } 
        else {
            // record contains hash or array
            var last = [];
            ret.push( last );
            while( rec.length ) {
                if( match = rec.match( this.blockRE ) ) {
                    // fb_log( match );
                    // remove from record
                    rec = rec.substr( match[0].length );  
                    var fields = match[2].split( this.FS );
                    // fb_log( fields );
                    var first = match[1].charAt( 0 );
                    if( first == this.GS ) {         // hash
                        // convert array to hash.  There has GOT to be a 
                        // better way
                        var h = {};
                        for( var w=0 ; w< fields.length; w+=2 ) {
                            h[ fields[w] ] = fields[w+1];
                        }              
                        // fb_log( h );
                        last.push( h );
                    } else if(  first == this.US ) { // array
                        last.push( fields );
                    }
                    else {
                        fb_log( "what gives?", match );
                    }
                }
                else if( match = rec.match( this.recRE ) ){
                    // remove from rec
                    rec = rec.substr( match[0].length );  
                    last.push( match[1] );
                }
                else {
                    last.push( rec );
                    rec = '';
                }
                // fb_log( "rec='%s'", rec );
            }
        }
    }
    return ret;
}

// ------------------------------------------------------------------
// A request is finished.  
_.done = function () {
    $application.timing( 'Request', this.time, Date.now() );

    // Allow other requests through
    delete this['req'];
    this.do_next();
}

// ------------------------------------------------------------------
// Wait a bit for this request
_.defer = function ( req, callback ) {
    fb_log( 'defer ', req );
    if( ! req.version ) 
        req.version = this.version;

    if( ! this.req )
        return;

    var oldreq = this.req.options.parameters;
    fb_log( 'oldreq', this.req );
    if( oldreq && oldreq.event == 'Click' ) {
        fb_log( "Attempted " + req.event + " during a " + oldreq.event );

        if( req.event == 'Click' && req.source_id == oldreq.source_id ) {
            // This looks like a dup click.  Why do we get dup clicks?
            // This seems to happen most often in Windows.
            // Whatever, don't warn.
        }
        else {
            alert( "Unable to send '" + req.event + "' at this time.  " +
               " id=" + req.source_id + " source_id=" + oldreq.source_id
         );
        }
        return;
    }

    this.queue.push( { 'req': req, 
                       'callback': callback
                   } );
}

// ------------------------------------------------------------------
// OK, now do it
_.do_next = function () {

    while( this.queue.length ) {
        var d = this.queue.shift();
        if( d.req.version >= this.version ) {
            fb_log( "do_next ", d );
            this.request( d.req, d.callback );
            return;    
        }
        alert( "version=" + d.req.version + " vs " + this.version );
        // Node versions changed.  Try the next one.
    }
}

// ------------------------------------------------------------------
// 
_.reqURI = function ( req ) {
    var params = new Hash( req );
    this.setupRequest( req );
    return this.URI + "?" + params.toQueryString();
}
