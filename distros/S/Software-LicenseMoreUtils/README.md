# Software::LicenseMoreUtils #

This Perl modules provides some utilities on top of [Software::License](https://metacpan.org/pod/Software::License):

* The possibility to create
  [Software::License](https://metacpan.org/pod/Software::License)
  object using short names like `GPL-1`,
  `GPL_1`. [new_from_short_name](https://metacpan.org/pod/Software::LicenseUtils#new_from_short_name) from  [Software::LicenseUtils](https://metacpan.org/pod/Software::LicenseUtils)
  provides a similar function but knows less short names than this
  module.
* Support license summaries on Debian that redirect the user to the licenses available in
  `/usr/share/common-licenses`
* Provides a
  [LGPL-2](http://search.cpan.org/perldoc?Software%3A%3ALicense%3A%3ALGPL_2)
  object. LGPL-2 is deprecated but sometimes found in Debian packages.

## Compatibility ##

[new_from_short_name](http://search.cpan.org/~ddumont/Software-LicenseMoreUtils-0.001/lib/Software/LicenseMoreUtils.pm#new_from_short_name)
has the same parameters as
[new_from_short_name](https://metacpan.org/pod/Software::LicenseUtils#new_from_short_name). It
returns Returns a new
[Software::LicenseUtils::LicenseWithSummary](https://metacpan.org/pod/Software::LicenseUtils::LicenseWithSummary)
object which has the same methods as
[Software::License](https://metacpan.org/pod/Software::License).

## What about RedHat and other Linux distributions ##

This module was written mainly to help Debian packaging. Adding
support for other distribution should be straightforward. PRs are
welcome.


