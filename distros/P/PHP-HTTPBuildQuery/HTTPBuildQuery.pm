# Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  The
# copyrights to the contents of this file are licensed under the Perl
# Artistic License (ver. 15 Aug 1997)

###########################################
package PHP::HTTPBuildQuery;
###########################################
use strict;
use warnings;
use URI::Escape;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(http_build_query http_build_query_utf8);

our $VERSION = "0.09";

###########################################
sub http_build_query {
###########################################
    my($data, $prefix, $separator) = @_;

    return http_build_query_iso($data, $prefix, $separator);
}

###########################################
sub http_build_query_utf8 {
###########################################
    my($data, $prefix, $separator) = @_;

    return serialize($data, $prefix, $separator, 
                     \&URI::Escape::uri_escape_utf8);
}

###########################################
sub http_build_query_iso {
###########################################
    my($data, $prefix, $separator) = @_;

    return serialize($data, $prefix, $separator, 
                     \&URI::Escape::uri_escape);
}

###########################################
sub serialize {
###########################################
    my($data, $prefix, $separator, $escaper, $sofar) = @_;

    $separator = '&' unless defined $separator;

    if( ref($data) eq "HASH" ) {
        return hash_serialize($data, $prefix, $separator, $escaper, $sofar);
    } elsif( ref($data) eq "ARRAY" ) {
        return array_serialize($data, $prefix, $separator, $escaper, $sofar);
    } elsif( ref($data) eq "" ) {
        return scalar_serialize($data, $prefix, $separator, $escaper, $sofar);
    } else {
        die "Data type ", ref($data), " not (yet) implemented.";
    }
}

###########################################
sub hash_serialize {
###########################################
    my($data, $prefix, $separator, $escaper, $sofar) = @_;

    my $result = "";

    for my $key (keys %$data) {

        my $newsofar = 
            defined $sofar ? 
              ($sofar . "%5B" . $escaper->($key) . "%5D") :
              $escaper->($key);

        $result .= $separator if length $result;
        $result .= serialize( 
                     $data->{$key},
                     $prefix,
                     $separator,
                     $escaper,
                     $newsofar,
                   );
    }
    return $result;
}

###########################################
sub array_serialize {
###########################################
    my($data, $prefix, $separator, $escaper, $sofar) = @_;

    my $result = "";
    my $idx    = 0;

    for my $element (@$data) {

        my $newsofar = 
            defined $sofar                    ? 
              ($sofar . "%5B" . $idx . "%5D") :
              defined $prefix     ? 
                ("$prefix" . "_" . $idx) :
                $idx;

        $result .= $separator if length $result;
        $result .= serialize( 
                     $element,
                     $prefix,
                     $separator,
                     $escaper,
                     $newsofar,
                   );
        $idx++;
    }
    return $result;
}

###########################################
sub scalar_serialize {
###########################################
    my($data, $prefix, $separator, $escaper, $sofar) = @_;

    my $escaped_data = defined $data ? $escaper->($data) : '';
    my $new_sofar    = defined $sofar ? $sofar : '';

    return "$new_sofar=$escaped_data";
}

1;

__END__

=head1 NAME

PHP::HTTPBuildQuery - Data structures become form-encoded query strings

=head1 SYNOPSIS

    use PHP::HTTPBuildQuery qw(http_build_query);

    my $query = http_build_query( 
        { foo => { 
              bar => "baz", 
                  quick => { "quack" => "schmack" },
              },
        },
    );

    # Query: "foo%5Bbar%5D=baz&foo%5Bquick%5D%5Bquack%5D=schmack"

    # URL decoded: "foo[bar]=baz", "foo[quick][quack]=schmack"

=head1 DESCRIPTION

PHP::HTTPBuildQuery implements PHP's C<http_build_query> function in
Perl. It is used to form-encode Perl data structures in URLs, so that
PHP can read them on the receiving end.

New with version 0.04 comes C<http_build_query_utf8> which has an
identical syntax but deals with utf8 data instead. See the GOTCHAS section 
below for details.

C<http_build_query> accepts one mandatory and two optional parameters: 

     http_build_query( $data, $prefix, $separator );

where

=over 4

=item *

C<$data> is a reference to the data structure (hash or array)

=item *

C<$prefix> is an array name for array elements at the top level. An 
array at the top level, as in

    http_build_query( [ 'foo', 'bar', 'baz' ]);

would create a query string like:

    "0=foo&1=bar&2=baz"

which PHP can't make sense of at the receiving end, as variables names
can't start with a number. Adding a prefix, like in

    http_build_query( [ 'foo', 'bar', 'baz' ], "var");

creates

    "var_0=foo&var_1=bar&var_2=baz"

which then makes sense in PHP land.
    
=item *

C<$seperator> is an optional argument separator (defaults to '&'),
used to separate the fields in the encoded string.

=back

=head1 EXAMPLES

=head2 Array

    $query = http_build_query( ['foo', 'bar'] );

    # Query: "name_0=foo&name_1=bar"

=head2 Hash with Array

    $query = http_build_query( { foo => [ 'bar', 'baz' ] } );

    # Query: "foo[0]=bar&foo[1]=baz" (not escaped for readability)

=head1 GOTCHAS

=over 4

=item B<UTF8 Characters>

The C<uri_escape()> function used in C<http_build_query> won't encode
utf8 characters. If your data is utf8 encoded, use C<http_build_query_utf8>
instead.

=item B<Hash Element Order>

Perl hashes have no defined order, so if you encode something like
C<{ foo => "bar", baz => "quack" }>, don't be surprised if you get
the entries in a different order:

    # Query: "baz=quack&foo=bar"

=item B<Frankenstein Arrays>

PHP's Frankenstein arrays handle numeric indexing and hash-like lookups
transparently. For example, you could have a data structure like

      # PHP
    $a = array(
       'foo'  => 'bar',
       'baz',
    );
      # PHP

and you could access both its numeric and associative elements:

     # PHP
   print $a[0];
     # prints: 'baz'

     # PHP
   print $a[foo];
     # prints: 'bar'

PHP's C<http_build_query> function would transform the Frankenstein
array above to

    "foo=bar&0=baz" 

or, better, with a prefix of 'name', to

    "foo=bar&name_0=baz" 

In Perl, on the other hand, there's hashes for associative lookups and 
arrays for numerically indexed containers, so you can't mix and match,
and there's no way to define a data structure to print out the query
string above.

=item B<Special Characters>

C<http_build_query> creates a PHP-specific encoding format which
can't handle ']' or '[' characters in its keys (they're ok in hash
values, though). This module won't check against this case, it
will just generate form strings that won't be decodable afterwards. Make
sure to filter your data before passing it to C<http_build_query()>.

=back

=head1 THANKS

Thanks to the following Yahoos who provided advice, ideas and code:
Sara Golemon, Rasmus Lerdorf, Evan Miller. 

=head1 COPYRIGHT & LICENSE

COPYRIGHT & LICENSE

Copyright (c) 2008-2012 Yahoo! Inc. All rights reserved. The copyrights to the 
contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997)

=head1 AUTHOR

2008, Mike Schilli <cpan@perlmeister.com>
