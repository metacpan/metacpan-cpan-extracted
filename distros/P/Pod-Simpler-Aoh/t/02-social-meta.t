#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Pod::Simpler::Aoh' ) || print "Bail out!\n";
}

subtest 'hash options' => sub {
     test_value({
        get => 0,
        identifier => 'head1',
        content => 'HTML::SocialMeta - Module to generate Social Media Meta Tags,',
        title => 'NAME',
    }); 
    test_value({
        get => 5,
        identifier => 'head2',
        title => 'Constructor',
        content => q{Returns an instance of this class. Requires $url as an argument;

card

OPTIONAL - if you always want the same card type you can set it

site

The Twitter @username the card should be attributed to. Required for Twitter Card analytics.

site_name

This is Used by Facebook, you can just set it as your organisations name.

title

The title of your content as it should appear in the card

description

A description of the content in a maximum of 200 characters

image

A URL to a unique image representing the content of the page

url

OPTIONAL OPENGRAPH - allows you to specify an alternative url link you want the reader to be redirected

player

HTTPS URL to iframe player. This must be a HTTPS URL which does not generate active mixed content warnings in a web browser

player_width

Width of IFRAME specified in twitter:player in pixels

player_height

Height of IFRAME specified in twitter:player in pixels

operating_system

IOS or Android

app_country

UK/US ect

app_name

The applications name

app_id

String value, and should be the numeric representation of your app ID in the App Store (.i.e. 307234931)

app_url

Application store url - direct link to App store page

fb_app_id

This field is required to use social meta with facebook, you must register your website/app/company with facebook. They will then provide you with a unique app_id.},    
    }); 
};

done_testing();

sub test_value {
    my $args = shift;

    my $parser = Pod::Simpler::Aoh->new();
    $parser->parse_from_file( 't/data/social-meta.pod' );

    my $values = $parser->get($args->{get});
    
    my @fields = qw(identifier content title);
    foreach my $field (@fields) {
        is($values->{$field}, $args->{$field}, "correct value for $field - get $args->{get}");
    }
}

1;
