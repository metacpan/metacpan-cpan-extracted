package Template::Plugin::Datum;
$VERSION = 0.02;

use strict;
use base 'Template::Plugin';

sub new {
    my ($self, $context) = @_;

    $context->define_filter('datum', \&datum, '');

    return $self;
}

sub datum {
    my $text = shift || '';

    my @date = ();
    my @time = ();

    # 8 digits?
    if ($text =~ /^(\d{4})(\d{2})(\d{2})$/) {
        @date = ($1, $2, $3);
    } elsif ($text =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/) {
        @date = ($1, $2, $3);
        @time = ($4, $5, $6);
    } else {
        # split on '-', '.' or '/'
        @date = split(/[-\/.]/, $text);
    }

    # wrong?
    return '' unless (scalar @date == 3);

    my $output = join('.', reverse @date);

    if (scalar @time == 3) {
        $output .= ' '.join(':', @time);
    }

    return $output;
}


1;
__END__

=head1 NAME

Template::Plugin::Datum - TT2 plugin that converts international
date format to German date format

=head1 SYNOPSIS

  [% USE Datum %]

  von: [% '20030101' | datum %]   -> 01.01.2003
  bis: [% '2003-12-31' | datum %] -> 31.12.2003

  Zeitstempel: [% '20031212143000' | datum %] -> 12.12.2003 14:30:00

=head1 DESCRIPTION

This plugin converts international date format (year-month-day) to
German date format (day.month.year).

Recognized formats are:

=over 2

=item *

yyyy-mm-dd (2003-12-31)

=item *

yyyymmdd (20031231)

=item *

yyyymmddHHMMSS (20031231143000) date and time

=back

=head1 NOTE

It does not check the date if it is correct!

MySQL returns international date format by default.

=head1 AUTHOR

Uwe Voelker E<lt>uwe.voelker@gmx.deE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut
