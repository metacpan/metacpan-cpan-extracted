#!/usr/bin/env perl

use Test::More tests=>7;

use_ok 'Prty::Stacktrace'; 

# Konstruktor

my $st = Prty::Stacktrace->new;
is ref($st),'Prty::Stacktrace';

# asString() als Objektmethode

my $str = $st->asString;
like $str,qr/Prty::Stacktrace::new/;

# asString() als Klassenmethode

$str = Prty::Stacktrace->asString;
like $str,qr/Prty::Stacktrace::asString/;

# Aufrufhierarchie

sub a {
    b();
}

sub b {
    c();
}

sub c {
    $st = Prty::Stacktrace->new;
}

a();

$str = $st->asString;
like $str,qr/^main::a/;
like $str,qr/^  main::b/m;
like $str,qr/^    main::c/m;

# eof
