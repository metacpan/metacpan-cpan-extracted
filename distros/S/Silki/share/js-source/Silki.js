JSAN.use('DOM.Ready');
JSAN.use('Silki.FileView');

/* These three need to be loaded in this order so Silki.PageEdit can define
   itself first */
JSAN.use('Silki.PageEdit');
JSAN.use('Silki.PageEdit.Preview');
JSAN.use('Silki.PageEdit.Toolbar');

JSAN.use('Silki.PageTags');
JSAN.use('Silki.ProcessStatus');
JSAN.use('Silki.QuickSearch');
JSAN.use('Silki.SystemLogs');
JSAN.use('Silki.URI');
JSAN.use('Silki.User');

if ( typeof Silki == "undefined" ) {
    Silki = {};
}

Silki.instrumentAll = function () {
    new Silki.FileView ();
    new Silki.PageEdit ();
    new Silki.PageTags ();
    new Silki.ProcessStatus ();
    new Silki.QuickSearch ();
    new Silki.SystemLogs ();
};

DOM.Ready.onDOMDone( Silki.instrumentAll );
