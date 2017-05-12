package Su;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Carp;
use Test::More;
use File::Path;

use Su::Process;
use Su::Template;
use Su::Model;
use Su::Log;

use Fatal qw(mkpath open);

our $VERSION = '0.110';

our @ISA = qw(Exporter);

our @EXPORT = qw(resolve setup gen_defs gen_model gen_proc);

our $info_href = {};

our $BASE_DIR = './';

our $DEFS_DIR = 'Defs';

our $DEFS_MODULE_NAME = "Defs";

our $DEFAULT_MODEL_NAME = 'Model';

our $DEFAULT_PROC_NAME = 'MainProc';

# A relative path to place the .tmpl file.
our $SU_TMPL_DIR = '/Su/templates/';

# The field name to define the global fields in Defs file.
our $GLOBAL_MODEL_FIELD = 'global_model_field';

=head1 NAME

Su - A simple application layer to divide and integrate data and processes in the Perl program.

=head1 SYNOPSIS

 my $su = Su->new;
 my $proc_result = $su->resolve('process_id');
 print $proc_result;

=head1 DESCRIPTION

Su is a simple application framework that works as a thin layer to
divide data and process in your Perl program. This framework aims an
ease of maintenance and extension of your application.

Su is a thin application layer, so you can use Su with many other
frameworks you prefer in many cases.

Note that Su framework has nothing to do with unix C<su> (switch
user) command.

=head3 Prepare Data and Process file

Su provides the method to generate the template of Model and Process.
You can use method C<generate()> like the following:

  perl -MSu -e 'Su::generate("Pkg::SomeProc")'

Then, the file F<Pkg/SomeProc.pm> and F<Pkg/SomeModel.pm> should be
generated.

Now describe your data to the C<$model> field of the generated Model
file.

 my $model=
 {
   field_a =>'value_a'
 };

And describe your process code to the C<process> method defined in the
generated Process file like the following:

 sub process{
   my $self = shift if ref $_[0] eq __PACKAGE__;
   my $param = shift;

   my $ret = "param:" . $param . " and model:" . $model->{field_a};
   return $ret;
 }

=head3 Integrate Model and Process

Su integrates Model and Processes using the definition file.
To generate the definition file, type the following command.

 perl -MSu -e 'Su::gen_defs()'

Then describe your setting to the C<$defs> field defined in the
generated F<Defs.pm> file.

 my $defs =
   {
    some_entry_id =>
    {
     proc=>'Pkg::SomeProc',
     model=>'Pkg::SomeModel',
    },
   };

You can also generate F<Defs.pm> using the C<generate> method by
passing the parameter C<1> as a second parameter.

  perl -MSu=base,lib -e 'Su::generate("Pkg::SomeProc", 1)'

Then the file F<Defs.pm> will be generated with Model and Process file.

=head3 Run the process using Su

You can call the process via Su by passing the entry id which defined in
the definition file F<Defs.pm>.

 my $su = Su->new;
 my $result = $su->resolve('some_entry_id');

To pass the parameters to the C<process> method in Process, then pass
the additional parameter to the C<resolve> method.

 my $result = $su->resolve('some_entry_id', 'param1');

=head3 Other features Su provides

Logging and string template are the feature su provides for
convinience. These features are frequently used in many kinds of
applications and you can use these features without any other
dependencies.  Surely you can use other modules you prefer with Su
framework.

=head2 Additional usage - Filters

The map, reduce and scalar filters can be defined in the definition file.

These filters are Perl module which has the method for filtering the
result of the process. (In case of C<map> filter, method name is
C<map_filter>.) You can chain filter modules. The following code is a
sample definition which uses these filters.

  my $defs =
   {
    some_proc_id =>
    {
     proc=>'MainProc',
     model=>'Pkg::MainModel',
     map_filter=>'Pkg::FilterProc',     # or ['Filter01','Filter02']
     reduce_filter=>'Pkg::ReduceProc',  # reduce filter can only apply at once.
     scalar_filter=>'Pkg::ScalarProc',  # or ['Filter01','Filter02']
    }
   };

The filters Su recognizes are the followings.

=over

=item map_filter

The perl module which has C<map_filter> method.
The parameter of this method is an array which is a result of the
'process' method of the Process or the chained map filter.
The C<map_filter> method must return the array data type.

=item reduce_filter

The perl module which has C<reduce_filter> method.
The parameter of this method is an array which is a result of the
'process' method of the Process.
If the map filters are defined in the C<Defs.pm>, then the map_filters
are applied to the result of the process before passed to the reduce
filter.
The C<reduce_filter> method must return the scalar data type.
Note that this method can't chain.

=item scalar_filter

The perl module which has C<scalar_filter> method.
The parameter of this method is a scalar which is a result of the
'process' method of the Process.
If the C<map_filters> and C<recude_filters> are defined in the
C<Defs.pm>, then these filters are applied to the result of the
process before passed to the scalar filter.

The C<scalar_filter> method must return the scalar data type.

=back

=head1 ATTRIBUTES

=head2 C<$MODEL_LOCALE>

Set the locale string like 'ja_JP' to load locale specific Model
module. Locale specific Model has the postfix in it's name like
'Pkg::ModelName__ja_JP'.

Then you should set the locale like this.

  $Su::MODEL_LOCALE = 'ja_JP';

=cut

our $MODEL_LOCALE = '';

=head2 C<$MODEL_KEY_PREFIX>

