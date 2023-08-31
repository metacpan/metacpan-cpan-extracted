package PICA::Parser::Import;
use v5.14.1;
use utf8;

our $VERSION = '2.12';

use charnames ':full';
use Carp qw(carp croak);

use parent 'PICA::Parser::Base';

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{reader};
    my $line;

    # All data before the first record separator is ignored
    if (!$self->count) {
        do {
            $line = readline($reader);
            return unless defined $line;
        } while ($line =~ /^\x1D$/);
    }

    my @record;
    while (1) {
        $line = readline($reader);
        if (!defined $line) {
            @record ? last : return;
        }

        next if $line =~ /^#|^\s*$/;    # ignore empty or comment lines
        last if $line =~ /^\x1D$/;
        chomp $line;

        if ($line
            =~ m/^\x1E([012][0-9][0-9][A-Z@])(\/(\d{2,3}))?\s((\x1F[^\x1F]+)+)$/
            )
        {
            my $tag = $1;
            my $occ = $3 > 0 ? $3 : '';
            my @sf  = split /\x1F/, $4;
            shift @sf;
            push @record, [$tag, $occ, map {split //, $_, 2} @sf];
        }
        elsif ($self->{strict}) {
            croak "ERROR: invalid PICA field structure \"$line\"";
        }
        else {
            carp
                "WARNING: invalid PICA field structure \"$line\". Skipped field";
            next;
        }

    }

    return \@record;
}

1;
__END__

=encoding UTF-8

=head1 NAME

PICA::Parser::Import - PICA Import format parser

=head1 DESCRIPTION

Parses PICA+ records in PICA Import format (also known as "normalized title
format", see L<https://format.gbv.de/pica/import>).

Fields or subfields spread over several lines are not supported!

See L<PICA::Parser::Base> for synopsis and configuration.

The counterpart of this module is L<PICA::Writer::Import>.

=cut
