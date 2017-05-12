package Search::InvertedIndex;

# $RCSfile: InvertedIndex.pm,v $ $Revision: 1.31 $ $Date: 2000/01/25 19:53:26 $ $Author: snowhare $

use strict;
use Carp;
use Class::NamedParms;
use Class::ParmList qw (simple_parms parse_parms);
use Search::InvertedIndex::AutoLoader;
use vars qw (@ISA $VERSION);

@ISA     = qw(Class::NamedParms);
$VERSION = '1.14';

# Used to catch attempts to open the same -map
# to multiple objects simultaneously and to
# store the object refs for the map databases.

my $open_maps = {};

# DATABASE SECTIONING CONSTANTS.
my $DATABASE_STRINGIFIER      = 'stringifier';
my $DATABASE_VERSION          = 'database_version';
my $DATABASE_FIX_LEVEL        = 'database_fix_level';

my $INDEX                     = 'i_';
my $INDEX_ENUM                = 'ie_';
my $INDEX_ENUM_DATA           = 'ied_';

my $GROUP                     = 'g_';
my $GROUP_ENUM                = 'ge_';
my $GROUP_ENUM_DATA           = 'ged_';
my $INDEXED_KEY_LIST          = '_a_';
my $INDEX_ENUM_GROUP_CHAIN    = '_b_';
my $KEYED_INDEX_LIST          = '_c_';
my $KEY_TO_KEY_ENUM           = '_d_';
my $KEY_ENUM_TO_KEY_AND_CHAIN = '_e_';

my $PRELOAD_GROUP_ENUM_DATA   = 'pged_';
my $UPDATE_GROUP_COUNTER      = '_a_';
my $UPDATE_DATA               = '_b_';
my $UPDATE_SORTBLOCK_A        = '_c_';
my $UPDATE_SORTBLOCK_B        = '_d_';
my $UPDATE_GROUP_PREFIX_NAME  = '09a2184 xjkjeru 827i^131 mqwj;z';

my $NULL_ENUM                 = '-' x 12;
my $ZERO_ENUM                 = '0' x 12;

####################################################################
# _pack_list($hash_ref);
#
# Internal method. Not for access outside of the module.
#
# Packs the passed hash ref of enum keys and signed 16 bit int values
# into a dense binary structure. There is an endian dependancy
# here.
#

sub _pack_list {
#	my ($hash_ref) = @_;

	my @data_list = %{$_[0]};
	return '' if (@data_list == 0);
	my $list_length = int (@data_list / 2);
	pack ("H12s" x $list_length,@data_list);
}

####################################################################
# _unpack_list($packed_list);
#
# Internal method. Not for access outside of the module.
#
#Unpacks the passed dense binary structure into
#an anonymous hash of enum keys and signed 16 bit int values.
#There is an endian dependancy here.
#

sub _unpack_list {
	my ($bin_pack) = @_;

#	if (not defined $bin_pack) {
#		croak (__PACKAGE__ . "::_unpack_list() - did not pass a binary structure for unpacking\n");
#	}

	my $list_length = length($bin_pack)/8;
	my $hash_ref    = {};
	return {} if ($list_length == 0);
	%$hash_ref        = unpack("H12s" x $list_length,$bin_pack);
	return $hash_ref;
}

=head1 NAME

Search::InvertedIndex - A manager for inverted index maps

=head1 SYNOPSIS

   use Search::InvertedIndex;

   my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new({
			  -map_name => '/www/search-engine/databases/test-maps/test',
				 -multi => 4,
			 -file_mode => 0644,
			 -lock_mode => 'EX',
		  -lock_timeout => 30,
		-blocking_locks => 0,
			 -cachesize => 1000000,
		 -write_through => 0,
	   -read_write_mode => 'RDWR';
		 });

   my $inv_map = Search::Inverted->new({ -database => $database });

 ##########################################################
 # Example Update
 ##########################################################

   my $index_data = "Some scalar - complex structure refs are ok";

   my $update = Search::InvertedIndex::Update->new({
							    -group => 'keywords',
							    -index => 'http://www.nihongo.org/',
							     -data => $index_data,
							     -keys => {
							                 'some' => 10,
							               'scalar' => 20,
							              'complex' => 15,
							            'structure' => 15,
							                 'refs' => 15,
							                  'are' => 15,
							                   'ok' => 15,
							              },
							              });
   my $result = $inv_map->update({ -update => $update });

 ##########################################################
 # Example Query
 # '-nodes' is an anon list of Search::InvertedIndex::Query
 # objects (this allows constructing complex booleans by
 # nesting).
 #
 # '-leafs' is an anon list of Search::InvertedIndex::Query::Leaf
 # objects (used for individual search terms).
 #
 ##########################################################

   my $query_leaf1 = Search::InvertedIndex::Query::Leaf->new({
							               -key => 'complex',
							             -group => 'keywords',
							            -weight => 1,
							            });

   my $query_leaf2 = Search::InvertedIndex::Query::Leaf->new({
							               -key => 'structure',
							             -group => 'keywords',
							            -weight => 1,
							            });
   my $query_leaf3 = Search::InvertedIndex::Query::Leaf->new({
							               -key => 'gold',
							             -group => 'keywords',
							            -weight => 1,
							            });
   my $query1 = Search::InvertedIndex::Query->new({
					  -logic => 'and',
					 -weight => 1,
					  -nodes => [],
					  -leafs => [$query_leaf1,$query_leaf2],
				   });
   my $query2 = Search::InvertedIndex::Query->new({
					  -logic => 'or',
					 -weight => 1,
					  -nodes => [$query1],
					  -leafs => [$query_leaf3],
				   });

   my $result = $inv_map->search({ -query => $query2 });

 ##########################################################

   $inv_map->close;

=head1 DESCRIPTION

Provides the core of an inverted map based search engine. By
mapping 'keys' to 'indexes' it provides ultra-fast look ups
of all 'indexes' containing specific 'keys'. This produces
highly scalable behavior where thousands, or even millions
of records can be searched extremely quickly.

Available database drivers are:

 Search::InvertedIndex::DB::DB_File_SplitHash
 Search::InvertedIndex::DB::Mysql

Check the POD documentation for each database driver to
determine initialization requirements.

=head1 CHANGES

 1.00 1999.06.16 - Initial release

 1.01 1999.06.17 - Documentation fixes and fix to 'close' method in
				   Search::InvertedIndex::DB::DB_File_SplitHash

 1.02 1999.06.18 - Major bugfix to locking system.
				   Performance tweaking. Roughly 3x improvement.

 1.03 1999.06.30 - Documentation fixes.

 1.04 1999.07.01 - Documentation fixes and caching system bugfixes.

 1.05 1999.10.20 - Altered ranking computation on search results

 1.06 1999.10.20 - Removed 'use attrs' usage to improve portability

 1.07 1999.11.09 - "Cosmetic" changes to avoid warnings in Perl 5.004

 1.08 2000.01.25 - Bugfix to 'Search::InvertedIndex::DB:DB_File_SplitHash' submodule
				   and documentation additions/fixes

 1.09 2000.03.23 - Bugfix to 'Search::InvertedIndex::DB:DB_File_SplitHash' submodule
				   to manage case where 'open' is not performed before close is called.

 1.10 2000.07.05 - Delayed loading of serializer and added option to select
				   which serializer (Storable or Data::Dumper) to use at instance 'new' time.
				   This should allow module to be loaded by mod_perl via the 'PerlModule'
				   conf directive and enable use on platforms that do not support
				   'Storable' (such as Macintosh).

 1.11 2000.11.29 - Added 'Search::InvertedIndex::DB::Mysql' (authored by
				   Michael Cramer <cramer@webkist.com>) database driver
				   to package.

 1.12 2002.04.09 - Squashed bug in removal of an index from a group when the index doesn't
				   exist in that group that caused index counts for the group to be decremented
				   in error.

 1.13 2003.09.28 - Interim release. Fixed false error return from 'first_key_in_group' for a group
                   that has not yet had any keys set.  Tightened calling
                   parm parses. Tweaked performance of preload updating code.
                   Added taint fix for stringifier identifier.
                   This release was driven by the taint issue and code bug as crisis items.
                   Hopefully a 1.14 release will be in the not too distant future.

 1.14 2003.11.14 - Patch to the MySQL database driver to accomodate changes in DBD::mysql.
                   Addition of a test for MySQL functionality. Patch and test thanks to
                   Kate L Pugh.

=head2 Public API

=cut

####################################################################

=over 4

=item C<new({ -database =E<gt> $database_object [,'-search_cache_size' =E<gt> 1000, -search_cache_dir =E<gt> '/var/tmp/search_cache', -stringifier =E<gt> ['Storable','Data::Dumper'],  ] });>

Provides the interface for obtaining a new Search::InvertedIndex
object for manipulating a inverted database.

Example 1:

 my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new({
			 -map_name => '/www/databases/test-map_names/test',
				-multi => 4,
			-file_mode => 0644,
			-lock_mode => 'EX',
		 -lock_timeout => 30,
	   -blocking_locks => 0,
			-cachesize => 1000000,
		-write_through => 0,
	  -read_write_mode => 'RDONLY',
		});

 my $inv_map = Search::InvertedIndex->new({
				'-database' => $database,
	   '-search_cache_size' => 1000,
		'-search_cache_dir' => '/var/tmp/search_cache',
			   -stringifier => ['Storable','Data::Dumper'],
	 });


Parameter explanations:

  -database          - A database interface object. Defined database interfaces
					   are currently Search::InvertedIndex::DB::DB_File_SplitHash
					   and Search::InvertedIndex::DB::Mysql. (Required)

  -stringifier       - Declares the stringifier used to store information in the
					   underlaying database. Currently defined stringifiers are
					   'Storable' and 'Data::Dumper'. The default is to use
					   'Storable' with fallback to 'Data::Dumper'. (Optional)

  -search_cache_size - Sets the number of cached searched to hold in the search cache (Optional)

  -search_cache_dir  - Sets the directory to be used for the search cache
					   (Required if search_cache_size is set to something other than 0)

The -database parameter is required and must be a 'Search::InvertedIndex::DB::...'
type database object. The other two parameters are optional and define the
location and size of the search cache. If omitted, no search caching will be done.

The optional '-stringifier' parameter can be used to override the default
use of 'Storable' (with fallback to 'Data::Dumper') as the stringifier used
for storing data by the module. Specifiying -stringifier => 'Data::Dumper'
would specify using 'Data::Dumper' (only) as the stringifier while
specifiying -stringifier => ['Data::Dumper','Storable'] would specify
to use Data::Dumper by preference (but to fall back to 'Storable' if Data::Dumper
was not available). If a database was created using a particular serializer,
it will automatically detect it and attempt to use the correct one.

=back

=cut

sub new {
	my $proto   = shift;
	my $package = __PACKAGE__;
	my $class   = ref ($proto) || $proto || $package;
	my $self    = Class::NamedParms->new(qw (-database  -thaw  -freeze  -stringifier));
	bless $self,$class;

	# Check the passed parms and set defaults as necessary
	my $parms = parse_parms({ -parms => \@_,
							  -legal => ['-search_cache_size', '-search_cache_dir'],
						   -required => ['-database'],
						   -defaults => { -search_cache_size => 0,
							               -search_cache_dir => undef,
							                    -stringifier => [qw(Storable Data::Dumper)],
							            },
							   });
	   if (not defined $parms) {
		   my $error_message = Class::ParmList->error;
		   croak (__PACKAGE__ . "::new() - $error_message\n");
	}

	my ($database,$search_cache_dir,$search_cache_size,$stringifier) =
			$parms->get(qw (-database -search_cache_dir -search_cache_size -stringifier));

	$stringifier = [$stringifier] if ('ARRAY' ne ref($stringifier));

    $self->search_cache_dir($search_cache_dir);
    $self->search_cache_size($search_cache_size);
	$self->set({ -database => $database, });

	$database->open;
	$self->_select_stringifier(@$stringifier);

#    # auto-fix corrupted group key/index counters
#	my $database_fix_level = $database->get({ -key => $DATABASE_FIX_LEVEL});
#    $database_fix_level    = 0 unless ((defined $database_fix_level) and ($database_fix_level ne ''));
#    my $database_lock_mode = $database->status('-lock_mode');
#    if (($database_lock_mode eq 'EX') and ($database_fix_level < '2')) {
#        if ($database->put({ -key => $DATABASE_FIX_LEVEL, -value => '1' })) {
#            # OK. We are opened EX and writable. Time to fix things
#            require Search::InvertedIndex::FixGroups;
#            # Code here XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#        }
#    }

	return $self;
}

#####################################################################
#
# $self->_select_stringifier(@stringifier_list);
#
# Selects the serializer to use for data serialization in the database
#

sub _select_stringifier {
	my $self = shift;

	my @stringifier = @_;

	my $db    = $self->get(-database);

	# We use whatever the *database* may already have used in preference
	# to any requests for a stringifier. This will prevent wierdness like the database
	# breaking because 'Storable' was installed after it was created
	# using 'Data::Dumper'.This is backward compatible with old databases
	# created with this because old database defaulted to 'Storable'
	my $declared_stringifier = $db->get({ -key => $DATABASE_STRINGIFIER });
	if (defined $declared_stringifier) {
		@stringifier = ($declared_stringifier);
	}

	# We delay the load of stringification modules to here to make it
	# compatible with PerlModule for mod_perl and to allow a choice
	# of stringification modules
	my $have_stringifier;
	foreach my $module_name (@stringifier) {
		if ($module_name !~ m/^(Storable|Data::Dumper)$/) {
			croak ('[' . localtime(time) . "] [error] " . __PACKAGE__ .
				"::_select_stringifier() - Stringifier of '$module_name' is not supported.");
		}
        my $untainted_module_name = $1;
		eval "use $untainted_module_name;";
		next if ($@);
		$have_stringifier = $untainted_module_name;
		last;
	}
	if (not defined $have_stringifier) {
			croak('[' . localtime(time) . "] [error] " . __PACKAGE__ .
				"::_select_stringifier() - Unable to load stringification modules. Tried: " . join (' ',@stringifier));
	}
	my ($thaw,$freeze);
	if ($have_stringifier eq 'Storable') {
		$thaw   = \&Storable::thaw;
		$freeze = \&Storable::nfreeze;
	} elsif ($have_stringifier eq 'Data::Dumper') {
		my $dumper = Data::Dumper->new(['blecherous']);
		$thaw   = sub { my $value = shift;
						local $^W;
						no strict 'vars';
						my $thawed = eval $value;
						return $thawed; };
		if ($dumper->can('Dumpxs')) {
			$freeze = sub { my $value = shift;
							local $Data::Dumper::Purity = 1;
							local $Data::Dumper::Indent = 0;
							my $frozen = Data::Dumper::DumperX($value);
							return $frozen; };
		} else {
			$freeze = sub { my $value = shift;
							local $Data::Dumper::Purity = 1;
							local $Data::Dumper::Indent = 0;
							my $frozen = Data::Dumper::Dumper($value);
							return $frozen; };

		}
	} else {
			croak('[' . localtime(time) . "] [error] " . __PACKAGE__ .
				"::_select_stringifier() - Unsupported stringification module ($have_stringifier)");

	}

	# This may well fail if the database was opened read only. We don't care if it does.
	# A silent failure is *ok*.
	if ((not defined $declared_stringifier) and ('EX' eq $db->status('-lock_mode'))) {
		$db->put({ -key => $DATABASE_STRINGIFIER, -value => $have_stringifier });
		my $database_version = $db->get({ -key => $DATABASE_VERSION });
		if (not defined $database_version) {
			$db->put({ -key => $DATABASE_VERSION, -value => $VERSION });
		}
	}

	$self->set({
					 -thaw => $thaw,
				   -freeze => $freeze,
			 });
}

####################################################################

=over 4

=item C<lock({ -lock_mode => 'EX|SH|UN' [, -lock_timeout => 30] [, -blocking_locks => 0] });>

Changes a lock on the underlaying database.

Forces 'sync' if the stat is changed from 'EX' to a lower lock state
(i.e. 'SH' or 'UN'). Croaks on errors.

Example:

	$inv->lock({ -lock_mode => 'EX' [, -lock_timeout => 30] [, -blocking_locks => 0],
		  });

The only _required_ parameter is the -lock_mode. The other
parameters can be inherited from the object state. If the
other parameters are used, they change the object state
to match the new settings.

