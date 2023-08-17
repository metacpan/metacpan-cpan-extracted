##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Query.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/06/13
## Modified 2023/06/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Query;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Apache2::API::Query );
    use vars qw( $VERSION );
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

1;
# NOTE: pod
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Query - utf8 compliant URI query string manipulation

=head1 SYNOPSIS

    # Constructor - using a GET query string
    $qq = Net::API::REST::Query->new($query_string);
    # OR Constructor - using a hashref of key => value parameters
    $qq = Net::API::REST::Query->new($cgi->Vars);
    # OR Constructor - using an array of successive keys and values
    $qq = Net::API::REST::Query->new(@params);

    # Clone the current object
    $qq2 = $qq->clone;

    # Revert back to the initial constructor state (to do it all again)
    $qq->revert;

    # Remove all occurrences of the given parameters
    $qq->strip('page', 'next');

    # Remove all parameters except the given ones
    $qq->strip_except('pagesize', 'order');

    # Remove all empty/undefined parameters
    $qq->strip_null;

    # Replace all occurrences of the given parameters
    $qq->replace(page => $page, foo => 'bar');

    # Set the argument separator to use for output (default: unescaped '&')
    $qq->separator(';');

    # Output the current query string
    print "$qq";           # OR $qq->stringify;
    # Stringify with explicit argument separator
    $qq->stringify(';');

    # Output the current query string with a leading '?'
    $qq->qstringify;
    # Stringify with a leading '?' and an explicit argument separator
    $qq->qstringify(';');

    # Get a flattened hash/hashref of the current parameters
    #   (single item parameters as scalars, multiples as an arrayref)
    my %qq = $qq->hash;

    # Get a non-flattened hash/hashref of the current parameters
    #   (parameter => arrayref of values)
    my %qq = $qq->hash_arrayref;

    # Get the current query string as a set of hidden input tags
    print $qq->hidden;

    # Check whether the query has changed since construction
    if ($qq->has_changed) {
      print "changed version: $qq\n";
    }

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

As of version C<1.0.0>, this module fully inherits from L<Apache2::API::Query>.

The rest below is taken from L<Apache2::API::Query> documentation and is copied here for convenience.

=head2 CONSTRUCTOR

Net::API::REST::Query objects can be constructed from scalar query strings ('foo=1&bar=2&bar=3'), from a hashref which has parameters as keys, and values either as scalars or arrayrefs of scalars (to handle the case of parameters with multiple values e.g. { foo => '1', bar => [ '2', '3' ] }), or arrays composed of successive parameters-value pairs  e.g. ('foo', '1', 'bar', '2', 'bar', '3'). For instance:

    # Constructor - using a GET query string
    $qq = Net::API::REST::Query->new($query_string);

    # Constructor - using an array of successive keys and values
    $qq = Net::API::REST::Query->new(@params);

    # Constructor - using a hashref of key => value parameters,
    # where values are either scalars or arrayrefs of scalars
    $qq = Net::API::REST::Query->new($cgi->Vars);

Net::API::REST::Query also handles L<CGI.pm>-style hashrefs, where multiple values are packed into a single string, separated by the "\0" (null) character.

All keys and values are URI unescaped at construction time, and are stored and referenced unescaped. So a query string like:

    group=prod%2Cinfra%2Ctest&op%3Aset=x%3Dy

is stored as:

    'group'     => 'prod,infra,test'
    'op:set'    => 'x=y'

You should always use the unescaped/normal variants in methods i.e.

     $qq->replace('op:set'  => 'x=z');

NOT:

     $qq->replace('op%3Aset'  => 'x%3Dz');

You can also construct a new Net::API::REST::Query object by cloning an existing one:

     $qq2 = $qq->clone;


=head2 MODIFIER METHODS

All modifier methods change the state of the Net::API::REST::Query object in some way, and return $self, so they can be used in chained style e.g.

    $qq->revert->strip('foo')->replace(bar => 123);

Note that Net::API::REST::Query stashes a copy of the parameter set that existed at construction time, so that any changes made by these methods can be rolled back using 'revert()'. So you don't (usually) need to keep multiple copies around to handle incompatible changes.

=over 4

=item revert()

Revert the current parameter set back to that originally given at construction time i.e. discard all changes made since construction.

=item strip($param1, $param2, ...)

Remove all occurrences of the given parameters and their values from the current parameter set.

=item strip_except($param1, $param2, ...)

Remove all parameters EXCEPT those given from the current parameter
set.

=item strip_null()

Remove all parameters that have a value of undef from the current
parameter set.

=item replace($param1 => $value1, $param2, $value2, ...)

Replace the values of the given parameters in the current parameter set with these new ones. Parameter names must be scalars, but values can be either scalars or arrayrefs of scalars, when multiple values are desired.

Note that 'replace' can also be used to add or append, since there's no requirement that the parameters already exist in the current parameter
set.

=item strip_like($regex)

Remove all parameters whose names match the given (qr-quoted) regex e.g.

    $qq->strip_like(qr/^utm/)

Does NOT match against parameter values.

=item separator($separator)

Set the argument separator to use for output. Default: '&'.

=back

=head2 ACCESSOR METHODS

=over 4

=item has_changed()

If the query is actually changed by any of the modifier methods (strip, strip_except, strip_null, strip_like, or replace) it sets an internal changed flag which can be access by:

    $qq->has_changed

revert() resets the has_changed flag to false.

=back

=head2 OUTPUT METHODS

=over 4

=item "$qq", stringify(), stringify($separator)

Return the current parameter set as a conventional param=value query string, using $separator as the separator if given. e.g.

    foo=1&bar=2&bar=3

Note that all parameters and values are URI escaped by stringify(), so that query-string reserved characters do not occur within elements. For instance, a parameter set of:

    'group'     => 'prod,infra,test'
    'op:set'    => 'x=y'

will be stringified as:

    group=prod%2Cinfra%2Ctest&op%3Aset=x%3Dy

=item qstringify(), qstringify($separator)

Convenience method to stringify with a leading '?' e.g.

    ?foo=1&bar=2&bar=3

=item hash()

Return a hash (in list context) or hashref (in scalar context) of the current parameter set. Single-item parameters have scalar values, while while multiple-item parameters have arrayref values e.g.

    {
        foo => 1,
        bar => [ 2, 3 ],
    }

=item hash_arrayref()

Return a hash (in list context) or hashref (in scalar context) of the current parameter set. All values are returned as arrayrefs, including those with single values e.g.

    {
        foo => [ 1 ],
        bar => [ 2, 3 ],
    }

=item hidden()

Returns the current parameter set as a concatenated string of hidden input tags, one per parameter-value e.g.

    <input type="hidden" name="foo" value="1" />
    <input type="hidden" name="bar" value="2" />
    <input type="hidden" name="bar" value="3" />

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::Query>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
