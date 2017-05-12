use strict;
use Test::More;
use Test::Exception;
use ShipIt::Step::Readme;

################################################################################
# no name no version
my $package_content = q~
=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::Readme;

    my $foo = ShipIt::Step::Readme->new();
    ...

~;

throws_ok   sub { ShipIt::Step::Readme->_add_install_instructions($package_content) },
            qr/trying to add pod Install section after VERSION or NAME Section, but there is none/,
            'no name or version dies';


done_testing;