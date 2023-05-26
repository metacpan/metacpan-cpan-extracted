package App::TenableSC::API;

use strict;
use warnings;

use JSON;
use Pod::Usage;

use parent 'App::TenableSC';

use App::TenableSC::Utils qw(:all);

our $VERSION = '0.311';

@App::TenableSC::command_options = (
    'output|format|f=s',

    'json',
    'table',
    'csv',
    'tsv',
    'yaml',
    'dumper',

    'verbose'
);

sub startup {

    my ($self) = @_;

    my @output_formats = qw/json table csv tsv yaml dumper/;

    if ( $self->options->{'format'} ) {
        if ( !grep { $self->options->{'format'} eq $_ } @output_formats ) {
            print "ERROR: Unknown output format\n\n";
            pod2usage( -exitstatus => 0, -verbose => 0 );
        }
    }

    $self->options->{'format'} ||= 'json';

    foreach (@output_formats) {
        $self->options->{'format'} = $_ if ( $self->options->{$_} );
    }

    my $params  = {};
    my $results = undef;
    my $api     = $ARGV[0] || undef;
    my $method  = $ARGV[1] || undef;

    $api    =~ s/-/_/g if ($api);
    $method =~ s/-/_/g if ($method);

    pod2usage( -verbose => 0 ) if ( !$api || !$method );

    foreach my $arg (@ARGV) {

        if ( $arg =~ m{^([^=]+)=(.*)$} ) {

            my ( $key, $value ) = ( $1, $2 );
            $key =~ s{-}{_}g;
            $params->{$key} = $value;

        }

    }

    my $sc = $self->connect;

    $results = $sc->$api->$method( %{$params} ) or cli_error( $sc->error );

    if ( ref $results eq 'ARRAY' || ref $results eq 'HASH' ) {

        if ( $self->options->{'format'} eq 'json' ) {

            # Convert bessed Time::Piece and Time::Seconds object for JSON encoding
            require Time::Piece;

            sub Time::Piece::TO_JSON {
                my ($time) = @_;
                return $time->datetime;    # convert all date to ISO 8601 format
            }

            sub Time::Seconds::TO_JSON {
                my ($time) = @_;
                return $time->seconds;
            }

            print JSON->new->pretty(1)->convert_blessed(1)->encode($results);
            exit;

        }

        if ( $self->options->{'format'} eq 'dumper' ) {
            print dumper($results);
            exit;
        }

        if ( $self->options->{'format'} eq 'yaml' ) {

            if ( eval { require YAML::XS } ) {
                print YAML::XS::Dump($results);
                exit;
            }
            if ( eval { require YAML } ) {
                print YAML::Dump($results);
                exit;
            }

            print "ERROR: YAML or YAML::XS module are missing\n";
            exit(255);
        }

        if (   $self->options->{'format'} eq 'tsv'
            || $self->options->{'format'} eq 'csv'
            || $self->options->{'format'} eq 'table' )
        {

            my @rows   = ();
            my @fields = ();

            if ( ref $results ne 'ARRAY' ) {
                $results = [$results];
            }

            foreach my $row ( @{$results} ) {

                if ( !@fields ) {
                    @fields = sort keys %{$row};
                }

                my @row = ();

                foreach (@fields) {

                    if ( ref $row->{$_} eq 'HASH' ) {
                        push @row, encode_json( $row->{$_} );
                    } else {
                        my $value = $row->{$_};

                        if ( $self->options->{'format'} ne 'table' ) {
                            $value = sprintf '"%s"', $value if ( $value =~ /\n/ || $value =~ /\,/ );
                            $value =~ s/\n/\r\n/g;
                        }
                        push @row, $value;
                    }

                }

                push @rows, \@row;
            }

            if (@rows) {

                print $self->table(
                    rows             => \@rows,
                    headers          => \@fields,
                    format           => $self->options->{'format'},
                    column_separator => ' | ',
                    header_separator => '-',
                );

            }

            exit;

        }

    }

    print "$results\n";
    exit;

}

sub table {

    my ( $self, %args ) = @_;

    my $col_separator    = $args{'column_separator'} || '  ';
    my $header_separator = $args{'header_separator'} || undef;
    my $rows             = $args{'rows'}             || ();
    my $headers          = $args{'headers'}          || ();
    my $output_format    = $args{'format'}           || 'table';
    my $widths           = ();

    my @checks = @{$rows};

    push( @checks, $headers ) if ($headers);

    if ( $output_format eq 'table' ) {

        for my $row (@checks) {

            for my $idx ( 0 .. @{$row} ) {

                if ( defined( $args{'widths'}->[$idx] ) && $args{'widths'}->[$idx] > 0 ) {
                    $widths->[$idx] = $args{'widths'}->[$idx];
                    next;
                }

                my $col = $row->[$idx];
                $widths->[$idx] = length($col) if ( $col && length($col) > ( $widths->[$idx] || 0 ) );

            }
        }

    } else {

        for my $i ( 0 .. @{ $rows->[0] } - 1 ) {
            $widths->[$i] = 0;
        }

        $header_separator = undef;

        $col_separator = ','  if ( $output_format eq 'csv' );
        $col_separator = "\t" if ( $output_format eq 'tsv' );

    }

    my $format = join( $col_separator, map {"%-${_}s"} @{$widths} ) . "\n";
    my $table  = '';

    if ($headers) {

        my $header_row   = sprintf( $format, @{$headers} );
        my $header_width = length($header_row);

        $table .= $header_row;

        if ($header_separator) {
            $table .= sprintf( "%s\n", $header_separator x $header_width );
        }

    }

    for my $row ( @{$rows} ) {
        $table .= sprintf( $format, map { $_ || '' } @{$row} );
    }

    return $table;

}

1;

=pod

=encoding UTF-8


=head1 NAME

App::TenableSC::API - API application for App::TenableSC


=head1 SYNOPSIS

    use App::TenableSC::API;

    App::TenableSC::API->run;


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 METHODS


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
