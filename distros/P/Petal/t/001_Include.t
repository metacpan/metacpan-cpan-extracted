#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More tests => 8;
use Petal;
sub nowarnings {
    $Petal::MEMORY_CACHE &&
    $Petal::DISK_CACHE
};

$Petal::BASE_DIR = './t/data/include';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;

my $petal = new Petal ('index.xml');

unlike(${$petal->_canonicalize()}, '/World""/', "canonicalise");
like($petal->process, '/__INCLUDED__/', "find marker");
unlike($petal->process, '/__INCLUDED__\s+<\/body>/', "find marker and tag");
like($petal->process, '/Hello, &quot;World&quot;/', "find hello");

{
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "MTB - XML find included");
    
    $Petal::OUTPUT = "XHTML";
    $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "MTB - XHTML find included");
}

$Petal::BASE_DIR = './t/data/include/deep';
eval {
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('index.xml');
    $petal->process;
};
like($@, '/Cannot go above base directory/', "correct error");


$Petal::BASE_DIR = './t/data/include';
{
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('deep/index.xml');
    like($petal->process, '/__INCLUDED__/', "deep find included");
}


1;


__END__
