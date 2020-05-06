package Mojo::Rx;
use 5.008001;
use strict;
use warnings;

use Carp 'croak';
use File::Basename 'dirname';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    rx_observable rx_timer rx_interval rx_of rx_race rx_concat rx_merge rx_subject
    rx_from_event rx_from_event_array rx_defer rx_EMPTY $rx_EMPTY rx_throw_error rx_never

    op_map op_map_to op_filter op_take op_tap op_multicast op_ref_count op_share
    op_take_until op_delay op_scan op_pairwise
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v0.12.0";

sub import {
    my ($class, @keywords) = @_;

    my $dirname = dirname(__FILE__);
    my @missing;
    foreach my $keyword (@keywords) {
        if ($keyword eq '$rx_EMPTY') {
            require "$dirname/Rx/internal/observable/EMPTY.pl";
        } elsif ($keyword eq ':all') {
            require $_ foreach (
                glob("$dirname/Rx/internal/observable/*"),
                glob("$dirname/Rx/internal/operators/*"),
            );
        } elsif (grep $keyword eq $_, @EXPORT_OK) {
            my $keyword = $keyword;
            my $subdir =
                $keyword =~ s/^op_// ? 'operators' :
                    $keyword =~ s/^rx_// ? 'observable' :
                        die "malformed import symbol: $keyword";
            require "$dirname/Rx/internal/$subdir/$keyword.pl";
        } else {
            push @missing, $keyword;
        }
    }

    if (@missing) {
        for (my $i = 0; $i < @missing; $i++) {
            print " " if $i > 0;
            print qq{"$missing[$i]" is not exported by the $class module\n};
        }
        croak "Can't continue after import errors";
    }

    Mojo::Rx->export_to_level(1, @_);
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Rx - It's new $module

=head1 SYNOPSIS

    use Mojo::Rx;

=head1 DESCRIPTION

Mojo::Rx is ...

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut

