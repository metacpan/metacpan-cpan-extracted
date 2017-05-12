#!perl -T
use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Exception;

package Test::Factory;
use Test::DeepMock ();

our @ISA = qw( Test::DeepMock );
our $PATH_TO_MOCKS;
our $CONFIG = {
    'Mock::Source' => {
        source => 'package Mock::Source; sub who_am_i {__PACKAGE__} 1;'
    },
    'Mocking::Source::Ref' => {
        source => \'package Mocking::Source::Ref; sub who_am_i {__PACKAGE__} 1;'
    },
    'Mock::FileHandle' => {
        file_handle => *DATA
    },
    'MockByPath' => {
        path => 't'
    },
    default => sub {
        my ($class, $package) = @_;
        return \"package $package; sub who_am_i {__PACKAGE__} 1;";
    }
};

package main;

Test::Factory->import ( grep {$_ ne 'default'} keys %{$Test::Factory::CONFIG}, 'Default::Handled::Package' );

foreach my $package (keys %{$Test::Factory::CONFIG}){
    next if $package eq 'default';
    my $file_name = $package;
    $file_name =~ s/::/\//g;
    require $file_name . '.pm';
    is($package->who_am_i, $package, "mocked $package");
}

require Default::Handled::Package;
is(Default::Handled::Package->who_am_i, 'Default::Handled::Package', "mocked Default::Handled::Package");

$Test::Factory::PATH_TO_MOCKS = 't';
Test::Factory->import("Reading::From::Package::Path");
require Reading::From::Package::Path;
is(Reading::From::Package::Path->who_am_i, 'Reading::From::Package::Path', "mocked Reading::From::Package::Path");

$Test::Factory::CONFIG->{default} = {};
throws_ok(sub {Test::Factory->import("Default::Handler::Throws")}, qr/could not mock/, "could not mock");

$Test::Factory::CONFIG->{default} = sub {
    my ($class, $package) = @_;
    my $FH;
    open($FH,'< t/MockByFileHandle.pm');
    return $FH;
};
$Test::Factory::PATH_TO_MOCKS = undef;
Test::Factory->import("MockByFileHandle");
require MockByFileHandle;
is(MockByFileHandle->who_am_i, 'MockByFileHandle', "mocked MockByFileHandle");

$Test::Factory::CONFIG->{default} = {};
throws_ok(sub {Test::Factory->import("Panic::Error")}, qr/could not mock/, "handler is not a sub");

$Test::Factory::CONFIG->{default} = sub { die "in purpose"; };
throws_ok(sub {Test::Factory->import("Panic::Error")}, qr/default handler died/, "handler is died");

$Test::Factory::CONFIG->{default} = sub {  };
throws_ok(sub {Test::Factory->import("Panic::Error")}, qr/could not mock/, "handler returned undef");

$Test::Factory::CONFIG->{default} = sub { return \sub {} };
throws_ok(sub {Test::Factory->import("Panic::Error")}, qr/could not mock/, "handler returned sub");

$Test::Factory::CONFIG->{default} = sub { 'package Panic::Error; sub who_am_i {__PACKAGE__} 1;' };
Test::Factory->import("Panic::Error");
require Panic::Error;
is(Panic::Error->who_am_i, 'Panic::Error', "mocked Panic::Error by default with scalar");

done_testing();

package Test::Factory;
__DATA__
package Mock::FileHandle;
sub who_am_i {__PACKAGE__}
1;
