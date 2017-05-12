# ABSTRACT: Selenium's PageObject pattern in Perl.  Now your module @ISA pageObject!
# PODNAME: Selenium::PageObject

package Selenium::PageObject;
$Selenium::PageObject::VERSION = '0.012';
use 5.010;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(reftype blessed);
use Try::Tiny;

use Selenium::Remote::WDKeys; #Needed to send things like tabs for navigation
use Selenium::Element;


sub new {
    my ($class,$driver,$uri) = @_;
    confess("Constructor must be called statically, not by an instance") if ref($class);
    confess("Driver must be an instance of Selenium::Remote::Driver or WWW::Selenium") if !( grep {defined(blessed($driver)) && $_ eq blessed($driver)} qw(Selenium::Remote::Driver WWW::Selenium) );

    my $self = {
        'drivertype' => blessed($driver) eq 'WWW::Selenium',
        'driver'     => $driver,
        'page'       => $uri
    };

    $self->{'drivertype'} ?  $driver->open($uri) : $driver->get($uri); #Get initial page based on what type of driver used

    bless $self, $class;
    return $self;
}


sub driver {
    my $self = shift;
    return $self->{'driver'};
}


sub getElement {
    my ($self,$selector,$selectortype) = @_;
    my $element;
    if ($self->{'drivertype'}) {
        $element = $self->{'driver'}->is_element_present("$selectortype=$selector") ? "$selectortype=$selector" : undef;
    } else {
        try {
            $element = $self->{'driver'}->find_element($selector,$selectortype);
        } catch {
            carp "# $_ \n";
            $element = undef;
        }
    }
    return Selenium::Element->new($element,$self->{'drivertype'} ? $self->{'driver'} : $self->{'drivertype'},[$selector,$selectortype]);
}


sub getElements {
    my ($self,$selector,$selectortype) = @_;
    my $elements = [];
    confess ("WWW::Selenium is designed to work with single elements.  Consider refining your selectors and looping instead.") if $self->{'drivertype'};
    try {
        @$elements = $self->{'driver'}->find_elements($selector,$selectortype);
    };
    return map {Selenium::Element->new($_,$self->{'drivertype'} ? $self->{'driver'} : $self->{'drivertype'},[$selector,$selectortype])} @$elements;
}


sub tab {
    my $self = shift;
    #9 is VK_TAB
    $self->{'drivertype'} ? $self->driver->key_press_native(9) : $self->driver->send_keys_to_active_element(KEYS->{'tab'});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::PageObject - Selenium's PageObject pattern in Perl.  Now your module @ISA pageObject!

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    package ExamplePageObject;
    use base qw{Selenium::PageObject};
    sub do_something_cool_returning_an_element {
        my $self = shift;
        return $self->getElement('radElement','id');
    }
    1;

=head1 DESCRIPTION

This module is intended to be a base for PageObjects.
It abstracts a good deal of the things required to get/set various page inputs, and provides callback hooks so you can do special things like wait for JS.
It also is driver agnostic -- use WWW::Selenium or Selenium::Remote::Driver if you want.
I recommend Selenium::Remote::Driver due to it having a more complete feature set.

Refer to the other module in this distribution L<Selenium::Element> for the rest.

=head1 CONSTRUCTOR

=head2 new(driver,uri)

Create a new PageObject using the provided driver, and navigate to the provided URI.
If you have subclassed your driver, you will need to override this method to not do it's strict driver class checks.

B<INPUTS>:

I<DRIVER (WWW::Selenium or Selenium::Remote::Driver)> - The driver object

I<URI (STRING)> - the page this object should fiddle with (saved as $self->{'page'})

B<OUTPUT>:

  new Selenium::PageObject object

=head1 UTILITY

=head2 driver

The base selenium driver is available to you here.

=head1 GETTERS

=head2 getElement(SELECTOR,SELECTORTYPE)

Get the first element matching the provided selector and selector type.  Refer to your driver's documentation as to valid types.

B<INPUTS>:

I<SELECTOR (STRING)> - Instructions for finding some element on the page

I<SELECTORTYPE (STRING)> - Specification by which above instructions are parsed

B<OUTPUT>:

  new Selenium::Element object

=head2 getElements(SELECTOR,SELECTORTYPE)

Get the elements matching the provided selector and selector type.  Refer to your driver's documentation as to valid types.
WWW::Selenium is designed to work with single elements, so this method will fail when using it.  Consider refining your selectors and looping instead.

B<INPUTS>:

I<SELECTOR (STRING)> - Instructions for finding some element on the page

I<SELECTORTYPE (STRING)> - Specification by which above instructions are parsed

B<OUTPUT>:

  array of new Selenium::Element objects

=head1 GLOBAL EVENTS

=head2 tab

Send a tab to the page, to test tab navigation, or to blur the current element (useful for lose focus listeners, etc).

=head1 SEE ALSO

L<WWW::Selenium>

L<Selenium::Remote::Driver>

L<https://code.google.com/p/selenium/wiki/PageFactory>
for info about PageFactories, like this

L<https://code.google.com/p/selenium/wiki/PageObjects>
for more info about page objects themselves.

=head1 SPECIAL THANKS

cPanel, Inc. graciously funded the initial work on this Module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Neil Bowers

Neil Bowers <neil@bowers.com>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/Selenium-PageObjects-Perl>
and may be cloned from L<git://github.com/teodesian/Selenium-PageObjects-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
