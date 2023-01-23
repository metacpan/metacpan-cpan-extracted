use strict; use warnings;

package SQL::PatchDAG;
our $VERSION = '0.110';

use File::Spec ();
use Fcntl ();

sub new {
	my $class = shift;
	my $self = bless { binmode => ':unix', patches => {}, @_ }, $class;
	my @applied = @{ delete $self->{'applied'} || [] };
	@{ $self->{'applied'} }{ @applied } = ();
	$self;
}

sub deps_of { @{ $_[0]{'patches'}{ $_[1] } } }
sub patches { sort keys %{ $_[0]{'patches'} } }
sub applied { sort keys %{ $_[0]{'applied'} } }

sub dir             { $_[0]{'dir'} }
sub binmode :method { $_[0]{'binmode'} }
sub readdir :method {
	my $dir = shift->dir;
	opendir my $dh, $dir or die "Couldn't open directory '$dir': $!\n";
	File::Spec->no_upwards( sort readdir $dh );
}
sub open :method {
	my ( $self, $name, $do_rw ) = ( shift, @_ );
	die "Bad patch name '$name'\n" if $name !~ /\A[a-z0-9_][a-z0-9_-]*\z/;
	my $fn = File::Spec->catfile( $self->dir, "$name.sql" );
	my $mode = $do_rw ? Fcntl::O_RDWR() | Fcntl::O_CREAT() : Fcntl::O_RDONLY();
	my $fh; eval q{ use open IO => $self->binmode; sysopen $fh, $fn, $mode }
		or die "Couldn't open '$fn': $!\n";
	( $fn, $fh );
}

sub from {
	my ( $class, $dir ) = ( shift, shift );
	my $self = $class->new( @_, dir => $dir );
	my @entry = $self->readdir;

	for my $name ( map /(.*)\.sql\z/s, @entry ) {
		my ( $fn, $fh ) = $self->open( $name );
		if ( eof $fh ) { warn "Ignoring empty patch '$fn'\n"; next }
		my $dep = readline $fh;
		$dep =~ s/^-- preceding-patch(?:es)? =(?=(?: \S+)+$)//
			or die "Bad or missing patch dependecies in '$fn'\n";
		$self->{'patches'}{ $name } = [ grep $name ne $_, split ' ', $dep ];
	}

	my @ignore = $self->grep_unknown( map /(.*)\.ignore\z/s, @entry );
	delete @{ $self->{'applied'} }{ @ignore };

	$self;
}

sub grep_unknown   { my $self = shift; grep !exists $self->{'patches'}{ $_ }, @_ }
sub grep_unapplied { my $self = shift; grep !exists $self->{'applied'}{ $_ }, @_ }

sub die_if_not_matching {
	my ( $self, $skip_missing ) = ( shift, @_ );
	my @prob;
	if ( my @u =                      $self->grep_unknown  ( $self->applied ) ) { push @prob, "extraneous: @u" }
	if ( my @u = $skip_missing ? () : $self->grep_unapplied( $self->patches ) ) { push @prob, "missing: @u" }
	( not @prob ) or die sprintf "Database schema does not match patches (%s)\n", join '; ', @prob;
}

sub get_next_unapplied {
	my $self = shift;

	$self->die_if_not_matching( 'skip_missing' );
	( my @missing = $self->grep_unapplied( $self->patches ) ) or return;

	for my $name ( @missing ) {
		if ( not $self->grep_unapplied( $self->deps_of( $name ) ) ) {
			$self->{'applied'}{ $name } = undef;
			my ( $fn, $fh ) = $self->open( $name );
			return ( $name, $fn, do { local $/; readline $fh } );
		}
	}

	die "All missing patches have unsatisfied dependencies: @missing\n";
}

sub create {
	my ( $self, $name, $do_recreate ) = ( shift, @_ );
	my $patches = $self->{'patches'};

	die sprintf "Patch '%s' %s\n", $name, $do_recreate ? 'does not exist' : 'already exists'
		if exists $patches->{ $name } xor !!$do_recreate;

	my ( $fn, $fh ) = $self->open( $name, 'rw' );
	my @content = "\n/* remove this comment and put your DDL statements and other SQL here */\n";

	if ( $do_recreate ) {
		@content = readline $fh;
		shift @content if @content and $content[0] =~ m!^-- preceding-patch(?:es)? = !;
		delete $patches->{ $name };
	}

	my %depended = map +( $_, undef ), map @$_, values %$patches;
	my @dep = sort grep !exists $depended{ $_ }, keys %$patches;
	$patches->{ $name } = \@dep;

	@dep = $name if not @dep;
	seek $fh, 0, 0;
	print $fh "-- preceding-patches = @dep\n", @content;
	truncate $fh, tell $fh;

	$fn;
}

sub run {
	my $self = shift;

	my ( $fn )
		= @_ == 1 && $_[0] !~ /^-/ ? $self->create( $_[0] )
		: @_ == 2 && $_[0] eq '-r' ? $self->create( $_[1], 'recreate' )
		: @_ == 2 && $_[0] eq '-e' ? $self->open( $_[1] )
		: die "usage: $0 [ -r | -e ] <patchname>\n";

	die "No editor to run, EDITOR environment variable unset\n"
		if do { no warnings 'uninitialized'; '' eq $ENV{'EDITOR'} };

	$self->_exec( $ENV{'EDITOR'}, $fn );
}

