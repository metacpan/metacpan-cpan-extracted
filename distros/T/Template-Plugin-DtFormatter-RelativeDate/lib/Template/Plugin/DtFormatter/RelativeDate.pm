package Template::Plugin::DtFormatter::RelativeDate;

use warnings;
use strict;
use utf8;

use base 'Template::Plugin';

#use DateTime::Locale;
use DateTime::Format::Natural;
use Template::Plugin::DtFormatter::RelativeDate::I18N;
#my $loc = DateTime::Locale->load('ja_JP');

our $MOCK = 0;
my $NATURAL = DateTime::Format::Natural->new;

=head1 NAME

Template::Plugin::DtFormatter::RelativeDate - return finder like relative date.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    [% USE DtFormatter.RelativeDate %]
    [% SET ymd = DtFormatter.RelativeDate.formatter("%Y-%m-%d", 'en') %]

    [% USE date = DateTime(today => 1) %]
    [% ymd( date ) %]                   # Today
    [% ymd( date.add(days=>1) ) %]      # Tomorrow
    [% ymd( date.add(days=>1) ) %]      # 2007-07-31
    [% ymd( date.subtract(days=>3) ) %] # Yesterday
    [% ymd( date.subtract(days=>1) ) %] # 2007-07-27

=head1 FUNCTIONS

=head2 new

internal function.

=cut

sub new {
     my ($class, $context) = @_;

     my $self = bless {}, $class;

     return $self;
}

=head2 formatter(strftime_string, lang)

return closure.

=cut

sub formatter {
    my ($self, $format, $lang) = @_;

    $lang ||= 'en';

    my %memoize;
    if ($MOCK) {
        my $today = DateTime->new(year=>2007,month=>7,day=>28);
        %memoize = (
            today     => $today,
            yesterday => $today->clone->subtract( days => 1 ),
            tomorrow  => $today->clone->add( days => 1 ),
        );
    }

    my $lh  = Template::Plugin::DtFormatter::RelativeDate::I18N->get_handle($lang);

    return sub {
        my $dt = shift;

        local $NATURAL->{Time_zone} = $dt->{tz} if ref($dt) and $dt->isa("DateTime");
        
        for my $string (qw/today yesterday tomorrow/) {
            $memoize{$string} ||= $NATURAL->parse_datetime($string);
            return $lh->maketext($string) if $memoize{$string}->ymd eq $dt->ymd;
        }

        return $format ? $dt->strftime($format) : $dt->ymd;
    };
}

=head1 AUTHOR

bokutin, C<< <bokuin at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
