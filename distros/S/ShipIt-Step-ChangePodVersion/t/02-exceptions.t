use strict;
use Test::More;
use Test::Exception;
use ShipIt::Step::ChangePodVersion;

################################################################################
# no name no version
my $package_content = q~
=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~;

throws_ok   sub { ShipIt::Step::ChangePodVersion->_change_pod_version($package_content, 0.01) },
            qr/trying to add a POD VERSION section after NAME Section, but there is none/,
            'no name no version dies';

################################################################################
# numbers next paragraph
$package_content = q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

=head1 SYNOPSIS

122 <= not to be changed

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~;

throws_ok   sub { ShipIt::Step::ChangePodVersion->_change_pod_version($package_content, 0.01) },
            qr/there is a POD VERSION section, but the version cannot be parsed/,
            'no numbers in the next paragraph were harmed during this test';

done_testing;