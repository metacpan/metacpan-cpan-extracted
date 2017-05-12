use Plack::App::JSP;
# Plack::App::JSP->new( js => q{
    # [ 200, [ 'Content-type', 'text/html' ], [ 'Hello, World!' ] ] 
# });

Plack::App::JSP->new( js => q{
    function respond(body) {
        return [ 200, [ 'Content-type', 'text/html' ], [ body ] ]
    }
    
    respond("Five factorial is " + 
        (function(x) {
          if ( x<2 ) return x;
          return x * arguments.callee(x - 1);
        })(5)
    );
});