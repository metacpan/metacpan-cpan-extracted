#-----------------------------------------------------------------
# OWL::Base
# Author: Edward Kawas  <edward.kawas@gmail.com>
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Base.pm,v 1.28 2010-02-11 00:02:51 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Base;
use strict;
use HTTP::Date;
use URI;
use OWL::LSID;

use vars qw( $VERSION $Revision $AUTOLOAD @EXPORT @ISA );
use vars qw( $LOG $LOGGER_NAME $CONFIG_NAMESPACE );

# names of attribute's types
use constant STRING   => 'string';
use constant INTEGER  => 'integer';
use constant FLOAT    => 'float';
use constant BOOLEAN  => 'boolean';
use constant DATETIME => 'datetime';

# names of attribute's properties
use constant TYPE     => 'type';
use constant POST     => 'post';
use constant ISARRAY  => 'is_array';
use constant READONLY => 'readonly';
use overload q("")    => "as_string";

BEGIN {
	@ISA      = qw( Exporter );
	@EXPORT   = qw( $LOG );
	$VERSION  = sprintf "%d.%02d", q$Revision: 1.28 $ =~ /: (\d+)\.(\d+)/;
	$Revision = '$Id: Base.pm,v 1.29 2010-02-11 00:02:51 ubuntu Exp $';

	# initiate error handling
	require Carp;
	import Carp qw( confess );

	# read default configuration file and import configuration
	# parameters into 'OWLCFG namespace'
	use OWL::Config;
	$CONFIG_NAMESPACE = 'OWLCFG';

	sub init_config {
		shift;    # invocant ignored
		OWL::Config->init(@_);
		OWL::Config->import_names($CONFIG_NAMESPACE);
	}
	OWL::Base->init_config;

	# initiate logging
	use Log::Log4perl qw(get_logger :levels :no_extra_logdie_message);
	$LOGGER_NAME = 'generator';

	sub init_logging {
		if ($OWLCFG::LOG_CONFIG) {
			eval { Log::Log4perl->init($OWLCFG::LOG_CONFIG) };
			$LOG = get_logger($LOGGER_NAME) and return unless $@;
			print STDERR
			  "Problem with configuration file '$OWLCFG::LOG_CONFIG': $@\n";
		}

		# configuration for logging not found; make some easy logging
		my $logfile  = $OWLCFG::LOG_FILE;
		my $loglevel = $OWLCFG::LOG_LEVEL || $INFO;
		my $pattern  = $OWLCFG::LOG_PATTERN
		  || '%d (%r) %p> [%x] %F{1}:%L - %m%n';
		$LOG = get_logger($LOGGER_NAME);
		$LOG->level( uc $loglevel );
		my $appender =
		  ( $logfile and $logfile !~ /^stderr$/i )
		  ? Log::Log4perl::Appender->new(
										  "Log::Log4perl::Appender::File",
										  name     => 'Log',
										  filename => $logfile,
										  mode     => 'append'
		  )
		  : Log::Log4perl::Appender->new( "Log::Log4perl::Appender::Screen",
										  name => 'Screen' );
		$LOG->add_appender($appender);
		my $layout = Log::Log4perl::Layout::PatternLayout->new($pattern);
		$appender->layout($layout);
	}
	OWL::Base->init_logging;
}

#-----------------------------------------------------------------
# These methods are called by set/get methods of the sub-classes. If
# it comes here, it indicates that an attribute being get/set does not
# exist.
#-----------------------------------------------------------------
{
	my %_allowed = ();

	sub _accessible {
		my ( $self, $attr ) = @_;
		exists $_allowed{$attr};
	}

	sub _attr_prop {
		my ( $self, $attr_name, $prop_name ) = @_;
		my $attr = $_allowed{$attr_name};
		return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
		return undef;
	}
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
	my ( $class, @args ) = @_;

	#    $LOG->debug ("NEW: $class - " . join (", ", @args)) if $LOG->is_debug;
	# create an object
	my $self = bless {}, ref($class) || $class;

	# initialize the object
	$self->init();

	# set all @args into this object with 'set' values
	my (%args) = ( @args == 1 ? ( value => $args[0] ) : @args );
	foreach my $key ( keys %args ) {
		no strict 'refs';
		$self->$key( $args{$key} );
	}

	# done
	return $self;
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
	my ($self) = shift;
}

