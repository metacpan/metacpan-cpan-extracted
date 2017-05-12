JSAN.use('DOM.Utils');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.PageEdit = function () {
    this.form = $("form-and-preview");

    if ( ! this.form ) {
        return;
    }

    this.toolbar = new Silki.PageEdit.Preview ();
    this.toolbar = new Silki.PageEdit.Toolbar ();
};
