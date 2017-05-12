use strict;
use Test::More;
use ShipIt::Step::ChangePodVersion;

################################################################################
# replacing version
my $package_content = q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

1

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~;

my $new_package = ShipIt::Step::ChangePodVersion->_change_pod_version($package_content, 0.01);
is  $new_package,
    q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~,
    'Version exists and is replaced';

################################################################################
# replacing version + word before versionnumber
$package_content = q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

Version 1

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~;

$new_package = ShipIt::Step::ChangePodVersion->_change_pod_version($package_content, 0.01);
is  $new_package,
    q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~,
    'Version exists and is replaced, no words before versionnumber were harmed';


################################################################################
# creating version
$package_content = q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~;

$new_package = ShipIt::Step::ChangePodVersion->_change_pod_version($package_content, 0.01);
is  $new_package,
    q~
=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in jour Pod in sync with $VERSION

=head1 VERSION

0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ShipIt::Step::ChangePodVersion;

    my $foo = ShipIt::Step::ChangePodVersion->new();
    ...

~,
    'Version is created';



done_testing;