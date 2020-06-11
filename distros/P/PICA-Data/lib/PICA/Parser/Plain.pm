package PICA::Parser::Plain;
use v5.14.1;

our $VERSION = '1.08';

use charnames ':full';
use Carp qw(carp croak);

use parent 'PICA::Parser::Base';

sub SUBFIELD_INDICATOR {'$'}
sub END_OF_FIELD       {"\N{LINE FEED}"}
sub END_OF_RECORD      {"\N{LINE FEED}"}

sub _next_record {
    my ($self) = @_;

    my $plain = undef;
    while (my $line = $self->{reader}->getline) {
        last if $line =~ /^\s*$/;
        $plain .= $line;
    }
    return unless defined $plain;

    chomp $plain;
    my @fields = split $self->END_OF_FIELD, $plain;
    my @record;

    for my $field (@fields) {

        my ($tag, $occurence, $data);
        if ($field =~ m/^(\d{3}[A-Z@])(\/(\d{2,3}))?\s(.+)/) {
            $tag       = $1;
            $occurence = $3 // '';
            $data      = $4;
        }
        else {
            if ($self->{strict}) {
                croak "ERROR: no valid PICA field structure \"$field\"";
            }
            else {
                carp
                    "WARNING: no valid PICA field structure \"$field\". Skipped field";
                next;
            }
        }

        # data is byte sequence, no character sequence!
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
                        $code  = substr $value, 0, 1;
                        $value = substr $value, 1;
                    }
                }
                push @tokens, $code, $value;
            }
            @subfields = @tokens;
        }

        push @record, [$tag, $occurence, @subfields];
    }
    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::Plain - Plain PICA format parser

=head1 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and configuration.

The counterpart of this module is L<PICA::Writer::Plain>.

=cut
