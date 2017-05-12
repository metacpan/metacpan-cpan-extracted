#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class) = shift;
    return bless {}, $class;
}

sub PRINT  {
    my($self) = shift;
    $main::_STDOUT_ .= join '', @_;
}

sub READ {}
sub READLINE {}
sub GETC {}

package main;

local $SIG{__WARN__} = sub { $_STDERR_ .= join '', @_ };
tie *STDOUT, 'Catch' or die $!;


{
#line 36 lib/Module/InstalledVersion.pm

BEGIN: { use_ok("Module::InstalledVersion", "Use Module::InstalledVersion") }

foreach my $module (qw(CPAN Fcntl Text::Wrap)) {
    if (eval "require $module" ) {
        my $m = Module::InstalledVersion->new($module);
        ok($m->isa("Module::InstalledVersion"), "create new object for $module");
        is($m->{version}, ${"${module}::VERSION"}, "Picked up version of $module");
    } else {
        print STDERR "Can't require $module\n";
    }
}


}

