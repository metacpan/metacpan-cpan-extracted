=head1 NAME

SQL::Snippet - Conatraint-based OO Interface to RDBMS

=head1 SYNOPSIS

    use SQL::Snippet::ExampleRepository;

    my $snippet = SQL::Snippet::ExampleRepository->new( @args );

    # auto-instantiate the population and limit it
    $snippet->pop->pop_name->lim->new( 'lim_name' );

    # assign select clause
    $snippet->pop_name->select( $select_clause );

    # get sql statement suitable for handing off to DBI
    my $sql = $snippet->pop->pop_name->query;

=head1 DESCRIPTION

SQL::Snippet has two major benefits:

1) Ease of system maintenence:  all SQL is removed from individual perl scripts and boiled down into unique elements.  These elements are named after the real-world objects they represent and are stored in one central repository/module.  When SQL adjustments or additions are needed, all changes are made in this one central repository, instead of within many individual scripts.

2) Ease of data access:  In response to requests made in easy OO syntax, SQL::Snippet combines snippets from the repository on the fly to create canonical SQL.  Thus programmers need not be concerned about tables and joins and other RDBMS complexities when writing a scriptrequiring database interaction.  Further, creating ad-hoc drill-down reports for end users becomes a simple exercise.

=head1 PARADIGM

There are four elements to the paradigm that SQL::Snippet uses to enable easy interaction with your RDBMS.
  1.  pop     - Populations
  2.  lim     - Limits applicable to those populations
  3.  parm    - Parameters needed to flesh out the pops and
                lims
  4.  methods - each of the above three items has various
                built in methods associated with it.
                Additionally, objects and methods are
                automatically generated from the snippets
                in your Repository as needed.  (See below.)

=over 2

=item C<Populations>

Population objects are real world things that are represented in your RDBMS.  The following are example of objects you might find in your RDBMS:
  - people
  - suppliers
  - parts
  - assemblies
  - SKUs (Stock Keeping Units)

All of these are real world things.  Information about them in your RDBMS may be contained in one and only one table, or the information may be normalized (split) between many different tables.  In the latter case, the SQL necessary to query your object of interest could get rather complicated, necessarily including all of the relevant tables and joins.

SQL::Snippet abstracts the details of your RDBMS table structure into objects that you can simply reference in your scripts; SQL::Snippet will fill in all the details behind the scenes.  For example:

  # prints the canonical SQL statement needed to
  # query info about assemblies from your RDBMS
  print $snippet->pop->assemblies->query;

=item C<Limits>

Limits are types of real world attributes that can apply to the population objects.  For example, gender is a type of attribute applicable to people, but not to assemblies.  Weight is a type of attribute applicable to both people and assemblies.  By indicating a limit for a given population, you can sharpen the definition of that population.  For example:

  # apply the gender limit to our 'people' population
  $snippet->pop->people->lim->new( 'gender' );

Note that neither we nor the user of the script has yet specified what gender to limit the population by (Unknown, Female, etc.).  We have only indicated that the population should have a gender limit applied to it.  To complete the job we need to look at the next element of the SQL::Snippet paradigm.

=item C<Parameters>
Parameters are the actual attributes used by population limits.  In the above example we specified a gender limit, so now we should specify the gender parameter to be used by that limit.  The gender limit requires only one parameter, aptly named 'gender'.

  # limit the people population to those with gender
  # attribute of Female or Unknown
  $snippet->pop->people->lim->gender->parm->gender(
      ['U','F']
  );

Actually, we don't need to say:
  $snippet->pop->people->lim->new( 'gender' );

before saying:
  $snippet->pop->people->lim->gender->parm->gender(
      ['U','F']
  );

The gender limit is autoinstantiated in the latter example.  In fact, it's all autoinstantiated, from pop to gender.  You start your script with a simple snippet object, and the rest autoinstantiates as needed.

=item C<Methods>

In the above examples you see that pop, lim, and parm are autoinstantiated objects furnished by SQL::Snippet.  There are multiple methods associated with each one.  For example, we called the 'new' method on lim.  But note that most of the methods and objects we used were actually named by us, the *users* of SQL::Snippet, not by me, the guy who wrote SQL::Snippet.  For example, not only did we use the autoinstantiated 'gender' object, we also called the 'gender' method on parm (see the last example above).  Note that we, the users of SQL::Snippet did not have to actually code a 'gender' method somewhere -- far from it.  This method was AUTOLOADed for us.  All we had to do was create a repository with pop, lim, and parm snippets, and the rest was automatic.  For example, here is the 'gender' snippet from SQL::Snippet::ExampleRepository, an example repository included with the distribution:

  if ($parm eq 'gender') {
    return (
      name      =>  $parm,
      default   =>  '',
      msg       =>
          "By default, gender will bear no impact " .
          "on selection.  Press ENTER to accept this" .
          "default, or, to limit the selection by" .
          "gender, type one or more gender codes " .
          "from the following list:  M (Male), " .
          "F (Female), U (Unknown)",
      delimiter =>  ',',
      prompt    =>  'Gender',
      check     =>  [ 'M','F','U' ],
    );
  } elsif ($parm eq ...

When you reference 'gender' in your code, either as an object or method (as in the above examples), SQL::Snippet will automatically create the needed object or method using this snippet as a source of basic information.  If you can follow this easy pattern for creating snippets, you can use SQL::Snippet.  SQL::Snippet itself automatically creates the back end stuff needed to allow the use of intuitive OO syntax.

=back 2

=head1 EXAMPLES

EXAMPLE SCRIPT 1

  # specify the repository to be used.  The repository is
  # subclassed from SQL::Snippet.
  use SQL::Snippet::ExampleRepository;

  # If you don't specify the parm values needed to fill
  # out your pops and lims, the user will be prompted
  # automatically.  I use Term::Interact to enable this
  # in interaction in a command line environment.
  use Term::Interact;

  # We'll use DBI to execute the SQL we get from
  # SQL::Snippet.  Also, SQL::Snippet may use DBI to
  # validate user input (if you so specify in the
  # repository) and to quote parameters.
  use DBI;

  my $ti = Term::Interact->new;
  my $dbh = DBI->connect( ... );
  $ti->dbh( $dbh );
  my $snippet = SQL::Snippet::ExampleRepository->new(
      dbh    => $dbh,
      ui     => $ti,
      syntax => 'oracle'
  );


  ###EXAMPLE 1###

  # We need to specify what our SELECT statement will be.
  # A future version will allow prompting of the user to
  # build his own SELECT based on meta-data supplied by
  # the snippets.
  $snippet->pop->catalog_recipient->select(
    'SELECT count(*)'
  );

  # get the SQL necessary to pull a count of the catalog
  # recipient population out of your RDBMS.
  print $snippet->pop->catalog_recipient->query;


  ###EXAMPLE 2###

  # instead of grabbing the whole population of catalog
  # recipients, let's limit it to those who never placed
  # an order.
  $snippet->
    pop->catalog_recipient->
      lim->last_order->
        parm->last_order(
                'NULL'
              );

  # our SELECT is still set for this pop from above...
  print $snippet->pop->catalog_recipient->query;


  ###EXAMPLE 3###

  # instead of forcing a last_order limit, let's let
  # the user say whether or not he wants the limit,
  # and if so what sort of limit.  Possible inputs by
  # the user might be:
  #    '> 1/1/2001'       # with orders after 1/1/2001
  #       -or-
  #    'NULL'             # with no orders ever
  #       -or-
  #    ''                 # let's not limit, thank you

  # set the limit for this pop
  $snippet->pop->catalog_recipient->lim->new(
      'last_order'
  );

  # when generating the SQL, SQL::Snippet will notice we
  # have requested a 'last_order' limit, but no parm value
  # for 'last_order' has been set.  The user will be
  # prompted with whatever verbiage we have stored in the
  # repository, and their input will be parsed by whatever
  # logic we have in the repository.  (See perldoc
  # Term::Interact for the details of user prompting, and
  # the source for SQL::Snippet::ExampleRepository for
  # boilerplate and example Repository logic.
  print $snippet->pop->catalog_recipient->query;


EXAMPLE SCRIPT 2

  # This example script uses some more advanced
  # functionality.  See perldoc SQL::Snippet for full
  # documentation.

  use SQL::Snippet::ExampleRepository;
  use Term::Interact;
  use DBI;

  my $ti = Term::Interact->new;
  my $dbh = DBI->connect( ... );
  my $snippet = SQL::Snippet::ExampleRepository->new(
      dbh => $dbh,
      ui => $ti,
      syntax => 'oracle'
  );

  # all pops referenced from the current snippet will
  # automatically have the zip limit applied.
  $snippet->shared_lim->new( 'zip' );

  # Since all pops will share the zip lim, let's set
  # the zip parm value *once* the top level (instead
  # of once for each pop at the pop->lim->parm level).
  # Here, the value will be set via user interaction
  # since we have passed in no value and none has
  # been previously set.
  $snippet->parm->zip->value;

  $snippet->pop->pre_sale->select(
      'SELECT SKU, count(SKU)'
  );
  $snippet->pop->pre_sale->group_by( 'SKU' );
  $snippet->pop->pre_sale->order_by( 'count(SKU)' );

  $snippet->pop->sale->select(
      'SELECT SKU, count(SKU)'
  );
  $snippet->pop->sale->group_by( 'SKU' );
  $snippet->pop->sale->order_by( 'count(SKU)' );

  $snippet->pop->re_sale->select(
      'SELECT SKU, count(SKU)'
  );
  $snippet->pop->re_sale->group_by( 'SKU' );
  $snippet->pop->re_sale->order_by( 'count(SKU)' );

  my $pre_sale_hits_by_SKU = $dbh->selectall_arrayref(
      $snippet->pop->pre_sale->query
  );
  my $sales_by_SKU = $dbh->selectall_arrayref(
      $snippet->pop->sale->query
  );
  my $re_sales_by_SKU = $dbh->selectall_arrayref(
      $snippet->pop->re_sale->query
  );

  print       "                  ----SKU----  --COUNT--\n";
  print       "Pre-Sales Hits\n";
  for (@$pre_sale_hits_by_SKU) {
      print   "                  $_->[0]      $_->[1]\n";
  }
  print       "Sales\n";
  for (@$sales_by_SKU) {
      print   "                  $_->[0]      $_->[1]\n";
  }
  print       " Re-Sales\n";
  for (@$re_sales_by_SKU) {
      print   "                  $_->[0]      $_->[1]\n";
  }

  # print any notes the repository has associated with
  # limits placed on the whole report.
  print scalar($snippet->get_shared_lim_notes);

=head1 METHODS

=over 2

=head2 Snippet Methods

  # $snippet->method;

=over 2

=item C<new>

Snippet object constructor.  Accepts parameters via passed in key value pairs.  Ex:

  my $snippet = SQL::Snippet::ExampleRepository->new(
    dbh => $dbh,
    ui  => $ui,
  );

Parameters defaults at construction:
  interact => 1
  sql_syntax => 'Oracle'

=item C<interact>

Boolean parameter accessor/mutator (boolean):

  # set
  $snippet->interact( 0 );

  #get
  my $interact = $snippet->interact;

=item C<dbh>

Database handle parameter accessor/mutator:

  # set
  $snippet->dbh( $dbh );

  #get
  my $dbh = $snippet->dbh;

=item C<sql_syntax>

String parameter accessor/mutator:

  # set
  $snippet->sql_syntax( 'oracle' );

  #get
  my $sql_syntax = $snippet->sql_syntax;

=item C<ui>

User interface object parameter accessor/mutator:

  # set
  $snippet->ui( $ui );

  #get
  my $ui = $snippet->ui;

=item C<get_shared_lim_notes>

Accessor to retrieve the note parameters from any shared limits.

  # get notes in array form
  my @notes = $snippet->get_shared_lim_notes;

  # get notes pre-joined with "\n"
  my $notes = $snippet->get_shared_lim_notes;

=back 2

=head2 Pop Methods

  # $snippet->pop->method;

=over 2

=item C<new>

Constructs a new pop snippet.  Requires name of the pop snippet to be passed in.  Also accepts key=>value parameters (see pop snippet accessor/mutator methods for a list) that will override any defaults from the repository.

  $snippet->pop->new(
    $pop_name,
    select => 'SELECT foo',
  );

=item C<list>

Returns a list of those pop objects currently instantiated.

  my @pops = $snippet->pop->list;

=item C<remove>

Eliminates the specified pop object.

  $snippet->pop->remove( 'foo' );

=back 2

=head2 Pop Snippet Methods

  # $snippet->pop->pop_name->method;

=over 2

=item C<create_select>

[UNIMPLEMENTED]  Will prompt the user to construct a select statement using pop meta-information.

=item C<select>

string parameter accessor/mutator:

  # set
  $snippet->pop->foo->select( $sql );

  #get
  my $sql = $snippet->pop->foo->select;

=item C<selectable>

aref parameter accessor/mutator:

The 'selectable' parm value is a aref with meta-information about the snippet: what fields are selectable (and what are their aliases) because of the inclusion of this snippet.

  my @selectable = (
    'field_1',
    [ 'field_2' => 'filed_2_alias' ],
  )

  # set
  $snippet->pop->foo->selectable( \@selectable );

  #get
  my $selectable_aref = $snippet->pop->foo->selectable;

=item C<prompt_parm>

aref parameter accessor/mutator:

The 'prompt_parm' parm value is an aref with meta-information about the snippet: parms that will be required because of the inclusion of this snippet.

  my @prompt_parm = (
    'bar_parm',
    'foo_parm' => {   # override default parm attributes
                      prompt => 'Custom Prompt: ',
                  },
  )

  # set
  $snippet->pop->foo->prompt_parm( \@prompt_parm );

  #get
  my $prompt_parm_aref = $snippet->pop->foo->prompt_parm;

=item C<table>

aref parameter accessor/mutator:

  # set
  $snippet->pop->foo->table( [ 'bar.foo', 'bar.baz' ] );

  #get
  my $table = $snippet->pop->foo->table;

=item C<sql>

aref parameter accessor/mutator:

  # set
  $snippet->pop->foo->sql(
    [
        "and foo.id = baz.id",
        "and foo.thing in ($string_of_quoted_n_delimited_things)",
    ],

  #get
  my $sql = $snippet->pop->foo->sql;

=item C<group_by>

[UNIMPLEMENTED] aref parameter accessor/mutator:

  # set
  $snippet->pop->foo->group_by( [ 'foo.id', 'baz.id' ] );

  #get
  my $group_by = $snippet->pop->foo->group_by;

=item C<order_by>

[UNIMPLEMENTED] aref parameter accessor/mutator:

  # set
  $snippet->pop->foo->order_by( [ 'foo.id', 'baz.id' ] );

  #get
  my $group_by = $snippet->pop->foo->order_by;

=item C<having>

[UNIMPLEMENTED] aref parameter accessor/mutator:

  # set
  $snippet->pop->foo->having(
    [
        "and foo.id = baz.id",
        "and foo.thing in ($string_of_quoted_n_delimited_things)",
    ],

  #get
  my $having = $snippet->pop->foo->having;

=item C<desc>

[UNIMPLEMENTED] string parameter accessor/mutator.  The 'desc' parm value is a string with meta-information about the snippet

  # set
  $snippet->pop->foo->desc( $str );

  #get
  my $desc = $snippet->pop->foo->desc;

=item C<query>

Returns the SQL for a pop and all of its associated lims (including shared_lims) and parms.

  my $sql = $snippet->pop->foo->query;

=back 2

=head2 Lim Methods

  # $snippet->shared_lim->method;
  # $snippet->pop->pop_name->lim->method;

=over 2

=item C<new>

Constructs a new lim snippet, either attached to a particular pop snippet or as a shared lim at the snippet level.  (These are identical in structure except that shared lims do not accaept any parm information.)  Requires name of the lim snippet to be passed in.  Also accepts key=>value parameters (see lim snippet accessor/mutator methods for a list) that will override any defaults from the repository.

  $snippet->pop->pop_name->lim->new(
    $lim_name,
  );

=item C<list>

Returns a list of those lim objects currently instantiated.

  my @pops = $snippet->shared_lim->list;

=item C<remove>

Eliminates the specified pop object.

  $snippet->pop->foo_pop->remove( 'bar_lim' );

=back 2

=head2 Lim Snippet Methods

  # $snippet->pop->pop_name->lim->lim_name->method;
  # $snippet->shared_lim->lim_name->method;

=over 2

=item C<selectable>

aref parameter accessor/mutator:

The 'selectable' parm value is a aref with meta-information about the snippet: what fields are selectable (and what are their aliases) because of the inclusion of this snippet.

  my @selectable = (
    'field_1',
    [ 'field_2' => 'filed_2_alias' ],
  )

  # set
  $snippet->pop->pop_name->lim->lim_name->selectable(
    \@selectable
  );

  #get
  my $selectable_aref = $snippet->pop->pop_name
                          ->lim->lim_name->selectable;

=item C<prompt_parm>

aref parameter accessor/mutator:

The 'prompt_parm' parm value is an aref with meta-information about the snippet: parms that will be required because of the inclusion of this snippet.

  my @prompt_parm = (
    'bar_parm',
    'foo_parm' => {   # override default parm attributes
                      prompt => 'Custom Prompt: ',
                  },
  )


  # set
  $snippet->pop->pop_name
    ->lim->lim_name->prompt_parm( \@prompt_parm );

  # get
  my $prompt_parm_aref = $snippet->pop->pop_name
                           ->lim->lim_name->prompt_parm;

=item C<table>

aref parameter accessor/mutator:

  # set
  $snippet->shared_lim->lim_name->table(
    [ 'bar.foo', 'bar.baz' ]
  );

  #get will return either an aref or a scalar, depending
  # on which was stored as the value for table
  my $table = $snippet->shared_lim->lim_name->table;

=item C<sql>

aref parameter accessor/mutator:

  # set
  $snippet->pop->pop_name->lim->lim_name->sql(
    [
        "and foo.id = baz.id",
        "and foo.thing in ($string_of_quoted_n_delimited_things)",
    ],

  # get
  my $sql = $snippet->pop->pop_name->lim->lim_name->sql;

=item C<desc>

[UNIMPLEMENTED] string parameter accessor/mutator.  The 'desc' parm value is a string with meta-information about the snippet

  # set
  $snippet->shared_lim->lim_name->desc( $str );

  #get
  my $desc = $snippet->shared_lim->lim_name->desc;

=item C<note>

String parameter accessor/mutator.  The 'note' is useful for explaining the inclusion of a limit.  For example, the snippet level get_shared_lim method will return all the notes of those lims instantiated as shered_lim s.

  # set
  $snippet->pop->pop_name->lim_lim_name->note( $str );

  #get
  my $note = $snippet->pop_name->lim_lim_name->note;

=back 2

=head2 Parm Methods

  # $snippet->parm->method;
  # $snippet->pop->pop_name->parm->method;
  # $snippet->pop->pop_name->lim->lim_name->parm->method;

=over 2

=item C<new>

Constructs a new parm snippet.  Requires name of the parm snippet to be passed in.  Also accepts key=>value parameters (see parm snippet accessor/mutator methods for a list) that will override any defaults from the repository.  Note that when the query method is called  on a population, any parameter values required by that population and it's limits that are not defined at the pop or pop->lim level will be sought at the snippet level.  SHould they not be found there the user will be prompted and a snippet level parm object will be instantiated.

  $snippet->parm->new(
    $lim_name,
  );

=item C<list>

Returns a list of those parm objects currently instantiated.

  my @pops = $snippet->pop->pop_name->list;

=item C<remove>

Eliminates the specified pop object.

  $snippet->pop->pop_name->lim->lim_name->parm->remove( 'bar_lim' );

=back 2

=head2 Parm Snippet Methods

  # $snippet->parm->parm_name->method;
  # $snippet->pop->pop_name->parm->parm_name->method;
  # $snippet->pop->pop_name->lim->lim_name->parm->parm_name->method;

Note that all the parameters from Term::Interact (i.e., name, type, allow_null, check) are available as parameters for your parm snippets.  I won't recount them here; see perldoc Term::Interact for the details.  Other parameters available for your parm snippet:

=over 2

=item C<value>

string or aref accessor/mutator method.  Operates on the current value of the parm snippet.

  # set
  $snippet->parm->parm_name->value( 'foo' );

  #get
  my $value = $snippet->parm->parm_name->value;

=item C<label>

[UNIMPLEMENTED] string accessor/mutator method.  Operates on the meta-value 'label' parameter.  I see this as useful when auto-generating an HTML user interface.

=item C<desc>

[UNIMPLEMENTED] string accessor/mutator method.  Operates on the meta-value 'desc' parameter.  I see this as useful when auto-generating an HTML user interface.

=back 2

=cut

#################################
package SQL::Snippet::Parm;
use strict;

use vars qw/ $AUTOLOAD /;

sub _new_parm_obj {
    shift;
    my $self = bless {}, 'SQL::Snippet::Parm';
    my ($parm, %args) = @_;
    $self->snippet( $args{snippet} );
    eval { $self->name( $parm ) };  # ui should have a name parm, but you never know
    my @defaults = $self->snippet->init_parm(
                                                parm => $parm,
                                                ( $args{lim} ? (lim => $args{lim}) : () ),
                                                ( $args{pop} ? (pop => $args{pop}) : () ),
                                            );
    my %defaults = @defaults;
    for (keys %defaults) {
        $self->$_( $defaults{$_} );
    }
    for (keys %args) {
        $self->$_( $args{$_} );
    }
    return $self;
}

sub snippet {
    my $self = shift;
    $self->{snippet} = shift if @_;
    return $self->{snippet};
}

sub value {
    my $self = shift;

    my %args;

    # just use _value method for mutator functionality
    if ($#_ == 0) {
        if (!ref $_[0] or ref $_[0] eq 'ARRAY') {
            return $self->_value( @_ );
        } elsif (ref $_[0] eq 'HASH') {
            %args = %{ $_[0] };
        } else {
            die "Invalid arg to $self->value";
        }
    } else {
        # just return if we already have a value
        return $self->_value if (defined $self->_value);
        # otherwise, grab any args
        %args = @_;
    }

    if
    (
        $self->snippet->interact
          and
        (!exists $args{interact} or $args{interact})
    )
    {
        # set and return value via user interaction
        return $self->_value(
                                     # TODO: why these extra braces? ###################
                                         # slice out and pass only those parameters
                                         # allowed by $ui, followed by @_
            $self->snippet->ui->get( [ [ (map { exists $self->{$_} ? ($_,$self->{$_}) : () } $self->snippet->ui->parameters), @_] ] )
        );
    } else {
        if ($self->default) {
            return $self->_value( $self->default );
        } else {
            return undef;
        }
    }
}


sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;

    my @built_ins = (
        # for snippet object storage
        qw/ pop lim /,

        # actual value stored here
        qw/ _value /,

        # meta-info about this parm
        qw/ label desc /,
    );

    if (grep /$AUTOLOAD/, @built_ins) {
        $self->{$AUTOLOAD} = shift if @_;
    } else { # check $AUTOLOAD against those parms ui allows
        # look for boolean calls
        if ($AUTOLOAD =~ /^(set|clear)_/){
            my $op = $1;

            my @ui_args_boolean;
            push @ui_args_boolean, $self->snippet->ui->parameters( type=>'bool' );

            # remove operator
            $AUTOLOAD =~ s/^(set|clear)_//;
            die "method '${op}_$AUTOLOAD' is not valid" unless grep /$AUTOLOAD/, @ui_args_boolean;
            $self->{$AUTOLOAD} = ($op eq 'set') ? 1 : 0;
        } else {
            my @ui_args_non_boolean;
            push @ui_args_non_boolean, $self->snippet->ui->parameters( type=>'!bool' );
            die "method '$AUTOLOAD' is not valid" unless grep /$AUTOLOAD/, @ui_args_non_boolean;
            $self->{$AUTOLOAD} = shift if @_;
        }
    }
    return $self->{$AUTOLOAD};
}

#################################
package SQL::Snippet::ParmHash;
use strict;

use vars qw/ $AUTOLOAD /;

sub _parm_hash_ctor {
    shift;
    my %args = @_;
    my $self = {};
    for (keys %args) {
        $self->{$_} = $args{$_};
    }
    return bless $self;
}

# accomodate: $snippet->parm->new( 'foo' );
sub new {
    my ($self,$parm) = (shift,shift) or die;
    $self->{$parm} = SQL::Snippet::Parm->_new_parm_obj(
                                                          $parm,
                                                          snippet =>  $self->{snippet},
                                                          @_
                                                      );
    return ($self->{$parm}) ? 1 : 0;
}

# TODO: use $ui->validate to validate any value passed in via AUTOLOAD mutator
# accomodate: $snippet->parm->foo->parm_method;
sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;

    # this AUTOLOAD method merely enables autoinstantiation and the return
    # of parm objects.  No parameters should be passed to it.
    if (@_) {
        die "You passed parameters to $AUTOLOAD, but that makes no sense because $AUTOLOAD is an object.  Did you forget to specify the method you were looking for, ala ...$AUTOLOAD->method( \@parms )?"
    }
    $self->new($AUTOLOAD) unless $self->{$AUTOLOAD};    # autoinstantiation enabler
    return $self->{$AUTOLOAD};
}

sub list {
    my $self = shift;
    my @keys = sort keys %{ $self };
    my @return;
    for (@keys) {
        push @return, $_ if (ref $self->{$_} eq 'SQL::Snippet::Parm');
    }
    return @return;
}

sub remove {
    my ($self,@parms) = @_;
    my $pop_lim = '';
    if ($self->{pop}) {
        $pop_lim .= $self->{pop} . '->';
    }
    if ($self->{lim}) {
        $pop_lim .= $self->{lim} . '->';
    }
    for (@parms) {
        warn "You tried to remove parameter $_, but no parm \$snippet->" . $pop_lim . "{$_} exists" unless exists $self->{$_};
        delete $self->{$_};
    }
}


#################################
package SQL::Snippet::Lim;
use strict;

use Class::MethodMaker
    new_with_init   =>  '_new_lim_obj',
    new_hash_init   =>  '_init_args',
    get_set         =>  [qw/ snippet
                             pop
                             name
                             valid_pop
                             prompt_parm
                             selectable
                             table
                             sql
                             parm
                             desc
                             note       /];

sub init {
    my ($self, $lim, %args) = @_;
    $self->name( $lim );

    my $snippet = $args{snippet};

    # shared_lim will *not* have its own heirarchy of parm objects
    unless ($args{shared_lim}) {
        $self->parm( SQL::Snippet::ParmHash->_parm_hash_ctor(
                                                                snippet => $snippet,
                                                                ( $args{pop} ? (pop => $args{pop}) : () ),
                                                                lim => $lim,
                                                            ) );
    } else {
        # we're done with this flag
        delete $args{shared_lim};
    }

    # set defaults
    my $meta_data_href = $snippet->init_lim( lim => $lim, single_meta => 1 );
    for (keys %{$meta_data_href->{$lim}}) {
        $self->$_( $meta_data_href->{$lim}{$_} );
    }

    for (keys %args) {
        if ( $self->can($_) ) {
            $self->$_( $args{$_} );
        } else {
            die "You tried to set a Limit attribute that was not recognized - $_\n";
        }
    }
}

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;
    die "You tried to invoke $self->{name}\->$AUTOLOAD\, but the $self->{name} lim has no method named $AUTOLOAD";
}


#################################
package SQL::Snippet::LimHash;
use strict;
use vars qw/ $AUTOLOAD /;

sub _lim_hash_ctor {
    shift;
    my %args = @_;
    my $self = {};
    for (keys %args) {
        $self->{$_} = $args{$_};
    }
    return bless $self;
}

# accomodate: $snippet->shared_lim->new( 'bar' );
# accomodate: $snippet->pop->foo->lim->new( 'bar' );
sub new {
    my ($self,$lim) = (shift,shift) or die;
    $lim = [ $lim ] unless ref $lim;
    for (@$lim) {
        $self->{$_} = SQL::Snippet::Lim->_new_lim_obj(
                                                        $_,
                                                        snippet => $self->{snippet},
                                                        ( $self->{pop} ? (pop => $self->{pop}) : () ),
                                                        @_
                                                     ) or die "Could not set up lim $_";
    }
    return 1;
}

# accomodate: $snippet->shared_lim->bar->lim_method;
# accomodate: $snippet->pop->foo->lim->bar->lim_method;
sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;

    # this AUTOLOAD method merely enables autoinstantiation and the return
    # of lim objects.  No parameters should be passed to it.
    if (@_) {
        die "You passed parameters to $AUTOLOAD, but that makes no sense because $AUTOLOAD is an object.  Did you forget to specify the method you were looking for, ala ...$
AUTOLOAD->method( \@parms )?"
    }
    $self->new($AUTOLOAD) unless $self->{$AUTOLOAD};    # autoinstantiation enabler
    return $self->{$AUTOLOAD};
}

sub list {
    my $self = shift;
    my @keys = sort keys %{ $self };
    my @return;
    for (@keys) {
        push @return, $_ if (ref $self->{$_} eq 'SQL::Snippet::Lim');
    }
    return @return;
}

sub remove {
    my ($self,@lims) = @_;
    for (@lims) {
        warn "You tried to remove limit $_, but no lim \$snippet->" . ($self->{pop} ? $self->{pop} . '->' : '') . "{$_} exists" unless exists $self->{$_};
        delete $self->{$_};
    }
}

#################################
package SQL::Snippet::Pop;
use strict;

use Class::MethodMaker
    new_with_init   =>  '_new_pop_obj',
    new_hash_init   =>  '_init_args',
    get_set         =>  [qw/ snippet
                             name
                             select
                             selectable
                             prompt_parm
                             table
                             sql
                             group_by
                             order_by
                             having
                             parm
                             lim
                             desc   /];

sub init {
    my ($self, $pop, %args) = @_;
    my $snippet = $args{snippet};
    $self->name( $pop );
    $self->parm( SQL::Snippet::ParmHash->_parm_hash_ctor(
                                                            snippet => $snippet,
                                                            pop     => $pop
                                                        ) );
    $self->lim( SQL::Snippet::LimHash->_lim_hash_ctor(
                                                        snippet =>  $snippet,
                                                        pop     =>  $pop
                                                     ) );

    # TODO: make sure no parms are attached that are not in prompt_parm aref.

    # set defaults
    $self->table( [] );
    $self->sql( [] );
    my $meta_data_href = $snippet->init_pop( pop => $pop, single_meta => 1 );
    for (keys %{$meta_data_href->{$pop}}) {
        $self->$_( $meta_data_href->{$pop}{$_} );
    }

    for (keys %args) {
        if ( $self->can($_) ) {
            $self->$_( $args{$_} );
        } else {
            die "You tried to set a Population attribute that was not recognized - $_\n";
        }
    }

    # TODO: add syntax enforcement for selectable value here.
}

