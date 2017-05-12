JSAN.use('DOM.Events');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.QuickSearch = function () {
    var input = $("quick-search-input");

    if ( ! input ) {
        return;
    }

    var match = input.className.match( /js-default-text-(\w+)/ );
    var default_val = match[1];

    DOM.Events.addListener( input,
                            "focus",
                            function () {
                                if ( input.value == default_val ) {
                                    input.value = "";
                                }
                            }
                          );
};