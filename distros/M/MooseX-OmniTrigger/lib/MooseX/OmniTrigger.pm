use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Class::Load ();
use Hash::Util::FieldHash ();
use Moose 2.0200 ();
use Moose::Exporter ();
use Moose::Util::MetaRole ();

{ package MooseX::OmniTrigger;

    our $VERSION = '0.06';

    Moose::Exporter->setup_import_methods;

    my (undef, undef, $init_meta_method) = Moose::Exporter->build_import_methods(

        install => [qw(import unimport)],

        role_metaroles => {

            role => [qw(MooseX::OmniTrigger::MetaRole::Role)],

            Moose->VERSION >= 1.9900 ? (applied_attribute => [qw(MooseX::OmniTrigger::MetaRole::Attribute)]) : (),

            application_to_role  => [qw(MooseX::OmniTrigger::MetaRole::AppToRole )],
            application_to_class => [qw(MooseX::OmniTrigger::MetaRole::AppToClass)],
        },

        class_metaroles => {

            class     => [qw(MooseX::OmniTrigger::MetaRole::Class    )],
            attribute => [qw(MooseX::OmniTrigger::MetaRole::Attribute)],
            instance  => [qw(MooseX::OmniTrigger::MetaRole::Instance )],
        },
    );

    sub init_meta { goto $init_meta_method }
}

{ package MooseX::OmniTrigger::MetaRole::Role;

    use Moose::Role;

    around composition_class_roles => sub {

        my ($orig_method, $self) = (shift, shift);

        return ($self->$orig_method(@_), 'MooseX::OmniTrigger::MetaRole::Composite');
    };
}

{ package MooseX::OmniTrigger::MetaRole::Composite;

    use Moose::Role;

    around apply_params => sub {

        my ($orig_method, $self) = (shift, shift);

        $self->$orig_method(@_);

        $self = Moose::Util::MetaRole::apply_metaroles(

            for => $self,

            role_metaroles => {

                application_to_class => [qw(MooseX::OmniTrigger::MetaRole::AppToClass)],
                application_to_role  => [qw(MooseX::OmniTrigger::MetaRole::AppToRole )],
            },
        );

        return $self;
    };
}

{ package MooseX::OmniTrigger::MetaRole::AppToClass;

    use Moose::Role;

    around apply => sub {

        my ($orig_method, $self, $role, $applicant) = (shift, shift, @_);

        $applicant = Moose::Util::MetaRole::apply_metaroles(

            for => $applicant,

            class_metaroles => {

                class    => [qw(MooseX::OmniTrigger::MetaRole::Class   )],
                instance => [qw(MooseX::OmniTrigger::MetaRole::Instance)],
            },
        );

        $self->$orig_method($role, $applicant);

        # NO EXPLICIT RETVAL.
    };
}

{ package MooseX::OmniTrigger::MetaRole::AppToRole;

    use Moose::Role;

    around apply => sub {

        my ($orig_method, $self, $role, $applicant) = (shift, shift, @_);

        $applicant = Moose::Util::MetaRole::apply_metaroles(

            for => $applicant,

            role_metaroles => {

                application_to_class => [qw(MooseX::OmniTrigger::MetaRole::AppToClass)],
                application_to_role  => [qw(MooseX::OmniTrigger::MetaRole::AppToRole )],
            },
        );

        $self->$orig_method($role, $applicant);

        # NO EXPLICIT RETVAL.
    };
}

{ package MooseX::OmniTrigger::State; use namespace::autoclean;

    use Moose;

    Hash::Util::FieldHash::fieldhash(my %state);

    { my $state; sub singleton { $state ||= __PACKAGE__->new } }

    sub instance { $state{$_[1]}                                              ||= {} }
    sub slot     { $state{$_[1]}{SLOT_NAME}{ref($_[2]) ? $_[2]->name : $_[2]} ||= {} }

    sub reset {

        # CALLED JUST BEFORE THE ORIG MM::Class::_fixup_attributes_after_rebless AND JUST AFTER THE
        # ORIG CMOP::Instance::clone_instance. WIPES OUT INSTANCE/SLOT STATE FOR $instance AND THEN
        # ESTABLISHES oldval_at_reset AND initval_at_reset FOR EACH $instance SLOT.

        my ($self, $instance, $params) = @_;

        delete($state{$instance});

        for my $attr (Moose::Util::find_meta($instance)->_get_all_attrs_that_have_omnitrigs) {

            my $slot_state = $self->slot($instance, $attr);

            $slot_state->{oldval_at_reset} = [$attr->has_value($instance) ? $attr->get_raw_value($instance) : ()];

            $slot_state->{initval_at_reset} = [exists($params->{$attr->init_arg || ''}) ? $params->{$attr->init_arg} : ()];
        }

        # NO EXPLICIT RETVAL.
    }

    sub _test_me { \%state }

    __PACKAGE__->meta->make_immutable;
}

{ package MooseX::OmniTrigger::MetaRole::Class; use namespace::autoclean;

    use Moose::Role;

    around clone_object => sub {

        # MOOSE DOESN'T HANDLE TRIGGERS DURING OBJECT CLONING THE SAME AS IT DOES DURING REGULAR
        # CONSTRUCTION. call_all_triggers ISN'T USED. CMOP LOOPS OVER ALL ATTRIBUTES AND SETS ANY
        # NEW INITVALS VIA set_value IMMEDIATELY AFTER THE CLONING OF THE INSTANCE; AND ANY MOOSE
        # TRIGGERS ARE FIRED AS USUAL WITH EACH set_value CALL. (THUS THE *BEHAVIOR* FOR TRIGGERS IS
        # CONSISTENT BETWEEN NORMAL CONSTRUCTION AND CLONING, BUT THE IMPLEMENTATION ISN'T.)

        # FOR OMNITRIGGERS, WE TREAT CLONE CONSTRUCTION IN BLACK-BOX FASHION JUST AS WE DO WITH
        # NORMAL CONSTRUCTION AND REBLESS FIXUP.

        my ($orig_method, $self_aka_class, undef, %params) = (shift, shift, @_);

        my $clone = $self_aka_class->$orig_method(@_);

        $self_aka_class->_call_all_omnitriggers($clone, \%params);

        return $clone;
    };

    around _fixup_attributes_after_rebless => sub {

        my ($orig_method, $self_aka_class, $instance, undef, %params) = (shift, shift, @_);

        my $state = MooseX::OmniTrigger::State->singleton;

        $state->reset($instance, \%params);

        local $state->instance($instance)->{fixing_up} = 1;

        $self_aka_class->$orig_method(@_);

        # NO EXPLICIT RETVAL.
    };

    around _call_all_triggers => sub {

        my ($orig_method, $self_aka_class, $instance) = (shift, shift, @_);

        MooseX::OmniTrigger::State->singleton->instance($instance)->{omnitrigs_ready} = 1;

        $self_aka_class->$orig_method(@_);

        $self_aka_class->_call_all_omnitriggers(@_);

        # NO EXPLICIT RETVAL.
    };

    sub _call_all_omnitriggers {

        my ($self_aka_class, $instance, $params) = @_;

        my $state = MooseX::OmniTrigger::State->singleton;

        #===========================================================================================
        # TO THIS POINT, $instance HAS BEEN IN A STATE OF CONSTRUCTION, CLONING, OR FIXUP.
        # omnitrigs_ready WILL HAVE BEEN FALSE, AND OMNITRIGGERS WILL NOT HAVE BEEN ALLOWED TO FIRE.

        $state->instance($instance)->{omnitrigs_ready} = 1;

        #
        #===========================================================================================

        ATTRIBUTE: for my $attr ($self_aka_class->_get_all_attrs_that_have_omnitrigs) {

            my $slot_state = $state->slot($instance, $attr);

            #=======================================================================================
            # WE NEED TO FIRE THIS OMNITRIGGER NOW ONLY IF AN ATTEMPT TO FIRE IT WAS MADE DURING
            # CONSTRUCTION/CLONING/FIXUP (AND ONLY IF IT HASN'T BEEN FIRED SINCE THAT ATTEMPT).

            next ATTRIBUTE unless $slot_state->{fire_omnitrig_when_ready};

            #
            #=======================================================================================

            #=======================================================================================
            # THE OLDVAL IS WHATEVER IT WAS *PRIOR* TO CONSTRUCTION/FIXUP, EVEN THOUGH THAT VALUE
            # DOESN'T NECESSARILY MATCH WHAT'S IN THE SLOT AT THIS EXACT MOMENT.

            $attr->_fire_omnitrigger({

                instance => $instance,

                oldval => [@{$slot_state->{oldval_at_reset} || []}],
            });
        }

        # NO EXPLICIT RETVAL.
    }

    sub _get_all_attrs_that_have_omnitrigs {

        my ($self_aka_class) = @_;

        my @attributes = $self_aka_class->get_all_attributes;

        @attributes = grep($_->can('has_omnitrigger') && $_->has_omnitrigger, @attributes);

        @attributes = sort({ $a->omnitrig_sort_key cmp $b->omnitrig_sort_key } @attributes);

        return @attributes;
    }

    around _eval_environment => sub {

        my ($orig_method, $self_aka_class) = (shift, shift);

        # IT APPEARS THAT CMOP AND MOOSE TAKE SOME PAINS TO AVOID USING HASHES AS EE VARS, PROBABLY
        # FOR PERFORMANCE. WE'LL USE HASHES, THOUGH (HERE AND WHERE WE WRAP _eval_environment IN
        # MooseX::OmniTrigger::MetaRole::Attribute), BECAUSE IT MAKES IT EASIER TO GET SOME REUSE
        # OUT OF _icode_fire_omnitrigger.

        my @attrs = $self_aka_class->_get_all_attrs_that_have_omnitrigs;

        return {

            %{$self_aka_class->$orig_method(@_)},

            '%_EE_OMNITRIG_attrs_init_arg'    => {map(($_->name => $_->init_arg   ), @attrs)},
            '%_EE_OMNITRIG_attrs_omnitrigger' => {map(($_->name => $_->omnitrigger), @attrs)},
        };
    };

    around _inline_triggers => sub {

        my ($orig_method, $self_aka_class) = (shift, shift);

        #===========================================================================================
        # WE HARDCODE THE EXPRESSION '$instance' BECAUSE _inline_triggers HARDCODES IT, HAVING NOT
        # RECEIVED IT AS AN ARGUMENT. (WHICH PROBABLY IT SHOULD HAVE? IT WAS AVAILABLE AS EARLY AS
        # _inline_new_object.)

        my $iexpr_instance = '$instance';

        #
        #===========================================================================================

        return ( # ORIG METHOD RETURNS CODE AS LIST.

            "MooseX::OmniTrigger::State->singleton->instance($iexpr_instance)->{omnitrigs_ready} = 1;",

            $self_aka_class->$orig_method(@_),

            @{$self_aka_class->icode_call_all_omnitriggers({

                iexpr_instance => $iexpr_instance,
            })},
        );
    };

    sub icode_call_all_omnitriggers {

        # SEE COMMENTS IN _call_all_triggers.

        my ($self_aka_class, $p) = (shift, @_);

        my @icode_call_all_omnitriggers; for my $attr ($self_aka_class->_get_all_attrs_that_have_omnitrigs) {

            my $attr_name = $attr->name;

            push(@icode_call_all_omnitriggers,
                'ATTRIBUTE: {',

                    "my \$_OMNITRIG_slot_state = MooseX::OmniTrigger::State->singleton->slot($p->{iexpr_instance}, '$attr_name');",

                    "next ATTRIBUTE unless \$_OMNITRIG_slot_state->{fire_omnitrig_when_ready};",

                    @{$attr->_icode_fire_omnitrigger({

                        iexpr_slot_state => '$_OMNITRIG_slot_state',

                        iexpr_instance => $p->{iexpr_instance},

                        iexpr_oldval => "[\@{\$_OMNITRIG_slot_state->{oldval_at_reset} || []}]",
                    })},
                '}',
            );
        }

        return \@icode_call_all_omnitriggers;
    }
}

