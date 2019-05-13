# NAME

Perl::Critic::Policy::Catalyst::ProhibitUnreachableCode - Don't write code after an unconditional Catalyst detach.

# DESCRIPTION

This module was forked from
[Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode](https://metacpan.org/pod/Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode)
version `1.132` and modified to fit.

The primary difference is this module looks for these two
Catalyst specific bits of code as signifying a terminating statement:

```
$c->detach();
$c->redirect_and_detach();
```

The `redirect_and_detach` context method is available if you are using
[Catalyst::Plugin::RedirectAndDetach](https://metacpan.org/pod/Catalyst::Plugin::RedirectAndDetach).

# PARAMETERS

## context\_methods

By default this policy looks for the `detach` and `redirect_and_detach`
context methods.  You can specify additional context methods to look for
with the `context_methods` parameter.  In your `.perlcriticrc` this
would look something like:

```perl
[Catalyst::ProhibitUnreachableCode]
context_methods = my_detaching_method my_other_detaching_method
```

This policy would then consider all of the following lines as
terminating statements:

```perl
$c->detach();
$c->redirect_and_detach();
$c->my_detaching_method();
$c->my_other_detaching_method();
```

## controller\_methods

Sometimes controllers have in-house methods which call `detach`, you
can specify those:

```
[Catalyst::ProhibitUnreachableCode]
controller_methods = foo bar
```

Then this policy would look for any package with `::Controller::` in
its name and would consider the following lines as terminating
statements:

```perl
$self->foo();
$self->bar();
```

There are no default methods for this parameter.

# SUPPORT

Please submit bugs and feature requests to the
Perl-Critic-Policy-Catalyst-ProhibitUnreachableCode GitHub issue tracker:

[https://github.com/bluefeet/Perl-Critic-Policy-Catalyst-ProhibitUnreachableCode/issues](https://github.com/bluefeet/Perl-Critic-Policy-Catalyst-ProhibitUnreachableCode/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
Peter Guzis <pguzis@cpan.org>
```

# COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
