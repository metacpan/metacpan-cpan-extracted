package SQL::Exec;
our $VERSION = '0.10';
use strict;
use warnings;
use feature 'switch';
use Carp;
use Exporter 'import';
use Scalar::Util 'blessed', 'reftype', 'openhandle';
use List::MoreUtils 'any';
use DBI;
use DBI::Const::GetInfoType;
use DBIx::Connector;
use SQL::SplitStatement;
use SQL::Exec::Statement;

# Note: This file contains both a POD documentation which describes the public
# API of this package and a technical documentation (on the internal methods and
# how to subclasse this package) in standard Perl comments.

=encoding utf-8

=head1 NAME

SQL::Exec - Simple thread and fork safe database access with functionnal and OO interface

=head1 SYNOPSIS

  use SQL::Exec ':all';
  
  connect('dbi:SQLite:dbname=db_file');
  
  execute(SQL);
  
  my $val = query_one_value(SQL);
  
  my @line = query_one_line(SQL);
  
  my @table = query_all_line(SQL);

=head2 Main functionnalities

SQL::Exec is (another) interface to the DBI which strive for simplicity. Its main
functionalities are:

=over 4

=item * DBMS independent. The module offers specific support for some DB server
but can work with any DBD driver;

=item * Extremely simple, a query is always only one function or method call;

=item * Everything is as efficient: you choose the function to call based
only on the data that you want to get back, not on some supposed performance
benefit;

=item * Supports both OO and functional paradigm with the same interface and
functionalities;

=item * Hides away all DBIism, you do not need to set any options, they are
handled by the library with nice defaults;

=item * Safe: SQL::Exec verify that what happens is what you meant;

=item * Not an ORM, nor a query generator: you are controling your SQL;

=item * Easy to extends to offer functionalities specific to one DB server;

=item * Handles transparently network failure, fork, thread, etc;

=item * Safely handle multi statement query and automatic transaction;

=item * Handles prepared statements and bound parameters.

=back

All this means that SQL::Exec is extremely beginners friendly, it can be used
with no advanced knowledge of Perl and code using it can be easily read by people
with no knowledge of Perl at all, which is interesting in a mixed environment.

Also, the fact that SQL::Exec does not try to write SQL for the programmer (this
is a feature, not a bug), ease the migration to other tools or languages if a big
part of the application logic is written in SQL.

Thus SQL::Exec is optimal for fast prototyping, for small applications which do
not need a full fledged ORM, for migrating SQL code from/to an other environment,
etc. It is usable (thanks to C<DBIx::Connector>) in a CGI scripts, in a mod_perl
program or in any web framework as the database access layer.

=head1 DESCRIPTION

=cut

#dire un peu ce qu'est DBI et ce que sont les DBD.

=head2 Support of specific DB

The C<SQL::Exec> library is mostly database agnostic. However there is some
support (limited at the moment) for specific database which will extends the
functionnalities of the library for those database.

If there is a sub-classe of C<SQL::Exec> for your prefered RDBMS you should
use it (for both the OO and the functionnal interface of the library) rather than
using directly C<SQL::Exec>. These sub-classes will provide tuned functions
and method for your RDBMS, additionnal functionnalities, will set specific
database parameters correctly and will assist you to connect to your desired
database.

You will find in L</"Sub-classes"> a list of the supported RDBMS and a link to
the documentation of their specific modules.  If your prefered database is not
listed there, you can still use C<SQL::Exec> directly and get most of its benefits.

Do not hesitate to ask for (or propose) a module for your database of choice.

=head2 Exported symbols

Each function of this library (that is everything described below except C<new>
and C<new_no_connect> which are only package method) may be exported on request.

There is also a C<':all'> tag to get everything at once. Just do :

  use SQL::Exec ':all';

at the beginning of your file to get all the power of C<SQL::Exec> with an overhead
as small as possible.

=cut



################################################################################
################################################################################
##                                                                            ##
##                            HELPER FUNCTIONS                                ##
##                                                                            ##
################################################################################
################################################################################
# The functions in this section are for internal use only by this package
# or by subclasses. The functions here are NOT method.



# functions are 'push-ed' below in this array.
our @EXPORT_OK = ();
# every thing is put in ':all' at the end of the file.
our %EXPORT_TAGS = ();

our @CARP_NOT = ('DBIx::Connector');



# The structure of a SQL::Exec object, this hash is never made an object but
# it is copied by get_empty whenever a new object must be created.
# N.B.: The get_empty function must be adapted if new references are added
# inside this object (like e.g. options and restore_options), to ensure that
# they are properly copied.
#
# Warning : an SQL::Exec::Statement object shares the sames structure but with
# an added 'parent' pointer.
my %empty_handle;
BEGIN {
	%empty_handle = (
			options => {
					die_on_error => 1, # utilise croak
					print_error => 1, # utilise carp pour les erreurs
					print_warning => 1, # utilise toujours carp
					print_query => 0, # spécifie un channel à utiliser
					strict => 1,
					replace => undef,
					connect_options => undef,
					auto_transaction => 1,
					auto_split => 1,
					use_connector => 1,
					stop_on_error => 1,
					line_separator => "\n", # pour query_to_file
					value_separator => ';', # pour query_to_file
				},

			restore_options => {},

			db_con => undef,
			is_connected => 0,
			last_req_str => "",
			last_req => undef,
			last_stmt => undef,
			req_over => 1,
			auto_handle => 0,
			#last_msg => undef,
		);
}

# This variable stores the default instance of this class. It is set up in a
# BEGIN block.
my $default_handle;

# Return a reference of a new copy of the empty_handle hash, used by the
# constructors of the class.
sub get_empty {
	my %new_empty = %empty_handle;
	$new_empty{options} = { %{$empty_handle{options}} };
	$new_empty{restore_options} = { %{$empty_handle{restore_options}} };
	return \%new_empty;
}

# One of the three function below (just_get_handle, get_handle and
# check_options) must be called at each entry-point of the library with the
# syntax: '&function;' which allow the current @_ array to be passed to the
# function without being copied.
# Their purpose is to check if the method was invoqued as a method or as a
# function in which case the default class instance is used.
#
# This function is called by the very few entry point of the library which are
# not supposed to clear the errstr field of the instance.
sub just_get_handle {
	return (scalar(@_) && blessed $_[0] && $_[0]->isa(__PACKAGE__)) ? shift @_ : $default_handle;
}

# See above for the purpose and usage of this function.
#
# This function is called by the entry points which must not restore the saved
# options or which are not expected to receive any function.
sub get_handle {
	my $c = &just_get_handle;
	delete $c->{errstr};
	delete $c->{warnstr};
	return $c;
}

# See above for the purpose and usage of this function.
#
# This function is called by most of the entry points of the library which are
# generally expected to work both as package function and as instance method.
# Also, this function check if the last argument it receives is a hash-ref and,
# if so, assume that it is option to be applied for the duration of the current
# call.
sub check_options {
	my $c = &get_handle;

	my $h = {};
	if (@_ && ref($_[-1]) && ref($_[-1]) eq 'HASH') {
		$h = pop @_;
	}
	
	my $ro = $c->set_options($h);
	
	if ($ro) {
		$c->{restore_options} = $ro;
	} else {
		$c->strict_error('The options were not correctly applied due to errors') and return;
	}

	return $c;
}

# Just a small helper function for the sub-classes to check if a given DBD
# driver is installed.
sub test_driver {
	my ($driver) = @_;

	return any { $_ eq $driver } DBI->available_drivers();
}

# function used to sanitize the input to the option set/get methods.
sub __boolean {
	if (defined $_[0]) {
		return $_[0] ? 1 : 0;
	} else {
		return undef;
	}
}

sub __set_boolean_opt {
	my ($c, $o, @v) = @_;

	$c->__restore_options();
	my $r = $c->{options}{$o};
	$c->{options}{$o} = __boolean($v[0]) if @v;
	return $r;
}

sub __set_opt {
	my ($c, $o, @v) = @_;

	$c->__restore_options();
	my $r = $c->{options}{$o};
	$c->{options}{$o} = $v[0];
	return $r;
}