{ package MooseX::OmniTrigger::MetaRole::Attribute; use namespace::autoclean;

    use Moose::Role;

    has omnitrigger => (is => 'rw', isa => 'CodeRef', predicate => 'has_omnitrigger');

    has omnitrig_sort_key => (required => 1, is => 'rw', isa => 'Str', default => "\0");

    sub _fire_omnitrigger {

        my ($self_aka_attr, $p) = @_;

        my $instance_state = MooseX::OmniTrigger::State->singleton->instance($p->{instance}                );
        my     $slot_state = MooseX::OmniTrigger::State->singleton->slot    ($p->{instance}, $self_aka_attr);

        my $omnitrig_is_recursing = $slot_state->{omnitrig_is_recursing};

        local $slot_state->{omnitrig_is_recursing} = 1;

        if ($omnitrig_is_recursing) {

            $p->{sub_to_wrap}() if $p->{sub_to_wrap};

            return;
        }

        unless ($instance_state->{omnitrigs_ready}) {

            # A FALSE omnitrigs_ready MEANS THE INSTANCE IS BEING CONSTRUCTED, CLONED, OR FIXED UP
            # AND _call_all_triggers HAS NOT YET BEEN HIT. OMNITRIGGERS ARE NOT ALLOWED TO FIRE AT
            # THIS TIME. HOWEVER, WE DO SET A FLAG INDICATING THAT THIS OMNITRIGGER SHOULD FIRE WHEN
            # omnitrigs_ready DOES BECOME TRUE.

            #=======================================================================================
            # THERE'S A SPECIAL CASE, WHEN WE'RE HERE AS THE RESULT OF A SLOT BEING SET DURING FIXUP
            # FOR THE PURPOSE OF "TRANSFERRING" A VALUE FROM THE "OLD" INSTANCE TO THE "NEW." WE
            # DON'T COUNT SUCH A TRANSFER AS A *CHANGE*: IT'S JUST BOOKKEEPING. SO FOR THESE
            # TRANSFERS WE NEITHER FIRE THE OMNITRIGGER NOW NOR SET fire_omnitrig_when_ready TRUE
            # FOR A FUTURE FIRING.

            # KLUDGY SOLUTION, THE unless CONDITION, HERE. I FINALLY HAD TO DO SOMETHING LIKE THIS
            # BECAUSE OF THE WAY _fixup_attributes_after_rebless IS IMPLEMENTED. THERE ARE BASICALLY
            # THREE DIFFERENT SCENARIOS THERE: 1) EXISTING VALUES OF ATTRIBUTES WITH UNDEFINED
            # init_argS ARE TRANSFERRED VIA set_value; 2) EXISTING VALUES OF ATTRIBUTES WITH DEFINED
            # init_argS ARE TRANSFERRED VIA set_initial_value; AND 3) NEWLY INCOMING VALUES FOR
            # ATTRIBUTES WITH DEFINED init_argS ARE SET VIA set_initial_value. WE NORMALLY FIRE
            # OMNITRIGGERS FOR ANY USE OF set_value OR set_initial_value (RATHER,
            # _set_initial_slot_value, ULTIMATELY), BUT HERE OMNITRIGGERS SHOULD FIRE ONLY FOR THAT
            # THIRD SCENARIO. AS MOOSE GIVES NO WAY EXPLICITLY TO ISOLATE "SET-FOR-THE- PURPOSE-OF-
            # TRANSFER" OPERATIONS, WE'VE GOT TO ISOLATE (AND AVOID) THEM MORE CIRCUITOUSLY.

            $slot_state->{fire_omnitrig_when_ready} = 1
                unless $instance_state->{fixing_up} && @{$slot_state->{oldval_at_reset} || []} && ! @{$slot_state->{initval_at_reset} || []};

            #
            #=======================================================================================

            $p->{sub_to_wrap}() if $p->{sub_to_wrap};

            return;
        }

        #===========================================================================================
        # TO GET THE OLDVAL (AND THE NEWVAL, HERE AND ELSEWHERE), WE USE get_raw_value. WE DON'T
        # CONSIDER IT OUR BUSINESS TO PERFORM ANY CHECKS OR COERCIONS.

        my $oldval = $p->{oldval} || [$self_aka_attr->has_value($p->{instance}) ? $self_aka_attr->get_raw_value($p->{instance}) : ()];

        #
        #===========================================================================================

        #===========================================================================================
        # BEAR IN MIND THAT (HERE AND ABOVE) sub_to_wrap WILL BE UNDEF IF WE WERE CALLED FROM
        # _call_all_triggers. IF SO, ANY ACTUAL SET OPS WILL ALREADY HAVE BEEN PERFORMED INSIDE THE
        # CONSTRUCTION/CLONING/FIXUP "BLACK BOX."

        $p->{sub_to_wrap}() if $p->{sub_to_wrap};

        #
        #===========================================================================================

        my $newval = [$self_aka_attr->has_value($p->{instance}) ? $self_aka_attr->get_raw_value($p->{instance}) : ()];

        #===========================================================================================
        # BY ITS NATURE, WEAKENING CAN OCCUR ONLY *AFTER* THE SET OP. THIS MEANS THAT, IF WE'VE
        # WRAPPED A BASIC SETTER, WEAKENING WON'T YET HAVE HAPPENED -- WE'D EXPECT IT TO OCCUR SOME
        # TIME AFTER _fire_omnitrigger RETURNS. BUT TO BE CORRECT AND SAFE, WE WANT ANY NECESSARY
        # WEAKENING TO OCCUR NOW, PRIOR TO FIRING THE OMNITRIGGER.

        # DEPENDING ON WHETHER THE SETTER WE'VE WRAPPED PERFORMS WEAKENING ITSELF, THE WEAKENING
        # HERE IS EITHER ITSELF REDUNDANT, OR IS GOING TO MAKE A FUTURE WEAKENING REDUNDANT.

        $self_aka_attr->_weaken_value($p->{instance}) if ref($newval->[0]) && $self_aka_attr->is_weak_ref;

        #
        #===========================================================================================

        #===========================================================================================
        # FIRE.

        $p->{instance}->$_($self_aka_attr->name, $newval, $oldval) for $self_aka_attr->omnitrigger;

        #
        #===========================================================================================

        #===========================================================================================
        # IF WE'RE IN _call_all_omnitriggers, AND IF THIS OMNITRIGGER HASN'T YET BEEN "ARTIFICIALLY"
        # FIRED INSIDE THE "ATTRIBUTE" LOOP THERE, WE NOW WANT TO MAKE SURE AN ARTIFICIAL FIRING
        # NEVER HAPPENS. THE FIRING THAT JUST OCCURRED, WHATEVER THE REASON FOR IT, SATISFIES THE
        # fire_omnitrigger_when_ready REQUIREMENT, AND AN ARTIFICIAL FIRING WOULD NOW BE REDUNDANT
        # AND INCORRECT.

        delete($slot_state->{fire_omnitrig_when_ready});

        #
        #===========================================================================================

        # NO EXPLICIT RETVAL.
    }

    around _eval_environment => sub {

        my ($orig_method, $self_aka_attr) = (shift, shift);

        my $attr_name = $self_aka_attr->name;

        return {

            %{$self_aka_attr->$orig_method(@_)},

            '%_EE_OMNITRIG_attrs_init_arg'    => {$attr_name => $self_aka_attr->init_arg   },
            '%_EE_OMNITRIG_attrs_omnitrigger' => {$attr_name => $self_aka_attr->omnitrigger},
        };
    };

    sub _icode_fire_omnitrigger {

        my ($self_aka_attr, $p) = @_;

        my $attr_name = $self_aka_attr->name;

        my $iexpr_instance_has_and_get_ternary = sprintf('[%s ? %s : ()]',

            $self_aka_attr->_inline_instance_has($p->{iexpr_instance}),
            $self_aka_attr->_inline_instance_get($p->{iexpr_instance}),
        );

        return [

            'OMNITRIGGER: {',

                'my $_OMNITRIG_slot_state = ' . ($p->{iexpr_slot_state} || "MooseX::OmniTrigger::State->singleton->slot($p->{iexpr_instance}, '$attr_name')") . ";",

                "my \$_OMNITRIG_omnitrig_is_recursing = \$_OMNITRIG_slot_state->{omnitrig_is_recursing};",

                "local \$_OMNITRIG_slot_state->{omnitrig_is_recursing} = 1;",

                'if ($_OMNITRIG_omnitrig_is_recursing) {',

                    @{$p->{icode_to_wrap} || []}, ';',

                    'next OMNITRIGGER;',
                '}',

                #===================================================================================
                # MOOSE DOESN'T (YET) IMPLEMENT INLINE REBLESSING, SO THERE'S NO NEED TO FUSS WITH
                # LOOKING FOR SET-FOR-TRANSFER-DURING-FIXUP OPERATIONS LIKE WE DO IN
                # _fire_omnitrigger.

                "unless (MooseX::OmniTrigger::State->singleton->instance($p->{iexpr_instance})->{omnitrigs_ready}) {",

                    '$_OMNITRIG_slot_state->{fire_omnitrig_when_ready} = 1;',

                    @{$p->{icode_to_wrap} || []}, ';',

                    'next OMNITRIGGER;',
                '}',

                #
                #===================================================================================

                'my $_OMNITRIG_oldval = ' . ($p->{iexpr_oldval} || $iexpr_instance_has_and_get_ternary) . ';',

                @{$p->{icode_to_wrap} || []}, ';',

                "my \$_OMNITRIG_newval = $iexpr_instance_has_and_get_ternary;",

                $self_aka_attr->_inline_weaken_value($p->{iexpr_instance}, '$_OMNITRIG_newval->[0]'),

                "$p->{iexpr_instance}->\$_('$attr_name', \$_OMNITRIG_newval, \$_OMNITRIG_oldval) for \$_EE_OMNITRIG_attrs_omnitrigger{$attr_name};",

                "delete(\$_OMNITRIG_slot_state->{fire_omnitrig_when_ready});",
            '}',
        ];
    }

    # WHICH SETTERS/CLEARERS TO WRAP?

    # WE CAN'T WRAP Instance SETTERS, AS WE HAVE NO GOOD WAY OF KNOWING WHETHER THEY'RE BEING CALLED
    # FOR SET OR FOR SET-RAW OPS.

    # IDEALLY, WE WANT TO WRAP "BASIC" SETTERS/CLEARERS -- METHODS IN Moose::Meta::Attribute THAT DO
    # NOTHING MORE THAN SET/CLEAR THE VALUE THROUGH THE INSTANCE INTERFACE AS DIRECTLY AS POSSIBLE
    # AND THUS AREN'T LIKELY TO CHANGE. AND WE WANT TO WRAP NO MORE SETTERS/CLEARERS THAN ABSOLUTELY
    # NECESSARY, WHILE STILL INTERCEPTING EVERY "NORMAL" (AND OMITTING EVERY RAW AND INTERNAL-SPECIAL
    # -PURPOSE) SET/CLEAR OPERATION.

    #===============================================================================================
    # MUTABLE INIT-SETTER: THERE ARE A FEW CHOICES, HERE. IN THE END, ALL ROADS LEAD TO
    # _set_initial_slot_value, WHICH IS AS CLOSE AS WE CAN GET IN Attribute TO A BASIC INIT-SETTER.
    # IF THERE'S NO INITIALIZER, IT CALLS Instance::set_slot_value DIRECTLY, WHICH IS NICE; IF THERE
    # *IS* AN INITIALIZER, IT MAKES THE CALL THROUGH AN INITIALIZER WRITER CALLBACK THAT DOES
    # COERCION. NO WEAKENING.

    around _set_initial_slot_value => sub {

        my ($orig_method, $self_aka_attr, undef, $instance) = (shift, shift, @_);

        return $self_aka_attr->$orig_method(@_) unless $self_aka_attr->has_omnitrigger;

        my @args_lexical = @_;

        $self_aka_attr->_fire_omnitrigger({

            instance => $instance,

            sub_to_wrap => sub { $self_aka_attr->$orig_method(@args_lexical) },
        });

        # NO EXPLICIT RETVAL.
    };

    #
    #===============================================================================================

    #===============================================================================================
    # MUTABLE SETTER: NO CHOICE BUT set_value. IT INCLUDES SEVERAL BEHAVIORS APART FROM SIMPLY
    # SETTING THE VALUE, WHICH MAKES IT NOT THE MOST ATTRACTIVE HOOK (ALTHOUGH IT DOES DO
    # WEAKENING). TO PERFORM THE ACTUAL SET OP, IT CALLS SUPER (IN Class::MOP::Attribute), WHICH IS
    # A BETTER HOOK CANDIDATE, AS IT'S PRETTY MUCH A DIRECT LINE TO THE INSTANCE SETTER -- BUT I
    # CAN'T THINK OF A GOOD WAY TO HANG A METHOD MODIFIER ON Moose::Meta::Attribute'S *SUPER'S*
    # set_value WITHOUT CAUSING PROBLEMS. FORTUNATELY, IT LOOKS LIKE set_value IS THE ONLY (MUTABLE
    # NON-INIT) SETTER IN Attribute, AND IT'S ORGANIZED WITH TRIGGERS IN MIND, ANYWAY, WITH THE
    # TRIGGER OP BEING CONVENIENTLY THE LAST THING TO HAPPEN. WE CAN WRAP set_value AND FEEL
    # CAUTIOUSLY OK ABOUT IT.

    around [qw(set_value clear_value)] => sub {

        my ($orig_method, $self_aka_attr, $instance) = (shift, shift, @_);

        return $self_aka_attr->$orig_method(@_) unless $self_aka_attr->has_omnitrigger;

        my @args_lexical = @_;

        $self_aka_attr->_fire_omnitrigger({

            instance => $instance,

            sub_to_wrap => sub { $self_aka_attr->$orig_method(@args_lexical) },
        });

        # NO EXPLICIT RETVAL.
    };

    #
    #===============================================================================================

    #===============================================================================================
    # IMMUTABLE SETTER: _inline_instance_set DOESN'T DO WEAKENING, BUT OTHERWISE IT'S EXACTLY WHAT
    # WE'RE LOOKING FOR, HANDLING BOTH INIT-SETTING AND SETTING.

    around [qw(_inline_instance_set _inline_instance_clear)] => sub {

        my ($orig_method, $self_aka_attr, $iexpr_instance) = (shift, shift, @_);

        return $self_aka_attr->$orig_method(@_) unless $self_aka_attr->has_omnitrigger;

        return join("\n", ( # ORIG METHODS RETURN EXPRESSIONS AS STRINGS.

            'do {',

                @{$self_aka_attr->_icode_fire_omnitrigger({

                    icode_to_wrap => [map(ref($_) ? @$_ : $_, $self_aka_attr->$orig_method(@_))],

                    iexpr_instance => $iexpr_instance,
                })},
            '}',
        ));
    };

    #
    #===============================================================================================

    around _weaken_value => sub {

        # WE WRAP _weaken_value (AND _inline_weaken_value, BELOW) AS A BIT OF KLUDGERY TO PREVENT
        # THE WEAKENING OF ALREADY-WEAK VALUES (WHICH WOULD CAUSE Scalar::Util::weaken TO SQUAWK).

        my ($orig_method, $self_aka_attr, $instance) = (shift, shift, @_);

        return if $self_aka_attr->associated_class->get_meta_instance->slot_value_is_weak($instance, $self_aka_attr->name);

        return $self_aka_attr->$orig_method(@_);
    };

    around _inline_weaken_value => sub {

        my ($orig_method, $self_aka_attr, $iexpr_instance) = (shift, shift, @_);

        #===========================================================================================
        # THE ORIG METHOD TESTS ref($val) AND $attr->is_weak_ref; SO UNLESS THOSE PASS IT'LL RETURN
        # NOTHING AND WE CAN EARLY OUT. (STRANGE THAT _weaken_value DOESN'T DO THE SAME?)

        return unless my @icode_weaken_value = ($self_aka_attr->$orig_method(@_));

        #
        #===========================================================================================

        return ( # ORIG METHOD RETURNS CODE AS LIST.

            'unless (Scalar::Util::isweak(' . $self_aka_attr->associated_class->get_meta_instance->inline_slot_access($iexpr_instance, $self_aka_attr->name) . ')) {',

                @icode_weaken_value,
            '}',
        );
    };

    # around interpolate_class_and_new => sub {

    #   my ($orig_method, $self_aka_attr) = (shift, shift);

    #   my ($new_attr) = $self_aka_attr->$orig_method(@_);

    #   if ($new_attr->does('Moose::Meta::Attribute::Native::Trait')) {

    #       Moose::Util::ensure_all_roles($new_attr->meta, MooseX::OmniTrigger::MetaRole::Attribute::Native::Trait->meta);
    #   }

    #   return $new_attr;
    # };

    *Moose::Meta::Attribute::Custom::Trait::OmniTrigger::register_implementation = sub { __PACKAGE__ };
}

