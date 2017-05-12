#########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

package Agni;

=encoding utf-8

=head1 NAME

Agni - persistent data and objects

=head1 SYNOPSIS

I<This module requires the PApp module to be installed and working. Please
read the LICENSE file: this version of Agni is neither GPL nor BSD
licensed).>

=head1 DESCRIPTION

Agni is the God of the Sun and Fire. The rest is obvious...

Most of these functions are low-level stuff. Better look at the methods
of the agni root object (本) first, which has most of the functionality
packaged in a nicer way.

=head2 FUNCTIONS

=over 4

=cut

use strict qw(vars subs);

use utf8;

use Carp;

use PApp::Config qw(DBH $DBH $Database); DBH;

use PApp ();
use PApp::Env;
use PApp::SQL;
use PApp::Event;
use PApp::Preprocessor;
use PApp::PCode qw(pxml2pcode perl2pcode pcode2perl);
use PApp::Callback ();
use PApp::Exception;
use PApp::I18n ();

# load these so their callbacks can be registered
# TODO: should be done by papp proper
use PApp::EditForm ();
use PApp::XPCSE ();

use Convert::Scalar ":utf8";

use base Exporter::;

our $app; # current application object
our $env; # current content::environment

our %temporary; # used by the "temporary" attribute type

BEGIN {
   *DEVEL_TRACE = sub () { 0 }
      unless defined &DEVEL_TRACE;
}

BEGIN {
   # I was lazy, all the util xs functions are in PApp.xs
   require XSLoader;
   XSLoader::load PApp, $PApp::VERSION unless defined &PApp::bootstrap;
}

our @EXPORT = qw(
      require_path new_objectid

      %obj_cache

      path_obj_by_gid gid obj_of

      %pathid @pathname @pathmask @subpathmask @parpathmask @parpath

      agni_exec agni_refresh
);

our @EXPORT_OK = (@EXPORT, qw(
      *app *env
));

# packages used to provide useful compilation environment
use PApp::HTML;

our %obj_cache; # obj_cache{$gid}[$pathid]

my @agni_bootns; # boot package objects
my %ns_cache;    # the package object cache

our %pathid;      # name => id
our @parpath;     # id => id
our @pathname;    # id => name
our @pathmask;    # id => maskbit
our @subpathmask; # id => subpath mask (|| of path + all subpaths)
our @parpathmask; # id => parent path mask (|| of all parents, sans path itself)

our $last_compile_status;

# reserved object gids
# <20 == must only use string types and perl methods, for bootstrapping.

our $OID_OBJECT			= 1;
our $OID_ATTR			= 2;
our $OID_ATTR_NAMED		= 3;
our $OID_METHOD			= 4;
our $OID_METHOD_ARGS		= 5;
our $OID_DATA			= 6;
our $OID_DATA_STRING		= 7;
our $OID_METHOD_PERL		= 8;
our $OID_ATTR_SQLCOL		= 9;

our $OID_METHOD_PXML		= 20;
our $OID_META			= 21;
our $OID_META_DESC		= 22;
our $OID_META_NAME		= 23;
our $OID_ATTR_NAME		= 24;
our $OID_ATTR_CONTAINER		= 25;
our $OID_DATA_REF		= 26;
our $OID_IFACE_CONTAINER	= 27; # object has a gc_enum, + obj_enum methods (NYI)
our $OID_META_NOTE		= 28; # notes/flags for objects
our $OID_ATTR_TAG		= 29; # objects used as tags for containers
our $OID_META_PACKAGE		= 30; # perl package name
our $OID_INTERFACE		= 31; # class interface
our $OID_ROOTSET		= 32; # a container containing all objects that are alive "by default"
our $OID_ISA			= 33; # the data/method parent for lookups
our $OID_ISA_METHOD		= 5100001742; # the gids start to get ugly here
our $OID_ISA_DATA		= 5100001741;
our $OID_CMDLINE_HANDLER	= 21474836484; # util::cmdline
our $OID_META_PACKAGE		= 4295048763;
our $OID_PACKAGE_DEFAULT	= 4295049779; # lots of special-casing for that one
our $OID_META_PARCEL		= 5100000280;
our $OID_NAMESPACES		= 5100003444; # circular reference of namespace_base to namespace
our $OID_ISA_NAMESPACE		= 5100003446;
our $OID_COMMITINFO		= 5100004671; # used in split_obj, the committer, and more

our %BOOTSTRAP_LEVEL; # indexed by {gid}

sub UPDATE_PATHID() { 0x01 }
sub UPDATE_ATTR()   { 0x02 }
sub UPDATE_CLASS()  { 0x04 }
sub UPDATE_PATHS()  { 0x08 }
sub UPDATE_ALL()    { 0x10 }

sub init_paths {
   %pathid =
   @pathname =
   @pathmask =
   @subpathmask =
   @parpathmask = ();

   # all paths, shorter ones first
   my $st = sql_exec \my($id, $mask, $name), "select id, (1 << id), path from obj_path order by path";
   while ($st->fetch) {
      $pathid{$name} = $id;
      $pathname[$id] = $name;
      $pathmask[$id] = $mask;
      $parpathmask[$id] = sql_fetch "select coalesce(sum(1 << id), 0) from obj_path
                                     where left(?, length(path)) = path and ? != path",
                                     $name, $name;
      $subpathmask[$id] = sql_fetch "select coalesce(sum(1 << id), 0) from obj_path
                                     where path like ?",
                                     "$name%";
      $parpath[$id] = $pathid{$name} if $name =~ s/[^\/]+\/$//;
   }

   for (values %obj_cache) {
      for (@$_) {
         $_
            and $_->{_paths} =
               sql_fetch "select paths from obj where gid = ? and paths & (1 << ?) <> 0",
                         $_->{_gid}, $_->{_path};
      }
   }
}

sub top_path {
   my $paths = $_[0];
   for (sort { (length $a) <=> (length $b) } keys %pathid) {
      return $pathid{$_} if and64 $paths, $pathmask[$pathid{$_}];
   }
   croak "top_path called with illegal paths mask ($paths)";
}

our @sqlcol = (
   "d_int",
   "d_double",
   "d_string",
   "d_blob",
   "d_fulltext",
);

our %sqlcol = map +($_ => 1), @sqlcol;

our %fetch_sqlcol;
our %storefetch_sqlcol;
our %storeupdate_sqlcol;

our %sqlcol_is_numeric = (
   d_double => 1,
   d_int    => 1,
);

our %sqlcol_dbi_type = (
  d_int      => DBI::SQL_INTEGER,
  d_double   => DBI::SQL_NUMERIC,
  d_string   => DBI::SQL_BINARY,
  d_blib     => DBI::SQL_BINARY,
  d_fulltext => DBI::SQL_BINARY,
);