################################################################################
################################################################################
##                                                                            ##
##                         CONSTRUCTORS/DESTRUCTORS                           ##
##                                                                            ##
################################################################################
################################################################################



=head1 CONSTRUCTORS/DESTRUCTORS

If you want to use this library in an object oriented way (or if you want to use
multiple database connection at once) you will need to create C<SQL::Exec>
object using the constructors described here. If you want to use this library in
a purely functionnal way then you will want to take a look at the L</"connect">
function described below which will allow you to connect the library without using
a single object.

=head2 new

  my $h = SQL::Exec->new($dsn, $user, $password, %opts);

Create a new C<SQL::Exec> object and connect-it to the database defined by
the C<$dsn> argument, with the supplied C<$user> and C<$password> if necessary.

The syntax of the C<$dsn> argument is described in the manual of your C<DBD>
driver. However, you will probably want to use one of the existing sub-classes of
this module to assist you in connecting to some specific database.

The C<%opts> argument is optionnal and may be given as a hash or as a hash
reference. If the argument is given it set accordingly the option of the object
being created. See the L</"set_options"> method for a description of the available
options.

If your DB has a specific support in a L<sub-classe|/"Sub-classes"> you must
use its specific constructor to get the additionnal benefits it will offer.

=head2 new_no_connect

  my $h = SQL::Exec->new_no_connect(%opts);

This constructor creates a C<SQL::Exec> object without connecting it to any
database. You will need to call the L</"connect"> option on the handle to connect
it to a database.

The C<%opts> argument is optionnal and is the same as for the C<new> constructor.

=head2 destructor

Whenever you have finished working with a database connection you may close it
(see the L</"disconnect"> function) or you may just let go of the database handle.
There is a C<DESTROY> method in this package which will take care of closing the
database connection correctly whenever your handle is garbage collected.

=cut

# Les options que l'on donne à new, sont valable pour l'objet, pas juste
# pour l'appel de fonctions/méthode, comme les autres fonctions.
# Les options sont a fixer à chaque création d'objet (indépendamment de l'objet
# par défaut).
# A constructor which will not connect 
sub new_no_connect {
	my ($class, @opt) = @_;

	my $c = get_empty();
	bless $c, $class;
	$c->set_options(@opt);
	return $c;
}

# dans le cas ou la connection échoue, l'objet est quand même créée et renvoyé
# si jamais on ignore les erreurs.
sub new {
	my ($class, @args) = @_;
	
	my ($con_str, $user, $pwd, @opt) = $class->build_connect_args(@args);
	my $c = new_no_connect($class, @opt);
	$c->__connect($con_str, $user, $pwd);
	return $c;
}

# This bless the default handle. The handle is blessed again if it is
# connected in a sub classe.
UNITCHECK {
	$default_handle = __PACKAGE__->new_no_connect();
}


sub DESTROY {
	my $c = shift;
	$c->__disconnect() if $c->{is_connected};
}



################################################################################
################################################################################
##                                                                            ##
##                            INTERNAL METHODS                                ##
##                                                                            ##
################################################################################
################################################################################
# The methods in this section are for internal use only by this package
# or by subclasses. The functions here ARE methods and must be called explicitely
# on an instance of this class (or of one of its sub-classes).


# The purpose of this function is to be overidden in sub-classes which would
# take a different set of argument for their constructors without having to
# redefine the constructor itself.
sub build_connect_args {
	my ($class, $con_str, $user, $pwd, @opt) = @_;

	return ($con_str, $user, $pwd, @opt);
}

# This method must be called when an error condition happen. It croaks, carps or
# does nothing depending on the current option. It also set the errstr variable.
sub error {
	my ($c, $msg, @args) = @_;

	$c->{errstr} = sprintf $msg, @args;
	$c->{parent}{errstr} = $c->{errstr} if $c->{parent};

	if ($c->{options}{die_on_error}) {
		croak $c->{errstr};
	} elsif ($c->{options}{print_error}) {
		carp $c->{errstr};
	}

	return;
}

# Same thing but for warning which may only be printed.
sub warning {
	my ($c, $msg, @args) = @_;

	$c->{warnstr} = sprintf $msg, @args;
	$c->{parent}{warnstr} = $c->{warnstr} if $c->{parent};

	if ($c->{options}{print_warning}) {
		carp $c->{warnstr};
	}

	return;
}

# Same thing but for violation of strictness, test if the currant instance is in
# strict mode and, if so, convert strictness violations into errors.
#
# if the condition which trigger a strict_error is  costly then it must be tested
# only when strict_error is defined (true or false). Otherwise, the strict_error
# method may be called without testing the strict_error option.
# You must not return when a strict error is detected, as the processing is able to
# continue after it. You must check for the return value of the function and return
# if it is true C<$c->strict_error(...) and return;
sub strict_error {
	my ($c, $msg, @args) = @_;

	if (defined $c->{options}{strict}) {
		if ($c->{options}{strict}) {
			$c->error($msg, @args);
			return 1;
		} else {
			$c->warning($msg, @args);
			return;
		}
	} else {
		return;
	}
}

sub format_dbi_error {
	my ($c, $msg, @args) = @_;
	
	#$c = $c->{parent} if $c->{parent};
	
	# TODO: corriger ça si on n'utilise pas DBIx::Connector
	my ($errstr, $err, $state);
	# TODO: ici on utilise le fait que dbh() renvoie un hashref (toujours), il faudrait
	# voir si on peut tester la connection plus proprement sans dépendre de la
	# représentation qu'en fait DBIx::Connector.
	# le test de dbh est inutile mais plus sûr si la représentation change.
	if ($c->{db_con} &&  blessed $c->{db_con}->dbh()) {
		my $dbh = $c->{db_con}->dbh();
		$errstr = $dbh->errstr // $dbh->func('plsql_errstr') // '';
		$err = $dbh->err // '0';
		$state = $dbh->state // '0'; # // pour la coloration syntaxique de Gedit
	} else {
		$errstr = $DBI::errstr // '';
		$err = $DBI::err // '0';
		$state = $DBI::state // '0'; # // pour la coloration syntaxique de Gedit
	}
	my $err_msg = "Error during the execution of the following request:\n\t".$c->{last_req_str}."\n";
	$err_msg .= "Error: $msg\n\t Error Code: $err\n\t Error Message: $errstr\n\t State: $state\n";

	return $err_msg;
}
# This function is called in case of error in a call to the DBI in order to
# format an error message
sub dbi_error {
	my ($c, $msg, @args) = @_;

	$c->error($c->format_dbi_error($msg.' ',@args));

	return;
}

sub __replace {
	my ($c, $str) = @_;

	my $r = $c->{options}{replace};
	if ($r && reftype($r) eq 'CODE') {
		local $_ = $str;
		$str = eval { $r->(); $_ };
		return $c->error("A call to the replace procedure has failed with: $@") if $@;
	} elsif ($r and blessed($_[0]) and $_[0]->can('replace')) {
		$str = eval { $r->replace($str) };
		return $c->error("A call to the replace method of the object given procedure has failed with: $@") if $@;
	} elsif ($r) {
		confess "should not happen";
	}

	return $str;
}

# This function is called each time an SQL statement is sent to the database
# it possibly apply the replace procedure of a String::Replace object on the
# SQL query string and save the query.
sub query {
	my ($c, $query) = @_;

	$query = $c->__replace($query) or return;

	if ($c->{options}{print_query}) {
		chomp (my $r = $query);
		print { $c->{options}{print_query} } $r."\n";
	}
	
	$c->{last_req_str} = $query;

	return $query;
}


# This function must be called by the library entry-points (user called
# functions) if they need a connection to the database.
sub check_conn {
	my ($c) = @_;

	my $rc = $c->{parent} ? $c->{parent} : $c;
	
	if (!$rc->{is_connected}) {
		$c->error("The library is not connected");
		return;
	}
	return 1;
}


