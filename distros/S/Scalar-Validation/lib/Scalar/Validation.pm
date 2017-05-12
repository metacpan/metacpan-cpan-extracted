# perl
#
# Class Scalar::Validation
#
# Simple rule based validation package for scalar values
#
# Ralf Peine, Sat Oct 25 15:10:22 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "0.700";

package Scalar::Validation;

use base qw (Exporter);

use strict;
use warnings;

our @EXPORT = qw();
our @EXPORT_OK = qw (validate is_valid validate_and_correct npar named_parameter par parameter 
                     get_rules rule_known declare_rule delete_rule replace_rule enum Enum enum_explained Enum_explained
                     greater_than greater_equal less_than less_equal equal_to g_t g_e l_t l_e
                     is_a 
                     p_start parameters_start convert_to_named_params parameters_end p_end
                     validation_trouble get_validation_trouble_level add_validation_trouble
                     validation_messages get_and_reset_validation_messages prepare_validation_mode
                     meta_info_clear build_meta_info_for_module end_meta_info_gen get_meta_info list_meta_info
);

our %EXPORT_TAGS = (
        all => [qw(validate is_valid validate_and_correct npar named_parameter par parameter
                   get_rules rule_known declare_rule delete_rule replace_rule enum Enum enum_explained Enum_explained
                   greater_than greater_equal less_than less_equal equal_to g_t g_e l_t l_e
                   is_a
                   p_start parameters_start convert_to_named_params parameters_end p_end
                   validation_trouble get_validation_trouble_level add_validation_trouble
                   validation_messages get_and_reset_validation_messages prepare_validation_mode
                   meta_info_clear build_meta_info_for_module end_meta_info_gen get_meta_info list_meta_info
)],);               

use Carp;
# use Data::Dumper;

# ------------------------------------------------------------------------------
#
# Initiliazation
#
# ------------------------------------------------------------------------------

our $ignore_callers    = { __PACKAGE__ , 1 };
our $ignore_caller_pattern;

sub _update_caller_pattern {
    $ignore_caller_pattern = eval ("qr/^(".join("|",keys (%$ignore_callers)).")/o");
}

sub ignore_caller {
    my $module_string = shift;

    die "not a module string: '$module_string'" unless $module_string || $module_string =~ /^[\w:]+$/;
    
    $ignore_callers->{$module_string} = 1;
    update_caller_pattern();
}

_update_caller_pattern();

_init_private_calls();
_init_run_API();

# _init_doc_API();

# ------------------------------------------------------------------------------
#
# default actions, not changable
#
# ------------------------------------------------------------------------------

our $call_info = '';

my $croak_sub = sub { croak "Error: ",@_; };
my $get_caller_info_default = sub {
    my ($module, $file_name, $line, $sub_name);
    $sub_name     = __PACKAGE__;
    my $call_level_iter = 1;

    while ($sub_name =~ $ignore_caller_pattern) {
        ($module, $file_name, $line, $sub_name) = caller($call_level_iter++);
        $sub_name = '' unless $sub_name;
    }
    
    $sub_name = "MAIN" unless $sub_name;
    return $sub_name;
};

# ------------------------------------------------------------------------------
#
# variables my be overwritten by user
#
# ------------------------------------------------------------------------------

our $message_store   = undef; # local $Scalar::Validation::message_store = []; # to start storing messages
our $trouble_level   = 0;     # to count failed validations. Not affected by is_valid(...)
our $off             = 0;     # no validation checks if $off == 1
our $validate_defaults = 1;     # validate default values defined by -Default rule, if set

# ------------------------------------------------------------------------------
#
# actions, changable
#
# ------------------------------------------------------------------------------

our $fail_action     = $croak_sub;
our $get_caller_info = $get_caller_info_default;

# ------------------------------------------------------------------------------
#
#  private vars of Validation "Instance"
#
# ------------------------------------------------------------------------------
my $non_blessed = {
    REF   => 1,
    ARRAY => 1,
    HASH  => 1,
};

my $special_rules;
my $rule_store;
my $get_content_subs;


my $class_meta_model = {};
my $doc_class_name;
my $doc_class_method;

# ------------------------------------------------------------------------------
#
# normal rules, can be added, replaced, removed
#
# ------------------------------------------------------------------------------

$rule_store = {

    # --- This rules are needed for Validation.pm to work, don't delete or change! ---
        
    Defined     =>   { -name    => 'Defined',
                       -where   => sub { defined $_ },
                       -message => sub { "value is not defined" },
                       -owner   => 'CPAN',
                       -description => "Value is defined",
    },
    Filled      =>   { -name    => 'Filled',
                       -where   => sub { defined $_ and ref($_) eq '' and $_ ne '' },
                       -message => sub { "value is not set" },
                       -owner   => 'CPAN',
                       -description => "Value is Scalar and defined and not empty ('')",
    },
    Empty       =>   { -name    => 'Empty',
                       -where   => sub { !defined $_ or $_ eq '' },
                       -message => sub { "value $_ has to be empty" },
                       -owner   => 'CPAN',
                       -description => "Value is not defined or ''",
    },
    Optional    =>   { -name    => 'Optional',
                       -where   => sub { 1; },
                       -message => sub { "value is optional" },
                       -owner   => 'CPAN',
                       -description => "Value is optional, cannot fail. Use as last entry in -Or rule.",
    },
    String      =>   { -name    => 'String',
                       -where   => sub { defined $_ and ref($_) eq '' },
                       -message => sub { "value $_ is not a string" },
                       -owner   => 'CPAN',
                       -description => "Values is a Scalar and defined",
    },
    Int =>           { -name    => 'Int',
                       -as      => 'Filled',
                       -where   => sub { /^[\+\-]?\d+$/ },
                       -message => sub { "value $_ is not an integer" },
                       -owner   => 'CPAN',
                       -description => "Value is an integer",
    },
    Even =>          { -name    => 'Even',
                       -as      => 'Int',
                       -where   => sub { $_ % 2 ? 0: 1; },
                       -message => sub { "value $_ is not an integer or not even"},
                       -owner   => 'CPAN',
                       -description => 'Value is an even integer ($_ % 2 == 0)',
    },
    Scalar      =>   { -name    => 'Scalar',
                       -where   => sub { ref($_) eq '' },
                       -message => sub { "value $_ is not a scalar" },
                       -owner   => 'CPAN',
                       -description => 'Value is a Scalar : ref ($_) eq ""',
    },
    Ref         =>   { -name    => 'Ref',
                       -where   => sub { $_ and ref($_) ne '' },
                       -message => sub { "value $_ is not a reference" },
                       -owner   => 'CPAN',
                       -description => "Value is a reference and not a scalar.",
    },
    ArrayRef    =>   { -name    => 'ArrayRef',
                       -where   => sub { $_ and ref($_) eq 'ARRAY' },
                       -message => sub { "value $_ is not a array reference" },
                       -owner   => 'CPAN',
                       -description => "Value is an Array reference.",
    },
    HashRef     =>   { -name    => 'HashRef',
                       -where   => sub { $_ and ref($_) eq 'HASH' },
                       -message => sub { "value $_ is not a hash reference" },
                       -owner   => 'CPAN',
                       -description => "Value is a Hash reference.",
    },
    CodeRef     =>   { -name    => 'CodeRef',
                       -where   => sub { $_ and ref($_) eq 'CODE' },
                       -message => sub { "value $_ is not a code reference" },
                       -owner   => 'CPAN',
                       -description => "Value is a Code reference.",
    },
    Class       =>   { -name    => 'Class',
                       -where   => sub { return 0 unless $_;
                                         my $type_name = ref($_);
                                         !$type_name || $non_blessed->{$type_name} ? 0: 1;
                       },
                       -message => sub { "value $_ is not a reference" },
                       -owner   => 'CPAN',
                       -description => "Value is a reference and not a scalar.",
    },
    ModuleName  =>   { -name    => 'ModuleName',
                       -as      => Filled =>
                       -where   => sub { /^\w+(::\w+)*$/;
                       },
                       -message => sub { "value $_ is not a module name like A::Ba::Cba" },
                       -owner   => 'CPAN',
                       -description => "Value is a module name like A::Ba::Cba.",
    },

    # --- Some additional global rules --------------------
        
    ExistingFile  => { -name    => 'ExistingFile',
                       -as      => 'Filled',
                       -where   => sub { -f $_ },
                       -message => sub { "$_ is not a valid name of an existing file"},
                       -owner   => 'CPAN',
                       -description => "File with given file name has to exist"
    },

    Bool =>          { -name    => 'Bool',
                       -where   => sub { ref ($_) ? 0: 1 },
                       -message => sub { "value $_ is not a bool value" },
                       -owner   => 'CPAN',
                       -description => "Value is a Scalar, all values including undef allowed",
    },
    PositiveInt =>   { -name    => 'PositiveInt',
                       -as      => 'Int',
                       -where   => sub { $_ >= 0 },
                       -message => sub { "value $_ is not a positive integer" },
                       -owner   => 'CPAN',
                       -description => "Value is a positive integer",
    },
    NegativeInt =>   { -name    => 'NegativeInt',
                       -as      => 'Int',
                       -where   => sub { $_ < 0 },
                       -message => sub { "value $_ is not a negative integer" },
                       -owner   => 'CPAN',
                       -description => "Value is a negative Integer",
    },
    Float =>         { -name    => 'Float',
                       -as      => 'Filled',
                       -where   => sub { /^[\+\-]?\d+(\.\d+)?([Ee][\+-]?\d+)?$/ },
                       -message => sub { "value $_ is not a float" },          
                       -owner   => 'CPAN',
                       -description => "Value is a floating number with optional exponent",
    },
    PositiveFloat => { -name    => 'PositiveFloat',
                       -as      => 'Float',
                       -where   => sub { $_ > 0 },
                       -message => sub { "value $_ is not a positive float" },         
                       -owner   => 'CPAN',
                       -description => "Value is a positive floating number with optional exponent",
    },
    NegativeFloat => { -name    => 'NegativeFloat',
                       -as      => 'Float',
                       -where   => sub { $_ < 0 },
                       -message => sub { "value $_ is not a negative float" },         
                       -owner   => 'CPAN',
                       -description => "Value is a negative floating number with optional exponent",
    },
};

