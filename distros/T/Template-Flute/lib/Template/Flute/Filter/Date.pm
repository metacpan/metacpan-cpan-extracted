package Template::Flute::Filter::Date;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use Scalar::Util qw/blessed/;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Date - Date filter

=head1 DESCRIPTION

Date filter based on L<DateTime>.

=head1 PREREQUSITES

L<DateTime> and L<DateTime::Format::ISO8601> modules.

=head1 METHODS

=head2 init

The init method allows you to set the following options:

=over 4

=item format

Format string for L<DateTime>'s strftime method. Defaults to %c.

=item strict

Determines how strict the filter is with empty resp. invalid
dates. The default setting is to throw an error on both.

You can override this setting for empty and invalid dates
separately resulting in returning an empty string instead.

Example for accepting empty dates:

    options => {strict => {empty => 0}}

=item date_text

This option can be used to supply strings for empty and/or
invalid dates. It also overrides the C<strict> option.

Example for empty dates:

    options => {date_text => {empty => 'Not yet scheduled'}}

=back

=cut

sub init {
    my ($self, %args) = @_;
    
    $self->{format} = $args{options}->{format} || '%c';
    $self->{strict} = $args{options}->{strict} || {empty => 1,
                                                   invalid => 1};
    $self->{date_text} = $args{options}->{date_text}
        || {empty => '', invalid => ''};
}

=head2 filter

Date filter.

=cut

sub filter {
    my ($self, $date, %args) = @_;
    my ($dt, $fmt);

    if ($args{format}) {
        $fmt = $args{format};
    }
    else {
        $fmt = $self->{format};
    }

    if (! defined $date || $date !~ /\S/) {
        if (my $date_text = $self->{date_text}->{empty}) {
            return $date_text;
        }
        if (! $self->{strict}->{empty}) {
            # accept empty strings for dates
            return '';
        }
        else {
            die "Empty date.";
        }
    }

    if (defined blessed $date && $date->isa('DateTime')) {
        $dt = $date;
    }
    else {
        # parsing date
        eval {
            $dt = DateTime::Format::ISO8601->parse_datetime($date);
        };

        if ($@) {
            if (my $date_text = $self->{date_text}->{invalid}) {
                return $date_text;
            }
            if ($self->{strict}->{invalid}) {
                die $@;
            }
            else {
                # replace invalid dates with empty string
                return '';
            }
        }
    }

    return $dt->strftime($fmt);
}


=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
