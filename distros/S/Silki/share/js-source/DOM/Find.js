if ( typeof DOM == "undefined") DOM = {};

DOM.Find = {

  VERSION: 1.00,

  EXPORT: [ 'checkAttributes','getElementsByAttributes', 'geba' ],

  checkAttributes: function(hash,el){

      // Check that passed arguments make sense

      if( el === undefined || el === null )
        throw("Second argument to checkAttributes should be a DOM node or the ID of a DOM Node");

      if( el.constructor === String )
        el = document.getElementById(el);

      if( el === null || !el.nodeType ) // Make sure el is a Node
        throw("Second argument to checkAttributes should be a DOM node or the ID of a DOM Node");

      if(! (hash instanceof Object))
        throw("First argument to checkAttributes should be an Object of attribute/test pairs. See the documentation for more information.");

      // If we're still here, check the test pairs

      for(key in hash){

        /*
          Prepare the "pointer"
        */

        // Check to make sure property chain is valled
        // Provides easy declaration of nested propteries
        // Example: {'style.position':'absolute'}

        var pointer = el      // pointer
        var last    = null;   // last pointer used to aplly() later

        var pieces  = key.split('.');                   // break up the property chain

        for(var i=0; i<pieces.length; i++){             // loop property chain
          // There can be no match
          // if the attribute does not exist
          if(!pointer[pieces[i]]) return false;         // test the pointer exists
          // Save the current pointer
          last    = pointer;                            // backup current pointer
          // Develope the pointer
          pointer = pointer[pieces[i]];                 // stack the pointer
        }

        // Check if the pointer is actually a function
        // Provides easy declaration of methods
        // Example: {'hasChildNodes':true}
        // Example: {'firstChild.hasChildNodes':true}

        // Does not work in IE
        // IE returns Object instead of Function
        if( pointer instanceof Function )
          try {
            pointer = pointer.apply(last);
          }catch(error){
            throw("First agrument to checkAttributes included a Function Refrence which caused an ERROR: " +  error);
          }

        /*
          Test "pointer" against "value"
        */

        // Perform one of 3 tests
        // Regex, Function, Scalar

        // Check against a regex
        if( hash[key] instanceof RegExp ){
          if( !hash[key].test( pointer ) )
             return false;

        // Check against a function
        }else if( hash[key] instanceof Function ){
          if( !hash[key]( pointer ) )
            return false;

        // Or check against a scalar value
        }else if( hash[key] != pointer ){
          return false;
        }

      }

      return true;
  },

  getElementsByAttributes: function( searchAttributes, startAt, resultsLimit, depthLimit ) {

     // if we haven't been deep enough yet
     if(depthLimit !== undefined && depthLimit <= 0) return [];

     // if no startAt is provided use document as default
     if(startAt === undefined){
       startAt = document;

     // if startAt is a string convert it to a domref
     }else if(typeof startAt == 'string'){
       startAt = document.getElementById(startAt);
     }

     // check the startAt element
     var results = DOM.Find.checkAttributes(searchAttributes, startAt) ? [ startAt ] : [];

     // return the results right away if they only want 1 result
     if(resultsLimit == 1 && results.length > 0) return results;

     // Scan the childNodes of startAt
     if (startAt.childNodes)
       for( var i = 0; i < startAt.childNodes.length; i++){
         // concat onto results any childNodes that match
         results = results.concat(
            DOM.Find.getElementsByAttributes( searchAttributes, startAt.childNodes[i], (resultsLimit) ? resultsLimit - results.length : undefined, (depthLimit) ? depthLimit -1 : undefined )
         )
         if (resultsLimit !== undefined && results.length >= resultsLimit) break;
       }

     return results;
  }

}

/*

=head1 AUTHOR

Daniel, Aquino <mr.danielaquino@gmail.com>.

=head1 COPYRIGHT

  Copyright (c) 2007 Daniel Aquino.
  Released under the Perl Licence:
  http://dev.perl.org/licenses/

*/
