package Punk::Plugin::Blob;

use 5.010;
use strict;
use warnings;
use Punk ();
use Apophis ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Plugin::Blob - content addressed storage for uploads

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'Blob' => { root      => '/var/lib/app/blobs',
                       namespace => 'myapp' };

    post '/avatar' => sub {
        my ($c) = @_;
        my $id = $c->blob_put($c->upload('file'));
        $c->model('User')->update($c->user->{id}, { avatar => $id });
        $c->json({ id => $id });
    };

    get '/blob/:id' => sub { $_[0]->blob_send($_[0]->param('id')) };

=head1 DESCRIPTION

This stores bytes by their contents, on L<Apophis>, and hands back an id.

B<The user's filename never becomes a path.> The address is derived from the
contents, so C<../../etc/passwd> as a filename is a string in a metadata
column and nothing more. B<Deduplication is free>: one file uploaded by a
hundred users is stored once. B<Integrity is checkable>, because the name is
the hash.

=head2 An upload is never read into memory to store it

An id derived from the contents means the contents must be read - and reading
them into a scalar to hash them is exactly the copy that L<Punk::Upload> now
avoids by streaming a large part to a temp file.

So an upload that is already a file is hashed where it lies, in 64 KB chunks,
and then B<moved> into the store. Measured, a 128 MiB upload costs 0.2 MiB of
resident memory to store.

The id is the same one the in-memory path produces for the same bytes. It has
to be: were it not, every blob stored before this would be unreachable through
the new path, and that is asserted in the test suite rather than assumed.

The move is a C<rename> when the spill directory and the store share a
filesystem, and a chunked copy when they do not - so put them on the same one.
A B<duplicate moves nothing>: the bytes are already held, so the upload is
left where it is rather than taken away from the caller for no reason.

=head2 Deduplication crosses tenants

Read this before C<namespace> looks like boilerplate.

Two accounts uploading the same file store it once, and a store that finds the
id present returns without writing - measurably faster than one that writes.
So an account can upload a file, time the response, and learn whether another
account already holds that exact file.

For most applications that is uninteresting. For anything where possession of
a document is itself the confidential fact - a legal matter, a diagnosis, a
CV, a leaked document - it is a real disclosure, and the kind that never
appears in a threat model because the deduplication was a performance decision
made somewhere else.

C<namespace> is the control, and it takes either form:

    namespace => 'myapp'                        # one namespace, dedup everywhere
    namespace => sub { 'tenant-' . $_[0]->tenant_id }   # one per tenant

Different namespaces produce different ids for the same content, so a
namespace per tenant makes their ids disjoint and there is nothing to probe
for. The callback receives the context and is resolved per request; the store
it names is built on first use and cached for the life of the worker.

B<The cost is the deduplication between them>: a file held by a thousand
tenants is stored a thousand times. That is the trade, it is yours, and it is
why C<namespace> is required rather than defaulted.

A callback that gives back an empty namespace croaks rather than falling back
to a default, because the default would be somebody else's namespace.

=head3 What namespacing does not do

It makes another tenant's id B<underivable>, not B<unreachable>. Apophis
shards on the id, so every namespace shares one directory tree: an id changes
with the namespace, but where a given id lives does not. Somebody who already
holds an id can still read it.

That is not the hole it looks like - an id is 128 bits and unguessable, and
the thing this closes is deriving one from content you already have. But
whether B<this> request may see B<that> blob is authorisation, and this plugin
does not do authorisation.

=head2 Two different files cannot silently share an id

Apophis identifies content with UUID v5, which is B<SHA-1>, and its C<store>
returns immediately when the id is present without comparing the bytes - the
right optimisation under the assumption content addressing usually carries,
and one SHA-1 has not supported since 2017.

Which would make this possible: craft two colliding files, upload the first so
it is stored and approved, and then anybody who uploads the second is handed a
reference that serves the first.

So B<a deduplication hit reads the stored blob and compares it>. Equal is the
ordinary case and costs one read. Unequal croaks, because it cannot be
resolved: the store holds one of the two files and either answer is wrong for
somebody.

=head2 A blob is served as a download

An uploader controls the bytes B<and> claims the type. Serving those bytes
back as the claimed type is stored cross-site scripting with this
application's origin on it, and it is the commonest way a file-upload feature
becomes a vulnerability. So C<blob_send> defaults to the unfriendly answer:

    Content-Type: application/octet-stream
    Content-Disposition: attachment
    X-Content-Type-Options: nosniff