# This internal version of the disconnect function may be called from the
# connect function.
sub __disconnect {
	my ($c) = @_;
	if ($c->{is_connected}) {
		$c->{last_req}->finish() if defined $c->{last_req} && !$c->{req_over};
		$c->query("logout");
		$c->{db_con}->disconnect if defined $c->{db_con};
		$c->{is_connected} = 0;
		return 1;
	} else {
		$c->strict_error("The library is not connected");
		return;
	}
}

# This function is also expected to be extended in sub-classes and is used by
# the default constructors.
sub get_default_connect_option {
	return (
		PrintError => 0, # les erreurs sont récupéré par le code qui les affiches
		RaiseError => 0, # lui même.
		Warn => 1,      # des warning généré par DBI
		PrintWarn => 1, # les warning renvoyé par le drivers lui même
		AutoCommit => 1,
		AutoInactiveDestroy => 1, # pour DBIx::Connector
		ChopBlanks => 0,
		LongReadLen => 4096, # TODO: Il faut une fonction pour le modifier, Cf la doc de ce paramètre
		#TODO: il faudrait aussi ajouter du support pour les options Taint...
		FetchHashKeyName => 'NAME_lc'
		# cette constante apparait aussi dans low_level_fetchrow_hashref, dans
		# __get_columns_dummy et dans get_columns (juste lc);
	);
}

# Internal connect method, called by the constructors and by the connect function
# and by the sub-classses.
sub __connect {
	my ($c, $con_str, $user, $pwd) = @_;
	
	if ($c->{is_connected}) {
		if (not $c->{auto_handle}) {
			$c->strict_error("The object is already connected") and return;
		}
		$c->__disconnect();
	}
	
	my $usr = $user // ''; # //
	$c->query("login to '${con_str}' with user '${usr}'");
	
	my @l = DBI->parse_dsn($con_str);
	if (not @l or not $l[1]) {
		$c->error("Cannot connect with an invalid connection string");
		return;
	}
	
	my $con_opt = $c->{options}{connect_options} // { $c->get_default_connect_option() }; # //
	
	if ($c->{options}{use_connector}) {
		$c->{db_con} = DBIx::Connector->new($con_str, $user, $pwd, $con_opt);
		# TODO: ici on utilise le fait que dbh() renvoie un hashref (toujours), il faudrait
		# voir si on peut tester la connection plus proprement sans dépendre de la
		# représentation qu'en fait DBIx::Connector.
		# le test de dbh est inutile mais plus sûr si la représentation change.
		# (idem que pour errstr).
		if (!$c->{db_con} ||  ! blessed $c->{db_con}->dbh()) {
			$c->dbi_error("Cannot connect to the database");
			return;
		}	
		$c->{db_con}->disconnect_on_destroy(1);
		$c->{db_con}->mode('fixup');
	} else {
		$c->{db_con} = DBI->connect($con_str, $user, $pwd, $con_opt);
		if (!$c->{db_con}) {
			$c->dbi_error("Cannot connect to the database");
			return;
		}	
	}

	$c->{is_connected} = 1;
	return 1;
}

sub __restore_options {
	my ($c) = @_;

	foreach my $k (keys %{$c->{restore_options}}) {
		$c->{options}{$k} = $c->{restore_options}{$k};
	}

	$c->{restore_options} = {};

	return;
}

my %splitstatement_opt = (
		keep_terminator => 0,
		keep_extra_spaces => 0,
		keep_comments => 1,
		keep_empty_statements => 0,
	);
my %splitstatement_opt_grep = (
		keep_comments => 0,
		keep_empty_statements => 0,
	); 

my $sql_splitter = SQL::SplitStatement->new(%splitstatement_opt);
my $sql_split_grepper = SQL::SplitStatement->new(%splitstatement_opt_grep);

# split a string containing multiple query separated by ';' characters.
sub __split_query {
	my ($c, $str) = @_;
	return $str if not $c->{options}{auto_split};
	return grep { $sql_split_grepper->split($_) } $sql_splitter->split($str);
}

sub get_one_query {
	my ($c, $str) = @_;

	my @l = $c->__split_query($str);

	if (@l > 1) {
		return $c->error("The supplied query contains more than one statement");
	} elsif (@l == 0) {
		return $c->error("The supplied query does not contain any statements");
	} else {
		return $l[0]; # is always true
	}
}

################################################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#!                                                                            !#
#!                                WARNINGS                                    !#
#!                                                                            !#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
################################################################################

# All the functions below this points may be called by the users either in OO
# or in functionnal mode. So they must all fetch the correct handle to work with.
#
# This function may also all accept temporary option which will apply only for
# the duration of the function call. As these arguments are deactivated when the
# same handle is used next, none of this functions may be called by another
# function of the library (or else, the option handling would be wrong). Only
# function above this point may be called by other functions of this package.

################################################################################
################################################################################
##                                                                            ##
##                          GETTER/SETTER AND OPTIONS                         ##
##                                                                            ##
################################################################################
################################################################################

=head1 GETTER/SETTER AND OPTIONS

The functions and method described below are related to knowing and manipulating
the state of a database connection and of its options. The main function to set
the options of a database connection is the L<C<set_options>|/"set_options">
functions. However, you can pass a hash reference as the I<last> argument to any
function of this library with the same syntax as for the C<set_options> function
and the options that it describes will be in effect for the duration of the
function or method call.

Any invalid option given in this way to a function/method will result in a
C<'no such option'> error. If you do not die on error but are in strict mode, then
the called function will not be executed.

=head2 connect

  connect($dsn, $user, $password, %opts);
  $h->connect($dsn, $user, $password, %opts);

This function/method permits to connect a handle which is not currently connected
to a database (either because it was created with C<new_no_connect> or because
C<disconnect> has been called on it). It also enable to connect to library to
a database in a purely functionnal way (without using objects). In that case
you can maintain only a single connection to a database. This is the connection
that will be used by all the function of this library when not called as an
object method. This connection will be refered to as the I<default handle> in this
documentation. Its the handle that all other function will use when not applied
to an object.

You can perfectly mix together the two styles (OO and functionnal): that is, have
the library connected in a functionnal style to a database and have multiple
other connections openned through the OO interface (with C<new>).

As stated above, this function accepts an optional hash reference as its last
argument. Note, however, that the option in this hash will be in effect only for
the duration of the C<connect> call, while options passed as the last argument of
the constructors (C<new> and C<new_no_connect>) remain in effect until they are
modified. This is true even if C<connect> is called to create a default connection
for the library. You should use C<set_options> to set options permanently for the
default database handle (or any other handle after its creation).

This function will return a I<true> value if the connection succeed and will die
or return C<undef> otherwise (depending on the C<die_on_error> option). Not that
in strict mode it is an error to try to connect a handle which is already connected
to a database.

=head2 disconnect

  disconnect();

This function disconnect the default handle of the library from its current
connection. You can later on reconnect the library to an other database (or to
the same) with the C<connect> function.

  $h->disconnect();

This function disconnect the handle it is applied on from its database. Note that
the handle itself is not destroyed and can be reused later on with the C<connect>
method.

=head2 is_connected

  my $v = is_connected();
  my $v = $h->is_connected();

This call returns whether the default handle of the library and/or a given handle
is currently connected to a database.

This function does not actually check the connection to the database. So it is
possible that this call returns I<true> but that a later call to a function
which does access the database will fail if, e.g., you have lost your network
connection.

=head2 get_default_handle

  my $h = get_default_handle();

Return the default handle of the library (the one used by all function when not
applied on an object). The returned handle is an C<SQL::Exec> object and may
then be used as any other handles through the OO interface, but it will still be
used by the functionnal interface of this library.

=head2 get_dbh

  my $dbh = get_dbh();
  my $dbh = $h->get_dbh();

Returns the internal C<L<DBI>> handle to your database. This handle may be used
in conjonction with other libraries which can accept a connected handle.

Note that, because of the use of C<DBIx::Connector>, this handle may change
during the life of your program. If possible, you should rather use the
C<get_conn> method (see below) to get a persistant handle.

