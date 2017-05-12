$Browser.include("common.js");

function login(args, options) {
    var doc = $Browser.get("http://www.facebook.com");

    var login_form = doc.form({ id: "login_form "});
    
    var doc2 = login_form.submit({
        email: args.email,
        password: args.password,
    });    
    
    Session.logged_in = 1;
}

function recent_news(args, options) {
    if (!$Session.logged_in) {
        throw "Not logged in, can't proceed";
    }
    
    var maxItems = $Browser.gimme("maxItems");
    
    var doc = $Browser.get("http://www.facebook.com/#!/home.php?sk=lf");
    var elements = $Browser.find(doc, "h6.uiStreamMessage");

    return elements.slice(0, 5).map(
        function(e) {
            return e.textValue;
        }
    );
}