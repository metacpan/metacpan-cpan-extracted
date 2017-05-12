package Sort::SQL;

use strict;
use warnings;
use vars qw( $VERSION );    # for version 5.005...

$VERSION = '0.08';

my $debug = $ENV{PERL_DEBUG} || 0;

sub parse {
    my $class = shift;
    my $order = shift || '';    # will return empty array

    my @s = split( m/[\ ,]+/, $order );
    my @pairs;

    while ( my ( $prop, $dir ) = splice( @s, 0, 2 ) ) {

        $debug and warn sprintf( "prop='%s'  dir='%s'\n", $prop, $dir || '' );

        next if $prop =~ m/[^\.\w]/;    # avoid sql injection

        if ( !defined $dir ) {
            $dir = 'ASC';
        }
        elsif ( $dir !~ m/^(ASC|DESC)$/i ) {
            unshift( @s, $dir );
            $dir = 'ASC';
        }

        push @pairs, [ $prop => uc($dir) ];
    }

    return \@pairs;
}

sub string2array {
    my $pairs = shift->parse(@_);
    return [
        map {
            { $_->[0] => $_->[1] }
            } @$pairs
    ];
}

1;
__END__

=head1 NAME

Sort::SQL - manipulate SQL sort strings

=head1 SYNOPSIS

  use Sort::SQL;

  my $array_of_arrays = Sort::SQL->parse('foo ASC bar DESC bing');
  # $array_of_arrays == [ [ 'foo', 'ASC' ], [ 'bar', 'DESC' ], [ 'bing', 'ASC' ] ]
  
  my $array_of_hashes = Sort::SQL->string2array('foo asc bar DESC bing');
  # $array_of_hashes == [ { foo => 'ASC' }, { bar => 'DESC' }, { bing  => 'ASC' } ]
  
=head1 DESCRIPTION

Sort::SQL is so simple it almost doesn't deserve to be on CPAN. 
But since I kept finding myself copy/pasting this method 
into multiple places, I finally figured
it deserved to live in its own class.

=head1 METHODS

Sort::SQL implements these methods, each of which
take a scalar string of the SQL C<ORDER BY> syntax and return
a data structure.

=head2 parse( I<sql sort string> )

Returns I<sql sort string> as an arrayref of arrayrefs.

=head2 string2array( I<sql sort string> )

Returns I<sql sort string> as an arrayref of hashrefs. This is for
backwards compat only -- parse() is a little faster and more
usable.

=head1 EXAMPLE

Here's how I use it in my web applications. I want to allow users
to re-sort search results by table column header. Each column name is a
link back to the server, and I want to provide the SQL C<ORDER BY> value
as a param in the URI.

In my controller code I do:

 my $sort_order = $c->request->param('order');
 $c->stash->{search}->{order} = Sort::SQL->parse( $sort_order );
 
And then in my template:

 column.links = {};
 
 FOREACH pair IN search.order;

  column     = pair.0;
  direction  = pair.1;

  # toggle the sort direction for current sorted column
  # so the next browser request will reverse the sort
  IF ( direction == 'ASC' );
    column.links.$column.direction = 'DESC';

  ELSE;
    column.links.$column.direction = 'ASC';
  
  END;

 END;

=head1 SEE ALSO

SWISH::API::Object

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

Thanks to Atomic Learning for sponsoring the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
