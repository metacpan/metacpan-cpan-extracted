package SPVM::Resource::SQLite;

our $VERSION = "0.003";

1;

=head1 Name

SPVM::Resource::SQLite - A resource that provides the SQLite header and source code.

=head1 Description

SPVM::Resource::SQLite in L<SPVM> is a L<resource|SPVM::Document::Resource> class for L<SQLite|https://www.sqlite.org/>.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_c99;
  $config->use_resource('Resource::SQLite');
  $config;

MyClass.c:

  #include "sqlite3.h"
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    const char* version = sqlite3_libversion();
    
    return 0;
  }

=head1 Original Product

L<SQLite|https://www.sqlite.org/>

=head1 Original Product Version

L<SQLite 3.45.1 (Amalgamation)|https://www.sqlite.org/download.html>

=head1 Language

C

=head1 Language Standard

C99

=head1 Header Files

=over 2

=item * sqlite3.h

=item * sqlite3ext.h

=back

=head1 Source Files

=over 2

=item * sqlite3.c

=back

=head1 Compiler Flags

=over 2

=item * -DSQLITE_THREADSAFE=1

Enables multi-thread support.

=item * -DSQLITE_ENABLE_COLUMN_METADATA

Enables APIs that provide column metadata, required by many database drivers.

=item * -DSQLITE_ENABLE_FTS5

Enables the Full-Text Search engine version 5.

=item * -DSQLITE_ENABLE_RTREE

Enables the R*Tree index extension for spatial queries.

=item * -DSQLITE_ENABLE_MATH_FUNCTIONS

Enables built-in SQL math functions (sin, cos, log, sqrt, etc.).

=item * -DSQLITE_ENABLE_JSON1

Enables JSON functions for managing JSON data in SQL.

=item * -DSQLITE_ENABLE_DBSTAT_VTAB

Enables the dbstat virtual table to query database space usage.

=item * -pthread

Adds support for multithreading with the pthreads library.

=back

=head1 How to Create Resource

=head2 Download

  mkdir -p .tmp
  # Download SQLite 3.49.1 Amalgamation (Released in early 2025)
  curl -L https://www.sqlite.org/2025/sqlite-amalgamation-3490100.zip -o .tmp/sqlite-amalgamation-3490100.zip
  unzip .tmp/sqlite-amalgamation-3490100.zip -d .tmp/

=head2 Extracting Source Files

  # Copy the amalgamation source file
  cp .tmp/sqlite-amalgamation-3490100/sqlite3.c lib/SPVM/Resource/SQLite.native/src/

=head2 Extracting Header Files

  # Copy the header files
  cp .tmp/sqlite-amalgamation-3490100/sqlite3.h lib/SPVM/Resource/SQLite.native/include/
  cp .tmp/sqlite-amalgamation-3490100/sqlite3ext.h lib/SPVM/Resource/SQLite.native/include/

=head1 Repository

L<SPVM::Resource::SQLite - Github|https://github.com/yuki-kimoto/SPVM-Resource-SQLite>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License