
# Perl-Critic-Mardem

## DESCRIPTION

Perl-Critic policies for isolated Refactoring-Support.

This Perl-Critic Policy-Modules should help where to start a safe
refactoring in old legacy Perl code.

The McCabe complexity check within the standard Perl-Critic Module are a good
overall starting point see:

* [Perl::Critic::Policy::Modules::ProhibitExcessMainComplexity](https://metacpan.org/pod/Perl::Critic::Policy::Modules::ProhibitExcessMainComplexity)
* [Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity](https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity)

but these are for some bigger scans, so these new policies should check (or begin) in smaller chunks:

1. **[ProhibitReturnBooleanAsInt](lib/Perl/Critic/Policy/Mardem/ProhibitReturnBooleanAsInt.pm)** - return boolean as int "return 1;"
1. **[ProhibitConditionComplexity](lib/Perl/Critic/Policy/Mardem/ProhibitConditionComplexity.pm)** - condition complexity "if/while/for/... (...){}"
1. **[ProhibitManyConditionsInSub](lib/Perl/Critic/Policy/Mardem/ProhibitManyConditionsInSub.pm)** - subs has many conditionals "if, while, for, ..."
1. **[ProhibitLargeBlock](lib/Perl/Critic/Policy/Mardem/ProhibitLargeBlock.pm)** - large code block as statement count "{...}"
1. **[ProhibitBlockComplexity](lib/Perl/Critic/Policy/Mardem/ProhibitBlockComplexity.pm)** - code block complexity "{...}"
1. **[ProhibitLargeSub](lib/Perl/Critic/Policy/Mardem/ProhibitLargeSub.pm)** - large subs as statement count
1. **[ProhibitLargeFile](lib/Perl/Critic/Policy/Mardem/ProhibitLargeFile.pm)** - large files as line count
1. **[ProhibitFileSize](lib/Perl/Critic/Policy/Mardem/ProhibitFileSize.pm)** - large files as byte or char count

## INSTALLATION

To install this module, run the following commands:

```
  perl Build.PL
  ./Build
  ./Build test
  ./Build install
```

## SUPPORT AND DOCUMENTATION

Each policy has its own detailed documentation.

## BUG REPORTS

Please report bugs on GitHub.

The source code repository can be found at [https://github.com/mardem1/perl-critic-mardem](https://github.com/mardem1/perl-critic-mardem)

## AUTHOR

Markus Demml, mardem@cpan.com

## LICENSE AND COPYRIGHT

Copyright (c) 2024, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

## DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.