The hash reference which contains the key prefixes of the Model.
The key of this hash is a name of the model to apply this prefix.

  $MODEL_KEY_PREFIX = {
    'pkg::SomeModel'=>'pre1',
  };

In this example, the key string 'pre1_key1' defined in
'pkg::SomeModel' is automatically converted to 'key1'. So you can
access customized value using key 'key1'.

If the modified key is not exist, then the value of original key
should used.

=cut

our $MODEL_KEY_PREFIX = {};

=head2 C<$MODEL_KEY_POSTFIX>

The hash reference which contains the key postfixes of the Model.
The key of this hash is a name of the model to apply this postfix.

This variable work same as $MODEL_KEY_PREFIX.

=cut

our $MODEL_KEY_POSTFIX = {};

=begin comment

The flag to use global defs setting set by the method Su::setup() directly, instead of read from Defs file.

=end comment

=cut

our $USE_GLOBAL_SETUP = undef;

=head1 METHODS

=over

=item import()

use Su base=>'./base', proc=>'tmpls', model=>'models', defs=>'defs';

If you want to specify some parameters from the command line, then it becomes like the following.

perl -Ilib -MSu=base,./base,proc,tmpls,defs,models -e '{print "do some work";}'

=cut

sub import {
  my $self = shift;

  # Save import list and remove from hash.
  my %tmp_h        = @_;
  my $imports_aref = $tmp_h{import};

  delete $tmp_h{import};
  my $base     = $tmp_h{base};
  my $template = $tmp_h{template};
  my $defs     = $tmp_h{defs};
  my $model    = $tmp_h{model};

  #  print "base:" . Dumper($base) . "\n";
  #  print "template:" . Dumper($template) . "\n";
  #  print "model:" . Dumper($model) . "\n";
  #  print "defs:" . Dumper($defs) . "\n";
  #  $self->{logger}->trace( "base:" . Dumper($base) );
  #  $self->{logger}->trace( "template:" . Dumper($template) );
  #  $self->{logger}->trace( "model:" . Dumper($model) );
  #  $self->{logger}->trace( "defs:" . Dumper($defs) );
  Su::Log->trace( "base:" . Dumper($base) );
  Su::Log->trace( "template:" . Dumper($template) );
  Su::Log->trace( "model:" . Dumper($model) );
  Su::Log->trace( "defs:" . Dumper($defs) );

  $DEFS_DIR                   = $defs     if $defs;
  $Su::Template::TEMPLATE_DIR = $template if $template;
  $Su::Model::MODEL_DIR       = $model    if $model;

# If base is specified, then this setting effects to the all modules in Su package.
  if ($base) {
    no warnings qw(once);
    $BASE_DIR                        = $base;
    $Su::Template::TEMPLATE_BASE_DIR = $base;
    $Su::Model::MODEL_BASE_DIR       = $base;
  } ## end if ($base)

  if ( $base || $template || $model || $defs ) {
    $self->export_to_level( 1, $self, @{$imports_aref} );
  } else {

# If '' or '' is not passed, then all of the parameters are required method names.
    $self->export_to_level( 1, $self, @_ );
  }

} ## end sub import

=begin comment

Load the definition file which binds process and model to the single entry.
The default definition file loaded by Su is F<Defs::Defs.pm>.
You can specify the loading definition file as a parameter of this method.

 $su->_load_defs_file();
 $su->_load_defs_file('Defs::CustomDefs');

If the Defs file is already loaded, do nothing and just return it's hash.

If you want to reload defs file force, then pass the second parameter
as reload option.

  $su->_load_defs_file( "Defs::Defs", 1 );

=end comment

=cut

our $defs_module_name;

sub _load_defs_file {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $BASE_DIR = $self->{base} ? $self->{base} : $BASE_DIR;
  my $DEFS_DIR = $self->{defs} ? $self->{defs} : $DEFS_DIR;

  # Nothing to do if info is already set or loaded.
  # if ( $info_href && keys %{$info_href} ) {
  #   return;
  # }

  my $defs_mod_name  = shift || "Defs::Defs";
  my $b_force_reload = shift || undef;

  if ( !$b_force_reload ) {

    # Defs file tring to load is already loaded.
    if ($self) {
      if ( defined $self->{defs_module_name}
        && $self->{defs_module_name} eq $defs_mod_name )
      {
        return $self->{defs_href};
      }
    } else {
      if ( defined $defs_module_name && $defs_module_name eq $defs_mod_name ) {
        return $info_href;
      }
    }
  } ## end if ( !$b_force_reload )

  # Back up the Defs module name.
  if ($self) {
    $self->{defs_module_name} = $defs_mod_name;
  } else {
    $defs_module_name = $defs_mod_name;
  }

  # my $info_path;
  # if ( $BASE_DIR eq './' ) {
  #   $info_path = $DEFS_DIR . "/" . $DEFS_MOD_NAME . ".pm";
  # } else {
  #   $info_path = $BASE_DIR . "/" . $DEFS_DIR . "/" . $DEFS_MOD_NAME . ".pm";
  # }

  # Unload Defs module.
  if ($b_force_reload) {
    _unload_module($defs_mod_name);
  }
  my $proc = Su::Process->new;
  $proc->load_module($defs_mod_name);

  #  require $defs_mod_name;

  if ($self) {
    $self->{defs_href} = $defs_mod_name->defs;
  } else {
    $info_href = $defs_mod_name->defs;
  }
  return $defs_mod_name->defs;

} ## end sub _load_defs_file

