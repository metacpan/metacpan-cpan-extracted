package Solstice::Model;

# $Id: Model.pm 2393 2005-07-18 17:12:40Z pmichaud $

=head1 NAME

Model - The superclass for all Solstice data models.

=head1 SYNOPSIS

  package Model;

  use Model;
  our @ISA = qw(Model);

  sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    return $self;
  }

  sub store {
    my $self = shift;
    my $retval = FALSE;

    return TRUE unless $self->_isTainted;

    # pseudocode...
    my $datastore = MyDatastore->new;

    if ($datastore->put($self)) {
      $self->_setID($datastore->get_last_id);
      $self->_untaint;
      $retval = TRUE;
    }

    return $retval;
  }

  sub delete {
    my $self = shift;
    my $retval = FALSE;

    # pseudocode...
    my $datastore = MyDatastore->new;

    if ($datastore->remove($self)) {
      $self->_setID(undef);
      $retval = TRUE;
    }

    return $retval;
  }

  sub clone {
    my $self = shift;
    my $clone = $self->SUPER::clone(@_);

    return $clone;
  }

=head1 DESCRIPTION

This should be used by all models in Solstice.  It provides some basic application
functionality, such as getting and setting ids, managing taintedness, cloning,
and store() and delete() stubs.

Here taintedness describes whether or not the object has been altered since it
was loaded from the datastore.  New, "blank" object are tainted.  New objects
loaded from a datastore are not.  Set-accessors and other methods that alter the
object should use the _taint() method.  The store() method can use the
_isTainted() method for optimization -- there's no reason to do the work of
storing the object if it hasn't changed.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Carp qw(cluck confess);
use Class::ISA;
use Devel::Symdump;


use Solstice::ConfigService;
use Solstice::SearchField;
use Solstice::Search;

use constant TRUE  => 1;
use constant FALSE => 0;

use vars qw($AUTOLOAD);

our ($VERSION) = ('$Revision: 2393 $' =~ /^\$Revision:\s*([\d.]*)/);
our $has_sub_name = FALSE;

BEGIN {
    eval {
        require Sub::Name;
    };
    if ($@) {
        $has_sub_name = FALSE;
    }
    else {
        $has_sub_name = TRUE;
    }
}

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructor; should only be called by a subclass.  Returns a Model object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_initAttributes();

    return $self;
}

=item getClassName()

Return the class name for the model. This method should be sub-classed to
avoid using ref().

=cut

sub getClassName {
    my $self = shift;
    return ref $self;
}

=item getErrorMessages()

Returns a reference to a list of error strings.

=cut

sub getErrorMessages {
    my $self = shift;
    return $self->{'_error_messages'} || []; 
}

=item clearErrorMessages()

Empty the list of error strings.

=cut

sub clearErrorMessages {
    my $self = shift;
    $self->{'_error_messages'} = []; 
}


=item store()

This is a stub method, expected to be implemented by a subclass.  It
serializes the object to some datastore and assigns to the object an ID local to
that datastore.  Returns true upon success, false otherwise.

=cut

sub store {
    my $self = shift;
    cluck ref($self) . '->store(): Not implemented';    
    return FALSE;
}

=item delete()

This is a stub method, expected to be implemented by a subclass.  It removes
this object from a datastore and clears the object's ID.  It does not, however,
reinitialize this object, destroy it, or undefine it; only it's ID is undefined.
Returns true upon success, false otherwise.

=cut

sub delete {
    my $self = shift;
    cluck ref($self) . '->delete(): Not implemented';
    return FALSE;
}

=item clone()

Returns a deep copy of this object, without any IDs.

=cut

sub clone {
    my $self = shift;
    cluck ref($self) . '->clone(): Not implemented';
    return FALSE;
}

=item processPersistenceValues ($exception_hash_ref)

