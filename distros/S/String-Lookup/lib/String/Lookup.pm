package String::Lookup;
$VERSION= 0.14;

# what runtime features we need
use 5.014;
use warnings;

# just use the PurePerl implementation for now
use String::Lookup::PurePerl;

# satisfy -require-
1;

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup - convert strings to ID's authoritatively and vice-versa

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup',
   autoflush => $when,      # when to automatically flush, default: destruction
   offset    => $offset,    # start counting from, default: 0
   increment => $increment, # space between ID's, default: 1

   # persistent storage backend, instead of "init" and "flush"
   storage => $storage, # how to store, e.g. 'FlatFile'
   tag     => $tag,     # tag to distinguish between logical hashes
   fork    => 1,        # fork for each flush, default: no
   ...                  # other persistent backend type specific parameters

   # or set up your own "init" and "flush"
   init      => $what,      # hash / code ref to initialize hash with
   flush     => sub { },    # code to flush hash with, default: don't flush
 };

 my $id= $lookup{ \$string }; # strings must be indicated by reference
 my $string= $lookup{$id};    # numbers indicate id -> string mapping

 # optimizing by bypassing the slow tie interface
 my $ro_lookup= %lookup;
 my $id= $ro_lookup->{$string} // $lookup{ \$string };

=head1 VERSION

This documentation describes version 0.14.

=head1 DESCRIPTION

Provide a simple way to map (a great number of) strings to ID's authoritatively.
Uses the C<tie> interface for simplicity.  Looking up the ID of a string is
accomplished by B<passing a reference to the string> as the key in the tied
hash.  If a reference is seen, it is assumed this is a string -> ID lookup
(even if the string only consists of a number).  If a non-reference is passed,
then it is assumed to be the numeric ID for which the string should be returned.

New ID's are assigned by taking the current offset value (by default starting
at B<0>) and adding the increment value to that (by default B<1>), and
remembering that as the next offset value.  Offset and increment value can only
be set at C<tie> time.

=head1 PERSISTENCE

 tie my %lookup, 'String::Lookup',
   storage => $storage, # how to store, e.g. 'FlatFile'
   tag     => $tag,     # tag to distinguish between logical hashes
   fork    => 1,        # fork for each flush, default: no
   ...                  # other persistent backend type specific parameters
 };

Generally, you want lookup hashes to have persistence across process runs.
You can indicate this with the C<storage> parameter.  It indicates which
persistent storage backend should be used.  If specified, it replaces the
C<init> and C<flush> parameters.

At least two parameters need to be specified to indicate where the persistent
storage of the lookup hash is located: C<storage> and C<tag>.  One parameter
is optional: C<fork>.  Other parameters may be needed for a given type of
persistent backend, please consult the documentation of the associated backend
module.

=over 4

=item storage

 tie my %lookup, 'String::Lookup',
   storage => $storage, # how to store, e.g. 'FlatFile'
 };

Indicate the type of persistent storage to be used.  It can either be a single
word (in which case it will be appended to the class name, e.g. C<FlatFile>
becomes L<String::Lookup::FlatFile>) or a fully qualified class name (in which
case it is expected to supply the C<init> and C<flush> interface for persistent
storage backends).

The L<Class::Lookup> distribution contains the L<String::Lookup::<FlatFile>
and C<String::Lookup::DBI> persistent backend modules.

=item tag

 tie my %lookup, 'String::Lookup',
   tag     => $tag,     # tag to distinguish between logical hashes
 };

Indicate the logical name of the lookup hash.  For the C<FlatFile> backend
this name is used as the filename in which to store.  For the C<DBI>
backend, this is the name of the table in which to store.  Other backends
may use the tag in different ways.

=item fork

 tie my %lookup, 'String::Lookup',
   fork    => 1,        # fork for each flush, default: no
 };

Indicate whether or not the flushing process (be it automatically or not)
should take place in a forked process or not.  Doing the flush in a forked
process has the advantage that lookups will continue almost immediately,
rather than having to wait for the storage requests to come back.  It currently
has the disadvantage that it will hide any problems in the flushing process.

=item (other, storage dependent parameters)

Any other acceptable parameters, should be returned by the class method
C<parameters_ok> on the storage class.  Any other parameters will be considered
to be an error and cause an exception.

