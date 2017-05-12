#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::BASE_DIR = ('t/data');
my $file     = 'metal_define_macro.xml';

$Petal::OUTPUT = 'XML';

{
    my $t = new Petal ( file => 'metal_define_macro.xml' );
    my $s = $t->process();
    like ($s, qr/<span>Foo<\/span>/);
    like ($s, qr/<span>Bar<\/span>/);
    like ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#foo' );
    my $s = $t->process();
    like ($s, qr/<span>Foo<\/span>/);
    unlike ($s, qr/<span>Bar<\/span>/);
    unlike ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#bar' );
    my $s = $t->process();
    unlike ($s, qr/<span>Foo<\/span>/);
    like ($s, qr/<span>Bar<\/span>/);
    unlike ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#baz' );
    my $s = $t->process();
    unlike ($s, qr/<span>Foo<\/span>/);
    unlike ($s, qr/<span>Bar<\/span>/);
    like ($s, qr/<span>Baz<\/span>/);
}

$Petal::OUTPUT = 'XHTML';

{
    my $t = new Petal ( file => 'metal_define_macro.xml' );
    my $s = $t->process();
    like ($s, qr/<span>Foo<\/span>/);
    like ($s, qr/<span>Bar<\/span>/);
    like ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#foo' );
    my $s = $t->process();
    like ($s, qr/<span>Foo<\/span>/);
    unlike ($s, qr/<span>Bar<\/span>/);
    unlike ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#bar' );
    my $s = $t->process();
    unlike ($s, qr/<span>Foo<\/span>/);
    like ($s, qr/<span>Bar<\/span>/);
    unlike ($s, qr/<span>Baz<\/span>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#baz' );
    my $s = $t->process();
    unlike ($s, qr/<span>Foo<\/span>/);
    unlike ($s, qr/<span>Bar<\/span>/);
    like ($s, qr/<span>Baz<\/span>/);
}