# UNDER DEVELOPMENT
sub create_select {
    # This would prompt user with available select fields using ui...
    die "No SELECT statement has been set for this pop, and the create_select method is (as yet) unimplemented!";
}

sub query {

    ### TO DO: recreate this method to allow multiple sql_syntaxes.
    ###        currently it will always do Oracle syntax

    my $self = shift;
    my %args = @_;

    my $pop = $self->name;

    my %defaults = $self->snippet->init_pop( pop => $pop );
    for (keys %defaults) {
        if ( $self->can($_) ) {
            $self->$_( $defaults{$_} );
        } else {
            die "The Repository tried to set a Population attribute for population $pop that was not recognized - $_";
        }
    }

    my @clauses_raw = (ref $self->sql eq 'ARRAY')   ? @{ $self->sql }   : ($self->sql );
    my @tables_raw  = (ref $self->table eq 'ARRAY') ? @{ $self->table } : ($self->table );
    die "No tables were found for pop $pop!" unless scalar @tables_raw;

    # UPGRADE: enable this sort of sorting
    # for (sort { $self->{$_}{order}{$a} <=> $self->{$_}{order}{$a} } keys $self->{lim}) {}

    # pop level lim processing
    for my $lim ($self->lim->list) {
        my $defaults = $self->snippet->init_lim( lim => $lim, pop => $pop );
        if (keys %{ $defaults}) {
            die "No list of valid populations was returned from repository for lim $lim"
                unless (exists $defaults->{$lim}{valid_pop});
            my @valid_pop = (ref $defaults->{$lim}{valid_pop} eq 'ARRAY')
                          ? @{ $defaults->{$lim}{valid_pop} }
                          :  ( $defaults->{$lim}{valid_pop} );
            die "Population ", $pop ," cannot be limited by $lim"
                unless (grep /^$pop$/ => @valid_pop );
            delete $defaults->{$lim}{valid_pop};

            for (keys %{$defaults->{$lim}}) {
                if ( $self->lim->$lim->can($_) ) {
                    $self->lim->$lim->$_( $defaults->{$lim}{$_} );
                } else {
                    # do i really want to die here?  why not silently forgive...
                    die "The Repository tried to set a Limit attribute for limit $lim that was not recognized - $_";
                }
            }
        } else {
            # this must have been a custom lim, i.e. not supplied in the repository.
            # TODO:  require that certain parms like SQL be extant in the lim obj
            # already since there were none in the repository?
        }

        push @clauses_raw,  (ref $self->lim->$lim->sql eq 'ARRAY')
                            ? @{ $self->lim->$lim->sql }
                            :  ( $self->lim->$lim->sql );

        if ($self->lim->$lim->table) {
            unshift @tables_raw,    (ref $self->lim->$lim->table eq 'ARRAY')
                                    ?  reverse @{ $self->lim->$lim->table }
                                    :  ( $self->lim->$lim->table );
        }
    }

    # snippet level (shared) lim processing
    # add in shared lims unless this is a 'standalone' query
    unless ($args{standalone}) {  #TODO: document standalone option
        for my $lim ($self->snippet->shared_lim->list) {

            # note that the shared lim default info is being generated with regard to the
            # population it is currently being appllied to.
            my $defaults = $self->snippet->init_lim( lim => $lim, pop => $pop );
            if (keys %{ $defaults}) {
                die "No list of valid populations was returned from repository for lim $lim"
                    unless (exists $defaults->{$lim}{valid_pop});
                my @valid_pop = (ref $defaults->{$lim}{valid_pop} eq 'ARRAY')
                              ? @{ $defaults->{$lim}{valid_pop} }
                              :  ( $defaults->{$lim}{valid_pop} );
                die "Population ", $pop ," cannot be limited by $lim"
                    unless (grep /^$pop$/ => @valid_pop );
                delete $defaults->{$lim}{valid_pop};

                # be careful!  the note for this shared lim will be revised to reflect
                # this particular application.  Thus if you are binding you will end
                # up with a note like "This report limited to those records with foo: ?"
                for (keys %{$defaults->{$lim}}) {
                    if ( $self->snippet->shared_lim->$lim->can($_) ) {
                        $self->snippet->shared_lim->$lim->$_( $defaults->{$lim}{$_} );
                    } else {
                        # do i really want to die here?  why not silently forgive...
                            die "The Repository tried to set a Limit attribute for limit $lim that was not recognized - $_";
                    }
                }
            } else {
                # this must have been a custom lim, i.e. not supplied in the repository.
                # TODO:  require that certain parms like SQL be extant in the lim obj
                # already since there were none in the repository?
            }

            push @clauses_raw,  (ref $self->snippet->shared_lim->$lim->sql eq 'ARRAY')
                                ? @{ $self->snippet->shared_lim->$lim->sql }
                                :  ( $self->snippet->shared_lim->$lim->sql );

            if ($self->snippet->shared_lim->$lim->table) {
                unshift @tables_raw,    (ref $self->snippet->shared_lim->$lim->table eq 'ARRAY')
                                        ?  reverse @{ $self->snippet->shared_lim->$lim->table }
                                        :  ( $self->snippet->shared_lim->$lim->table );
            }
        }
    }

    # Hash used to extract unique elements from a list.
    my %saw;    # (As in, "I *saw* it.")

    # Extract unique tablenames; discard duplicates.
    my @sql_tables = grep(!$saw{$_}++, @tables_raw);

    # Create FROM statement. ###################################
    my $sql_from = ("FROM " . join ', ', @sql_tables) . "\n";

    # Create WHERE clause. #####################################

    my (@equality_clauses,       @other_clauses);
    my (@clauses_final_unsorted, @clauses_final_sorted);
    my  @clauses_final;

    my $precedence = 0;
    foreach (@clauses_raw) {
      # Ignore any null strings, process the rest.
      if ($_) {
        # Ensure first word is 'and'.
        die "Received a where clause that didn't begin with \'and\'!\n"
            unless ($_ =~ /\s*and/i);
        # Split $_ on whitespace, after ignoring leading whitespace.
        my @words = split;
        # If this clause has 4 words and the 3rd is an equal sign...
        if ($#words == 3 && $words[2] eq '=') {
            push @equality_clauses, [ $precedence, $_ ];
        } else {
            push @other_clauses, [ $precedence, $_];
        }
        $precedence++;
      }
    }

    my @equality_clauses_2;
    foreach (@equality_clauses) {
        $precedence = ${ $_ }[0];
        my $line = ${ $_ }[1];
        # Replace any spaces with NULLs
        $line =~ s/\s+//g;
        # Kill the 'and'.
        substr($line, 0, 3) = '';
        # the following fields array has three positions:
        #  - field1
        #  - field2
        #  - outer join field  (optional, could be field1 or field2)
        my @fields = split /=/, $line;
        foreach (@fields) {
            # If this field has the outer join marker...
            if (substr($_, -3) eq "\(+\)") {
                # Remove outer join marker from field.
                substr($_, -3) = '';
                # Copy field into third position of fields array
                push @fields, $_;
            }
        }
        # No more than one field should have the (+), so fields array
        #  length should never exceed 3 elements.
        die "Both sides of a join were marked with the outer join symbol!\n"
            if ($#fields > 2);
        # Enforce same length of 3 elements for each clause.
        push @fields, '' unless ($fields[2]);
        # Push anonymous arrayref to fields array
        push @equality_clauses_2, [ $precedence, @fields ];
    }
    # Eliminate any outright duplicates based on @fields.
    undef %saw;
    @equality_clauses_2 = grep {
                                    my @x = @{ $_ }[1,2,3];         # Get @fields
                                    my $x = join '',@x;             # Smush them together into one string

                                    # The last line in this grep block is tricky, so here's the explanation:
                                    #                       THE BIG PICTURE:
                                    # If the last expressions in the block evaluates as true, the current
                                    # element of @equality_clauses_2 will be passed on by grep.
                                    #               WHAT !$saw{$x}++ ACTUALLY MEANS:
                                    # The first time $x is referenced, !$saw{$x} will be TRUE, because
                                    # the value recorded for the $x key of the %saw hash is merely undef (i.e.
                                    # FALSE).  However, the autoincrement operator will add one to the original
                                    # value of undef, resuting in a value of 1.  If the same string should be
                                    # referenced again, !$saw{$x} will evaluate as FALSE, because there is now
                                    # a true value for the key $x.  Once again, the value of one will be added
                                    # by the autoincrement operator.
                                    !$saw{$x}++;
                               } @equality_clauses_2;

    # There will be one key for each group of semi-duplicates.
    #  The value for that key will be an arrayref of arrayrefs.
    #  This block thanks to John Porter and Uri Guttman via clpmisc.
    my %temp_hash;
    foreach ( @equality_clauses_2 ) {
      push @{ $temp_hash{join '', sort @{$_}[1,2] } }, $_;
    }
    my @grouped_list = @temp_hash{ keys %temp_hash } ;

    foreach my $group (@grouped_list) {
      # We'll be returning the finalized clause in precedence of the first
      #  semi-duplicate.
      my $precedence = ${ ${ $group }[0] }[0];
      my $outerj = '';

      # Process each member of this group of semi-duplicates.  If the snippet appears both with and without
      #  an outer join, the outer join version will be the one preserved.
      foreach my $aref (@{ $group } ) {
        # If there's a value in the outerjoin position of the array...
        if (${ $aref }[3]) {
            if ($outerj) {
                # If we already defined the outerjoin field for this group, die
                #  if this semi-duplicate indicates a different outerjoin field.
                die "Two different where clause lines indicated opposite sides of\n" .
                    "a join with the outer-join symbol (+)!  Only one should have\n" .
                    "been so indicated.\n"
                    unless ($outerj eq ${ $aref }[3]);
            } else {
                # Since we have not yet defined any field as an outerjoin field,
                #  set this field as the outerjoin field for this group.
                $outerj = ${ $aref }[3];
            }
        }
      }

      # Create final clause for this group of semi-duplicates.  The order of the
      #  two fields is not controlled; the ordering found in the first member of
      #  group is used.  If there is an outerjoin field set for this group, the
      #  appropriate field has the (+) sign concatenated on.
      my ($field1, $field2);
      if ($outerj eq '') {
          # Don't add (+) to either field.
          $field1 = ${ ${ $group }[0] }[1];
          $field2 = ${ ${ $group }[0] }[2];
      } elsif ($outerj =~ /${ ${ $group }[0] }[1]/) {
          # Add (+) to the first field
          $field1 = $outerj . '(+)';
          $field2 = ${ ${ $group }[0] }[2];
      } else {
          $field1 = ${ ${ $group }[0] }[1];
          # Add (+) to the second field
          $field2 = $outerj . '(+)';
      }
      push @clauses_final_unsorted, [ $precedence, "and $field1 = $field2\n" ];
    }

    # Eliminate any duplicate other_clauses, regardless of whitespace.
    undef %saw;
    push @clauses_final_unsorted, grep  {
                                            (my $x = ${ $_}[1]) =~ s/\s+//g;
                                            !$saw{$x}++
                                        } @other_clauses;

    @clauses_final_sorted = sort {    ${ $a }[0]     <=>     ${ $b }[0]    } @clauses_final_unsorted;

    foreach (@clauses_final_sorted) {
        push @clauses_final, ${ $_ }[1];
    }

    foreach (@clauses_final) { chomp; }
    my $sql_clauses = join "\n", @clauses_final;
    $sql_clauses =~ s/and/WHERE/; #replace 1st 'and' with 'WHERE'

    my $select;
    unless ($self->select) {
        $self->select( $self->create_select );
    }
    $select = $self->select;
    chomp $select;


    # Concatenate and return select, from, and where clauses.
    my $sql = $select. "\n" . $sql_from . $sql_clauses;

    # we should log SQL statement at this point...

    return $sql;
}


#################################
package SQL::Snippet::PopHash;
use strict;

use vars qw/ $AUTOLOAD /;

sub _pop_hash_ctor {
    shift;
    my %args = @_;
    my $self = {};
    for (keys %args) {
        $self->{$_} = $args{$_};
    }
    return bless $self;
}

# accomodate: $snippet->pop->new( 'foo' );
sub new {
    my ($self,$pop) = (shift,shift) or die;
    $self->{$pop} = SQL::Snippet::Pop->_new_pop_obj(
                                                      $pop,
                                                      snippet =>  $self->{snippet},
                                                      @_
                                                    );
    return ($self->{$pop}) ? 1 : 0;
}

# accomodate: $snippet->pop->foo->pop_method;
sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY$/;
    $AUTOLOAD =~ s/.*:://;  # trim the package name
    my $self = shift;
    $self->new($AUTOLOAD) unless $self->{$AUTOLOAD};    # autoinstantiation enabler
    return $self->{$AUTOLOAD};
}

