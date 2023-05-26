perl API for mit.dk
===================

This is perl interface for mit.dk, Danish national email system 

Included a simple POP server for proxying mitdk for read-only mail access
and a simple downloader.

Installation
============

Unix/Linux
----------

* Install this module by opening command line and typing `cpan Net::MitDK` (with `sudo` if needed)

* Run `mitdk-authenticate`, open `http://localhost:9999/` in the browser, and login to NemID as described below.

* Add `mitdk-renew-lease -a` in a new cron job as yourself (see 'examples/cron'):
  - Run ``perl -le 'print q(*/10 * * * * ).($_=`which mitdk-renew-lease`,chomp,$_).q( -a)'``
  - Run `crontab -e` and add this line

Windows
-------

* You'll need `perl`. Go to [strawberry perl](http://strawberryperl.com/) and fetch one.

* Install this module by opening command line and typing `cpan Net::MitDK`

* Open command line and run

  `mitdk-install-win32`

that will fire up a browser-based install wizard. Click "Install", then login with
NemID credentials as described below.

* Set up your favourite desktop mail reader so it connects to a POP3 server
running on server localhost, port 8111. Username is 'default', no password is needed.

* Optionally, if you want to forward the mails, you can choose from numerous
programs that can forward mails from a POP3 server to another mail account
[(list of
examples)](https://blogs.technet.microsoft.com/brucecowper/2005/03/18/pop-connectors-pullers-for-exchange/).
If you use Outlook it [can do that
too](https://www.laptopmag.com/articles/how-to-set-up-auto-forwarding-in-outlook-2013).

Upgrading
---------

* Windows: run `mitdk-install-win32` and stop the servers in the browser-based setup.
Quit the setup.

* Install the dev version from github. Download/clone the repo, then run

```
  perl Makefile.PL
  make
  make install
```
(or `sudo make install`, depending); `gmake` instead of `make` for Windows.

* Windows: run `mitdk-install-win32` and start the servers in the browser-based setup.
Quit the setup.


One-time NemID registration
---------------------------

For each user, you will need to go through one-time registration through your
personal NemID signature. Run `mitdk-authenticate` to start a small webserver
on `http://localhost:9999/`, where you will need to connect to with a browser
(the Windows installer will run it for you).  There, it will will try to show a
standard NemID window. You will need to log in there, in the way you usually
do, using either one-time pads or the NemID app, and then confirm the request
from MitDK. If that works, the script will create an authorization token and
save it in your home catalog under `.mitdk/default.profile`. This token will be
used for password-less logins to the MitDK site. In case it expires, in will
need to be renewed using the same procedure.

In case you never logged in to the Digital Post, you'll get a login error.
You shall need to log in manually to the website, eventually fill your phone
number and contact email, and accept the conditions. After that, the login
should work.

**Security note**:

Make sure that the content of .mitdk directory is only readable to you.
By default, on unix installation, the directory and the files will be readable
and writable by you and readable by user `nobody`. The latter is needed because
the mitdk2pop server runs as `nobody` and needs to use the login leases.

Lease renewal
-------------

MidDK only allows sessions for 20 minutes, thereafter it may require a NemID
relogin.  Therefore there is added a daemon, `mitdk-renew-lease`. You can run
it from cron (unix), or as a standalone program as `mitdk-renew-lease -la`
(windows).  It then will renegotiate a lease every 10 minutes. If you installed
the module using `mitdk-install-win32` as described above, this program is
added to your startup folder automatically.

If for some reason the lease expires, it will warn you, once (by remembering
the last error). On unix, if you won't redirect the output to a logfile, you
will be notified through the standard cron mail. On windows there's so far no
notification mechanism developed.

In case the lease will get invalidated for one or another reason, you shall
need to relogin with `mitdk-authenticate` again. However after relogin you
won't need to do anything with the renewer, it will pick up the new lease
automatically.

Lease migration
---------------

If you cannot run a browser to authenticate with NemID on the server that will be used for mail
fetching, or you want to migrate to another server, you will need the saved lease moved.
The saved lease is located in your home directory 
( run `perl -MNet::MitDK -le "print Net::MitDK::ProfileManager->new->homepath"` if in doubt ),
move it to another server. Make sure the `mitdk-renew-lease` is not running on the old server.

Multi-user installation
-----------------------

The module and the POP3 server can operate on several users. By default, there is just one
default profile in `$HOME/.mitdk/default.profile` that is getting renewed. However you may
rename it to whatever name.profile, and have more than one. The authenticator will allow
you to switch between profiles for different NemID users, and the lease renewer will pick up
new profiles automatically. The profile name can be used as login name in the POP3 proxy, too.

Operations
==========

Download your mails as a mailbox
--------------------------------

Note: You most probably won't need it, this script is mostly for testing that the access works.

On command line, type `mitdk-dump` and wait until it downloads all into
mitdk.mbox. Use your favourite mail agent to read it.

Use mit.dk as a POP3 server
-----------------------------

You may want this setup if you don't have a dedicated server, or don't want
to spam your mail by MitDK. You can run everything on a single desktop.

1) On command line, type `mitdk2pop`

2) Connect your mail client to POP3 server at localhost, where username is
'default' and password is empty string.

If you followed windows installation steps above, this is the option that 
the installer program set up for you.

Use on mail server
------------------

This is the setup I use on my own remote server, where I connect to using
email clients to read my mail.

1) Create a startup script, f.ex. for FreeBSD see `example/mitdk2pop.freebsd`,
and for Debian/Ubuntu see `examples/mitdk2pop.debian`

2) Install *procmail* and *fetchmail*. Look into `example/procmailrc.local` and
and `examples/fetchmail` (the latter needs to have permissions 0600). 

3) Add a cron job f.ex.

`  2       2       *       *       *       /usr/local/bin/fetchmail > /dev/null 2>&1`

to fetch mails once a day. Only new mails will be fetched. This will also work for 
more than one user.

Automated forwarding
--------------------

You might want just to forward your MitDK messages to your mail address.  The
setup is basically same as in previous section, but see
`examples/procmailrc.forward.simple` instead.

The problem you might encounter is that the module generates mails as
originated from `noreply@mit.dk` and f.ex. Gmail won't accept that due to
[SPF](https://en.wikipedia.org/wiki/Sender_Policy_Framework). See if rewriting
the sender as in `examples/procmail.forward.srs` helps.

Enjoy!

Thanks to:
----------

Morten Helmstedt