{ package MooseX::OmniTrigger::MetaRole::Instance; use namespace::autoclean;

    use Moose::Role;

    around clone_instance => sub {

        my ($orig_method, $self_aka_meta_instance, $instance) = (shift, shift, @_);

        my $clone = $self_aka_meta_instance->$orig_method($instance);

        #===========================================================================================
        # WOULD HAVE PREFERRED NOT TO INVADE CMOP::Instance FOR THIS, BUT THERE WAS NO PLACE INSIDE
        # CMOP::Class ITSELF TO SNEAK IN AN OMNITRIG STATE RESET *AFTER* THE BASIC CLONING OF THE
        # INSTANCE AND *BEFORE* THE SETTING OF INITVALS.

        MooseX::OmniTrigger::State->singleton->reset($clone);

        #
        #===========================================================================================

        return $clone;
    };
}

{ package MooseX::OmniTrigger::MetaRole::Method::Accessor::Native::Writer; use namespace::autoclean;

    use Moose::Role;

    around _inline_set_new_value => sub {

        my ($orig_method, $self_aka_accessor, $iexpr_instance) = (shift, shift, @_);

        my $attr = $self_aka_accessor->associated_attribute;

        return $self_aka_accessor->$orig_method(@_) unless $attr->can('has_omnitrigger') && $attr->has_omnitrigger;

        return join("\n", @{$attr->_icode_fire_omnitrigger({ # ORIG METHOD RETURNS CODE AS STRING.

            icode_to_wrap => [map(ref($_) ? @$_ : $_, $self_aka_accessor->$orig_method(@_))],

            iexpr_instance => $iexpr_instance,

            iexpr_oldval => sprintf('[%s ? %s : ()]',

                $self_aka_accessor->_has_value($iexpr_instance),

                $self_aka_accessor->can('_copy_old_value')
                    ? $self_aka_accessor->_copy_old_value($self_aka_accessor->_get_value($iexpr_instance))
                    :                                     $self_aka_accessor->_get_value($iexpr_instance) ,
            ),
        })});
    };
}