sub prepare_papp_dbh {
  my $dbh = shift;

  for (@sqlcol) {
    $fetch_sqlcol{$_} =
      $dbh->prepare ("select data from $_ where id = ? and type = ?");

    my $st = $storefetch_sqlcol{$_} =
      $dbh->prepare ("select data <=> ? from $_ where id = ? and type = ?");

    $st->bind_param (1, undef, { TYPE => $Agni::sqlcol_dbi_type{$_} });

    my $st = $storeupdate_sqlcol{$_} =
      $dbh->prepare ("update $_ set data = ? where (not (data <=> ?)) and id = ? and type = ?");

    $st->bind_param (1, undef, { TYPE => $Agni::sqlcol_dbi_type{$_} });
    $st->bind_param (2, undef, { TYPE => $Agni::sqlcol_dbi_type{$_} });
  }
};

$PApp::Config::prepare_papp_dbh{"Agni::sqlcol"} = \&prepare_papp_dbh;
prepare_papp_dbh $PApp::Config::DBH;

sub lock_all_tables {
   "lock tables obj_gidseq write, obj write, ". join ", ", map "$_ write", @sqlcol, @_;
}

sub new_objectid() {
   sql_exec "lock tables obj_gidseq write";
   my $gid = sql_fetch "select seq from obj_gidseq";
   sql_exec "update obj_gidseq set seq = seq + 1";
   sql_exec "unlock tables";
   $gid;
}

sub insert_obj($$$) {
   sql_insertid sql_exec "insert into obj (id, gid, paths) values (?, ?, ?)",
                         $_[0], $_[1], $_[2];
}

sub newpath($) {
   unless (defined $pathid{$_[0]}) {
      my $path = "";
      sql_exec "lock tables obj_path write, obj write";
      for (split /\//, $_[0]) {
         my $parent = $path;
         $path .= "$_/";
         unless (sql_uexists "obj_path where path = ?", $path) {
            my $pathid = 0;
            $pathid++ while sql_exists "obj_path where id = ?", $pathid;
            $pathid < 64 or die "no space for new path $path, current limit is 64 paths\n";

            sql_uexec "insert into obj_path (id, path) values (?, ?)", $pathid, $path;

            sql_exec "update obj set paths = paths | (1 << ?) where paths & (1 << ?) <> 0", $pathid, $pathid{$parent};
            $pathid{$path} = $pathid;
         }
      }
      PApp::Event::broadcast agni_update => [&UPDATE_PATHS];
      sql_exec "unlock tables";
   }
}

# return the pathid of the staging path corresponding to the given path
sub staging_path($) {
   defined $_[0] and defined $pathname[$_[0]]
      or die "staging_path called without a pathid\n";
   (my $path = $pathname[$_[0]]) =~ s{/(staging/)?$}{/staging/};
   newpath $path unless exists $pathid{$path};
   defined $pathid{$path}
      or die "FATAL 101: unable to create staging path for $_[0] ($path)\n";
   $pathid{$path};
}

# the reverse to staging_path
sub commit_path($) {
   defined $_[0] and defined $pathname[$_[0]]
      or die "staging_path called without a pathid\n";
   (my $path = $pathname[$_[0]]) =~ s{/staging/$}{/};
   newpath $path unless exists $pathid{$path};
   defined $pathid{$path}
      or die "FATAL 101: unable to create commit path for $_[0] ($path)\n";
   $pathid{$path};
}

sub staging_path_p($) {
   $pathname[$_[0]] =~ m{/staging/$};
}

#############################################################################

our $hold_updates;
our @held_updates;

sub hold_updates(&;@) {
   local $hold_updates = $hold_updates + 1;
   eval { &{+shift} };

   # ALWAYS broadcast updates, even if we are deeply nested
   if (@held_updates) {
      local $@;
      PApp::Event::broadcast agni_update => @held_updates;
      @held_updates = ();
   }

   die if $@;
}

sub update(@) {
   if ($hold_updates) {
      push @held_updates, @_;
   } else {
      PApp::Event::broadcast agni_update => @_;
   }
}

#############################################################################

sub gid($) {
   ref $_[0] ? $_[0]{_gid} : $_[0];
}

=item path_obj_by_gid $path, $gid

Returns a object by gid in a specified path.

=cut

sub path_obj_by_gid($$) {
   $obj_cache{$_[1]}[$_[0]]
      or do {
         local $PApp::SQL::DBH = $DBH;
         update_class({ _path => $_[0], _gid => $_[1], _loading => 1 })
      };
}

# like path_obj_by_gid, but is called by PApp::Storable
*storable_path_obj_by_gid = \&path_obj_by_gid;
#sub storable_path_obj_by_gid {
#   warn "SPOBID @_\n";
#   my $gid = $_[1];
#   my $ob = &path_obj_by_gid;
#   use PApp::Util; warn PApp::Util::sv_dump $ob if $gid eq "64424509652";#d#
#   $ob
#}#d#

# stolen & modified from Symbol::delete_package: doesn't remove the stash itself
sub empty_package ($) {
   my $pkg = shift;

   unless ($pkg =~ /^main::.*::$/) {
      $pkg = "main$pkg"       if      $pkg =~ /^::/;
      $pkg = "main::$pkg"     unless  $pkg =~ /^main::/;
      $pkg .= '::'            unless  $pkg =~ /::$/;
   }

   my($stem, $leaf) = $pkg =~ m/(.*::)(\w+::)$/;
   my $stem_symtab = *{$stem}{HASH};
   return unless defined $stem_symtab and exists $stem_symtab->{$leaf};

   # free all the symbols in the package

   my $leaf_symtab = *{$stem_symtab->{$leaf}}{HASH};
   foreach my $name (keys %$leaf_symtab) {
      undef *{$pkg . $name};
   }

   # delete the symbol table

   %$leaf_symtab = ();
}

our $bootstrap; # bootstrapping?
our %bootstrap; # contains postponed methods/objects
our %bootstrap_cache;
our $update_level;

# for bootstrapping and used in object::attr::named::method

# a single callback that preloads the object containing the real callback
my $agni_cb =
   PApp::Callback::register_callback
      \&agni_exec_cb,
      name => "agni_cb";

# load the object and call the corresponding callback
sub agni_exec_cb {
   my ($obj, $name) = splice @_, 0, 2;

   goto &{
      $obj->{_cb}{$name}
         or croak "cannot execute callback $obj->{_path}/$obj->{_gid}/$name for $_[0]{_path}/$_[0]{_gid}: callback doesn't exist";
   };
}

# substitute for PApp::Callback::register, used in perl/pxml2pcode
sub register_callback {
   my ($path, $gid, $cb, undef, $name) = @_;
   my $obj = path_obj_by_gid $path, $gid
      or Carp::confess "Unable to load object belonging to callback ($path/$gid)";

   $obj->{_cb}{$name} = $cb;

   $agni_cb->new (args => [$obj, $name]);
}

