package Pongo::Client;
use strict;
use warnings;
require XSLoader;

XSLoader::load('Pongo::Client', $Pongo::VERSION);

1;

=head1 NAME

collection_insert_one - Insert a single document into a MongoDB collection

=head1 SYNOPSIS

  bool collection_insert_one(
      mongoc_collection_t *collection,
      SV *document,
      SV *opts,
      SV *reply,
      SV *error
  );

=head1 DESCRIPTION

Inserts a single document into the specified MongoDB collection. This function
takes the collection object, the document to insert, and optional configuration
parameters. It also accepts optional reply and error handling parameters.

=head1 PARAMETERS

=over 4

=item collection (mongoc_collection_t *)

The MongoDB collection to insert the document into.

=item document (SV *)

The document to insert, provided as a Perl SV reference, which should be
converted to a BSON document.

=item opts (SV *)

Optional settings or options for the insertion operation, provided as a Perl
SV reference to a BSON document.

=item reply (SV *)

Optional reply containing the result of the insertion, returned as a Perl
SV reference.

=item error (SV *)

Optional error structure to capture any issues that occur during insertion,
returned as a Perl SV reference.

=back

=head1 RETURN VALUE

Returns a boolean value: C<true> if the insertion was successful, otherwise
C<false>.

=cut


=head1 NAME

collection_update_one - Update a single document in a MongoDB collection

=head1 SYNOPSIS

  bool collection_update_one(
      mongoc_collection_t *collection,
      SV *selector,
      SV *update,
      SV *opts,
      SV *reply,
      SV *error
  );

=head1 DESCRIPTION

Updates a single document in the specified MongoDB collection, matching the
selector criteria. The function takes the collection object, a selector to
identify the document, an update document, and optional parameters for options,
reply, and error handling.

=head1 PARAMETERS

=over 4

=item collection (mongoc_collection_t *)

The MongoDB collection to update the document in.

=item selector (SV *)

A selector to find the document that will be updated, provided as a Perl SV
reference to a BSON document.

=item update (SV *)

The update operation to apply to the matched document, provided as a Perl SV
reference to a BSON document.

=item opts (SV *)

Optional settings or options for the update operation, provided as a Perl
SV reference to a BSON document.

=item reply (SV *)

Optional reply containing the result of the update, returned as a Perl
SV reference.

=item error (SV *)

Optional error structure to capture any issues that occur during the update,
returned as a Perl SV reference.

=back

=head1 RETURN VALUE

Returns a boolean value: C<true> if the update was successful, otherwise
C<false>.

=cut


=head1 NAME

collection_delete_many - Delete multiple documents from a MongoDB collection

=head1 SYNOPSIS

  bool collection_delete_many(
      mongoc_collection_t *collection,
      SV *selector,
      SV *opts,
      SV *reply,
      SV *error
  );

=head1 DESCRIPTION

Deletes multiple documents that match the provided selector criteria from
the specified MongoDB collection. It also accepts optional reply and error
handling parameters.

=head1 PARAMETERS

=over 4

=item collection (mongoc_collection_t *)

The MongoDB collection from which to delete documents.

=item selector (SV *)

A selector to match the documents to be deleted, provided as a Perl SV
reference to a BSON document.

=item opts (SV *)

Optional settings or options for the deletion operation, provided as a Perl
SV reference to a BSON document.

=item reply (SV *)

Optional reply containing the result of the deletion, returned as a Perl
SV reference.

=item error (SV *)

Optional error structure to capture any issues that occur during deletion,
returned as a Perl SV reference.

=back

=head1 RETURN VALUE

Returns a boolean value: C<true> if the deletion was successful, otherwise
C<false>.

=cut


=head1 NAME

collection_delete_one - Delete a single document from a MongoDB collection

=head1 SYNOPSIS

  bool collection_delete_one(
      mongoc_collection_t *collection,
      SV *selector,
      SV *opts,
      SV *reply,
      SV *error
  );

=head1 DESCRIPTION

Deletes a single document that matches the provided selector criteria from
the specified MongoDB collection. It also accepts optional reply and error
handling parameters.

=head1 PARAMETERS

=over 4

=item collection (mongoc_collection_t *)

The MongoDB collection from which to delete the document.

=item selector (SV *)

A selector to match the document to be deleted, provided as a Perl SV
reference to a BSON document.

=item opts (SV *)

Optional settings or options for the deletion operation, provided as a Perl
SV reference to a BSON document.

=item reply (SV *)

Optional reply containing the result of the deletion, returned as a Perl
SV reference.

=item error (SV *)

Optional error structure to capture any issues that occur during deletion,
returned as a Perl SV reference.

=back

=head1 RETURN VALUE

Returns a boolean value: C<true> if the deletion was successful, otherwise
C<false>.

=cut