#-----------------------------------------------------------------
# toString
#-----------------------------------------------------------------
sub toString {
	my ( $self, $something_else ) = @_;
	require Data::Dumper;
	if ($something_else) {
		return Data::Dumper->Dump( [$something_else], ['M'] );
	} else {
		return Data::Dumper->Dump( [$self], ['M'] );
	}
}

#-----------------------------------------------------------------
# module_name_escape
#-----------------------------------------------------------------
sub module_name_escape {
	my ( $self, $name ) = @_;
	$name =~ tr/-/_/;
	$name =~ s/~//g;
	return $name;
}

#-----------------------------------------------------------------
# datatype2module
#-----------------------------------------------------------------
sub datatype2module {
	my ( $self, $datatype_name ) = @_;
	return undef unless $datatype_name;

	return $self->module_name_escape($datatype_name);
}

#-----------------------------------------------------------------
# oProperty2module
#-----------------------------------------------------------------
sub oProperty2module {
	my ( $self, $datatype_name ) = @_;
	return undef unless $datatype_name;

	return $self->module_name_escape($datatype_name);
}

#-----------------------------------------------------------------
# uri2package
#-----------------------------------------------------------------
sub uri2package {
	my ( $self, $uri ) = @_;
	return undef unless $uri;

	# is $uri an LSID?
	if ( lc($uri) =~ m/^urn\:lsid/gi ) {
		my $lsid = OWL::LSID->new( $uri );

		# cheat a little ;-)
		$uri =
		    'http://'
		  . $lsid->authority . '/'
		  . $lsid->namespace . '#'
		  . $lsid->object;
	}
	# strip off any '.owl' bits from the URI
	$uri =~ s/\.owl//gi;
	my $u1 = URI->new($uri);

	# the domain from the uri
	my $authority = $u1->authority || '';

	# convert . to ::
	$authority =~ s/\./::/g;

	# the thing after the # if it exists
	my $frag = $u1->fragment || '';

    # remove any leading / or #
	$frag =~ s/^[\/#]*//g;
	# remove any trailing
	$frag =~ s/[\/#]*$//g;

	# convert . to _
	$frag =~ s/\./_/g if $frag;

	# remove from frag ~ 
    $frag =~ s/~//g;

	# the path
	my $path = $u1->path || '';

	# remove leading /
	$path =~ s/^\///g;

	# remove any trailing / or #
	$path =~ s/[\/|#]*$//g;

	# sub path with : to _ 
	$path =~ s/:/_/g;

    # remove from path ~ 
    $path =~ s/~//g;

    # replace any // with a single /; doesnt affect // in http://
	$path =~ s/\/\//\//g;

	# convert / and . to ::
	$path =~ s/\/|\./::/g;

	my $package = '';

	# package name assuming that uri#foo
	$package = "$authority\:\:$path\:\:$frag" if $frag and $frag ne '';

	# package name assuming uri/foo
	$package = "$authority\:\:$path" if $package eq '';

	# make sure that nothing funny happened ...
	$package =~ s/^\:*//g;
	$package =~ s/\:*$//g;
	if ( $package =~ m/^genid/gi ) {
        $package = "Blank::$package";
	}
	return $package;
}

#-----------------------------------------------------------------
# owlClass2module
#-----------------------------------------------------------------
sub owlClass2module {
	my ( $self, $datatype_name ) = @_;
	return undef unless $datatype_name;
	return $self->module_name_escape($datatype_name);
}

#-----------------------------------------------------------------
# escape_name
#-----------------------------------------------------------------
sub escape_name {
	my ( $self, $name ) = @_;
	$name =~ s/\W/_/g;
	return ( $name =~ /^\d/ ? "_$name" : $name );
}

#-----------------------------------------------------------------
#
#  Error handling
#
#-----------------------------------------------------------------
my $DEFAULT_THROW_WITH_LOG   = 0;
my $DEFAULT_THROW_WITH_STACK = 1;

#-----------------------------------------------------------------
# throw
#-----------------------------------------------------------------
sub throw {
	my ( $self, $msg ) = @_;
	$msg .= "\n" unless $msg =~ /\n$/;

	# make an instance, if called as a class method
	unless ( ref $self ) {
		no strict 'refs';
		$self = $self->new;
	}

	# add (optionally) stack trace
	$msg ||= 'An error.';
	my $with_stack = (
					   defined $self->enable_throw_with_stack
					   ? $self->enable_throw_with_stack
					   : $DEFAULT_THROW_WITH_STACK
	);
	my $result = ( $with_stack ? $self->format_stack($msg) : $msg );

	# die or log and die?
	my $with_log = (
					 defined $self->enable_throw_with_log
					 ? $self->enable_throw_with_log
					 : $DEFAULT_THROW_WITH_LOG
	);
	if ($with_log) {
		$LOG->logdie($result);
	} else {
		die($result);
	}
}

#-----------------------------------------------------------------
# Some throwing options
#
#    These options are not set by using AUTOLOAD (as other regular
#    attributes) because AUTOLOAD could raise exception and we would be
#    in a deep..., well deep recursion.
#
#    Default values are: NO  enable_throw_with_log
#                        YES enable_throw_with_stack
#    (but they are globally changeable by calling
#     default_throw_with_log and default_throw_with_stack)
#
#-----------------------------------------------------------------
sub enable_throw_with_log {
	my ( $self, $value ) = @_;
	$self->{enable_throw_with_log} = ( $value ? 1 : 0 )
	  if ( defined $value );
	return $self->{enable_throw_with_log};
}

sub default_throw_with_log {
	my ( $self, $value ) = @_;
	$DEFAULT_THROW_WITH_LOG = ( $value ? 1 : 0 )
	  if defined $value;
	return $DEFAULT_THROW_WITH_LOG;
}

sub enable_throw_with_stack {
	my ( $self, $value ) = @_;
	$self->{enable_throw_with_stack} = ( $value ? 1 : 0 )
	  if defined $value;
	return $self->{enable_throw_with_stack};
}

sub default_throw_with_stack {
	my ( $self, $value ) = @_;
	$DEFAULT_THROW_WITH_STACK = ( $value ? 1 : 0 )
	  if defined $value;
	return $DEFAULT_THROW_WITH_STACK;
}

#-----------------------------------------------------------------
# format_stack
#-----------------------------------------------------------------
sub format_stack {
	my ( $self, $msg ) = @_;
	my $stack  = $self->_reformat_stacktrace($msg);
	my $class  = ref($self) || $self;
	my $title  = "------------- EXCEPTION: $class -------------";
	my $footer = "\n" . '-' x CORE::length($title);
	return "\n$title\nMSG: $msg\n" . $stack . $footer . "\n";
}

#-----------------------------------------------------------------
# _reformat_stacktrace
#    Taken from bioperl.
#
#  Takes one argument - an error message. It uses it to remove its
#  repeated occurences from each line (not to print it).
#
#  Reformatting of the stack:
#    1. Shift the file:line data in line i to line i+1.
#    2. change xxx::__ANON__() to "try{} block"
#    3. skip the "require" and "Error::subs::try" stack entries (boring)
#  This means that the first line in the stack won't have
#  any file:line data.
#-----------------------------------------------------------------
sub _reformat_stacktrace {
	my ( $self, $msg ) = @_;
	my $stack = Carp->longmess;
	$stack =~ s/\Q$msg//;
	my @stack = split( /\n/, $stack );
	my @new_stack = ();
	my ( $method, $file, $linenum, $prev_file, $prev_linenum );
	my $stack_count = 0;
	foreach my $i ( 0 .. $#stack ) {

		if ( ( $stack[$i] =~ /^\s*([^(]+)\s*\(.*\) called at (\S+) line (\d+)/ )
			 || ( $stack[$i] =~ /^\s*(require 0) called at (\S+) line (\d+)/ ) )
		{
			( $method, $file, $linenum ) = ( $1, $2, $3 );
			$stack_count++;
		} else {
			next;
		}
		if ( $stack_count == 1 ) {
			push @new_stack, "STACK: $method";
			( $prev_file, $prev_linenum ) = ( $file, $linenum );
			next;
		}
		if ( $method =~ /__ANON__/ ) {
			$method = "try{} block";
		}
		if (    ( $method =~ /^require/ and $file =~ /Error\.pm/ )
			 || ( $method =~ /^Error::subs::try/ ) )
		{
			last;
		}
		push @new_stack, "STACK: $method $prev_file:$prev_linenum";
		( $prev_file, $prev_linenum ) = ( $file, $linenum );
	}
	push @new_stack, "STACK: $prev_file:$prev_linenum";
	return join "\n", @new_stack;
}

#-----------------------------------------------------------------
# Set methods test whether incoming value is of a correct type.
# Here we return message explaining that it isn't.
#-----------------------------------------------------------------
sub _wrong_type_msg {
	my ( $self, $given_type_or_value, $expected_type, $method ) = @_;
	my $msg = 'In method ';
	if ( defined $method ) {
		$msg .= $method;
	} else {
		$msg .= ( caller(1) )[3];
	}
	return (
"$msg: Trying to set '$given_type_or_value' but '$expected_type' is expected."
	);
}

#-----------------------------------------------------------------
# Set methods test whether incoming value exceeds the cardinality
# constraints for the OWL Class.
# Here we return message explaining that it has exceeded.
#-----------------------------------------------------------------
sub _bad_cardinality_msg {
    my ( $self, $expected_size, $method ) = @_;
    my $msg = 'In method ';
    if ( defined $method ) {
        $msg .= $method;
    } else {
        $msg .= ( caller(1) )[3];
    }
    return (
"$msg: Trying to add property but we have exceeded cardinality constraints of '$expected_size'."
    );
}

#-----------------------------------------------------------------
# Deal with 'set', 'get' and 'add_' methods.
#-----------------------------------------------------------------
sub AUTOLOAD {
	my ( $self, @new_values ) = @_;
	my $ref_sub;
	if ( $AUTOLOAD =~ /.*::(\w+)/ && $self->_accessible("$1") ) {

		# get/set method
		my $attr_name     = "$1";
		my $attr_type     = $self->_attr_prop( $attr_name, TYPE ) || STRING;
		my $attr_post     = $self->_attr_prop( $attr_name, POST );
		my $attr_is_array = $self->_attr_prop( $attr_name, ISARRAY );
		my $attr_readonly = $self->_attr_prop( $attr_name, READONLY );
		$ref_sub = sub {
			local *__ANON__ = "__ANON__$attr_name" . "_" . ref($self);
			my ( $this, @values ) = @_;
			return $this->_getter($attr_name) unless @values;
			$self->throw("Sorry, the attribute '$attr_name' is read-only.")
			  if $attr_readonly;

			# here we continue with 'set' method:
			if ($attr_is_array) {
				my @result =
				  ( ref( $values[0] ) eq 'ARRAY' ? @{ $values[0] } : @values );
				foreach my $value (@result) {
					$value = $this->check_type( $AUTOLOAD, $attr_type, $value );
				}
				$this->_setter( $attr_name, $attr_type, \@result );
			} else {
				# no need to check cardinality contraints here ... sets one value here ...
				$this->_setter(
								$attr_name,
								$attr_type,
								$this->check_type(
												  $AUTOLOAD, $attr_type, @values
								)
				);
			}

			# call post-procesing (if defined)
			$this->$attr_post( $this->{$attr_name} ) if $attr_post;
			return $this->{$attr_name};
		};
	} elsif ( $AUTOLOAD =~ /.*::add_(\w+)/ && $self->_accessible("$1") ) {

		# add_XXXX method
		my $attr_name = "$1";
		my $attr_post = $self->_attr_prop( $attr_name, POST );
		if ( $self->_attr_prop( $attr_name, ISARRAY ) ) {
			my $attr_type = $self->_attr_prop( $attr_name, TYPE ) || STRING;
			$ref_sub = sub {
				local *__ANON__ = "__ANON__$attr_name" . "_" . ref($self);
				my ( $this, @values ) = @_;
				if (@values) {
					my @result = (
								   ref( $values[0] ) eq 'ARRAY'
								   ? @{ $values[0] }
								   : @values );
					# TODO check if we have cardinality constraints ( size of @results + size of existing values)
					foreach my $value (@result) {
						$value =
						  $this->check_type( $AUTOLOAD, $attr_type, $value );
					}
					$this->_adder( $attr_name, $attr_type, @result );
				}

				# call post-procesing (if defined)
				$this->$attr_post( $this->{$attr_name} ) if $attr_post;
				return $this;
			  }
		} else {
			$self->throw(
				 "Method '$AUTOLOAD' is allowed only for array-type attributes."
			);
		}
	} else {
		$self->throw("No such method: $AUTOLOAD");
	}
	no strict 'refs';
	*{$AUTOLOAD} = $ref_sub;
	use strict 'refs';
	return $ref_sub->( $self, @new_values );
}

#-----------------------------------------------------------------
# The low level get/set methods. They are called from AUTOLOAD, and
# they are separated here so they can be overriten - as they are in
# the service skeletons, for example. Also, there may be situation
# that one can call them if other features (such as type checking) are
# not required.
#-----------------------------------------------------------------
sub _getter {
	my ( $self, $attr_name ) = @_;
	return $self->{$attr_name};
}

sub _setter {
	my ( $self, $attr_name, $attr_type, $value ) = @_;
	$self->{$attr_name} = $value;
}

sub _adder {
	my ( $self, $attr_name, $attr_type, @values ) = @_;
	push( @{ $self->{$attr_name} }, @values );
}

#-----------------------------------------------------------------
# Keep it here! The reason is the existence of AUTOLOAD...
#-----------------------------------------------------------------
sub DESTROY {
}

#-----------------------------------------------------------------
#
# Check type of @value against $expected_type. Return checked $value
# (perhaps trimmed, or otherwise corrected - e.g. wrapped in an
# appropriate object), or undef if the $value is of a wrong type.
#
#-----------------------------------------------------------------
sub check_type {
	my ( $self, $name, $expected_type, @values ) = @_;
	my $value = $values[0];

	# first process cases when an expected type is a simple string,
	# integer etc. (not OWL::Data::String etc.) - e.g. when an ID
	# attribute is being set
	if ( $expected_type eq STRING ) {
		return $value;
	} elsif ( $expected_type eq INTEGER ) {
		$self->throw( $self->_wrong_type_msg( $value, $expected_type, $name ) )
		  unless $value =~ m/^\s*[+-]?\s*\d+\s*$/;
		$value =~ s/\s//g;
		return $value;
	} elsif ( $expected_type eq FLOAT ) {
		$self->throw( $self->_wrong_type_msg( $value, $expected_type, $name ) )
		  unless $value =~
			  m/^\s*[+-]?\s*(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$/;
		$value =~ s/\s//g;
		return $value;
	} elsif ( $expected_type eq BOOLEAN ) {
		return ( $value =~ /true|\+|1|yes|ano/ ? '1' : '0' );
	} elsif ( $expected_type eq DATETIME ) {
		my $iso;
		eval {
			$iso = (
					 HTTP::Date::time2isoz(
						  HTTP::Date::str2time( HTTP::Date::parse_date($value) )
					 )
			);
		};
		$self->throw( $self->_wrong_type_msg( $value, 'ISO-8601', $name ) )
		  if $@;
		return $iso;    ### $iso =~ s/ /T/;  ??? TBD
	} else {

		# Then process cases when the expected type is a name of a
		# real object (e.g. OWL::Data::String); for these cases the
		# $value[0] can be already such object - in which case nothing
		# to be done; or $value[0] can be HASH, or @values can be a
		# list of name/value pairs, in which case a new object (of
		# type $expected_type) has to be created and initialized by
		# @values; and, still in the latter case, if the @values has
		# just one element (XX), this element is considered a 'value':
		# it is treated as a a hash {value => XX}.
		return $value if UNIVERSAL::isa( $value, $expected_type );
		$value = { value => $value }
		  unless ref($value) || @values > 1;
		my ($value_ref_type) = ref($value);
		if ( $value_ref_type eq 'HASH' ) {

			# e.g. $sequence->Length ( { value => 12, id => 'IR64'} )
			return $self->create_member( $name, $expected_type, %$value );
		} elsif ( $value_ref_type eq 'ARRAY' ) {

			# e.g. $sequence->Length ( [ value => 12, id => 'IR64'] )
			return $self->create_member( $name, $expected_type, @$value );
		} elsif ($value_ref_type) {

			# e.g. $sequence->Length ( new OWL::Data::Integer ( value => 12) )
			$self->throw(
						  $self->_wrong_type_msg(
										  $value_ref_type, $expected_type, $name
						  )
			) unless UNIVERSAL::isa( $value, $expected_type );
			return $value;
		} else {

			# e.g. $sequence->Length (value => 12, id => 'IR64')
			return $self->create_member( $name, $expected_type, @values );
		}
	}
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub create_member {
	my ( $self, $name, $expected_type, @values ) = @_;
	eval "require $expected_type";
	$self->throw( $self->_wrong_type_msg( $values[0], $expected_type, $name ) )
	  if $@;
	return "$expected_type"->new(@values);
}

#-----------------------------------------------------------------
# as_string (an "" operator overloading)
#-----------------------------------------------------------------
my $DUMPER;

BEGIN {
	use Dumpvalue;
	use IO::String;
	$DUMPER = Dumpvalue->new();

	#    $DUMPER->set (veryCompact => 1);
}

sub as_string {
	my $self = shift;
	my $dump_str;
	my $io  = IO::String->new( \$dump_str );
	my $oio = select($io);
	$DUMPER->dumpValue( \$self );
	select($oio);
	return $dump_str;
}
1;
__END__

=head1 NAME

OWL::Base - Hash-based abstract super-class for all owl 2 perl objects

=head1 SYNOPSIS

  use base qw( OWL::Base );

  $self->throw ("This is an error");

  $LOG->info ('This is an info message.');
  $LOG->error ('This is an error to be logged.');

=head1 DESCRIPTION

This is a hash-based implementation of a general owl2perl
super-class. Most owl2perl objects should inherit from this.

=head1 CONTACT

Re-factored by Edward Kawas E<lt>edward.kawas@gmail.comE<gt> from a
similar module in perl moses (MOSES::MOBY::Base) created by Martin Senger
E<lt>martin.senger@gmail.comE<gt>.

=head1 ACCESSIBLE ATTRIBUTES

Most of the owl2perl objects are just containers of other objects (attributes,
members). Therefore, in order to create a new OWL2Perl object it
is often enough to inherit from this C<OWL::Base> and to list allowed
attributes. The object lists only new, additional, attributes (those
defined in its parent classes are already available).

This is done by creating a I<closure> with a list of allowed attribute
names. These names correspond with the allowed I<get> and I<set>
methods. For example:

  {
    my %_allowed =
        (
	 id         => undef,
	 namespace  => undef,
	 );
  }

The closure above allows to call:

    $obj->id;                    # a get method
    $obj->id ('my id');          # a set method

    $obj->namespace;             # a get method
    $obj->namespace ('my ns');   # a set method

Well, not yet. The closure also needs two methods that access these
(and only these - that is why it is a closure, after all)
attributes. Here they are:

  {
    my %_allowed =
	(
	 id         => undef,
	 namespace  => undef,
	 );
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
  }

More about these methods in a moment.

Each attribute has also associated some properties (that is why we
need the second method in the closure, the C<_attr_prop>). For example:

  {
    my %_allowed =
	(
	 id         => undef,
	 namespace  => undef,
	 date  => {type => OWL::Base->DATETIME},
	 numbers      => {type => OWL::Base->INTEGER, is_array => 1},
     primitive  => {type => OWL::Base->BOOLEAN},
	 );
    ...
  }

The recognized property names are:

=over

=item B<type>

It defines a type of its attribute. It can be a primitive type - one
of those defined as constants in C<OWL::Base>
(e.g. "OWL::Base->INTEGER") - or a name of a real object
(e.g. C<OWL::Data::OWL::Class>).

When an attribute new value is being set it is checked against this
type, and an exception is thrown if the value does not comply with the
type.

Default type (used also when the whole properties are undef) is
"OWL::Base->STRING".

=item B<is_array>

A boolean property. If set to true it allows to set more values to
this attribute. It also allows to call a method prefixed with C<add_>
to add a new value (or values) to this attribute. 

Default value is C<false>.

Recognized values for C<true> are: C<1>, C<yes>, C<true>, C<+> and
C<ano>. Anything else is considered C<false>.

=item B<readonly>

A boolean property. If set to true the atribute can only be read.

=item B<post>

A property containing a reference to a subroutine. This subroutine is
called after a new value was set. It allows to do some
post-processing. For example:

  {
    my %_allowed =
	(
	 value  => {post => sub { shift->{isValueCDATA} = 0; } },
	 );
    ...
  }

=back

Now we know what attribute properties are - so we can define what
these methods in closure do (even though you do not need to know -
unless C<The Law of Leaky Abstractions> starts showing).

=over

=item C<_accessible ($attr_name)>

Return 1 if the parameter C<$attr_name> is an allowed name to be
set/get in this class; otherwise, pass it to the parent class.

=item C<_attr_prop ($attr_name, $prop_name)>

Return a value of a property given by name $prop_name for given
attribute $attr_name; if such attribute does not exist here, pass it
to the parent class.

=back

=head1 THROWING EXCEPTIONS

One of the functionalities that C<OWL::Base> provides is the ability
to B<throw()> exceptions with pretty stack traces.

=head2 throw

Throw an exception. An argument is an error message.

=head2 format_stack

Return a nicely formatted stack trace. The resul includes also an
error message given as a scalar argument. Usually, this method is not
called directly but via C<throw> (unless C<enable_throw_with_stack>
was set to true).

    print $self->format_stack ("Something terrible happen.");

=head1 LOGGING

Logging is available through the $LOG variable create and exported as a result of using this module.

As a service writer, you can $LOG->info('some message'), $LOG->warn('some warning'),
 $LOG->debug('some debug statement') or $LOG->error('some error message').

The next question is where are these messages sent? OWL2Perl allows you to 
configure where to send messages in the log4perl.properties file. When 
you run owl2perl-install.pl this module, this file is automatically created 
for you and placed (usually) in your home directory in a folder called 
Perl-OWL2Perl. If no properties file exists, then the messages are usually 
placed in STDOUT.

=head1 OTHER SUBROUTINES

=head2 new

Create an empty hash-based object. Then call B<init()> in order to do
any initializing steps. This class provides only an empty C<init()>
but sub-classes may have it richer. Finally, fill the new object with
the given arguments (name/value pairs). The filling is done via C<set>
methods - which means that only attributes allowed for this particular
object can be used.

Arguments are name/value pairs. A special case is allowed: when a
single element argument occurs, it is treated as a "value". For
example, it is allowed to write:

    $sadiint = new OWL::Data::Integer (42);

instead of a long way (doing the same):

    $sadiint = new OWL::Data::Integer (value => 42);

=head2 init

Called after an object has been created (in B<new()>) and before the
values given in the constructor have been set. No arguments.

If your sub-class implements this method, make sure that it calls also
the same method of its super class:

   sub init {
       my ($self) = shift;
       $self->SUPER::init();
       # ... here do what you wish to do
       # ...
   }


=head2 toString

Return an (almost) human-readable description of any object.

Without any parameter, it stringifies the caller object
(self). Otherwise it stringifies the object given as parameter.

    print $self->toString;

    my $good_stuff = { yes => [1,2,3],
		       no  => { net => 'R', nikoliv => 'C' },
		   };
    print $self->toString ($good_stuff);


=cut


#-----------------------------------------------------------------
# Dealing with creating XML...
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Logging...
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# module_name_escape
#
#   Make sure that the given name can be used as (part of) a Perl
#   module name.
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# datatype2module
#
#   Prefix given data type name with a package name OWL::DATA,
#   and call 'module_name_escape' to substitute bad characters.
#   The result is a valid Perl module name that can represent
#   the given OWL2Perl data type.
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# oProperty2module
#
#   Prefix given an object property name with a package name OWL::DATA::OWL,
#   and call 'module_name_escape' to substitute bad characters.
#   The result is a valid Perl module name that can represent
#   the given object property.
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# uri2package
#
#   Takes a uri and creates a suitable package string from it.
#   This string can then be used as is, or as a prefix/suffix
#   to an existing package string.
#   
#   Example:
#    uri given: 
#      http://sadiframework.org/examples/regression#DatedValue   
#    package returned:
#      sadiframework::org::examples::regression
#
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# init_config
#-----------------------------------------------------------------

=head2 init_config

Find and read given configuration files (and perhaps some
others). Import all their properties into C<OWLCFG> namespace. More
about how to use configuration properties is in L<OWL::Config>
module.

But making a long story short, this is all what you need in your
service implementation to use a property (excluding the fact that you
need to know the property name):

    $self->init_config ('my.conf');
    open HELLO, $OWLCFG::MABUHAY_RESOURCE_FILE
	or $self->throw ('Mabuhay resource file not found.');

Arguments are optional and contain the file names of the configuration
files to be read, and/or hash references with the direct configuration
arguments. The files are looking for at the paths defined in the @INC,
and - if set - by the environment variable C<OWL_CFG_DIR>.

=cut