sub register_callback_info {
   my $self = shift;
   +{
      register_function => "Agni::register_callback $self->{_path}, '$self->{_gid}',",
      callback_preamble => "my \$self = shift;",
      argument_preamble => "\$self",
   }
}

use vars '$PACKAGE'; # the current compilation package (NOT our because that's visible inside eval's!!!)

sub get_package {
   my ($path, $gid) = @_;

   $ns_cache{$path, $gid} || do {
      my $package;

      # during bootstrap, everything is put into the default package. oh yes!!
      if ($bootstrap) {
         return $agni_bootns[$path] if $agni_bootns[$path];
         $package = $agni_bootns[$path] = bless {
            _path  => $path,
            _gid   => $gid,
         }, Agni::BootPackage::;
      } else {
         $package = path_obj_by_gid $path, $gid;
      }

      $package->{_package_name} = "ns::$package->{_path}::$package->{_gid}";

      my $init_code = q~
         use strict qw(vars subs);#TODO: common::sense

         use Carp;
         use Convert::Scalar ':utf8';
         use List::Util qw(min max);

         use PApp;
         use PApp::Config ();
         use PApp::SQL;
         use PApp::HTML;
         use PApp::Exception;
         use PApp::Callback;
         use PApp::Env;
         use PApp::Util qw(dumpval);

         use PApp::Application ();

         use Agni qw(*env *app path_obj_by_gid gid obj_of);

         use vars qw($PATH $PACKAGE $papp_translator);

         sub obj($) {
            ref $_[0] ? $_[0] : path_obj_by_gid PATH, $_[0];
         }

         # HACK BEGIN
         use PApp::XSLT;
         use PApp::ECMAScript;
         use PApp::XML qw(xml_quote);
         use PApp::UserObs;
         use PApp::PCode qw(pxml2pcode perl2pcode pcode2perl);
         use PApp::XPCSE;
         use PApp::EditForm;

         sub __      ($){ PApp::I18n::Table::gettext (PApp::I18n::get_table ($papp_translator, $PApp::langs), $_[0]) }
         sub gettext ($){ PApp::I18n::Table::gettext (PApp::I18n::get_table ($papp_translator, $PApp::langs), $_[0]) }
         # HACK END
      ~;

      ${"$package->{_package_name}::PATH"}    = $path;
      ${"$package->{_package_name}::PACKAGE"} = $package;
      ${"$package->{_package_name}::papp_translator"}
         = PApp::I18n::open_translator ("$PApp::i18ndir/" . eval { $package->domain }, $package->{lang});

      $package->eval (qq~
            sub PATH() { $path }
            $init_code;
         ~);
      die if $@;

      $package->initialize;

      $ns_cache{$path, $gid} = $package
         unless Agni::BootPackage:: eq ref $package; # don't cache the bootpackage

      $package
   }
}

BEGIN {
   no strict;

   $objtag_start    = "\x{10f101}";
   $objtag_type_lo  = "\x{10f102}";
   $objtag_obj      = "\x{10f102}"; # inline object
   $objtag_obj_gid  = "\x{10f103}"; # inline object gid
   $objtag_obj_show = "\x{10f104}"; # call show, used by content::dynamic::xml
   $objtag_type_hi  = "\x{10f1ed}";
   $objtag_end      = "\x{10f1fe}";
}

# compile code into the current package... also expands the special method gids

sub compile {
   no strict;

   my $code = $_[0];

   $code =~ s{
      $objtag_start([$objtag_type_lo-$objtag_type_hi])([^$objtag_end]*)$objtag_end
   }{
      my ($type, $content) = ($1, $2);
      if ($type eq $objtag_obj) {
         # we have to load delayed to be able to bootstrap, currently
         #"+(\$Agni::obj_cache{'$content'}[$PACKAGE->{_path}] || obj '$content')"
         "+(state \$__ = obj '$content')"
      } elsif ($type eq $objtag_obj_gid) {
         "'$content'";
      } else {
         warn "unknown method tag " . ((ord $type) - (ord $objtag_type_lo) + 2) . " with content '$content', maybe you need a newer version of agni?\n";
         "";
      }
   }ogex; # " vim fix

   use 5.010;
   use strict qw(vars subs);
   local $SIG{__DIE__};

   eval "package $PACKAGE->{_package_name}; $code";
}

sub compile_method_perl {
   my ($self, $name, $args, $code) = @_;

   my $args = join ",", '$self', split /[ \t,]+/, $args;

   my $class     = ref $self;
   my $isa_class = ref $self->{_isa};

   $code =~ s/->SUPER::/->$isa_class\::/g;
   $code =~ s/->SUPER(?!\w)/->$isa_class\::$name/g;

   compile "sub $class\::$name { my ($args) = \@_; ();\n"
         . "#line 3 \"{$pathname[$self->{_path}]$self->{_gid}::$name}\"\n"
         . "$code\n"
         . "}";

   if (my $err = $@) {
      *{"$class\::$name"} = sub {
         fancydie "can't call method $name because of compilation errors", $err, abridged => 1;
      };

      $last_compile_status = $err;
      warn "error while compiling $self->{_path}/$self->{_gid}->$name: $err";
   }
}

sub compile_method_environment {
   my ($self, $cb) = @_;

   $self->{_package}
      or croak "unable to compile method: no package in object $self->{_path}/$self->{_gid}";

   local $PACKAGE = get_package $self->{_path}, $self->{_package};
   local $PApp::PCode::register_callback = register_callback_info $self;

   if ((ref $self) eq (ref $self->{_isa})) {
      my $class = "agni::$self->{_path}::$self->{_gid}";

      @{"$class\::ISA"} = ref $self;

      update_isa_class ($self, $class);
   }

   &$cb;
}

# the toplevel object, can't be edited etc.. but it exists ;)
our $toplevel_object = Agni::agnibless { }, agni::object::;

exists $toplevel_object->{_type} or die; # magic?

sub Agni::BootPackage::eval {
   local $PACKAGE = $_[0];

   compile $_[1];
}

sub Agni::BootPackage::initialize {
   my $self = shift;
   # might be called multiple times
   $self->{_initialized} ||= do {
      # nop, for now
      1;
   };
}

sub Agni::BootPackage::domain {
   "agni"
}