sub list {
    my $self = shift;
    my @keys = sort keys %{ $self };
    my @return;
    for (@keys) {
        push @return, $_ if (ref $self->{$_} eq 'SQL::Snippet::Pop');
    }
    return @return;
}

sub remove {
    my ($self,@pops) = @_;
    for (@pops) {
        warn "You tried to remove population $_, but no pop \$snippet->{$_} exists" unless exists $self->{$_};
        delete $self->{$_};
    }
}


#################################
package SQL::Snippet;
#use diagnostics;
use strict;

use vars qw( $VERSION );

$VERSION = '0.03';

use Class::MethodMaker
    new_with_init   =>  'new',
    new_hash_init   =>  '_init_args',
    boolean         =>  'interact',
    get_set         =>  [
                          qw/
                                sql_syntax
                                dbh
                                ui
                                parm
                                shared_lim
                                pop
                            /
                        ];

sub init {
    my ($self,%args) = @_;

    # set defaults
    $self->set_interact;
    $self->sql_syntax( 'oracle' );

    if ($args{shared_lim}) {
        $self->{shared_lim} = $args{shared_lim};
        delete $args{shared_lim};
    }

    # use passed in defaults
    $self->_init_args( %args );

    # die if an unsupported SQL syntax was requested.
    die "$self->sql_syntax syntax is not currently supported."
      if ($self->sql_syntax !~ /^oracle$/i);

    # stick parm object in our 'parm' slot
    $self->parm( SQL::Snippet::ParmHash->_parm_hash_ctor(snippet => $self) );

    # stick lim object in our 'shared_lim' slot
    $self->shared_lim( SQL::Snippet::LimHash->_lim_hash_ctor(snippet => $self, shared_lim => 1) );

    # stick pop object in our 'pop' slot
    $self->pop( SQL::Snippet::PopHash->_pop_hash_ctor(snippet => $self) );
}