See L<"METHODS IN STORAGE MODULE"> for more information about creating your
own persistent storage module.

=back

=head1 AUTOMATIC FLUSHING

 tie my %lookup, 'String::Lookup',
   autoflush => $when,    # when to automatically flush, default: at destruction
 };

The C<autoflush> parameter indicates when flushing of strings and their
associated ID's should be done automatically, rather then "manually" (by
calling the C<flush> method on the underlying object) or at object destruction
time.

Two types of autoflush parameter can be specified:

=over 4

=item per X new ID's

 autoflush => $number,         # flush after every $number new ID's

If the value specified with the C<autoflush> parameter is a simple number,
then it will be interpreted as the number of new ID's that should be seen
before an automatic flush will take place.

=item per every N seconds

 autoflush => $seconds . "s",  # flush after every $seconds seconds

If the value specified with the C<autoflush> parameter is a simple number
postfixed with the letter "s", then it will be interpreted as the number of
seconds since the last flush that should have passed before doing an automatic
flush (and with new ID's having been added, of course).

=back

=head1 OPTIMIZING STRING LOOKUPS

 # optimizing by bypassing the slow tie interface if possible
 my $ro_lookup= %lookup;
 my $id= $ro_lookup->{$string} // $lookup{ \$string };

The C<tie> interface is notoriously slow.  If a high number of strings needs
to be looked up, then the lookups may slow things down a lot.  Since we only
want to lookup strings because they occur again and again, it makes sense to
not have to use the C<tie> interface if the string has already an ID assigned
to it.  But the underlying hash lookup is hidden by the C<tie> interface.
If it would be possible to access the underlying (real) hash, then that could
be used to first check if a string is already known.

Finding out what the underlying real hash is, is possible by accessing the
tied hash in scalar context once: it will then return a reference to the
underlying hash, allowing direct lookup access.  Like so:

 my $ro_lookup= %lookup;

If there is no defined value returned from the underlying hash, then the
original, tied hash access should be used to automatically obtain the numeric
ID.  Like so:

 my $id= $ro_lookup->{$string} // $lookup{ \$string };

Please note that the lookup in the underlying hash should be made with the
string, and the lookup in the tied hash with the B<reference to> the string!

=head1 RANGE OF ID's

 tie my %lookup, 'String::Lookup',
   offset    => $offset,    # start counting from, default: 0
 };

In some cases you want the ID's to be issued to start at a certain value
(rather than starting from 1).  The C<offset> parameter can be used for this.

=head1 SPACE BETWEEN ID's

 tie my %lookup, 'String::Lookup',
   increment => $increment, # space between ID's, default: 1
 };

In some cases you want ID's to be spaced.  For instance in a multi datacenter
environment, where each data center has its own set of ID's that need to be
merged in a single persistent backend at some point in time.  In such a
situation, one can specify the C<increment> parameter.  If one expects to have
a maximum of 10 data centers, one could specify an increment of C<10>, and a
different C<offset> for each data center.  This would ensure that for each ID
there would always be 1 string, at the expense of the added complexity that
for each string, there could possibly be multiple ID's.

=head1 INITIALIZATION

 tie my %lookup, 'String::Lookup',
   init  => $hash_ref,    # hash ref to use as underlying hash
 };

 tie my %lookup, 'String::Lookup',
   init  => sub { ... },  # code to initialize hash with
 };

The C<init> parameter indicates how the underlying hash should be initialized.
It should only be used if you do B<not> have a persistent backend for your
lookup hash.  It can either be a a hash reference (that will be used directly)
or a code reference that is supposed to return a hash reference that should be
used as the underlying hash in which string to numerical ID mapping is stored.

A simple implementation of the code reference, that assumes strings will never
contain newlines, could be:

 sub simple_init {
     my %hash;
     open my $handle, '<', 'file.lookup' or die $!;
     while ( <$handle> ) {
         my ( $id, $string )= split ':', $_, 2;
         $hash{$id}= $string;
     }
     close $handle;
     return \%hash;
 } #simple_init

=head1 FLUSHING

 tie my %lookup, 'String::Lookup',
   flush => sub { my ( $strings, $ids )= @_ },  # code to flush hash with
 };