# a very complicated thing happens here: the initial loading of the
# objects necessary to work properly - during bootstrap, only string
# datatypes and perl methods are compiled, the rest is fixed later.
sub agni_bootstrap($) {
   my $path = $_[0];

   $path =~ /^\d+$/
      or fancydie "bootstrapping error", "tried to bootstrap path '$path', which is not a valid path";

   local $bootstrap = 1;
   local %bootstrap;
   local %bootstrap_cache;

   # Load the absolute minimum set of objects that allows
   # loading of arbitrary other objects. These objects
   # will only load partially(!)
   for my $gid ($OID_OBJECT, $OID_PACKAGE_DEFAULT,
                $OID_ROOTSET, $OID_ISA_DATA, $OID_ISA_METHOD,
                $OID_META_PARCEL, $OID_NAMESPACES) {
      path_obj_by_gid $path, $gid;
      $BOOTSTRAP_LEVEL{$gid} ||= $bootstrap;
   }

   ####################

   # the default package must be loaded now... or is it not?
   my $package = $obj_cache{$OID_PACKAGE_DEFAULT}[$path]
      or die "FATAL 20: boot package for path $path not loaded after bootstrapping";

   $ns_cache{$package->{_path}, $package->{_gid}} = $package;
   delete $agni_bootns[$path]
      or die "FATAL 21: no bootpackage for path $path after bootstrapping";

   $package->{_package_name} = "ns::$package->{_path}::$package->{_gid}";
   $package->initialize;

   ####################

   # fix types of bootstrap objects (still in bootstrap mode, so iterate)
   while (%bootstrap) {
      $bootstrap++;
      my @bs = values %bootstrap; %bootstrap = ();
      for (@bs) {
         my ($self, $postponed) = @$_;

         $self->{_path} == $path
            or die "FATAL 23: path mismatch, path $path needs object $self->{_path}/$self->{_gid}??";

         $BOOTSTRAP_LEVEL{$self->{_gid}} ||= $bootstrap;

         # fixing datatypes
         while (my ($type, $data) = each %$postponed) {
            my $tobj = path_obj_by_gid $self->{_path}, $type
               or die "FATAL 24: unable to handle bootstrap datatype $type for object $self->{_path}/$self->{_gid}\n";
            eval {
               $tobj->populate ($self, $data);
            };
            warn "(bootstrap) unable to populate agni::$self->{_path}::$self->{_gid} with attribute $type: $@" if $@;
         }
      }
   }
}

# update the in-memory class of an object to $new
sub update_isa_class($$) {
   my ($self, $new) = @_;

   # when loading an object we never care for (nonexistant) instances
   if ($self->{_loading}) {
      agnibless $self, $new;
   } else {
      my $obj;
      my $old = ref $self;

      if ($old eq ref $self->{_isa}) {
         # has no own methods or similar, so inherits package

         if ($old ne $new) {
            for (values %obj_cache) {
               agnibless $obj, $new
                  if ($obj = $_->[$self->{_path}])
                      && ($old eq ref $obj)
                      && $obj->isa($self);
            }
         }
      }

      # "try" to nuke perl's ISA caches. simply
      # assigning to ISA does not necessarily work.
      eval "sub Agni::nukeme { }";
      my $stash = *{main::Agni::}{HASH};
      my $sub = delete $stash->{nukeme};
   }
}

# update the isa of an in-memory object
sub update_isa_mem($$) {
   my ($self, $gid) = @_;

   my $isa = path_obj_by_gid $self->{_path}, $gid;

   if (!$isa) {
      $self->{_gid} eq "1"
         or Carp::cluck "ISA class ($gid) of object $self->{_path}/$self->{_gid} doesn't exist or couldn't be loaded";

      $isa = $toplevel_object;
   }

   update_isa_class $self, ref $isa;

   $self->{_isa} = $isa;
}

#############################################################################
# support functions for _cache and _type management

my %type_hash_cache;
my %name_hash_cache;

sub _obj_member_add($$$) {
   my ($obj, $name, $tobj) = @_;

   my %type = %{ $obj->{_type} };

   $type{$name} = $tobj;

   my $key = join ",", sort %type;
   Scalar::Util::weaken ($name_hash_cache{$key} ||= \%type);
   $obj->{_type} = $name_hash_cache{$key};
}

sub _obj_member_del($$) {
   my ($obj, $name) = @_;

   my %type = %{ $obj->{_type} };

   delete $type{$name};

   my $key = join ",", sort %type;
   Scalar::Util::weaken ($name_hash_cache{$key} ||= \%type);
   $obj->{_type} = $name_hash_cache{$key};
}

sub _obj_cache_set($$$) {
#   my ($obj, $gid, $value) = @_;
   $_[0]{_cache}{$_[1]} = $_[2];
}

sub _obj_cache_del($$) {
   my ($obj, $gid) = @_;

   delete $obj->{_cache}{$gid};
}

sub _obj_cache_exists($$) {
   my ($obj, $gid) = @_;

   exists $obj->{_cache}{$gid};
}

#############################################################################