sub _exec { shift; exec { $_[0] } @_ }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::PatchDAG - A minimal DB schema patch manager

=head1 SYNOPSIS

=head2 Code

 use DBI;
 use SQL::PatchDAG;
 my $dbh = DBI->connect( ... );

 # setup:
 my $applied = $dbh->selectcol_arrayref( 'SELECT name FROM schemapatch' );
 my $patches = SQL::PatchDAG->from( 'patches', applied => $applied );

 # consistency check prior to application start:
 $patches->die_if_not_matching;

 # application of missing patches:
 while ( my ( $name, $fn, $sql ) = $patches->get_next_unapplied ) {
   print $fn, "\n";
   $dbh->begin_work;
   $dbh->do( $sql );
   $dbh->do( 'INSERT INTO schemapatch (name) VALUES (?)', undef, $name );
   $dbh->commit;
 }

 # helper script for creating new patches:
 $patches->run( @ARGV );

=head2 F<patches/schemapatch.sql>

 -- preceding-patches = schemapatch
 CREATE TABLE schemapatch ( name VARCHAR(255) PRIMARY KEY );

=head1 DESCRIPTION

This module manages a directory containing SQL files that must be run in
a particular order.
This order is specified implicitly by the contents of the files: each of them
must contain a dependency declaration, which the module provides code to help
maintain.
This provides a merge-friendly way to introduce schema patches in a code base
across multiple branches.

Patch application itself is up the caller.
The module does not talk to a database.

=head1 INTERFACE

=head2 C<new>

Takes a list of key/value pairs and returns an instance with that configuration.

Typically you will use the C<from> constructor rather than calling C<new> directly.

The following parameters are available:

=over 2

=item C<dir>

The name of the directory containing the SQL files.

=item C<binmode>

The L<C<binmode>|perlfunc/binmode> to apply to filehandles when opening patch files.

Defaults to C<:unix>.

=item C<applied>

A reference to an array listing the names of the patches which have been applied.

Defaults to an empty array.

=item C<patches>

A reference to hash of arrays, in which each key is the name of a known patch
and its value is the list of patches it depends on.

Defaults to an empty hash.

=back

=head2 C<from>

Takes a directory name and a set of key/value pairs and returns an instance
with that configuration.
It will read the directory and parse the dependencies from each SQL file to
populate the set of known patches.

Patches are expected to be have an F<.sql> extension.
The full basename of a patch is taken as its patch name.

Additionally, the directory may contain files with an F<.ignore> extension,
which is a convenience feature for switching branches during development.
Normally if you create and apply a patch on one branch and then switch to
another branch, your application will no longer start because the database
contains a patch which is not in the patch directory on that branch.
This is annoying if the application would work (mostly when the patch makes
no incompatible changes to your schema and only adds things to it).
To allow the application to start despite having applied the patch,
you can create an ignore file with the same basename as the patch.
When L</C<from>> finds such a file, an extraneous patch of the same name
will be ignored rather than causing an error.
(It is a good idea to add F<patches/*.ignore> to your VCS ignore file
to avoid accidentally committing these files.)

=head2 C<die_if_not_matching>

Throws an error if the sets of applied and known patches are not the same.

=head2 C<get_next_unapplied>

Returns either the name, filename and contents of the next patch to apply,
or the empty list if there is no patch to apply.

Throws an error if there are extraneous patches.

=head2 C<create>

Takes the name of a patch to create
and a flag indicating whether to recreate an existing patch.
Returns the path to the (re)created patch file.

An appropriate dependency declaration is computed and written to the file
automatically.

When creating a new patch, the patch must not exist.

When recreating an existing patch, the patch must exist.
Its dependecies are recomputed as if the patch had not existed and are
rewritten to the file, but the rest of its contents is preserved.

=head2 C<run>

Takes a list of paramters, and either calls L</C<open>> or L</C<create>>
accordingly and then L<C<exec>|perlfunc/exec>s C<$EDITOR> on the path returned,
or else outputs a usage message and exits.

You would normally pass C<@ARGV> to this method.

=head2 C<patches>

Returns the list of known patches.

=head2 C<applied>

Returns the list of applied patches.

=head2 C<grep_unknown>

Takes and returns a list of patch names, filtering out the ones which
have been found in the patch directory.

=head2 C<grep_unapplied>

Takes and returns a list of patch names, filtering out the ones which
have already been applied.

=head2 C<deps_of>

Takes a patch name and returns its dependencies as a list.

=head2 C<dir>

Returns the value of the C<dir> attribute.

=head2 C<binmode>

Returns the value of the C<binmode> attribute.

=head2 C<readdir>

Reads the patch directory and returns its contents as a list.

=head2 C<open>

Takes the name of a patch to open
and a flag indicating whether to open it read-only or read/write.
Returns the path to the patch
and a filehandle with the configured C<binmode> applied.

The filename must consist of only C<[a-z0-9_-]>
and may not begin with a C<[-]>.

When opening a patch read-only, it must already exist;
when opening it read-write, it may be created.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