=item setup()

Instead of loading the definition form the Definition file, this method set the definition directly.

 Su::setup(
   menu =>{proc=>'MenuTmpl', model=>qw(main sites about)},
   book_comp =>{proc=>'BookTmpl', model=>'MenuModel'},
   menuWithArg =>{proc=>'MenuTmplWithArg', model=>{field1=>{type=>'string'},field2=>{type=>'number'}}},
  );

=cut

sub setup {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  if ( ref $_[0] eq 'HASH' ) {
    $info_href = shift;
  } else {
    my %h = @_;
    $info_href = \%h;
  }

} ## end sub setup

=item new()

Instantiate the Su instance.
To make Su instance recognize the custom definition module, you can
pass the package name of the definition file as a parameter.

my $su = Su->new;

my $su = Su->new('Pkg::Defs');

my $su = Su->new(defs_module=>'Pkg::Defs');

=cut

sub new {
  my $self = shift;

  if ( scalar @_ == 1 ) {
    my $defs_id = $_[0];
    my $tmp_ref = \$defs_id;
    if ( ref $tmp_ref eq 'SCALAR' ) {
      return bless { defs_module => $defs_id }, $self;
    }
    croak "invalid new parameter:" . @_;
  } ## end if ( scalar @_ == 1 )
  else {
    my %h = @_;
    return bless \%h, $self;
  }

} ## end sub new

=item resolve()

Find the passed id from the definition file and execute the
corresponding Process after the injection of the corresponding Model to
the Process.

An example of the definition in F<Defs.pm> is like the following.

 my $defs =
   {
    entry_id =>
    {
     proc=>'Pkg::SomeProc',
     model=>'Pkg::SomeModel',
    },
   };

Note that C<proc> field in the definition file is required, but
C<model> field can omit. To execute the process descired in this
example, your code will become like the following.

 my $ret = $su->resolve('entry_id');

If you pass the additional parameters to the resolve method, these
parameters are passed to the C<process> method of the Process.

 my $ret = $su->resolve('entry_id', 'param_A', 'param_B');

If the passed entry id is not defined in Defs file, then the error is thorwn.

Definition can be also specified as a parameter of the C<resolve> method like the following.

   $su->resolve({
     proc=>'MainProc',
     model=>['Model01','Model02','Model03'],
    });

  $su->resolve(
  {
    proc  => 'Sample::Procs::SomeModule',
    model => { key1 => { 'nestkey1' => ['value'] } },
  },
  'arg1',
  'arg2');

B<Optional Usage - Model Definition>

This method works differently according to the style of the model definition.

If the C<model> field is a string, then Su treat it as a name of the Model, load
it's class and set it's C<model> field to the Process.

 some_entry_id =>{proc=>'ProcModule', model=>'ModelModule'},

If the C<model> field is a hash, Su set it's hash to the C<model> field of
the Process directly.

 some_entry_id =>{proc=>'ProcModule', model=>{key1=>'value1',key2=>'value2'}},

If the C<model> field is a reference of the string array, then Su load each
element as Model module and execute Process with each model.

 some_entry_id =>{proc=>'TmplModule', model=>['ModelA', 'ModelB', 'ModelC']},

In this case, Process is executed with each Model, and the array of
each result is returned.

B<Optional Usage - Filters>

If a definition has any filter related fields, then these filter
methods are applied before Su return the result of the process method.
The module specified as a filter must has the method which corresponds
to the filter type.  About usable filter types, see the section of
C<map_filter>, C<reduce_filter>, C<scalar_filter>.

These filter methods receive the result of the process or previous
filter as a parameter, and return the filtered result to the caller or
next filter.

Following is an example of the definition file to use post filter.

 my $defs =
   {
    exec_post_filter =>
    {
     proc=>'MainProc',
     model=>['Model01','Model02','Model03'],
     post_filter=>'FilterProc'
    },

Multiple filters can be set to the definition file.

    exec_post_filter_chain =>
    {
     proc=>'MainProc',
     model=>['Model01','Model02','Model03'],
     post_filter=>['FilterProc1', 'FilterProc1']
    }
   };

An example of the C<map_filter> method in the filter class is the following.
The C<map_filter> receives an array of previous result as a parameter and
return the result as an array.

 sub map_filter {
   my $self = shift if ref $_[0] eq __PACKAGE__;
   my @results = @_;
 
   for (@results) {
     # Do some filter process.
   }
   return @results;
 }

An example of the C<reduce_filter> method in the filter class is the
following.  The C<reduce_filter> receives an array as a parameter and
return the result as a scalar.

 sub reduce_filter {
   my $self = shift if ref $_[0] eq __PACKAGE__;
   my @results = @_;
 
   # For example, just join the result and return.
   return join( ',', @results );
 }

An example of the C<scalar_filter> method in the filter class is the
following.  The C<scalar_filter> receives a scalar as a parameter and
return the result as a scalar.

 sub scalar_filter {
   my $self = shift if ref $_[0] eq __PACKAGE__;
   my $result = shift;
 
 # Do some filter process to the $result.
  
   return $result;
 }

This method change the Model file to load by the specified locale.

If you specify the resource locale to $Su::MODEL_LOCALE, this method
load locale specific Model automatically,  and locale specific Model
is not exist, then this method tring to load default Model.