The C<flush> parameter indicates a code reference that will be called to
save strings that have been added since the hash was created / initialized,
or the previous time the tied hash was flushed.  It should only be used if
you do B<not> have a persistent backend for your lookup hash.  By default,
the hash is only flushed when being C<untie>d, or when the tied hash is
destroyed.

It is supposed to accept two parameters:

=over 4

=item 1 list reference for ID -> string mapping

The first parameter is a list reference to the underlying array that is used
for the ID to string mapping.

=item 2 list reference to ID's that were added

The second parameter is a list reference to the numeric ID's that were added
since the last flush (if any).

=back

It is supposed to return a boolean indicating whether the flush was successful.

A simple implementation, that assumes strings will never contain newlines,
could be:

 sub simple_flush {
     my ( $strings, $ids )= @_;
     open my $handle, '>>', 'file.lookup' or die $!;
     print $handle, "$_:$strings->[$_]\n" foreach @{$ids};
     return close $handle;
 } #simple_flush

Flushing the data can also be done at any one time by calling the C<flush>
method on the object under the C<tie> implementation.  This object can be
obtained with the C<tied> function:

  ( tied %hash )->flush;

Please note that it is generally a bad idea to keep a reference to the
underlying object around.  See C<The "untie" Gotcha> in L<perltie>.

=head1 METHODS IN STORAGE MODULE

=head2 flush

 sub flush {
     my ( $options, $strings, $ids )= @_;
     ...
     return $ok;
 } #flush

Perform the actual flush to the storage of this module.  The first parameter
is a hash reference with at least the C<tag> parameter, and any other
parameters that are specified with the L<parameters_ok> method.

The other parameters are the same as the parameters to the code ref that is
needed with the C<flush> parameter when tieing a hash with L<String::Lookup>
(currently a list reference with strings, and a list ref with ID's to be
flushed)..

Like the C<flush> code reference parameter when tying a hash, it is
expected to return a boolean, indicating whether the write to permanent
storage was successful or not.

=head2 init

 sub init {
     my ($options)= @_;
     ...
     return $hash;
 } #init

Perform the actions needed to initialize the underlying hash.  The first
parameter is a hash reference with at least the C<tag> parameter, and any
other parameters that are specified with the L<parameters_ok> method.

Like the C<init> code reference parameter when tying a hash, it is expected
to return a hash reference to be used as the underlying hash.

=head2 parameters_ok

 my @ok= $class->parameters_ok;

Return a list with the names of the parameters that are understandable by the
storage class.  Must be provided.

=head1 BACKGROUND

At a former $client, a large amount of (similar) string data is processed
every second.  Think user agent strings, IPv4 and IPv6 numbers, URL's, tags and
labels, domain names, HTTP input headers, affiliate ID's, etc. etc.

To reduce the database I/O, all of these strings are converted to numeric ID's.
ID's can be smaller, and more easily packed than strings.  But if a database
is being used to assign numeric ID's (usually using an auto-increment feature),
this means overhead.  Overhead that is generally not needed for what is
basically either a hash lookup, or an index on an array.  This would be
different if we could have a daemon like process whose function it would only
be to assign numeric ID's to strings without needing a database backend.

This module provides the basic interface mechanism for such a daemon.  It can
of course also be used for more mundane usage.

=head1 WHY REFERENCE TO STRING?

To keep the interface of string to ID and ID to string as simple as possible,
a cunning way was needed to differentiate between strings and ID's.  Since
some strings may consist of just a number (think HTTP status codes), it is
not a good idea to use that as a differentiating factor.

Since strings can become very large, copying around should be prevented.  By
specifying a reference to a string to do string to ID mapping, we kill two
birds with one stone: it is an unambiguous way to find out that we want string
to ID mapping B<and> we don't copy the string around as much.

=head1 IMPLEMENTATION

At the moment there is only a pure Perl reference implementation available.
This has the disadvantage of being slower than it could possibly be made.  But
it works B<now>.  It is the intention of providing a faster XS interface at a
later point in time.  Patches welcome!

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

maintained by LNATION, <thisusedtobeanemail@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>, 2019 LNATION <thisusedtobeanemail@gmail.com>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