=back

=cut

sub lock {
	my $self = shift;
	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::lock() - No database opened for use\n");
	}
	$db->lock(@_);
}

####################################################################

=over 4

=item C<status(-open|-lock_mode);>

Returns the requested status line for the database. Allowed requests
are '-open', and '-lock'.

Example 1:
 my $status = $inv_map->status(-open); # Returns either '1' or '0'

Example 2:
 my $status = $inv_map->status(-lock_mode); # Returns 'UN', 'SH' or 'EX'

=back

=cut

sub status {
	my $self = shift;
	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::status() - No database opened for use\n");
	}
	$db->status(@_);
}

####################################################################

=over 4

=item C<update({ -update =E<gt> $update });>

Performs an update on the map. This is designed for
adding/changing/deleting a bunch of related information
in a single block update.  It takes a
Search::InvertedIndex::Update object as input. It assumes
that you wish to remove all references to the specified index
and replace them with a new list of references. It can also
will update the -data for the -index. If -data is passed
and the -index does not already exist, a new index record
will be created. It is a fatal error to pass a non-existant
index without a -data parm to initialize it. It is also
a fatal error to pass an update for a non-existant -group.

Passing an empty -keys has the effect of deleting the
index from group (but not from the system).

Example:

 my $update = Search::InvertedIndex::Update->new(...);
 $inv_map->update({ -update => $update });

It is much faster to update a index using the update
method than the add_entry_to_group method in most cases
because the batching of changes allows for efficiency
optimizations when there is more than one key.

=back

=cut

sub update {
	my $self = shift;

	my ($update) = simple_parms(['-update'],@_);
	my ($db)     = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::update() - No database opened for use\n");
	}
	my ($index,$index_data,$group,$key_list) = $update->get(qw(-index -data -group -keys));
	if ((not defined $index) or ($index eq '')) {
		croak (__PACKAGE__ . "::update() - No -index set.\n");
	}
	if ((not defined $group) or ($group eq '')) {
		croak (__PACKAGE__ . "::update() - No -group set.\n");
	}
	if (not defined $key_list) {
		$key_list = {};
	}
	my $new_keys = 0;
	while (my ($key,$ranking) = each %$key_list) {
		$ranking = int($ranking+0.5);
		if (($ranking < -32768) or ($ranking > 32767)) {
			croak (__PACKAGE__ . "::update() - Invalid ranking value of '$ranking' for key '$key'. Only values from -32768 to +32767 are allowed\n");
		}
		$new_keys++;
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::update() - Attempted to add an entry to the undeclared -group '$group'\n");
	}

	# Delete the existing -index/-group data
	$self->remove_index_from_group({ -group => $group, '-index' => $index});

	# Create the -index and store the -data record for the -index as needed
	my $index_enum;
	if (defined $index_data) {
		$index_enum = $self->add_index({ '-index' => $index, -data => $index_data });
	} else {
		$index_enum = $db->get({ -key => "$INDEX$index" });
		if (not defined $index_enum) {
			croak(__PACKAGE__ . "::update() - Attempted to add a new index to the system without setting its -data\n");
		}
	}

	# Add keys to the group if needed.
	my $indexed_keys = {};
	while (my ($key,$ranking) = each %$key_list) {
		$ranking = int($ranking+0.5);

		# Add the key to the group, if necessary.
		my $key_enum      = $self->add_key_to_group ({ -group => $group, -key => $key });

		# Add the ranking to the running key_enum indexed record
		$indexed_keys->{$key_enum} = $ranking;

		# Add the index_enum to the list of index_enums for this key_enum
		my $keyed_record  = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
		$keyed_record = '' if (not defined $keyed_record);
		my $keyed_indexes = _unpack_list($keyed_record);
		$keyed_indexes->{$index_enum} = $ranking;
		$keyed_record = _pack_list($keyed_indexes);
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum", -value => $keyed_record })) {
			croak (__PACKAGE__ . "::update() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum' -> (list of ranked indexes)\n");
		}
	}

	# increment the _number_of_indexes counter and create
	# a new INDEXED_KEY_LIST for this index_enum if we
	# assigned new keys for this group for the index
	# This is where we gain a big chunk of our performance advantage from.
	if ($new_keys) {
		my $indexed_record = _pack_list($indexed_keys);
		my $number_of_group_indexes = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" });
		if (not defined $number_of_group_indexes) {
			croak (__PACKAGE__ . "::update () - Database may be corrupt. Failed to locate '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record for group '$group'\n");
		}
		$number_of_group_indexes++;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes", -value => $number_of_group_indexes })) {
			croak (__PACKAGE__ . "::update () - Database may be corrupt. Unable to update '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record to '$number_of_group_indexes' for group '$group'\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum", -value => $indexed_record })) {
			croak (__PACKAGE__ . "::update() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum' -> (list of ranked keys)\n");
		}
	}

	# Update the INDEX_ENUM_GROUP_CHAIN as necessary
	# Check if the index already exists in the group
	my ($chain) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
	if (not defined $chain) {
		# Add the index_enum to the index chain for the group
		my $old_first_index_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
		my $first_index_enum_record = "$NULL_ENUM $NULL_ENUM";
		if (defined ($old_first_index_enum) and ($old_first_index_enum ne $NULL_ENUM)) { # Record formated as: prev next index
			my $old_first_index_enum_record = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum" });
			if (not defined $old_first_index_enum_record) {
				croak (__PACKAGE__ . "::update() - Unable to read '$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum' record. Database may be corrupt.\n");
			}
			$old_first_index_enum_record =~ s/^$NULL_ENUM/$index_enum/;
			if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum",
							 -value => $old_first_index_enum_record, })) {
				croak (__PACKAGE__ . "::update() - Unable to update 'prev' enum reference for '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum'\n");
			}
			$first_index_enum_record = "$NULL_ENUM $old_first_index_enum";
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum", -value => $first_index_enum_record })) {
			croak (__PACKAGE__ . "::update() - Unable to save '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' -> '$first_index_enum_record' to map\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum", -value => $index_enum })) {
			croak (__PACKAGE__ . "::update() - Unable to save '$GROUP_ENUM_DATA${group_enum}_first_index_enum' -> '$index_enum' map entry.\n");
		}
	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;
}

####################################################################

=over 4

=item C<preload_update({ -update =E<gt> $update });>

'preload_update' places the passed 'update' object data into a pending
queue which is not reflected in the searchable database until the
'update_group' method has been called. This allows the
loading process to be streamlined for maximum performance
on large full updates. This method is not appropriate to
incremental updates as the 'update_group' method destroys
the previous searchable data set on execution.

It also places the database effectively offline during the update,
so this is not a suitable method for updating a 'online' database.
Updates should happen on an 'offline' copy that is then swapped
into place with the 'online' database.

Example:

 my $update = Search::InvertedIndex::Update->new(...);
 $inv_map->preload_update({ -update => $update });
		.
		.
		.
 $inv_map->update_group({ -group => 'test' });

=back

=cut

sub preload_update {
	my $self = shift;

	my ($update)     = simple_parms(['-update'],@_);
	my ($db,$freeze) = $self->get(qw(-database -freeze));
	if (not $db) {
		croak (__PACKAGE__ . "::preload_update() - No database opened for use\n");
	}
	my ($index,$index_data,$group,$key_list) = $update->get(qw(-index -data -group -keys));
	if ((not defined $index) or ($index eq '')) {
		croak (__PACKAGE__ . "::preload_update() - No -index set.\n");
	}
	if ((not defined $group) or ($group eq '')) {
		croak (__PACKAGE__ . "::preload_update() - No -group set.\n");
	}
	$key_list = {} if (not defined $key_list);
	my $new_keys = 0;
	while (my ($key,$ranking) = each %$key_list) {
		$ranking = int($ranking+0.5);
		if (($ranking < -32768) or ($ranking > 32767)) {
			croak (__PACKAGE__ . "::preload_update() - Invalid ranking value of '$ranking' for key '$key'. Only values from -32768 to +32767 are allowed\n");
		}
		$new_keys++;
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::preload_update() - Attempted to add an entry to the undeclared -group '$group'\n");
	}

	# Increment the update record counter
	my $update_counter = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$UPDATE_GROUP_COUNTER" });
	if (not defined $update_counter) {
		$update_counter = $ZERO_ENUM;
	}
	$update_counter = $self->_increment_enum($update_counter);
	if (not defined $db->put({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$UPDATE_GROUP_COUNTER",
							 -value => "$update_counter" })) {
		croak(__PACKAGE__ . "::preload_update() - Failed to save incremented UPDATE_GROUP_COUNTER for group '$group'\n");
	}
	my $update_record = &$freeze($update);
	if (not defined $db->put({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$UPDATE_DATA$update_counter",
							 -value => $update_record })) {
		croak(__PACKAGE__ . "::preload_update() - Failed to save preloaded Update record for group '$group'\n");

	}
}

####################################################################

=over 4

=item C<clear_preload_update_for_group({ -group =E<gt> $group });>

This clears all the data from the preload area for the specified
group.

=back

=cut

sub clear_preload_update_for_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::clear_preload_update_for_group() - No database opened for use\n");
	}
	if ((not defined $group) or ($group eq '')) {
		croak (__PACKAGE__ . "::clear_preload_update_for_group() - No -group set.\n");
	}

	# Get the group_enum for this group
	my $original_group      = $group;
	my $original_group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $original_group_enum) {
		croak(__PACKAGE__ . "::clear_preload_update_for_group() - Attempted to clear preload queue for the undeclared -group '$group'\n");
	}
	my $update_counter = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_GROUP_COUNTER" });
	if (not defined $update_counter) {
		return 1;
	}
	my $counter   = $ZERO_ENUM;
	while ($counter lt $update_counter) {
		$counter = $self->_increment_enum($counter);
		if (not $db->delete({ -key => "$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_DATA$counter" })) {
			croak(__PACKAGE__ . "::clear_preload_update_for_group() - Failed to delete record '$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_DATA$counter'\n");
		}
	}

	if (not $db->delete({ -key => "$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_GROUP_COUNTER" })) {
			croak(__PACKAGE__ . "::clear_preload_update_for_group() - Failed to delete record '$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_GROUP_COUNTER'\n");
	}

	1;
}

####################################################################

=over 4

=item C<update_group({ -group =E<gt> $group[, -block_size =E<gt> 65536] });>

