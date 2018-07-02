# Software::LicenseMoreUtils #

This Perl modules provides some utilities on top of [Software::License](https://metacpan.org/pod/Software::License):

* The possibility to create
  [Software::License](https://metacpan.org/pod/Software::License)
  object using short names like `GPL-1`, `GPL_1`. This module accepts
  more variations on the short name than
  [new_from_short_name](https://metacpan.org/pod/Software::LicenseUtils#new_from_short_name)
  from
  [Software::LicenseUtils](https://metacpan.org/pod/Software::LicenseUtils).
* Support license summaries on Debian that redirect the user to the licenses available in
  `/usr/share/common-licenses`
* Provides a
  [LGPL-2](http://search.cpan.org/perldoc?Software%3A%3ALicense%3A%3ALGPL_2)
  object. LGPL-2 is deprecated but sometimes found in Debian packages.
* GPL summaries support the "or later" clause often used with GPL licenses

## Example ##

```perl
use Software::LicenseMoreUtils;
   
 my $lic = Software::LicenseMoreUtils->new_from_short_name({
   short_name => 'Apache-2.0', # accepts also Apache-2 Apache_2_0
   holder => 'X. Ample'
});

# returns a license summary on Debian, returns license text elsewhere
my $text = $lic->summary_or_text;

# returns license full text
my $text = $lic->text;

my $gpl = Software::LicenseMoreUtils->new_from_short_name({
   short_name => 'GPL-1+',
   holder => 'X. Ample'
});

say $gpl->summary_or_text;

```

## Compatibility ##

[new_from_short_name](http://search.cpan.org/perldoc?Software%3A%3ALicenseMoreUtils%3A%3ALicenseWithSummary#new_from_short_name)
accepts the same parameters as the
[new_from_short_name](https://metacpan.org/pod/Software::LicenseUtils#new_from_short_name)
method provided by
[Software::License](https://metacpan.org/pod/Software::License). It
returns a new
[Software::LicenseMoreUtils::LicenseWithSummary](https://metacpan.org/pod/Software::LicenseMoreUtils::LicenseWithSummary)
object which supports the same methods as
[Software::License](https://metacpan.org/pod/Software::License).

## What about RedHat and other Linux distributions ##

This module was written mainly to help Debian packaging. Adding
support for other distribution should be straightforward. PRs are
welcome.


