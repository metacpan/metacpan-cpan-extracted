package Net::SecurityCenter::Utils;

use warnings;
use strict;

use Carp;
use Params::Check qw(allow);
use Time::Piece;
use Data::Dumper ();
use Exporter qw(import);

our $VERSION = '0.206';

our @EXPORT_OK = qw(
    sc_check_params
    sc_decode_scanner_status
    sc_filter_array_to_string
    sc_filter_int_to_bool
    sc_filter_datetime_to_epoch
    sc_merge
    sc_normalize_hash
    sc_normalize_array
    sc_method_usage
    sc_schedule

    decamelize
    dumper
    trim
    deprecated
    cpe_decode
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $NESSUS_SCANNER_STATUS = {

    1      => 'Working',
    2      => 'Connection Error',
    4      => 'Connection Timeout',
    8      => 'Certificate mismatch',
    16     => 'Protocol Error',
    32     => 'Authentication Error',
    64     => 'Invalid Configuration',
    128    => 'Reloading Scanner',
    256    => 'Plugins out-of-sync',
    512    => 'PVS results ready',
    1024   => 'Updating plugins',
    2048   => 'LCE main daemon down',
    4096   => 'LCE query daemon down',
    8192   => 'Updating Status',
    16384  => 'Scanner disabled by user',
    32768  => 'Scanner requires an upgrade',
    65536  => 'LCE version too low',
    131072 => 'License Invalid',
    262144 => 'Not used',
    524288 => 'Resource Unavailable',

};

#-------------------------------------------------------------------------------
# COMMON UTILS
#-------------------------------------------------------------------------------

sub decamelize {
    return join( '_', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/, shift );
}

#-------------------------------------------------------------------------------

sub dumper {
    return Data::Dumper->new( [@_] )->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump;
}

#-------------------------------------------------------------------------------

sub trim {

    my ($string) = @_;

    return if ( !$string );

    $string =~ s/^\s+|\s+$//g;
    return $string;

}

#-------------------------------------------------------------------------------

sub deprecated {
    local $Carp::CarpLevel = 1;
    carp @_;
}

#-------------------------------------------------------------------------------

sub cpe_decode {

    my ($cpe) = @_;

    $cpe =~ s/cpe:\///;

    my (
        $part,     $vendor,     $product,   $version,   $update, $edition,
        $language, $sw_edition, $target_sw, $target_hw, $other
    );

    ( $part, $vendor, $product, $version, $update, $edition, $language ) = split( /:/, $cpe );

    ( $sw_edition, $target_sw, $target_hw, $other ) = split( /~/, $language ) if ($language);

    return {
        'part'       => $part,
        'vendor'     => $vendor,
        'product'    => $product,
        'version'    => $version,
        'update'     => $update,
        'edition'    => $edition,
        'language'   => $language,
        'sw_edition' => $sw_edition,
        'target_sw'  => $target_sw,
        'target_hw'  => $target_hw,
        'other'      => $other
    };

}

#-------------------------------------------------------------------------------
# COMMON CLASS UTILS
#-------------------------------------------------------------------------------

sub sc_schedule {

    my (%args) = @_;

    my $tmpl = {
        type => {
            allow    => [ 'dependent', 'ical', 'never', 'rollover', 'template', 'now' ],
            default  => 'never',
            required => 1,
        },
        start       => {},
        repeat_rule => {
            remap => 'repeatRule',
        },
    };

    my $params = sc_check_params( $tmpl, \%args );

    if ( $params->{'type'} eq 'now' ) {

        return {
            'repeatRule' => 'FREQ=NOW;INTERVAL=1',
            'type'       => 'now'
        };

    }

    if ( $params->{'type'} eq 'ical' ) {

        return {
            'type'       => 'ical',
            'start'      => $params->{'start'},
            'repeatRule' => $params->{'repeatRule'},
        };

    }

    return $params;

}

#-------------------------------------------------------------------------------

sub sc_method_usage {

    my ($template) = @_;

    my $usage_class = ( caller(2) )[3] || q{};
    $usage_class =~ s/(::)(\w+)$/->$2/;

    my $usage_args = q{};

    my @usage_req_args;
    my @usage_opt_args;

    foreach my $key ( sort keys %{$template} ) {

        ( exists $template->{$key}->{'required'} )
            ? push @usage_req_args, "$key => ..."
            : push @usage_opt_args, "$key => ...";

    }

    $usage_args .= join ' , ', @usage_req_args;

    if (@usage_req_args) {
        $usage_args .= ' , ';
    }

    $usage_args .= '[ ' . ( join ' , ', @usage_opt_args ) . ' ]';

    return "Usage: $usage_class( $usage_args )";

}

#-------------------------------------------------------------------------------

sub sc_check_params {

    my ( $template, $params ) = @_;

    my $args   = {};
    my $output = {};

    foreach my $key ( keys %{$params} ) {
        my $lc_key = lc $key;
        $args->{$lc_key} = $params->{$key};
    }

    foreach my $key ( keys %{$template} ) {

        my $tmpl = $template->{$key};

        if ( exists $tmpl->{'required'} and not exists $args->{$key} ) {

            my $error_message = "Required '$key' param is not provided";

            if ( defined $tmpl->{'messages'}->{'required'} ) {
                $error_message = $tmpl->{'messages'}->{'required'};
            }

            carp $error_message;
            croak sc_method_usage($template);

        }

        if ( exists $tmpl->{'default'} ) {
            $output->{$key} = $tmpl->{'default'};
        }

    }

    foreach my $key ( keys %{$args} ) {

        next if ( !exists $template->{$key} );

        my $value = $args->{$key};
        my $tmpl  = $template->{$key};

        # Execute pre-validation filter
        if ( exists $tmpl->{'filter'} and ref $tmpl->{'filter'} eq 'CODE' ) {
            $value = $tmpl->{'filter'}->($value);
        }

        if ( exists $tmpl->{'allow'} ) {

            if ( ref $value eq 'ARRAY' ) {

                foreach ( @{$value} ) {

                    if ( !allow( $_, $tmpl->{'allow'} ) ) {
                        carp "Invalid '$key' ($_) value (allowed values: " . join( ', ', @{ $tmpl->{'allow'} } ) . ')';
                        croak sc_method_usage($template);
                    }

                }

            } else {

                if ( !allow( $value, $tmpl->{'allow'} ) ) {

                    my $error_message = q{};

                    if ( ref $tmpl->{'allow'} eq 'ARRAY' ) {
                        $error_message
                            = "Invalid '$key' ($value) value (allowed values: "
                            . join( ', ', @{ $tmpl->{'allow'} } ) . ')';
                    }

                    if ( ref $tmpl->{'allow'} eq 'Regexp' ) {
                        $error_message = "Invalid param '$key' ($value) value";
                    }

                    if ( exists $tmpl->{'messages'}->{'allow'} ) {
                        $error_message = $tmpl->{'messages'}->{'allow'};
                    }

                    carp $error_message;
                    croak sc_method_usage($template);

                }
            }
        }

        # Execute post validation filter
        if ( exists $tmpl->{'post_filter'} and ref $tmpl->{'post_filter'} eq 'CODE' ) {
            $value = $tmpl->{'post_filter'}->($value);
        }

        if ( $key eq 'fields' ) {

            if ( ref $value eq 'ARRAY' ) {
                $value = join( ',', @{$value} );
            }

        }

        $output->{$key} = $value;

        if ( exists $tmpl->{'remap'} ) {
            $output->{ $tmpl->{'remap'} } = $output->{$key};
            delete $output->{$key};
        }

    }

    return $output;

}

#-------------------------------------------------------------------------------

sub sc_decode_scanner_status {

    my ($scanner_status) = @_;

    foreach ( sort { $b <=> $a } keys %{$NESSUS_SCANNER_STATUS} ) {

        if ( $scanner_status >= $_ ) {
            return $NESSUS_SCANNER_STATUS->{$_};
        }

    }

    return;

}

#-------------------------------------------------------------------------------

sub sc_normalize_hash {

    my ($data) = @_;

    my @time_fields = qw(
        createdTime
        finishTime
        importFinish
        importStart
        lastSyncTime
        lastTrendUpdate
        lastVulnUpdate
        modifiedTime
        startTime
        updateTime
        diagnosticsGenerated
        statusLastChecked
        lastScan
        lastUnauthRun
        lastAuthRun
    );

    my @seconds_fields = qw(
        scanDuration
        uptime
    );

    foreach my $item ( keys %{$data} ) {
        if ( ref $data->{$item} eq 'HASH' ) {
            $data->{$item} = sc_normalize_hash( $data->{$item} );
        }
        if ( $item =~ m/(Update|Date|Time)$/ && $data->{$item} =~ /\d+/ && ref $data->{$item} ne 'Time::Piece' ) {
            $data->{$item} = Time::Piece->new( $data->{$item} );
        }
    }

    foreach my $field (@time_fields) {
        if ( exists( $data->{$field} ) && ref $data->{$field} ne 'Time::Piece' ) {
            $data->{$field} = Time::Piece->new( $data->{$field} );
        }
    }

    foreach my $field (@seconds_fields) {
        if ( exists( $data->{$field} ) && ref $data->{$field} ne 'Time::Seconds' ) {
            $data->{$field} = Time::Seconds->new( $data->{$field} );
        }
    }

    return $data;

}

#-------------------------------------------------------------------------------

sub sc_normalize_array {

    my ($data) = @_;

    my $results = [];

    foreach my $item ( @{$data} ) {
        push( @{$results}, sc_normalize_hash($item) );
    }

    return $results;

}

#-------------------------------------------------------------------------------

sub sc_merge {

    my ($data) = @_;
    my %hash = ();

    foreach my $type ( ( 'usable', 'manageable' ) ) {

        next unless ( exists( $data->{$type} ) );

        foreach my $item ( @{ $data->{$type} } ) {

            $item = sc_normalize_hash($item);
            $item->{$type} = 1;

            if ( exists( $hash{ $item->{'id'} } ) ) {
                $hash{ $item->{'id'} }->{$type} = 1;
            } else {
                $hash{ $item->{'id'} } = $item;
            }
        }
    }

    my @results = values %hash;
    return \@results;

}

#-------------------------------------------------------------------------------
# FILTERS
#-------------------------------------------------------------------------------

sub sc_filter_array_to_string {

    my ($data) = @_;

    if ( ref $data eq 'ARRAY' ) {
        return join( ',', @{$data} );
    }

    return $data;

}

sub sc_filter_int_to_bool {
    return ( $_[0] == 1 ) ? \1 : \0;
}

sub sc_filter_datetime_to_epoch {

    my ($date) = @_;

    if ( ref $date eq 'Time::Piece' ) {
        return $date->epoch;
    }

    if ( $date =~ /^\d{4}-\d{2}-\d{2}$/ ) {
        my $t = Time::Piece->strptime( $date, '%Y-%m-%d' );
        return $t->epoch;
    }

    if ( $date =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
        my $t = Time::Piece->strptime( $date, '%Y-%m-%d %H:%M:%S' );
        return $t->epoch;
    }

    if ( $date =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/ ) {
        my $t = Time::Piece->strptime( $date, '%Y-%m-%dT%H:%M:%S' );
        return $t->epoch;
    }

    return $date;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::Utils - Utils package for Net::Security::Center


=head1 SYNOPSIS

    use Net::SecurityCenter::Utils;


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

This software is copyright (c) 2018-2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