#===================================================================================================
# THIS IS PROMISCUOUS, AS IT WILL AFFECT Moose::Meta::Method::Accessor::Native::Writer FOR ALL
# CLASSES, NOT JUST MooseX::OmniTriggerED ONES. IT DOESN'T LOOK LIKE Moose::Exporter CAN HELP OUT,
# HERE, BUT MAYBE I'M MISSING SOMETHING. ANYWAY, IT WAS EITHER THIS, WHICH THOUGH PROMISCUOUS IS
# DIRECT, OR A BIT OF KLUDGERY INVOLVING WRAPPING MM::Attribute::interpolate_class_and_new AND
# MM::Attribute::Native::Trait::_native_accessor_class_for, WHICH I'M NOT SURE WOULD'VE BEEEN ANY
# BETTER CONSIDERING THE ANON CLASS CACHING GOING ON THERE. THE GOAL IS TO WRAP _inline_set_new_value.

for ('Moose::Meta::Method::Accessor::Native::Writer') {

    Class::Load::load_class($_);

    Moose::Util::ensure_all_roles($_, MooseX::OmniTrigger::MetaRole::Method::Accessor::Native::Writer->meta);
}

#
#===================================================================================================

# { package MooseX::OmniTrigger::MetaRole::Attribute::Native::Trait;
#
#   use Moose::Role;
#
#   around _native_accessor_class_for => sub {
#
#       my ($orig_method, $self_aka_attr) = (shift, shift);
#
#       my $native_accessor_class = $self_aka_attr->$orig_method(@_);
#
#       Moose::Util::ensure_all_roles($native_accessor_class, MooseX::OmniTrigger::MetaRole::Method::Accessor::Native::Writer->meta);
#
#       $native_accessor_class;
#   };
# }