Set the locale variable like the following:

  $Su::MODEL_LOCALE = 'ja_JP';

The name of locale specific Model is like the following:

  pkg::SomeModel__ja_JP

And the file name becomes like this.

  pkg/SomeModel__ja_JP.pm

=cut

sub resolve {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $comp_id = shift;
  my @ctx     = @_;

  my ( $info_href, $new_comp_id ) =
    ( $self && eval { $self->isa('Su') } )
    ? $self->_get_info($comp_id)
    : _get_info($comp_id);
  $comp_id = $new_comp_id if $new_comp_id;

# If Su->{base} is specified, this effects to Template and Model, else used own value Template and Model has.
  my $BASE_DIR = $self->{base};
  my $MODEL_DIR = $self->{model} ? $self->{model} : $Su::Model::MODEL_DIR;
  my $TEMPLATE_DIR =
    $self->{template} ? $self->{template} : $Su::Template::TEMPLATE_DIR;

  my $proc = Su::Process->new( base => $BASE_DIR, dir => $TEMPLATE_DIR );
  my $proc_id = $info_href->{$comp_id}->{proc};
  croak 'proc not set in '
    . (
      $self->{defs_module_name}
    ? $self->{defs_module_name} . ":${comp_id}"
    : 'the passed definition'
    )
    . '.'
    unless $proc_id;
  my $tmpl_module = $proc->load_module($proc_id);

  # Save executed module to the instance.
  $self->{module} = $tmpl_module if $self;

  my @ret_arr = ();

  # Still not refactored!

  # If the setter method of the field 'model' exists.
  if ( $tmpl_module->can('model') ) {

    # model is hash reference. so pass it direct.
    if ( ref $info_href->{$comp_id}->{model} eq 'HASH' ) {
      $tmpl_module->model( $info_href->{$comp_id}->{model} );
    } elsif ( ref $info_href->{$comp_id}->{model} eq 'ARRAY' ) {

    } else {

      # this should be model class name.

      my $mdl = Su::Model->new( base => $BASE_DIR, dir => $MODEL_DIR );
      my $loading_model = $info_href->{$comp_id}->{model};
      chomp $loading_model;

      # Add locale postfix if postfix is specified.
      my $base_loading_model = $loading_model;
      $loading_model .= '__' . $Su::MODEL_LOCALE if ($Su::MODEL_LOCALE);

      # If locale specific model is not exist, then load default model file.
      Su::Log->trace( 'loading model:' . $loading_model );
      if ($loading_model) {
        my $model = $mdl->load_model( $loading_model, { suppress_error => 1 } );
        $model = $mdl->load_model($base_loading_model) unless $model;

        # Load global field from Defs file.
        %{$model} = ( %{$model}, %{ $info_href->{$GLOBAL_MODEL_FIELD} } )
          if defined $info_href->{$GLOBAL_MODEL_FIELD};

        # Get the prefix or postfix setting for loading model.
        my $MODEL_KEY_PREFIX  = $MODEL_KEY_PREFIX->{$loading_model}  || '';
        my $MODEL_KEY_POSTFIX = $MODEL_KEY_POSTFIX->{$loading_model} || '';

        # If the key prefix or postfix is specified, copy the value of the
        # modified key to original key value.
        if ( $MODEL_KEY_PREFIX || $MODEL_KEY_POSTFIX ) {
          my $new_model = {};
          foreach my $key ( keys %{$model} ) {
            if (
              exists $model->{ $MODEL_KEY_PREFIX . '__' 
                  . $key . '__'
                  . $MODEL_KEY_POSTFIX } )
            {
              $new_model->{$key} =
                $model->{ $MODEL_KEY_PREFIX . '__' 
                  . $key . '__'
                  . $MODEL_KEY_POSTFIX };
            } elsif ( exists $model->{ $MODEL_KEY_PREFIX . '__' . $key } ) {
              $new_model->{$key} = $model->{ $MODEL_KEY_PREFIX . '__' . $key };
            } elsif ( exists $model->{ $key . '__' . $MODEL_KEY_POSTFIX } ) {
              $new_model->{$key} = $model->{ $key . '__' . $MODEL_KEY_POSTFIX };
            } else {
              $new_model->{$key} = $model->{$key};
            }
          } ## end foreach my $key ( keys %{$model...})
          $model = $new_model;
        } ## end if ( $MODEL_KEY_PREFIX...)
        $tmpl_module->model($model);

      } ## end if ($loading_model)
    } ## end else [ if ( ref $info_href->{...})]
  } ## end if ( $tmpl_module->can...)

  # Just return proc instance.
  if ( $self->{just_return_module} ) {
    return $tmpl_module;
  }

  if ( $tmpl_module->can('model') ) {
    if ( ref $info_href->{$comp_id}->{model} eq 'ARRAY' ) {

      # Call module method with each of models.
      my $mdl = Su::Model->new( base => $BASE_DIR, dir => $MODEL_DIR );

      for my $loaded_model ( @{ $info_href->{$comp_id}->{model} } ) {

        #diag("model:" . $info_href->{$comp_id}->{model});
        #diag("loaded:" . $mdl->load_model($info_href->{$comp_id}->{model}));
        chomp $loaded_model;
        if ($loaded_model) {
          $tmpl_module->model( $mdl->load_model($loaded_model) );
          push @ret_arr, $tmpl_module->process(@ctx);
        }
      } ## end for my $loaded_model ( ...)

    } ## end if ( ref $info_href->{...})
  } ## end if ( $tmpl_module->can...)

  my @filters = ();
  my $reduce_filter;
  my @scalar_filters = ();

  # Collect post filters.
  if ( $info_href->{$comp_id}->{map_filter} ) {

    # The single filter is set as class name string.
    if ( ref $info_href->{$comp_id}->{map_filter} eq '' ) {
      push @filters, $info_href->{$comp_id}->{map_filter};
    } elsif ( ref $info_href->{$comp_id}->{map_filter} eq 'ARRAY' ) {

      # The filters are set as array reference.
      @filters = @{ $info_href->{$comp_id}->{map_filter} };
    }

  } ## end if ( $info_href->{$comp_id...})

  # Collect reduce filter.
  # Note:Multiple reduce filter not permitted to set.
  if ( $info_href->{$comp_id}->{reduce_filter} ) {

    # The single filter is set as class name string.
    if ( ref $info_href->{$comp_id}->{reduce_filter} eq '' ) {
      $reduce_filter = $info_href->{$comp_id}->{reduce_filter};
    }
  } ## end if ( $info_href->{$comp_id...})

  # Collect scalar filters
  if ( $info_href->{$comp_id}->{scalar_filter} ) {

    # The single filter is set as class name string.
    if ( ref $info_href->{$comp_id}->{scalar_filter} eq '' ) {
      push @scalar_filters, $info_href->{$comp_id}->{scalar_filter};
    } elsif ( ref $info_href->{$comp_id}->{scalar_filter} eq 'ARRAY' ) {

      # The filters are set as array reference.
      @scalar_filters = $info_href->{$comp_id}->{scalar_filter};
    }

  } ## end if ( $info_href->{$comp_id...})

  # Multiple data process return it's result array.
  if (@ret_arr) {
    for my $elm (@filters) {
      my $tmpl_filter_module =
        $proc->load_module( $info_href->{$comp_id}->{map_filter} );
      @ret_arr = $tmpl_filter_module->map_filter(@ret_arr);
    }

#Todo: Multiple data process not implemented to apply reduce filter and scalar filter.
    return @ret_arr;
  } ## end if (@ret_arr)

  my @single_ret_arr = ( $tmpl_module->process(@ctx) );

  # Apply map filters.
  for my $elm (@filters) {
    my $tmpl_filter_module = $proc->load_module($elm);
    @single_ret_arr = $tmpl_filter_module->map_filter(@single_ret_arr);
  }

  return ( scalar @single_ret_arr == 1 ? $single_ret_arr[0] : @single_ret_arr )
    unless ( $reduce_filter or @scalar_filters );

  my $reduced_result = '';

  # Apply reduce filter once.
  if ($reduce_filter) {
    my $reduce_filter_module = $proc->load_module($reduce_filter);
    $reduced_result = $reduce_filter_module->reduce_filter(@single_ret_arr);
  } elsif ( scalar @single_ret_arr == 1 ) {
    $reduced_result = $single_ret_arr[0];
  } else {
    croak
"[ERROR]Can't apply scalar filter(s), because the result of the process is multiple and not reduced by the reduce filter";
  }

  #Apply scalar filter to the single process result.
  for my $elm (@scalar_filters) {
    my $tmpl_filter_module = $proc->load_module($elm);
    $reduced_result = $tmpl_filter_module->scalar_filter($reduced_result);
  }
  return $reduced_result;

} ## end sub resolve