sub update_class($) {
   my $self = $_[0];

   rmagical_off $self;

   # sanity check since mysql compares 45 and '45"' as equal..
   "$self->{_path},$self->{_gid}" =~ /^[0-9]+,[0-9]+$/ or return undef;

   # is the root object available or do we need to bootstrap?
   unless ($obj_cache{1}[$self->{_path}] or $bootstrap) {
      isobject $self
         and die "FATAL 3: bootstrapping caused by already loaded object";
      agni_bootstrap $self->{_path};

      # can't reuse $self (could already be loaded!), so just return sth. else
      return path_obj_by_gid $self->{_path}, $self->{_gid};
   }

   sql_fetch \my($id, $paths),
             "select id, paths
              from obj
              where gid = ? and paths & (1 << ?) <> 0",
             "$self->{_gid}", $self->{_path};

   $id or return undef;

   ::trace_update_class_enter ($self) if DEVEL_TRACE;

   # to avoid endless recursion, set the object before loading the isa object
   # (not a problem under normal circumstances)
   $obj_cache{$self->{_gid}}[$self->{_path}] = $self;

   $self->{_id}    = $id;
   $self->{_paths} = $paths;

   local $update_level = $update_level + 1;

   $update_level < 100 or croak "deep recursion in object loader (check for circular isa?)";

   my (%data, $types, @types);

   for (@sqlcol) {
      my $st = sql_exec \my($type, $data),
                        "select type, data
                         from $_
                         where id = ?
                         order by type",
                        $id;

      while ($st->fetch) {
         $data{$type} = $data;
         push @types, $type;
      }
   }

   $types = $type_hash_cache{join ",", @types}
            ||= {
               map { $_ => undef } @types
            };

   # use populate for these, too! #d# #FIXME#
   update_isa_mem $self, delete $data{$OID_ISA};

   if (exists $data{$OID_META_PACKAGE}) {
      $self->{_package} = delete $data{$OID_META_PACKAGE};
   }

   if ($bootstrap) {
      $bootstrap{$self} = [$self, my $postponed = {}];

      # now load some data and method types
      while (my ($type, $data) = each %data) {
         my ($ismethod, $isnamed, $name, $args, $superclass) = @{$bootstrap_cache{$self->{_path},$type} ||=  [
            # classes directly descending from method::perl and having a name are considered simple perl methods
            sql_ufetch
                "select args.id is not null, 1, name.data, args.data, isa.data
                 from obj
                     inner join d_int    isa  on (obj.id = isa.id  and isa.type  = $OID_ISA)
                     inner join d_string name on (obj.id = name.id and name.type = $OID_ATTR_NAME)
                     left  join d_string args on (obj.id = args.id and args.type = $OID_METHOD_ARGS)
                 where gid = ?
                   and paths & (1 << ?) <> 0",
                $type,
                $self->{_path},
            ]};

         if ($ismethod) { # if it has an args attribute...
            $self->{_package} eq $OID_PACKAGE_DEFAULT
               or die "FATAL 31: bootstrapping object $self->{_path}/$self->{_gid} needs non-agni package $self->{_package}";

            compile_method_environment $self, sub {
               if ($superclass eq $OID_METHOD_PERL) {
                  compile_method_perl $self, $name, $args, pcode2perl perl2pcode utf8_on $data;
               } else {
                  # non-perl-method, store for later use

                  # plant a bomb
                  my $class = ref $self;
                  *{"$class\::$name"} = sub { die "non-bootstrap method $class->$name ($args) called during bootstrap" };

                  $postponed->{$type} = $data;
               }
            };

         } elsif ($isnamed) { # no args attribute but named, must be data
            # pretend to be able to handle descendents of OID_DATA_STRING and nothing else.
            _obj_cache_set $self, $type, $data if $superclass eq $OID_DATA_STRING;

            # plant a bomb, so other accesses than fetch die
            _obj_member_add $self, $name, bless { _gid => $type },
                                           "non-bootstrap data access during bootstrap ($self->{_path}/$self->{_gid}\{$type=$name}";

            $postponed->{$type} = $data;
         } else {
            $postponed->{$type} = $data;
         }
      }
   } else {
      while (my ($type, $data) = each %data) {
         # undef data must be populated, too...
         my $tobj = path_obj_by_gid ($self->{_path}, $type)
            or warn "object agni::$self->{_path}::$self->{_gid} refers to nonloadable type $type";
         eval {
            $tobj->populate ($self, $data);
         };
         warn "unable to populate agni::$self->{_path}::$self->{_gid} with attribute $type: $@" if $@;
      }

      # cannot happen during bootstrap
      for (keys %{$self->{_attr}}) {
         unless (exists $types->{$_}) {
            my $tobj = path_obj_by_gid ($self->{_path}, $_)
               or croak "agni::$self->{_path}::$self->{_gid}: unable to load type object $_, unable to depopulate\n";
            $tobj->depopulate ($self);
         }
      }
   }

   # if we were loading this object, then it's loaded now...
   # this is just used to avoid expensive loops in
   # update_isa_class in the common case, but may be used
   # for other purposes, too.
   delete $self->{_loading};

   $self->{_attr} = $types;

   rmagical_on $self;

   ::trace_update_class_leave ($self) if DEVEL_TRACE;

   $self
}

#############################################################################

sub update_commitinfo($$) {
   sql_exec "replace into d_string (id, type, data) values (?, ?, ?)",
            $_[1], $OID_COMMITINFO, "$PApp::NOW $PApp::stateid $_[0] {$PApp::Config{SYSID}}";
}

# make sure the object described by $paths|$gid|$id is copied into the
# target layer. returns the new id on copy or undef otherwise.
# another way to view this operation is that the object is split
# at the path $target and the id of the copy is returned (if one was created)

sub split_obj {
   my ($paths, $gid, $id, $target) = @_;

   sql_exec lock_all_tables ();

   my $newid = eval {
      local $SIG{__DIE__};
      insert_obj undef, $gid, and64 $paths, $subpathmask[$target];
   };
   if ($newid) {
      sql_exec "update obj set paths = paths &~ ? where id = ?", $subpathmask[$target], $id;

      for my $table (@sqlcol) {
         my $st = sql_exec \my($type, $data),
                           "select type, data from $table where id = ?",
                           $id;
         sql_exec "insert into $table (id, type, data) values (?, ?, ?)",
                  $newid, $type, $data
            while $st->fetch;
      }
      update_commitinfo split => $newid;

      sql_exec "unlock tables";

      Agni::update [UPDATE_PATHID, $paths, $gid];
   } else {
      sql_exec "unlock tables";
   }

   $newid
}

sub agni::object::copy_to_path {
   my ($self, $target) = @_;

   defined $target or $target = $self->{_path};

   if (and64 $self->{_paths}, $pathmask[$target]) {
      # object is from the target path
      if (and64 $self->{_paths}, $parpathmask[$target]) {
         split_obj $self->{_paths}, $self->{_gid}, $self->{_id}, $target
            || sql_fetch "select id from obj where gid = ? and paths & (1 << ?) <> 0", $self->{_gid}, $target;
      } else {
         $self->{_id};
      }
   } else {
      # object is outside the target path, fetch the id of the correct object
      sql_fetch "select id from obj where gid = ? and paths & (1 << ?) <> 0", $self->{_gid}, $target;
   }
}

# these are rarely shown and only defined for completeness
sub agni::object::name     { "\x{4e0a}" }
sub agni::object::fullname { "\x{4e0a}" }

sub agni::object::isa_obj {
   $_[0]{_isa}
}

sub agni::object::STORABLE_freeze {
   Carp::croak "cannot serialise agni objects via Storable - use PApp::Storable instead, at";
}

sub update_isa {
   my ($self) = @_;

   sql_exec "replace into d_int (id, type, data) values (?, ?, ?)", $self->{_id}, $OID_ISA, $self->{_isa}{_gid};
}

=item path_gid2name $path, $gid

Tries to return the name of the object, or some other descriptive string, in
case the object lacks a name. Does not load the object into memory, but
might load other objects in memory.

=cut

