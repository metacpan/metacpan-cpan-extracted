#!perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'author tests run only if $ENV{CLOUDSERVERS_AUTHOR_TESTS} set'
    if (!defined $ENV{'CLOUDSERVERS_AUTHOR_TESTS'}
    || !$ENV{'CLOUDSERVERS_AUTHOR_TESTS'});
plan 'no_plan';

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open(my $fh, '<', $filename)
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{ $violated{$desc} ||= [] }, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
        $module => 'the great new $MODULENAME' => qr/ - The great new /,
        'boilerplate description'  => qr/Quick summary of what the module/,
        'stub function definition' => qr/function[12]/,
    );
}

not_in_file_ok(Changes => "placeholder date/time" => qr(Date/time));
module_boilerplate_ok('lib/Net/RackSpace/CloudServers.pm');
module_boilerplate_ok('lib/Net/RackSpace/CloudServers/Flavor.pm');
module_boilerplate_ok('lib/Net/RackSpace/CloudServers/Image.pm');
module_boilerplate_ok('lib/Net/RackSpace/CloudServers/Server.pm');

