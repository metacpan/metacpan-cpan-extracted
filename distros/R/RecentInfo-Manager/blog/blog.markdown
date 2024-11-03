:-( I'm looking to finally add "recently used files" support to my command line programs, to make attaching files to mails more convenient, but the XDG spec doesn't have a valid DTD

[XDG Desktop Bookmark Spec](https://www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/) - also used for the recently used files, but the DTD is not valid for `recently-used.xbel`

[XBEL homepage](https://pyxml.sourceforge.net/topics/xbel/) - some kind of XBEL, but not applicable for ingesting existing files

> \[Corion]: (and of course, manually editing the file results in either no change, or an empty recently-used list, without error messages to validate. And all things I find online are parsers, not writers)
> \[Corion]: I guess I have to dive into the ad-hoc generators and parsers, and generate a DTD from that :-(

[Some shell script that does the reverse](https://github.com/laodzu/gnome-recent)

Via Stackoverflow [some Python library](https://github.com/xenomachina/recently_used)
that points to [`Gtk.RecentManager`](https://docs.gtk.org/gtk3/class.RecentManager.html).
that points to [`gtkrecentmanager.c`](https://gitlab.gnome.org/GNOME/gtk/-/blob/main/gtk/gtkrecentmanager.c?ref_type=heads)
that points to [`gbookmarkfile.c`](https://gitlab.gnome.org/GNOME/glib/-/blob/main/glib/gbookmarkfile.c?ref_type=heads)

This feels like a good small project to look into `perlclass`.


The code in the original Aramaic does XML by manipulating strings. Yay.

# Approach

* Read/parse the file into an object tree
* Construct XML from the object tree
* Check that the two are (byte-for-byte) identical, maybe ignoring whitespace
