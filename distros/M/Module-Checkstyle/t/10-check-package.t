#!perl
use Test::More tests => 22;

use strict;
use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Package'); } # 1


my $checker = Module::Checkstyle::Check::Package->new(Module::Checkstyle::Config->new(\*DATA));

# matches-name
{
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
package Foo::Bar;
END_OF_CODE

    is(scalar $checker->begin_document($doc), 0); # 2
    my $tokens = $doc->find('PPI::Statement::Package');
    is(scalar @$tokens, 1); # 3
    my @problems = $checker->handle_package(shift @$tokens);
    is(scalar @problems, 0); # 4
    is(scalar $checker->end_document($doc), 0); # 5
}

# don't match name
{
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
package Foo::Bar2;
END_OF_CODE

    is(scalar $checker->begin_document($doc), 0); # 6
    my $tokens = $doc->find('PPI::Statement::Package');
    is(scalar @$tokens, 1); # 7
    my @problems = $checker->handle_package(shift @$tokens);
    is(scalar @problems, 1); # 8
    my $problem = shift @problems;
    like("$problem", qr/name 'Foo::Bar2' does not match/); # 9
    is(scalar $checker->end_document($doc), 0); # 10
}

# count declarations
{
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
package Foo::Bar;
package Foo::Bar::Baz;
END_OF_CODE

    is(scalar $checker->begin_document($doc), 0); # 11
    my $tokens = $doc->find('PPI::Statement::Package');
    is(scalar @$tokens, 2); # 12
    my @problems = $checker->handle_package(shift @$tokens);
    is(scalar @problems, 0); # 13
    @problems = $checker->handle_package(shift @$tokens);
    is(scalar @problems, 1); # 14
    
    is(scalar $checker->end_document($doc), 0); # 15
}

# check package is first statement
{
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
#!/usr/bin/perl

my $x = 10;

package Foo::Bar;
END_OF_CODE

   my @problems = $checker->begin_document($doc, 'MyModule.pm');
   is(scalar @problems, 1); # 16
   my $problem = shift @problems;
   like("$problem", qr/First statement is not a package declaration/); # 17
}

# check package matches filename
{
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
package Foo::Bar;
END_OF_CODE

    my @problems = $checker->begin_document($doc, 'lib/Foo/Bar.pm');
    is(scalar @problems, 0); # 18
    $checker->handle_package($_, 'lib/Foo/Bar.pm') foreach(@{$doc->find('PPI::Statement::Package')});
    @problems = $checker->end_document($doc, 'lib/Foo/Bar.pm');
    is(scalar @problems, 0); # 19

    $doc = PPI::Document->new(\<<'END_OF_CODE');
package Foo::Bar;
END_OF_CODE

    @problems = $checker->begin_document($doc, 'lib/Foo/Bar2.pm');
    is(scalar @problems, 0); # 20
    $checker->handle_package($_, 'lib/Foo/Bar2.pm') foreach(@{$doc->find('PPI::Statement::Package')});
    @problems = $checker->end_document($doc, 'lib/Foo/Bar2.pm');
    is(scalar @problems, 1); # 21
}

# handle_package with wrong args
{
    eval {
        my $problems = $checker->handle_package(bless {}, 'MyModule');
        fail('Called handle_package with wrong argument'); # 22
    };
    if($@) {
        like($@, qr(^Expected 'PPI::Statement::Package' but got 'MyModule' at)); # 22
    }
}

1;

__DATA__
global-error-level    = WARN

[Package]
matches-name          = ERROR /^([A-Z][A-Za-z]+)(::[A-Z][A-Za-z]+)*$/
max-per-file          = 1
is-first-statement    = true
has-matching-filename = true
