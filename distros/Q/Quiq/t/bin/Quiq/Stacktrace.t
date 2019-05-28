#!/usr/bin/env perl

use Test::More tests => 7;

use_ok 'Quiq::Stacktrace'; 

# Konstruktor

my $st = Quiq::Stacktrace->new;
is ref($st),'Quiq::Stacktrace';

# asString() als Objektmethode

my $str = $st->asString;
like $str,qr/Quiq::Stacktrace::new/;

# asString() als Klassenmethode

$str = Quiq::Stacktrace->asString;
like $str,qr/Quiq::Stacktrace::asString/;

# Aufrufhierarchie

sub a {
    b();
}

sub b {
    c();
}

sub c {
    $st = Quiq::Stacktrace->new;
}

a();

$str = $st->asString;
like $str,qr/^main::a/;
like $str,qr/^  main::b/m;
like $str,qr/^    main::c/m;

# eof