=begin comment

Read Process and Model infomation from Defs file.

=end comment

=cut

sub _get_info {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $comp_id = shift;
  my $info_href;

  # If the flag $USE_GLOBAL_SETUP is set, use the setting set by the
  # method Su::setup.
  if ($USE_GLOBAL_SETUP) {
    $info_href = $Su::info_href;
  } elsif ( $self
    && UNIVERSAL::isa( $self, 'UNIVERSAL' )
    && $self->isa('Su') )
  {

    # If hash is passed, just use passed info, and not load defs file.
    $self->_load_defs_file( $self->{defs_module} )
      unless ref $comp_id eq 'HASH';
  } else {

    # called as global method like 'Su::resolve("id")'.
    unless ( ref $comp_id eq 'HASH' ) {

      # If Su::setup is called, then use global setting, else load setting
      # from defs file.
      $info_href =
        keys %{$Su::info_href} ? $Su::info_href : _load_defs_file();

      # _load_defs_file();
      Su::Log->trace( 'comp_id:' . $comp_id );
      Su::Log->trace( 'new set:' . Dumper($info_href) );
    } ## end unless ( ref $comp_id eq 'HASH')

    # _load_defs_file();
  } ## end else [ if ($USE_GLOBAL_SETUP)]

  # If defs info is passed as paramter, then use it.
  if ( ref $comp_id eq 'HASH' ) {
    $info_href = { 'dmy_id' => $comp_id };

    # Set dummy id to use passed parameter.
    $comp_id = 'dmy_id';
  } elsif ( !$info_href ) {

    # $self->{defs_href} and $Su::info_href is set by _load_defs_file().
    $info_href = $self->{defs_href} ? $self->{defs_href} : $Su::info_href;
  }

  if (
    !$info_href->{$comp_id}
    || !(
      ref $info_href->{$comp_id} eq 'HASH' && keys %{ $info_href->{$comp_id} }
    )
    )
  {
    croak "Entry id '$comp_id' is  not found in Defs file:"
      . Dumper($info_href);
  } ## end if ( !$info_href->{$comp_id...})

  return ( $info_href, $comp_id eq 'dmy_id' ? $comp_id : 0 );

} ## end sub _get_info