Takes all persistence values and stores them into the model, except
those specified by the exception list.  Only works for models with
public sets.

    $self->processPersistenceValues({
        method_3 => TRUE,
        method_6 => TRUE,
    });

=cut

sub processPersistenceValues {
    my $self = shift;
    my $exceptions = shift || {};

    for my $name (keys %{$self->{'_persistence'}}) {
        next if exists $exceptions->{$name};  

        my $function = 'set'.$name;
        $self->$function($self->{'_persistence'}->{$name}) if $self->can($function);
    }
    return TRUE;
}

=item clearPersistenceValues()

Removes all persistence values for this model, to make it easy to revert.

=cut

sub clearPersistenceValues {
    my $self = shift;
    $self->{'_persistence'} = {};
    return TRUE;
}




=item createSearchField($name, $content)

Creates a search field with the given name and content.
Returns the search field object so you can set further options.
See the Solstice::SearchField API

=cut

sub createSearchField {
    my ($self, $name, $content) = @_;

    $self->_loadSearchLibrary || return;

    $self->{'_solstice_search_fields'} = {} unless defined $self->{'_solstice_search_fields'};

    my $field = Solstice::SearchField->new($name, $content);

    $self->{'_solstice_search_fields'}{$name} = $field;

    return $field;
}

=item storeSearchIndex()

This gathers the values from the searchfields you have created and adds or updates
this model's entry in the index.

=cut

sub storeSearchIndex {
    my $self = shift;

    $self->_loadSearchLibrary || return;
    return unless $self->getID();

    my $search_id = $self->getClassName().'|'.$self->getID();
    my $index_filename = $self->_getSearchIndexFilename();

    my $indexer;
    eval {
        my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en');
        my $create = -d $index_filename ? FALSE : TRUE; #does the index exist?
        $indexer = KinoSearch::InvIndexer->new(
            invindex => $index_filename,
            create   => $create,
            analyzer => $analyzer,
        );


        #Spec the fields we need in the index:
        $indexer->spec_field(
            name        => 'solstice_search_id',
            stored      => 1, boost       => 1,
            indexed     => 1, analyzed    => 0,
            stored      => 1, compressed  => 0,
            vectorized  => 0,
        );

        #model-defined fields
        my @fields = values(%{$self->{'_solstice_search_fields'}});
        for my $field (@fields){
            $indexer->spec_field($field->getOptions());
        }

        #create a document for this object
        my $doc = $indexer->new_doc;
        $doc->set_value('solstice_search_id', $search_id);

        for my $field (@fields){
            $doc->set_value($field->getName(), $field->getContent());
        }

        #get rid of the old one first.
        $indexer->delete_docs_by_term(KinoSearch::Index::Term->new('solstice_search_id', $search_id));
        $indexer->add_doc($doc);
    };

    warn "Indexer failed to index file: ".ref $self. ", with id: ".$self->getID() if $@;
    $indexer->finish();
}

=item createSearch ( $search_string )

Builds a Solstice::Search object that will return objects of this type.

See the Solstice::Search API

=cut

sub createSearch {
    my $self = shift;
    my $query = shift;

    $self->_loadSearchLibrary || return;
    return unless $query;

    my $search;
    eval {
        my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en');
        my $searcher = KinoSearch::Searcher->new(
            invindex    => $self->_getSearchIndexFilename(),
            analyzer    => $analyzer
        );

        $search = Solstice::Search->new();
        $search->_init($query, $searcher);
    };

    warn "KinoSearch failed to build a Search object: $@" if $@;

    return $search;
}

=back

=head2 Private Methods

=over 4

=cut

=item _loadSearchLibrary

Enables graceful failure of searching if the prerequisites are not
installed

=cut

sub _loadSearchLibrary {
    my $self = shift;

    eval {
        $self->loadModule('KinoSearch');
        $self->loadModule('KinoSearch::InvIndexer');
        $self->loadModule('KinoSearch::Analysis::PolyAnalyzer');
        $self->loadModule('KinoSearch::Searcher');
        $self->loadModule('KinoSearch::Index::Term');
        $self->loadModule('KinoSearch::Highlight::Highlighter');
        $self->loadModule('KinoSearch::Search::QueryFilter');
    };

    if($@){
        warn "KinoSearch is not installed - cannot search: $@";
        return FALSE;
    }else{
        return TRUE;
    }
}

=item _getSearchIndexFilename()

Builds the file path used to store search indexes - specific to each model class.

=cut

sub _getSearchIndexFilename {
    my $self = shift;

    my $package_flatten = ref $self || $self;
    $package_flatten =~ s/\:+/_/g;
    my $index_filename = $self->getConfigService()->getDataRoot().'/solstice_search_indexes/';
    $self->_dirCheck($index_filename);
    $index_filename .= $package_flatten;
    return $index_filename;
}


=item _addErrorMessage($string)

Add an error message.

=cut

sub _addErrorMessage {
    my $self = shift;
    my $message = shift;
    return unless defined $message;

    my $messages = $self->{'_error_messages'} || [];
    push @$messages, $message;
    $self->{'_error_messages'} = $messages;
}

=item _taint()

Sets the model as having been changed by user data, and therefore in need of
saving, when a store method is called.  Returns C<undef>.

=cut

sub _taint {
    my $self = shift;
    $self->{'_model_tainted'} = TRUE;
    return;
}

=item _untaint()

Unsets the model as having been tainted.  Returns C<undef>.

=cut

sub _untaint {
    my $self = shift;
    delete $self->{'_model_tainted'};
    return;
}

=item _isTainted()

Returns true if the model has been tainted by user data (as set by _taint()),
false otherwise.

=cut

sub _isTainted {
    my $self = shift;
    return $self->{'_model_tainted'};
}

=item _deprecate()

Sets the model as having been deprecated, and therefore in need of
deletion, when a store method is called.  Returns C<undef>.

=cut

sub _deprecate {
    my $self = shift;
    $self->{'_model_deprecated'} = TRUE;
    return;
}

=item _undeprecate()

Unsets the model as having been deprecated.  Returns C<undef>.

=cut

sub _undeprecate {
    my $self = shift;
    delete $self->{'_model_deprecated'};
    return;
}

=item _isDeprecated()

Returns true if the model has been deprecated (as set by _deprecate()),
false otherwise.

=cut

sub _isDeprecated {
    my $self = shift;
    return $self->{'_model_deprecated'};
}

=item _areEqual($arg1, $arg2)

Returns true if $arg1 and $arg2 are equal, false otherwise.

=cut

sub _areEqual {
    my $self = shift;
    my ($this, $that) = @_;
  
    my $ref_this = ref($this);
    my $ref_that = ref($that);
    if (!$ref_this and !$ref_that) {
        if (!defined $this || !defined $that) {
            return !defined $this && !defined $that;
        } else {
            return $this eq $that;
        }
    } elsif ($ref_this eq $ref_that) {
        # TODO: implement deep comparison
    }
    
    # Definately not equal...
    return FALSE;
}           

=item _initAttributes()

Initializes attributes and accessor methods for the model. This method also
initializes attributes for any superclasses that haven't already been 
initialized, to ensure that inherited accessors are available to 
nitthe model.

=cut

sub _initAttributes {
    my $self = shift;
    my $service_to_use = shift;

    # We need the || $self for when people do 
    # Package::Name->getValue()
    my $classname = ref $self || $self;

    # Memory service makes it so models are only Devel::Symdumped once per thread
    my $service;

    if($service_to_use){
        $service = $service_to_use;
    }elsif ( $self->getConfigService()->getDevelopmentMode()) {
        $service = Solstice::Service->new();
    }
    else {
        $service = Solstice::Service::Memory->new();
    }

    return TRUE if defined $service->get('init'.$classname);

    for my $class (Class::ISA::self_and_super_path($classname)) {
        next if defined $service->get('init'.$class);
        my $return  = Solstice::Model::_createAttributes($class);
        $service->set('init'.$class, $return);
    }
    
    return TRUE; 
}

=back

=head2 Private Functions 

=over 4

=cut

=item _createAttributes($class)

Creates accessors for $class. Attribute data is fetched using the method
_getAccessorDefinition(), which returns an arrayref. Each element in the
array is a hashref with the format:

  {
    name  => 'Name',    # method name suffix: getName/setName in this example
    key   => '_name',   # object key
    type  => 'String',  # data type, see explanation below
    taint => 0|1,       # public set taints model, false by default
    private_set => 0|1, # specifies that set is private, false by default
    private_get => 0|1, # specifiies that get is private, false by default
  },

The required keys are 'name', 'key', and 'type'. All others are optional.
Acceptable values for 'type' are: Integer, PositiveInteger, Float, String, 
Boolean, ArrayRef, HashRef, List, Tree, Person, DateTime.
Object package names are also ok, when it is desired that an attribute 
accept only a specific class.

If an accessor already exists in the model, it will not be overwritten.

=cut

sub _createAttributes {
    my $class = shift; # This is a string, not self

    return FALSE unless defined $class;

    my %functions = map {$_ => 1} Devel::Symdump->new($class)->functions();
    
    return TRUE unless exists $functions{$class.'::_getAccessorDefinition'};

    my $attributes = eval "${class}::_getAccessorDefinition"; ## no critic

    warn "Couldn't load _getAccessorDefinition for $class: $@" if $@;

    my $invalid_input = "Invalid attribute definitions for class $class\n";
    die "$invalid_input: _getAccessorDefinition output is not a list ref\n" unless Solstice::isValidArrayRef(undef, $attributes);

    # We do this per model, in case a model adds a function to the 
    # Solstice::ModelTemplates namespace for custom validation.
    my %defined_templates = map {$_ => 1} Devel::Symdump->new('Solstice::ModelTemplates')->functions();
    my %existing_names;
    my %existing_keys;

    for my $hashref (@$attributes) {
        die $invalid_input unless Solstice::isValidHashRef(undef, $hashref);

        my $name = $hashref->{'name'};
        my $key  = $hashref->{'key'};
        my $type = $hashref->{'type'};

        if (!defined $key) {
            $key = $name;
        }

        die "$invalid_input: missing or invalid name\n" unless $name;
        die "$invalid_input: missing or invalid type\n" unless $type;
        die "$invalid_input: duplicate name $name\n"    if $existing_names{$name};
        die "$invalid_input: duplicate key $key\n"      if $existing_keys{$key};

        $existing_names{$name} = 1;
        $existing_keys{$key}   = 1;

        my $_private_set = '_privateSet'.$type; 
        unless (exists $defined_templates{"Solstice::ModelTemplates::$_private_set"}) {
            $_private_set = '_privateSetObject'; 
        }

        {   ## no critic
            #can't really do this stuff with strict refs
            no strict 'refs'; 

            my $get = $hashref->{'private_get'} ? '_get' : 'get';
            unless (exists $functions{$class.'::'.$get.$name}) {
                my $get_method = Solstice::ModelTemplates::_publicGet($key);
                if ($has_sub_name) {
                    *{$class.'::'.$get.$name} = subname ("$get$name" => eval "$get_method");
                }
                else {
                    *{$class.'::'.$get.$name} = eval "$get_method";
                }
            }

            unless (exists $functions{$class.'::_set'.$name}) {
                my $_set_method = &{"Solstice::ModelTemplates::$_private_set"}($key, $name, $type);
                if ($has_sub_name) {
                    *{$class.'::_set'.$name} = subname ('_set'.$name => eval "$_set_method");
                }
                else {
                    *{$class.'::_set'.$name} = eval "$_set_method";
                }
            }

            if (!$hashref->{'private_set'} and !exists $functions{$class.'::set'.$name}) {
                my $set_method = $hashref->{'taint'}
                    ? Solstice::ModelTemplates::_publicSetTaint($name, $key)
                    : Solstice::ModelTemplates::_publicSet($name);

                if ($has_sub_name) {
                    *{$class.'::set'.$name} = subname ('set'.$name => eval "$set_method");
                }
                else {
                    *{$class.'::set'.$name} = eval "$set_method";
                }
            }
        }
    }
    return TRUE;
}