This clears the specifed group and loads all
preloaded data (updates batch loaded through
the 'preload_update' method pending finalization.

This is by far the fastest way to load a large set of
data into the search system - but it is an 'all or nothing'
approach. No 'incremental' updating is possible via this
interface - the update_group completely erases all previously
searchable data from the group and replaces it with the
pending 'preload'ed data.

Examples:

  $inv_map->update_group({ -group => 'test' });

  $inv_map->update_group({ -group => 'test', -block_size => 65536 });

-block_size determines the 'chunking factor' used to limit the amount
of memory the update uses (it corresponds roughly to the number of
line entry items to be processed in memory at one time). Higher
'-block_size's will improve performance until you run out of real
memory. The default is 65536.

Since an exclusive lock should be held during the entire process,
the database is essentially inaccessible until the update is
complete. It is probably inadvisable to use this method of
updating without keeping an 'online' and a seperate 'offline'
database and copy over the 'offline' to 'online' after
completion of the mass update on the 'offline' database.

=back

=cut

sub update_group {
	my $self = shift;

	my $parms = parse_parms ({ -parms => \@_,
							   -legal => ['-block_size'],
							-required => ['-group'],
							-defaults => { -block_size => 65536 },
						   });
	if (not defined $parms) {
		my $error_message = Class::ParmList->error;
		croak (__PACKAGE__ . "::update_group() - $error_message\n");
	}
	my ($db,$thaw) = $self->get('-database','-thaw');
	if (not $db) {
		croak (__PACKAGE__ . "::update_group() - No database opened for use\n");
	}
	my ($group,$block_size) = $parms->get(-group,-block_size);
	if ((not defined $group) or ($group eq '')) {
		croak (__PACKAGE__ . "::update_group() - No -group set.\n");
	}
	if ((not defined $block_size) or ($block_size != int ($block_size)) or ($block_size <= 0)) {
		croak (__PACKAGE__ . "::update_group() - Illegal -block_size set: Must be an integer greater than 0.\n");
	}

	# Get the original group_enum for this group
	my $original_group      = $group;
	my $original_group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $original_group_enum) {
		croak(__PACKAGE__ . "::update_group() - Attempted to add an entry to the undeclared -group '$group'\n");
	}

	# Add in the new updated group enum we will use to store the mass update in.
	# The double creation cycle clears any garbage that might have been
	# left from a previous incomplete update
	$group = "$UPDATE_GROUP_PREFIX_NAME$group";
	$self->add_group({ -group => $group });
	$self->remove_group({ -group => $group });
	my $group_enum = $self->add_group({ -group => $group });

	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::update_group() - Failed to create -group '$original_group' update group\n");
	}
	my $update_counter = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_GROUP_COUNTER" });
	my $counter               = $ZERO_ENUM;
	$update_counter           = $counter if (not defined $update_counter);
	my $block_element_counter = 0;
	my $block_data            = [];
	my $block_counter         = 0;
	my $record_size           = 32; # 12+1+12+1+6 (key_enum + ':' + index_enum + ':' + ranking (6 digits with sign))
	while ($counter lt $update_counter) {
		$counter = $self->_increment_enum($counter);
		my $update_record = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$original_group_enum$UPDATE_DATA$counter" });
		my $update = &$thaw($update_record);
		my ($index,$index_data,$alleged_group,$key_list) = $update->get(qw(-index -data -group -keys));
		if (not defined $key_list) {
			$key_list = {};
		}

		# Create the -index and store the -data record for the -index as needed
		my $index_enum;
		if (defined $index_data) {
			$index_enum = $self->add_index({ '-index' => $index, -data => $index_data });
		} else {
			$index_enum = $db->get({ -key => "$INDEX$index" });
			if (not defined $index_enum) {
				croak(__PACKAGE__ . "::update_group() - Attempted to add a new index to the system without setting its -data\n");
			}
		}

		# Add the -index to the update group
		$self->add_index_to_group({ -group => $group, '-index' => $index });

		my $new_keys = 0;
		my $indexed_keys = {};
		while (my ($key,$ranking) = each %$key_list) {
			$new_keys++;

			# Add the key to the group, if necessary.
			my $key_enum = $self->add_key_to_group ({ -group => $group, -key => $key, -database => $db });

			# Add the ranking to the running key_enum indexed record
			$indexed_keys->{$key_enum} = $ranking;

			# Save a record for key sorting
			if ($ranking < 0) {
				$ranking = sprintf('%0.5ld',$ranking);
			} else {
				$ranking = sprintf('+%0.5ld',$ranking);
			}
			my $update_sort_value = "$key_enum:$index_enum:$ranking";
			push (@$block_data,$update_sort_value);
			$block_element_counter++;
			if ($block_element_counter == $block_size) {
				my $update_sort_key    = "$PRELOAD_GROUP_ENUM_DATA$group_enum$UPDATE_SORTBLOCK_A$block_counter";
				my $update_sort_value  = join (' ',reverse sort @$block_data); # Largest 'value' to smallest 'value'
				$block_element_counter = 0;
				$block_data            = [];
				$block_counter++;
				if (not $db->put({ -key => $update_sort_key, -value => $update_sort_value })) {
					croak(__PACKAGE__ . "::update_group() - Failed to save UPDATE_SORTBLOCK_A record '$update_sort_key': size of record " . length($update_sort_value)." $!\n");
				}
			}
		}

		# Create a new INDEXED_KEY_LIST for this index_enum if we
		# assigned new keys for this group for the index
		# This is where we gain a big chunk of our performance advantage from.
		if ($new_keys) {
			my $indexed_record = _pack_list($indexed_keys);
			if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum",
							 -value => $indexed_record })) {
				croak (__PACKAGE__ . "::update_group() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum' -> (list of ranked keys)\n");
			}
		}

		# Update the INDEX_ENUM_GROUP_CHAIN as necessary
		# Check if the index already exists in the group
		my ($chain) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
		if (not defined $chain) {
			# Add the index_enum to the index chain for the group
			my $old_first_index_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
			my $first_index_enum_record = "$NULL_ENUM $NULL_ENUM";
			if (defined ($old_first_index_enum) and ($old_first_index_enum ne $NULL_ENUM)) { # Record formated as: prev next index
				my $old_first_index_enum_record = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum" });
				if (not defined $old_first_index_enum_record) {
					croak (__PACKAGE__ . "::update_group() - Unable to read '$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum' record. Database may be corrupt.\n");
				}
				$old_first_index_enum_record =~ s/^$NULL_ENUM/$index_enum/;
				if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum",
							     -value => $old_first_index_enum_record, })) {
					croak (__PACKAGE__ . "::update_group() - Unable to update 'prev' enum reference for '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum'\n");
				}
				$first_index_enum_record = "$NULL_ENUM $old_first_index_enum";
			}
			if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum", -value => $first_index_enum_record })) {
				croak (__PACKAGE__ . "::update_group() - Unable to save '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' -> '$first_index_enum_record' to map\n");
			}
			if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum", -value => $index_enum })) {
				croak (__PACKAGE__ . "::update_group() - Unable to save '$GROUP_ENUM_DATA${group_enum}_first_index_enum' -> '$index_enum' map entry.\n");
			}
		}
	}

	# Flush any dangling sort data to a record
	if ($block_element_counter) {
		my $update_sort_key    = "$PRELOAD_GROUP_ENUM_DATA$group_enum$UPDATE_SORTBLOCK_A$block_counter";
		my $update_sort_value  = join (' ',reverse sort @$block_data);
		$block_data            = [];
		$block_element_counter = 0;
		$block_counter++;
		if (not $db->put({ -key => $update_sort_key, -value => $update_sort_value })) {
			   croak(__PACKAGE__ . "::update_group() - Failed to save UPDATE_SORTBLOCK_A record '$update_sort_key'\n");
		}
	}

	# Merge sort the record blocks
	my $block_chunk     = 1;
	my $source_blocks   = $UPDATE_SORTBLOCK_B;
	my $target_blocks   = $UPDATE_SORTBLOCK_A;
	my $high_block      = $block_counter;
	# Keep making passes until the number of blocks
	# in a chunk is larger than the number of blocks.
	my $n_passes        = 0;
	my $max_block_bytes = $block_size * ($record_size + 1) - 1;
	while ($high_block > $block_chunk) {
		# Swap the source and target areas
		my $temp_source = $source_blocks;
		$source_blocks  = $target_blocks;
		$target_blocks  = $temp_source;
		$n_passes++;
		my @block_pointer        = (0,$block_chunk);
		my $target_block_counter = 0;
		# Pairwise walk through the blocks in a pass
		while ($block_pointer[0] < $block_counter) { # Merge block pairings
			my @block_offset           = (-1,-1);
			my @running_block_pointer  = ($block_pointer[0] - 1,$block_pointer[1] - 1);
			my @block_data             = (undef,undef);
			my @block_data_length      = (0,0);
			my @running_record_pointer = (1,1);
			my $target_record_offset   = 0;
			my $target_data            = '';
			my $target_size            = 0;
			my @match_data             = (undef,undef);

			# Keep merging blocks until we exhaust the chunk we are looking at
			my $chunk_done = 0;
			until ($chunk_done) {
				# Load blocks as needed to keep the merge lists filled with records
				foreach my $half (0..1) {
					if ($running_record_pointer[$half] >= $block_data_length[$half]) {
						$block_offset[$half]++;
						$running_block_pointer[$half]++;
						if (($block_offset[$half] < $block_chunk) and ($running_block_pointer[$half] < $block_counter)) {
							$block_data[$half] = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$source_blocks$running_block_pointer[$half]" });
							$block_data_length[$half] = length ($block_data[$half]);
							$running_record_pointer[$half] = 0;
						} else { # out of data for this half
							$block_data[$half]        = undef;
							$block_data_length[$half] = 0;
							$running_record_pointer[$half] = -1;
						}
					}
				}
				# If there is no data pending for either side, we have finished the chunk.
				if (not (defined ($block_data[0]) or defined ($block_data[1]))) {
					$chunk_done = 1;
					last;
				}

				if ($target_record_offset == 0) {
					$target_size = ($block_data_length[0] - $running_record_pointer[0]) +
							          ($block_data_length[1] - $running_record_pointer[1]);
					$target_size = $max_block_bytes if ($target_size > $max_block_bytes);
					$target_data = ' ' x $target_size;
				}

				# Do the actual merging of the two data blocks
				# Question: At typical block sizes, would it be faster
				# to use the built in sort over the item by item merge?
				# It it worth the substantial memory trade-off?
				while (($running_record_pointer[0] < $block_data_length[0]) and
					   ($running_record_pointer[1] < $block_data_length[1])) {
					$match_data[0] = ($block_data_length[0] and ($block_data_length[0] > $running_record_pointer[0])) ? substr($block_data[0],$running_record_pointer[0],$record_size) : '';
					$match_data[1] = ($block_data_length[1] and ($block_data_length[1] > $running_record_pointer[1])) ? substr($block_data[1],$running_record_pointer[1],$record_size) : '';
					if ($match_data[0] ge $match_data[1]) {
						substr($target_data,$target_record_offset,$record_size) = $match_data[0];
						$running_record_pointer[0] += $record_size + 1;
					} else {
						substr($target_data,$target_record_offset,$record_size) = $match_data[1];
						$running_record_pointer[1] += $record_size + 1;
					}
					$target_record_offset += $record_size + 1;
					if ($target_record_offset >= $target_size) { # We've filled the target block. Save it and start a new one.
						if (not $db->put({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$target_block_counter",
							             -value => $target_data })) {
							croak (__PACKAGE__ . "::update_group() - Unable to save sort record to '$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$target_block_counter'\n");
						}
						$target_block_counter++;
						$target_size = ($block_data_length[0] - $running_record_pointer[0]) +
							      ($block_data_length[1] - $running_record_pointer[1]);
						$target_size = $max_block_bytes if ($target_size > $max_block_bytes);
						$target_size = 0 if ($target_size < 0);
						$target_data = ' ' x $target_size;
						$target_record_offset = 0;
					}
				}
			}
			if ($target_record_offset) { # We have an unsaved target block. Save it.
				if (not $db->put({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$target_block_counter",
							     -value => $target_data })) {
					croak (__PACKAGE__ . "::update_group() - Unable to save sort record to '$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$target_block_counter'\n");
				}
			}
			$block_pointer[0] += 2 * $block_chunk;
			$block_pointer[1] += 2 * $block_chunk;
		}
		# Double the block chunk size
		$block_chunk *= 2;
	}
	# The current 'target_blocks' holds the fully sorted records
	# Extract the 'sets' of KEYED_INDEX_DATA and save them.
	my $current_key_enum     = $NULL_ENUM;
	my $current_block_number = 0;
	my $current_key_data     = {};
	my $dirty_counter        = 0;
	while ($current_block_number < $block_counter) {
		my $block_data = $db->get({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$current_block_number"});
		if (not defined $block_data) {
			croak (__PACKAGE__ . "::update_group() - Unable to load block '$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$current_block_number'\n");

		}

		my (@key_records) = split (/ /,$block_data);
		for (my $count=0; $count<= $#key_records; $count++) {
			my ($key_enum,$index_enum,$ranking) = split(/:/,$key_records[$count],3);
			if ($key_enum ne $current_key_enum) {
				if ($current_key_enum ne $NULL_ENUM) {
					my $keyed_index_record = _pack_list($current_key_data);
					if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$current_key_enum" ,
							         -value => $keyed_index_record })) {
						croak (__PACKAGE__ .. "::update_group() - Unable to save KEYED_INDEX_LIST record ''\n");
					}
				}
				$current_key_data = {};
				$current_key_enum = $key_enum;
				$dirty_counter    = 0;
			}
			$current_key_data->{$index_enum} = $ranking;
			$dirty_counter++;
		}


		# delete the sorted blocks from the database as we go
		$db->delete({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$target_blocks$current_block_number"} );
		if ($n_passes) {
			$db->delete({ -key => "$PRELOAD_GROUP_ENUM_DATA$group_enum$source_blocks$current_block_number"} );
		}
		$current_block_number++;
	}

	# Save the final key_enum set, if needed
	if ($dirty_counter and ($current_key_enum ne $NULL_ENUM)) {
		my $keyed_index_record = _pack_list($current_key_data);
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$current_key_enum",
						 -value => $keyed_index_record })) {
			croak (__PACKAGE__ .. "::update_group() - Unable to save KEYED_INDEX_LIST record ''\n");
		}
	}

	# clear the preload_update for the group
	$self->clear_preload_update_for_group({ -group => $original_group });

	# Fast swap the newly created database with the original database via pointer magic
	my $original_group_enum_record = $db->get({ -key => "$GROUP_ENUM$original_group_enum" });
	$original_group_enum_record =~ s/^(.{12}) (.{12}) (.*)$/$1 $2 $group/s;
	my $new_group_enum_record = $db->get({ -key => "$GROUP_ENUM$group_enum" });
	$new_group_enum_record =~ s/^(.{12}) (.{12}) (.*)$/$1 $2 $original_group/s;
	$db->put({ -key => "$GROUP$original_group", -value => $group_enum });
	$db->put({ -key => "$GROUP_ENUM$group_enum", -value => $new_group_enum_record });
	$db->put({ -key => "$GROUP$group", -value => $original_group_enum });
	$db->put({ -key => "$GROUP_ENUM$original_group_enum", -value => $original_group_enum_record });

	# remove the original database
	$self->remove_group({ -group => $group });

	   # We don't want the cache returning old info after an update
	   $self->clear_cache;
}

####################################################################

=over 4

=item C<search({ -query =E<gt> $query [,-cache =E<gt> 1] });>

Performs a query on the map and returns the results as a
Search::InvertedIndex::Result object containing the keys and rankings.

Example:

 my $query = Search::InvertedIndex::Query->new(...);
 my $result = $inv_map->search({ -query => $query });

Performs a complex multi-key match search with boolean logic and
optional search term weighting.

The search request is formatted as follows:

my $result = $inv_map->search({ -query => $query });

where '$query' is a Search::InvertedIndex::Query object.

Each node can either be a specific search term with an optional weighting
term (a Search::InvertedIndex::Query::Leaf object) or a logic term with
its own sub-branches (a Search::Inverted::Query object).

The weightings are applied to the returned matches for each search term by
multiplication of their base ranking before combination with the other logic terms.

This allows recursive use of search to resolve arbitrarily
complex boolean searches and weight different search terms.

The optional -cache parameter instructs the database to cache (
if the -search_cache_dir and -search_cache_size initialization
parameters are configured for use) the search and results for
performance on repeat searches. '1' means use the cache, '0' means do not.

=back

=cut

sub search {
	my $self = shift;

	my $parms = parse_parms({ -parms => \@_,
							  -legal => ['-cache'],
						   -required => ['-query'],
						   -defaults => {-cache => 1},
						  });
	if (not defined $parms) {
		my $error_message = Class::ParmList->error;
		croak (__PACKAGE__ . "::search() - $error_message\n");
	}
	my ($query,$use_cache) = $parms->get(qw(-query -cache));
	my $db                 = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::search() - No database opened for use\n");
	}

	# Check the cache first
	my ($cache,$cache_key);
	if ($use_cache) {
        my $cache_dir = $self->search_cache_dir;
        my $cache_size = $self->search_cache_size;
		if (defined ($cache_dir) and ($cache_size > 0)) {
			$cache = Tie::FileLRUCache->new({ -cache_dir => $cache_dir,
							                  -keep_last => $cache_size,
							                 });
			$cache_key = $cache->make_cache_key({ -key => $query });
			$cache_key = $self->_untaint($cache_key);
			my ($hit,$result_from_cache) = $cache->check({ -cache_key => $cache_key, });
			return $result_from_cache if ($hit);
		}
	}

	# It wasn't in the cache, so do the search.
	my $indexes = $self->_bare_search({ -query => $query });

	# Sort the results into an array
	my $sorted_indexes = [];
	@$sorted_indexes = map { { -index_enum => $_, -ranking => $indexes->{$_}} }
						sort { $indexes->{$b} <=> $indexes->{$a} }
						 keys %$indexes;

	# Make the Result object and load the search results into it
	my $result = Search::InvertedIndex::Result->new({ -inv_map => $self,
							                            -query => $query,
							                          -indexes => $sorted_indexes,
							                        -use_cache => $use_cache,
							                      });

	# If we are caching, cache the result of the search
	if ($cache) {
		$cache->update({ -cache_key => $cache_key,
							 -value => $result,
						   });
	}

	# All done. Return the results of the search.
	$result;
}

####################################################################

=over 4

=item C<data_for_index({ -index =E<gt> $index });>

Returns the data record for the passed -index. Returns undef
if no matching -index is in the system.

Example:
  my $data = $self->data_for_index({ -index => $index });

=back

=cut

sub data_for_index {
	my ($self) = shift;

	my ($index)    = simple_parms(['-index'],@_);
	my ($db,$thaw) = $self->get('-database','-thaw');
	if (not $db) {
		croak (__PACKAGE__ . "::data_for_index() - No database opened for use\n");
	}
	my ($index_enum)  = $db->get({ -key => "$INDEX$index" });
	return if (not defined $index_enum);
	my ($data_record) = $db->get({ -key => "$INDEX_ENUM_DATA${index_enum}_data" });
	if (not defined $data_record) {
		croak (__PACKAGE__ . "::data_for_index() - Corrupt database. Record '$INDEX_ENUM_DATA${index_enum}_data' not found in system unexpectedly.\n");
	}
	my ($data_ref) = &$thaw($data_record);
	return $data_ref->{-data};
}

####################################################################

=over 4

=item C<clear_all;>

Completely clears the contents of the database and the search cache.

=back

=cut

sub clear_all {
	my ($self) = shift;

	my $database = $self->get(-database);
	$database->clear;
	$self->clear_cache;
}

####################################################################
# Special accessor to improve performance
sub search_cache_dir {
    my $self = shift;
    my $package = __PACKAGE__;
    if (@_ == 1) {
        $self->{$package}->{-search_cache_dir} = shift;
        return;
    } else {
        return $self->{$package}->{-search_cache_dir};
    }
}

####################################################################
# Special accessor to improve performance

sub search_cache_size {
    my $self = shift;
    my $package = __PACKAGE__;
    if (@_ == 1) {
        $self->{$package}->{-search_cache_size} = shift;
        return;
    } else {
        return $self->{$package}->{-search_cache_size};
    }
}

####################################################################

=over 4

=item C<clear_cache;>

Completely clears the contents of the search cache.

=back

=cut

sub clear_cache {
	my ($self) = shift;

    my $cache_dir = $self->search_cache_dir;
    my $cache_size = $self->search_cache_size;

	if (defined ($cache_dir) and ($cache_size > 0)) {
		my $cache = Tie::FileLRUCache->new({ -cache_dir => $cache_dir,
							                   -keep_last => $cache_size,
							             });
		$cache->clear;
	}
}

####################################################################

=over 4

=item C<close;>

Closes the currently open -map and flushes all associated buffers.

=back

=cut

sub close {
	my ($self) = shift;

	my $database = $self->get(-database);
	return if (not defined $database);
	$self->clear(-database);
	$database->close;
	$database = $self->get(-database);
	if (defined $database) {
		croak(__PACKAGE__ . "::close - failed to clear -database\n");
	}
}

####################################################################

=over 4

=item C<number_of_groups;>

Returns the raw number of groups in the system.

Example: my $n = $inv_map->number_of_groups;

=back

=cut

sub number_of_groups {
	my $self = shift;

	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::number_of_groups() - No database opened for use\n");
	}
	my ($number_of_groups) = $db->get({ -key => 'number_of_groups' });
	if (defined $number_of_groups) {
		return $number_of_groups;
	}
	0;
}

####################################################################

=over 4

=item C<number_of_indexes;>

Returns the raw number of indexes in the system.

Example: my $n = $inv_map->number_of_indexes;

=back

=cut

sub number_of_indexes {
	my $self = shift;

	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::number_of_indexes() - No database opened for use\n");
	}
	my ($number_of_indexes) = $db->get({ -key => 'number_of_indexes' });
	if (defined $number_of_indexes) {
		return $number_of_indexes;
	}
	0;
}

####################################################################

=over 4

=item C<number_of_keys;>

Returns the raw number of keys in the system.

Example: my $n = $inv_map->number_of_keys;

=back

=cut

sub number_of_keys {
	my $self = shift;

	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::number_of_keys() - No database opened for use\n");
	}
	my ($number_of_keys) = $db->get({ -key => 'number_of_keys' });
	if (defined $number_of_keys) {
		return $number_of_keys;
	}
	0;
}

####################################################################

=over 4

=item C<number_of_indexes_in_group({ -group =E<gt> $group });>

Returns the raw number of indexes in a specific group.

Example: my $n = $inv_map->number_of_indexes_in_group({ -group => $group });

=back

=cut

sub number_of_indexes_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::number_of_indexes_in_group() - No database opened for use\n");
	}
	my ($group_enum)        = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::number_of_indexes_in_group() - Group '$group' not in database\n");
	}
	my ($number_of_indexes) = $db->get({ -key =>  "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" });
	if (defined $number_of_indexes) {
		return $number_of_indexes;
	}
	0;
}

####################################################################

=over 4

=item C<number_of_keys_in_group({ -group =E<gt> $group });>

Returns the raw number of keys in a specific group.

Example: my $n = $inv_map->number_of_keys_in_group({ -group => $group });

=back

=cut

sub number_of_keys_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::number_of_keys_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get ({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::number_of_indexes_in_group() - Group '$group' not in database\n");
	}
	my ($number_of_keys) = $db->get({ -key =>  "$GROUP_ENUM_DATA${group_enum}_number_of_keys" });
	if (defined $number_of_keys) {
		return $number_of_keys;
	}
	0;
}

####################################################################

=over 4

=item C<add_group({ -group =E<gt> $group });>

Adds a new '-group' to the map. There is normally no need to
call this method from outside the module. The addition of
new -groups is done automatically when adding new entries.

Example: $inv_map->add_group({ -group => $group });

croaks if unable to successfuly create the group for some reason.

It silently eats attempts to create an existing group.

=back

=cut

sub add_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::add_group() - No database opened for use\n");
	}

	# Check if the group already exists in the system
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		# Add the new group
		my ($group_enum_counter) = $db->get({ -key => 'group_enum_counter' });
		my ($old_first_group_enum);
		if (not defined $group_enum_counter) { # First group
			$group_enum_counter = $ZERO_ENUM;
		} else {
			$group_enum_counter = $self->_increment_enum($group_enum_counter);
			$old_first_group_enum = $db->get({ -key => "${GROUP_ENUM}first_group_enum" });
			if (not defined $old_first_group_enum) {
				croak (__PACKAGE__ . "::add_group() - Unable to locate the existing '${GROUP_ENUM}first_group_enum' value. Database may be corrupt.\n");
			}
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum_counter}_number_of_keys", -value => 0 })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM_DATA${group_enum_counter}_number_of_keys' -> '0'\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum_counter}_number_of_indexes", -value => 0 })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM_DATA${group_enum_counter}_number_of_indexes' -> '0'\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum_counter}_key_enum_counter", -value => $ZERO_ENUM })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM_DATA${group_enum_counter}_group_key_enum_counter' -> '000000000000'\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum_counter}_first_key_enum", -value => $NULL_ENUM })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM_DATA${group_enum_counter}_first_key_enum' -> '$NULL_ENUM'\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum_counter}_first_index_enum", -value => $NULL_ENUM })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM_DATA${group_enum_counter}_first_index_enum' -> '$NULL_ENUM'\n");
		}
		if (not $db->put({ -key => "$GROUP$group", -value => $group_enum_counter })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP$group' -> '$group_enum_counter' map entry\n");
		}
		if (not $db->put({ -key => 'group_enum_counter', -value => $group_enum_counter })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save updated group_enum_counter '$group_enum_counter' to map.");
		}
		my $first_group_enum_record = "$NULL_ENUM $NULL_ENUM $group";
		# Rethread the head of an existing group link list to the new group
		if (defined $old_first_group_enum) { # Record formated as: prev next group
			my $old_first_group_enum_record = $db->get({ -key => "$GROUP_ENUM$old_first_group_enum" });
			if (not defined $old_first_group_enum_record) {
				croak (__PACKAGE__ . "::add_group() - Unable to read '$GROUP_ENUM$old_first_group_enum' record. Database may be corrupt.\n");
			}
			$old_first_group_enum_record =~ s/^$NULL_ENUM/$group_enum_counter/;
			if (not $db->put({ -key => "$GROUP_ENUM$old_first_group_enum", -value => $old_first_group_enum_record })) {
				croak (__PACKAGE__ . "::add_group() - Unable to update 'prev' enum reference for '$GROUP_ENUM$old_first_group_enum'\n");
			}
			$first_group_enum_record = "$NULL_ENUM $old_first_group_enum $group";
		}
		if (not $db->put({ -key => "$GROUP_ENUM$group_enum_counter", -value => $first_group_enum_record })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '$GROUP_ENUM$group_enum_counter' -> '$first_group_enum_record' to map\n");
		}
		if (not $db->put({ -key => "${GROUP_ENUM}first_group_enum", -value => $group_enum_counter })) {
			croak (__PACKAGE__ . "::add_group() - Unable to save '${GROUP_ENUM}first_group_enum' -> '$group_enum_counter' map entry.\n");
		}
		my $number_of_groups = $db->get({ -key => 'number_of_groups' });
		if (not defined $number_of_groups) {
			$number_of_groups = 1;
		} else {
			$number_of_groups++;
		}
		if (not $db->put({ -key => 'number_of_groups', -value => $number_of_groups })) {
			croak (__PACKAGE__ . "::add_group() - Unable to update 'number_of_groups. Database may be corrupt.\n");
		}
		$group_enum = $group_enum_counter;
	}
	$group_enum;
}

####################################################################

=over 4

=item C<add_index({ -index =E<gt> $index, -data =E<gt> $data });>

Adds a index entry to the system.

Example: $inv_map->add_index({ -index => $index, -data => $data });

If the 'index' is the same as an existing index, the '-data' for that
index will be updated.

-data can be pretty much any scalar. strings/object/hash/array references are ok.
They will be transparently serialized using Storable (preferred) or Data::Dumper.

This method should be called to set the '-data' record returned by searches
to something useful. If you do not, you will have to maintain the
information you want to show to users seperately from the main search
engine core.

The method returns the index_enum of the index.

=back

=cut

sub add_index {
	my $self = shift;

	my ($index,$data) = simple_parms(['-index','-data'],@_);

	if (not defined $data) {
		croak (__PACKAGE__ . "::add_index() - -data for index may not be 'undef' value.");
	}

	my ($db,$freeze) = $self->get('-database','-freeze');
	if (not $db) {
		croak (__PACKAGE__ . "::add_index() - No database opened for use\n");
	}
	# Check if the index already exists in the system
	my ($index_enum)        = $db->get({ -key => "$INDEX$index" });
	if (not defined $index_enum) {
		# Add the new index
		my ($index_enum_counter) = $db->get({ -key => 'index_enum_counter' });
		my ($old_first_index_enum);
		if (not defined $index_enum_counter) {
			$index_enum_counter = $ZERO_ENUM;
		} else {
			$index_enum_counter = $self->_increment_enum($index_enum_counter);
			$old_first_index_enum = $db->get({ -key => "${INDEX_ENUM}first_index_enum" });
			if (not defined $old_first_index_enum) {
				croak (__PACKAGE__ . "::add_index() - Unable to locate the existing '${INDEX_ENUM}first_index_enum' value. Database may be corrupt.\n");
			}
		}
		if (not $db->put({ -key => "$INDEX$index", -value => $index_enum_counter })) {
			croak (__PACKAGE__ . "::add_index() - Unable to save '$INDEX$index' -> '$index_enum_counter' map entry\n");
		}
		if (not $db->put({ -key => 'index_enum_counter', -value => $index_enum_counter })) {
			croak (__PACKAGE__ . "::add_index() - Unable to save updated index_enum_counter '$index_enum_counter' to map.");
		}
		my $first_index_enum_record = "$NULL_ENUM $NULL_ENUM $index";
		if (defined $old_first_index_enum) { # Record formated as: prev next index
			my $old_first_index_enum_record = $db->get({ -key => "$INDEX_ENUM$old_first_index_enum" });
			if (not defined $old_first_index_enum_record) {
				croak (__PACKAGE__ . "::add_index() - Unable to read '$INDEX_ENUM$old_first_index_enum' record. Database may be corrupt.\n");
			}
			$old_first_index_enum_record =~ s/^$NULL_ENUM/$index_enum_counter/;
			if (not $db->put({ -key => "$INDEX_ENUM$old_first_index_enum",
							 -value => $old_first_index_enum_record, })) {
				croak (__PACKAGE__ . "::add_index() - Unable to update 'prev' enum reference for '$INDEX_ENUM$old_first_index_enum'\n");
			}
			$first_index_enum_record = "$NULL_ENUM $old_first_index_enum $index";
		}
		if (not $db->put({ -key => "$INDEX_ENUM$index_enum_counter", -value => $first_index_enum_record })) {
			croak (__PACKAGE__ . "::add_index() - Unable to save '$INDEX_ENUM$index_enum_counter' -> '$first_index_enum_record' to map\n");
		}
		if (not $db->put({ -key => "${INDEX_ENUM}first_index_enum", -value => $index_enum_counter })) {
			croak (__PACKAGE__ . "::add_index() - Unable to save '${INDEX_ENUM}first_index_enum' -> '$index_enum_counter' map entry.\n");
		}
		my $number_of_indexes = $db->get({ -key => 'number_of_indexes' });
		if (not defined $number_of_indexes) {
			$number_of_indexes = 1;
		} else {
			$number_of_indexes++;
		}
		if (not $db->put({ -key => 'number_of_indexes', -value => $number_of_indexes })) {
			croak (__PACKAGE__ . "::add_index() - Unable to update 'number_of_indexs. Database may be corrupt.\n");
		}
		$index_enum = $index_enum_counter;
	}

	# Store the -data record. The merged record saves an I/O for reading.
	my ($raw_index_record) = { '-index' => $index, -data => $data };
	my $index_record = &$freeze($raw_index_record);
	if (not $db->put({ -key => "$INDEX_ENUM_DATA${index_enum}_data", -value => $index_record })) {
		croak (__PACKAGE__ . "::add_index() - Unable to store '$INDEX_ENUM_DATA${index_enum}_data' -data value\n");
	}
	# We don't want the cache returning old info after an update
	$self->clear_cache;

	$index_enum;
}

####################################################################

=over 4

=item C<add_index_to_group({ -group =E<gt> $group, -index =E<gt> $index[, -data =E<gt> $data] });>

Adds an index entry to a group. If the index does not already
exist in the system, adds it to the system as well.

Examples:

   $inv_map->add_index_to_group({ -group => $group, '-index' => $index});

   $inv_map->add_index_to_group({ -group => $group, '-index' => $index, -data => $data});

Returns the 'index_enum' for the index record.

If the 'index' is the same as an existing key, the 'index_enum' of the
existing index will be returned.

There is normally no need to call this method directly. Addition
of index to groups is handled automatically during addition of
new entries.

It cannot be used to add index to non-existant groups. This is
a feature not a bug.

The -data parameter is optional

=back

=cut

sub add_index_to_group {
	my $self = shift;

	my $parms = parse_parms ({ -parms => \@_,
							   -legal => ['-data'],
							-required => ['-group', '-index'],
							-defaults => { -data => undef },
						 });

	if (not defined $parms) {
		my $error_message = Class::ParmList->error;
		croak (__PACKAGE__ . "::add_index_to_group() - $error_message\n");
	}

	my ($group,$index,$data) = $parms->get(qw(-group -index -data));
	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::add_index_to_group() - No database opened for use\n");
	}
	my $group_enum   = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::add_index_to_group() - Attempted to add -index '$index' to non-existant -group '$group'\n");
	}
	my $index_enum = $db->get({ -key => "$INDEX$index" });
	if (not defined $index_enum) {
		if (not defined $data) {
			croak (__PACKAGE__ . "::add_index_to_group() - Attempted to add completely new -index '$index with no defined -data' \n");
		}
		$index_enum = $self->add_index({ '-index' => $index, -data => $data });
	}

	# Update the INDEX_ENUM_GROUP_CHAIN  and number of indexes for the group as necessary
	# Check if the index already exists in the group (if it doesn't, there isn't much to do)
	my ($chain) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
	if (not defined $chain) {
		# Add the index_enum to the index chain for the group
		my $old_first_index_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
		my $first_index_enum_record = "$NULL_ENUM $NULL_ENUM";
		if (defined ($old_first_index_enum) and ($old_first_index_enum ne $NULL_ENUM)) { # Record formated as: prev next index
			my $old_first_index_enum_record = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum" });
			if (not defined $old_first_index_enum_record) {
				croak (__PACKAGE__ . "::add_index_to_group() - Unable to read '$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum' record. Database may be corrupt.\n");
			}
			$old_first_index_enum_record =~ s/^$NULL_ENUM/$index_enum/;
			if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum",
							 -value => $old_first_index_enum_record, })) {
				croak (__PACKAGE__ . "::add_entry_to_group() - Unable to update 'prev' enum reference for '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum'\n");
			}
			$first_index_enum_record = "$NULL_ENUM $old_first_index_enum";
		}

		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum", -value => $first_index_enum_record })) {
			croak (__PACKAGE__ . "::add_index_to_group() - Unable to save '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' -> '$first_index_enum_record' to map\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum", -value => $index_enum })) {
			croak (__PACKAGE__ . "::add_index_to_group() - Unable to save '$GROUP_ENUM_DATA${group_enum}_first_index_enum' -> '$index_enum' map entry.\n");
		}

		# Increment the number of indexes for the group
		my $number_of_group_indexes = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" });
		if (not defined $number_of_group_indexes) {
			croak (__PACKAGE__ . "::add_index_to_group () - Database may be corrupt. Failed to locate '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record for group '$group'\n");
		}
		$number_of_group_indexes++;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes", -value => $number_of_group_indexes })) {
			croak (__PACKAGE__ . "::add_index_to_group () - Database may be corrupt. Unable to update '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record to '$number_of_group_indexes' for group '$group'\n");
		}
	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	return $index_enum;
}

####################################################################

=over 4

=item C<add_key_to_group({ -group =E<gt> $group, -key =E<gt> $key });>

Adds a key entry to a group.

Example: $inv_map->_add_key({ -group => $group, -key => $key });

Returns the 'key_enum' for the key record.

If the 'key' is the same as an existing key, the 'key_enum' of the
existing key will be returned.

There is normally no need to call this method directly. Addition
of keys to groups is handled automatically during addition of
new entries.

It cannot be used to add keys to non-existant groups. This is
a feature not a bug.

=back

=cut

sub add_key_to_group {
	my $self = shift;

    my $parm_ref = {};
    if (@_ == 1) {
        $parm_ref = shift;
    } else {
        %$parm_ref = @_;
    }
    my $group = $parm_ref->{'-group'};
    if (not defined $group) {
		croak (__PACKAGE__ . "::add_key_to_group() - '-group' parameter not passed.\n");
    }
    my $key   = $parm_ref->{'-key'};
    if (not defined $key) {
		croak (__PACKAGE__ . "::add_key_to_group() - '-key' parameter not passed.\n");
    }
    # Hidden performance hack. We can optionally pass the database ref in via the calling parms
    my $db   = $parm_ref->{'-database'};
    if (not defined $db) {
	    ($db)  = $self->get(-database);
    }

	if (not $db) {
		croak (__PACKAGE__ . "::add_key_to_group() - No database opened for use\n");
	}
	my $group_enum   = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::add_key_to_group() - Attempted to add -key '$key' to non-existant -group '$group'\n");
	}
	my $key_enum  = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_TO_KEY_ENUM$key" });
	if (not defined $key_enum) {

		# Add the new key
		my ($key_enum_counter) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_key_enum_counter" });
		my ($old_first_key_enum);
		if (not defined $key_enum_counter) {
			croak (__PACKAGE__ . "::add_key_to_group() - Corrupt database. No '$GROUP_ENUM_DATA${group_enum}_key_enum_counter' value found for group '$group'.\n");
		}
		$key_enum_counter = $self->_increment_enum($key_enum_counter);
		$old_first_key_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" });
		if (not defined $old_first_key_enum) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to locate the existing '$GROUP_ENUM_DATA${group_enum}_first_key_enum' value. Database may be corrupt.\n");
		}

		# Rethread the end of the next/prev links to place the new key as the 'first' key for the group
		if ($old_first_key_enum ne $NULL_ENUM) {
			# If the existing 'first_key_enum' is not the null enum value, update its 'prev' field to the new 'key_enum'
			my $old_first_key_enum_record = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$old_first_key_enum" });
			if (not defined $old_first_key_enum_record) {
				croak (__PACKAGE__ . "::add_key_to_group() - Unable to read '$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$old_first_key_enum' record. Database may be corrupt.\n");
			}
			$old_first_key_enum_record =~ s/^.{12}/$key_enum_counter/;
			if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$old_first_key_enum", -value => $old_first_key_enum_record })) {
				croak (__PACKAGE__ . "::add_key_to_group() - Unable to update 'prev' enum reference for '$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$old_first_key_enum' -> '$old_first_key_enum_record'\n");
			}
		}
		# Prev Next Key
		my $first_key_enum_record = "$NULL_ENUM $old_first_key_enum $key";

		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum_counter",
						 -value => $first_key_enum_record })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to save '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum_counter' -> '$first_key_enum_record' to map\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum",
						 -value => $key_enum_counter })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to save '$GROUP_ENUM_DATA${group_enum}_first_key_enum' -> '$key_enum_counter' map entry.\n");
		}

		# Add to KEY_TO_KEY_ENUM
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum${KEY_TO_KEY_ENUM}$key",
						 -value => $key_enum_counter })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to save '$GROUP_ENUM_DATA$group_enum${KEY_TO_KEY_ENUM}$key' -> '$key_enum_counter' to map\n");
		}

		# Update number of keys for the group
		my $number_of_keys_in_group = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_keys" });
		$number_of_keys_in_group = 0 if (not defined $number_of_keys_in_group);
		$number_of_keys_in_group++;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_keys", -value => $number_of_keys_in_group })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to save '$GROUP_ENUM_DATA${group_enum}_number_of_keys' -> '$number_of_keys_in_group'\n");
		}

		# Update number of keys for the system
		my $number_of_keys = $db->get({ -key => 'number_of_keys' });
		if (not defined $number_of_keys) {
			$number_of_keys = 1;
		} else {
			$number_of_keys++;
		}
		if (not $db->put({ -key => 'number_of_keys', -value => $number_of_keys })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to update 'number_of_keys' -> '$number_of_keys'. Database may be corrupt.\n");
		}

		# Update the key_enum_counter
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_key_enum_counter", -value => $key_enum_counter })) {
			croak (__PACKAGE__ . "::add_key_to_group() - Unable to update '${GROUP_ENUM_DATA}${$group_enum}_key_enum_counter' -> '$key_enum_counter'. Database may be corrupt.\n");
		}


		$key_enum = $key_enum_counter;
	}
	# We don't want the cache returning old info after an update
	$self->clear_cache;

	$key_enum;
}

####################################################################

=over 4

=item C<add_entry_to_group({ -group =E<gt> $group, -key =E<gt> $key, -index =E<gt> $index, -ranking =E<gt> $ranking });>

Adds a reference to a particular index for a key with a ranking
to a specific group.

Example: $inv_map->add_entry_to_group({ -group => $group, -key => $key, -index => $index, -ranking => $ranking });

This method cannot be used to create new -indexes or -groups. This is a feature, not a bug.
It *will* create new -keys as needed.

=back

=cut

sub add_entry_to_group {
	my $self = shift;

	my ($group,$key,$index,$ranking) = simple_parms(['-group', '-key', '-index', '-ranking'],@_);

	$ranking = int($ranking+0.5);
	if (($ranking > 32767) or ($ranking < -32768)) {
		croak (__PACKAGE__ . "::add_entry_to_group() - Legal ranking values must be between -32768 and 32768 inclusive\n");
	}
	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::add_entry_to_group() - No database opened for use\n");
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::add_entry_to_group() - Attempted to add an entry to the undeclared -group '$group'\n");
	}

	# Get the index_enum for this index
	my $index_enum = $db->get({ -key => "$INDEX$index" });
	if (not defined $index_enum) {
		croak(__PACKAGE__ . "::add_entry_to_group() - Attempted to add an entry to -group '$group' with an undeclared -index of '$index'\n");
	}

	# Add the key to the group, if necessary.
	my $key_enum      = $self->add_key_to_group ({ -group => $group, -key => $key });

	# Add the index_enum to the list of index_enums for this key_enum
	my $keyed_record  = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
	if (not defined $keyed_record) {
		$keyed_record = '';
	}
	my $keyed_indexes = _unpack_list($keyed_record);
	$keyed_indexes->{$index_enum} = $ranking;
	$keyed_record = _pack_list($keyed_indexes);
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum", -value => $keyed_record })) {
		croak (__PACKAGE__ . "::add_entry_to_group() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum' -> (list of ranked indexes)\n");
	}
	my $test = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum" });
	if ($test ne $keyed_record) {
		croak (__PACKAGE__ . "::add_entry_to_group() - Database is failing to correctly store and retreive binary data\n");
	}

	# Add the key_enum to the list of key_enums for this index_enum
	my $indexed_record  = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum" });
	# If this index is not currently used in this group,
	# make a new INDEXED_KEY_LIST for this index_enum
	# and increment the number of indexes for the group
	my $indexed_keys = {};
	if (not defined $indexed_record) {
		my $number_of_group_indexes = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" });
		if (not defined $number_of_group_indexes) {
			croak (__PACKAGE__ . "::add_entry_to_group () - Database may be corrupt. Failed to locate '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record for group '$group'\n");
		}
		$number_of_group_indexes++;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes", -value => $number_of_group_indexes })) {
			croak (__PACKAGE__ . "::add_entry_to_group () - Database may be corrupt. Unable to update '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record to '$number_of_group_indexes' for group '$group'\n");
		}
	} else {
		$indexed_keys = _unpack_list($indexed_record);
	}
	$indexed_keys->{$key_enum} = $ranking;
	my @displ_list = %$indexed_keys;
	$indexed_record = _pack_list($indexed_keys);
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum", -value => $indexed_record })) {
		croak (__PACKAGE__ . "::add_entry_to_group() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$key_enum' -> (list of ranked keys)\n");
	}

	$test = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum" });
	if ($test ne $indexed_record) {
		croak (__PACKAGE__ . "::add_entry_to_group() - Database is failing to correctly store and retreive binary data\n");
	}
	# Update the INDEX_ENUM_GROUP_CHAIN as necessary
	# Check if the index already exists in the group
	my ($chain) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
	if (not defined $chain) {
		# Add the index_enum to the index chain for the group
		my $old_first_index_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
		my $first_index_enum_record = "$NULL_ENUM $NULL_ENUM";
		if (defined ($old_first_index_enum) and ($old_first_index_enum ne $NULL_ENUM)) { # Record formated as: prev next index
			my $old_first_index_enum_record = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum" });
			if (not defined $old_first_index_enum_record) {
				croak (__PACKAGE__ . "::add_entry_to_group() - Unable to read '$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum' record. Database may be corrupt.\n");
			}
			$old_first_index_enum_record =~ s/^$NULL_ENUM/$index_enum/;
			if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum",
							 -value => $old_first_index_enum_record, })) {
				croak (__PACKAGE__ . "::add_entry_to_group() - Unable to update 'prev' enum reference for '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$old_first_index_enum'\n");
			}
			$first_index_enum_record = "$NULL_ENUM $old_first_index_enum";
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum", -value => $first_index_enum_record })) {
			croak (__PACKAGE__ . "::add_entry_to_group() - Unable to save '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' -> '$first_index_enum_record' to map\n");
		}
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum", -value => $index_enum })) {
			croak (__PACKAGE__ . "::add_entry_to_group() - Unable to save '$GROUP_ENUM_DATA${group_enum}_first_index_enum' -> '$index_enum' map entry.\n");
		}
	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	1;
}

####################################################################

=over 4

=item C<remove_group({ -group =E<gt> $group });>

Remove all entries for a group from the map.

Example: $inv_map->remove_group({ -group => $group });

This removes all key and key/index entries for the group and
all other group specific data from the map.

Use this method when you wish to completely delete a searchable
'group' from the map without disturbing other existing groups.

=back

=cut

sub remove_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::remove_group() - No database opened for use\n");
	}

	# Check if the group exists in the system
	my ($group_enum)        = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ ."::remove_group() - Attempted to remove a non-existant group '$group'\n");
	}

	# Remove the 'key' related records
	my ($first_key_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" });
	if (not defined $first_key_enum) {
		croak (__PACKAGE__ . "::remove_group() - Corrupt database. No '$GROUP_ENUM_DATA${group_enum}_first_key_enum' record found for group '$group'\n");
	}

	# Chase the linked list of 'key_enum's and delete them
	my $key_enum = $first_key_enum;
	while ($key_enum ne $NULL_ENUM) {
		my ($key_enum_record) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" });
		if (not defined $key_enum_record) {
			croak (__PACKAGE__ . "::remove_group() - Corrupt database. No '$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record found for group '$group'\n");
		}
		my ($prev_key_enum,$next_key_enum,$key) = $key_enum_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record found for group '$group'\n");
		}
		if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_TO_KEY_ENUM$key" })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}$KEY_TO_KEY_ENUM$key' record found for group '$group'\n");
		}
		$db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum" });
		$key_enum = $next_key_enum;
	}
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}_first_key_enum' record found for group '$group'\n");
	}

	# Remove the 'index' related records
	my ($first_index_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
	if (not defined $first_index_enum) {
		croak (__PACKAGE__ . "::remove_group() - Corrupt database. No '$GROUP_ENUM_DATA${group_enum}_first_index_enum' record found for group '$group'\n");
	}

	# Chase the linked list of 'index_enum's and delete them
	my $index_enum = $first_index_enum;
	while ($index_enum ne $NULL_ENUM) {
		my ($index_enum_record) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$index_enum" });
		if (not defined $index_enum_record) {
			croak (__PACKAGE__ . "::remove_group() - Corrupt database. No '$GROUP_ENUM_DATA${group_enum}$KEY_ENUM_TO_KEY_AND_CHAIN$index_enum' record found for group '$group'\n");
		}
		my ($prev_index_enum,$next_index_enum,$index) = $index_enum_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$index_enum" })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}$INDEX_ENUM_GROUP_CHAIN$index_enum' record found for group '$group'\n");
		}
		$db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum" });
		$index_enum = $next_index_enum;
	}
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}_first_index_enum' record found for group '$group'\n");
	}

	# Adjust the system wide 'number_of_keys' counter
	my ($number_of_group_keys) = $db->get({ -key=> "$GROUP_ENUM_DATA${group_enum}_number_of_keys" });
	if (not defined $number_of_group_keys) {
		croak (__PACKAGE__ . "::remove_group() - Unable to retrieve '$GROUP_ENUM_DATA${group_enum}_number_of_keys' for group '$group'\n");
	}
	my ($number_of_keys) = $db->get({ -key=> "number_of_keys" });
	$number_of_keys = 0 if (not defined $number_of_keys);
	$number_of_keys -= $number_of_group_keys;
	if (not $db->put({ -key => 'number_of_keys', -value => $number_of_keys })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to store updated 'number_of_keys' ($number_of_keys) for system\n");
	}

	# remove the group key and index counters
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_keys" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}_number_of_keys' record\n");
	}
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}_key_enum_counter" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}_key_enum_counter' record\n");
	}
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record\n");
	}

	# Get the 'next' and 'prev' pointers for the group.
	my ($group_record) = $db->get({ -key => "$GROUP_ENUM$group_enum" });
	if (not defined $group_record) {
		croak (__PACKAGE__ . "::remove_group() - Inconsistent database. Unable to find '$GROUP_ENUM$group_enum' record for group '$group'\n");
	}

	# Rethread the doubly linked list of groups to omit this group
	my ($prev_group_enum,$next_group_enum) = $group_record =~ m/^(.{12}) (.{12})/;
	if (not (defined ($prev_group_enum) and defined ($next_group_enum))) {
		croak (__PACKAGE__ . "::remove_group() - Corrupt data record '$GROUP_ENUM$group_enum' for group '$group'\n");
	}

	# Point the 'next' for the previous group to the next group_enum
	if ($prev_group_enum ne $NULL_ENUM) {
		my $prev_group_record = $db->get({ -key => "$GROUP_ENUM$prev_group_enum" });
		if (not defined $prev_group_record) {
			croak (__PACKAGE__ . "::remove_group() - Inconsistent database. Unable to find '$GROUP_ENUM$prev_group_enum' record for group '$group'\n");
		}
		$prev_group_record =~ s/^(.{12}) (.{12})/$1 $next_group_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM$prev_group_enum", -value => $prev_group_record })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to update '$GROUP_ENUM$prev_group_enum' record to '$prev_group_record'\n");
		}
	}

	# Point the 'prev' for the next group to the previous group_enum
	if ($next_group_enum ne $NULL_ENUM) {
		my $next_group_record = $db->get({ -key => "$GROUP_ENUM$next_group_enum" });
		if (not defined $next_group_record) {
			croak (__PACKAGE__ . "::remove_group() - Inconsistent database. Unable to find '$GROUP_ENUM$next_group_enum' record for group '$group'\n");
		}
		$next_group_record =~ s/^(.{12})/$prev_group_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM$next_group_enum", -value => $next_group_record })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to update '$GROUP_ENUM$next_group_enum' record to '$next_group_record'\n");
		}
	}

	# Fix the ${GROUP_ENUM}first_group_enum if we used to be it.
	my $first_group_enum = $db->get({ -key => "${GROUP_ENUM}first_group_enum" });
	if (not defined $first_group_enum) {
		croak (__PACKAGE__ . "::remove_group() - Corrupt database. Unable to locate '${GROUP_ENUM}first_group_enum' record\n");
	}
	if ($first_group_enum eq $group_enum) {
		if (not $db->put({ -key => "${GROUP_ENUM}first_group_enum", -value => $next_group_enum })) {
			croak (__PACKAGE__ . "::remove_group() - Unable to update '${GROUP_ENUM}first_group_enum' record to '$next_group_enum'\n")
		}
	}

	# Delete this group listing
	if (not $db->delete({ -key => "$GROUP$group" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP$group' record\n");
	}
	if (not $db->delete({ -key => "$GROUP_ENUM$group_enum" })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to delete '$GROUP_ENUM$group_enum' record\n");
	}

	# Decrement the number of groups
	my $number_of_groups = $db->get({ -key => 'number_of_groups' });
	if (not defined $number_of_groups) {
		croak (__PACKAGE__ . "::remove_group() - Inconsistent database. No 'number_of_groups' record found.\n");
	} else {
		$number_of_groups--;
	}
	if (not $db->put({ -key => 'number_of_groups', -value => $number_of_groups })) {
		croak (__PACKAGE__ . "::remove_group() - Unable to update 'number_of_groups. Database may be corrupt.\n");
	}


	# delete the 'group_enum_counter'  and the ${GROUP_ENUM}first_group_enum if no groups are left.
	# The 'group_enum_counter' record is used as a flag for the 'add_group()' method
	# to determine when to initialize for the first group.
	if ($number_of_groups == 0) {
		if (not $db->delete({-key => 'group_enum_counter'})) {
			croak (__PACKAGE__ . "::remove_group() - Unable to delete 'group_enum_counter' record from database.\n");
		}
		if (not $db->delete({-key => "${GROUP_ENUM}first_group_enum"})) {
			croak (__PACKAGE__ . "::remove_group() - Unable to delete '${GROUP_ENUM}first_group_enum' record from database.\n");
		}
	}


	# We don't want the cache returning old info after an update
	$self->clear_cache;

	1;
}

####################################################################

=over 4

=item C<remove_entry_from_group({ -group =E<gt> $group, -key =E<gt> $key, -index =E<gt> $index });>

Remove a specific key<->index entry from the map for a group.

Example: $inv_map->remove_entry_from_group({ -group => $group, -key => $key, -index => $index });

Does not remove the -key or -index from the database or the group -
only the entries mapping the two to each other.

=back

=cut

sub remove_entry_from_group {
	my $self = shift;

	my ($group,$key,$index) = simple_parms(['-group','-key','-index'],@_);

	my ($db) = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::remove_entry_from_group() - No database opened for use\n");
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::remove_entry_from_group() - Attempted to remove an entry from the undeclared -group '$group'\n");
	}

	# Get the index_enum for this index
	my $index_enum = $db->get({ -key => "$INDEX$index" });
	if (not defined $index_enum) {
		croak(__PACKAGE__ . "::remove_entry_from_group() - Attempted to remove an entry from the -group '$group' with an undeclared -index of '$index'\n");
	}

	# Get the key_enum for this key
	my $key_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_TO_KEY_ENUM$key" });
	if (not defined $key_enum) {
		croak(__PACKAGE__ . "::remove_entry_from_group() - Attempted to remove an entry from the -group '$group' with an undeclared -key of '$key'\n");
	}

	# Delete the index_enum from the list of index_enums for this key_enum
	my $keyed_record  = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum" });
	my $keyed_indexes = _unpack_list($keyed_record);
	delete $keyed_indexes->{$index_enum};
	$keyed_record = _pack_list($keyed_indexes);
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum", -value => $keyed_record })) {
		croak (__PACKAGE__ . "::remove_entry_from_group() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$KEYED_INDEX_LIST$key_enum' -> (list of ranked indexes)\n");
	}

	# Delete the key_enum from the list of key_enums for this index_enum
	my $indexed_record  = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum" });
	my $indexed_keys = _unpack_list($indexed_record);
	delete $indexed_keys->{$key_enum};
	$indexed_record = _pack_list($indexed_keys);
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$index_enum", -value => $keyed_record })) {
		croak (__PACKAGE__ . "::remove_entry_from_group() - Failed to save updated '$GROUP_ENUM_DATA${group_enum}$INDEXED_KEY_LIST$key_enum' -> (list of ranked keys)\n");
	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	1;
}

####################################################################

=over 4

=item C<remove_index_from_group ({ -group =E<gt> $group, -index =E<gt> $index });>

Remove all references to a specific index for all keys for a group.

Example: $inv_map->_remove_index_from_group({ -group => $group, -index => $index });

Note: This *does not* remove the index from the _system_ - just a specific
	  group.

It is a null operation to remove an undeclared index or to remove a
declared index from a group where it is not used.

=back

=cut

sub remove_index_from_group {
	my $self = shift;

	my ($group,$index) = simple_parms(['-group','-index'],@_);
	my ($db)           = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::remove_index_from_group() - No database opened for use\n");
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::remove_index_from_group() - Attempted to remove an index from an undeclared -group '$group'\n");
	}

	# Get the index_enum for this index
	my $index_enum = $db->get({ -key => "$INDEX$index" });
	return unless (defined $index_enum);

	# Get the group chain entry for this index
	my ($index_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });

	# If we did not find a matching index entry for removal - bail: There is nothing we need to do.
	return unless (defined $index_chain_entry);

	# Remove the index from the INDEXED_KEY_LIST
	my ($indexed_key_list_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST$index_enum" });

	# If there was no match for the index, bail - there is nothing to do.
	return unless (defined $indexed_key_list_record);

	my ($key_enum_data) = _unpack_list($indexed_key_list_record);
	my @key_enums = keys %$key_enum_data;
	my @zeroed_key_enums = ();
	# Remove the index from the appropriate KEYED_INDEX_LISTs
	foreach my $key_enum (@key_enums) {
		my ($keyed_index_list_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
		if (not defined $keyed_index_list_record) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Corrupted database. Unable to find '$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum' record\n");
		}
		my ($index_enum_data) = _unpack_list($keyed_index_list_record);
		delete $index_enum_data->{$index_enum};
		$keyed_index_list_record = _pack_list($index_enum_data);
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum",
						 -value => $keyed_index_list_record})) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum' record\n");
		}
		push (@zeroed_key_enums,$key_enum) if (length($keyed_index_list_record) == 0);
	}
	$db->delete({ -key => "$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST$index_enum" });

	# Re-thread the INDEX_ENUM_GROUP_CHAIN to omit this index_enum
	my ($prev_index_enum,$next_index_enum) = $index_chain_entry =~ m/^(.{12}) (.{12})$/;
	if (not (defined ($prev_index_enum) and defined ($next_index_enum))) {
		croak (__PACKAGE__ . "::remove_index_from_group() - Corrupted database. Unable to parse 'GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' record for group '$group'\n");
	}

	# Point the 'next' for the previous index_eum to the next index_enum in the chain
	if ($prev_index_enum ne $NULL_ENUM) {
		my ($prev_index_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$prev_index_enum" });
		if (not defined $index_chain_entry) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Corrupted database. Unable to locate 'GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$prev_index_enum' record for group '$group'\n");
		}
		$prev_index_chain_entry =~ s/^(.{12}) (.{12})/$1 $next_index_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$prev_index_enum",
						 -value => $prev_index_chain_entry })) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$prev_index_enum' record ($prev_index_chain_entry) for group '$group'\n");
		}
	}

	# Point the 'prev' for the next index_eum to the previous index_enum in the chain
	if ($next_index_enum ne $NULL_ENUM) {
		my ($next_index_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum" });
		if (not defined $index_chain_entry) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Corrupted database. Unable to locate 'GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum' record for group '$group'\n");
		}
		$next_index_chain_entry =~ s/^(.{12})/$prev_index_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum",
						 -value => $next_index_chain_entry })) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum' record ($next_index_chain_entry) for group '$group'\n");
		}
	}

	# Fix the $GROUP_ENUM_DATA${group_enum}first_index_enum if we used to be it.
	my $first_index_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
	if (not defined $first_index_enum) {
		croak (__PACKAGE__ . "::remove_index_from_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA${group_enum}_first_index_enum' record\n");
	}
	if ($first_index_enum eq $index_enum) {
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum",
						 -value => $next_index_enum })) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Unable to update '$GROUP_ENUM_DATA${group_enum}_first_index_enum' record to '$next_index_enum'\n")
		}
	}

	# Delete this index_enum from the INDEX_ENUM_GROUP_CHAIN
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" })) {
		croak (__PACKAGE__ . "::remove_index_from_group() - Unable to delete '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' record from group '$group'\n");
	}

	# Decrement the number_of_indexes for this group
	my ($number_of_indexes) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes" });
	if (not defined $number_of_indexes) {
		croak (__PACKAGE__ . "::remove_index_from_group() - Unable to locate '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record for group '$group'\n");
	}
	$number_of_indexes--;
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_indexes", -value => $number_of_indexes })) {
		croak (__PACKAGE__ . "::remove_index_from_group() - Unable to update '$GROUP_ENUM_DATA${group_enum}_number_of_indexes' record  to '$number_of_indexes' for group '$group'\n");
	}

	# Remove zeroed out keys.
	for my $key_enum (@zeroed_key_enums) {
		my $key_record = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" });
		if (not defined $key_record) {
			croak (__PACKAGE__ . "::remove_index_from_group() - Unable to locate '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record.\n")
		}
		my ($prev_key_enum,$next_key_enum,$key) = $key_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		$self->remove_key_from_group({ -group => $group, -key => $key });

	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	return 1;
}

####################################################################

=over 4

=item C<remove_index_from_all ({ -index =E<gt> $index });>

Remove all references to a specific index from the system.

Example: $inv_map->_remove_index_from_all({ -index => $index });

This *completely* removes it from all groups and the master
system entries.

It is a null operation to remove an undefined index.

=back

=cut

sub remove_index_from_all {
	my $self = shift;

	my ($index) = simple_parms(['-index'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::remove_index_from_all() - No database opened for use\n");
	}
	my ($index_enum) = $db->get({ -key => "$INDEX$index" });
	return if (not defined $index_enum);

	# Remove index entries from all groups
	my ($first_group_enum) = $db->get({ -key => "${GROUP_ENUM}first_group_enum" });

	if (defined $first_group_enum) {
		my $group_enum = $first_group_enum;
		while ($group_enum ne $NULL_ENUM) {
			my ($group_record) = $db->get({ -key => "${GROUP_ENUM}$group_enum" });
			if (not defined $group_record) {
				croak (__PACKAGE__ . "::remove_index_from_all() - Database corrupt. Unable to locate '${GROUP_ENUM}$group_enum' record for system.\n");
			}
			my ($prev_group_enum,$next_group_enum,$group) = $group_record =~ m/^(.{12}) (.{12}) (.*)$/s;
			$self->remove_index_from_group({ -group => $group, '-index' => $index });
			$group_enum = $next_group_enum;
		}
	}

	# Re-thread the INDEX_ENUM to omit this index_enum
	my ($index_chain_entry) = $db->get({ -key => "$INDEX_ENUM$index_enum" });
	if (not defined $index_chain_entry) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Corrupt database. Unable to locate '$INDEX_ENUM$index_enum' record\n");
	}
	my ($prev_index_enum,$next_index_enum) = $index_chain_entry =~ m/^(.{12}) (.{12})/;
	if (not (defined ($prev_index_enum) and defined ($next_index_enum))) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Corrupt database. Unable to parse '$INDEX_ENUM$index_enum' record\n");
	}

	if ($prev_index_enum ne $NULL_ENUM) {
		my ($prev_index_chain_entry) = $db->get({ -key => "$INDEX_ENUM$prev_index_enum" });
		if (not defined $prev_index_chain_entry) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Corrupt database. Unable to locate '$INDEX_ENUM$prev_index_enum' record\n");
		}
		$prev_index_chain_entry =~ s/^(.{12}) (.{12})/$1 $next_index_enum/;
		if (not $db->put({ -key => "$INDEX_ENUM$prev_index_enum",
						 -value => $prev_index_chain_entry })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to save updated '$INDEX_ENUM$prev_index_enum' record ($prev_index_chain_entry)\n");
		}
	}

	if ($next_index_enum ne $NULL_ENUM) {
		my ($next_index_chain_entry) = $db->get({ -key => "$INDEX_ENUM$next_index_enum" });
		if (not defined $next_index_chain_entry) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Corrupt database. Unable to locate '$INDEX_ENUM$next_index_enum' record\n");
		}
		$next_index_chain_entry =~ s/^(.{12})/$prev_index_enum/;
		if (not $db->put({ -key => "$INDEX_ENUM$next_index_enum",
						 -value => $next_index_chain_entry })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to save updated '$INDEX_ENUM$next_index_enum' record ($next_index_chain_entry)\n");
		}
	}

	# Fix the ${INDEX_ENUM}first_index_enum if we used to be it.
	my $first_index_enum = $db->get({ -key => "${INDEX_ENUM}first_index_enum" });
	if (not defined $first_index_enum) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Corrupt database. Unable to locate '${INDEX_ENUM}first_index_enum' record\n");
	}
	if ($first_index_enum eq $index_enum) {
		if (not $db->put({ -key => "${INDEX_ENUM}first_index_enum",
						 -value => $next_index_enum })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to update '${INDEX_ENUM}first_index_enum' record to '$next_index_enum'\n")
		}
	}

	# Delete this index_enum from the INDEX_ENUM
	if (not $db->delete({ -key => "$INDEX_ENUM$index_enum" })) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete '$INDEX_ENUM$index_enum' record\n");
	}

	# Delete this index from the INDEX
	if (not $db->delete({ -key => "$INDEX$index" })) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete '$INDEX$index' record\n");
	}

	# Delete this index -data from the INDEX_ENUM_DATA
	if (not $db->delete({ -key => "$INDEX_ENUM_DATA${index_enum}_data" })) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete '$INDEX_ENUM_DATA${index_enum}_data' record\n");
	}

	# Decrement the number_of_indexes for the system
	my ($number_of_indexes) = $db->get({ -key => "number_of_indexes" });
	if (not defined $number_of_indexes) {
		croak (__PACKAGE__ . "::remove_index_from_all() - Unable to locate 'number_of_indexes' record for system\n");
	}
	$number_of_indexes--;
	if (not $db->put({ -key => "number_of_indexes", -value => $number_of_indexes })) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to update 'number_of_indexes' record  to '$number_of_indexes' for system\n");
	}

	# If there are no more indexes, clear out the
	# ${INDEX_ENUM}_first_index_enum
	# index_enum_counter and number_of_indexes
	if ($number_of_indexes == 0) {
		if (not $db->delete({ -key => "${INDEX_ENUM}first_index_enum" })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete '${INDEX_ENUM}first_index_enum' record\n");
		}
		if (not $db->delete({ -key => "index_enum_counter" })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete 'index_enum_counter' record\n");
		}
		if (not $db->delete({ -key => "number_of_indexes" })) {
			croak (__PACKAGE__ . "::remove_index_from_all() - Unable to delete 'number_of_indexes' record\n");
		}
	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	1;
}

####################################################################

=over 4

=item C<remove_key_from_group({ -group =E<gt> $group, -key =E<gt> $key });>

Remove all references to a specific key for all indexes for a group.

Example: $inv_map->remove({ -group => $group, -key => $key });

Returns undef if the key speced was not even in database.
Returns '1' if the key speced was in the database, and has
			been successfully deleted.

croaks on errors.

=back

=cut

sub remove_key_from_group {
	my $self = shift;

	my ($group,$key) = simple_parms(['-group','-key'],@_);
	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::remove_key_from_group() - No database opened for use\n");
	}

	# Get the group_enum for this group
	my $group_enum = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak(__PACKAGE__ . "::remove_key_from_group() - Attempted to remove an key from an undeclared -group '$group'\n");
	}

	# Get the key_enum for this key
	my $key_enum = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_TO_KEY_ENUM$key" });
	return if (not defined $key_enum);

	# Remove the key from the KEYED_INDEX_LIST
	my ($keyed_index_list_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
	my $index_enum_data = {};
	if (defined $keyed_index_list_record) {
		$index_enum_data = _unpack_list($keyed_index_list_record);
	}
	my @index_enums = keys %$index_enum_data;
	my @zeroed_index_enums = ();
	# Remove the key from the appropriate INDEXED_KEY_LISTs
	foreach my $index_enum (@index_enums) {
		my ($indexed_key_list_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST$index_enum" });
		if (not defined $indexed_key_list_record) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Corrupted database. Unable to find '$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST' record\n");
		}
		my ($key_enum_data) = _unpack_list($indexed_key_list_record);
		delete $key_enum_data->{$key_enum};
		$indexed_key_list_record = _pack_list($key_enum_data);
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST$index_enum",
						 -value => $indexed_key_list_record })) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$INDEXED_KEY_LIST' record\n");
		}
		push(@zeroed_index_enums,$index_enum) if (length ($indexed_key_list_record) == 0);
	}
	if (defined $keyed_index_list_record) {
		$db->delete({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
	}

	# Re-thread the KEY_ENUM_TO_KEY_AND_CHAIN to omit this key_enum
	my ($key_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" });
	if (not defined $key_chain_entry) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Corrupt database. Unable to locate 'GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record for group '$group'\n");
	}
	my ($prev_key_enum,$next_key_enum) = $key_chain_entry =~ m/^(.{12}) (.{12})/;
	if (not (defined ($prev_key_enum) and defined ($next_key_enum))) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Corrupt database. Unable to parse 'GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record ($key_chain_entry) for group '$group'\n");
	}

	if ($prev_key_enum ne $NULL_ENUM) {
		my ($prev_key_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$prev_key_enum" });
		if (not defined $key_chain_entry) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Corrupt database. Unable to locate 'GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$prev_key_enum' record for group '$group'\n");
		}
		$prev_key_chain_entry =~ s/^(.{12}) (.{12})/$1 $next_key_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$prev_key_enum",
						 -value => $prev_key_chain_entry })) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$prev_key_enum' record ($prev_key_chain_entry) for group '$group'\n");
		}
	}

	if ($next_key_enum ne $NULL_ENUM) {
		my ($next_key_chain_entry) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum" });
		if (not defined $key_chain_entry) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Corrupt database. Unable to locate 'GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum' record for group '$group'\n");
		}
		$next_key_chain_entry =~ s/^(.{12})/$prev_key_enum/;
		if (not $db->put({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum",
						 -value => $next_key_chain_entry })) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Unable to save updated '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum' record ($next_key_chain_entry) for group '$group'\n");
		}
	}

	# Fix the $GROUP_ENUM_DATA${group_enum}first_key_enum if we used to be it.
	my $first_key_enum = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" });
	if (not defined $first_key_enum) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA${group_enum}_first_key_enum' record\n");
	}
	if ($first_key_enum eq $key_enum) {
		if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum",
						 -value => $next_key_enum })) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Unable to update '$GROUP_ENUM_DATA${group_enum}_first_key_enum' record to '$next_key_enum'\n")
		}
	}

	# Delete this key_enum from the KEY_ENUM_TO_KEY_AND_CHAIN
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" })) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to delete '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record from group '$group'\n");
	}

	# Delete the KEY_TO_KEY_ENUM entry for this key
	if (not $db->delete({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_TO_KEY_ENUM$key" })) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to delete '$GROUP_ENUM_DATA$group_enum$KEY_TO_KEY_ENUM$key' record from group '$group'\n");
	}

	# Decrement the number_of_keys for this group
	my ($group_number_of_keys) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_keys" });
	if (not defined $group_number_of_keys) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to locate '$GROUP_ENUM_DATA${group_enum}_number_of_keys' record for group '$group'\n");
	}
	$group_number_of_keys--;
	if (not $db->put({ -key => "$GROUP_ENUM_DATA${group_enum}_number_of_keys", -value => $group_number_of_keys })) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to update '$GROUP_ENUM_DATA${group_enum}_number_of_keys' record  to '$group_number_of_keys' for group '$group'\n");
	}

	# Decrement the number_of_keys for the system
	my ($number_of_keys) = $db->get({ -key => "number_of_keys" });
	if (not defined $number_of_keys) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to locate 'number_of_keys' record for system\n");
	}
	$number_of_keys--;
	if (not $db->put({ -key => "number_of_keys", -value => $number_of_keys })) {
		croak (__PACKAGE__ . "::remove_key_from_group() - Unable to update 'number_of_keys' record  to '$number_of_keys' for system\n");
	}

	# Remove zeroed out indexes.
	for my $index_enum (@zeroed_index_enums) {
		my $index_record = $db->get({ -key => "$INDEX_ENUM$index_enum" });
		if (not defined $index_record) {
			croak (__PACKAGE__ . "::remove_key_from_group() - Unable to locate '$INDEX_ENUM$index_enum' record.\n")
		}
		my ($prev_index_enum,$next_index_enum,$index) = $index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		$self->remove_index_from_group({ -group => $group, '-index' => $index });

	}

	# We don't want the cache returning old info after an update
	$self->clear_cache;

	1;
}

####################################################################

=over 4

=item C<list_all_keys_in_group({ -group =E<gt> $group });>

Returns an anonymous array containing a list of all
defined keys in the specified group.

Example:
 $keys = $inv_map->list_all_keys_in_group({ -group => $group });

Note: This can result in *HUGE* returned lists. If you have a
lot of records in the group, you are better off using the
iteration support ('first_key_in_group', 'next_key_in_group').

=back

=cut

sub list_all_keys_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::list_all_keys_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::list_all_keys_in_group() - Attempted to list keys for an undeclared -group: '$group'\n");
	}
	my ($first_key_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" });
	my ($keys) = [];
	my $key_enum = $first_key_enum;
	while ($key_enum ne $NULL_ENUM) {
		my ($key_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" });
		if (not defined $key_record) {
			croak (__PACKAGE__ . "::list_all_keys_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record in group '$group'\n");
		}
		my ($prev_key_enum, $next_key_enum, $key) = $key_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		if (not defined $key) {
			croak (__PACKAGE__ . "::list_all_keys_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record in group '$group'\n");
		}
		push (@$keys,$key);
		$key_enum = $next_key_enum;
	}
	return $keys;
}

####################################################################

=over 4

=item C<first_key_in_group({ -group =E<gt> $group_name });>

Returns the 'first' key in the -group based on hash ordering.

Returns 'undef' if there are no keys in the group.

Example: my $first_key = $inv_map->first_key_in_group({-group => $group});

=back

=cut

sub first_key_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::first_key_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::first_key_in_group() - Attempted to list keys for an undeclared -group: '$group'\n");
	}

	my ($first_key_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_key_enum" });
	return if ($first_key_enum eq $NULL_ENUM);

	my ($key_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$first_key_enum" });
	if (not defined $key_record) {
		croak (__PACKAGE__ . "::first_key_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$first_key_enum' record in group '$group'\n");
	}
	my ($prev_key_enum, $next_key_enum, $key) = $key_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $key) {
		croak (__PACKAGE__ . "::first_key_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$first_key_enum' record in group '$group'\n");
	}
	return $key;
}

####################################################################

=over 4

=item C<next_key_in_group({ -group =E<gt> $group, -key =E<gt> $key });>

Returns the 'next' key in the group based on hash ordering.

Returns 'undef' when there are no more keys in the group or if
the passed -key is not in the group map.

Example: my $next_key = $inv_map->next_key_in_group({ -group => $group, -key => $key });

=back

=cut

sub next_key_in_group {
	my $self = shift;

	my ($group,$key) = simple_parms(['-group','-key'],@_);
	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::next_key_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::next_key_in_group() - Attempted to list keys for an undeclared -group: '$group'\n");
	}
	my ($key_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}$KEY_TO_KEY_ENUM$key" });
	return if (not defined $key_enum); # The passed key is not in the database
	my ($key_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum" });
	if (not defined $key_record) {
		croak (__PACKAGE__ . "::next_key_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record in group '$group'\n");
	}
	my ($prev_key_enum, $next_key_enum, $this_key) = $key_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $this_key) {
		croak (__PACKAGE__ . "::next_key_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record in group '$group'\n");
	}
	return if ($next_key_enum eq $NULL_ENUM); # No next key
	my ($next_key_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum" });
	if (not defined $next_key_record) {
		croak (__PACKAGE__ . "::next_key_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$next_key_enum' record in group '$group'\n");
	}
	my ($next_prev_key_enum, $next_next_key_enum, $next_key) = $next_key_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $next_key) {
		croak (__PACKAGE__ . "::next_key_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$KEY_ENUM_TO_KEY_AND_CHAIN$key_enum' record in group '$group'\n");
	}
	$next_key;
}

####################################################################

=over 4

=item C<list_all_indexes_in_group({ -group =E<gt> $group });>

Returns an anonymous array containing a list of all
defined indexes in the group

Example: $indexes = $inv_map->list_all_indexes_in_group({ -group => $group });

Note: This can result in *HUGE* returned lists. If you have a
lot of records in the group, you are better off using the
iteration support (first_index_in_group(), next_index_in_group())

=back

=cut

sub list_all_indexes_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::list_all_indexes_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::list_all_indexes_in_group() - Attempted to list indexes for an undeclared -group: '$group'\n");
	}
	my ($first_index_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
	my ($indexes) = [];
	return $indexes if ((not defined $first_index_enum) or ($first_index_enum eq $NULL_ENUM));
	my $index_enum = $first_index_enum;
	while ($index_enum ne $NULL_ENUM) {
		my ($group_index_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
		if (not defined $group_index_record) {
			croak (__PACKAGE__ . "::list_all_indexes_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' record in group '$group'\n");
		}
		my ($prev_group_index_enum, $next_group_index_enum) = $group_index_record =~ m/^(.{12}) (.{12})$/;
		if (not defined $prev_group_index_enum) {
			croak (__PACKAGE__ . "::list_all_indexes_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' record in group '$group'\n");
		}
		my ($system_index_record) = $db->get({ -key => "$INDEX_ENUM$index_enum" });
		if (not defined $system_index_record) {
			croak (__PACKAGE__ . "::list_all_indexes_in_group() - Corrupt database. Unable to locate '$INDEX_ENUM$index_enum' record\n");
		}
		my ($prev_system_index_enum, $next_system_index_enum, $index) = $system_index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		push (@$indexes,$index);
		$index_enum = $next_group_index_enum;
	}
	return $indexes;
}

####################################################################

=over 4

=item C<first_index_in_group;>

Returns the 'first' index in the -group based on hash ordering.
Returns 'undef' if there are no indexes in the group.

Example: my $first_index = $inv_map->first_index_in_group({ -group => $group });

=back

=cut

sub first_index_in_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::first_index_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::list_all_indexes_in_group() - Attempted to list indexes for an undeclared -group: '$group'\n");
	}
	my ($first_index_enum) = $db->get({ -key => "$GROUP_ENUM_DATA${group_enum}_first_index_enum" });
	return if ($first_index_enum eq $NULL_ENUM);

	my ($indexes) = [];
	my $index_enum = $first_index_enum;
	my ($system_index_record) = $db->get({ -key => "$INDEX_ENUM$index_enum" });
	if (not defined $system_index_record) {
		croak (__PACKAGE__ . "::list_all_indexes_in_group() - Corrupt database. Unable to locate '$INDEX_ENUM$index_enum' record\n");
	}
	my ($prev_system_index_enum, $next_system_index_enum, $index) = $system_index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	return if (not defined $index);
	return $index;
}

####################################################################

=over 4

=item C<next_index_in_group({-group => $group, -index => $index});>

Returns the 'next' index in the -group based on hash ordering.
Returns 'undef' if there are no more indexes.

Example: my $next_index = $inv_map->next_index_in_group({-group => group, -index => $index});

=back

=cut

sub next_index_in_group {
	my $self = shift;

	my ($group,$index) = simple_parms(['-group','-index'],@_);
	my ($db)           = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::next_index_in_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	if (not defined $group_enum) {
		croak (__PACKAGE__ . "::next_index_in_group() - Attempted to list indexes for an undeclared -group: '$group'\n");
	}
	my ($index_enum) = $db->get({ -key => "$INDEX$index" });
	return if (not defined $index_enum); # The passed index is not in the database
	my ($index_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum" });
	return if (not defined $index_record); # The passed index is not in the group
	my ($prev_index_enum, $next_index_enum) = $index_record =~ m/^(.{12}) (.{12})$/;
	if (not defined $prev_index_enum) {
		croak (__PACKAGE__ . "::next_index_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$index_enum' record in group '$group'\n");
	}
	return if ($next_index_enum eq $NULL_ENUM); # No next index
	my ($next_index_record) = $db->get({ -key => "$INDEX_ENUM$next_index_enum" });
	if (not defined $next_index_record) {
		croak (__PACKAGE__ . "::next_index_in_group() - Corrupt database. Unable to locate '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum' record in group '$group'\n");
	}
	my ($system_prev_index_enum, $system_next_index_enum, $next_index) = $next_index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $next_index) {
		croak (__PACKAGE__ . "::next_index_in_group() - Corrupt database. Unable to parse '$GROUP_ENUM_DATA$group_enum$INDEX_ENUM_GROUP_CHAIN$next_index_enum' record in group '$group'\n");
	}
	$next_index;
}

####################################################################

=over 4

=item C<list_all_indexes;>

Returns an anonymous array containing a list of all
defined indexes in the map.

Example: $indexes = $inv_map->list_all_indexes;

Note: This can result in *HUGE* returned lists. If you have a
lot of records in the map or do not have a lot memory,
you are better off using the iteration support
('first_index', 'next_index')

=back

=cut

sub list_all_indexes {
	my $self = shift;

	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::list_all_indexes() - No database opened for use\n");
	}
	my ($first_index_enum) = $db->get({ -key => "${INDEX_ENUM}first_index_enum" });
	my ($indexes) = [];
	return $indexes if ((not defined $first_index_enum) or ($first_index_enum eq $NULL_ENUM));
	my $index_enum = $first_index_enum;
	while ($index_enum ne $NULL_ENUM) {
		my ($index_record) = $db->get({ -key => "$INDEX_ENUM$index_enum" });
		if (not defined $index_record) {
			croak (__PACKAGE__ . "::list_all_indexes - Corrupt database. Unable to locate '$INDEX_ENUM$index_enum' record\n");
		}
		my ($prev_index_enum, $next_index_enum, $index) = $index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		push (@$indexes,$index);
		$index_enum = $next_index_enum;
	}
	$indexes;
}

####################################################################

=over 4

=item C<first_index;>

Returns the 'first' index in the system based on hash ordering.
Returns 'undef' if there are no indexes.

Example: my $first_index = $inv_map->first_index;

=back

=cut

sub first_index {
	my $self = shift;

	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::first_index() - No database opened for use\n");
	}

	my ($first_index_enum) = $db->get({ -key => "${INDEX_ENUM}first_index_enum" });
	return if ($first_index_enum eq $NULL_ENUM);

	my ($index_record) = $db->get({ -key => "$INDEX_ENUM$first_index_enum" });
	if (not defined $index_record) {
		croak (__PACKAGE__ . "::first_index - Corrupt database. Unable to locate '$INDEX_ENUM$first_index_enum' record\n");
	}
	my ($prev_index_enum, $next_index_enum, $index) = $index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $index) {
		croak (__PACKAGE__ . "::first_index - Corrupt database. Unable to parse '$INDEX_ENUM$first_index_enum' record\n");
	}
	$index;
}

####################################################################

=over 4

=item C<next_index({-index =E<gt> $index});>

Returns the 'next' index in the system based on hash ordering.
Returns 'undef' if there are no more indexes.

Example: my $next_index = $inv_map->next_index({-index => $index});

=back

=cut

sub next_index {
	my $self = shift;

	my ($index) = simple_parms(['-index'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::next_index() - No database opened for use\n");
	}
	my ($index_enum) = $db->get({ -key => "$INDEX$index" });
	return if (not defined $index_enum); # The passed index is not in the database
	my ($index_record) = $db->get({ -key => "$INDEX_ENUM$index_enum" });
	if (not defined $index_record) {
		croak(__PACKAGE__ . "::next_index() - Corrupt database. Unable to locate '$INDEX_ENUM$index_enum'\n");
	}
	my ($prev_index_enum, $next_index_enum,$this_index) = $index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $this_index) {
		croak (__PACKAGE__ . "::next_index() - Corrupt database. Unable to parse '$INDEX_ENUM$index_enum' record\n");
	}
	return if ($next_index_enum eq $NULL_ENUM); # No next index
	my ($next_index_record) = $db->get({ -key => "$INDEX_ENUM$next_index_enum" });
	if (not defined $next_index_record) {
		croak (__PACKAGE__ . "::next_index() - Corrupt database. Unable to locate '$INDEX_ENUM$next_index_enum' record\n");
	}
	my ($prev_next_index_enum, $next_next_index_enum, $next_index) = $next_index_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $next_index) {
		croak (__PACKAGE__ . "::next_index() - Corrupt database. Unable to parse '$INDEX_ENUM$next_index_enum' record\n");
	}
	$next_index;
}

####################################################################

=over 4

=item C<list_all_groups;>

Returns an anonymous array containing a list of all
defined groups in the map.

Example: $groups = $inv_map->list_all_groups;

If you have a lot of groups in the map or do not have a lot of memory,
you are better off using the iteration support ('first_group',
'next_group')

=back

=cut

sub list_all_groups {
	my $self = shift;

	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::list_all_groups() - No database opened for use\n");
	}
	my ($first_group_enum) = $db->get({ -key => "${GROUP_ENUM}first_group_enum" });
	my ($groups) = [];
	return $groups if ((not defined $first_group_enum) or ($first_group_enum eq $NULL_ENUM));
	my $group_enum = $first_group_enum;
	while ($group_enum ne $NULL_ENUM) {
		my ($group_record) = $db->get({ -key => "$GROUP_ENUM$group_enum" });
		if (not defined $group_record) {
			croak (__PACKAGE__ . "::list_all_groups - Corrupt database. Unable to locate '$GROUP_ENUM$group_enum' record\n");
		}
		my ($prev_group_enum, $next_group_enum, $group) = $group_record =~ m/^(.{12}) (.{12}) (.*)$/s;
		push (@$groups,$group);
		$group_enum = $next_group_enum;
	}
	$groups;
}

####################################################################

=over 4

=item C<first_group;>

Returns the 'first' group in the system based on hash ordering.
Returns 'undef' if there are no groups.

Example: my $first_group = $inv_map->first_group;

=back

=cut

sub first_group{
	my $self = shift;

	my ($db)         = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::first_group() - No database opened for use\n");
	}

	my ($first_group_enum) = $db->get({ -key => "${GROUP_ENUM}first_group_enum" });
	return if ($first_group_enum eq $NULL_ENUM);

	my ($group_record) = $db->get({ -key => "$GROUP_ENUM$first_group_enum" });
	if (not defined $group_record) {
		croak (__PACKAGE__ . "::first_group - Corrupt database. Unable to locate '$GROUP_ENUM$first_group_enum' record\n");
	}
	my ($prev_group_enum, $next_group_enum, $group) = $group_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $group) {
		croak (__PACKAGE__ . "::first_index - Corrupt database. Unable to parse '$GROUP_ENUM$first_group_enum' record\n");
	}
	$group;
}

####################################################################

=over 4

=item C<next_group ({-group =E<gt> $group });>

Returns the 'next' group in the system based on hash ordering.
Returns 'undef' if there are no more groups.

Example: my $next_group = $inv_map->next_group({-group => $group});

=back

=cut

sub next_group {
	my $self = shift;

	my ($group) = simple_parms(['-group'],@_);
	my ($db)    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::next_group() - No database opened for use\n");
	}
	my ($group_enum) = $db->get({ -key => "$GROUP$group" });
	return if (not defined $group_enum); # The passed group is not in the database
	my ($group_record) = $db->get({ -key => "$GROUP_ENUM$group_enum" });
	if (not defined $group_record) {
		croak(__PACKAGE__ . "::next_group() - Corrupt database. Unable to locate '$GROUP_ENUM$group_enum'\n");
	}
	my ($prev_group_enum, $next_group_enum,$this_group) = $group_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $this_group) {
		croak (__PACKAGE__ . "::next_group() - Corrupt database. Unable to parse '$GROUP_ENUM$group_enum' record\n");
	}
	return if ($next_group_enum eq $NULL_ENUM); # No next group
	my ($next_group_record) = $db->get({ -key => "$GROUP_ENUM$next_group_enum" });
	if (not defined $next_group_record) {
		croak (__PACKAGE__ . "::next_group() - Corrupt database. Unable to locate '$GROUP_ENUM$next_group_enum' record\n");
	}
	my ($prev_next_group_enum, $next_next_group_enum, $next_group) = $next_group_record =~ m/^(.{12}) (.{12}) (.*)$/s;
	if (not defined $next_group) {
		croak (__PACKAGE__ . "::next_group() - Corrupt database. Unable to parse '$GROUP_ENUM$next_group_enum' record\n");
	}
	$next_group;
}

####################################################################
#
# Internals
#
#The routines after this point are _internal_ to the object.
#Do not access them from outside the object.
#
#They are documented for code maintainence reasons only.
#
#You Have Been Warned. ;)
#

####################################################################
# _bare_search($parm_ref);
#
#Performs a query on the map and returns the results as a
#an anonymous array containing the keys and rankings.
#
#Example:
#
# my $query = Search::InvertedIndex::Query->new(...);
# my $result = $inv_map->search({ -query => $query });
#
#Performs a complex multi-key match search with boolean logic and
#optional search term weighting.
#
#The search request is formatted as follows:
#
#my $result = $inv_map->search({ -query => $query });
#
#where '$query' is a Search::InvertedIndex::Query object.
#
#
#Each node can either be a specific search term with an optional weighting
#term (a Search::InvertedIndex::Query::Leaf object) or a logic term with
#its own sub-branches (a Search::Inverted::Query object).
#
#The weightings are applied to the returned matches for each search term by
#multiplication of their base ranking before combination with the other logic terms.
#
#This allows recursive use of search to resolve arbitrarily
#complex boolean searches and weight different search terms.
#
#Returns a reference to a hash of indexes and their rankings.
#

sub _bare_search {
	my $self = shift;

	my $parms = parse_parms ({ -parms => \@_,
							   -legal => ['-use_cache'],
							-required => ['-query'],
							-defaults => { -cache => 0},
						  });

	if (not defined $parms) {
		my $error_message = Class::ParmList->error;
		croak (__PACKAGE__ . "::search() - $error_message\n");
	}
	my ($query,$use_cache) = $parms->get('-query','-use_cache');
	my $db    = $self->get(-database);
	if (not $db) {
		croak (__PACKAGE__ . "::search() - No database opened for use\n");
	}

	my $group_enum_cache = {};
	my $terms = [];

	# Load the leaf term data
	my ($logic,$weight,$leafs,$nodes) = $query->get(-logic,-weight,-leafs,-nodes);
	$logic = lc ($logic);
	if ($logic !~ m/^(and|or|nand)$/) {
		croak (__PACKAGE__ . "::search() - Illegal -logic value of '$logic'. Must be one of 'and','or','nand'\n");
	}
	foreach my $leaf (@$leafs) {
		my ($weight,$group,$key) = $leaf->get(-weight,-group,-key);
		my $group_enum;
		if (not exists $group_enum_cache->{$group}) {
			$group_enum = $db->get({ -key => "$GROUP$group" });
		} else {
			$group_enum = $group_enum_cache->{$group};
		}
		if (not defined $group_enum) {
			croak (__PACKAGE__ . "::search() - No group '$group' defined in map\n");
		}
		my $key_enum = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEY_TO_KEY_ENUM$key" });
		if (not defined $key_enum) {
			push (@$terms,{});
			next;
		}
		my ($keyed_index_list_record) = $db->get({ -key => "$GROUP_ENUM_DATA$group_enum$KEYED_INDEX_LIST$key_enum" });
		$keyed_index_list_record = '' if (not defined $keyed_index_list_record);
		my $index_data = _unpack_list($keyed_index_list_record);
		if ($weight != 1) {
			my (@index_enums) = keys (%$index_data);
			foreach my $index_enum (@index_enums) {
				$index_data->{$index_enum} *= $weight;
			}
		}
		push (@$terms,$index_data);
	}

	# Load the node term data via recursion
	foreach my $node (@$nodes) {
		my $index_data = $self->_bare_search({ -query => $node, -use_cache => 0 });
		push (@$terms,$index_data);
	}

	# Now merge the results with the applied logic condition
	my $merge;
	if ($logic eq 'and') {
		$merge = $self->_and($terms);
	} elsif ($logic eq 'or') {
		$merge = $self->_or($terms);
	} elsif ($logic eq 'nand') {
		$merge = $self->_nand($terms);
	}

	# Apply the weighting
	if ($weight != 1) {
		while (my ($key,$value) = each %$merge) { $merge->{$key} *= $weight; }
	}

	$merge;
}

####################################################################
#_get_data_for_index_enum($parm_ref);
#
#Returns the data record for the passed -index_enum.
#
#Returns undef if no data record exists for the requested -index_enum.
#
#Example:
#  my $data = $self->_get_data_for_index_enum({ -index_enum => $index_enum });
#

sub _get_data_for_index_enum {
	my ($self) = shift;

	my ($index_enum) = simple_parms(['-index_enum'],@_);
	my ($db,$thaw)   = $self->get('-database','-thaw');
	if (not $db) {
		croak (__PACKAGE__ . "::search() - No database opened for use\n");
	}
	my ($data_record) = $db->get({ -key => "$INDEX_ENUM_DATA${index_enum}_data" });
	return if (not defined $data_record);
	my ($data) = &$thaw($data_record);
	$data;
}

####################################################################
# _and($terms);
#
# Takes the passed list of search data results and merges them
# via logical _and. Merged ranking is the sum of the individual rankings.
#

sub _and {
	my $self = shift;

	my ($terms) = @_;

	my $n_terms = $#$terms + 1;
	return {} if ($n_terms == 0);
	return $terms->[0] if ($n_terms == 1);
	my $first   = shift @$terms;
	my %merged  = ();
	%merged     = %$first;
	my ($key);
	foreach my $term (@$terms) {
		my @merge_keys = keys %merged;
		foreach $key (@merge_keys) {
			if (exists ($term->{$key})) {
				$merged{$key} += $term->{$key};
			} else {
				delete $merged{$key};
			}
		}
	}
#    foreach $key (keys %merged) { # arithmetical average each term
#        $merged{$key} /= $n_terms;
#    }

	return \%merged;
}

####################################################################
# _nand($terms);
#
#Takes the passed list of search data results and merges them
#via logical NAND (Not And). Merged ranking is the sum
#of the individual rankings.
#

sub _nand {
	my $self = shift;

	my ($terms) = @_;

	my $n_terms = $#$terms + 1;
	return {} if ($n_terms == 0);
	return {} if ($n_terms == 1);
	my $first   = shift @$terms;
	my %merged  = ();
	%merged     = %$first;
	my %count   = ();
	foreach my $key (keys %merged) {
		$count{$key} = 1;
	}
	my ($key);
	foreach my $term (@$terms) {
		my @term_keys = keys %$term;
		foreach $key (@term_keys) {
			$merged{$key} += $term->{$key};
			$count{$key}++;
		}
	}

	# Discard things that appear in ALL terms
	my @merge_keys = keys %merged;
	foreach $key (@merge_keys) {
		if ($count{$key} == $n_terms) {
			delete $merged{$key};
		}
	}
	return \%merged;
}

####################################################################
# _or($terms);
#
# Takes the passed list of search data results and merges them
# via logical OR. Merged ranking is the sum of the individual rankings.
#

sub _or {
	my $self = shift;

	my ($terms) = @_;

	my $n_terms = $#$terms + 1;
	return {} if ($n_terms == 0);
	return $terms->[0] if ($n_terms == 1);
	my $first   = shift @$terms;
	my %merged  = ();
	%merged  = %$first;
	my ($key);
	my %count   = ();
	foreach my $key (keys %merged) {
		$count{$key} = 1;
	}
	foreach my $term (@$terms) {
		my @term_keys = keys %$term;
		foreach $key (@term_keys) {
			$merged{$key} += $term->{$key};
			$count{$key}++;
		}
	}

	# Compute arithmetical averages of the terms
#    my @merge_keys = keys %merged;
#    foreach $key (@merge_keys) {
#        $merged{$key} /= $count{$key};
#    }

	return \%merged;
}


####################################################################
# _increment_enum($enum_value);
#
# Internal method. Not for access outside of the module.
#
# Increments an 'enum' (internally a 12 digit hexadecimal number) by 1.
#

sub _increment_enum {
	my $self = shift;

	my ($enum) = @_;
	if ($enum !~ m/^([0-9a-fA-F]{4})([0-9a-fA-F]{4})([0-9a-fA-F]{4})$/) {
		croak (__PACKAGE__ . "::_increment_enum() - passed an invalid enum value of '$enum'\n");
	}
	my (@hexwords) = ($1,$2,$3);
	my $word2 = hex($hexwords[2]);
	$word2++;
	if ($word2 > 65535) {
		my $word1 = hex($hexwords[1]);
		$word2 = 0;
		$word1++;
		if ($word1 > 65535) {
			my $word0 = hex($hexwords[0]);
			$word1 = 0;
			$word0++;
			$hexwords[0] = sprintf('%0.4lx',$word0);
		}
		$hexwords[1] = sprintf('%0.4lx',$word1);
	}
	$hexwords[2] = sprintf('%0.4lx',$word2);
	join('',@hexwords);
}

################################################################
#_untaint($string);
#
#Untaints the passed string. Use with care.

sub _untaint {
	my ($self) = shift;
	my $string;
	if (ref $self) {
		$string = $self;
	} else {
		($string) = @_;
	}
	my ($untainted_string) = $string =~ m/^(.*)$/s;
	$untainted_string;
}

####################################################################
#
# DESTROY;
#
# Closes the currently open -map and flushes all associated buffers.
#

sub DESTROY {
	my ($self) = shift;
	$self->close;
}

# ################################################################
#
# DATABASE STRUCTURES
#
# The inverted database uses a complex overlay built on a generic
# key/value accessible database (it really is fairly 'database agnostic').
#
# It is organized into sub-sets of information by database key name space:
#
#  ; Stringifier. The serializer used for packing information for storage
#  $STRINGIFIER            -> 'Data::Dumper' or 'Storable'
#
#  $VERSION                -> The version number of Search::InvertedIndex
#                             matching this database.
#
#  ; Counter. Incremented for new groups, decremented for deleted groups.
#  number_of_groups        -> # (decimal integer)
#
#  ; Counter. Incremented for new indexes, decremented for deleted indexes.
#  number_of_indexes       -> # (decimal integer)
#
#  ; Counter. Incremented for new keys, decremented for deleted keys.
#  number_of_keys          -> # (decimal integer)
#
#  ; The 'high water' mark used in assigning new index_enum keys
#  index_enum_counter      -> # (12 digit hex number)
#
#  ; Maps an index ("file") to its assigned index enumeration key
#  $INDEX<index>               -> index_enum
#
#  ; Maps the assigned index enumeration back to the index ("file") and
#  ; provides pointers to the 'next' and 'prev' index_enums in the system
#  $INDEX_ENUM<index_enum>         -> _next_index_enum_ _prev_index_enum_ index
#
#  ; Maps the 'first' 'index_enum' for the system
#  ${INDEX_ENUM}first_index_enum     -> index_enum of 'first' index_enum for the system
#
#  ; Data record for the index ("File"). Wrapped using 'Storable' or 'Data::Dumper'
#  $INDEX_ENUM_DATA<index_enum>_data   -> data
#
#  ; The 'high water' mark used in assigning new group_enum keys
#  group_enum_counter      -> # (12 digit hex number)
#
#  ; Maps a group's name to its assigned group enumeration key
#  $GROUP<groupname>           -> group_enum
#
#  ; Maps the assigned group enumeration key to a group and provides
#  ; pointers to the 'next' and 'previous' groups in the system.
#  $GROUP_ENUM<group_enum>         -> _prev_group_enum_ _next_group_enum_ $group
#
#  ; Maps the 'first' 'group_enum' for the system
#  ${GROUP_ENUM}first_group_enum     -> group_enum of 'first' group_enum for the system
#
#  ; Counter. Incremented for new keys, decremented for deleted keys.
#  $GROUP_ENUM_DATA<group_enum>_number_of_keys     -> # (decimal integer)
#
#  ; Counter. Incremented for new indexes, decremented for deleted indexes.
#  $GROUP_ENUM_DATA<group_enum>_number_of_indexes  -> #  (decimal integer)
#
#  ; 'High water' mark used in assigning new key_enum values for keys
#  $GROUP_ENUM_DATA<group_enum>_key_enum_counter   -> # (12 digit hex number)
#
#  ; Maps the 'first' 'key_enum' for the group
#  $GROUP_ENUM_DATA<group_enum>_first_key_enum         -> key_enum of 'first' key_enum
#
#  ; Maps the 'first' 'index_enum' for the group
#  $GROUP_ENUM_DATA<group_enum>_first_index_enum       -> index_enum of 'first' index_enum for the group
#
#  ; network order packed list of (6 byte) key_enums and
#  ; (16 bit signed) relevance rankings for the specified group_enum
#  ; and index_enum
#  $GROUP_ENUM_DATA<group_enum>$INDEXED_KEY_LIST<index_enum>           -> key_list
#
#  ; Pointers to the 'next' and 'previous' index_enums for this group.
#  $GROUP_ENUM_DATA<group_enum>$INDEX_ENUM_GROUP_CHAIN<index_enum>           -> _prev_index_enum_ _next_index_enum_
#
#  ; network order packed list of (6 byte) index_enums
#  ; and (16 bit signed) relevance rankings for the specified group_enum
#  ; and key_enum
#  $GROUP_ENUM_DATA<group_enum>$KEYED_INDEX_LIST<key_enum>             -> index_list
#
#  ; Maps 'key's to 'key_enum's
#  $GROUP_ENUM_DATA<group_enum>$KEY_TO_KEY_ENUM<key>                  -> key_enum
#
#  ; Maps 'key_enum's to 'key's and provides pointers to the
#  ; 'next' and 'previous' keys for the group
#  $GROUP_ENUM_DATA<group_enum>$KEY_ENUM_TO_KEY_AND_CHAIN<key_enum>             -> _prev_key_enum_ _next_key_enum_ key
#

=head1 VERSION

1.14

=head1 COPYRIGHT

Copyright 1999-2002, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Integrate code and documentation patches from Kate Pugh. Seperate POD into .pod files.

Concept item for evaluation: By storing a dense list of all indexed keywords,
you would be able to use a regular expression or other fuzzy search matching
scheme comparatively efficiently, locate possible words via a grep and then
search on the possibilities. Seems to make sense to implement that as _another_
module that uses this module as a backend. 'Search::InvertedIndex::Fuzzy' perhaps.

=head1 SEE ALSO

 Search::InvertedIndex::Query  Search::InvertedIndex::Query::Leaf
 Search::InvertedIndex::Result Search::InvertedIndex::Update
 Search::InvertedIndex::DB::DB_File_SplitHash
 Search::InvertedIndex::DB::Mysql

=cut

1;