=head2 get_conn

  my $conn = get_conn();
  my $conn = $h->get_conn();

Returns the internal C<L<DBIx::Connector>> handle to your database. This handle
may be used in conjonction with other libraries which can accept such a handle
(e.g. C<L<DBIx::Lite>>). This handle will not change while you do not close your
connection to your database.

=head2 errstr

  my $e = errstr();
  my $e = $c->errstr;

This function returns an error string associated with the last call to the library
made with a given handle (or with the default handle). This function will return
C<undef> if the last call did not raise an error.

=head2 warnstr

  my $e = warnstr();
  my $e = $c->warnstr;

This function returns a warning string associated with the last call to the library
made with a given handle (or with the default handle). This function will return
C<undef> if the last call did not raise a warning.

Note that a single call way raise multiple warning. In that case, only the last
one will we stored in this variable.

=head2 set_options

  set_options(HASH);
  $c->set_options(HASH);

This function sets the option of the given connection handle (or of the default
handle). The C<HASH> describing the option may be given as a list of C<<option => value>>
or as a reference to a hash.

The function returns a hash with the previous value of all modified
options. As a special case, if the function is called without argument, it will
returns a hash with the value of all the options. In both cases, this hash is
returned as a list in list context and as a hash reference in scalar context.

If an error happen (e.g. use of an invalid value for an option) the function
returns undef or an empty list and nothing is modified. In C<strict> mode it is
also an error to try to set an nonexistant option.

If the options that you are setting include the C<strict> option, the value of
the C<strict> mode is not defined during the execution of this function (that is,
it may either be I<true> or I<false>).

See below for a list of the available options.

=head2 Options

You will find below a list of the currently available options. Each of these options
may be accessed through its dedicated function or with either of the C<set_option>/C<set_options>
functions.

=head3 die_on_error

  set_options(die_on_error => val);
  die_on_error(val);

This option (which default to I<true>) specify if an error condition abort the
execution of your program or not. If so, the C<croak> function will be called
(and you may trap the error with C<eval>). If not, the function call will still
abort and return C<undef> or an empty list (depending on the context). When this
may be a valid result for the function, you may call the C<L<errstr|/"errstr">> function/method
to get the last error message or C<undef> if the last call was succesful.

=head3 print_error

  set_options(print_error => val);
  print_error(val);

This option (which default to I<true>) control whether the errors are printed or
not (this does not depend on the setting of the C<die_on_error> option). If the
supplied value is I<true> the errors are printed to C<STDERR>, otherwise nothing
is printed.

=head3 print_warning

  set_options(print_warning => val);
  print_warning(val);

This option (which default to I<true>) control whether the warning are printed
or not. If the supplied value is I<true> the warnings are printed to C<STDERR>,
otherwise nothing is printed.

=head3 print_query

  set_options(print_query => FH);
  print_query(FH);

This option (which default to C<undef>) control whether the queries are printed
before being executed. Unless the previous option, to set it, you must pass it
an open I<file handle>. The queries will then be printed to this handle.

=head3 strict

  set_options(strict => val);
  strict(val);

This option (which default to I<true>) control the so-called C<strict> mode of
the library. It has 3 possible settings. If set to a I<true> value, some condition
are checked to ensure that the operations of the library are as safe as possible
(the exact condition are described in the documentation of the function to which
they apply). When the condition are not met, an error is thrown (what happens
exactly depends on the C<die_on_error> and C<print_error> options).

If this option is set to a I<defined> I<false> value (such as C<'0'>), then the
strict conditions are still tested, but only result in a warning when they are
not met.

Finally, if this option is set to C<undef> then the nothing happens when a strict
condition is not met (and the tests will altogether be omitted if they are
potentially costly).

=head3 replace

  set_option(replace => \&code);
  replace(\&code);
  replace($obj);
  replace(HASH);
  replace(undef);

This option allows to set up a procedure which get the possibility to modify
an SQL query before it is executed (e.g. to replace generic parameter by specific
name). The default (when the option is C<undef>) is that nothing is done.

If this option is a I<CODE> reference (or an anonymous sub-function), then this
function is called each time you supply an SQL query to this library with the
query in the C<$_> variable. The function may modify this variable and the
resulting value of C<$_> is executed. The call to this function takes place before
the spliting of the SQL query (if C<auto_split> is I<true>).

You may also pass to this option a I<HASH> reference. In that case, the hash
describes a series of replacement to be performed on the SQL query (see the
example below). Internally, this requires the C<L<String::Replace>> library.
The function will croak if you call it with a I<HASH> and you do not have this
library installed. When using the C<replace> function (rather than the
C<set_options> function) you may give a list descibing a I<HASH>, rather than a
I<HASH> reference.

Finally, you may also give to this function any object which have a C<replace>
method (e.g. an already built C<String::Replace> object). This method will then
be called with your SQL queries (using arguments and return values, and not the
C<$_> variable).

Here is an example (which will work with an SQLite database):

  replace(String::Replace->new(table_name => 't'));
  execute('create table table_name (a)');
  replace(table_name => 't');
  execute('insert into table_name values (1)');
  query_one_value('select * from table_name', { replace => sub { s/table_name/t/g } }) == 1

=head3 connect_options

Do not use this option...

=head3 auto_split

This option (which default to I<true>) controls whether the queries are split in
atomic statement before being sent to the database. If it is not set, your
queries will be sent I<as-is> to the database, with their ending terminator (if
any), this may result in error with some database driver which do not allow for
multi-statement queries. You should not set this option to a I<false> value
unless you know what you are doing.

The spliting facility is provided by the C<SQL::SplitStatement> package.

=head3 auto_transaction

  set_options(auto_transaction => val);
  auto_transaction(val);

This option (which default to I<true>) controls whether the C<execute> and
C<execute_multiple> functions automatically start a transaction whenever they
execute more than one statement.

=head3 use_connector

Do not use this option...

=head3 stop_on_error

  set_options(stop_on_error => val);
  stop_on_error(val);

This option is only usefull when the C<die_on_error> and C<strict_error> options
are false and will control if the execution is interupted when an error occurs
during a multi-statement query. Its default value is I<true>.

=head3 line_separator

  set_options(line_separator => val);
  line_separator(val);

This option is used only by the C<query_to_file> function. It specifies the
line separator used between different records. The default value is C<"\n">.

=head3 value_separator

  set_options(value_separator => val);
  line_separator(val);

This option is used only by the C<query_to_file> function. It specifies the
value separator used between different value of a records. The default value is
C<';'>.

=cut

push @EXPORT_OK, ('connect', 'disconnect', 'is_connected', 'get_default_handle',
	'get_dbh', 'get_conn',
	'errstr', 'set_options', 'set_option', 'die_on_error', 'print_error',
	'print_warning', 'print_query', 'strict', 'replace', 'connect_options',
	'auto_transaction', 'auto_split', 'use_connector', 'stop_on_error',
	'line_separator', 'value_separator');

# contrairement à new, connect met des options temporaire. bien ?
sub connect {
	my $c = &check_options or return;
	return $c->__connect(@_);
}

sub disconnect {
	my $c = &check_options or return;
	return $c->__disconnect(@_);
}

sub is_connected {
	my $c = &check_options or return;
	return $c->{is_connected};
}

sub get_default_handle {
	return just_get_handle();
}

sub get_dbh {
	my $c = &just_get_handle;
	return $c->{db_con}->dbh();
}

sub get_conn {
	my $c = &just_get_handle;
	return $c->{db_con};
}

# renvoie la dernière erreur et undef si le dernier appel a réussi.
sub errstr {
	my $c = &just_get_handle;
	return $c->{errstr};
}

sub die_on_error {
	my $c = &get_handle;
	return $c->__set_boolean_opt('die_on_error', @_);
}

sub print_error {
	my $c = &get_handle;
	return $c->__set_boolean_opt('print_error', @_);
}

sub print_warning {
	my $c = &get_handle;
	return $c->__set_boolean_opt('print_warning', @_);
}



