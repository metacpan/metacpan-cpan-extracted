Module-Build-Prereq
===================

Perl module to naïvely analyze your module dependencies and then make
sure they're properly listed in your Makefile.PL.

## INSTALLATION ##

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

## USAGE ##

Use in your `Makefile.PL`:

    use Module::Build::Prereq;

    my %prereq_pm = (Foo => '1.2',
                     Bar => '2.2a');

    assert_modules(prereq_pm => \%prereq_pm);

    WriteMakefile(CONFIGURE_REQUIRES => {
                    'Module::Build::Prereq' => '0.01',
                  },
                  PREREQ_PM => \%prereq_pm, ...);

Use in your `Build.PL`:

    use Module::Build::Prereq;

    my %prereq_pm = (Foo => '1.2',
                     Bar => '2.2a');

    assert_modules(prereq_pm => \%prereq_pm);

    my $build = Module::Build->new
      (
        requires => \%prereq_pm,
      );
    $build->create_build_script;

`assert_modules` should not be added to any `Makefile.PL` which is
part of a publicly available module (unless you want your module users
to have another needless dependency); it is meant to help a) during
development of any module and b) any time you need to ensure you
deploy with the correct dependencies.

COPYRIGHT AND LICENCE

Copyright (C) 2013 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.
