package Mojolicious::Plugin::FormFieldsFromJSON::Date;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

use Time::Piece;

sub register {
    my ($self, $app) = @_;

    1;
}

sub Mojolicious::Plugin::FormFieldsFromJSON::_date {
    my ($self, $c, $field, %params) = @_;

    my $name         = $field->{name} // $field->{label} // '';
    my $id           = $field->{id} // $name;
    my %local_params = %{ $params{$name} || {} };

    my $requested = ( $c->param( $name . '-day' ) ) ?
       ( sprintf "%04d-%02d-%02d",
           $c->param( $name . '-year' ),
           $c->param( $name . '-month' ),
           $c->param( $name . '-day' ),
       ) :
       "";

    my $now      = localtime;
    my $default  = $local_params{data} || $requested || $field->{data} || $now->ymd;
    my $selected = Time::Piece->strptime( $default, '%Y-%m-%d' );

    my $day = _day_dropdown(
        $c,
        %{ $field->{attributes} || {} },
        %local_params,
        day  => $selected->mday,
        id   => $id . '-day',
        name => $name . '-day',
    );

    my $month = _month_dropdown(
        $c,
        %{ $field->{attributes} || {} },
        %local_params,
        month => $selected->mon,
        id    => $id . '-month',
        name  => $name . '-month',
    );

    my $year = _year_dropdown(
        $c,
        startyear => $field->{startyear},
        %{ $field->{attributes} || {} },
        %local_params,
        year => $selected->year,
        id   => $id . '-year',
        name => $name . '-year',
    );

    my $format = $params{format} || $field->{format} || '%Y-%m-%d';
    $format =~ s/-//g;
    $format =~ s/\%Y/$year/g;
    $format =~ s/\%m/$month/g;
    $format =~ s/\%d/$day/g;

    return $format;
}

sub _day_dropdown {
    my ($c, %params) = @_;

    my @days = map{
        my %opts = ( $_ == $params{day} ) ?
            ('selected' => 'selected') :
            ();
        [ $_ => sprintf("%02d", $_) , %opts ]
    }(1 .. 31);

    $c->param( $params{name}, '' );

    my $select = $c->select_field(
        $params{name},
        \@days,
        id => $params{id},
        %{ $params{attrs} || {} },
    );
}

sub _month_dropdown {
    my ($c, %params) = @_;

    my @months = map{
        my %opts = ( $_ == $params{month} ) ?
            ('selected' => 'selected') :
            ();
        [ $_ => sprintf("%02d", $_), %opts ]
    }(1 .. 12);

    $c->param( $params{name}, '' );

    my $select = $c->select_field(
        $params{name},
        \@months,
        id => $params{id},
        %{ $params{attrs} || {} },
    );
}

sub _year_dropdown {
    my ($c, %params) = @_;

    my $now   = localtime;
    my $base  = ( $params{startyear} // $now->year );
    my $start = $base - ( $params{past} // 1 );
    my $stop  = $base + ( $params{future} // 5 );

    $c->param( $params{name}, '' );

    my $has_year;
    my @years = map{
        $has_year++ if $_ == $params{year};
        my %opts = ( $_ == $params{year} ) ?
            ('selected' => 'selected') :
            ();
        [ $_ => $_, %opts ]
    }($start .. $stop);

    if ( !$has_year ) {
        unshift @years, [ $params{year} => $params{year}, { selected => 'selected' } ];
    }

    my $select = $c->select_field(
        $params{name},
        \@years,
        id => $params{id},
        %{ $params{attrs} || {} },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::FormFieldsFromJSON::Date

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('FormFieldsFromJSON::Date');
  $self->plugin('FormFieldsFromJSON' => {
    types => {
      date => 1,
    },
  });

  # Mojolicious::Lite
  plugin 'FormFieldsFromJSON::Date';
  plugin 'FormFieldsFromJSON' => {
    types => {
      date => 1,
    },
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::FormFieldsFromJSON::Date> is an extension for
L<Mojolicious::Plugin::FormFieldsFromJSON> to create date fields.

=head1 NAME

Mojolicious::Plugin::FormFieldsFromJSON::Date - Mojolicious Plugin

=head1 CONFIGURATION

You can configure several things for the date fields:

=over 4

=item * selected

The date selected. Must be in ISO format, e.g.

  2014-12-29

Default: "today"

=item * format

Defines the order of the dropdowns.

  %Y-%m-%d

is the default and this will create the "year"-dropdown first, then
the "month"-dropdown and finally the "day"-dropdown.

=item * future

Defines how many years in the future should be available. (Default: 5)

=item * past

Defines how many years in the past should be available. (Default: 1)

=back

=head1 DATE FIELDS

The date fields is a collection of dropdowns to select a date.

=head2 A simple date field

This is an example for a very simple date field

Configuration:

  [
    {
      "name":"start",
      "future": 2,
      "past": 0,
      "format":"%d-%m-%Y"
    }
  ]

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>,
L<Mojolicious::Plugin::FormFieldsFromJSON>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
