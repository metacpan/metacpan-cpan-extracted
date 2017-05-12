# TODO

* bugs!
  * messy permissions, we should set some umask (we'd like
    group-writable mailstore)
    * `umask 0007;` and a `chmod -R g+s store` seem to work well
      enough for my installation
  * maybe auto-mkpath for `::MailStore::FS`?
* list footer
  * append to plain text single part
  * or add a plain text (or HTML?) part if multi-part
  * how do we deal with signed messages?
  * seems to be a hard problem:
    http://www.ietf.org/mail-archive/web/ietf-smtp/current/msg01078.html
  * there's this script
    https://stuff.mit.edu/~jik/software/mailman_mimedefang/
    https://stuff.mit.edu/~jik/software/mailman_mimedefang/mailman_mimedefang_fix_footer.pl.txt
  * I'll probably go the stupid / simple way: just append text to the
    whole body, and MIME be damned
* qmail-compatible wrapper (to map exit codes)
  - requires exceptions to be thrown by the various pieces
