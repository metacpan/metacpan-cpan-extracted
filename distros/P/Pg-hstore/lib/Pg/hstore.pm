package Pg::hstore;

use 5.010;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Pg::hstore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	hstore_encode hstore_decode
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	hstore_encode hstore_decode
);

our $VERSION = '1.06';

require XSLoader;
XSLoader::load('Pg::hstore', $VERSION);

# Preloaded methods go here.
sub hstore_encode($) {
	Pg::hstore::encode(@_);
}

sub hstore_decode($) {
	Pg::hstore::decode(@_);
}

1;
__END__
=head1 NAME

Pg::hstore - Perl extension for encoding/decoding postgresql's hstore data type.

=head1 SYNOPSIS

  use Pg::hstore;
  ...
  my $row = $sth->fetchrow_hashref;   #Getting row from DB
  print "hstore data: ", $row->{addinfo}, "\n";
  my $addinfo = Pg::hstore::decode($row->{addinfo});   #Decoding into perl hashref

  #now $addinfo is 1-level hash ref with key->value
  print "addinfo->'full_name' = ", $addinfo->{full_name}, "\n";

  ...
  #Updating hstore. This type of updating can wipe other process work on addinfo field
  $addinfo->{full_name} = "John the ripper";
  $dbh->do("update users set addinfo=? where id=?", undef,
     Pg::hstore::encode($addinfo), 123);

=head1 DESCRIPTION

=head2 decode(string)

Decode given HSTORE value. NULL values will be converted to Perl undef; NULL or empty keys will be ignored.
Returns hash ref with key => value pairs. Can return undef on internal error.
Keys and values will have same UTF8 flag as incoming string.

=head2 encode(hashref)

Encodes given hash ref to HSTORE-format string. undef values will be converted to NULL. Empty or undef keys will be ignored.
Returns hstore-serialized string. Can return undef on internal error.
String will have UTF8 flag ON if any of hashref values have it.

=head1 EXPORT

None by default.
Can export B<hstore_encode> and B<hstore_decode> subs:

 use Pg::hstore qw/hstore_encode hstore_decode/;

=head1 BUGS

None known.
Feel free to clone/contribue from https://bitbucket.org/PSIAlt/p5-pg-hstore

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Alt

 ----------------------------------------------------------------------------
 "THE BEER-WARE LICENSE"
 As long as you retain this notice you can do whatever you want with this stuff.
 If we meet some day, and you think this stuff is worth it, you can buy me a beer
 in return.
 ----------------------------------------------------------------------------

=cut
