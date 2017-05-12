# OS-CheckUpdates-AUR

ALPM (Arch Linux Package Manager) pacman include checkupdates which show you all packages that is not up2date in format:
```
name old_version -> new_version
```
This program/module try reproduce it for aur.

# EXAMPLES OF USAGE:
## Gnome-shell
Extension [Arch Linux Updates Indicator](https://extensions.gnome.org/extension/1010/archlinux-updates-indicator/)

Command for checking updates:
```
/usr/bin/sh -c "/usr/bin/checkupdates; /usr/bin/checkupdates-aur"
```
Command for upgrades:
```
gnome-terminal -e 'sh -c  "yaourt -Syu --aur; echo; echo All done... now you can press enter or close this window.; read" '
```

## Any other tools as frontend.
### Example1, list with names only:
```
checkupdates-aur|awk '{print $1}'
```
### Example2, fast list for your perl program:
```
...
use OS::CheckUpdates::AUR;
my $cua = OS::CheckUpdates::AUR->new();
do_updates(@{$cua->get()});
...
```
# INSTALLATION

To install this module, run the following commands:
```
perl Build.PL
./Build
./Build test
./Build install
```
# SUPPORT AND DOCUMENTATION
https://github.com/3ed/CheckUpdates-AUR/

# LICENSE AND COPYRIGHT

Copyright (C) 2016 3ED

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

