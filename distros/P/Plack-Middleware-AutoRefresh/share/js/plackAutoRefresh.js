// Park everything in a function to avoid poluting the global namespace
(function(host) {

// Mock the console if it isn't defined
if (typeof(console) == 'undefined') {
    console = { log: function() {} }
}

// Simple bind utility
var bind = function( object, method ){
    return function(){
        return method.apply(object,arguments);
    };
}

// Handle ajax interaction
// Some code taken from prototype.js (http://www.prototypejs.org/)
var Ajax = {
    Request: function(url, opts) {
        this.getTransport = function(){
            try{ return new XMLHttpRequest()}                   catch(e){};
            try{ return new ActiveXObject('Msxml2.XMLHTTP')}    catch(e){};
            try{ return new ActiveXObject('Microsoft.XMLHTTP')} catch(e){};
            alert("XMLHttpRequest not supported");
        };

        this.opts = opts;
        this.transport = this.getTransport();

        this.timeout = setTimeout( bind( this, function(){
                this.transport.abort();
            } ), this.opts.wait );

        this.transport.open( 'get', url, true );
        this.transport.onreadystatechange =
            bind( this, function(){
                if( this.transport.readyState != 4 ) { return }
                clearTimeout( this.timeout );
                if( this.transport.status != 200 ){
                    this.opts.onFailure && this.opts.onFailure( this.transport );
                } else {
                    this.opts.onSuccess && this.opts.onSuccess( this.transport );
                }
            } );
        this.transport.send(null);
    }
};

// Primary routine to check for changes to source files and reload
// the page if there is a change
var check =  function(wait){
    var start = +"{{now}}";
    new Ajax.Request( host, {
        wait: wait,
        onSuccess: function(transport) {

            // Server will return json as the body 
            // Changed is the only currently supported entity
            try { 
                var json = JSON && JSON.parse(transport.responseText)
                         || eval('('+transport.responseText+')');

                if( json.changed > start ){
                    location.reload(true);   // never returns
                }
            } catch(e) { }

            // If we got here, either their was an exception in the try
            // or the json.changed <= start
            // Either way, queue another check
            setTimeout( function(){ check(wait) }, 1500 );

        },
        onFailure: function(transport) {
            setTimeout( function(){ check(wait) }, 1500 );
        }
      });

};

// Prevent multiple connections
window['-plackAutoRefresh-'] ||
    (window['-plackAutoRefresh-'] = 1) && check(+"{{wait}}");

})("{{url}}/{{uid}}/{{now}}")

// vim: ts=4 sw=4 expandtab:
