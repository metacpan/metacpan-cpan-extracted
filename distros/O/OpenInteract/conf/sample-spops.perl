# This is a sample spops.perl file. Its purpose is to define the
# objects that will be used in your package. Each of the keys is
# commented below.

# If you do not plan on defining any objects for your package, then
# you can skip this discussion and leave the file as-is.

# Note that you must edit this file by hand -- there is no web-based
# interface for editing a package's spops.perl (or other)
# configuration files.

# You can have any number of entries in this file, although they
# should all be members of the single hashref (any name is ok) in the
# file.

# The syntax for this file is checked when you do a 'check_package'
# with the 'oi_manage' tool -- this is a good idea to do.

# Finally, you can retrieve this information (some in a slightly
# different format) at anytime by doing:
#
#   my $hashref = $object_class->CONFIG;
# or
#   my $hashref = $R->object-alias->CONFIG;

# For more information about the SPOPS configuration process, see
# 'perldoc SPOPS::Configure' and 'perldoc SPOPS::Configure::DBI'

$spops = {

# 'object-alias' - Defines how you can refer to the object class
# within OpenInteract. For portability and a host of other reasons, OI
# sets up aliases for the SPOPS object classes so you can refer to
# them from $R. For instance, if you are in an application 'MyApp':
#
#  my $user_class = $R->user;
#  print ">> User Class: <<$user_class>
#
#  Output: '>> User Class: <<MyApp::User>>'
#
# This way, your application can do:
#
#  my $object = $R->myobjectalias->fetch( $object_id );
#
# and not care about the different application namespaces and such.
#
# Note that the 'alias' key allows you to setup additional aliases for
# this object class.

#            'user' => {

# class - Defines the class this object will be known by. When you
# develop you'll refer to it here as 'OpenInteract::Blah' -- when the
# package is applied to a website, the class will be modified by
# OpenInteract to be in that website's namespace.

#              class        => 'OpenInteract::User',

# code_class - Perl module from which we read subroutines into the
# namespace of this class. This is *entirely optional*, only needed if
# you have additional behaviors to program into our object.

#              code_class   => 'OpenInteract::User',

# isa - Define the parents of this class. Every class should have at
# least 'OpenInteract::SPOPS::DBI' or 'OpenInteract::SPOPS::LDAP' and
# some sort of SPOPS implementation, usually 'SPOPS::DBI'

#              isa          => [ qw/ OpenInteract::SPOPS::DBI  SPOPS::Secure  
#                                    SPOPS::DBI::MySQL  SPOPS::DBI / ],

# field - List of fields/properties of this object

#              field        => [ qw/ user_id first_name last_name email 
#                                    login_name password theme_id / ],

# id_field - Name of primary key field -- this only identifies the
# object uniquely. You still need to deal with generating new values,
# either by an auto-incrementing mechanism (in which case you need to
# use the appropriate SPOPS::DBI class) or something else.

#              id_field     => 'user_id',

# increment_field - Whether to use (or be aware of) auto-incrementing
# features of your database driver.

#              increment_field => 1,

# no_insert - Fields for which we should not try to insert
# information, ever. If you're using a SPOPS implementation (e.g.,
# 'SPOPS::DBI::MySQL') which generates primary key values for you, be
# sure to put your 'id_field' value here.

#              no_insert    => [ qw/ user_id / ],

# no_update - Fields we should never update

#              no_update    => [ qw/ user_id / ],

# skip_undef - Values for these fields will not be inserted/updated at
# all if the value within the object is undefined. This, along with
# 'sql_defaults', allows you to specify default values. 

#              skip_undef   => [ qw/ theme_id / ],

# sql_defaults - List fields for which a default is defined. Note that
# SPOPS::DBI will re-fetch the object after first creating it if you
# have fields listed here to ensure that the object always reflects
# what's in the database.

#              sql_defaults => [ qw/ theme_id / ],

# base_table - Name of the table we store the object tinformation
# in. Note that if you have 'db_owner' defined in your application's
# 'server.perl' file (in the 'db_info' key), then SPOPS will prepend
# that (along with a period) to the table name here. For instance, if
# the db_owner is defined to 'dbo', we would use the table name
# 'dbo.sys_user'

#              base_table   => 'sys_user',

# alias - Additional aliases to use for referring to this object
# class. For instance, if we put 'project_user' here we'd be able to
# retrieve this class name by using '$R->user' AND '$R->project_user'.

#              alias        => [],

# has_a - Define a 'has-a' relationship between objects from this
# class and any number of other objects. Each key in the hashref is an
# object class (which gets translated to your app's class when you
# apply the package to an application) and the value is an arrayref of
# field names. The field name determines the name of the routine
# created: if the field name matches up with the 'id_field' of that
# class, then we create a subroutine named for the object's
# 'object-alias' field. If the field name does not match, we append
# '_{object_alias}' to the end of the field. (See 'perldoc
# SPOPS::Configre' for more.)

#              has_a        => { 'OpenInteract::Theme' => [ 'theme_id' ], },

# links_to - Define a 'links-to' relationship between objects from
# this class and any number of other objects. This may be modified
# soon -- see 'perldoc SPOPS::Configure::DBI' for more.

#              links_to     => { 'OpenInteract::Group' => 'sys_group_user' },

# creation_security - Determine the security to apply to newly created
# objects from this class. (See 'SPOPS::Secure')

#              creation_security => {
#                 u   => 'WRITE',
#                 g   => { 3 => 'WRITE' },
#                 w   => 'READ',
#              },

# track - Which actions should we log? True value logs action, false
# value does not.

#              track => {
#                 create => 0, update => 1, remove => 1
#              },

# display - Allow the object to be able to generate a URL to display itself.

#              display => { url => '/User/show/', class => 'OpenInteract::Handler::User', method => 'show' },

# name - Either a field name or a coderef (first and only arg =
# object) to generate a name for a particular object.

#              name => sub { return $_[0]->full_name },

# object_name - Name of this class of objects

#              object_name => 'User',
#            },

};