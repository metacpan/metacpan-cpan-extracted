package PGObject::Util::PseudoCSV;

use 5.008;
use strict;
use warnings;
use PGObject;
use Carp;

=head1 NAME

PGObject::Util::PseudoCSV - Tuple/Array parsing and serialization for PGObject

=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';


=head1 SYNOPSIS

This is a parser and constructor for PostgreSQL text representations of tuples
and arrays.

To parse:

For a tuple, we'd typically:

   my @list = pseudocsv_parse($text_representation, @typelist);

We can then arrange the hash as:

   my $hashref = pseudocsv_to_hash(\@list, \@col_list);

Which we can combine as:

   my $hashref =  pseudocsv_to_hash(
                     pseudocsv_parse($text_representation, @typelist),
                     \@col_list
   );

For an array we specify a single type to the parser:

   my @list = pseudocsv_parse($text_representation, $type);

=head1 DESCRIPTION

PostgreSQL can represent tuples and arrays in a text format that is almost like
CSV.  Unfortunately this format has a number of gotchas which render existing 
CSV-parsers useless.  This module provides basic parsing functions to other
programs for db interface purposes.  With this module you can both parse 
pseudocsv representations of tuples and arrays and you can create them from a 
list.

The API's here assume you send one (and only one) pseudo-csv record to the API 
at once.  These may be nested, so a single tuple can contain arrays of tuples 
which can contain arrays of tuples ad infinitum but the parsing only goes one
layer deep tuple-wise so that handlin classes have an opportunity to re-parse
with appropriate type information. Naturally this has performance implications,
so depth in SQL structures passed should be reasonably limited.

=head1 EXPORT

=over

=item pseudocsv_to_hash

=item pseudocsv_parse

=item to_pseudocsv

=back

=cut

use parent 'Exporter';

our @EXPORT = qw(pseudocsv_to_hash pseudocsv_parse to_pseudocsv 
                 hash2pcsv pcsv2hash);

=head1 SUBROUTINES/METHODS

=head2 pseudocsv_parse

This does a one-level deep parse of the pseudo-csv, with additional levels in
arrays.  When a tuple is encountered it is instantiated as its type but a 
subarray is parsed for more entities.

Only one pseudocsv record can be passed in at once, but embedded newlines are properly handled.

=cut

sub pseudocsv_parse {
    my ($csv, $type, $registry) = @_;
    if ($csv =~ /^\(/ ) { # tuple
       $csv =~ s/^\((.*)\)$/$1/s;
    } elsif ($csv =~ /^\{/ ) { # array 
       $csv =~ s/^\{(.*)\}$/$1/s;
    }
    $registry ||= 'default';
    my @returnlist = ();
    while (length($csv)) {
        my $val = _parse(\$csv);
        my $in_type = $type;
        $in_type = shift @$type if ref $type eq ref [];
        $val =~ s/""/"/g if defined $val;
        push @returnlist, PGObject::process_type($val, $type, $registry);
    }
    return @returnlist if wantarray;
    return \@returnlist;
}

=head2 pcsv2hash($literal_string, @cols);

Returns a hash from a tuple literal or array literal.  

=cut

sub pcsv2hash {
    my $string = shift;
    $string = shift if $string eq __PACKAGE__;
    my @colnames = @_;

    my @colvals = pseudocsv_parse($string, undef, undef);
    
    my $hash = { map{ $_ => shift @colvals } @colnames };
    return %$hash if wantarray;
    return $hash;
}

=head2 hash2pcsv($hashref, @cols)

Takes an ordered list of columns and a hashref and returns a tuple literal

=cut

sub hash2pcsv {
    my $hashref = shift;
    return to_pseudocsv([map { $hashref->{$_} } @_], 1)
}


# _parse is the private method which does the hard work of parsing.

sub _parse {
    my ($csvref) = @_;
    my $retval;
    if ($$csvref =~ /^"/){ # quoted string
       $$csvref =~ s/^"(([^"]|"")*)",?//s;
       $retval = $1;
       $retval =~ s/""/"/g;
    } else {
       $$csvref =~ s/^([^,]*)(,|$)//s;
       $retval = $1;
       $retval = undef if $retval =~ /^null$/i;
    }
    if (defined $retval and $retval =~ s/^\{(.*)\}$/$1/){
        my $listref = [];
        push @$listref, _parse(\$retval) while $retval;
        $retval = $listref;
    }
    return $retval;
}

=head2 pseudocsv_tohash($coldata, $colnames) DEPRECATED

Takes an arrayref of column data and an arrayref of column names and returns 
a hash.  This is mostly a helper function designed to help with tuple types.

This interface is deprecated and will go away in 2.0.  Use pcsv2hash instead.

=cut

sub pseudocsv_tohash {
    my ($cols, $colnames) = @_;
    my $hash = { map{ $_ => shift @$cols } @$colnames };
    return %$hash if wantarray;
    return $hash;
}

=head2 to_pseudocsv($datalist, $is_tuple)

Takes a list of data and an is_tuple argument and creates a pseudocsv.

Note:  this does not check for array sanity.  If you are not careful you can
get arrays returned which are not valid SQL arrays.  Remember that SQL arrays
have every item being the same size, and all SQL arrays are are regular in 
size (so all 1 and 2d arrays follow the same form as mathematical matrices).

=cut

sub _val {
    my ($val, $is_tuple) = @_;
    return 'NULL' unless defined $val;

    $val = $val->to_db if eval { $val->can('to_db') };
    $val = to_pseudocsv($_, 0) if ref $_ eq ref [];
    return $val if ref $_ eq ref [] and !$is_tuple;

    $val =~ s/"/""/;
    $val = qq("$val") if $val =~ /(^null$|[",{}])/i;
    return $val;
}

sub to_pseudocsv {
    my ($list, $is_tuple) = @_;
    Carp::croak 'First arg must be an arrayref' unless ref $list;
    my $csv =  join(',', map { _val($_, $is_tuple) } @$list);
    return qq|($csv)| if $is_tuple;	
    return qq|{$csv}|;
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-pseudocsv at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-PseudoCSV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::PseudoCSV


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-PseudoCSV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-PseudoCSV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-PseudoCSV>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-PseudoCSV/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of PGObject::Util::PseudoCSV
