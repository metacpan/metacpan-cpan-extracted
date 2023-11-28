# General

I am always open to improvements and suggestions.
Use [issues](https://github.com/CPAN-Security/Test-CVE/issues)

# Style

Below is not carved in stone for this module, as it is meant to be
a group effort.

I will not accept pull request that do not strictly conform to my
style, however you might hate it. You can read the reasoning behind
my [preferences](https://tux.nl/style.html). However, I am likely
to accept contributions that add real value or improvements, after
which I will fix the style issues myself.

I really do not care about mixed spaces and tabs in (leading) whitespace

Perl::Tidy will help getting the code in shape, but as all software, it
is not perfect. You can find my preferences for these in
[.perltidy](https://github.com/Tux/Release-Checklist/blob/master/.perltidyrc) and
[.perlcritic](https://github.com/Tux/Release-Checklist/blob/master/.perlcriticrc).

# Mail

Please, please, please, do *NOT* use HTML mail.
[Plain text](https://useplaintext.email)
[without](http://www.goldmark.org/jeff/stupid-disclaimers/)
[disclaimers](https://www.economist.com/business/2011/04/07/spare-us-the-e-mail-yada-yada)
will do fine!

# Requirements

The minimum version required to use this module is stated in
[Makefile.PL](./Makefile.PL), [META.json](./META.json) and
[cpanfile](./cpanfile)

# Testing

If you want to do the extensive testing like I do, please refer to
[Release::Checklist](https://metacpan.org/module/Release::Checklist)
which explains all the modules used when executing `make tgzdist`.
Lots of custom stuff.