=item get_proc()

This function is just a synonym of the method L<get_instance>.

=cut

sub get_proc {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $ret;
  if ($self) {
    $ret = $self->get_instance(@_);
  } else {
    $ret = get_instance(@_);
  }
  return $ret;
} ## end sub get_proc

=item

Just return the instance of the Process which defined in Defs
file. Model data is set to that returned Process.

  my $proc = $su->get_instance('main_proc');

=cut

sub get_instance {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $comp_id = shift;

  # just_return_module is a flag not to execute process and just return
  # the instance of the process itself.
  $self->{just_return_module} = 1;
  my $proc = $self->resolve($comp_id);
  $self->{just_return_module} = undef;
  return $proc;
} ## end sub get_instance

=item get_inst()

This function is just a synonym of the method L<get_instance>.

=cut

sub get_inst {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $ret;
  if ($self) {
    $ret = $self->get_instance(@_);
  } else {
    $ret = get_instance(@_);
  }
  return $ret;
} ## end sub get_inst

=item retr()

This function is just a synonym of the method L<get_instance>.

=cut

sub retr {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $ret;
  if ($self) {
    $ret = $self->get_instance(@_);
  } else {
    $ret = get_instance(@_);
  }
  return $ret;
} ## end sub retr

=item inst()

This function is just a synonym of the method L<get_instance>.

=cut

sub inst {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $ret;
  if ($self) {
    $ret = $self->get_instance(@_);
  } else {
    $ret = get_instance(@_);
  }
  return $ret;
} ## end sub inst

=item init()

Generate the initial files at once. The initial files are composed of
Defs, Model and Process module.

 Su::init('PkgName');

This method can be called from command line like the following:

 perl -MSu=base,base/directory -e 'Su::init("Pkg::SomeModule")'

=cut

sub init {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $pkg = shift;

  die "The parameter package name is requqired." unless $pkg;

# Note that the package of defs file is fixed and don't reflect the passed package name.
  no warnings qw(once);
  if ($self) {

# The method 'init' use the fixed module and method name. Only the package name can be specified.
    $self->gen_defs( package => $pkg );
    $self->gen_model("${pkg}::${DEFAULT_MODEL_NAME}");
    $self->gen_proc("${pkg}::${DEFAULT_PROC_NAME}");
  } else {
    gen_defs( package => $pkg );
    gen_model("${pkg}::Model");
    gen_proc("${pkg}::MainProc");

  } ## end else [ if ($self) ]

} ## end sub init

=item gen_model()

Generate a Model file.

 Su::gen_model("SomePkg::SomeModelName")

 perl -MSu=base,./lib/ -e 'Su::gen_model("Pkg::ModelName")'

=cut

sub gen_model {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $BASE_DIR = $self->{base} ? $self->{base} : $BASE_DIR;
  my $mdl = Su::Model->new( base => $BASE_DIR );
  $mdl->generate_model(@_);

} ## end sub gen_model

=item gen_proc()

Generate a Process file.

 perl -MSu=base,./lib/ -e 'Su::gen_proc("Pkg::TestProc")'

=cut

sub gen_proc {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $BASE_DIR = $self->{base} ? $self->{base} : $BASE_DIR;
  my $proc = Su::Process->new( base => $BASE_DIR );
  $proc->generate_proc(@_);

  # my $generated_file = $proc->generate_proc(@_);

} ## end sub gen_proc

=item generate()

Generate a pair of Process and Model file.

  my $su = Su->new;
  $su->generate('pkg::SomeProc');

This example generates C<pkg/SomeProc.pm> and C<pkg/SomeModl.pm>.

You can use this method from the commandline.

  perl -MSu=base,lib -e 'Su::generate("Pkg::SomeProc", 1)'
  perl -MSu=base,lib -e 'Su::generate("Pkg::SomeProc", "Defs::MyDefs")'

If the second parameter is specified, the Defs file will generated.

=cut

