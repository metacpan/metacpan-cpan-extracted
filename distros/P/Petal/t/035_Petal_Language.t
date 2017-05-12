#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;

# exists_filename tests
{
    my $filename;
    
    $filename = Petal::Functions::exists_filename ('fr-CA' => './t/data/language/exists_filename/');
    is ($filename => 'fr-CA.html');

    $filename = Petal::Functions::exists_filename ('fr'    => './t/data/language/exists_filename/');
    is ($filename => 'fr.xml');
    
    $filename = Petal::Functions::exists_filename ('en'    => './t/data/language/exists_filename/');
    ok (not defined $filename);
}


# parent_language
{
    my $lang = 'fr-CA';
    $lang = Petal::Functions::parent_language ($lang);
    is ($lang => 'fr');
    
    $lang = Petal::Functions::parent_language ($lang);
    is ($lang => 'en');

    $lang = Petal::Functions::parent_language ($lang);
    ok (not defined $lang);
}


{
    local $Petal::OUTPUT   = 'XML';
    local $Petal::BASE_DIR = 't/data/language';
    my $template = new Petal ( file => '.', lang => 'fr-CA');
    like ($template->process() => qr/fr\-CA/);
}


__END__
