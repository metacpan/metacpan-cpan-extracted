package OPM::Maker::Utils;
$OPM::Maker::Utils::VERSION = '1.10';
# ABSTRACT: Utility functions for OPM::Maker

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(reformat_size);

sub reformat_size {
    my ($size) = @_;

    $size =~ m{\A(?<count>[0-9]+)(?<unit>[MmGgKk])?\z};

    return 0 if !$+{count};

    my $unit = lc( $+{unit} // 'b' );

    my $factor =
        $unit eq 'k' ? 1024 :
            $unit eq 'm' ? 1024 * 1024 :
                $unit eq 'g' ? 1024 * 1024 * 1024:
                1;
    ;

    return $+{count} * $factor;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Utils - Utility functions for OPM::Maker

=head1 VERSION

version 1.10

=head1 FUNCTIONS

=head2 reformat_size

reformat size

  15000 -> 15000
  15k   -> 15360        ( 15 * 1024 )
  15m   -> 15728640     ( 15 * 1024 * 1024 )
  15g   -> 16106127360  ( 15 * 1024 * 1024 * 1024)

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