sub generate {
  my $self    = shift if ( ref $_[0] eq __PACKAGE__ );
  my $fqcn    = shift;
  my $gen_def = shift;

  # Save original fqcn.
  my $proc_fqcn = $fqcn;
  my $model_fqcn;

  return unless $fqcn;

  # Generate process.
  my $proc_fname = $self ? $self->gen_proc($fqcn) : gen_proc($fqcn);

  # Check whether the parameter has the postfix 'Proc'.
  if ( $fqcn =~ /.+Proc$/ ) {

    # Replace 'Proc' postfix to 'Model' to generate Model file.
    $fqcn =~ s/(.+)Proc$/$1Model/;
  } else {

    # Just add the postfix 'Model' to the passed param.
    $fqcn .= "Model";
  }
  $model_fqcn = $fqcn;

  # Generate model.
  my $model_fname = $self ? $self->gen_model($fqcn) : gen_model($fqcn);

  $proc_fname =~ s/\.pm$//;
  $proc_fname =~ s!/!::!g;

  $model_fname =~ s/\.pm$//;
  $model_fname =~ s!/!::!g;

  my $defs_fname = _is_string($gen_def) ? $gen_def : 'Defs::Defs';

  # Generate defs file.
  if (
    $gen_def
    || (
      $self ? $self->_is_defs_exist($defs_fname) : _is_defs_exist($defs_fname) )
    )
  {
    my @pkg_arr = split( '::', $fqcn );
    my $pkg = @pkg_arr[ 0 .. ( scalar @pkg_arr - 2 ) ];

    if ($self) {
      $self->gen_defs(
        name => $defs_fname,

        # package => $pkg,
        proc                                 => $proc_fqcn,
        model                                => $model_fqcn,
        just_add_entry_if_defs_already_exist => 1,
        use_proc_name_as_entry_id            => 1,
      );

      # $self->gen_defs( package => $defs_fname );
    } else {
      gen_defs(
        name => $defs_fname,

        # package => $pkg,
        proc                                 => $proc_fqcn,
        model                                => $model_fqcn,
        just_add_entry_if_defs_already_exist => 1,
        use_proc_name_as_entry_id            => 1,
      );

    } ## end else [ if ($self) ]
  } ## end if ( $gen_def || ( $self...))
  else {
    my $entry_id = _make_entry_id($proc_fqcn);
    my $output   = <<"__HERE__";
An example of the entry to add to the Defs file.

  $entry_id => {
    proc  => '$proc_fqcn',
    model => '$model_fqcn',
  },
__HERE__

    print $output;
  } ## end else [ if ( $gen_def || ( $self...))]
} ## end sub generate

=item gen_defs()

Generate a definition file.

 perl -MSu=base,./lib/ -e 'Su::gen_defs()'

You can specify the package name of the definition file as a parameter.

 gen_defs('Defs::Defs');

Also you can specify other parameters as a hash.

 gen_defs(name=>'Defs::Defs',
          package=>'pkg',
          proc=>'MyProc',
          model=>'MyModel',
          just_add_entry_if_defs_already_exist => 1,
          use_proc_name_as_entry_id            => 1)

param use_proc_name_as_entry_id:
Set the proc name as entry id instead of default id 'main'.

param just_add_entry_if_defs_already_exist:
If the specified Defs file is already exist, then add the entry to that Defs file.

return:
1: If generation success.
0: If the Defs file already exists.

=cut

sub gen_defs {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $ret =
      $self
    ? $self->_gen_defs_with_template_id( 'DefsPm', @_ )
    : _gen_defs_with_template_id( 'DefsPm', @_ );

  # Exclude the case of single parameter.
  if ( scalar @_ != 1 ) {
    my %defs_h = @_;
    if ( $ret == 0 && !$defs_h{just_add_entry_if_defs_already_exist} ) {
      warn "[WARN] Defs file alredy exists.";
    }
  } ## end if ( scalar @_ != 1 )
  return $ret;

} ## end sub gen_defs

=begin comment

param template_id: File name to load template string.
return:
  1: If generation success.
  0: If the Defs file already exists.

=end comment

=cut

sub _gen_defs_with_template_id {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $template_id = shift;
  my $template_string;
  use File::Basename;

  my $template_fname =
    dirname(__FILE__) . $SU_TMPL_DIR . $template_id . '.tmpl';

  open( my $F, '<', $template_fname ) or die $! . ":$template_fname";
  $template_string = join '', <$F>;

  return $self
    ? $self->_gen_defs_internal( $template_string, @_ )
    : _gen_defs_internal( $template_string, @_ );
} ## end sub _gen_defs_with_template_id

=begin comment

param1: Template string to expand.
return:
  1: If generation success.
  0: If the Defs file already exists.

=end comment

=cut

