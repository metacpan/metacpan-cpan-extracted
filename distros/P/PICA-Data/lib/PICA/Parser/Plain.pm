package PICA::Parser::Plain;
use v5.14.1;
use utf8;

our $VERSION = '2.12';

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
        $field = $self->parse_field($field);
        push @record, $field if $field;
    }

    return \@record;
}

sub parse_field {
    my ($self, $field) = @_;

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

    if (!$self->{strict} && $data =~ /^ƒ/) {
        $data =~ s/\$/\$\$/g;
        $data =~ s/ƒ/\$/g;
    }

    if ($data !~ /^(\$[^\$]([^\$]|\$\$)*)+$/) {
        if ($self->{strict}) {
            croak "ERROR: invalid PICA field structure \"$field\"";
        }
        else {
            carp
                "WARNING: invalid PICA field structure \"$field\". Skipped field";
            return;
        }
    }

    my @subfields;
    while ($data =~ m/\G\$([^\$])(([^\$]|\$\$)*)/g) {
        my ($code, $value) = ($1, $2);
        $value =~ s/\$\$/\$/g;
        push @subfields, $code, $value;
    }

    push @subfields, $annotation if defined $annotation;

    return [$tag, $occ > 0 ? $occ : '', @subfields];
}

1;
__END__

=encoding UTF-8

=head1 NAME

PICA::Parser::Plain - Plain PICA format parser

=head1 DESCRIPTION

This parser can parse both PICA Plain and annotated PICA. See L<PICA::Parser::Base> for synopsis and configuration.

In addition to the C<$> this parser also allows C<ƒ> as subfield indicator and it skips lines with WinIBW download messages, unless option C<strict> is enabled.

The counterpart of this module is L<PICA::Writer::Plain>.

This parser can parse PICA Patch format but L<PICA::Parser::Patch> should be used instead to ensure every field is annotated with C<+>, C<-> or space.

=cut
