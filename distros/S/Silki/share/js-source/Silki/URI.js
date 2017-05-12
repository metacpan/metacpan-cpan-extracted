Silki.URI = {};

Silki.URI.dynamicURI = function (path) {
    var uri = Silki.URI._dynamicURIRoot == "/" ? "" : Silki.URI._dynamicURIRoot;

    if ( uri.length ) {
        uri = uri + "/" + path;
    }
    else {
        uri = path;
    }

    return uri;
};

Silki.URI.staticURI = function (path) {
    var uri = Silki.URI._staticURIRoot == "/" ? "" : Silki.URI._staticURIRoot;

    if ( uri.length ) {
        uri = uri + "/" + path;
    }
    else {
        uri = path;
    }

    return uri;
};