sub _gen_defs_internal {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $template_string = shift;
  my $defs_id;
  my %defs_h;

  # The single parameter is Defs file name.
  if ( scalar @_ == 1 ) {
    $defs_id = shift || $DEFS_MODULE_NAME;
  } else {

    # Else the hash of parameters.
    %defs_h = @_;

    $defs_id = $defs_h{name} || $defs_h{file_name} || $DEFS_MODULE_NAME;

  } ## end else [ if ( scalar @_ == 1 ) ]

  my $BASE_DIR = $self->{base} ? $self->{base} : $BASE_DIR;
  my $DEFS_DIR = $self->{defs} ? $self->{defs} : $DEFS_DIR;

  # Make directory path.
  my @arr = split( '/|::', $defs_id );
  my $defs_base_name = '';
  if ( scalar @arr > 1 ) {
    $defs_base_name = join( '/', @arr[ 0 .. scalar @arr - 2 ] );
  }

  my $dir;
  if ( $defs_id =~ /::|\// ) {
    $dir = $BASE_DIR . "/" . $defs_base_name;
  } else {
    $dir = $BASE_DIR . "/" . $DEFS_DIR . "/" . $defs_base_name;
  }

  # Prepare directory for generate file.
  mkpath $dir unless ( -d $dir );

  if ( !-d $dir ) {
    die "Can't make dir:" . $!;
  }

  my $defs_id_filepath = $defs_id;
  $defs_id_filepath =~ s!::!/!g;

  # Generate file.
  my $fpath;
  if ( $defs_id =~ /::|\// ) {
    $fpath = $BASE_DIR . "/" . $defs_id_filepath . ".pm";
  } else {
    $fpath = $BASE_DIR . "/" . $DEFS_DIR . "/" . $defs_id_filepath . ".pm";
  }

  $defs_id =~ s/\//::/g;

  if ( $defs_id !~ /::/ ) {
    my $defs_dir_for_package = $DEFS_DIR;
    $defs_dir_for_package =~ s!/!::!g;

    #Note: Automatically add the default package Models.
    $defs_id = $defs_dir_for_package . '::' . $defs_id;
  } ## end if ( $defs_id !~ /::/ )

  my $defs_proc_name  = $defs_h{proc}    || $DEFAULT_PROC_NAME;
  my $defs_model_name = $defs_h{model}   || $DEFAULT_MODEL_NAME;
  my $pkg             = $defs_h{package} || $defs_h{pkg} || "";
  my $main_entry_id = 'main';

  # If the Defs file is already exist.
  if ( -f $fpath ) {

    # Add the entry to the Defs file which already exists.
    if ( $defs_h{just_add_entry_if_defs_already_exist} ) {

      my $entry_id = _make_entry_id($defs_proc_name);
      open( my $I, $fpath );
      my $content = join '', <$I>;
      close $I;
      my $tmpl_str = <<"__HERE__";
   ,
   ${entry_id} =>
   {
    proc=>"${pkg}${defs_proc_name}",
    model=>"${pkg}${defs_model_name}",
   },
__HERE__

      $content =~ s/(# \[The mark to add the entries\])/$tmpl_str\n$1/;

      open( my $FO, '>', $fpath );
      print $FO $content;
      close $FO;
    } else {

      # Do Nothing.
    }
    return 0;
  } ## end if ( -f $fpath )

  # Make entry id.
  if ( $defs_h{use_proc_name_as_entry_id} ) {
    $main_entry_id = _make_entry_id($defs_proc_name);
  }

  open( my $file, '>', $fpath );

  my $ft = Su::Template->new;

  use Data::Dumper;

  # Make package name, else remain empty.
  $pkg = $pkg ? ( $pkg . '::' ) : '';

  my $contents =
    $ft->expand( $template_string, $defs_id, $pkg, $defs_proc_name,
    $defs_model_name, $main_entry_id );

  print $file $contents;
  return 1;

} ## end sub _gen_defs_internal

=begin comment

Return 1 if the type of the passed argment is a string.
If the parameter type is a number or reference then this method return 0.
If the string "true" is passed, this method return 0;

=end comment

=cut

sub _is_string {
  my $arg = shift;
  if ( $arg && ( $arg ^ $arg ) ne '0' && !( ref $arg ) && $arg ne 'true' ) {
    return 1;
  } else {
    return 0;
  }

} ## end sub _is_string

=begin comment

Extract the class name from the passed parameter and make lower case it's firsr charactor.

param: The string of fully qualified name.
return: The class name converted to lower case of it's first charactor.

=end comment

=cut

sub _make_entry_id {
  my $arg = shift;
  my @name_elem = split( '::', $arg );
  return lcfirst $name_elem[ scalar @name_elem - 1 ];

} ## end sub _make_entry_id

=begin comment

Return 1 if passed argument is reference of empty hash.
Note that if argument type is not reference, then return 1;
Non-hash type parameter also return 1.

Note: Currently not used.

=end comment

=cut

# sub is_hash_empty {
#   my $self = shift if ( ref $_[0] eq __PACKAGE__ );
#   my $href = shift;
#   return 1 if ( !$href );
#   if ( ref $href eq 'HASH' ) {
#     if ( keys %{$href} ) {
#       return 0;
#     } else {
#       return 1;
#     }
#   } ## end if ( ref $href eq 'HASH')
#   return 1;
# } ## end sub is_hash_empty

=begin comment

Unload the passed module.

  _unload_module('Defs::Defs.pm');

=end comment

=cut

sub _unload_module {
  my $self       = shift if ( ref $_[0] eq __PACKAGE__ );
  my $fqmn       = shift;
  my @path_elems = split '::', $fqmn;

  {
    no strict 'refs';
    @{ $fqmn . '::ISA' } = ();
    %{ $fqmn . '::' }    = ();
    delete ${ ( join '::', @path_elems[ 0 .. $#path_elems - 1 ] ) . '::' }
      { $path_elems[-1] . '::' };
    delete $INC{ ( join '/', @path_elems ) . '.pm' };
  }

} ## end sub _unload_module

=begin comment

Return true if the Defs file is exist.

param: Defs module name or file path.

return:
 1: If the Defs file exist.
 undef: If the Defs file not exist.

=end comment

=cut

sub _is_defs_exist {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $defs_id = shift || $DEFS_MODULE_NAME;

  my $BASE_DIR = $self->{base} ? $self->{base} : $BASE_DIR;
  my $DEFS_DIR = $self->{defs} ? $self->{defs} : $DEFS_DIR;

  my $defs_id_filepath = $defs_id;
  $defs_id_filepath =~ s/::/\//;
  my $fpath;
  if ( $defs_id =~ /::|\// ) {
    $fpath = $BASE_DIR . "/" . $defs_id_filepath . ".pm";
  } else {
    $fpath = $BASE_DIR . "/" . $DEFS_DIR . "/" . $defs_id_filepath . ".pm";
  }
  return -f $fpath;
} ## end sub _is_defs_exist

1;

__END__

=back

=head1 SEE ALSO

L<Su::Process|Su::Process>,L<Su::Model|Su::Model>,L<Su::Template|Su::Template>,L<Su::Log|Su::Log>

=head1 AUTHOR

lottz <lottzaddr@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