sub path_gid2name($$) {
   my ($path, $gid) = @_;
   if (my $obj = $obj_cache{$gid}[$path]) {
      return $obj->name;
   } else {
      my $st = sql_exec \my ($nsname, $oname),
                        "select ns_name.data, attr_ns.data
                         from obj
                            inner join d_string attr_ns on (obj.id = attr_ns.id)
                            inner join obj obj_ns on (obj_ns.gid = attr_ns.type)
                            inner join d_int isa_ns on (isa_ns.id = obj_ns.id and isa_ns.type = $OID_ISA_NAMESPACE)
                            inner join d_string ns_name on (ns_name.id = obj_ns.id and ns_name.type = $OID_NAMESPACES)

                         where
                            obj.gid = ?
                            and obj.paths & (1 << ?) <> 0
                            and obj_ns.paths & (1 << ?) <> 0
                         limit 1",
                        $gid, $path, $path;

      if ($st->fetch) {
         utf8_on $nsname;
         utf8_on $oname;
         return "$nsname/$oname";
      } elsif (my $isa = sql_fetch "select isa.data
                                    from obj inner join d_int isa on (isa.id = obj.id and isa.type = $OID_ISA)
                                    where gid = ? and paths & (1 << ?) <> 0",
                                   $gid, $path) {
         my $aname = sql_fetch
                        "select attr_name.data
                         from obj
                            inner join d_string attr_name on (attr_name.id = obj.id and attr_name.type = $OID_ATTR_NAME)
                         where
                            obj.gid = ?
                            and obj.paths & (1 << ?) <> 0
                            and attr_name.data is not null",
                       $gid, $path;
         utf8_on $aname;

         (path_gid2name ($path, $isa)) . ">" . ($aname ? "#$aname" : $gid);
      } else {
         "#$gid";
      }
   }
}

=item obj2name $obj

Same as path_gid2name, but works on an existing object.

=cut

sub obj2name($) {
   path_gid2name $_[0]{_path}, $_[0]{_gid};
}

=item commit_objs [$gid, $src_path, $dst_path], ...

Commit (copy) objects from one path to another. If C<$dst_path> is
undefined or missing, deletes the instance (making higher-path instances
visible again).

Currently, C<$src_path> must be the "topmost" path of one object
instance. Object instances that are also visible in parent paths are
skipped.

It returns a html fragment describing it's operations.

 # delete the root object (gid 1) from the staging path
 Agni::commit_objs [1, $Agni::pathid{"root/staging/"}, undef];

 # kind of read-modify-write for an object
 # 1. get an object into the staging path
 my $sobj = $obj->to_staging_path;
 # 2. modify it
 $sobj->{...} = ...;
 # 3a. either commit it ("save changes"):
 Agni::commit_objs [$sobj->{_gid}, $sobj->{_path}, $obj->{_path}];
 # 3b. or delete it ("cancel"):
 Agni::commit_objs [$sobj->{_gid}, $sobj->{_path}, undef];

=cut

sub commit_objs {
   my $args = \@_;
   my $wantlog = defined wantarray;
   PApp::capture {
      my @event;

      sql_exec lock_all_tables "d_string name1", "d_string name2";

      :><p><:
      eval {
         for (@$args) {
            my ($obj_gid, $src, $dst) = @$_;

            :>gid <?$obj_gid:>...<:

            my ($obj_paths, $obj_id);

            if (my $obj = $obj_cache{$obj_gid}[$src]) {
               ($obj_paths, $obj_id) = ($obj->{_paths}, $obj->{_id});
            } else {
               ($obj_paths, $obj_id)
                  = sql_fetch "select paths, id from obj where paths & (1 << ?) <> 0 and gid = ?",
                              $src, $obj_gid;
            }

            if ($wantlog && 0) {#d#
               my $name = sql_fetch "select coalesce(name1.data, concat('#', name2.data), concat('#', gid))
                                     from obj
                                        left join d_string name1 on (obj.id = name1.id and name1.type = $OID_META_NAME)
                                        left join d_string name2 on (obj.id = name2.id and name2.type = $OID_ATTR_NAME)
                                     where paths & (1 << ?) <> 0 and gid = ?",
                                    $src, $obj_gid;
               :><b><?escape_html Convert::Scalar::utf8_on $name:></b>...<:
            }

            if (and64 $parpathmask[$src], $obj_paths) {
               :><?"already committed ...":><:
               # croak "commit_objs: src_path $src not the highest path of object $obj_gid";
            } else {
               # first unlink the object from the src layer.
               sql_exec "update obj set paths = paths | ? where gid = ? and paths & (1 << ?) <> 0",
                        $obj_paths, $obj_gid, $parpath[$src];

               if (defined $dst) {
                  my $dst_paths;

                  # then find the object that currently is visible in the target layer
                  sql_fetch \my($id, $paths),
                            "select id, paths from obj where gid = ? and paths & (1 << ?) <> 0",
                            $obj_gid, $dst;

                  # can't happen anymore?
                  $id != $obj_id or croak "FATAL, pls report! commit_objs: src_path $src not the highest path of object $obj_gid";

                  if ($id) {
                     # remove it from the target path
                     if (andnot64 $paths, $subpathmask[$dst]) {
                        :><?"splitting $id...":><:
                        sql_exec "update obj set paths = paths &~ ? where id = ?",
                                  $subpathmask[$dst], $id;
                     } else {
                        :><?"replacing $id...":><:
                        sql_exec "delete from $_ where id = ?", $id for ("obj", @sqlcol);
                     }
                     push @event, [UPDATE_PATHID, $paths, $obj_gid];

                     # move the commit object into the target path
                     $dst_paths = and64 $paths, $subpathmask[$dst];
                  } else {
                     :><?"created ...":><:
                     # calculcate all mask bits sans the obj_paths, use sum
                     $dst_paths = sql_fetch "select sum(paths) from obj where id != ? and gid = ?", $obj_id, $obj_gid;

                     # now move the object into the target path
                     $dst_paths = andnot64 $subpathmask[$dst], $dst_paths;
                  }

                  sql_exec "update obj set paths = ? where id = ?", $dst_paths, $obj_id;
                  update_commitinfo commit => $obj_id;
                  push @event, [UPDATE_CLASS, (or64 $dst_paths, $obj_paths), $obj_gid];
               } else {
                  :><?"removing $obj_id...":><:

                  sql_exec "delete from $_ where id = ?", $obj_id for ("obj", @sqlcol);

                  push @event, [UPDATE_CLASS, $obj_paths, $obj_gid];
               }
            }
            :><br /><:
         }
      }
      :></p><:

      my $err = $@;

      sql_exec "unlock tables";

      PApp::Event::broadcast agni_update => @event if @event;

      if ($err) {
         if ($wantlog) {
            :><error><?escape_html $err:></error><:
         } else  {
            die $err;
         }
      }

   };
}

sub check_gidseq($) {
   my ($force) = @_;

   my $seq = sql_fetch "select seq from obj_gidseq";
   my $max = sql_fetch "select max(gid) from obj where gid < (? | 0xffffffff)", $seq;

   $seq > $max
      or $force ? warn "WARNING: obj_gidseq points to allocated objects. Duplicate SYSID?\n"
                : die "FATAL, DATABASE OR IMAGE CORRUPTION: obj_gidseq points to allocated objects. Duplicate SYSID?\n";
}

