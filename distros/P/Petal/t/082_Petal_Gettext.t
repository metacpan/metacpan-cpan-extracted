#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal::I18N;
use Petal;

eval "use Locale::Maketext::Gettext";
if ($@) {
   warn "Locale::Maketext::Gettext not found - skipping";
   ok (1);
}
else {
    eval "use Petal::TranslationService::MOFile";
    eval "use Petal::TranslationService::Gettext";
    $@ and die $@;

    my %lexicon = read_mo ('./t/data/gettext/mo/fr.mo');
    ok ( $lexicon{'you-are-user'} );
    ok ( $lexicon{'hello-this-is-a-test'} );

    my $ts = Petal::TranslationService::MOFile->new ('./t/data/gettext/mo/en.mo');
    my $t = new Petal ( file => './t/data/gettext/html/index.html',
                        disk_cache => 0,
                        memory_cache => 0,
                        translation_service => $ts );


    my $res = $t->process( user_name => 'becky');
    like ($res, qr/Hello, this is a test/);
    like ($res, qr/You are user \<span\>becky\<\/span\>/);
    like ($res, qr/a search engine/);

    $ts = Petal::TranslationService::MOFile->new ('./t/data/gettext/mo/fr.mo');
    ok ($ts->maketext ('you-are-user'));
    ok ($ts->maketext ('hello-this-is-a-test'));

    $t = new Petal ( file => './t/data/gettext/html/index.html',
                     disk_cache => 0,
                     memory_cache => 0,
                     translation_service => $ts );
    
    $res = $t->process ( user_name => 'becky');
    like ($res, qr/Bonjour, ceci est un test/);

    my $ts_en = Petal::TranslationService::Gettext->new (
        locale_dir  => './t/data/locale',
        target_lang => 'en',
    ); 

    my $ts_es = Petal::TranslationService::Gettext->new (
        locale_dir  => './t/data/locale',
        target_lang => 'es',
    ); 

    my $ts_fr = Petal::TranslationService::Gettext->new (
        locale_dir  => './t/data/locale',
        target_lang => 'fr',
    );

    $t = new Petal ( file => './t/data/i18n-test.html',
                     disk_cache => 0,
                     memory_cache => 0 );

    $res = $t->process();
    like ($res, qr/i18n/);
    like ($res, qr/Hello, World/);

    $t->{translation_service} = $ts_en;
    $res = $t->process();
    unlike ($res, qr/i18n/);
    like ($res, qr/Hello, World/);


    $t->{translation_service} = $ts_fr;
    $res = $t->process();
    unlike ($res, qr/i18n/);
    like ($res, qr/Bonjour, le monde/);

    $t->{translation_service} = $ts_es;
    $res = $t->process();
    unlike ($res, qr/i18n/);
    like ($res, qr/Hola, Mundo/);

}


1;


__END__