C<nosniff> matters as much as the type. Without it a browser may sniff HTML
out of a response labelled C<octet-stream> and render it anyway, so this
helper sets it always and offers no way to turn it off.

Anything friendlier is a decision made out loud, and a type that came from
what a client claimed at upload time goes through the allowlist first:

    my $t = $c->blob_safe_type($row->{content_type});
    return $t ? $c->blob_send($id, type => $t, inline => 1)
              : $c->blob_send($id);

B<SVG is not on that allowlist>, which is the whole reason there is a list
rather than a C<< /^image\// >> test: an SVG is a document that can carry
script, and it passes every naive image check ever written. Neither is
C<application/pdf>.

=head2 Caching, and who may keep it

    Cache-Control: private, max-age=31536000, immutable

A content-addressed URL cannot come to mean anything else, so the lifetime is
right. B<Private by default>, because C<public> on a blob behind authorisation
tells a shared cache it may hand somebody's document to the next person who
asks. C<< public => 1 >> says otherwise.

=head2 Deleting a blob

Deduplication means several rows may reference one blob, so C<blob_remove>
unlinks bytes that another row may still name. It is here for an application
that knows that cannot happen - one namespace per tenant, or one reference per
blob by construction - and it is the wrong default for everything else.

The sanctioned path is a sweep: nothing unlinks during a request, and a
maintenance pass asks the application which ids are still referenced.

    my ($removed, $kept) = Punk::Plugin::Blob->sweep($app,
        live  => sub { MyApp->model('Attachment')->all_blob_ids },
        grace => 3600,
    );

B<An answer that failed is not an answer that there are no blobs.> A C<live>
callback that dies, or returns nothing, aborts the sweep and unlinks nothing -
because acting on it would unlink the entire store. C<< allow_empty => 1 >>
is how an application says, in as many words, that it really does reference
none.

C<grace> is the other guard: a blob younger than it is never collected, so a
file written between the caller's snapshot of live ids and the walk is not
taken before its row is committed. Anything not shaped like a blob id is left
alone, because a sweep that removes what it does not recognise eventually
removes something that mattered.

=head2 What this is not

B<It does not make large uploads possible.> L<Punk::Upload> is explicit that
an upload arrives whole in memory twice before a handler sees it, and nothing
here changes that. This makes storage sane, not ingestion.

B<It is not authorisation.> Whether this request may see this blob is
C<auth_guard>'s question and your model's.

=head1 OPTIONS

=head2 root

Required. Where the blobs live.

=head2 namespace

Required, and not boilerplate - see L</"Deduplication crosses tenants">.

A string is one namespace for the application. A coderef receives the context
and is resolved per request, so a namespace per tenant is:

    namespace => sub { 'tenant-' . $_[0]->tenant_id }

The store a namespace names is built on first use and cached for the life of
the worker. Giving back an empty namespace croaks rather than falling back to
a default.

=head1 HELPERS

=head2 $c->blob_put($upload | \$bytes | $bytes)

Stores the content and returns its id, comparing on a deduplication hit.

=head2 $c->blob_send($id, %options)

A finished download response through C<< $c->send_file >>, so ranges, ETags,
C<304>s, C<HEAD> and the sendfile path all work and the bytes never enter
Perl. Options are C<send_file>'s, plus C<< public => 1 >>.

An id that is not an id is a C<404> rather than an error: it came out of a
URL, so something probing C</blob/../..> is told there is nothing there
instead of filling the error log. A well-formed id naming no blob is a C<404>
too.

=head2 $c->blob_safe_type($claimed)

The claimed type if a blob may be served inline as it, otherwise C<undef>.

=head2 $c->blob_exists($id) / $c->blob_path($id) / $c->blob_remove($id)

Whether it is there; its on-disk path; and an immediate unlink - which
C<blob_path> croaks for a bad id where C<blob_send> answers C<404>, because a
program calls it deliberately.

=head2 $c->blob_store / $c->blob_root

The underlying L<Apophis> object, and the store root. With a coderef
C<namespace> the store is the one this request resolved to, not a single
application-wide object.

=head1 METHODS

=head2 Punk::Plugin::Blob->sweep($app_or_root, live => sub {...}, %opts)

Removes unreferenced blobs. See L</"Deleting a blob">.

=head2 Punk::Plugin::Blob->safe_inline_type($claimed)

The class-method form of C<< $c->blob_safe_type >>.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin>, L<Apophis>, L<Punk::Upload>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
