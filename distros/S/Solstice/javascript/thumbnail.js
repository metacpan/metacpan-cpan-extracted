Solstice.Thumbnail = function() {};

Solstice.Thumbnail.URL = Solstice.getDocumentBase() + 'file_thumbnail.cgi?s=32&tkt=';
Solstice.Thumbnail.Queue = new Array();

/*
 * This function searches the a portion of the document for elements
 * which will be converted to thumbnails, and adds each matching 
 * element's id to the Queue array. If any are found,
 * the conversion process is started by calling Solstice.Thumbnail.fetch()
 */
Solstice.Thumbnail.loadQueue = function(id) {
    var divs = document.getElementById(id).getElementsByTagName('div');
    for ( var i = 0, div; div = divs[i]; i++ ) {    
        if (div.id && div.id.match(/^thumbnail_(.*)$/)) {
            Solstice.Thumbnail.Queue.push(div.id);
        }
    }
    if (Solstice.Thumbnail.Queue.length) Solstice.Thumbnail.fetch();
}

Solstice.Thumbnail.fetch = function() {
    var id = Solstice.Thumbnail.Queue.shift();

    if (id) {
        var images = document.getElementById(id).getElementsByTagName('img');
        if (images[0]) {
            var img = images[0];
            img.original_src = img.src;
            img.onload  = Solstice.Thumbnail.fetch;
            img.onerror = Solstice.Thumbnail.error;
            img.src     = Solstice.Thumbnail.URL + id.replace(/^thumbnail_/, '');
        } else {
            Solstice.Thumbnail.fetch();
        }
    }
}

/*
 * Revert the image src to the original src, and move on...
 */
Solstice.Thumbnail.error = function() {
    this.src = this.original_src;
    this.onerror = null;
    Solstice.Thumbnail.fetch();
}
