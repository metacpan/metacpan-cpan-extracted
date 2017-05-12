package PICA::Path;
use strict;
use warnings;

our $VERSION = '0.31';

use Carp qw(confess);
use Scalar::Util qw(reftype);

use overload '""' => \&stringify;

sub new {
    my ($class, $path) = @_;

    confess "invalid pica path" if $path !~ /
        ([012*.][0-9*.][0-9*.][A-Z@*.]) # tag
        (\[([0-9*.]{2})\])?             # occurence
        (\$?([_A-Za-z0-9]+))?           # subfields
        (\/(\d+)?(-(\d+)?)?)?           # position
    /x;

    my $field      = $1;
    my $occurrence = $3;
    my $subfield   = defined $5 ? "[$5]" : "[_A-Za-z0-9]";

    my @position;
    if (defined $6) { # from, to
        my ($from, $dash, $to, $length) = ($7, $8, $9, 0);

        if ($dash) {
            confess "invalid pica path" unless defined($from // $to); # /-
        }

        if (defined $to) {
            if (!$from and $dash) { # /-X
                $from = 0;
            }
            $length = $to - $from + 1;
        } else {
            if ($8) {
                $length = undef;
            } else {
                $length = 1;
            }
        }

        if (!defined $length or $length >= 1) {
            unless (!$from and !defined $length) { # /0-
                @position = ($from, $length);
            }
        }
    }

    $field =~ s/\*/./g;
    $field = qr{$field};
    
    if (defined $occurrence) {
        $occurrence =~ s/\*/./g;
        $occurrence = qr{$occurrence};
    }

    $subfield = qr{$subfield};

    bless [ $field, $occurrence, $subfield, @position ], $class;
}

sub match_field {
    my ($self, $field) = @_;

    if ( $field->[0] =~ $self->[0] && 
        (!$self->[1] || (defined $field->[1] && $field->[1] =~ $self->[1])) ) {
        return $field;
    }

    return
}

sub match_subfields {
    my ($self, $field) = @_;

    my $subfield_regex = $self->[2];
    my $from           = $self->[3];
    my $length         = $self->[4];

    my @values;

    for (my $i = 2; $i < @$field; $i += 2) {
        if ($field->[$i] =~ $subfield_regex) {
            my $value = $field->[$i + 1];
            if (defined $from) {
                $value = $length ? substr($value, $from, $length) :
                                   substr($value, $from);
                next if '' eq ($value // '');
            }
            push @values, $value;
        }
    }

    return @values;
}

sub record_fields {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    return [ grep { $self->match_field($_) } @$record ];
}

sub record_subfields {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';

    my @values;

    foreach my $field (grep { $self->match_field($_) } @$record) {
        push @values, $self->match_subfields($field);
    }

    return @values;
}

sub stringify {
    my ($self, $short) = @_;

    my ($field, $occurrence, $subfields) = map {
        defined $_ ? do {
            s/^\(\?[^:]*:(.*)\)$/$1/;
            s/\./*/g;
            $_ } : undef
        } ($self->[0], $self->[1], $self->[2]); 

    my $str = $field;

    if (defined $occurrence) {
        $str .= "[$occurrence]";
    }

    if (defined $subfields and $subfields ne '[_A-Za-z0-9]') {
        $subfields =~ s/\[|\]//g;
        unless( $short and $subfields !~  /^\$/ ) {
            $str .= '$';
        }
        $str .= $subfields;
    }

    my ($from, $length, $pos) = ($self->[3], $self->[4]);
    if (defined $from) {
        if ($from) {
            $pos = $from;
        }         
        if (!defined $length) {
            if ($from) {
                $pos = "$from-";
            }
        } elsif ($length > 1) {
            $pos .= '-' . ($from + $length - 1);
        } elsif ($length == 1 && !$from) {
            $pos = 0;
        }
    }

    $str .= "/$pos" if defined $pos;

    $str;
}

1;
__END__

=head1 NAME

PICA::Path - PICA path expression to match field and subfield values

=head1 SYNOPSIS

    use PICA::Path;
    use PICA::Parser::Plain;

    # extract URLs from PIC Records, given from STDIN
    my $urlpath = PICA::Path->new('009P$a');
    my $parser = PICA::Parser::Plain->new(\*STDIN);
    while ( my $record = $parser->next ) {
        print "$_\n" for $urlpath->record_subfields($record);
    }

=head1 DESCRIPTION

PICA path expressions can be used to match fields and subfields of
L<PICA::Data> records or equivalent record structures. An instance of
PICA::Path is a blessed array reference, consisting of the following fields:

=over

=item

regular expression to match field tags against

=item

regular expression to match occurrences against, or undefined

=item

regular expression to match subfields against

=item

substring start position

=item

substring end position

=back

=head1 METHODS

=head2 new( $expression )

Create a PICA path by parsing the path expression. The expression consists of

=over

=item

A tag, constisting of three digits, the first C<0> to C<2>, followed by a digit
or C<@>.  The character C<*> can be used as wildcard.

=item

An optional occurrence, given by two digits (or C<*> as wildcard) in brackets,
e.g. C<[12]> or C<[0*]>.

=item

An optional list of subfields. Allowed subfield codes include C<_A-Za-z0-9>.

=item

An optional position, preceeded by C</>. Both single characters (e.g. C</0> for
the first), and character ranges (such as C<2-4>, C<-3>, C<2->...) are
supported.

=back

=head2 match_field( $field )

Check whether a given PICA field matches the field and occurrence of this path.
Returns the C<$field> on success.

=head2 filter_record_fields( $record )

Returns an array reference with fields of a L<PICA::Data> that match the path.
Subfield codes are ignore.

=head2 match_subfields( $field )

Returns a list of matching subfields (optionally trimmed by from and length)
without inspection field and occurrence values.

=head2 stringify( [ $short ] )

Stringifies the PICA path to normalized form. Subfields are separated with
C<$>, unless called as C<stringify(1)> or the first subfield is C<$>.

=head1 SEE ALSO

L<Catmandu::Fix::pica_map>

=cut