sub import_objs {
   my ($objs, $pathid, $delete_layer, $force) = @_;

   defined $pathid or croak "import_objs: undefined pathid\n";

   my $pathmask = $pathmask[$pathid];
   my $submask  = $subpathmask[$pathid];

   my %type_cache;
   my %obj;

   $obj{1} = { }; # object one doesn't have an isa

   for (@$objs) {
      $_->{gid} or croak "import_objs: object without gid";

      $type_cache{$_->{gid}} = $_->{attr}{$OID_ATTR_SQLCOL};

      $obj{$_->{gid}} = $_;
   }

   sql_exec lock_all_tables();

   eval {
      for (@$objs) {
         my $gid = $_->{gid};

         # generate isa array first
         my @isa;
         do {
            unshift @isa, $gid;
            $obj{$gid} ||= do {
               my $id = sql_fetch "select id from obj where gid = ? and paths & (1 << ?) <> 0", $gid, $pathid;
               my $isa = sql_fetch "select data from d_int where type = $OID_ISA and id = ?", $id;
               $isa or croak "import_objs: can't resolve isa of object $gid";
               { attr => { $OID_ISA => $isa } };
            };
            $gid = $obj{$gid}{attr}{$OID_ISA};
         } while $gid;

         $_->{isa_array} = \@isa;

         # check types next
         while (my ($type, $data) = each %{$_->{attr}}) {
            exists $type_cache{$type} or $type_cache{$type} = do {
               my $id = sql_fetch "select id from obj where gid = ? and paths & (1 << ?) <> 0", $type, $pathid
                  or croak "import_objs: can't resolve type $type (used in object $_->{gid})";
               sql_ufetch "select data from d_string where id = ? and type = ?", $id, $OID_ATTR_SQLCOL;
            };
            defined $type_cache{$type}
               or die "import_objs: no sqlcol found for type $type";
         }
      }

      my @event;

      if ($delete_layer) {
         my $st = sql_exec \my($id),
                           "select id from obj where paths & ? <> 0 and paths & ? = 0",
                           $pathmask, $parpathmask[$pathid];
         while ($st->fetch) {
            sql_exec "delete from d_int where id = ? and type = $Agni::OID_ROOTSET", $id;
         }
      }

      for my $o (@$objs) {
         sql_exec "update obj set paths = paths & ~? where gid = ? and paths & ~? <> 0", $submask, $o->{gid}, $submask;

         my $st = sql_exec \my($id), "select id from obj where gid = ? and paths & ? <> 0", $o->{gid}, $pathmask;
         while ($st->fetch) {
            for ("obj", @sqlcol) {
               sql_exec "delete from $_ where id = ?", $id;
            }
         }

         my $obj_mask = sql_fetch "select ? - coalesce(sum(paths),0) from obj where gid = ? and paths & ~? = 0",
                                  $submask, $o->{gid}, $submask;

         my $id = insert_obj undef, $o->{gid}, $obj_mask;

         #print "importing $o->{gid} (@{$o->{isa_array}}) ($pathmask,$submask,objmask $obj_mask) as $id\n";

         while (my ($type, $data) = each %{$o->{attr}}) {
            sql_exec "insert into $type_cache{$type} (id, type, data) values (?, ?, ?)",
                     $id, $type, $data;
         }

         push @event, [Agni::UPDATE_CLASS, $obj_mask, $o->{gid}];
      }

      Agni::update @event;
   };

   check_gidseq $force;

   sql_exec "unlock tables";

   die if $@;
}

sub gc_find_instances_by_id(&@) {
   my ($cb, @seed) = @_;

   while (@seed) {
      $cb->(@seed);

      @seed = sql_fetchall
                 "select distinct obj.id
                  from obj
                     inner join d_int on (obj.id = d_int.id and d_int.type = $OID_ISA)
                     inner join obj iobj on (iobj.gid = d_int.data and obj.paths & iobj.paths <> 0)
                  where iobj.id in (" . join(",", @seed) . ")";
   }
}

sub find_dead_objects {
   my %dead; # all dead gids
   my %isai; # all ids implementing the attr_container interface
   my %isac; # all objects id's that are attr::container's

   my ($seed, $next); # set of seed (newly alive) object ids, objects alive in next round

   my $lock_tables = lock_all_tables "obj iobj", "obj type";
   sql_exec $lock_tables;

   eval {
      # first mark all objects as dead. the gc will have to find the live ones
      my $st = sql_exec \my($id), "select id from obj";
      $dead{$id} = 1 while $st->fetch;

      # find all types implementing $OID_IFACE_CONTAINER
      {
         my @seed = sql_fetchall
                           "select obj.id
                            from obj
                               inner join d_int on (d_int.id = obj.id and d_int.type = $OID_IFACE_CONTAINER)
                           ";
         gc_find_instances_by_id { $isai{$_} = 1 for @_ } @seed;
      }

      # find all types that are attr::container's and special-case them (fast)
      {
         my @seed = sql_fetchall
                        "select id from obj
                         where gid = $OID_ATTR_CONTAINER";

         gc_find_instances_by_id { $isac{$_} = delete $isai{$_} or die "isac $_ is not isai!" for @_ } @seed;
      }

      grep !defined $_, values %isac and croak "isac not a subset of isai, check type tree!";

      # the root-set of alive objects (currently only the rootset)
      $seed = [ sql_fetchall "select id from obj where gid = $OID_ROOTSET" ];

      while (@$seed) {
         $next = [];
         #print "GC " . (scalar @$seed) . "\n";

         for my $id (@$seed) {
            # check wether this object is a container type
            # (this is an important optimization)
            if ($isac{$id}) {
               for (@sqlcol) {
                  push @$next, grep delete $dead{$_},
                     sql_fetchall "select distinct obj.id
                                   from obj
                                      inner join $_ using (id)
                                      inner join obj type on (type.gid = $_.type)
                                   where type.id = ? and obj.paths & type.paths <> 0",
                                  $id;
               }
            }
         }

         my $in = join ",", @$seed;

         # mark the isa objects as alive
         push @$next, grep delete $dead{$_},
            sql_fetchall "select distinct iobj.id
                          from obj iobj
                             inner join d_int on (d_int.type = $OID_ISA and d_int.data = iobj.gid)
                             inner join obj on (obj.id = d_int.id)
                          where obj.id in ($in) and obj.paths & iobj.paths <> 0";

         for my $sqlcol (@sqlcol) {
            # now fetch all attrs of the objects, mark them alive and resolve forward references
            my $st = sql_exec \my($id, $tgid, $tid, $paths),
                              "select obj.id, $sqlcol.type, type.id, type.paths
                               from obj
                                  inner join $sqlcol on ($sqlcol.id = obj.id)
                                  inner join obj type on ($sqlcol.type = type.gid)
                               where obj.id in ($in)";

            sql_exec "unlock tables";

            while ($st->fetch) {
               # mark the types alive
               push @$next, $tid if !$isac{$tid} && delete $dead{$tid};

               # forward-resolve types implementing the attr_container interface
               if ($isai{$tid}) {

                  # do it for every single path. this is not very efficient, but very correct
                  for my $path (values %pathid) {
                     next unless and64 $paths, $pathmask[$path];

                     my $tobj = path_obj_by_gid $path, $tgid
                        or croak "FATAL: garbage_collect cannot load type object ({$paths}/$tgid)";

                     if  ($sqlcol{$tobj->{sqlcol}}) {
                        my $data =
                           sql_fetch "select data
                                      from $tobj->{sqlcol} as attr where id = ? and type = ?",
                                     $id, $tgid;

                        my $gids = $tobj->attr_enum_gid ($data);

                        if (@$gids) {
                           my $st = sql_exec \my($id), "select id from obj
                                                        where gid in (".(join ",", @$gids).") and paths & (1 << ?) <> 0",
                                                       $path;
                           while ($st->fetch) {
                              push @$next, $id if delete $dead{$id};
                           }
                        }
                     } else {
                        warn "WARNING: type object $path/$tgid in use but has invalid sqlcol\n";
                     }
                  }
               }
            }
         }

         sql_exec $lock_tables;

         $seed = $next;
      }
   };

   sql_exec "unlock tables";
   die if $@;

   [keys %dead];
}