sub exists {

    my ($self, %args) = @_;
    my $pop  = ($args{pop})  ? $args{pop}  : '';
    my $lim  = ($args{lim})  ? $args{lim}  : '';
    my $parm = ($args{parm}) ? $args{parm} : '';

    if ($pop and $lim and $parm) {
        return (defined $self->{pop}{$pop}{lim}{$lim}{parm}{$parm}) ? 1 : 0;

    } elsif ($pop and $lim and !$parm) {
        return (defined $self->{pop}{$pop}{lim}{$lim}) ? 1 : 0;

    } elsif ($pop and !$lim and $parm) {
        return (defined $self->{pop}{$pop}{parm}{$parm}) ? 1 : 0;

    } elsif ($pop and !$lim and !$parm) {
        return (defined $self->{pop}{$pop}) ? 1 : 0;

    } elsif (!$pop and !$lim and $parm) {
        return (defined $self->{parm}{$parm}) ? 1 : 0;

    } else {
        die "You asked the exists method a strange question.\n";
    }
}

# quote and delimit values -- useful for SQL statement interpolation
sub qnd {
    my $self = shift;
    die "The qnd method was invoked, yet there is no database handle available for its use!" unless defined $self->dbh;

    my $list = (ref $_[0]) ? $_[0] : [ $_[0] ];
    return join ',' => map  {
                                $_ eq '?'                           # don't quote bind vals
                                ? $_
                                :
                                    $_ eq '\?'                      # unescape and quote literal ?
                                    ? $self->dbh->quote( '?' )
                                    : $self->dbh->quote( $_ )
                            }
                            @$list;
}

