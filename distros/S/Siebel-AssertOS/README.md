# Siebel-AssertOS

This modules will help identifying if the current OS that is running is supported by Siebel applications. If not, the module will cause an exception, forcing the code to stop being executed.

This is particulary useful for automated tests.

The list of supported OS is as defined by Oracle documentation regarding Siebel 8.2.

## INSTALLATION

To install this module type the following:

```
perl Makefile.PL
make
make test
make install
```

## DEPENDENCIES

None. Only Perl core modules here.

## COPYRIGHT AND LICENCE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

This file is part of Siebel GNU Tools project.

Siebel GNU Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel GNU Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel GNU Tools.  If not, see http://www.gnu.org/licenses/.