# ------------------------------------------------------------------------------
#
# gets content of ref container
#
# ------------------------------------------------------------------------------

$get_content_subs = {
        HASH  => sub { my @keys = keys %$_; return scalar @keys ? \@keys: undef; },
        ARRAY => sub { return scalar @$_ ? $_: undef; },
};

# ------------------------------------------------------------------------------
#
# special rules (combined and other), not changable
#
# ------------------------------------------------------------------------------

$special_rules = {
    -Optional => {
        -value_position => 3,
        -code           => sub {
            # my  $subject_info = shift || '';
            # my  $rule_info    = shift;
            local $_            = $_[2];

            # skip one param if special rule follows
            my $special_rule = $special_rules->{$_[1]};
            if ($special_rule) {
                $_ = $_[$special_rule->{-value_position}];
            }
            ;
        
            return $_ if !defined $_; # value not set
            return validate(@_);
        },
	-print_args => sub {
	    eval {
		my $rule    = shift;
		
		return "-Optional [$rule]";
	    }
	}
    },
    -Default => {
        -value_position => 4,
        -code           => sub {
            my  $subject_info = shift || '';
            my  $default      = shift;
            my  $rule_info    = shift;
            # local $_          = $_[3];

            my $value_idx = 0;

            # --- skip x params if special rule follows ---
            my $special_rule = $special_rules->{$rule_info};
            if ($special_rule) {
                my $special_idx = $special_rule->{-value_position};
                $value_idx = $special_idx - 2 if $special_idx >= 0;
            }

            my $value = $_[$value_idx];

            # --- value set, validate it ---
            return validate($subject_info, $rule_info, @_)
                if (defined $value && $value ne '');

            # --- value not set ----
            unless (defined $default) {
                $trouble_level++;
                $fail_action->("Rules: Default value for rule -Default not set!");
                return $_;
            }

            if (ref($default) eq 'CODE') {
                $default = $default->();
            }

            return $default unless $validate_defaults;

            my @args = @_;
            
            $args[$value_idx] = $default;

            # --- default has also to be validated!! ---
            return validate($subject_info, $rule_info, @args)
        },
	-print_args => sub {
	    eval {
		my $default = shift;
		my $rule    = shift;
		
		return "-Default = '$default' [$rule]";
	    }
	}
    },
    -And => {
        -value_position => 3,
        -code           => sub {
            my    $subject_info = shift || '';
            my    $rule_list    = shift;
            local $_            = shift;
            my    $message_ref  = shift;
            
            my $rule_exists  = 0;
            my $orig_value   = $_;
            
            foreach my $rule (@$rule_list) {
                if (!defined $rule || $rule eq '') {
                    $trouble_level++;
                    $fail_action->("Rules: rule for validation not set");
                    next        # in case of fail action doesn't die
                }
                
                if ($rule) {
                    my $special_rule = $special_rules->{$rule};
                    
                    if ($special_rule) {
                        $trouble_level++;
                        $fail_action->("Rules: cannot call any special rule inside of rule '-And'\n");
                        next;
                    }                        

                    validate ($subject_info, $rule, $_, $message_ref);
                    $rule_exists = 1;
                }
            }
            
            $trouble_level++;
            $fail_action->("Rules: No rule found in list to be validated") unless $rule_exists;
            
            return $orig_value;
        },
        -print_args => sub {
            my    $rule_list    = shift;
            
	    delete $rule_list->[$#$rule_list] unless $rule_list->[$#$rule_list];
	    my $arg_info = join (', ', @$rule_list);
	    $arg_info = 'no argument informations' unless $arg_info;

	    return "-And [$arg_info]";
	}
    },
    -Or => {
        -value_position => 3,
        -code           => sub {
            my    $subject_info = shift || '';
            my    $rule_list    = shift;
            local $_            = shift;
            my    $message_ref  = shift;
            
            my $rule_exists  = 0;
            my $orig_value   = $_;
            
            foreach my $rule_info (@$rule_list) {
                if (!defined $rule_info || $rule_info eq '') {
                    $trouble_level++;
                    $fail_action->("Rules: rule for validation not set");
                    next        # in case of fail action doesn't die
                }
                
                next unless $rule_info;
                
                my $rule_ref = $rule_store->{$rule_info};
                unless ($rule_ref) {
                    my $special_rule = $special_rules->{$rule_info};
                    
                    if ($special_rule) {
                        $trouble_level++;
                        $fail_action->("Rules: cannot call any special rule inside of rule '-Or'\n");
                        next;
                    }                        

                    my $ref_type = ref ($rule_info);
                        
                    unless ($ref_type) {
                        $trouble_level++;
                        $fail_action->("Rules: unknown rule '$rule_info' for validation");
                        next; # in case of fail action doesn't die
                    } elsif ($ref_type eq 'HASH') { # given rule
                        $rule_ref = $rule_info;
                        # TODO: validate rule ...
                    } elsif ($ref_type eq 'CODE') { # where condition for rule
                        $rule_ref = {
                            -where   => $rule_info,
                            -message => sub { "$_ does not match free defined rule" },
                        };
                    } else {
                        $trouble_level++;
                        $fail_action->("Rules: cannot handle ref type '$ref_type' of rule '$rule_info' for validation");
                        next;   # in case of fail action doesn't die
                    }
                }

                if ($rule_ref) {
                    my $test_message_ref = $message_ref || $rule_ref->{-message};

                    my $parent_is_valid = defined $rule_ref->{-as}
                        ? _check_parent_rules($rule_ref->{-as}, $_)
                            : 1;
                    return $orig_value if $parent_is_valid && $rule_ref->{-where}->();

                    $rule_exists = 1;
                }
            }
        
            $trouble_level++;
            $fail_action->("Rules: No rule found in list to be validated") unless $rule_exists;

            my $result = _do_fail($subject_info, $message_ref || sub { "No rule matched of [".join(', ', @$rule_list)."]";});
            return $result if defined $result;

            return $orig_value;
        },
        -print_args => sub {
            my    $rule_list    = shift;
            
	    delete $rule_list->[$#$rule_list] unless $rule_list->[$#$rule_list];
	    my $arg_info = join (', ', @$rule_list);
	    $arg_info = 'no argument informations' unless $arg_info;

	    return "-Or [$arg_info]";
	}
    },
    -Enum => {
        -value_position => 3,
        -code           => sub {
            my    $subject_info = shift || '';
            my    $enum_ref     = shift;
            local $_            = shift;
            my    $message_ref  = shift;
        
            my $orig_value      = $_;

            my $arg_type = ref ($enum_ref);
            if ($arg_type eq 'ARRAY') {
                $enum_ref = { map {$_=> 1} @$enum_ref };
            }
            elsif ($arg_type ne 'HASH') {
                _do_fail($subject_info, sub {"-Enum needs HASH_ref as second parameter";});
            }

            unless (defined $_ && $enum_ref->{$_}) {
                my $result = _do_fail($subject_info, $message_ref ||
                             sub { "value $_ unknown, allowed values are: [ "
                                       .join (", ", sort (keys(%$enum_ref)))." ]"; }
                         );
                return $result if defined $result;

            }
            return $orig_value;
        },
        -print_args => sub {
            my $enum_ref = shift;

	    my $arg_info = 'no argument informations';
            my $arg_type = ref ($enum_ref);
            if ($arg_type eq 'ARRAY') {
		$arg_info = join (', ', @$enum_ref);
            }
            elsif ($arg_type eq 'HASH') {
		$arg_info = join (', ', sort(keys(%$enum_ref)));
            }
	    return "Enum [$arg_info]";
	}
    },
    -Range => {
        -value_position => 4,
        -code           => sub {
            my    $subject_info = shift || '';
            my    $range_ref    = shift;
            my    $rule         = shift;
            local $_            = shift;
            my    $message_ref  = shift;
        
            my $wrong_call_message_sub_ref
                = sub { "-Range needs ARRAY_ref containing two values [min max] as second parameter" };

            my $orig_value = $_;
        
            unless (ref($range_ref) eq 'ARRAY') {
                _do_fail($subject_info, $wrong_call_message_sub_ref);
                return $orig_value;
            }

            unless (scalar @$range_ref == 2) {
                _do_fail($subject_info, $wrong_call_message_sub_ref);
                return $orig_value;
            }

            my ($min, $max) = @$range_ref;
            if ($min > $max) {
                _do_fail($subject_info, sub { "(min) $min > $max (max) in range definition"; });
                return $orig_value;
            }

            # type check by is_valid to return here if fails
            my @messages;
            my $is_valid;
            {
                local ($message_store) = [];
                $is_valid = is_valid ($subject_info, $rule, $_, $message_ref);
                @messages = @{validation_messages()};
            }
            
            unless ($is_valid) {
                my $message = join ("\n", @messages);
                push (@$message_store, $message) if $message_store;
                $trouble_level++;
                my $result = $fail_action->($message);
                return $result if defined $result;

                return $orig_value;
            }
        
            unless ($min <= $_  &&  $_<= $max) {
                my $result = _do_fail($subject_info, sub {"value $_ is out of range [$min,$max]"});
                return $result if defined $result;
                return $orig_value;
            }

            return $orig_value;
        },
        -print_args => sub {
            my    $range_ref    = shift;
            my    $rule         = shift;
	    my    $min          = $range_ref->[0];
	    my    $max          = $range_ref->[1];
	    return "Range [$min,$max] of type $rule";
	}
    },
    -RefEmpty => {
        -value_position => 3,
        -code => sub {
            
            my    $subject_info = shift || '';
            local $_            = shift;
            my    $message_ref  = shift;
            
            my $content_ref = _ref_empty_check($subject_info, $_, $message_ref);
            
            return undef unless defined $content_ref;
            
            my $count_results = scalar @$content_ref;
            return 0 unless $count_results;
            
            _do_fail($subject_info, sub { "Should be empty, but contains $count_results entries: [ ".
                                              join (", ", @$content_ref)." ];" });
            
            return $count_results;
        },
        -print_args => sub {
	    return "EmptyReference";
	}
    },
};

# ------------------------------------------------------------------------------
#
# internal Methods
#
# ------------------------------------------------------------------------------

sub _handle_enum_explained {
    my $transform_key_ref = shift;
    my $transformed_text  = shift;
    my $rule_name         = shift;
    my @enum_args;
    my @enums_list;
    my %enums;
    
    foreach my $arg (@_) {
        if ($arg eq 1 or $arg eq 0) {
            # arg is complete
            my $last_idx = $#enum_args;

            if ($last_idx < 1) {
                $trouble_level++;
                $fail_action->("Rules: not enough configuration values for enum '$enum_args[0]'");
            }
            
            my $explanation = $enum_args[$last_idx];
            map { my $key = $transform_key_ref ? $transform_key_ref->($_): $_;
                  $enums{$key} = $explanation;
                  push (@enums_list, $key);
              } @enum_args[0..--$last_idx];
            @enum_args = ();
        }
        else {
            push (@enum_args, $arg);
        }
    }

    my $validation_sub_ref = $transform_key_ref
        ? sub { defined $_ && defined $enums{$transform_key_ref->($_)} }
            : sub { defined $_ && defined $enums{$_} };
        
    return ($rule_name,
            -where   => $validation_sub_ref,
            -enum    => \%enums,
            -message => sub { "$rule_name: value $_ unknown, allowed values$transformed_text ".
                                  "are: [ ".join (", ", @enums_list)." ]" }
        );
}

sub _check_parent_rules {
    my    $rule_name    = shift;
    local $_            = shift;

    my $orig_value      = $_;

    my $rule_ref = $rule_store->{$rule_name};

    unless ($rule_ref) {
        $trouble_level++;
        $fail_action->("Rules: unknown rule '$rule_name' for validation");
        return 0; # in case of fail action doesn't die
    }
    
    if (defined $rule_ref->{-as}) {
        return 0 unless _check_parent_rules($rule_ref->{-as}, $_);
    }
    
    return $rule_ref->{-where}->();
}

sub _ref_empty_check {
        my    $subject_info = shift || '';
        local $_            = shift;
        my    $message_ref  = shift;

        my $ref_type = ref($_);

        unless ($ref_type) {
                _do_fail($subject_info, sub { "Not a reference: $_" });
                return undef;
        } 
        
        my $get_contents_ref = $get_content_subs->{$ref_type};

        unless ($get_contents_ref) {
                _do_fail($subject_info, sub { "could not check, if $ref_type is empty" });
                return undef;
        }
        
        return $get_contents_ref->();
}

sub _do_fail {
    my $subject_info = shift;
    my $message_ref  = shift;

    $trouble_level++;

    $_ = defined ($_) ? "'$_'" : '<undef>';

    my $message = $get_caller_info->()."($call_info$subject_info): ".$message_ref->();
    push (@$message_store, $message) if $message_store;

    return $fail_action->($message);
}

# ------------------------------------------------------------------------------
#
# API Methods
#
# ------------------------------------------------------------------------------

sub _init_run_API {
    *p_start          = *_do_parameters_start;
    *parameters_start = *_do_parameters_start;

    *p_end            = *_do_parameters_end;
    *parameters_end   = *_do_parameters_end;

    *npar             = *_do_named_parameter;
    *named_parameter  = *_do_named_parameter;

    *parameter        = *_do_validate_parameter;
    *par              = *_do_validate_parameter;

    *validate         = *_do_validate_call;
    *is_valid         = *_do_is_valid;

    *get_api_doc      = *get_api_documentation;

    *g_t       = *greater_than;
    *g_e       = *greater_equal;
    *l_t       = *less_than;
    *l_e       = *less_equal;

}

sub _init_private_calls {
    *_p_npar             = *_do_named_parameter;
    *_p_named_parameter  = *_do_named_parameter;
    
    *_p_parameter        = *_do_validate_parameter;
    *_p_par              = *_do_validate_parameter;
    
    *_p_validate         = *_do_validate_call;
    *_p_is_valid         = *_do_is_valid;
}

sub _get_meta_extraction_code {
    my $module_name = shift;
    return "
    use $module_name;
    *".$module_name."::p_start          = *".__PACKAGE__."::_start_sub_meta_extraction;
    *".$module_name."::parameters_start = *".__PACKAGE__."::_start_sub_meta_extraction;
                       
    *".$module_name."::p_end            = *".__PACKAGE__."::_end_sub_meta_extraction;
    *".$module_name."::parameters_end   = *".__PACKAGE__."::_end_sub_meta_extraction;
                       
    *".$module_name."::npar             = *".__PACKAGE__."::_sub_meta_extract_named_parameter;
    *".$module_name."::named_parameter  = *".__PACKAGE__."::_sub_meta_extract_named_parameter;
                       
    *".$module_name."::parameter        = *".__PACKAGE__."::_sub_meta_extract_positional_parameter;
    *".$module_name."::par              = *".__PACKAGE__."::_sub_meta_extract_positional_parameter;
                       
    *".$module_name."::validate         = *".__PACKAGE__."::_sub_meta_no_extraction;
";
}

sub _reset_validation_code {
    my $module_name = shift;
    return "
    use $module_name;
    *".$module_name."::p_start          = *".__PACKAGE__."::_do_parameters_start;
    *".$module_name."::parameters_start = *".__PACKAGE__."::_do_parameters_start;
                       
    *".$module_name."::p_end            = *".__PACKAGE__."::_do_parameters_end;
    *".$module_name."::parameters_end   = *".__PACKAGE__."::_do_parameters_end;
                       
    *".$module_name."::npar             = *".__PACKAGE__."::_do_named_parameter;
    *".$module_name."::named_parameter  = *".__PACKAGE__."::_do_named_parameter;
                       
    *".$module_name."::parameter        = *".__PACKAGE__."::_do_validate_parameter;
    *".$module_name."::par              = *".__PACKAGE__."::_do_validate_parameter;
                       
    *".$module_name."::validate         = *".__PACKAGE__."::_do_validate_call;
";
}

sub _do_parameters_start {
    return $trouble_level;
}

sub convert_to_named_params {
        my $array_ref = _p_validate (args => ArrayRef => shift);

        _p_validate (arg_count => Even => scalar @$array_ref =>
                                  sub { "Even number of args needed to build a hash, but arg-count = $_" });
        return @$array_ref;
}

sub _do_parameters_end {

    my $container_ref = _p_par (container_ref => -Or => [HashRef => 'ArrayRef'] => shift);
    my $message_text  = _p_par (message_text  => Scalar => shift) || "extra parameters found";

    my $container_type = ref ($container_ref);
    if ($container_type eq 'ARRAY') {
        _p_validate (parameters => sub { scalar @$container_ref == 0 } => $container_ref => sub { "$message_text: [ '".join ("', '", @$container_ref)."' ]"; });
        return scalar @$container_ref;
    }
    elsif ($container_type eq 'HASH') {
        my @arg_names = keys %$container_ref;
        _p_validate (parameters => sub { scalar @arg_names == 0 } => $container_ref => sub { "$message_text: [ '".join ("', '", @arg_names)."' ]"; });
        return scalar @arg_names;
    }

    _do_fail("parameters_end()", sub { "unknown reference type $container_ref" });
    return -1;
}

# ------------------------------------------------------------------------------
#
# Meta Information Mode
#
# ------------------------------------------------------------------------------

sub meta_info_clear {
    print "# Start API documentation ==============================\n";
    $class_meta_model = {};
}

sub build_meta_info_for_module {
    end_meta_info_gen();
    $doc_class_name = _p_par(module_name => ModuleName => shift);
    my $instance_creator = _p_par(instance_creation => -Optional => CodeRef => shift);

    # --- run sub -------------------------------------------------

    # print "# Module: $doc_class_name; # ==============================\n";
    $class_meta_model->{$doc_class_name} = {};
    $class_meta_model->{$doc_class_name}->{subs} = {};
    eval (_get_meta_extraction_code($doc_class_name)); print $@ if $@;
    
    $instance_creator = eval ('sub { return '.$doc_class_name.'->new(); }')
	unless $instance_creator;

    return $instance_creator->();
}

sub end_meta_info_gen {
    eval (_reset_validation_code($doc_class_name)) if $doc_class_name; print $@ if $@;
}

sub get_meta_info {
    return $class_meta_model;
}

sub list_meta_info {
    my @meta_info_list;

    foreach my $pm (sort (keys (%$class_meta_model))) {
	my $subs     = $class_meta_model->{$pm}->{subs};

	foreach my $sub_name (sort (keys (%$subs))) {
	    my $parameters = $subs->{$sub_name}->{params};
	    my %sub_info = (module => $pm, 
			    sub => $sub_name);

	    if (scalar (@$parameters)) {
		foreach my $parameter (@$parameters) {
		    my %par_info = (%$parameter, %sub_info);
		    push (@meta_info_list, \%par_info);
		}
	    }
	    else { # sub has no parameters
		$sub_info{rule} = $sub_info{kind} = $sub_info{name} = ''; 
		push (@meta_info_list, \%sub_info);
	    }
	}
    }

    return \@meta_info_list;
}

sub _start_sub_meta_extraction { # parameters_start
    $doc_class_method = $get_caller_info->();
    $doc_class_method =~ s/.*\:\://og;
    $class_meta_model->{$doc_class_name}->{subs}->{$doc_class_method} = {};
    $class_meta_model->{$doc_class_name}->{subs}->{$doc_class_method}->{params} = [];
    # print "\tMethod: $doc_class_method  # ---------------------------------------\n";
    return 0;
}

sub _end_sub_meta_extraction { # parameters_end
    # print "\t# --- end method documentation ---\n";
    $trouble_level++;
    return 0;
}

sub _sub_meta_extract_named_parameter { # named_parameter
    my $argument_infos = _api_doc_get_argument_info(@_);
    push (@{$class_meta_model->{$doc_class_name}->{subs}->{$doc_class_method}->{params}},
	  {
	      kind => Named =>
	      name => $argument_infos->[0],
	      rule => $argument_infos->[1],
	  }
	);

    local ($Scalar::Validation::off) = 1;
    $trouble_level++;
    return _do_named_parameter(@_);
}

sub _sub_meta_extract_positional_parameter { # parameter
    my $argument_infos = _api_doc_get_argument_info(@_);
    # print "\t\tPositional Parameter: $argument_info_str\n";
    push (@{$class_meta_model->{$doc_class_name}->{subs}->{$doc_class_method}->{params}},
	  {
	      kind => Positional =>
	      name => $argument_infos->[0],
	      rule => $argument_infos->[1],
	  }
	);

    local ($Scalar::Validation::off) = 1;
    $trouble_level++;
    return _do_validate_parameter(@_);
}

sub _sub_meta_no_extraction { # validate
    # print "_sub_meta_no_extraction ".join (', ', @_)."\n";
    local ($Scalar::Validation::off) = 1;
    $trouble_level++;
    return _do_validate_call(@_);
}

sub _api_doc_get_argument_info {
    my $name      = shift;
    my $rule_info = shift;

    unless ($rule_info) {
        $trouble_level++;
        $fail_action->("rule for validation not set");
        return [$_]; # in case of fail action doesn't die
    }

    my $rule_ref = $rule_store->{$rule_info};

    my $rule_info_string = 'No info for rule';

    if ($rule_ref) {
	$rule_info_string = $rule_ref->{-name};
    }
    else {
	my $special_rule_name = $rule_info;
	# print "$rule_info, ".join(', ', @_)."\n";
	$rule_ref = $special_rules->{$special_rule_name};
	if ($rule_ref) {
	    my $last_idx = scalar(@_);
	    if ($last_idx >= 0) {
		my $print_args = $rule_ref->{-print_args};
		if ($print_args) {
		    $rule_info_string = $print_args->(@_);
		}
		else {
		    $fail_action->("print_args missing for rule '$special_rule_name'");
		}
	    }
	}
    }

    unless ($rule_ref) {
        my $ref_type = ref ($rule_info);
        
        unless ($ref_type) {
            $trouble_level++;
	    my $error_message = "unknown rule '$rule_info' for validation";
            $fail_action->($error_message);
            return [$error_message];
        }
        elsif ($ref_type eq 'HASH') { # given rule
            $rule_ref = $rule_info;
            # TODO: _p_validate rule ...
        }
        elsif ($ref_type eq 'CODE') { # where condition for rule
            $rule_ref = {
                -name => 'anonymous private rule'
            };
        }
        else {
            $trouble_level++;
	    my $error_message = "Rules: cannot handle ref type '$ref_type' of rule '$rule_info' for validation";
            $fail_action->$error_message();
            return [$error_message]; # in case of fail action doesn't die
        }
	$rule_info_string = $rule_ref->{-name};
    }

    return [$name, $rule_info_string];

}

# ------------------------------------------------------------------------------
#
# Messages and Validation Mode
#
# ------------------------------------------------------------------------------

sub add_validation_trouble {
    my ($value
        ) = @_;

    $trouble_level += ($value || 1);
}

sub get_validation_trouble_level {
    return $trouble_level;
}

sub validation_trouble {
    my $trouble_accepted = shift || 0;
    return $trouble_level > $trouble_accepted ? $trouble_level: 0;
}

sub validation_messages {
    my $mode = shift || '';

    return $message_store if !$message_store || !$mode || $mode ne '-clear';

    my @messages = @$message_store;
    @$message_store = ();
    return \@messages;
}

sub prepare_validation_mode {
    my $mode = lc(shift);

    my $new_fail_action = $fail_action;
    my $new_off         = $off;

    unless (_p_is_valid(mode => -Enum => [ qw (die warn silent off) ] => $mode)) {
        $trouble_level++;
        croak "prepare_validation_mode(): unknown mode for Scalar::Validation selected: '$mode'";
    }

    # print "#### Select validation mode: $mode\n";
        
    if ($mode eq 'die') {
        $new_fail_action   = $croak_sub;
        $new_off = 0;
    }
    elsif ($mode eq 'warn') {
        $new_fail_action   = sub { carp "Warning: ", @_; return undef; };
        $new_off = 0;
    }
    elsif ($mode eq 'silent') {
        $new_fail_action   = sub { return undef; };
        $new_off = 0;
    }
    elsif ($mode eq 'off') {
        $new_fail_action = sub { return undef; };
        $new_off = 1;
    } else {
        # shouldn't be reached, just to be sure
        $trouble_level++;
        $fail_action->("prepare_validation_mode(): unknown validation mode $mode used");
    }

    return $new_fail_action, $new_off;
}

# ------------------------------------------------------------------------------
#
# Rules
#
# ------------------------------------------------------------------------------

sub get_rules {
    return $rule_store;
}

sub rule_known {
    my $rule = _p_par (rule => Filled => shift, sub { "rule to search not set" });

    return $rule_store->{$rule} ? $rule : '';
}

sub declare_rule {
    my $rule_name    = _p_par (rule => Filled => shift, sub { "rule to declare not set" });
    if (rule_known($rule_name)) { $fail_action->("rule '$rule_name': already defined"); }
        
    my %call_options = convert_to_named_params \@_;
    my %rule_options;

    $rule_options{-where} = _p_npar (-where => CodeRef => \%call_options
        => sub { "rule '$rule_name': where condition"._defined_or_not_message($_, " is not a code reference: $_");});

    $rule_options{-message} = _p_npar (-message => -Optional => CodeRef => \%call_options
        => sub { "rule '$rule_name': message"._defined_or_not_message($_, " is not a code reference: $_");})
           || sub { "Value $_ is not valid for rule '$rule_name'" };

    $rule_options{-as}           = _p_npar (-as          => -Optional => String           => \%call_options);
    $rule_options{-enum}         = _p_npar (-enum        => -Optional => HashRef          => \%call_options);
    $rule_options{-name}         = _p_npar (-name        => -Default  => $rule_name        => String  => \%call_options);
    $rule_options{-description } = _p_npar (-description => -Default  => "Rule $rule_name" => String  => \%call_options);
    $rule_options{-owner}        = _p_npar (-owner       => -Default  => 'CPAN'            => String  => \%call_options);

    parameters_end (\%call_options);
    
    $rule_store->{$rule_name} = \%rule_options; 
    
    return $rule_name;
}

sub delete_rule {
    my $rule_name    = _p_par (rule => Filled => shift, sub { "rule to delete not set" });

        _p_validate (delete_rule => Defined => delete $rule_store->{$rule_name}
                                  => sub {"no rule $rule_name found to delete"});
        return $rule_name;
}

sub replace_rule {
        my $rule_name    = _p_par (rule => Filled => shift, sub { "rule to replace not set" });

        return declare_rule(delete_rule($rule_name), @_);
}

# $_ is set to string '<undef>' in message part, if it was not defined
sub _defined_or_not_message {
        return " is missing" if '<undef>' eq shift;
        return shift;
}

# ------------------------------------------------------------------------------
#
# Dynamic rules
#
# ------------------------------------------------------------------------------

# --- Enum ---------------------------------------------------------------------------

sub Enum {
    my $rule_name  = shift;
    my %enums      = map { $_ => 1 } @_;
    my @enums_list = @_;

    return ($rule_name,
            -where   => sub { defined $_ && defined $enums{$_} },
            -enum    => \%enums,
            -message => sub { "$rule_name: value $_ unknown, allowed values are: [ ".join (", ", @enums_list)." ]" }
        );
}

sub enum {
    my $rule_name  = shift;
    my %enums      = map { lc($_) => 1 } @_;
    my @enums_list = map { lc($_)      } @_;

    return ($rule_name,
            -where   => sub { defined $_ && defined $enums{lc($_)} },
            -enum    => \%enums,
            -message => sub { "$rule_name: value $_ unknown, allowed values (transformed to lower case) are: [ ".join (", ", @enums_list)." ]" }
        );
}

sub Enum_explained {
    _handle_enum_explained(undef, "", @_);
}

sub enum_explained {
    _handle_enum_explained(sub { lc($_[0])}, " (transformed to lower case)", @_);
}

# --- numerical compare ---------------------------------------------------------------------------

sub greater_than {
    my $limit      = shift;
    my $type       = shift;
    return ({ -as    => $type,
              -where   => sub { $_ > $limit },
              -message => sub { "$_ > $limit failed. Value is not of type $type or not greater than limit."},
          },
            @_);
}

sub greater_equal {
    my $limit      = shift;
    my $type       = shift;
    return ({ -as    => $type,
              -where   => sub { $_ >= $limit },
              -message => sub { "$_ >= $limit failed. Value is not of type $type or not greater than limit."},
          },
            @_);
}

sub equal_to {
    my $compare      = shift;
    my $type         = shift;
    if ($type eq 'String') {
        return ({ -as    => $type,
                  -where   => sub { $_ eq $compare },
                  -message => sub { "$_ eq $compare failed. Value is not of type $type or different."},
              },
                @_);
    }
        
    return ({ -as    => $type,
              -where   => sub { $_ == $compare },
              -message => sub { "$_ == $compare failed. Value is not of type $type or different."},
          },
            @_);
}

sub less_than {
    my $limit      = shift;
    my $type       = shift;
    return ({ -as    => $type,
              -where => sub { $_ < $limit },
              -message => sub { "$_ < $limit failed. Value is not of type $type or not less than limit."},
          },
            @_);
}

sub less_equal {
    my $limit      = shift;
    my $type       = shift;
    return ({ -as    => $type,
              -where => sub { $_ <= $limit },
              -message => sub { "$_ <= $limit failed. Value is not of type $type or not less than limit."},
          },
            @_);
}

# --- ISA ---------------------------------------------------------------------------

sub is_a {
    my $type = shift;
    return ({ -name    => "IsClass '$type'",
              -as      => 'Class',
              -where   => sub { return $_->isa($type) },
              -message => sub { "$_ is not of class $type or derived from it."},
          },
            @_);
}

# ------------------------------------------------------------------------------
#
# Validation
#
# ------------------------------------------------------------------------------

# --- helpful for tests ------------------------------------------------

sub _do_is_valid {
    my $valid = 1;

    local $fail_action   = sub { $valid = 0 };
    local $trouble_level = 0; # not to rise trouble level
        
    validate(@_);

    return $valid;
}

# --- return value           if valid   ---------------
# --- return corrected value if invalid   ---------------
sub validate_and_correct {
    my ($validation_options_ref,        # options for validate
        $options_ref
    ) = @_;

    my $correction_action = $options_ref->{-correction}; # action that does corrections in value

    my $validation_options_copied = 0;
    my $value_pos    = 2;
    my $special_rule = $special_rules->{$validation_options_ref->[1]};
    $value_pos = $special_rule->{-value_position} if $special_rule;

    unless (defined $validation_options_ref->[$value_pos]) {
        my $default = $options_ref->{-default};

        if (defined $default && $value_pos >= 0) {
            my @tmp_validation_options = @$validation_options_ref;
            $validation_options_ref    = \@tmp_validation_options;
            $validation_options_ref->[$value_pos] = $default;
            $validation_options_copied = 1;
        }
    }

    if ($correction_action) {
        my $orig_fail_action = $fail_action;
        my $correction_done  = 0;
        my $result = undef;
        {
            local ($fail_action) = sub {
                s/^'//o;
                s/'$//o;
                $correction_done = 1;
                $correction_action->($_);
                
            };
            $result = validate(@$validation_options_ref);
        }
        
        if ($correction_done) {
            # --- update arg vector by new value $result ---
            if ($value_pos >= 0){
                unless ($validation_options_copied) {
                    my @corrected_validation_options = @$validation_options_ref;
                    $validation_options_ref = \@corrected_validation_options;
                }
                $validation_options_ref->[$value_pos] = $result;
            }
        }
        else {
            my $print_result = defined ($result) ? "'$result'" : '<undef>';
            return $result;
        }
    }

    return validate(@$validation_options_ref);
}

# --- don't name key twice, deletes validated values out of hash -------------------------
#   _do_named_parameter
sub _do_named_parameter {
        my $first_arg = shift;
        my $hash_ref;
        
        my $msg_ref;
        my $key;
        my $option_args_ref;

        my $args_ref = \@_;

        $call_info = '';

        unless (_p_is_valid(key  => Scalar  => $first_arg)) {
                $args_ref        = _p_validate (validation_args => ArrayRef => $first_arg);
                $key             = shift @$args_ref;
                $option_args_ref = shift;
        }
        else {
                $key = $first_arg;
        }

        $key = _p_validate (key  => Scalar  => $key);

        $hash_ref = pop @$args_ref;
        
        unless (_p_is_valid(option_ref => HashRef => $hash_ref)) {
	    $msg_ref  = _p_validate (message_ref => CodeRef => $hash_ref);
	    $hash_ref = _p_validate (option_ref  => HashRef => pop @$args_ref);
        }

        my $value = delete $hash_ref->{$key};

        unless (defined $value) {
                if ($option_args_ref) {
                        $value = $option_args_ref->{-default};
                        print "used default $key => '$value'\n";
                        # print $option_args_ref->{-description}."\n";
                }
        }

        return _p_validate ($key, @$args_ref, $value, $msg_ref);
}

# --- return value        if valid   ---------------
# --- call   $fail_action if invalid ---------------

sub _do_validate_parameter {
    $call_info = 'parameter ';
    goto &_do_validate;
}

sub _do_validate_call {
    $call_info = '';
    goto &_do_validate;
}

sub _do_validate {
    if ($off) {
        my $value_pos = 2;
	my $special_rule = $special_rules->{$_[1]};
        $value_pos = $special_rule->{-value_position} if $special_rule;
        return $_[$value_pos] if $value_pos >= 0;
    }

    my    $subject_info = shift || '';
    my    $rule_info    = shift;

    unless ($rule_info) {
        $trouble_level++;
        $fail_action->("rule for validation not set");
        return $_; # in case of fail action doesn't die
    }

    my $rule_ref   = $rule_store->{$rule_info};

    unless ($rule_ref) {
        my $special_rule = $special_rules->{$rule_info}->{-code};

        return $special_rule->($subject_info, @_) if $special_rule;

        my $ref_type = ref ($rule_info);
        
        unless ($ref_type) {
            $trouble_level++;
            $fail_action->("unknown rule '$rule_info' for validation");
            return shift; # in case of fail action doesn't die
        }
        elsif ($ref_type eq 'HASH') { # given rule
            $rule_ref = $rule_info;
            # TODO: _p_validate rule ...
        }
        elsif ($ref_type eq 'CODE') { # where condition for rule
            $rule_ref = {
                -where   => $rule_info,
                -message => sub { "$_ does not match free defined rule" },
            };
        }
        else {
            $trouble_level++;
            $fail_action->("Rules: cannot handle ref type '$ref_type' of rule '$rule_info' for validation");
            return shift; # in case of fail action doesn't die
        }
    }

    local $_            = shift;
    my    $message_ref  = shift;

    my $orig_value       = $_;
    my $test_message_ref = $message_ref || $rule_ref->{-message};

    my $parent_is_valid = defined $rule_ref->{-as}
        ? _check_parent_rules($rule_ref->{-as}, $_)
            : 1;

    unless ($parent_is_valid && $rule_ref->{-where}->()) {
        $_ = defined ($_) ? "'$_'" : '<undef>';
        my $message = $get_caller_info->()."($call_info$subject_info): ".$test_message_ref->();
        push (@$message_store, $message) if $message_store;
        $trouble_level++;
        my $result = $fail_action->($message);
        return $result if defined $result;
    }

    return $orig_value;
}

1;

__END__

=head1 NAME

Scalar::Validation - Makes validation of scalar values or function
(sub) parameters easy and uses pure Perl.

=head1 VERSION

This documentation refers to version 0.700 of Scalar::Validation

=head1 SYNOPSIS

  use Scalar::Validation qw(:all);

  my $int_1    = validate int_1   => Int   => 123;
  my $float_1  = validate float_1 => Float => 3.1415927;

  my $para_1   = par  parameter_1 => -Range => [1,5] => Int => shift;
  my $exponent = npar -exponent   => -Range => [1,5] => Int => \%options;

  my $para_2     = parameter       parameter_1 => -Range => [1,5] => Int => shift;
  my $exponent_2 = named_parameter -exponent   => -Range => [1,5] => Int => \%options;

  my $int_2    = validate (int_2    => -And => [Scalar => 'Int'],  123);
  my $int_3    = validate (int_3    => -Or  => [Int => 'CodeRef'], 123);
  my $code_ref = validate (code_ref => -Or  => [Int => 'CodeRef'], sub { 123; });

  my $enum_abc = validate (parameter => -Enum => {a => 1, b => 1, c => 1}, 'c');
  my $enum_abc = validate (parameter => -Enum => [ qw (a b c) ], 'c');

  my $int_4    = validate (int_4   => -Optional =>  Int   =>                             undef);
  my $int_5    = validate (int_5   => -Optional => -And   => [Scalar => Int => 0] =>     undef);
  my $int_6    = validate (int_6   => -Optional => -Or    => [Int => CodeRef => 0] =>    undef);
  my $enum_2   = validate (enum_2  => -Optional => -Enum  => {a => 1, b => 1, c => 1} => undef);
  my $range_1  = validate (range_1 => -Optional => -Range => [1,5] => Int =>             undef);

  my $float_1  = validate (float_1 => -Default => '1e1'  => Float                           => undef);
  my $float_2  = validate (float_2 => -Default => '-3.1' => -And  => [Scalar => Float => 0] => undef);

  my $rounded  = validate_and_correct ([rounded => Int => 1.1],
                                       {  -correction => sub {
                                             my $float = par (rounded => Float => shift);
                                             return int($float + 0.5) if $float > 0;
                                             return int($float - 0.5);
                                           },
                                       });


B<Just checks, never dies:>

  is_valid (valid_1 => Int => 123);   # is valid,     returns 1;
  is_valid (valid_2 => Int => 1.23);  # is not valid, returns 0;
  is_valid (valid_3 => Int => 'a');   # is not valid, returns 0;
  is_valid (valid_4 => Int => undef); # is not valid, returns 0;

B<Free defined rules or wheres only> (also for validate(...))

  my $value = 2;

  # be careful, doesn't check that $_ is an integer!
  is_valid (free_where_greater_zero => sub { $_ && $_ > 0} => $value);  # is valid, returns 1

  is_valid (free_rule_greater_zero => { -as      => Int =>
                                        -where   => sub { $_ > 0},
                                        -message => sub { "$_ is not > 0" },
                                      }
            => $value); # is valid, returns 1

  my $my_rule = { -as => Int => -where => sub { $_ && $_ > 0} => -message => sub { "$_ is not > 0" }};

  is_valid (free_rule_greater_zero => $my_rule => $value);              # is valid, returns 1

B<Managing Rules>

  declare_rule (
      NegativeInt => -as      => Int =>           # Parent rule is optional
                     -where   => sub { $_ < 0 },
                     -message => sub { "value $_ is not a negative integer" },
  );

  replace_rule (
      NegativeInt => -as      => Int =>           # Parent rule is optional
                     -where   => sub { $_ =< 0 },
                     -message => sub { "value $_ is not a negative integer" },
  );

  delete_rule ('NegativeInt');

  rule_known(Unknown  => 1); # returns 0 (false)
  rule_known(Negative => 1); # returns 1 (true)

B<Dynamic Rules For Comparison>

  par       parameter => greater_than  4 => Int    => shift;     # = 5
  validate  parameter => g_t           4 => Int    => $value;    # = 6
  
  is_valid (parameter => greater_equal 4 => Float  => $value);   # = 4.1
  is_valid (parameter => g_e           4 => Int    => $value);   # = 4
  
  npar     -parameter => less_than  4 => Int       => \%options;
  is_valid (parameter => l_t       (4 => 'Float')  => $value);   # = 4.1
  
  validate (parameter => less_equal (4 => 'Float') => $value);   # = 4.1
  is_valid (parameter => l_e         4 => Int      => $value);   # = 3
  
  my $value = 'Text';
  is_valid (parameter => equal_to (text => String) => lc($value)); # compares as String
  
  is_valid (parameter => equal_to (4 => String) => '4.0'); # not valid, compares as String
  is_valid (parameter => equal_to (4 => Float)  =>  4.0);  # valid,    compares as number
  is_valid (parameter => equal_to (4 => Int)    =>  4.0);  # valid !!, compares as number

B<Dynamic Rules To Check Types>

  my $animal = par is_a  Animal => shift;
  my $person = par is_a (Person => shift);
  my $tree   = par is_a (Tree),    shift;

B<Validation Modes>

  local ($Scalar::Validation::fail_action, $Scalar::Validation::off)
       = prepare_validation_mode('die');  
  local ($Scalar::Validation::fail_action, $Scalar::Validation::off)
       = prepare_validation_mode(warn => 1);

  local $Scalar::Validation::fail_action = sub { my_log('Error', $@); return undef; }

=head1 DESCRIPTION

You should not use this module without reason.

If possible, choose L<Moose>.

If using L<Moo>, there is the pure Perl module L<Type::Params> which
does not need be compiled. Or choose L<Kavorka> with nice syntax, but
you need to compile the modules. Or use experimental type checks of
Perl 5.20 .

If that all is not possible or you want different run modes for
validation, then you should take a look.

This class implements a fast and flexible validation for scalars.  It
is implemented functional to get speed and some problems using global
rules for all ;).

It is safer to use than L<Type::Params>, but slower.

It is written to work well with antique Perl versions like 5.6 and
5.8.

It is also written to be used in antique Code written for such antique
Perl versions. You can add it sub for sub. You can also validate
single values, that are not call parameters. Thats the name is coming from.

You can declare and test your own rules, give every process or sub in
process its own rules, if you want.

=head2 Validate Subs

Following validation functions exist:

  # --- sub parameters
  parameter(...);       # Positional parameter
    par(...);           # Alias for parameter()

  named_parameter(...);
    n_par(...);         # Alias for named_parameter()

  # --- just validate a value, that is not a sub parameter
  validate(...);

  # --- same as validate, but with option to correct invalid value
  validate_and_correct(...);

  is_valid(...);

=head3 validate(), parameter() and par()

Different names for same functionality.

But 

  validate(...);

is ignored while building up meta information.

Use like

  my $var_float = validate ('PI is a float' => Float => $PI);
  my $par_int   = par      (par_int         => Int   => shift);

First argument is a free name of the check done. If used as parameter
check for subs it is the 'name' of the parameter.

Last argument holds the value to be checked. It has to be a scalar,
and therefore the module was named C<Scalar::Validation>.

Optional last argument:
After the value argument can be added a sub to print out an own error message
instead of the default error message:

  my $var_float = validate ('PI is a float' => Float => $PI => sub { 'wrong defined $PI: '.$_ } );

All parameters after first before value argument are used to select or
define "validation rules": 'Float' and 'Int' in this example.

=head3 named_parameter(), n_par()

These subs extract named parameters out of a parameter_hash_ref. Key
and value will be deleted from hash during validation. After
processing all parameters hash_ref should be empty.

  my $par_1_int   = npar            (par_1 => Int   => \%parameters);
  my $par_2_float = named_parameter (par_2 => Float => \%parameters);

First argument ($key) is the key of the parameter.
Last argument ($parameters) has to be a hash_ref.

Without these subs you would have to implement for reading par_1:

  my $key       = 'par_1';
  my $value     = delete $parameters->{$key};
  my $par_1_int = par ($key => Int   => $value);

It could be done in one line, but this line will be complicated and
not easy to understand. The key value is needed twice and that can
cause Copy-Paste-Errors.

=head3 validate_and_correct()

Description is still missing, sorry ...

=head2 Dies by error message

On default, application dies with error message, if data checked by
C<named_parameter(...)> or C<validate(...)> is not valid.

  validate (parameter => -And => [Scalar => 'Int'],  {} );
  validate (parameter => -And => [Scalar => 'Int'],  [] );
  validate (parameter => -And => [Scalar => 'Int'],  sub { 'abc'; });

=head2 Just check without die

C<is_valid(...)> just does validation and returns 1 in case on success
and 0 in case of fail.

  print is_valid(parameter => -And => [Scalar => 'Int'],  123) ." => 123 is int\n";
  print is_valid(parameter => -And => [Scalar => 'Int'],  {} ) ." => {} is no scalar\n";
  print is_valid(parameter => -And => [Scalar => 'Int'],  [] ) ." => [] is no scalar\n";
  print is_valid(parameter => -And => [Scalar => 'Int'],  sub { 'abc'; }) ." => sub { 'abc'; } is no scalar\n";

=head2 Avoid trouble using invalid data

If a validation fails and validation mode is not set as 'die', you
probably will run in trouble afterwards, when you use invalid data.

Therefore do

  my $trouble_level = p_start;

  # add your code

  # fire exit, if validation does not die
  return undef if validation_trouble($trouble_level);

or something similar.

C<is_valid(...)> does not rise C<$trouble_level>, as to be
expected. All other validation subs do!

=head2 Get validation messages

Per default, no messages are stored to increase performance. To store
messages, the message store has to be localized into an array_ref.

This is the only safe way to deal with recursive calls and die! So use
a block like this to store messages

  my @messages;
  {
      local ($Scalar::Validation::message_store) = [];
  
      my $result = is_valid(parameter => -And => [Scalar => 'Int'],  {} );
              
      @messages = @{validation_messages()} unless $result;
  }

=head2 As parameter check for indexed arguments

C<Scalar::Validation> can be also used a parameter check for unnamed
and named sub parameters. C<parameters_start> (Shorthand: C<p_start>)
starts parameter validation and gives back current trouble
level. C<parameters_end \@_;> ensures, that all parameters are
processed. Otherwise it rises the usual validation error. Shorthand:
C<p_end>.

  sub create_some_polynom {
      my $trouble_level = p_start;

      my $max_potenz = par maximum_potenz => -Range => [1,5] => Int => shift;
      # additional parameters ...

      p_end \@_;

      # fire exit, if validation does not die
      return undef if validation_trouble($trouble_level);

      # --- run sub -------------------------------------------------

      my $polynom = '';      map { $polynom .= " + ".int (100*rand())."*x^".($max_potenz-$_); } (0..$max_potenz);

      return $polynom;
  };

  print create_some_polynom(1)."\n";
  print create_some_polynom(2)."\n";
  print create_some_polynom(3)."\n";
  print create_some_polynom(4)."\n";
  print create_some_polynom(5)."\n";

Dies by error message

  print create_some_polynom("four")."\n";
  print create_some_polynom(5.5)."\n";
  print create_some_polynom(6)."\n";
  print create_some_polynom(6, 1)."\n";

=head2 As parameter check for named arguments

Named arguments can also be handled. This needs more runtime than the indexed variant.

C<convert_to_named_params()> does a safe conversion by C<validate()>.

  sub create_some_polynom_named {
      my $trouble_level = p_start;

      my %pars = convert_to_named_params \@_;

      my $max_potenz = npar -maximum_potenz => -Range => [1,5] => Int => \%pars;
      # additional parameters ...

      parameters_end \%pars;

      # fire exit, if validation does not die
      return undef if validation_trouble($trouble_level);

      # --- run sub -------------------------------------------------

      my $polynom = '';
      map { $polynom .= " + ".int (100*rand())."*x^".($max_potenz-$_); } (0..$max_potenz);

      return $polynom;
  };

  print create_some_polynom_named(-maximum_potenz => 4);

=head2 Rules

=head3 declare_rule(...)

You can and should create your own rules, i.e.

  declare_rule (
      Positive =>  -as      => Int =>           # Parent rule is optional
                   -where   => sub { $_ >= 0 },
                   -message => sub { "value $_ is not a positive integer" },
                   -owner   => 'Me'             # Use your own name
                   -description => "This rule checks if $_ >= 0 and is an Integer"
  );

  rule_known(Unknown  => 1); # returns 0 (false)
  rule_known(Positive => 1); # returns 1 (true)

The value to be validated is stored in variable C<$_>. For 

  -message => sub { "my message for wrong value $_."}

it is enclosed in single ticks, so that you get the following output
for C<$_ = "Garfield">:

  my message for wrong value 'Garfield'.

=head3 delete_rule(...)

C<deletes_rule($rule)> deletes rule C<$rule>. It calls current
validation fail method, if C<$rule> not set or rule cannot be found.

  delete_rule ('NegativeInt');

=head3 replace_rule(...)

C<replace_rule($rule => ...)> deletes rule C<$rule> first and then declares it.
Same arguments as for declare_rule;

  replace_rule (
      NegativeInt => -as      => Int =>           # Parent rule is optional
                     -where   => sub { $_ =< 0 },
                     -message => sub { "value $_ is not a negative integer or 0" },
  );

=head3 Documentation Of Rules

To get a html documentation (or text or csv) of all existing rules,
you may use L<Report::Porf>, one of my other modules, like this:

  use Report::Porf qw(:all);
  use Scalar::Validation qw(:all);

  my $rules_ref = get_rules();
  my @rule_info = map { $rules_ref->{$_} } sort keys %$rules_ref;

  auto_report(\@rule_info, "rule_info.html");

All rules - also yours - are listed in the html file.

=head3 Main Rules

There are some main rules, that should not be changed by you, because
they are used internally. If defined wrong, C<Scalar::Validation> may
stop working or doing strange things...

    Defined
    Filled
    Empty
    Optional
    String
    Int
    Even
    Scalar
    Ref
    ArrayRef
    HashRef
    CodeRef
    Class

=head3 Special Rules

There are some special rules, that cannot be
changed. Those rules start with an '-' char in front:

 -Optional    # value may be undefined. If not, use following rule
 -Default     # if value not defined or eq '', use given default value instead
 -And         # all rules must be ok
 -Or          # at least one rule must be ok
 -Enum        # for easy defining enumeration on the fly, by array_ref or hash_ref
 -Range       # Intervall: [start, end] => type
 -RefEmpty    # array_ref: scalar (@$array_ref)     == 0
              # hash_ref:  scalar (keys %$hash_ref) == 0

Reason is, that they combine other rules or have more or different
parameters than a "normal" rule or using own implementation just to
speed up.

All normal rules should not start with a '-', but it is not forbidden to do so.

  my $var_float = validate ('PI is a float' => -Optional => Float => $PI => sub { 'wrong defined $PI: '.$_ } );

This rule does not die, if $PI is undef because of -Optional in front.

=head2 Create Own Validation Module

You should not use Scalar::Validation direct in your code.

Better is creating an own module My::Validation, that adds the rules
you need and only exports the subs the developers in your project
should use:

  use My::Validation;

  my $v = validate v => my_type => new MyType();

You can also define your own fail_action by:

  local $Scalar::Validation::fail_action = sub { my_log('Error', $@); return undef; }

to write validation messages into your own log system by using
C<my_log(...);>. See L<Validation Modes> for details.

=head3 Dealing with XSD

In this case My::Validation should create rules out of XML datatypes
after reading in a XSD file. So rules are dynamic and your application
can handle different XSD definitions without knowing something about
XSD outside of this module.

Also you can filter XSD type contents, i.e. for enmuerations:
Allowing not all possible values in UI or remove entries only for
compatibility with old versions.

And your Application or GUI doesn't need to know about it.

=head2 Validation Modes

Validation modes are selected by

  local ($Scalar::Validation::fail_action, $Scalar::Validation::off) = prepare_validation_mode($mode);

There are 4 predefined validation modes:

  die
  warn
  silent
  off

=head3 is_valid()

C<is_valid()> uses a special validation mode independent from the
followings. It will do the checks in all cases except mode C<'off'>.

=head3 Validation Mode 'die' (default)

The validation methods call C<croak "validation message";> in case of
failures or a rule fails. Your script (or this part of your script) will die.

=head3 Validation Mode 'warn'

The validation methods call C<carp "validation message";> in case of
failures or a rule fails. Your get warnings for every failed rule.

Your script (or this part of your script) will NOT die.

It will continue work. In critical cases you should take
care, that process will be stopped: Use C<validation_trouble()>!

=head3 Validation Mode 'silent'

The validation methods just store messages, if there is a message
store available. No messages will be printed out.

Your script (or this part of your script) will NOT die.

It will continue work. In critical cases you should take
care, that process will be stopped: Use C<validation_trouble()>!

=head3 Validation Mode 'off'

The validation methods just give back the value. They even don't
process the call parameters of the validation routines.

C<is_valid()> is also turned off and returns 1 for all calls.

Be careful! Now you are playing with dynamite! But you are fast.
If you explode, just try switch validation on, if you are still alive.

=head3 Faster than Validation Mode 'off'

=head4 Remove validation calls

Remove all validation calls from your code and fall back to era before
C<Scalar::Validation>.

Be careful! Now you are playing with nitroglycerin! But you cannot be
faster.

=head4 Duplicate parameter management

Having two parameter managements, switch between them by testing
C<$Scalar::Validation::off>: 

  sub create_some_polynom {
      my ($max_potenz,
      ) = @_;

      if ($Scalar::Validation::off) {
          my $trouble_level = p_start;

          $max_potenz = par maximum_potenz => -Range => [1,5] => Int => shift;
          # additional parameters ...
          
          p_end \@_;
          
          # fire exit, if validation does not die
          return undef if validation_trouble($trouble_level);
      }

      # --- run sub -------------------------------------------------

      my $polynom = '';
      map { $polynom .= " + ".int (100*rand())."*x^".($max_potenz-$_); } (0..$max_potenz);

      return $polynom;
  };

Now you have only one extra if statement compared to version without
checks. But you have duplicate parameter management. So only choose
this variant if performance is a real problem for your sub.

Be careful! You are still playing with dynamite! But you are fast.
If you explode, just try switch validation on, if you are still alive.

=head2 Traps

  my $unvalidated  = par => value => Int => shift;   # value is just used without checking
  my $string_shift = par    value => Int => shift => sub { "$_ is still 'shift'!!. Why?"};

=head3 par => value

  my $unvalidated  = par => value => Int => shift;   # value is just used without checking

C<par, npar, validate, ...> are functions, not keywords. The mistake
here is to use " => " instead of ",". Why? The special comma operator
quotes the left argument of

  par => value

so you get

  'par', value

and now par is a string and not a function. You get the last value of
the list, and that is shift! NO VALIDATION! So don't forget to write
tests with invalid data to detect this trap.

By using brackets

  my $unvalidated  = par (value => Int => shift);

you avoid this trap.

=head3 shift => sub { ... }

Another trap

  my $string_shift = par    value => Int => shift => sub { "$_ is still 'shift!!'. Why?"};

The mistake here is also to use " => " instead of ","

  shift => sub { }

It will be interpreted as

  'shift', sub { }

and so you get constant string C<'shift'> instead of the next value
from parameter stack.

Or if both traps are combined, you get the last argument, that may be
a coderef.

You cannot avoid this trap by safe coding, but it will be easy
detected by unit testing.

=head2 More Examples

Have a look into the examples directory or Scalar-Validation.t to see
what else is possible.

=head2 Extraction Of Meta Information

It is possible to extract meta information out of subs or classes, if 
subs are build by following structure:

  package MyClass;

  sub my_sub {
      my $trouble_level = p_start;

      my $first_par = par first_par => Int => shift;
      # additional parameters ...

      my %pars = convert_to_named_params \@_;

      my $max_potenz = npar -first_named => PositiveFloat => \%pars;
      # additional named parameters ...

      p_end \%pars;

      # needed to exit sub in meta extraction mode
      return undef if validation_trouble($trouble_level);

      # ------------------

      # Code of sub doing something
  }

  sub my_next_sub { ...

Extracting meta information will be done as followed:

  use Scalar::Validation qw(:all);
  use MyValidation; # if existing!

  meta_info_clear();

  # ------------------------------------------------------------------------------

  my $my_class = build_meta_info_for_module('MyClass');

  # or, if constructor needs arguments
  $my_class = build_meta_info_for_module('MyClass',
              sub { return MyClass->new(-name => 'AnyPerson') });

  # call without paramters, they are not needed for meta information mode
  $my_class->my_sub();
  $my_class->my_next_sub();

  # ------------------------------------------------------------------------------

  # next classes

  # ------------------------------------------------------------------------------
  end_meta_info_gen();

  print "\n# === Meta Class Information Dump ============================\n"
    .Dumper(get_meta_info());

This will print out

  $VAR = {'MyClass' => {
              'subs' => 
              {
                  'my_next_sub' => {
                      'params'  => [
                          # this sub has no parameters
                      ],
                  },
                  'my_sub' => {
                      'params'  => [
                          {
                              'kind' => 'Positional',
                              'name' => 'first_par',
                              'rule' => 'Int',
                          },
                          {
                              'kind' => 'Named',
                              'name' => '-first_named',
                              'rule' => 'PositiveFloat',
                          },
                      ],
                  },
	      },
         };

as hash_ref of classes/packages containing methods/subs containing
an array of parameters for each sub. The additional keys 'subs' and
'params' let this meta model be easy extended later on.

Or use C<list_meta_info()> to get an ordered list containing one hash
per parameter like:

  [ { 'module' => 'MyClass',
      'sub'    => 'my_sub',
      'kind'   => 'Positional',
      'name'   => 'first_par',
      'rule'   => 'Int',
    },
  ...
  ]

=head2 Coming Soon

=head3 if_par()

C<if_par> sets value only, if matching to rule. Otherwise returns undef.

  my $file_option = if_par_named  (-file => Defined => \%options);

or

  my $file_option = if_par_indexed (file => Defined => shift);
  
  my $file_name   = if_par (file => FileName   => $file_option);
  my $file_handle = if_par (file => FileHandle => $file_option);

  if_par_end $file_option; # raises $trouble_level if $file_option is not Empty

Both C<$file_name> and C<$file_handle>, one or none can be set, that
depends on the rules.

C<$file_option> is a hash containing keys C<-value, -matched (counter),
-rules (string of all tried)>.

C<if_par_end> checks that at least one rule fits.

=head1 SEE ALSO Moose, Moo, Type::Params and Kavorka

Use L<Moose> if possible. If not possible, have a look to L<Moo> and
L<Type::Params>. Or choose L<Kavorka> with nice syntax, but you need
to compile the modules. Or use experimental type checks of Perl 5.20 .

=head2 Differences to Type::Params

L<Type::Params> uses the C<state> pragma, which comes in Perl Version
12. This is much faster than C<Scalar::Validation>, but cannot be run
with earlier versions than Perl V12.

C<Scalar::Validation> doesn't use C<state> and runs even with Perl
V5.6, I tested it on sun.

Also there is no validation mode in L<Type::Params>, it dies in case
of validaiton failure.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
