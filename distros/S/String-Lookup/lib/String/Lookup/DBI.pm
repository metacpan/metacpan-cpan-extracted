package String::Lookup::DBI;
$VERSION= 0.14;

# what runtime features we need
use 5.014;
use warnings;
use autodie;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class Methods
#
#-------------------------------------------------------------------------------
# flush
#
#  IN: 1 class
#      2 options hash ref
#      3 underlying list ref
#      4 list ref with ID's to be flushed
# OUT: 1 boolean indicating success

sub flush {
    my ( $class, $options, $list, $ids )= @_;

    # initializations
    local $_;
    my $dbh=    $options->{dbh};
    my $insert= $options->{insert};
    
    # write all ID's (the stupid way, for now)
    $dbh->do( $insert, {}, $_, $list->[$_] ) foreach @{$ids};

    return 1;
} #flush

#-------------------------------------------------------------------------------
# init
#
#  IN: 1 class
#      2 options hash ref
# OUT: 1 hash ref with lookup

sub init {
    my ( $class, $options )= @_;
    
    # sanity check
    my @errors;
    push @errors, "Must have a 'dbh' specified" if !$options->{dbh};
    die join "\n", "Found the following problems with init:", @errors
      if @errors;

    # set up the fetch
    my $table= $options->{tag};
    my $id=    $options->{id}     || 'id';
    my $name=  $options->{string} || 'name';
    my $sth= $options->{dbh}->prepare( "SELECT $id, $name FROM $table" );
    $sth->execute;

    # put it into the hash
    my ( %hash, $values );
    $hash{ $values->[0] }= $values->[1] while $values= $sth->fetchrow_arrayref;

    # set up insert SQL
    $options->{insert}= "INSERT $id, $name INTO $table VALUES (?,?)";

    return \%hash;
} #init

#-------------------------------------------------------------------------------
# parameters_ok
#
#  IN: 1 class (not used)
# OUT: 1 .. N parameter names

sub parameters_ok { state $ok= [ qw( dbh id name ) ]; @{$ok} } #parameters_ok

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup::DBI - flush String::Lookup using DBI compatible database handle

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup',

   # standard persistent storage parameters
   storage => 'DBI', # store using DBI compatible database handle
   tag     => $tag,  # possibly fully qualified table name
   fork    => 1,     # fork for each flush, default: no

   # parameters specific to 'DBI'
   dbh    => $dbh,         # database handle to be used
   id     => $id_name,     # name of "id" column, default: 'id'
   string => $string_name, # name of "string" column, default: 'name'

   # other parameters for String::Lookup
   ...
 ;

=head1 VERSION

This documentation describes version 0.14.

=head1 DESCRIPTION

This module is a class for providing persistent storage for lookup hashes,
as provided by L<String::Lookup>.

Please see the C<METHODS IN STORAGE MODULE> section in L<String::Lookup> for
documentation on which methods this storage class provides.

=head1 ADDITIONAL PARAMETERS

The following additional parameters are provided by this storage class:

=over 4

=item dbh

 tie my %lookup, 'String::Lookup',
   dbh    => $dbh,         # database handle to be used
 ;

Indicate the L<DBI> compatible database handle to be used to store the lookup
hash.  C<Must be specified>.

=item id

 tie my %lookup, 'String::Lookup',
   id     => $id_name,     # name of "id" column, default: 'id'
 ;

Indicate the name of the column for storing "id" values.  Defaults to C<id>.

=item string

 tie my %lookup, 'String::Lookup',
   string => $string_name, # name of "string" column, default: 'name'
 ;

Indicate the name of the column for storing strings.  Defaults to C<name>.

=back

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
