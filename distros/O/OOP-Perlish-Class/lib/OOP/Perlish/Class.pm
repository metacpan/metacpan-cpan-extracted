#!/usr/bin/perl
# $Id$
# $Author$
# $HeadURL$
# $Date$
# $Revision$
use warnings;
use strict;
{
    ############################################################################################
    ## OOP::Perlish::Class: a Base class for creating Objects that conform to all common OOP
    ## practices, Multiple-Inheritance, Mix-in, Generational-Inheritance, Overriding,
    ## Overloading, Accessor validation, input mutation, singletons, Multitons, etc, etc
    ############################################################################################

    package OOP::Perlish::Class;
    use warnings;
    use strict;
    our $VERSION = '0.45.0';
    use OOP::Perlish::Class::Accessor;
    use Tie::IxHash;
    use Exporter;
    use IO::Handle;

    use constant OOP_PERLISH_CLASS_EMITLEVEL_FATAL   => 0;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_ERROR   => 1;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_WARNING => 2;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_INFO    => 3;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE => 4;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0  => 5;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1  => 6;
    use constant OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2  => 7;

    use Carp qw(carp croak confess cluck);

    our @EXPORT_TAGS = (
                         'emitlevels' => [
                                           'OOP_PERLISH_CLASS_EMITLEVEL_FATAL',   'OOP_PERLISH_CLASS_EMITLEVEL_ERROR',
                                           'OOP_PERLISH_CLASS_EMITLEVEL_WARNING', 'OOP_PERLISH_CLASS_EMITLEVEL_INFO',
                                           'OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE', 'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0',
                                           'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1',  'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2'
                                         ],
                       );

    our @EXPORT_OK = (
                       'OOP_PERLISH_CLASS_EMITLEVEL_FATAL',   'OOP_PERLISH_CLASS_EMITLEVEL_ERROR',
                       'OOP_PERLISH_CLASS_EMITLEVEL_WARNING', 'OOP_PERLISH_CLASS_EMITLEVEL_INFO',
                       'OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE', 'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0',
                       'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1',  'OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2'
                     );

    ############################################################################################
    ## We still use Exporter's import, but we need to clean it up first
    ## doing this via export_fail doesn't work because exporter must see 'our @EXPORT_FAIL'
    ## in the namespace of package being imported; and subclasses would not normally have
    ## re-defined that again and again and again; optionally, we'd @EXPORT = qw(@EXPORT <...>)
    ## which would result in every module cascading the exports down all the way to users
    ## of the object (not just inheritors) which would suck.
    ############################################################################################
    sub import
    {
        my ( $proto, @tags ) = @_;
        my $class = ref($proto) || $proto;

        if( bless( {}, $class )->isa(__PACKAGE__) ) {
            $class->____OOP_PERLISH_CLASS_DERIVED_CLASSES()->{$class} = 1;
        }

        return unless(@tags);

        my %non_import_flags;
        ## XXX: Hash slice assignment for LUT
        @non_import_flags{
            '_emitlevel:error', '_emitlevel:warning', '_emitlevel:info', '_emitlevel:verbose',
            '_emitlevel:debug', '_emitlevel:debug1',  '_emitlevel:debug2'
          }
          = undef;

        for my $tag (@tags) {
            for my $setter_tag ( keys %non_import_flags ) {
                $tag =~ m/ ^ \Q$setter_tag\E $ /gsmx && do {
                    my ( $static_method, $argument ) = split( ':', $tag );
                    if( bless( {}, $class )->can($static_method) ) {
                        $class->$static_method($argument);
                    }
                };
            }
        }

        @tags = grep { !exists( $non_import_flags{$_} ) } @tags;
        return Exporter::import(@tags);
    }

    ############################################################################################
    ## Create a new instance of this class; should not require overloading in derived classes.
    ############################################################################################
    sub new
    {
        my ( $proto, @opts ) = @_;

        ## support either ...( foo => 'bar' ); or ...( { foo => 'bar' } );
        my %opts =
            ( @opts == 1 ) ? ( ( ref( $opts[0] ) eq 'HASH' ) ? %{ $opts[0] } : () )
          : ( scalar @opts % 2 == 0 ) ? @opts
          :                             confess('Invalid number or type of arguments to constructor');

        my $class = ref($proto) || $proto;
        my $self = {};

        # obtain the @ISA for whomever inherited us
        no strict 'refs';
        @{ $self->{____CLASS_ISA} } = @{ $class . '::ISA' };
        use strict 'refs';

        #for my $parent_class ( @{ $self->{____CLASS_ISA} } ) {
        #    bless( $self, $parent_class );
        #}

        bless( $self, $class ); ## Bless so we can call _all_isa
        for my $parent_class ( $self->_all_isa() ) {
            bless( $self, $parent_class );
        }
        bless( $self, $class ); ## Bless back into this class last so we deref correctly
        $self = $self->____initialize_object(%opts);

        return $self;
    }

    ############################################################################################
    ## Get an immutable copy of the underlying data
    ############################################################################################
    sub get(@)
    {
        my ( $self, $field ) = @_;

        $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->self($self);
        return $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->value();
    }

    ############################################################################################
    ## Set (and validate) an immutable copy, return the validated data.
    ############################################################################################
    sub set(@)    ## no critic (AmbiguousNames)
    {
        my ( $self, $field, @values ) = @_;

        $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->self($self);
        return $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->value(@values);
    }

    ############################################################################################
    ## return true if the value has been set before (even if set to undef)
    ############################################################################################
    sub is_set(@)
    {
        ## use critic
        my ( $self, $field ) = @_;

        $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->self($self);
        ### Accessors uses -1, 0, and 1, but we make this boolean for Class
        return ( $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->is_set() > 0 );
    }

    ############################################################################################
    ## emit an error
    ############################################################################################
    sub error(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'ERROR', OOP_PERLISH_CLASS_EMITLEVEL_ERROR, @msgs );
    }

    ############################################################################################
    ## emit a warning
    ############################################################################################
    sub warning(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'WARNING', OOP_PERLISH_CLASS_EMITLEVEL_WARNING, @msgs );
    }

    ############################################################################################
    ## emit info
    ############################################################################################
    sub info(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'INFO', OOP_PERLISH_CLASS_EMITLEVEL_INFO, @msgs );
    }

    ############################################################################################
    ## emit something verbose
    ############################################################################################
    sub verbose(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'VERBOSE', OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE, @msgs );
    }

    ############################################################################################
    ## emit debugging info
    ############################################################################################
    sub debug(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'DEBUG0', OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0, @msgs );
    }

    ############################################################################################
    ## emit more obscure debugging info
    ############################################################################################
    sub debug1(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'DEBUG1', OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1, @msgs );
    }

    ############################################################################################
    ## emit the most obscure debugging info
    ############################################################################################
    sub debug2(@)
    {
        my ( $self, @msgs ) = @_;

        return $self->_emit( 'DEBUG2', OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2, @msgs );
    }

    ############################################################################################
    ## croak with the specified message
    ############################################################################################
    sub fatal(@)
    {
        my ( $self, @msgs ) = @_;

        if( $self->_emitlevel() >= OOP_PERLISH_CLASS_EMITLEVEL_FATAL ) {
            croak( map { my $l = defined($_) ? $_ : 'undef'; chomp($l); $l =~ s/^/FATAL: /gms; $l . $/ } @msgs );
        }
        return;
    }

    ############################################################################################
    ## Stub of a _preinit; note that init must return true or object initialization will fail
    ## This method does object initialization _before_ accessors have been set
    ############################################################################################
    sub _preinit(@) {
        my ($self, @args) = @_;
        $self->_all_SUPER('_preinit', @args);
        return 1; 
    }

    ############################################################################################
    ## Stub of an _init; note that init must return true or object initialization will fail
    ## This method does object initialization _after_ accessors have been set
    ############################################################################################
    sub _init(@) {
        my ($self, @args) = @_;
        $self->_all_SUPER('_init', @args);
        return 1; 
    }

    ############################################################################################
    ## name of the class which we use for accessors; overload if you want to use a different
    ## class
    ############################################################################################
    sub _accessor_class_name(@)
    {
        my ($self) = @_;
        return qw(OOP::Perlish::Class::Accessor);
    }

    ############################################################################################
    ## emit error, warning, info, verbose, debug, debug1, and debug2 messages; overload to
    ## change the way you emit
    ############################################################################################
    sub _emit(@)
    {
        my ( $self, $prefix, $level, @msgs ) = @_;

        if(@msgs) {
            if( $self->_emitlevel() >= $level ) {
                STDERR->print( map { my $l = defined($_) ? $_ : 'undef'; chomp($l); $l =~ s/^/$prefix: /gms; $l . $/ } @msgs );
            }
            push( @{ $self->{ '___' . $prefix } }, @msgs );
        }
        else {
            return @{ $self->{ '___' . $prefix } };
        }
        return;
    }

    ############################################################################################
    ## return a list of all methods that this object ->can() in order of:
    ## (
    ##   methods defined in furthest-ancestors,
    ##   methods defined nearer-ancestors
    ##   methods defined in this-class
    ## )
    ## now memoized, as this becomes a substantial performance hit otherwise.
    ############################################################################################
    sub _all_methods(@)
    {
        my ( $self, $class ) = @_;
        $class ||= ref($self) || $self;

        our %____oop_perlish_class_all_methods;

        unless(exists($____oop_perlish_class_all_methods{$class})) { 
            my %all_methods = ();

            ### preserve order so that methods defined in hiarchies are preserved in the order they
            ### occur
            tie %all_methods, q(Tie::IxHash);

            for my $parent_class ( $self->_all_isa($class) ) {
                no strict 'refs';
                for my $symbol ( keys %{ '::' . $parent_class . '::' } ) {
                    $all_methods{$symbol} = 1 if( bless( {}, $class )->can($symbol) );
                }
                use strict 'refs';
            }

            ### Reverse the order of methods found, so that for meta-programming iteration, we run
            ### the methods defined in top-level derived classes last (so they can override
            ### inherited methods return values and such)
            $____oop_perlish_class_all_methods{$class} = [ reverse keys %all_methods ];
        }

        return( @{ $____oop_perlish_class_all_methods{$class} } );
    }

    ############################################################################################
    ## return a list of all-classes that we derive from, in order of:
    ## (
    ##   self
    ##   parents
    ##   parents of parents
    ##   <...>
    ##   furthest-ancestor
    ## )
    ############################################################################################
    sub _all_isa(@)
    {
        my ( $self, $class ) = @_;
        $class ||= ref($self) || $self;

        $self->{____isa_hash} = {} unless( exists( $self->{____isa_hash} ) );
        tie %{ $self->{____isa_hash}->{$class} }, q(Tie::IxHash)
          unless( exists( $self->{____isa_hash}->{$class} ) && defined( $self->{____isa_hash}->{$class} ) );

        $self->____recurse_isa($class);

        return keys %{ $self->{____isa_hash}->{$class} };
    }


    ############################################################################################
    ## run a method in all immediate members of @ISA
    ############################################################################################
    sub _all_SUPER
    {
        my ($self, $method, @args) = @_;
        my $root_class = __PACKAGE__;

        for my $parent_class ( grep { !/^\Q$root_class\E$/ } @{ $self->{____CLASS_ISA} } ) {
            if($parent_class->can($method)) {
                no strict 'refs';
                my $sub = *{ $parent_class . '::' . $method };
                use strict;
                if(*{ $sub }{CODE}) { 
                    $sub->($self, @args);
                }
            }
        }
    }


    ############################################################################################
    ## DO NOT USE UNLESS YOU KNOW WHAT YOU ARE DOING!
    ############################################################################################
    ## Returns a reference to underlying storage; bypassing validation, untainting, etc.
    ############################################################################################
    sub _get_mutable_reference(@)
    {
        my ( $self, $name ) = @_;

        if( $self->can($name) ) {
            $self->$name();                               ### Do some internal plumbing to make sure that a reference exists if it can exist.
            return $self->{___fields}->{$name}->{_Value}; ### should always be a reference to something if it exists
        }
    }

    ############################################################################################
    ## Set per-instance emit-level via accessor, or per-class emit-level via static
    ############################################################################################
    sub _emitlevel(@)
    {
        my ( $self, $level ) = @_;
        my $class = ref($self) || $self;

        no strict 'refs';
        my $instance_storage = \$self->{___fields}->{'_emitlevel'}->{_Value} if( ref($self) );
        my $class_storage = \${ '::' . $class . '::_OOP_PERLISH_CLASS_EMITLEVEL' };
        use strict;

        my $storage = ( ref($self) ) ? $instance_storage : $class_storage;

        if($level) {
            $level =~ m/\D/ && do {
                my %level_map = (
                                  'fatal'   => OOP_PERLISH_CLASS_EMITLEVEL_FATAL,
                                  'error'   => OOP_PERLISH_CLASS_EMITLEVEL_ERROR,
                                  'warning' => OOP_PERLISH_CLASS_EMITLEVEL_WARNING,
                                  'info'    => OOP_PERLISH_CLASS_EMITLEVEL_INFO,
                                  'verbose' => OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE,
                                  'debug'   => OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0,
                                  'debug1'  => OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1,
                                  'debug2'  => OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2
                                );
                if( exists( $level_map{ lc($level) } ) ) {
                    $level = $level_map{ lc($level) };
                }
                else {
                    $self->error('invalid level set; cannot set emitlevel');
                }
            };

            return unless( $level =~ m/^\d+$/ );
            ${$storage} = $level;
        }
        $level = ${$storage} || ${$class_storage} || $main::_OOP_PERLISH_CLASS_EMITLEVEL || 0;

        return $level;
    }

    ############################################################################################
    ## set accessors, usually called like 'BEGIN { __PACKAGE__->_accessor(...) }' as the first
    ## section of any derived class.
    ############################################################################################
    sub _accessors(@)
    {
        my ( $self, %accessors ) = @_;

        my $class = ref($self) || $self;

        my $accessor_class = $self->_accessor_class_name();

        for my $field ( keys %accessors ) {
            my %opts = %{ $accessors{$field} };

            $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field} = $accessor_class->new( %opts, name => $field );

            ### Symbol table manipulation; creates a method named for the $field in the package's namespace
            ### The actual method is created via closure in ____oop_perlish_class_accessor_factory();
            no strict 'refs';
            *{ '::' . $class . '::' . $field } = $self->____oop_perlish_class_accessor_factory($field);
            use strict;
        }

        return;
    }

    ############################################################################################
    ## Handle the magic constuctor argument
    ## '_____oop_perlish_class__defer__required__fields__validation', set the key value pair
    ## 'defer_required_fields' to when we see that arg passed to a constructor (and its true)
    ############################################################################################
    #sub _magic_constructor_arg_handler_defer_required(@)
    #{
    #    my ( $self, $opts ) = @_;
    #
    #    my $key = 'defer_required_fields';
    #    my $defer_required_fields;
    #
    #    if( exists( $opts->{_____oop_perlish_class__defer__required__fields__validation} ) ) {
    #        $defer_required_fields = $opts->{_____oop_perlish_class__defer__required__fields__validation};
    #        delete $opts->{_____oop_perlish_class__defer__required__fields__validation};
    #    }
    #    return ( $key, $defer_required_fields );
    #}

    ############################################################################################
    ## List all classes which are derived from a given base class (or the class $self was
    ## instanced from)
    ############################################################################################
    sub _derived_classes
    {
        my ($self) = @_;
        my $class = ref($self) || $self;

        my @derived_classes =
          grep { bless( {}, $_ )->isa($class) && $_ ne $class } keys %{ $self->____OOP_PERLISH_CLASS_DERIVED_CLASSES() };

        return (@derived_classes);
    }

    ############################################################################################
    ## return an accessor subroutine reference
    ############################################################################################
    sub ____oop_perlish_class_accessor_factory(@)
    {
        my ( $class, $key ) = @_;

        return sub {
            my ( $self, @values ) = @_;

            return $self->set( $key, @values ) if(@values);
            return $self->get($key);
        };
    }

    ############################################################################################
    ## recurse @ISA of every class we inherit from
    ############################################################################################
    sub ____recurse_isa(@)
    {
        my ( $self, $class, @traverse_isa ) = @_;
        unshift( @traverse_isa, $class );

        my @parent_isa = ();

        for my $parent_class ( grep { !exists( $self->{____isa_hash}->{$class}->{$_} ) } @traverse_isa ) {
            $self->{____isa_hash}->{$class}->{$parent_class} = 1;
            push( @parent_isa, $parent_class );
            no strict 'refs';
            push( @parent_isa, $self->____recurse_isa( $class, @{ $parent_class . '::ISA' } ) );
            use strict 'refs';
        }

        return @parent_isa;
    }

    ############################################################################################
    ## return a static reference to a hash of accessors for this class; must work for all
    ## derived classes
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_ACCESSORS
    {
        my ($self) = @_;
        my $class = ref($self) || $self;
        our $____OOP_PERLISH_CLASS_ACCESSORS;

        $____OOP_PERLISH_CLASS_ACCESSORS = {} unless( defined($____OOP_PERLISH_CLASS_ACCESSORS) );
        $____OOP_PERLISH_CLASS_ACCESSORS->{$class} = {} unless( exists( $____OOP_PERLISH_CLASS_ACCESSORS->{$class} ) );

        return $____OOP_PERLISH_CLASS_ACCESSORS->{$class};
    }

    ############################################################################################
    ## Keep a list of all classes that derive from OOP::Perlish::Class; used in the utility
    ## method '_derived_classes' to return all children of a given class.
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_DERIVED_CLASSES
    {
        my ($self) = @_;
        our $____OOP_PERLISH_CLASS_DERIVED_CLASSES;
        $____OOP_PERLISH_CLASS_DERIVED_CLASSES = {} unless( defined($____OOP_PERLISH_CLASS_DERIVED_CLASSES) );

        return $____OOP_PERLISH_CLASS_DERIVED_CLASSES;
    }

    ############################################################################################
    ## return a static reference to an array of required fields for this class; must work for
    ## all derived classes
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_REQUIRED_FIELDS
    {
        my ($self) = @_;
        my $class = ref($self) || $self;
        our $____OOP_PERLISH_CLASS_REQUIRED_FIELDS;

        $____OOP_PERLISH_CLASS_REQUIRED_FIELDS = {} unless( defined($____OOP_PERLISH_CLASS_REQUIRED_FIELDS) );
        $____OOP_PERLISH_CLASS_REQUIRED_FIELDS->{$class} = [] unless( exists( $____OOP_PERLISH_CLASS_REQUIRED_FIELDS->{$class} ) );

        return $____OOP_PERLISH_CLASS_REQUIRED_FIELDS->{$class};
    }

    ############################################################################################
    ## object construction, typically it shouldn't be necessary to overload this directly,
    ## instead overload one or more of the things it calls
    ############################################################################################
    sub ____initialize_object(@)
    {
        my ( $self, %opts ) = @_;

        my %magic = $self->____process_magic_arguments( \%opts );
        if( exists( $magic{'return'} ) ) {
            my @ret = @{ $magic{'return'} };
            return @ret if( scalar @ret > 1 );
            return ( $ret[0] );
        }

        ### Grab our version of %opts from $self->{____oop_perlish_class_opts}, or initialize it if its not been set.
        %{ $self->{____oop_perlish_class_opts} } = %opts;

        $self->____inherit_accessors();
        $self->____pre_validate_opts(); #unless( $magic{defer_required_fields} );
        ### XXX: unnessessary, and annoying XXX $self->____inherit_constructed_refs();
        ### XXX: Might want to make a for (@ISA) { $_::_init(@_); } or similar for multiple_inheritance considerations.
        $self->____initialize_required_fields();# unless( $magic{defer_required_fields} );
        return unless( $self->_preinit() );
        $self->____initialize_non_required_fields();
        return unless( $self->_init() );
        $self->{__initialized} = 1; # unless($magic{defer_required_fields});

        return $self;
    }

    ############################################################################################
    ## Run any method named _magic_constructor_arg_handler* and collect its return tuple into a
    ## hash called %magic which will be referenced in ____initialize_object; or may mutate
    ## $self, or do any of a dozen other things.
    ## 
    ## The key 'return' is considered magical and sacred; if you return in your tuple
    ## 'return => foo' the constructor will immediately, and before any other initialization
    ## completes, return the thing you said to return; usually a blessed reference to something;
    ## be it a singleton, multiton, another object, acme-time-bomb ala wiley coyote, etc.
    ##
    ## Your method will be passed a reference to the options passed to the constructor; and may
    ## (usually should) delete the magical key you are interested in, so that it is not
    ## considered an accessor later.
    ## 
    ## This could have been done via attributes, but then it suffers from all the annoyances of
    ## having to be seen prior to CHECK blocks running, yada yada... 
    ############################################################################################
    sub ____process_magic_arguments(@)
    {
        my ( $self, $opts ) = @_;

        my %magic = ();

        for( $self->_all_methods() ) {
            m/^_magic_constructor_arg_handler/ && do {
                my $method = $_;
                my ( $key, $value ) = $self->$method($opts);
                $magic{$key} = $value if( $key && $value );
            };
        }

        return %magic;
    }

    ############################################################################################
    ## verify that we have our required fields, even if they don't have real values but have
    ## defaults instead (a default AND required field would be odd, but is supported)
    ############################################################################################
    sub ____pre_validate_opts(@)
    {
        my ($self) = @_;

        my @required_fields = $self->____identify_required_fields();

        for(@required_fields) {
            confess("Missing required field $_")
              unless(
                      exists( $self->{____oop_perlish_class_opts}->{$_} )
                      || ( exists( $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$_} )
                           && $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$_}->default_is_set() )
                    );
        }
        return;
    }

    ############################################################################################
    ## obtain the names and references to every accessor in our inheritance
    ############################################################################################
    sub ____inherit_accessors(@)
    {
        my ($self) = @_;

        ### Protect overloaded accessors by identifying those in our top-level namespace
        ### This cascaded up through the inheritance tree
        my %top_accessors = ();
        if( scalar( keys %{ $self->____OOP_PERLISH_CLASS_ACCESSORS() } ) ) {
            # XXX: Hash slice assignment
            @top_accessors{ keys %{ $self->____OOP_PERLISH_CLASS_ACCESSORS() } } =
              ( (1) x ( ( scalar keys %{ $self->____OOP_PERLISH_CLASS_ACCESSORS() } ) ) );
        }

        ### Assimilate inherited accessor references
        #for my $parent_class ( @{ $self->{____CLASS_ISA} } ) {
        for my $parent_class ( $self->_all_isa() ) {
            if( $parent_class && bless( {}, $parent_class )->can('____OOP_PERLISH_CLASS_ACCESSORS') ) {
                while( my ( $k, $v ) = each %{ $parent_class->____OOP_PERLISH_CLASS_ACCESSORS() } ) {
                    $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$k} = $v unless( exists( $top_accessors{$k} ) );    #protect overloading
                }
            }
        }
        return;
    }

    ############################################################################################
    ## run constructors of every class we derive from, and assimilate their %{ $self } hash into
    ## our own.
    ############################################################################################
    ## FIXME: We only support deriving from blessed-hashref classes.
    ############################################################################################
    sub ____inherit_constructed_refs
    {
        my ($self) = @_;

        for my $parent_class ( @{ $self->{____CLASS_ISA} } ) {
            next if( $parent_class eq __PACKAGE__ );
            my $tclass = bless( {}, $parent_class );
            my $this;
            if( $tclass->isa(__PACKAGE__) ) {
                $this = $parent_class->new( _____oop_perlish_class__defer__required__fields__validation => 1 );
            }
            elsif( $tclass->can('new') ) {
                $this = $parent_class->new();
            }
            ### FIXME: cleanly handle non-hashref ancestors...
            if( $this && $this->isa('HASH') ) {
                while( my ( $key, $val ) = each %{$this} ) {
                    $self->{$key} = $val unless( exists( $self->{$key} ) );
                }
                if( exists( $this->{___fields} ) ) {
                    while( my ( $key, $val ) = each %{ $this->{___fields} } ) {
                        $self->$key( $val->{_Value} ) unless( exists( $self->{___fields}->{$key} ) );
                    }
                }
            }
        }
        return;
    }

    ############################################################################################
    ## figure out what fields are required for all derived ancestor classes and ourself.
    ############################################################################################
    sub ____identify_required_fields(@)
    {
        my ($self) = @_;

        my $class = ref($self) || $self;

        if( !defined( $self->{____oop_perlish_class_required_fields} ) ) {
            my %required_fields = ();

            ### Obtain REQUIRED_FIELDS static from derived class. Assign it via hashslice
            @required_fields{ @{ $class->____OOP_PERLISH_CLASS_REQUIRED_FIELDS() } } = @{ $class->____OOP_PERLISH_CLASS_REQUIRED_FIELDS() };

            while( my ( $name, $field ) = each %{ $self->____OOP_PERLISH_CLASS_ACCESSORS() } ) {
                $required_fields{$name} = $name if( $field->required() );
            }

            # FIXME: Does not cascade beyond @ISA, should traverse inheritance tree and ensure that all required fields are
            # provided for any hiararchy. ... does cascade via new, but only to ancesters who conform with us. unsure how to fix
            #for my $parent_class ( @{ $self->{____CLASS_ISA} } ) {
            for my $parent_class ( $self->_all_isa() ) {
                if( bless( {}, $parent_class )->can('____OOP_PERLISH_CLASS_REQUIRED_FIELDS') ) {
                    @required_fields{ @{ $parent_class->____OOP_PERLISH_CLASS_REQUIRED_FIELDS() } } =
                      @{ $parent_class->____OOP_PERLISH_CLASS_REQUIRED_FIELDS() };
                }
            }

            @{ $self->{____oop_perlish_class_required_fields} } = keys %required_fields;
        }
        return @{ $self->{____oop_perlish_class_required_fields} };
    }

    ############################################################################################
    ## setup required fields, using their accessors
    ############################################################################################
    sub ____initialize_required_fields(@)
    {
        my ($self) = @_;

        my @required_fields = $self->____identify_required_fields();

        for my $method (@required_fields) {
            $self->$method( $self->{____oop_perlish_class_opts}->{$method} )
              if( exists( $self->{____oop_perlish_class_opts}->{$method} ) && defined( $self->{____oop_perlish_class_opts}->{$method} ) );
            croak("Invalid required attribute for $method") unless( $self->$method() || $self->is_set($method) );
        }
        return;
    }

    ############################################################################################
    ## setup non-required-fields, using their accessors
    ############################################################################################
    sub ____initialize_non_required_fields(@)
    {
        my ($self) = @_;

        ### XXX: Hash slice assignment
        my %required_fields_lut;
        @required_fields_lut{ $self->____identify_required_fields() } = $self->____identify_required_fields();

        my %opts =
          map { ( $_ => $self->{____oop_perlish_class_opts}->{$_} ) }
          grep { !exists( $required_fields_lut{$_} ) } keys %{ $self->{____oop_perlish_class_opts} };

        # prepopulate accessors so that calls that cascade will have values assigned
        # Set everything by accessor that we ->can()
        while( my ( $method, $value ) = each %opts ) {
            $self->$method($value) if( $self->can($method) );
        }

        $self->____validate_defaults();

        # reset all accessors for actually set values, re-running cascades where applicable...
        # there must be a better way, but this works
        while( my ( $method, $value ) = each %opts ) {
            $self->$method($value) if( $self->can($method) );
        }
        return;
    }

    ############################################################################################
    ## verify all default values are valid for the class
    ############################################################################################
    ## FIXME: make this static
    ############################################################################################
    sub ____validate_defaults(@)
    {
        my ($self) = @_;

        for my $field ( keys %{ $self->____OOP_PERLISH_CLASS_ACCESSORS() } ) {
            $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->self($self);
            $self->____OOP_PERLISH_CLASS_ACCESSORS()->{$field}->__validate_default();
        }
        return;
    }
}
1;
__END__