sub get_shared_lim_notes {
    my $self = shift;
    my @shared_lims = $self->shared_lim->list;

    my @return = ();
    for (@shared_lims) {
        my $note = $self->shared_lim->$_->note;
        push @return, $note if ($note);
    }

    return (wantarray) ? @return : join("\n" => @return) . "\n";
}

sub contextual_parm_info {
 #
 #  picture of invocation:
 #
 #  $self->contextual_parm_info (
 #                                  pop         =>  $pop,
 #                                  lim         =>  $lim,
 #                                  method      =>  $method,
 #                                  interact    =>  $interact,
 #                                  parm        =>  [
 #                                                      [
 #                                                          parm_name_1 =>  {
 #                                                                              prompt   => $prompt,
 #                                                                              msg      => $msg,
 #                                                                              dont_qnd => 1,
 #                                                                          },
 #                                                      ],
 #                                                      parm_name_2,
 #                                                  ],
 #                              );
 #
 #
 #
 #  returns an aref of values returned by the specified method, in order, for each specified
 #  parm object.
 #

    my $self = shift;
    my %arg = @_;

    my $pop = $arg{pop} || '';
    delete $arg{pop};
    my $lim = $arg{lim} || '';
    delete $arg{lim};
    my $method = $arg{method} || die "No method passed!";
    delete $arg{method};
    my $interact = $arg{interact} || '';
    delete $arg{interact};

    die "No aref of parm info was passed!" unless defined $arg{parm};

    # allow single parm name to come in as a scalar
    $arg{parm} = [ $arg{parm} ] unless (ref $arg{parm} eq 'ARRAY');

    my @ordered_parms;
    my $parm;
    for my $foo (@{$arg{parm}}) {
        if (!ref $foo) {
            push @ordered_parms, $foo;
            $parm->{$foo} = {};
        } elsif (ref $foo eq 'ARRAY') {
            push @ordered_parms, $foo->[0];
            $parm->{$foo->[0]} = $foo->[1];
        } else {
            die "invalid parm arg";
        }
    }

    for (@ordered_parms) {  # ordering doesn't actually matter for this block...
        my $temp_method = $method;

        if ($temp_method eq 'value') {
            # we'll avoid the 'value' method this time around (it's a fancy
            # front end to front end to the _value method.  Let's look only,
            # using _value.
            $temp_method = '_value';
        }

        if ( $pop and $self->exists(pop => $pop) ) {
            # lim level attempt
            if ($lim) {
                if ( $self->exists(pop => $pop, lim => $lim, parm => $_) ) {
                    $parm->{$_}{return} = $self->pop->$pop->lim->$lim->parm->$_->$temp_method;
                }
            } else {
                # pop level attempt
                if ( $self->exists(pop => $pop, parm => $_) ) {
                    $parm->{$_}{return} = $self->pop->$pop->parm->$_->$temp_method;
                }
            }
        }
        #parm level attempt
        unless (defined $parm->{$_}{return}) {
            $parm->{$_}{return} = $self->parm->$_->$temp_method;
        }
    }

    my @ordered_parms_w_undef_value = ();
    for my $parm_name (@ordered_parms) {
        unless (defined $parm->{$parm_name}{return}) {
            if ($method eq 'value') {
                push @ordered_parms_w_undef_value, $parm_name;
                # copy all the settings from parm object
                # into $parm->{$parm_name} for passing
                # to ui get method...
                # ... *unless* that setting is already
                # set!
                for (keys %{ $self->{parm}{$parm_name} }) {
                    $parm->{$parm_name}{$_} = $self->{parm}{$parm_name}{$_} unless defined $parm->{$parm_name}{$_};
                }
            }
        }
    }

    my @ui_args;
    for my $p (@ordered_parms_w_undef_value) {
        # set our interact status for each of the parms before passing them
        # to the user interface...
        $parm->{$p}{interact} = $self->interact;

        # for this parm, push an aref of only those parameters
        # allowed by ui onto @ui_args
        push @ui_args, [ map { exists $parm->{$p}{$_} ? ($_, $parm->{$p}{$_}) : () } $self->ui->parameters ];
    }
    my @vals = $self->ui->get( \@ui_args );

    my $idx = 0;
    for (@ordered_parms_w_undef_value) {
        # save the value for return
        $parm->{$_}{return} = $vals[ $idx ];
        # update the parm value, too!
        $self->parm->$_->value ( $vals[ $idx ] );

        $idx++;
    }

    my @return;
    for (@ordered_parms) {
        # we won't be quoting NULL strings, nor will we quote if we've been asked not to
        if
        (
            (
                !ref $parm->{$_}{return}
                  and
                $parm->{$_}{return} eq ''
            )
              or
            (
                ref $parm->{$_}{return} eq 'ARRAY'
                  and
                $#{ $parm->{$_}{return} } == 0
                  and
                ${ $parm->{$_}{return} }[0] eq ''
            )
        )
        {
            @return = ('');
        }
        elsif
        (
            defined $parm->{$_}{dont_qnd}
              and
            $parm->{$_}{dont_qnd}
        )
        {
            push @return, $parm->{$_}{return};
        }
        else
        {
            push @return, $self->qnd( $parm->{$_}{return} );
        }
    }

    return @return;
}


1;
__END__

=head1 AUTHOR

SQL::Snippet by Phil R Lawrence.

=head1 SUPPORT

Support is available by emailing the author directly:
  prl ~AT~ cpan ~DOT~ org

=head1 COPYRIGHT

The SQL::Snippet module is Copyright (c) 2002 Phil R Lawrence.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 NOTE

This module was developed while I was in the employ of Lehigh University.  They kindly allowed me to have ownership of the work with the understanding that I would release it to open source.  :-)

=head1 SEE ALSO

DBI, Term::Interact

=cut