1;

__END__
=head1 NAME

MooseX::OmniTrigger -- Provide Moose attributes with recursion-proof triggers that fire on any init,
set, or clear operation.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    { package MyClass;

        use Moose;
        use MooseX::OmniTrigger;

        has foo => (is => 'rw', isa => 'Str', default => 'FRELL',                  omnitrigger => \&_callback);
        has bar => (is => 'rw', isa => 'Str',                     lazy_build => 1, omnitrigger => \&_callback);

        has baz => (is => 'rw', isa => 'Str', omnitrigger => sub { $_[0]->baz("$_[2][0]!!!") });

        sub _callback {

            my ($self, $attr_name, $new, $old) = (shift, @_);

            warn("attribute $attr_name has been ", @$new ? 'set' : 'cleared');

            warn('   oldval: ', @$old ? $old->[0] // 'UNDEF' : 'NOVAL');
            warn('   newval: ', @$new ? $new->[0] // 'UNDEF' : 'NOVAL');
        }

        sub _build_bar { 'DREN' }
    }

    my $obj = MyClass->new;

    # attribute 'foo' has been set
    #    oldval: NOVAL
    #    newval: FRELL

    say $obj->bar; # DREN

    # attribute 'bar' has been set
    #    oldval: NOVAL
    #    newval: DREN

    $obj->clear_bar;

    # attribute 'bar' has been cleared
    #    oldval: DREN
    #    newval: NOVAL

    $obj->baz('YOTZ');

    say $obj->baz; # YOTZ!!!

=head1 DESCRIPTION

Sometimes you want to know when your attributes' values change. No matter when! No matter how!

MooseX::OmniTrigger is an effort to provide Moose attributes with triggers that may to some folks
behave more DWIMmily than standard Moose triggers, working around the documented feature/bug/caveat,
"Triggers will only fire when you assign to the attribute, either in the constructor, or using the
writer. Default and built values will not cause the trigger to be fired."

An omnitrigger fires any time its attribute's value is initialized, set, or cleared. This includes
initialization with default and built values, lazy or no, and sets via native type accessors.

The callback is given as a subref, and receives four arguments: the object, the attribute name, the
new value, and the old value. The new and old values are given as array refs. An empty array
indicates *no* value -- the slot is uninitialized or has been cleared. Otherwise, the value will be
the first (and only) array element.

Omnitriggers are recursion-proof. Firings beyond the first of a particular omnitrigger in the same
call stack are quietly prevented.

=head1 CAVEATS

MooseX::OmniTrigger currently requires Moose 2.02. Compatibility with older Mooses is TODO.

=head1 AUTHOR

Todd Lorenz <trlorenz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Todd Lorenz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