=head1 NAME

OOP::Perlish::Class - A Base class implementation providing the fundimental infrastructure for perl OOP

=head1 DESCRIPTION

A Base class for creating Objects that conform to all common OOP practices, while still remaining very much perl.

=head2 Currently supported:

=over

=item Multiple-Inheritance

=item Mix-in

=item Meta-programming (class introspection; quite useful with mix-ins) 

=item Generational Inheritance (complex hiarchies of inheritance)

=item method overriding/overloading

=item operator overriding/overloading

=item Accessor validation

=item accessor cascading via validator subroutine

=item singletons

=item multitons (aka: multi-singletons, keyed singletons, named singletons, singleton-maps)

=item polymorphism (aka duck-typing for ruby folks)

=item abstract-classes (aka interfaces, protocols, traits, flavors, roles, class-prototypes, etc)

=back

=head1 SYNOPSIS

=head2 Simple Example:

 {
     package Foo;
     use base qw(OOP::Perlish::Class);

     BEGIN {
        __PACKAGE__->_accessors(
            bar  => { type => 'SCALAR', },                           # accessor which accepts a scalar, and returns a scalar
            baz  => { type => 'HASH', },                             # accessor which returns a hash (may be set via hash or hashref)
            qux  => { type => 'HASHREF', },                          # accessor which returns a hashref (immutable), (may be set via hash or hashref)
            baz  => { type => 'ARRAY', },                            # accessor which returns a array (may be set via array or arrayref)
            bam  => { type => 'ARRAYREF', },                         # accessor which returns a arrayref (immutable), (may be set via array or arrayref)
            quux => { type => 'CODE', },                             # accessor which accepts and returns a code-reference
            fred => { type => 'OBJECT', },                           # accessor which accepts and returns a blessed reference
            thud => { type => 'REGEXP', },                           # accessor which accepts and returns a reference to a pre-compiled regular expression
            psdf => { type => 'GLOBREF', },                             # accessor which accepts and returns a reference to a glob (ref only), (synonym: GLOBREF)
        );
    };

    sub _preinit(@)
    {
        my ($self) = @_;

        # ... do some initialization stuff that needs to happen before you assign values to any accessors in the call to the constructor.

        return 1;
    }

    sub _init(@)
    {
        my ($self) = @_;

        # ... do some initialization stuff if necessary; DO THE ABSOLUTE MINIMUM HERE

        return 1;
    }
 }

