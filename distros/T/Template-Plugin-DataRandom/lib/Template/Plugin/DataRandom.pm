#============================================================================
#
# Template::Plugin::DataRandom
#
# DESCRIPTION
#
#   Plugin to use Data::Random in Template Toolkit
#
# AUTHORS
#   Emmanuel Quevillon   <tuco@pasteur.fr>
#
# COPYRIGHT
#   Copyright (C) 2010 Emmanuel Quevillon
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::DataRandom;

use strict;
use vars qw($VERSION);

use base 'Template::Plugin';
use Template::Plugin;
use Template::Exception;

use Data::Random qw(:all);

$VERSION = '0.03';

sub new {

    my($class, $context) = @_;

    bless {
        _CONTEXT => $context,
    },$class;
}

sub rndwrds {

    my $self = shift;
    my $args = shift;

    return rand_words(%$args);
}

sub rndchrs {

    my $self = shift;
    my $args = shift;

    return rand_chars(%$args);
}

sub rndset {

    my $self = shift;
    my $args = shift;

    return rand_set(%$args);
}

sub rndenum {

    my $self = shift;
    my $args = shift;

    return rand_enum(%$args);
}

sub rnddate {

    my $self = shift;
    my $args = shift;

    return rand_date(%$args);
}

sub rndtime {

    my $self = shift;
    my $args = shift;

    return rand_time(%$args);
}

sub rnddtime {

    my $self = shift;
    my $args = shift;

    return rand_datetime(%$args);
}

sub rndimg {

    my $self = shift;
    my $args = shift;

    return rand_image(%$args);
}

1;

__END__

=head1 NAME

Template::Plugin::DataRandom - Plugin to access Data::Random method in Template Toolkit

=head1 SYNOPSIS

 [% USE r = DataRandom %]

 [% words = r.rndwrds(size => 10) %]

 [% chars = r.rndchrs(set => alpha, size => 5 %]

 [% set = r.rndset(set => ['string1', 'string2'], size => 5 %]

 [% enum = r.rndenum(set => ['string1', 'string2', .. ]) %]

 [% date = r.rnddate(min => '1998-12-31') %]

 [% time = r.rndtime(min => '12:00:00', max => 'now' ) %]

 [% dtime = r.rnddtime(min => '1978-9-21 4:0:0', max => 'now' ) %]

 [% img = r.rndimg(minwidth => '10', maxwidth => '80', bgcolor => [55,120,255]) %]


=head1 DESCRIPTION

This plugin has been made to create random data on demand in your template.
It is deeply inspired from Adekunle Olonoh L<Data::Random> module.

=head1 METHODS

=head2 rndwrds

This returns a list of random words given a wordlist.  See below for possible parameters.

See L<Data::Random/rand_words()> for more infos about available options.

=head2 rndchrs

This returns a list of random characters given a set of characters.  See below for possible parameters.

See L<Data::Random/rand_chars()> for more infos about available options.

=head2 rndset

This returns a random set of elements given an initial set.  See below for possible parameters.

See L<Data::Random/rand_set()> for more infos about available options.

=head2 rnddate

This returns a random date in the form "YYYY-MM-DD". 2-digit years are not currently supported.  Efforts are made to make sure you're returned a truly valid date--ie, you'll never be returned the date February 31st.  See the options below to find out how to control the date range.

See L<Data::Random/rand_date()> for more infos.

=head2 rndtime

This returns a random time in the form "HH:MM:SS".  24 hour times are supported.  See the options below to find out how to control the time range.

See L<Data::Random/rand_datetime()> for more infos about available options.


=head2 rnddtime

This returns a random date and time in the form "YYYY-MM-DD HH:MM:SS".  See the options below to find out how to control the date/time range.

See L<Data::Random/rand_datetime()> for more infos about available options.

=head2 rndimg

This returns a random image. Currently only PNG images are supported.  See below for possible parameters.
See L<Data::Random/rand_image()> for more infos about available options.

=head1 VERSION

0.03

=head1 AUTHOR

Emmanuel Quevillon, tuco@pasteur.fr


=head1 COPYRIGHT

Copyright (c) 2010 Emmanuel Quevillon.
All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Template::Plugin, Data::Random

=cut

