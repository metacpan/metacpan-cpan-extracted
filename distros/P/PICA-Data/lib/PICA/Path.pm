package PICA::Path;
use v5.14.1;
use utf8;

our $VERSION = '1.24';

use Carp qw(confess);
use Scalar::Util qw(reftype);

use overload '""' => \&stringify;

sub new {
    my ($class, $path) = @_;

    confess "invalid pica path" if $path !~ /
        ([012.][0-9.][0-9.][A-Z@.]) # tag
        (\[([0-9.]{2,3})\])?        # occurrence
        (\$?([_A-Za-z0-9]+))?       # subfields
        (\/(\d+)?(-(\d+)?)?)?       # position
    /x;

    my $field      = $1;
    my $occurrence = $3 !~ /^0+$/ ? $3 : undef;
    my $subfield   = defined $5 ? "[$5]" : "[_A-Za-z0-9]";

    my @position;
    if (defined $6) {    # from, to
        my ($from, $dash, $to, $length) = ($7, $8, $9, 0);

        if ($dash) {
            confess "invalid pica path" unless defined($from // $to);    # /-
        }

        if (defined $to) {
            if (!$from and $dash) {                                      # /-X
                $from = 0;
            }
            $length = $to - $from + 1;
        }
        else {
            if ($8) {
                $length = undef;
            }
            else {
                $length = 1;
            }
        }

        if (!defined $length or $length >= 1) {
            unless (!$from and !defined $length) {    # /0-
                @position = ($from, $length);
            }
        }
    }

    $field = qr{$field};

    if (defined $occurrence) {
        $occurrence = qr{$occurrence};
    }

    $subfield = qr{$subfield};

    bless [$field, $occurrence, $subfield, @position], $class;
}

sub match_record {
    my ($self, $record, %args) = @_;

    # my $subfield_regex = $self->[2];

    my %default_args = (
        force_array   => 0,
        join          => '',
        nested_arrays => 0,
        pluck         => 0,
        split         => 0,
        value         => undef,
    );
    %args = (%default_args, %args);
    if ($args{nested_arrays}) {
        $args{split} = 1;
    }

    # check if path exists
    if ($args{value}) {
        my $value = $self->record_subfields($record);
        return $value ? $args{value} : undef;
    }

    # gather values from matched subfields
    my @matches;
    for my $field (@{$self->record_fields($record)}) {
        next unless defined $field;
        my @matched_subfields
            = $args{pluck}
            ? $self->match_subfields($field, pluck => 1)
            : $self->match_subfields($field);
        next unless defined $matched_subfields[0];
        if ($args{split}) {
            if ($args{nested_arrays}) {
                push @matches, \@matched_subfields;
            }
            else {
                push @matches, @matched_subfields;
            }
        }
        else {
            push @matches, join($args{join}, @matched_subfields);
        }

    }
    if (@matches) {

        # return matched fields as array reference
        if ($args{split}) {
            return $args{force_array} ? [\@matches] : \@matches;
        }

        # ... or string
        else {
            return $args{force_array}
                ? \@matches
                : join($args{join}, @matches);
        }
    }
    return;

}

sub match_field {
    my ($self, $field) = @_;

    if ($field->[0] =~ $self->[0]
        && (!$self->[1] || ($field->[1] > 0 && $field->[1] =~ $self->[1])))
    {
        return $field;
    }

    return;
}

sub match_subfields {
    my ($self, $field, %args) = @_;

    my $subfield_regex = $self->[2];
    my $from           = $self->[3];
    my $length         = $self->[4];

    my @values;

    if ($args{pluck}) {

        # Treat the subfields as a hash index
        my $subfield_href = {};
        for (my $i = 2; $i < @{$field}; $i += 2) {
            push @{$subfield_href->{$field->[$i]}}, $field->[$i + 1];
        }

        my $subfields = $self->[2];
        $subfields =~ s{.*\[(.+)\].*}{\1}g;
        for my $subfield (split('', $subfields)) {
            my $value = $subfield_href->{$subfield} // [undef];
            if (defined $from) {
                push @values, map {
                    $length
                        ? substr($_, $from, $length)
                        : substr($_, $from)
                } @{$value};
            }
            else {
                push @values, @{$value};
            }

        }
    }
    else {
        for (my $i = 2; $i < @$field; $i += 2) {
            if ($field->[$i] =~ $subfield_regex) {
                my $value = $field->[$i + 1];
                if (defined $from) {
                    $value
                        = $length
                        ? substr($value, $from, $length)
                        : substr($value, $from);
                    next if '' eq ($value // '');
                }
                push @values, $value;
            }
        }
    }

    return @values;
}

sub record_fields {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    return [grep {$self->match_field($_)} @$record];
}

sub record_subfields {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';

    my @values;

    foreach my $field (grep {$self->match_field($_)} @$record) {
        push @values, $self->match_subfields($field);
    }

    return @values;
}

sub unescape {
    my $exp = shift;
    $exp =~ s/^\(\?[^:]*:(.*)\)$/$1/ if defined $exp;
    return $exp;
}

sub stringify {
    my ($self, $short) = @_;

    my $str = $self->fields;

    my $occurrence = $self->occurrences;
    $str .= "[$occurrence]" if defined $occurrence;

    my $subfields = $self->subfields;
    if (defined $subfields) {
        unless ($short and $subfields !~ /^\$/) {
            $str .= '$';
        }
        $str .= $subfields;
    }

    my $pos = $self->positions;
    $str .= "/$pos" if defined $pos;

    $str;
}

sub fields {
    return unescape($_[0]->[0]);
}

sub occurrences {
    return unescape($_[0]->[1]);
}

sub subfields {
    my $subfields = unescape($_[0]->[2]);
    if (defined $subfields and $subfields ne '[_A-Za-z0-9]') {
        $subfields =~ s/\[|\]//g;
        return $subfields;
    }
    return;
}

sub positions {
    my ($self) = @_;

    my ($from, $length, $pos) = ($self->[3], $self->[4]);
    if (defined $from) {
        if ($from) {
            $pos = $from;
        }
        if (!defined $length) {
            if ($from) {
                $pos = "$from-";
            }
        }
        elsif ($length > 1) {
            $pos .= '-' . ($from + $length - 1);
        }
        elsif ($length == 1 && !$from) {
            $pos = 0;
        }
    }

    return $pos;
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

=head2 Matching rules

Example record:

    ...
    use PICA::Path;
    
    # PICA::Data record
    my $record = {
        record => [
            [ '005A', '', '0', '1234-5678' ],
            [ '005A', '', '0', '1011-1213' ],
            [ '009Q', '', 'u', 'http://example.org/', 'x', 'A', 'z', 'B', 'z', 'C' ],
            [ '021A', '', 'a', 'Title', 'd', 'Supplement' ],
            [ '031N', '', 'j', '1600', 'k', '1700', 'j', '1800', 'k', '1900', 'j', '2000' ],
            [ '045F', '01', 'a', '001' ],
            [ '045F', '02', 'a', '002' ],
            [ '045U', '', 'e', '003', 'e', '004' ],
            [ '045U', '', 'e', '005' ]
        ],
        _id => 1234
    };
    
    # create path
    my $path = PICA::Path->new('021A$ab');
    
    # match record
    my $match = $path->match_record($record);
    # $match = 'TitleSupplement'

=head3 Match single field with no subfield repetition

Field C<021A> has only unique subfield codes.
  
    # get all subfields
    $path = PICA::Path->new('021A');
    $match = $path->match($record);
    # $match = 'TitleSupplement'
    
    # get single subfield by code
    $path = PICA::Path->new('021A$a');
    $match = $path->match($record);
    # $match = 'Title'
    
    # get two subfields by code
    $path = PICA::Path->new('021A$ad');
    $match = $path->match($record);
    # $match = 'TitleSupplement');
    
    $path = PICA::Path->new('021A$da');
    $match = $path->match($record);
    # $match = 'TitleSupplement'
    
    # get two subfields by code in specific order
    $path = PICA::Path->new('021A$da');
    $match = $path->match($record, pluck => 1);
    # $match = 'SupplementTitle'
    
    # join subfields
    $path = PICA::Path->new('021A$da');
    $match = $path->match($record, pluck => 1, join => ' ');
    # $match = 'Supplement Title'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('021A$da');
    $match = $path->match($record, split => 1);
    # $match = ['Title', 'Supplement']

Option C<nested_arrays> creates a list for every field found:

    # split fields to lists
    $path = PICA::Path->new('021A$da');
    $match = $path->match($record, split => 1, nested_arrays => 1);
    # $match = [['Title', 'Supplement']]

=head3 Match single field with subfield repetition

Field C<009Q> has repeated subfields.
    
    # get all subfields
    $path = PICA::Path->new('009Q');
    $match = $path->match($record);
    # $match = 'http://example.orgABC'
    
    # get repeated subfields
    $path = PICA::Path->new('009Q$z');
    $match = $path->match($record);
    # $match = 'BC'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('009Q');
    $match = $path->match($record, split => 1);
    # $match = ['http://example.org', 'A', 'B', 'C']
    
    # split subfields to list
    $path = PICA::Path->new('009Q$z');
    $match = $path->match($record, split => 1);
    # $match = ['B', 'C']

Option C<nested_arrays> creates a list for every field found:

    # split fields to lists
    $path = PICA::Path->new('009Q$z');
    $match = $path->match($record, split => 1, nested_arrays => 1);
    # $match = [['B', 'C']]

=head3 Match repeated Field with no subfield repetition

Field C<005A> is repeated.

    # get all subfields
    $path = PICA::Path->new('009Q');
    $match = $path->match($record);
    # $match = '1234-56781011-1213'
    
    # get subfields by code
    $path = PICA::Path->new('009Q');
    $match = $path->match($record);
    # $match = '1234-56781011-1213'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('005A$0');
    $match = $path->match($record, split => 1);
    # $match = ['1234-5678', '1011-1213']
    ```

Option C<nested_arrays> creates a list for every field found:

    # split fields to lists
    $path = PICA::Path->new('005A$0');
    $match = $path->match($record, split => 1, nested_arrays => 1);
    # $match = [['1234-5678'], ['1011-1213']]

=head3 Match repeated field with subfield repetition

Field C<045U> is repeated and has repeated subfields.
    
    # get all subfields
    $path = PICA::Path->new('045U');
    $match = $path->match($record);
    # $match = '003004005'
    
    # get subfields by code
    $path = PICA::Path->new('045U$e');
    $match = $path->match($record);
    # $match = '003004005'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('045U$e');
    $match = $path->match($record, split => 1);
    # $match = ['003', '004', '005']

Option C<nested_arrays> creates a list for every field found:

    # split fields to lists
    $path = PICA::Path->new('045U$e');
    $match = $path->match($record, split => 1, nested_arrays => 1);
    # $match = [['003', '004'], ['005']]

=head3 Match repeated field with occurrence

Field C<045F> is repeated and has occurrences.
    
    # get subfield from field with specific occurrence
    $path = PICA::Path->new('045F[01]$a');
    $match = $path->match($record);
    # $match = '001'
    
    # get subfield from field with wildcard for occurrence
    $path = PICA::Path->new('045F[0.]$a');
    $match = $path->match($record);
    # $match = '001002'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('045F[0.]$a');
    $match = $path->match($record, split => 1);
    # $match = ['001', '002']

=head3 Match the whole record with wildcards

The dot (.) is a wildcard for field tags, occurrence and subfield codes.

The path C<.....> means take any subfield from any field.

    # get all subfields from all fields
    $path = PICA::Path->new('....$.');
    $match = $path->match($record);
    # $match = '1234-56781011-1213http://example.org/ABCTitleSupplement16001700180019002000001002003004005'
    
    # get specific subfield from all fields
    $path = PICA::Path->new('....$a');
    $match = $path->match($record);
    # $match = 'Title001002'

Option C<split> creates a list out of subfields:

    # split subfields to list
    $path = PICA::Path->new('....$a');
    $match = $path->match($record, split => 1);
    # $match = ['Title', '001', '002']

Option C<nested_arrays> creates a list for every field found:

    # split fields to lists
    $path = PICA::Path->new('....');
    $match = $path->match($record, split => 1, nested_arrays => 1);
    # $match = [['1234-5678'], ['1011-1213'], [ 'http://example.org/', 'A', 'B', 'C', ], [ 'Title', 'Supplement' ], [ 1600, 1700, 1800, 1900, 2000, ], ['001'], ['002'], [ '003', '004' ], ['005']]

=head1 METHODS

=head2 new( $expression )

Create a PICA path by parsing the path expression. The expression consists of

=over

=item

A tag, consisting of three digits, the first C<0> to C<2>, followed by a digit
or C<@>.  The character C<.> can be used as wildcard.

=item

An optional occurrence, given by two or three digits (or C<.> as wildcard) in brackets,
e.g. C<[12]>, C<[0.]> or C<[102]>.

=item

An optional list of subfields. Allowed subfield codes include C<_A-Za-z0-9>.

=item

An optional position, preceded by C</>. Both single characters (e.g. C</0> for
the first), and character ranges (such as C<2-4>, C<-3>, C<2->...) are
supported.

=back

=head2 match_record( $record, %options )

Returns matched fields as string or array reference. 

Optional parameter:

=over
 
=item join STRING
 
By default all the matched values are joined into a string without a field 
separator. Use the join function to set the separator. Default: '' 
(empty string).

    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match_record( $record, join => ' - ' );
    # $match = 'Title - Supplement'
 
=item pluck 0|1
 
Be default, all subfields are added to the mapping in the order they are 
found in the record. Using the pluck option, one can select the required 
order of subfields to map. Default: 0.
 
    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match_record( $record, pluck => 1 );
    # $match = 'SupplementTitle'

=item split 0|1
 
When split is set to 1 then all mapped values will be joined into an array 
instead of a string. Default: 0. 

    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match_record( $record, split => 1 );
    # $match = [ 'Title', 'Supplement' ]

=item nested_arrays 0|1
 
When the split option is specified the output of the mapping will always be 
an array of strings (one string for each subfield found). Using the 
nested_array option the output will be an array of array of strings (one 
array item for each matched field, one array of strings for each matched 
subfield). Default: 0.

    my $record = { _id => 123X, record => [[ '045U', '', 'e', '003', 'e', '004' ], [ '045U', '', 'e', '005' ]] }
    my $path = PICA::Path->new( '045U' );
    my $match = $path->match_record( $record, nested_arrays => 1 );
    # $match = [[ '003', '004'], ['005' ]]

=item force_array 0|1

Force array as return value. Default: 0.

    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match_record( $record, force_array => 1 );
    # $match = [ 'TitleSupplement' ]

=back

=head2 match_field( $field )

Check whether a given PICA field matches the field and occurrence of this path.
Returns the C<$field> on success.

=head2 filter_record_fields( $record )

Returns an array reference with fields of a L<PICA::Data> that match the path.
Subfield codes are ignored.

=head2 match_subfields( $field )

Returns a list of matching subfields (optionally trimmed by from and length)
without inspection field and occurrence values.

=head2 stringify( [ $short ] )

Stringifies the PICA path to normalized form. Subfields are separated with
C<$>, unless called as C<stringify(1)> or the first subfield is C<$>.

=head2 fields

Return the stringified field expression or undefined.

=head2 subfields

Return the stringified subfields expression or undefined.

=head2 occurrences

Return the stringified occurrences expression or undefined.

=head2 positions

Return the stringified position or undefined.

=head1 SEE ALSO

L<Catmandu::Fix::pica_map>

=cut
