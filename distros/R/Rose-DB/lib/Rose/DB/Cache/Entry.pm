package Rose::DB::Cache::Entry;

use strict;

use base 'Rose::Object';

our $VERSION = '0.736';

use Rose::Object::MakeMethods::Generic
(
  'scalar'  => 
  [
    'db',
    'key',
  ],

  'boolean' => 
  [
    'prepared',
    'created_during_apache_startup',
  ]
);

*is_prepared = \&prepared;

1;

__END__

=head1 NAME

Rose::DB::Cache::Entry - A cache entry for use with Rose::DB::Cache objects.

=head1 SYNOPSIS

  package My::DB::Cache::Entry;

  use base 'Rose::DB::Cache::Entry';
  ...

  package My::DB::Cache;

  use base 'Rose::DB::Cache';

  use My::DB::Cache::Entry;

  __PACKAGE__->entry_class('My::DB::Cache::Entry');
  ...

=head1 DESCRIPTION

L<Rose::DB::Cache::Entry> provides both an API and a default implementation of a cache entry for use with L<Rose::DB::Cache> objects.  A L<Rose::DB::Cache>-derived class L<uses|Rose::DB::Cache/entry_class> L<Rose::DB::Cache::Entry>-derived objects to store cache entries.

The default implementation includes attributes for storing the cache key, the cached L<Rose::DB>-derived object itself, and some boolean flags.  Subclasses can add new attributes as desired.


=head1 CONSTRUCTORS

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::DB::Cache::Entry> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<created_during_apache_startup [BOOL]>

Get or set a boolean value indicating whether or not the L<db|/db> object this cache entry contains was created while the apache server was starting up.

=item B<db [DB]>

Get or set the L<Rose::DB>-derived object stored in this cache entry.

=item B<key [KEY]>

Get or set the cache key for this entry.

=item B<prepared [BOOL]>

Get or set a boolean value indicating whether or not a cache entry is "prepared."  The interpretation of this flag is up to the L<Rose::DB::Cache>-derived class that L<uses|Rose::DB/entry_class> this entry class.

=item B<is_prepared>

Returns true if L<prepared|/prepared> is true, false otherwise.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