# undef si l'argument est invalide, 0 sinon (pour les autres fonctions, il n'y a pas d'argument invalide).
sub print_query {
	my $c = &get_handle;

	$c->__restore_options();
	my $r = $c->{options}{print_query};

	if (@_) {
		if (not $_[0]) {
			$c->{options}{print_query} = 0;
		} elsif (openhandle($_[0])) {
			$c->{options}{print_query} = $_[0];
		} else {
			return $c->error('Invalid file handle as argument to print_query');
		}
	}

	return $r;
}

sub strict {
	my $c = &get_handle;
	return $c->__set_boolean_opt('strict', @_);
}

sub replace {
	my $c = &get_handle;

	$c->__restore_options();
	my $r = $c->{options}{replace};

	if (@_) {
		if (not $_[0]) {
			$c->{options}{replace} = undef;
		} elsif ((reftype($_[0]) // '') eq 'CODE') {
			$c->{options}{replace} = $_[0];
		} elsif (blessed($_[0]) and $_[0]->can('replace')) {
			$c->{options}{replace} = $_[0];
		} elsif ((reftype($_[0]) // '') eq 'HASH') {
			if (eval { require String::Replace }) {
				my $v = eval { String::Replace->new($_[0]) };
				return $c->error("Creating a String::Replace object has failed: $@") if $@;
				$c->{options}{replace} = $v;
			} else {
				return $c->error('The String::Replace module is needed to handle HASH ref as argument to replace');
			}
		} elsif (not ref $_[0] and not @_ & 1) {
			if (eval { require String::Replace }) {
				my $v = eval { String::Replace->new(@_) };
				return $c->error("Creating a String::Replace object has failed: $@") if $@;
				$c->{options}{replace} = $v;
			} else {
				return $c->error('The String::Replace module is needed to handle HASH ref as argument to replace');
			}		
		} else {
			return $c->error('Invalid argument to replace, expexted an object or HASH or CODE ref');
		}
	}

	return $r // 0;	# //
}

# idem que print_query
sub connect_options {
	my $c = &get_handle;

	$c->__restore_options();
	my $r = $c->{options}{connect_options};

	if (@_) {
		if (not $_[0]) {
			$c->{options}{connect_options} = undef;
		} elsif ((reftype($_[0]) // '') eq 'HASH') { # //
			$c->{options}{connect_options} = $_[0];
		} else {
			return $c->error('Invalid argument to connect_options, expexted a HASH ref');
		}
	}

	return $r // 0; #//
}

sub auto_transaction {
	my $c = &get_handle;
	return $c->__set_boolean_opt('auto_transaction', @_);
}

sub auto_split {
	my $c = &get_handle;
	return $c->__set_boolean_opt('auto_split', @_);
}

sub use_connector {
	my $c = &get_handle;
	return $c->error('The use_connector option cannot be changed when connected to a DB') if @_ && $c->{is_connected};
	return $c->__set_boolean_opt('use_connector', @_);
}

sub stop_on_error {
	my $c = &get_handle;
	return $c->__set_boolean_opt('stop_on_error', @_);
}

sub line_separator {
	my $c = &get_handle;
	return $c->__set_opt('line_separator', @_);
}

sub value_separator {
	my $c = &get_handle;
	return $c->__set_opt('value_separator', @_);
}

# Il faut que si on recoit \{} en argument alors on renvoie
# un restore option vide (mais pas toutes les options) car
# c'est ce qu'attend check_option.
#
# le hash restore_options est rempli dans check_options, important, sinon
# on le vide dans chaque appel aux petites fonctions d'option.
#
# la gestion en cas d'erreur est un peu complexe...
sub set_options {
	my $c = &get_handle;

	$c->__restore_options();

	if (not @_) {
		return wantarray ? %{$c->{options}} : { %{$c->{options}} };
	}
	my %h;
	if (ref $_[0] && ref $_[0] ne "HASH") {
		return error("Invalid argument in %s::set_options", ref $c);
	} elsif (ref $_[0]) {
		%h = %{$_[0]};
	} else {
		%h = @_;
	}
	my %old = ();
	
	#TODO: test this
	$c->{restore_options} = { %{$c->{options}} };

	while (my ($k, $v) = each %h) {
		given($k) {
			when('die_on_error') { $old{$k} = $c->die_on_error($v) }
			when('print_error') { $old{$k} = $c->print_error($v) }
			when('print_warning') { $old{$k} = $c->print_warning($v) }
			when('print_query') {
					my $r = $c->print_query($v);
					$c->strict_error('Some option has not been set due to ignored errors') and return if not defined $r;
					$old{$k} = $r
				}
			when('strict') { $old{$k} = $c->strict($v) }
			when('replace') {
					my $r = $c->replace($v);
					$c->strict_error('Some option has not been set due to ignored errors') and return if not defined $r;
					$old{$k} = $r
				}
			when('connect_options') {
					my $r = $c->connect_options($v);
					$c->strict_error('Some option has not been set due to ignored errors') and return if not defined $r;
					$old{$k} = $r
				}
			when('auto_transaction') { $old{$k} = $c->auto_transaction($v) }
			when('auto_split') { $old{$k} = $c->auto_split($v) }
			when('use_connector') { $old{$k} = $c->use_connector($v) }
			when('stop_on_error') { $old{$k} = $c->stop_on_error($v) }
			when('line_separator') { $old{$k} = $c->line_separator($v) }
			when('value_separator') { $old{$k} = $c->value_separator($v) }
			default { $c->strict_error("No such option: $k") and return }
		}
	}

	$c->{restore_options} = { };

	return wantarray ? %old : \%old;
}


=for comment

sub set_option { 
	my $c = &get_handle;

	return $c->set_options({$_[0] => $_[1]}) if @_ == 2;
	
	$c->error("Bad number of arguments in %s::set_option", ref $c);
	return;
}

=cut




################################################################################
################################################################################
##                                                                            ##
##                          STANDARD QUERY FUNCTIONS                          ##
##                                                                            ##
################################################################################
################################################################################


=head1 STANDARD QUERY FUNCTIONS

=head2 execute

  execute(SQL);
  $c->execute(SQL);

This function execute the SQL code contained in its argument. The SQL is first
split at the boundary of each statement that it contains (except if the C<auto_split>
option is false) and is then executed statement by statement in a single transaction
(meaning that if one of the statement fails, nothing is changed in your database).
If the C<auto_transaction> option is false, each of your statement will be executed
atomically and all modification will be recorded immediately.

Optionnaly, you may also provide a reference to an array of SQL queries instead
of a single SQL query. In that case, each query will be split independently (if
C<auto_split> is true) and all the resulting queries will be executed in order
inside one single transaction (if C<auto_transaction> is true). Note that you
may not pass a list of SQL query, but only a reference to such a list (for
compatibility with a future version of the library).

The function will return a C<defined> value if everything succeeded, and C<undef>
if an error happen (and it is ignored, otherwise, the function will C<croak>).

The returned value may or may not be the total number of lines modified by your
query.

Here are examples of valid call to the C<execute> function:

  execute('insert into t values (1)');
  execute('insert into t values (1);insert into t values (1)');
  execute(['insert into t values (1)', 'insert into t values (1)']);

=head2 execute_multiple

  execute_multiple(SQL, PARAM_LIST);
  $c->execute_multiple(SQL, PARAM_LIST);

This function executes one or multiple time an SQL query with the provided
parameters. The SQL query may be only a single statement (although this
condition is not tested if C<auto_split> is false, but then there is no
garantee on what will happen).

The SQL query can contain placeholder (C<'?'> characters) in place of SQL values.
These placeholder will be replaced during the execution by the parameters that
you provide. You should provide a list of parameters with the same number of
parameters than the number of placeholder in the statement. You may provide this
list as an array or an array reference.

You may also provide a list of array reference or a reference to an array of
array reference. In that case, the query will be executed once for each element
of this array (the external one), with the placeholders taking the values given
in the sub-arrays.

As a special case, if there is only a single placeholder in your query, you may
provide a simple list of parameters to execute the query multiple time (each
with one of the parameter).

If the C<auto_transaction> option is true, then all the executions of your query
will be performed atomically inside a single transaction. This is usefull for
example to performs many insertions in a table in an efficient manner.

Here are three pairs of equivalent call to C<execute_multiple>:

  execute_multiple('insert into t values (?, ?)', 1, 2);
  execute_multiple('insert into t values (?, ?)', [1, 2]);
  
  execute_multiple('insert into t values (?, ?)', [1, 2], [3, 4]);
  execute_multiple('insert into t values (?, ?)', [[1, 2], [3, 4]]);
  
  execute_multiple('insert into t values (?)', 1, 2, 3);
  execute_multiple('insert into t values (?)', [[1], [2], [3]]);

=head2 query_one_value

  my $v = query_one_value(SQL, LIST);
  my $v = $h->query_one_value(SQL, LIST);

This function return one scalar value corresponding to the result of the SQL query
provided. This query must be a data returning query (e.g. C<SELECT>).

If C<auto_split> is activated, the SQL query provided to this function may
not contains more than one statement (otherwise an error is thrown). If the
option is not set, this condition will not be tested and there is no guarantee
on what will happens if you try to execute more than one statement with this function.

If the SQL statement has parameter placeholders, they should be provided in the
arguments list of the call. As this function expects a single statement, the parameters
should be passed directly as a list and not in an array-ref.

  query_one_value('select a, b from table where a = ?', 42);

The function will raise an error if nothing is returned by your query (even if
the SQL code itself is valid) and, if in C<strict> mode, the function will also
fail if your query returns more than one line or one column (but note that the
query is still executed).

In case of an error (and if C<die_on_error> is not set) the function will return
C<undef>. You must not that this value may also be returned if your query returns
a C<NULL> value. In that case to check if an error happened you must check the
C<errstr> function which will return C<undef> if there was no errors.

=head2 query_one_line

  my @l = query_one_line(SQL,LIST);
  my @l = $h->query_one_line(SQL,LIST);
  my $l = query_one_line(SQL,LIST);
  my $l = $h->query_one_line(SQL,LIST);

This function returns a list corresponding to one line of result of the provided
SQL query. If called in scalar context, the function will return a reference to an
array rather than a list. You may safely store this array which will not be reused
by the library.

In list context, the function will return an empty list in case of an error. You
may distinguish this from a query returning no columns with the C<errstr> function.
In scalar context, the function will return C<undef> in case of error or a reference
to an empty array for query returning no columns.

An error will happen if the query returns no rows at all and, if you are in
C<strict> mode, an error will also happen if the query returns more than one rows.

The same limitation applies to this function as for the C<query_one_line> about
the number of statement in your query and the parameter for the statement placeholders.

=head2 query_all_lines

  my @a = query_all_lines(SQL,LIST);
  my @a = $h->query_all_lines(SQL,LIST);
  my $a = query_all_lines(SQL,LIST);
  my $a = $h->query_all_lines(SQL,LIST);

This function executes the given SQL and returns all the returned data from this
query. In list context, the fonction returns a list of all the lines. Each lines
is a reference to an array, even if there is only one column per lines (use the 
query_one_column function for that). In scalar context, the function returns a
reference to an array containing each of the array reference for each lines.

In case of errors, if C<die_on_error> is not set, the function will return C<undef>
in scalar context and an empty list in list context. This could also be the correct
result of a query returning no rows, use the C<errstr> function to distinguish
between these two cases.

If there is an error during the fetching of the data and that C<die_on_error> is
not set and you are not in C<strict> mode, then all the data already fetched will
be returned but no tentatives will be done to try to fetch any more data.

The same limitation applies to this function as for the C<query_one_line> about
the number of statement in your query and the parameter for the statement placeholders.

=head2 query_one_column

  my @l = query_one_column(SQL,LIST);
  my @l = $h->query_one_column(SQL,LIST);
  my $l = query_one_column(SQL,LIST);
  my $l = $h->query_one_column(SQL,LIST);

This function returns a list corresponding to one column of result of the provided
SQL query. If called in scalar context, the function will return a reference to an
array rather than a list. You may safely store this array which will not be reused
by the library.

In list context, the function will return an empty list in case of an error. You
may distinguish this from a query returning no lines with the C<errstr> function.
In scalar context, the function will return C<undef> in case of error or a reference
to an empty array for query returning no lines.

An error will happen if the query returns no columns at all and, if you are in
C<strict> mode, an error will also happen if the query returns more than one columns.

The same limitation applies to this function as for the C<query_one_line> about
the number of statement in your query and the parameter for the statement placeholders.

=head2 query_to_file

  query_to_file(SQL, file_name, LIST);
  my $v = $h->query_one_value(SQL, file_name, LIST);
  query_to_file(SQL, FH, LIST);

This function execute an SQL query and send its output to a file or file handle.

The first argument is the query to execute (which may contain only a single
statement).

The second argument is the destination of the data. You may pass either a file name
or a reference to an I<IO> or I<GLOB>. If it is omitted or C<undef> the data will
go to C<STDOUT>. If you pass a filename, you may prefix it with C<<<'>>'>>> to append
to the file (rather that to erase it).

B<Changed in 0.09:> The data are written with each value of a raw separated by the value of the
C<value_separator> option (which defaults to C<';'>) and each row separated by
the value of the C<line_separator> option (which defaults to C<"\n">).

The same limitation applies to this function as for the C<query_one_line> about
the number of statement in your query and the parameter for the statement placeholders.

=head2 query_one_hash

  my %h = query_one_hash(SQL,LIST);
  my %h = $h->query_one_hash(SQL,LIST);
  my $h = query_one_hash(SQL,LIST);
  my $h = $h->query_one_hash(SQL,LIST);


=head2 query_all_hashes

  my @h = query_all_hashes(SQL,LIST);
  my @h = $h->query_all_hashes(SQL,LIST);
  my $h = query_all_hashes(SQL,LIST);
  my $h = $h->query_all_hashes(SQL,LIST);

=cut

push @EXPORT_OK, ('execute', 'query_one_value', 'query_one_line', 'query_all_lines',
				'query_one_column', 'query_to_file', 'execute_multiple',
				'query_one_hash', 'query_all_hashes');

# Cette fonction ci est la seule que l'on ne passe pas à Statement car elle
# manipule plusieurs statements qui doivent être exécuté au sein d'une seule
# transaction.
# On pourrait la réécrire en créant plein de Statement mais ça semble non optimale.
sub execute {
	my $c = &check_options or return;

	$c->check_conn() or return;
	my @queries;
	if ($_[0] and ref $_[0] and reftype $_[0] eq 'ARRAY') {
		@queries = map { $c->__split_query($_) } @{$_[0]};
	} else {
		@queries = $c->__split_query($_[0]);
	}
	
	my $proc = sub {
			my $a = 0;

			for my $r (@queries) {
			# TODO: lever l'erreur strict seulement dans le mode stop_on_error
			# et s'il reste des requête à exécuter.
				if (!$c->SQL::Exec::Statement::low_level_prepare($r)) {
					$c->strict_error("Some queries have not been executed due to an error") and die "EINT\n";
					die "ESTOP:$a\n" if $c->{options}{stop_on_error};
					next;
				}
				my $v = $c->SQL::Exec::Statement::low_level_execute();
				$c->SQL::Exec::Statement::low_level_finish();
				if (not defined $v) {
					$c->strict_error("Some queries have not been executed due to an error") and die "EINT\n";
					die "ESTOP:$a\n" if $c->{options}{stop_on_error};
					next;
				}
				$a += $v;
			}
			return $a;
		};

	my $v;
	if ($c->{options}{auto_transaction} && @queries > 1) {
		$v = eval { $c->{db_con}->txn($proc) };
	} else {
		$v = eval { $proc->() };
	}
	if ($@ =~ m/^EINT$/) {
		return;
	} elsif ($@ =~ m/^ESTOP:(\d+)$/) {
		return $c->{options}{auto_transaction} && @queries > 1 ? 0 : $1;
	} elsif ($@) {
		die $@;
	} else {
		return $v;
	}
}

sub __execute_multiple {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req) or return;
	return $c->{last_stmt}->__execute(@params);
}

sub execute_multiple {
	my $c = &check_options or return;
	return $c->__execute_multiple(@_);
}

sub __query_one_value {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req) or return;
	return $c->{last_stmt}->__query_one_value(@params);
}

sub query_one_value {
	my $c = &check_options or return;
	return $c->__query_one_value(@_);
}

sub __query_one_line {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_one_line(@params);
}

sub query_one_line {
	my $c = &check_options or return;
	return $c->__query_one_line(@_);
}

sub __query_all_lines {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_all_lines(@params);
}

sub query_all_lines {
	my $c = &check_options or return;
	return $c->__query_all_lines(@_);
}

sub __query_one_column {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_one_column(@params);
}

sub query_one_column {
	my $c = &check_options or return;
	return $c->__query_one_column(@_);
}

sub __query_to_file {
	my ($c, $req, $fh, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_to_file($fh, @params);
}

sub query_to_file {
	my $c = &check_options or return;
	return $c->__query_to_file(@_);
}

sub __query_one_hash {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_one_hash(@params);
}

sub query_one_hash {
	my $c = &check_options or return;
	return $c->__query_one_hash(@_);
}

sub __query_all_hashes {
	my ($c, $req, @params) = @_;
	$c->{last_stmt} = $c->__prepare($req);
	return $c->{last_stmt}->__query_all_hashes(@params);
}

sub query_all_hashes {
	my $c = &check_options or return;
	return $c->__query_all_hashes(@_);
}



################################################################################
################################################################################
##                                                                            ##
##                       PREPARED STATEMENTS FUNCTIONS                        ##
##                                                                            ##
################################################################################
################################################################################

=head1 PREPARED STATEMENTS

The library offers full support for prepared statements which can be executed
multiple times with different parameters.

=head2 prepare

  $st = prepare(SQL);
  $st = $h->prepare(SQL);

All L<standard query functions|/STANDARD QUERY FUNCTIONS> are accessible through
prepared statements, except that the C<execute> function behave exactly like the
C<execute_multiple> function. Users are encouraged to use the C<execute> name when
manipulating prepared statement.


=head2 Using a prepared statement

  $st->execute(LIST);
  $st->query_one_value(LIST);
  $st->query_one_line(LIST);
  $st->query_all_lines(LIST);
  $st->query_one_column(LIST);
  $st->query_to_file(FH, LIST);
  $st->query_to_file(filename, LIST);
  $st->query_one_hash(LIST);
  $st->query_all_hashes(LIST);


=cut

push @EXPORT_OK, ('prepare');

sub __prepare {
	my ($c, @p) = @_ or return;
	return SQL::Exec::Statement->new($c, @p);
}

sub prepare {
	my $c = &check_options or return;
	return SQL::Exec::Statement->new($c, @_);
}

################################################################################
################################################################################
##                                                                            ##
##                         HIGH LEVEL QUERY FUNCTIONS                         ##
##                                                                            ##
################################################################################
################################################################################


=head1 HIGH LEVEL QUERY FUNCTIONS

These functions (or method) provide higher level interface to the database. The implemetations
provided here try to be generic and portable but they may not work with any database
driver. If necessary, these functions will be overidden in the database specific
sub-classes. Be sure to check the documentation for the sub-classe that you are
using (if any) because the arguments of these function may differ from their base
version.

=head2 count_lines

  my $n = count_lines(SQL);
  my $n = $c->count_lines(SQL);

This function takes an SQL query (C<SELECT>-like), executes it and return the
number of lines that the query would have returned (with, e.g., the C<query_all_lines>
functions).

=head2 table_exists

  my $b = table_exists(table_name);
  my $b = $c->table_exists(table_name);

This function returns a boolean value indicating if there is a table with name
C<table_name>. The default implementation may erroneously returns I<false> if the
table exists but you do not have enough rights to access it.

This function might also returns I<true> when there is an object with the correct
name looking I<like> a table (e.g. a view) in the database.

=head2 get_columns

  my @c = get_columns(table_name);
  my $c = $c->get_columns(table_name);

=head2 get_primary_key

  my @c = get_primary_key(table_name);
  my $c = $c->get_primary_key(table_name);


=cut

push @EXPORT_OK, ('count_lines', 'table_exists', 'get_columns', 'get_primary_key');


sub __count_lines {
	my ($c, $req) = @_;

	$req = $c->get_one_query($req) or return;

#	return $c->__query_one_value("SELECT count(*) from (${req}) T_ANY_NAME");
	
	my $proc = sub {
			my $c = $c->__query_one_value("SELECT count(*) from (${req}) T_ANY_NAME");
			if (defined $c) {
				die "EGET:$c\n";
			} else {
				die "EINT\n";
			}
		};

#	my $v = eval { $c->{db_con}->txn($proc) };
	my $v = eval { $proc->() }; # la "transaction" est ouverte dans __query_one_value

	if ($@ =~ m/^EINT$/) {
		return;
	} elsif ($@ =~ m/^EGET:(\d+)$/) {
		return $1;
	} elsif ($@) {
		die $@;
	} else {
		confess 'Should not happen';
	}
}

sub count_lines {
	my $c = &check_options;
	$c->check_conn() or return;

	return $c->__count_lines(@_);
}

sub __quote_identifier {
	my ($c, @args) = @_;
	# les '' deviennent undef c'est ce qu'on veut ?
	@args = map { $_ ? split /\./, $_ : undef } @args;
	unshift @args, ((undef) x (3 - @args));
	my $table = eval { $c->get_dbh()->quote_identifier(@args) };
	if ($table) {
		return $table;
	} else {
		return join '.', grep { $_ } @args;
	}
}

# test aussi le droit en lecture, très mauvaise implémentation...
sub __table_exists_dummy {
	my ($c, @args) = @_;

	my $table = $c->__quote_identifier(@args);

	eval {
			$c->__prepare("select * from $table") or die "FAIL\n";
			1;
		};

	if ($@) { # pas que dans le cas FAIL, mais aussi les autres erreurs de la bibliothèque
		return 0;
	} else {
		return 1;
	}
}

# If a subclasses knows that the default implementation won't work, it can
# redefine the table_exists function to directly alias to __table_exists_dummy
# Beware that in this case, the check_options, check_conn and replace will need
# to be performed by the proxy function.
sub table_exists {
	my $c = &check_options;
	$c->check_conn() or return;

	my (@args) = @_;

	my $esc = eval {
			$c->get_dbh()->get_info($GetInfoType{SQL_SEARCH_PATTERN_ESCAPE})
		}  // '\\'; # /

	for (@args) {
		if ($_) {
			$_ = $c->__replace($_);
			# See Caveat in http://search.cpan.org/dist/DBI/DBI.pm#Catalog_Methods
			$_ =~ s/([_%])/$esc$1/g;
		}
	}

	@args = map { $_ ? split /\./, $_ : $_ } @args; # à faire après le __replace

	$c->query("[SQL::Exec] Table Exists: ".(join '.', grep { $_ } @args));

	$c->error('Too many arguments') if @args > 3;
	$c->error('Not enough arguments') if @args < 1;
	unshift @args, ((undef) x (3 - @args));
	
	my @t = eval {
			$c->get_dbh()->tables(@args, 'TABLE,VIEW');
		};

	if ($@) {
		$c->warning("Operation not supported by your driver");
		return $c->__table_exists_dummy(@args);
	} elsif (@t == 1) {
		return 1;
	} else {
		return 0;
	}
}

sub __get_columns_dummy {
	my ($c, @args) = @_;

	my $table = $c->__quote_identifier(@args);

	my $st = eval {
			$c->__prepare("select * from $table") or die "FAIL\n";
		};

	if ($@) {
		$c->error("unknown error, are you sure that the table '$table' exists ?");
		return;
	} else {
		my @c = @{$st->{last_req}->{NAME_lc}};
		return wantarray ? @c : \@c;
	}
}

# If a subclasses knows that the default implementation won't work, it can
# redefine the table_exists function to directly alias to __get_columns_dummy
sub get_columns {
	my $c = &check_options;
	$c->check_conn() or return;

	my (@args) = @_;

	my $esc = eval {
			$c->get_dbh()->get_info($GetInfoType{SQL_SEARCH_PATTERN_ESCAPE})
		}  // '\\'; # /

	for (@args) {
		if ($_) {
			$_ = $c->__replace($_);
			# See Caveat in http://search.cpan.org/dist/DBI/DBI.pm#Catalog_Methods
			$_ =~ s/([_%])/$esc$1/g;
		}
	}

	@args = map { $_ ? split /\./, $_ : $_ } @args; # à faire après le __replace

	$c->query("[SQL::Exec] Get Columns: ".(join '.', grep { $_ } @args));

	$c->error('Too many arguments') if @args > 3;
	$c->error('Not enough arguments') if @args < 1;
	unshift @args, ((undef) x (3 - @args));
	
	my @c = eval {
			my $sth = $c->get_dbh()->column_info(@args, undef);
			my $ref = $sth->fetchall_arrayref();
			map { lc $_->[3] } @{$ref};
		};

	if ($@) {
		$c->warning("Operation not supported by your driver");
		return $c->__table_exists_dummy(@args);
	} elsif (@c) {
		return wantarray ? @c : \@c;
	} else {
		my $table = join '.', grep { defined $_ } @args;
		$c->error("unknown error, are you sure that the table '$table' exists ?");
		return;
	}
}


sub get_primary_key {
	my $c = &check_options;
	$c->check_conn() or return;

	my (@args) = @_;

	my $esc = eval {
			$c->get_dbh()->get_info($GetInfoType{SQL_SEARCH_PATTERN_ESCAPE})
		}  // '\\'; # /

	for (@args) {
		if ($_) {
			$_ = $c->__replace($_);
			# See Caveat in http://search.cpan.org/dist/DBI/DBI.pm#Catalog_Methods
			$_ =~ s/([_%])/$esc$1/g;
		}
	}

	@args = map { $_ ? split /\./, $_ : $_ } @args; # à faire après le __replace

	$c->query("[SQL::Exec] Get Primary Key: ".(join '.', grep { $_ } @args));

	$c->error('Too many arguments') if @args > 3;
	$c->error('Not enough arguments') if @args < 1;
	unshift @args, ((undef) x (3 - @args));
	
	my @pk = eval {
			map { lc } $c->get_dbh()->primary_key(@args);
		};

	if ($@) {
		$c->error("Operation not supported by your driver");
	} else {
		if (defined $c->{options}{strict} and not @pk) {
			if (not $c->table_exists(@_)) {
				$c->strict_error("Table does not exist") and return;
			}
		}
		return wantarray ? @pk : \@pk;
	}
}

################################################################################
################################################################################
##                                                                            ##
##                      STATEMENTS INFORMATION FUNCTIONS                      ##
##                                                                            ##
################################################################################
################################################################################


=head1 STATEMENTS INFORMATION FUNCTIONS

All the functions (or methods) below can be applied either to an SQL::Exec object
(or to the default object) in which case they will return informations about the
previous query that was executed, or they can be applied to a prepared statement
in which case they will return information about the statement currently prepared.

The only exception is that queries executed through the C<execute> function/method
will not count as the last query for these functions. This does not apply to the
C<execute> method of a prepared statement nor to the C<execute_multiple>
function/method.

=head2 num_of_params

  my $n = num_of_params();
  my $n = $c->num_of_params();
  my $n = $st->num_of_params();

Returns the number of 

=head2 num_of_fields

  my $n = num_of_fields();
  my $n = $c->num_of_fields();
  my $n = $st->num_of_fields();

=head2 get_fields

  my @f = get_fields();
  my $f = get_fields();
  my @f = $st->get_fields();
  my @f = $st->get_fields();

=cut

push @EXPORT_OK, ('num_of_params', 'num_of_fields', 'get_fields');

sub __get_statement {
	my ($c) = @_;

	if ($c->{is_statement}) {
		return $c->{last_req};
	} else {
		$c->error('No query have ever been prepared with this object') if not $c->{last_stmt};
		return $c->{last_stmt}->{last_req};
	}
}

sub num_of_params {
	my $c = &SQL::Exec::check_options or return;
	$c->check_conn() or return;

	my $stmt = $c->__get_statement();

	return $stmt->{NUM_OF_PARAMS};
}

sub num_of_fields {
	my $c = &SQL::Exec::check_options or return;
	$c->check_conn() or return;

	my $stmt = $c->__get_statement();

	return $stmt->{NUM_OF_FIELDS} // 0; # / some driver returns undef instead of 0
}

sub get_fields {
	my $c = &SQL::Exec::check_options or return;
	$c->check_conn() or return;

	my $stmt = $c->__get_statement();
	my @fields = @{$stmt->{NAME_lc}};
	
	return wantarray ? @fields : \@fields; # copy to have a clean rw array
}


=for comment

################################################################################
################################################################################
##                                                                            ##
##                         HIGH LEVEL HELPER FUNCTIONS                        ##
##                                                                            ##
################################################################################
################################################################################

push @EXPORT_OK, ('split_query');


# TODO : décider de la sémantique (renvoie des statements vides ?)
sub split_query {
	my ($str) = @_;
	return grep { $sql_split_grepper->split($_) } $sql_splitter->split($str);
}

=cut

$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

1;

=head1 SUB-CLASSING

The implementation of this library is as generic as possible. However some
specific functions can be better written for some specific database server and
some helper function can be easier to use if they are tuned for a single
database server.

This specific support is provided through sub-classse which extend both the OO
and the functionnal interface of this library. As stated above, if there is a
sub-classe for your specific database, you should use it instead of this module,
otherwise.

=head2 Sub-classes

The sub-classes currently existing are the following ones:

=over 4

=item * L<SQLite|SQL::Exec::SQLite>: the in-file or in memory database with L<DBD::SQLite>;

=item * L<Oracle|SQL::Exec::Oracle>: access to Oracle database server with L<DBD::Oracle>;

=item * L<ODBC|SQL::Exec::ODBC>: access to any ODBC enabled DBMS through L<DBD::ODBC>;

=item * L<Teradata|SQL::Exec::ODBC::Teradata>: access to a Teradata database with
the C<ODBC> driver (there is a C<DBD::Teradata> C<DBI> driver using the native
driver for this database (C<CLI>), but its latest version is not on CPAN, so I
recommend using the C<ODBC> interface).

=back

If your database of choice is not yet supported, let me know it and I will do my
best to add a module for it (if the DBMS is freely available) or help you add
this support (if I cannot have access to an instance of this database server).

In the meantime, C<SQL::Exec> should just work with your database. If that is
not the case, you should report this as a L<bug|/"BUGS">.

=head2 How to

...

=head1 EXAMPLES

Examples would be good.

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-exec@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Exec>.

=head1 SEE ALSO

At some point or another you will want to look at the L<DBI> documentation,
mother of all database manipulation in Perl. You may also want to look at the
L<DBIx::Connector> and L<SQL::SplitStatement> modules upon which SQL::Exec
is based.

There is several CPAN module similar to SQL::Exec, I list here only the
closest (e.g. which does not impose OO upon your code), you should have a look
at them before deciding to use SQL::Exec:
L<DBI::Simple>, L<DBIx::Simple>, L<DBIx::DWIW>, C<DBIx::Wrapper>,
L<DBIx::SimpleGoBetween>, L<DBIx::Sunny>, C<SQL::Executor>.

Also, SQL::Exec will try its best to enable you to run your SQL code
in a simple and efficiant way but it will not boil your coffee. You may be
interested in other packages which may be used to go beyond SQL::Exec
functionnalities, like L<SQL::Abstract>, L<DBIx::Lite>, and
L<SQL::Translator>.

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.10 (March 2013)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


