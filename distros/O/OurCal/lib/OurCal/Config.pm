package OurCal::Config;

use strict;
use Config::INI::Reader;

=head1 NAME

OurCal::Config - a default config reader

=head1 SYNOPSIS

    image_url     = images
    template_path = templates

    [providers]
    providers = default birthday dopplr

    [default]
    dsn  = dbi:SQLite:ourcal
    type = dbi

    [birthday]
    file = ics/birthdays.ics
    type = icalendar

    [dopplr_cache]
    type  = cache
    dir   = .cache
    child = dopplr

    [dopplr]
    file  = http://www.dopplr.com/traveller/ical/user/d34dbeefd34dbeefd34dbeefd34dbeefd34dbeef.ics
    type  = icalendar


=head1 FORMAT

=head2 Generic Config

Then generic configuration contain key value pairs for non specific config values.

=head2 Provider Specific Config

Each provider can have specific config options in a named section.

=cut

=head1 METHODS

=cut

=head2 new <param[s]>

Must be given a file param which gives a path to an C<.ini> type file.

=cut

sub new {
    my $class = shift;
    my %what = @_;
    
    die "You must pass in a 'file' option\n" unless defined $what{file};
    $what{_config} = Config::INI::Reader->read_file($what{file});
    return bless \%what, $class;
}

=head2 config [name]

Returns a hashref containin the config for a give section or the generic config 
if no name is given.

=cut

sub config {
    my $self    = shift;
    my $section = shift || "_";
    return $self->{_config}->{$section}; 
}

1;
