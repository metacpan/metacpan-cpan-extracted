var fake = function() {
    var test_parser;
    return {
        tablesorter : {
            addParser : function(parser) {
                test_parser = parser;
            },
            getParser : function() {
                return test_parser;
            }
        }
    }
};
var $ = fake();