sub mass_delete_objects {
   my ($ids) = @_;

   sql_exec lock_all_tables("obj typ");

   # adjust paths... should instead call an object method instead
   for my $id (@$ids) {
      my ($gid, $paths) = sql_fetch "select gid, paths from obj where id = ?", $id;

      $paths or
         die "$gid is not in any path\n";

      sql_exec "update obj set paths = paths | ? where gid = ? and paths & ? <> 0",
               $paths, $gid, $parpathmask[top_path ($paths)];

      for my $table (@sqlcol) {
         # find all attributes in this table that are not referencable in other paths
         my $st = sql_exec \my($did),
                           "select obj.id from obj
                               inner join $table on ($table.id = obj.id and $table.type = ?)
                               left join obj typ on (obj.paths & typ.paths & ? <> 0 and typ.gid = ? and typ.id <> ?)
                            where typ.gid is null",
                           $gid,
                           $paths, $gid, $id;

         sql_exec "delete from $table where id = ? and type = ?", $did, $gid
            while $st->fetch;
      }
   }

   my $in = join ",", @$ids;

   for my $table ("obj", @sqlcol) {
      sql_exec "delete from $table where id in ($in)";
   }

   sql_exec "unlock tables";
}

#############################################################################

local $PApp::SQL::Database = $Database;
local $PApp::SQL::DBH      = $DBH;

init_paths;

sub flush_all_objects {
   for (values %obj_cache) {
      for (grep $_, @$_) {
         if (1 >= Convert::Scalar::refcnt_rv $_ and !$BOOTSTRAP_LEVEL{$_->{_gid}}) {
            $_ = undef;
         } else {
            update_class $_;
         }
      }
   }
}

PApp::Event::on agni_update => sub {
   shift;

   my %todo;
   my $todo;

   # this bundling does slightly more than necessary, i.e. if one object
   # gets a PATHID update in one path and an CLASS update in another
   # it will class-update all
   for (@_) {
      my ($type, $paths, $gid, $attr) = @$_;

      if ($type & (UPDATE_PATHS | UPDATE_ALL)) {
         $todo |= $type;
      } else {
         $todo{$gid}[0] |= $type;
         $todo{$gid}[1] = or64 $todo{$gid}[1], $paths;
         $todo{$gid}[2]{$attr}++ if $attr;
      }
   }

   if ($todo & UPDATE_PATHS) {
      init_paths;
      for (values %obj_cache) {
         for (@$_) {
            $_
               and $_->{_paths} =
                  sql_fetch "select paths from obj where gid = ? and paths & (1 << ?) <> 0",
                            $_->{_gid}, $_->{_path};
         }
      }
   }

   if ($todo & UPDATE_ALL) {
      flush_all_objects;
      return;
   }

   while (my ($gid, $v) = each %todo) {
      my ($type, $paths) = @$v;
      if ($type & UPDATE_CLASS) {
         for (grep $_, @{$obj_cache{$gid}}) {
            my $refcnt = Convert::Scalar::refcnt_rv $_; # we use a temporary value since ->{_paths} incs the refcnt
            if (and64 $paths, $_->{_paths}) {
               if (1 >= $refcnt and !$BOOTSTRAP_LEVEL{$gid} && 0) {
                  $_ = undef;
               } else {
                  update_class $_;
               }
            }
         }
      } else {
         if ($type & UPDATE_PATHID) {
            for (grep { $_ and and64 $paths, $_->{_paths} } @{$obj_cache{$gid}}) {
               ($_->{_paths}, $_->{_id}) =
                  sql_fetch "select paths, id from obj
                             where paths & (1 << ?) <> 0 and gid = ?",
                             $_->{_path}, $_->{_gid};
            }
         }

         if ($type & UPDATE_ATTR) {
            for my $obj (grep { $_ and and64 $paths, $_->{_paths} } @{$obj_cache{$gid}}) {
               for (map { path_obj_by_gid $obj->{_path}, $_ } keys %{$v->[2]}) {
                  if ($_) {
                     $_->update ($obj, $_->fetch ($obj));
                  } else {
                     warn "unable to update some types for object $obj->{_path}/$obj->{_gid}";
                  }
               }
            }
         }
      }
   }
};

=item agni_exec { BLOCK };

Execute the given perl block in an agni-environment (i.e. database set up
correctly etc.).

=item agni_refresh

Refresh the database connection and the $PApp::NOW timestamp, and also
checks for events (e.g. write accesses) done by other agni processes.
Usually called within C<agni_exec> after some time has progressed.

Might do other things in the future.

=cut

sub agni_refresh {
   $PApp::NOW = time;
   $PApp::SQL::DBH = PApp::Config::DBH;

   %PApp::temporary = ();

   PApp::Event::check;
}

sub agni_exec(&) {
   my $cb = shift;

   local $PApp::SQL::Database = $PApp::Config::Database;
   local $PApp::NOW;
   local $PApp::SQL::DBH;
   local %PApp::state;
   local %PApp::temporary;

   agni_refresh;

   &$cb;
}

#############################################################################

package Agni::Callback;

use overload
   fallback => 1,
   #'""'  => \&asString,
   '&{}' => sub {
      my ($self, $method, $args) = @{$_[0]};
      my $method = ($self->can ($method)
         or die "can't call method $method of $self, method does not exist");
      sub {
         local $PApp::SQL::DBH = $PApp::Config::DBH;
         $method->($self, @$args, @_);
      };
   };

sub new {
   my $class = shift;

   bless [ @_ ], $class;
}


1;

=back

=head1 SEE ALSO

The C<bin/agni> commandline tool, the agni online documentation.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut


