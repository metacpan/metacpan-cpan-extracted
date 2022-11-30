package PICA::Parser::Plain;
use v5.14.1;
use utf8;

our $VERSION = '2.05';

use charnames ':full';
use Carp qw(carp croak);

use parent 'PICA::Parser::Base';

sub END_OF_FIELD {"\N{LINE FEED}"}

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{reader};
    my $plain;

    my $blank = $self->{strict} ? '\s*' : '((SET|Eingabe|Warnung):.*)?\s*';
    do {
        $plain = readline($reader);
    } while (defined $plain && $plain =~ /^$blank$/);

    while (defined(my $line = readline($reader))) {
        last if $line =~ /^$blank$/;
        $plain .= $line;
    }
    return unless defined $plain;

    chomp $plain;
    my @fields = split $self->END_OF_FIELD, $plain;
    my @record;

    for my $field (@fields) {
        my ($annotation, $tag, $occ, $data);

        unless (defined $self->{annotate} && !$self->{annotate}) {
            if ($field =~ s/^([^a-z0-9]) (.+)/\2/) {
                $annotation = $1;
            }
            elsif ($self->{annotate}) {
                croak "ERROR: expected field annotation at field \"$field\"";
            }
        }

        if ($field =~ m/^(\d{3}[A-Z@])(\/(\d{2,3}))?\s(.+)/) {
            $tag  = $1;
            $occ  = $3;
            $data = $4;
        }
        else {
            if ($self->{strict}) {
                croak " ERROR : no valid PICA field structure \"$field\"";
            }
            else {
                carp
                    "WARNING: no valid PICA field structure \"$field\". Skipped field";
                next
            }
        }

        if (!$self->{strict} && $data =~ /^ƒ/) {
            $data =~ s/\$/\$\$/g;
            $data =~ s/ƒ/\$/g;
        }

        my @subfields = split /\$(\$+|.)/, $data;
        shift @subfields;
        push @subfields, '' if @subfields % 2;   # last subfield without value

        if ($data =~ /\$\$/) {
            my @tokens = (shift @subfields, shift @subfields);
            while (@subfields) {
                my $code  = shift @subfields;
                my $value = shift @subfields;
                if ($code =~ /^\$+$/) {
                    my $length = length $code;
                    $code =~ s/\$\$/\$/g;
                    if ($length % 2) {
                        $tokens[-1] .= "$code$value";
                        next;
                    }
                    else {
                        $tokens[-1] .= $code;
                        $code = substr $value, 0, 1;
                        $value = substr $value, 1;
                    }
                }
                push @tokens, $code, $value;
            }
            @subfields = @tokens;
        }

        push @subfields, $annotation if defined $annotation;

        push @record, [$tag, $occ > 0 ? $occ : '', @subfields];
    }
    return \@record;
}

1;
__END__

=encoding UTF-8

=head1 NAME

PICA::Parser::Plain - Plain PICA format parser

=head1 DESCRIPTION

This parser can parse both PICA Plain and annotated PICA. Option C<annotation>
can be used to enforce or forbid annotations.

See L<PICA::Parser::Base> for synopsis and configuration.

In addition to the C<$> this parser also allows C<ƒ> as subfield indicator and it skips lines with WinIBW download messages, unless option C<strict> is enabled.

The counterpart of this module is L<PICA::Writer::Plain>.

=cut