=item _getAccessorDefinition()

Returns an array ref containing attribute data. Subclasses will override 
this method to generate specialized accessor methods.

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'ID',
            key  => '_model_id',
            type => 'String',
            private_set => TRUE,
        },
    ];
}

sub AUTOLOAD {
    my $self = shift;
    my @args = @_;

    #no strict "refs"; #Why was this here? We don't do anything bad that I can see...
    
    my $function_name = $AUTOLOAD;
    $function_name =~ s/.*://;

    if ($function_name eq 'DESTROY') {
        return;
    }

    # If we're pulling a model from session, and haven't yet called new, 
    # we need to load the accessor methods.
    # We need the || $self for when people do 
    # Package::Name->madeUpFunction();
    my $classname = ref $self || $self;

    # Memory service makes it so models are only Devel::Symdumped once per thread
    my $service;
    if ($self->getConfigService()->getDevelopmentMode()) {
        $service = Solstice::Service->new();
    }
    else {
        $service = Solstice::Service::Memory->new();
    }
    unless (defined $service->get('init'.$classname)) {
        $self->_initAttributes();
        return $self->$function_name(@args); 
    }

    # Check for a 'persistence' accessor call
    if ($function_name =~ /^([s|g]et)Persistence([\w\W]+)$/) {
        my $get_set = $1;
        my $function = $2;

        if ($get_set eq 'get') {
            if (defined $self->{'_persistence'}->{$function}) {
                return $self->{'_persistence'}->{$function};
            } else {
                $function = $get_set . $function;
                return $self->can($function) ? $self->$function() : undef; 
            }
        } else {
            $self->{'_persistence'}->{$function} = $args[0];
        }
    } else {
        die "Can't locate object method '$function_name' in class '$classname'. Called from ".join(' ', caller)."\n";
    }
}

=back

=head2 Attribute Validation Methods

=over 4

=cut


=back

=head1 Model Templates

Solstice::ModelTemplates - a set of functions that get globbed into subclasses of Model.

=cut

package Solstice::ModelTemplates;

=over 4

=item _publicGet($key)

=cut

sub _publicGet {
    my $key = shift;
    return "sub {
    my \$self = shift;
    return \$self->{'$key'};
    }";
}

=item _publicSet($name, $taint)

=cut

sub _publicSet {
    my $name = shift;
    return "sub {
    my \$self = shift;
    my \$arg  = shift;
    return FALSE unless \$self->_set$name(\$arg);
    return TRUE;
    }";
}

=item _publicSetTaint($name)

=cut

sub _publicSetTaint {
    my ($name, $key) = @_;
    return "sub {
    my \$self = shift;
    my \$arg  = shift;
    return FALSE if \$self->_areEqual(\$self->{'$key'}, \$arg);
    return FALSE unless \$self->_set$name(\$arg);
    \$self->_taint();
    return TRUE;
    }";
}

=item _privateSetNumber($key)

=cut

sub _privateSetNumber {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidNumber(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid number\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetInteger($key)

=cut

sub _privateSetInteger {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidInteger(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid integer\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetPositiveInteger($key)

=cut

sub _privateSetPositiveInteger {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidPositiveInteger(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid positive integer\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetNonNegativeInteger($key)

=cut

sub _privateSetNonNegativeInteger {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidNonNegativeInteger(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid non-negative integer\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetFloat($key)

=cut

sub _privateSetFloat {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidFloat(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid float\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetString($key)

=cut

sub _privateSetString {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidString(\$str) or
    confess \"_set$name(): Argument is not a valid string\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetEmail($key)

=cut

sub _privateSetEmail {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidEmail(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid email\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetURL($key)

=cut

sub _privateSetURL {
    my ($key, $name) = @_;
    return "sub {
        my \$self = shift;
        my \$str  = shift;
        \$self->isValidURL(\$str) or
        confess \"_set$name(): Argument '\$str' is not a valid URL\";
        \$self->{'$key'} = \$str;
        return TRUE;
        }";
    }

=item _privateSetBoolean($key)

=cut

sub _privateSetBoolean {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$str  = shift;
    \$self->isValidBoolean(\$str) or
    confess \"_set$name(): Argument '\$str' is not a valid boolean\";
    \$self->{'$key'} = \$str;
    return TRUE;
    }";
}

=item _privateSetArrayRef($key)

=cut

sub _privateSetArrayRef {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$ref  = shift;
    \$self->isValidArrayRef(\$ref) or
    confess \"_set$name(): Argument is not a valid arrayref\";
    \$self->{'$key'} = \$ref;
    return TRUE;
    }";
}

=item _privateSetHashRef($key)

=cut

sub _privateSetHashRef {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$ref  = shift;
    \$self->isValidHashRef(\$ref) or
    confess \"_set$name(): Argument is not a valid hashref\";
    \$self->{'$key'} = \$ref;
    return TRUE;
    }";
}

=item _privateSetList($key)

=cut

sub _privateSetList {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$list = shift;
    \$self->isValidList(\$list) or
    confess \"_set$name(): Argument is not a valid List object\";
    \$self->{'$key'} = \$list;
    return TRUE;
    }";
}

=item _privateSetTree($key)

=cut

sub _privateSetTree {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$tree = shift;
    \$self->isValidTree(\$tree) or
    confess \"_set$name(): Argument is not a valid Tree object\";
    \$self->{'$key'} = \$tree;
    return TRUE;
    }";
}

=item _privateSetPerson($key)

=cut

sub _privateSetPerson {
    my ($key, $name) = @_;
    return "sub {
    my \$self   = shift;
    my \$person = shift;
    \$self->isValidPerson(\$person) or
    confess \"_set$name(): Argument is not a valid Person object\";
    \$self->{'$key'} = \$person;
    return TRUE;
    }";
}

=item _privateSetGroup($key)

=cut

sub _privateSetGroup {
    my ($key, $name) = @_;
    return "sub {
    my \$self  = shift;
    my \$group = shift;
    \$self->isValidGroup(\$group) or
    confess \"_set$name(): Argument is not a valid Group object\";
    \$self->{'$key'} = \$group;
    return TRUE;
    }";
}

=item _privateSetDateTime($key)

=cut

sub _privateSetDateTime {
    my ($key, $name) = @_;
    return "sub {
    my \$self = shift;
    my \$date = shift;
    \$self->isValidDateTime(\$date) or
    confess \"_set$name(): Argument is not a valid DateTime object\";
    \$self->{'$key'} = \$date;
    return TRUE;
    }";
}

=item _privateSetObject($key, $class)

This creates a generic object accessor, that will validate a ref() of the 
passed arg against $class.

=cut

sub _privateSetObject {
    my ($key, $name, $class) = @_;
    return "sub {
    my \$self = shift;
    my \$obj  = shift;
    \$self->isValidObject(\$obj, '$class') or
    confess \"_set$name(): Argument is not a '$class' object\";
    \$self->{'$key'} = \$obj;
    return TRUE;
    }";
}

1;

__END__

=back

=head2 Modules Used

L<Carp|Carp>,
L<Class::ISA|Class::ISA>,
L<Devel::Symdump|Devel::Symdump>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2393 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