=head2 Accessor Validation via regular expression:

Additionally, accessors may be more complicated than noted above. For instance, you might care what data is passed to an accessor. 
Here are some examples of validating input:

 BEGIN {
     __PACKAGE__->_accessors(
            bar  => { type => 'SCALAR',   validator => qr/.*bar.*/ },      # a scalar that must match the regular expression /.*bar.*/
            baz  => { type => 'HASH',     validator => qr/.*bar.*/ },      # a hash who's values must match the regular expression /.*bar.*/
            qux  => { type => 'HASHREF',  validator => qr/.*bar.*/ },      # a hashref who's values must match the regular expression /.*bar.*/
            baz  => { type => 'ARRAY',    validator => qr/.*bar.*/ },      # an array who's values must match the regular expression /.*bar.*/
            bam  => { type => 'ARRAYREF', validator => qr/.*bar.*/ },      # an arrayref who's values must match the regular expression /.*bar.*/
            fred => { type => 'OBJECT',   validator => qr/.*bar.*/ },      # an object who's string representation must match the regular expression /.*bar.*/
     );
 };

=head2 Accessor Validation via subroutine:

However, a simple regular expression might not provide you with the means to validate an attribute, so instead of using a regexp, you can use a sub routine

 BEGIN {
     __PACKAGE__->_accessors(
            bar  => { type => 'SCALAR',    validator => sub { my ($self, $value) = @_; <...>; return $value },
            baz  => { type => 'HASH',      validator => sub { my ($self, %values) = @_; <...>; return %values },
            qux  => { type => 'HASHREF',   validator => sub { my ($self, %values) = @_; <...>; return %values },
            baz  => { type => 'ARRAY',     validator => sub { my ($self, @values) = @_; <...>; return @values },
            bam  => { type => 'ARRAYREF',  validator => sub { my ($self, @values) = @_; <...>; return @values },
            quux => { type => 'CODE', },   validator => sub { my ($self, $coderef) = @_; <...>; return $coderef },
            fred => { type => 'OBJECT', }, validator => sub { my ($self, $blessed_ref ) = @_; <...>; return $blessed_ref },
            thud => { type => 'REGEXP', }, validator => sub { my ($self, $regexp ) = @_; <...>; return $regexp },
            psdf => { type => 'GLOBREF', },   validator => sub { my ($self, $globref ) = @_; <...>; return $globref },
     );
 };

Note that the "$self" value passed to your validation routine will be the $self of the class, and so you can invoke methods upon it, mutate it (within reason), etc
as necessary. 

Note also that the returned value(s) from your validation routine are the values that will actually be stored, allowing you to verify and/or mutate values on setting.

Note finally, that while the regular expression form of validation automatically de-taints values, when you use a subroutine validator, you must explicitely untaint the 
values you return.

=head2 Additional properties of all accessors:

Accessors can also have special properties associated with them, below is an example of all that are applicable to every type:


 BEGIN {
     __PACKAGE__->_accessors(
            foo  => { 
                      type => 'SCALAR',             # type, mandatory for any accessor
                      validator => qr/\d+/,         # validator, optional, may be compiled-regexp, or subroutine reference returning validated values.
                      required => 1,                # boolean, is this accessor required to be passed valid data to ->new()
                      default => '12345',           # default value, must be valid input for the type and validator.
                      readonly => 1,                # boolean, do not allow any further changes to the value of this accessor once object-initialization is complete
                    },
    );

Note that you should take care to ensure that any accessor used in any other accessor's 'validator => sub {}' mechanism is marked as 'required' so that it will have a valid value whenever it is used by other accessors.

Note also that 'readonly' marks an accessor as immutable after initialization; this means that you can modify it in its validator => sub {}, in _preinit, or in _init, but you will not be able to modify it after 
_init has completed.

=head2 Additional properties of special accessors:

In addition the the accessor properties specified above, certain types of accessors have additional special properties.

=head3 Special properties for OBJECTs 

 BEGIN {
     __PACKAGE__->_accessors(
            foo  => { 
                      type => 'OBJECT',                         # type, mandatory for any accessor
                      object_can => [ qw(foo bar baz) ],        # specify a reference to an array containing method-names that any object passed must have.
                      object_isa => [ qw(A::Class, B::Class) ], # specify a reference to an array containing class-names which the object must have in @ISA.
                    },



Note that in 99% of cases, you are more interested in whether an object exposes a particular interface than you are interested in what its ancestory might be; hence, you should use object_can 99% of the time.

=head1 EXPORTS

=over 4

=item tags

=over 4

=item emitlevels

Exports the constants: 
OOP_PERLISH_CLASS_EMITLEVEL_FATAL, OOP_PERLISH_CLASS_EMITLEVEL_ERROR, OOP_PERLISH_CLASS_EMITLEVEL_WARNING, OOP_PERLISH_CLASS_EMITLEVEL_INFO,
OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE, OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0, OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1, OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2

=back

=item available exports: 

All of the following are error-levels which can be set per-instance, per class, or for all OOP::Perlish::Class derived classes. See the section L<DIAGNOSTICS> for more information.

=over 4

=item OOP_PERLISH_CLASS_EMITLEVEL_FATAL

=item OOP_PERLISH_CLASS_EMITLEVEL_ERROR

=item OOP_PERLISH_CLASS_EMITLEVEL_WARNING

=item OOP_PERLISH_CLASS_EMITLEVEL_INFO

=item OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE

=item OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0

=item OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1

=item OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2

=back

=back

=head1 CONSTRUCTOR

The construction of objects has been broken up into multiple parts:

=over

=item ->new(ARGS)

The ->new() method simply gets a hash or hashref, puts it into a hash, blesses itself into all parent classes, and then invokes ____initialize_object(). Args may be a hash, or a hash-reference of name-value pairs referring to accessors-methods in the class, and the arguments to pass to them.

The ->new() method inherited fromt his module should seldem if ever be overridden.

=item ->____initialize_object(%ARGS)

%ARGS is a hash of name-value pairs of accessor-methods in the class, and arguments to pass to them. 

->____initialize_object() does all the heavy-lifting of object instantiation. 
In most cases, you wild not want or need to overload this method.

Things it calls, in order, are:

=over

=item $self->____process_magic_arguments(@) 

This method will automagically run any method in your class' namespace that begins with _magic_constructor_arg_handler. Simply defining a method that begins with this string will result in it being
invoked as a 'magic' constructor-argument-handler

=item $self->____inherit_accessors();

Used internally, typically should not be overloaded -- See source.

Walks @ISA of every parent, and infers their accessors, preserving hiarchial inheritance for overloaded accessors.

=item $self->____pre_validate_opts()

Usually not overloaded, but occasionally you might want to do additional pre-validation prior to populating required fields. 

Takes no arguments (other than $self), returns nothing; expected to croak if there is an error with the options passed to the constructor.

=cut

#=item $self->____inherit_constructed_refs();
#
#Used internally, typically should not be overloaded -- See source.
#
#Inherits hash-references from all parent instances of '$self'

=item $self->____initialize_required_fields()

Usually not overloaded, -- See source.

This will be run if the 'magic' constructor-argument '_____oop_perlish_class__defer__required__fields__validation' was not specified. Said argument sets the %magic hash key 'defer_required_fields'

=item return unless( $self->_preinit() );

Call _preinit, see below.

=item $self->____initialize_non_required_fields();

Usually not overloaded. -- See source.

Initializes all non-required fields.

=item return unless( $self->_init() );

Call _init, see below.

=back

=item ->_preinit()

This method is specifically intended to be overloaded in your class to do any initialization required before any non-required fields have been initialized. Because required-fields are guaranteed to have been passed to the constructor, they are initialized prior to this method being called, however you may update their values if necessary here (even if they are marked as read-only)

=item ->_init()

This method is specifically intended to be overloaded in your class to do any initialization required after all non-required fields have been initialized. You may still modify readonly accessors here, and as soon as this method completes, they will be locked-out from any further changes.

=back

=head1 ACCESSORS

=over

=item _emitlevel(LEVEL)

This accessor is defined for every derived class, and allows you to specify an emitlevel used for the 'freebie' diagnostic methods provided (see below)

LEVEL is a number from 0-7, which you can obtain constants for by using the export-tag ':emitlevels' when using any object.

The default value for this accessor will be inferred dynamically at runtime. if the class variable _emitlevel has been defined, for instance via 'perl -MClass::Name=_emitlevel:debug', 
or if there is a variable $main::_OOP_PERLISH_CLASS_EMITLEVEL defined with a number from 0-7, its value will be used globally for every derived class.

=back

=head1 METHODS

=over

=item ->get(NAME)

This is used internally, but can often be handy to use yourself. rather than getting the value of an accessor via its method, you can use ->get(NAME) where NAME is the name of the accessor.

=item ->set(NAME, VALUES)

This is used internally, but can often be handy to use yourself. rather than getting the value of an accessor via its method, you can use ->set(NAME, VALUES) where NAME is the name of the accessor, and VALUES
are value(s) are values which are valid for the accessor.

=item ->is_set(NAME)

Test if a particular accessor has been set, even if set to undef;

=item ->fatal(MSG)

Croak of an error with MSG

=item ->error(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_ERROR

=item ->warning(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_WARNING

=item ->info(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_INFO

=item ->verbose(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_VERBOSE

=item ->debug(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_DEBUG0

=item ->debug1(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_DEBUG1

=item ->debug2(MSG)

Report an error; Emitted only if _emitlevel >= OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2

=back

=head1 ADDITIONAL METHODS

The following methods are prefixed with a '_' indicating they are primarly for usage inside derived classes, but not typically used by users of derived classes.

=over

=item _accessor_class_name

Overload this if you use a different class for Accessors than the default OOP::Perlish::Class::Accessor.

=item _emit

Overload this if you wish to change the behavior of 'error', 'warning', 'info', 'verbose', 'debug', 'debug1', and 'debug2' discussed above.

=item _all_methods

Obtain a list of all methods this class has. This list will be sorted in the order of methods-defined-in-furthest-ancestor => methods-defined-in-self.

=item _all_isa

Optain a list of all classes this class has in its ancestory. This list will be sorted in nearest => furthest. 

=item _get_mutable_reference

B<ONLY USE IF YOU KNOW EXACTLY WHAT YOU ARE DOING>

This will return a naked, completely unprotected reference to the underlying storage of an accessor. No validators will be checked, no type-checking will be performed, you are on your honor not to break things.

=back

=head1 DIAGNOSTICS

Below are the three possible ways to enable diagnostics reporting for OOP::Perlish::Class and derived classes at various levels of verbosity. 
They are listed in order of precedence, with the first taking priority over the last.

=over

=item Set via accessor

Always takes highest precedence

    use Class::Name qw(:emitlevels);
    my $c = Class::Name->new(_emitlevel => OOP_PERLISH_CLASS_EMITLEVEL_INFO); # create a new 'Class::Name' instance that will display info level messages.

=item Set via package-scoped global

Will be used any time an instance hasn't been set via accessor

    perl -MClass::Name=_emitlevel:verbose /path/to/foo  # enable verbose messages for the OOP::Perlish::Class derived class 'Class::Name'

=item Set via $main::_OOP_PERLISH_CLASS_EMITLEVEL

Will be used if there is no package-scoped global, and the instance has no value set via the accessor

    package main;
    use OOP::Perlish::Class qw(:emitlevels);

    our $_OOP_PERLISH_CLASS_EMITLEVEL = OOP_PERLISH_CLASS_EMITLEVEL_DEBUG2; # enable debug2 messages for every OOP::Perlish::Class derived class

=back

See also: L<-E<gt>_emitlevel>, L<-E<gt>fatal>, L<-E<gt>error>, L<-E<gt>warn>, L<-E<gt>info>, L<-E<gt>verbose>, L<-E<gt>debug>, L<-E<gt>debug1>, L<-E<gt>debug2>

=head1 INTERNAL GUTS

See source for complete details. The following methods are used internally, and you might find some need to overload them at some point, so they are mentioned here:

=over

=item sub ____oop_perlish_class_accessor_factory(@)

Produce a subroutine closure for get and set accessors

=item sub ____recurse_isa(@)

Recursively traverse isa of this class, and all parents, skipping loops

=item sub ____OOP_PERLISH_CLASS_ACCESSORS(@)

return a static hash-reference of name => accessor-object pairs for every accessor in this class.

=item sub ____OOP_PERLISH_CLASS_REQUIRED_FIELDS(@)

return a static array-reference to the list of required-fields for this class.

=item sub ____identify_required_fields(@)

Returns a list of all required fields for this class, and all ancestors.

=item sub ____validate_defaults(@)

Verify that default values are valid for the type and validator of every accessor

=back

=cut
