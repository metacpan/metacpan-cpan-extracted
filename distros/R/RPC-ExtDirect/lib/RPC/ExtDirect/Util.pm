package RPC::ExtDirect::Util;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use Carp;
use JSON;

use base 'Exporter';

our @EXPORT_OK = qw/
    clean_error_message
    get_caller_info
    parse_global_flags
/;

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Clean croak() and die() messages of file/line information
#

sub clean_error_message {
    my ($msg) = @_;

    $msg =~ s/
        (?<![,]) \s
        at
        .*?
        line \s \d+(, \s <DATA> \s line \s \d+)? \.? \n*
        (?:\s*eval \s \{...\} \s called \s at \s .*? line \s \d+ \n*)?
        //msx;

    return $msg;
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return formatted call stack part to use in exceptions
#

sub get_caller_info {
    my ($depth) = @_;
    
    my ($package, $sub) = (caller $depth)[3] =~ / \A (.*) :: (.*?) \z /xms;
    
    return $package . '->' . $sub;
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Fetch the values of the (deprecated) global flags into an object,
# giving a warning when they're used
#

sub parse_global_flags {
    my ($flags, $obj) = @_;
    
    my $caller_pkg = caller;
    
    for my $flag ( @$flags ) {
        my $package = $flag->{package};
        my $var     = $flag->{var};
        my $type    = $flag->{type};
        my $fields  = $flag->{setter};
        my $default = $flag->{default};
        
        my $have_default = exists $flag->{default};
        my $full_var     = $package . '::' . $var;
        
        my ($value, $have_value);
        
        {
            no strict   'refs';
            no warnings 'once';
            
            if ( $type eq 'scalar' ) {
                $have_value = defined ${ $full_var };
                $value      = $have_value ? ${ $full_var } : $default;
            }
            elsif ( $type eq 'hash' ) {
                $have_value = %{ $full_var };
                $value      = $have_value            ? { %{ $full_var } }
                            : 'HASH' eq ref $default ? { %$default      }
                            :                          undef
                            ;
            }
            elsif ( $type eq 'array' ) {
                $have_value = @{ $full_var };
                $value      = $have_value             ? [ @{ $full_var } ]
                            : 'ARRAY' eq ref $default ? [ @$default      ]
                            :                           undef
                            ;
            }
            else {
                die "Unknown global variable type: '$type'"; # Debug mostly
            }
        }
        
        if ( $have_value ) {
            my $warning = <<"END";

The package global variable $full_var is deprecated
and is going to be removed in the next RPC::ExtDirect version.
END
            
            if ( 'ARRAY' eq ref $fields ) {
                
                my $tpl = <<"END";
Use $caller_pkg instance with the following config options instead:
%s

    my \$config = $caller_pkg->new(
%s
    );

END
                my $w1 = join ', ', map { "`$_`" } @$fields;
                my $w2 = join "\n", map { "\t\t$_ => ..." } @$fields;
                
                $warning .= sprintf $tpl, $w1, $w2;
            }
            else {
                $warning .= <<"END";
Use the `$fields` config option with the $caller_pkg
instance instead:

    my \$config = $caller_pkg->new(
            $fields => ...
    );
    
END
            }
            
            warn $warning;
        }

        croak "Can't resolve the field name for var $full_var"
            unless $fields;
        
        $fields = [ $fields ] unless 'ARRAY' eq ref $fields;
        
        for my $field ( @$fields ) {
            my $predicate = "has_$field";
        
            $obj->$field($value)
                if $have_value || ($have_default && !$obj->$predicate());
        }
    }
}

### NON-EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Parse ExtDirect attribute, perform sanity checks and return
# the attribute hashref
#

sub parse_attribute {
    my ($package, $symbol, $referent, $attr, $data, $phase, $file, $line)
        = @_;

    croak "Method attribute is not ExtDirect at $file line $line"
        unless $attr eq 'ExtDirect';

    # Attribute::Handlers automagically parses the data into arrayref
    # *if* it is parseable Perl (which it should be). If not, the data
    # is going to be a garbled string which is kaput for us. However,
    # an *empty* string means the bare attribute was used with no
    # parameters, which is strange but is not an error.
    croak "Malformed ExtDirect attribute '$data' at $file line $line"
        if $data ne '' && 'ARRAY' ne ref $data;

    my $symbol_name = eval { no strict 'refs'; *{$symbol}{NAME} };
    croak "Can't resolve symbol '$symbol' for package '$package' ".
          "at $file line $line: $@"
        if $@;
    
    # Attribute may be empty, means no argument checking
    $data ||= [];

    # Calling convention attributes are mutually exclusive
    my @calling_convention;

    my %attr;
    
    # Compatibility form (n, ...), where n stands for (len => n)
    if ( $data->[0] =~ / \A \d+ \z /xms ) {
        $attr{len} = shift @$data;
        push @calling_convention, 'len';
    }

    while ( @$data ) {
        my $param_def = shift @$data;
        
        # len means ordered (by position) arguments
        if ( $param_def =~ / \A len \z /xms ) {
            $attr{len} = shift @$data;

            croak "ExtDirect attribute 'len' should be followed ".
                  "by a number of ordered arguments at file $file ".
                  "line $line"
                unless $attr{len} =~ / \A \d+ \z /xms;
            
            push @calling_convention, 'len';
        }

        # formHandler means exactly that, a handler for form requests
        elsif ( $param_def =~ / \A formHandler \z /xms ) {
            $attr{formHandler} = 1;
            push @calling_convention, 'formHandler';
        }

        # pollHandlers are used with EventProvider
        elsif ( $param_def =~ / \A pollHandler \z /xms ) {
            $attr{pollHandler} = 1;
            push @calling_convention, 'pollHandler';
        }
        
        # named arguments for the method
        elsif ( $param_def =~ / \A params \z /ixms ) {
            my $arg_names = shift @$data;

            croak "ExtDirect attribute 'params' must be followed by ".
                  "arrayref at $file line $line"
                if ref $arg_names ne 'ARRAY';

            # Copy the names
            $attr{params} = [ @{ $arg_names } ];

            push @calling_convention, 'params';
        }

        # Hooks
        elsif ( $param_def =~ / \A (before|instead|after) \z /ixms ) {
            my $type = $1;
            my $code = shift @$data;

            croak "ExtDirect attribute '$type' must be followed by coderef, ".
                  "undef, or 'NONE' at $file line $line"
                if defined $code && $code ne 'NONE' && 'CODE' ne ref $code;
            
            $attr{ $type } = $code;
        }

        # Strict is a boolean attribute, but let's be flexible about it
        elsif ( $param_def =~ / \A strict \z /ixms ) {
            $attr{strict} = !!(shift @$data);
        }
        
        # Assume a generic foo => 'bar' attribute and fall through
        else {
            $attr{ $param_def } = shift @$data;
        }

        # There should be at most one calling convention attribute defined,
        # but we don't care how many exactly if more than one
        croak sprintf "ExtDirect attributes '%s' and '%s' are ".
                      "mutually exclusive at file $file line $line",
                      @calling_convention
            if @calling_convention > 1;
    };

    # strict should only be defined for named methods
    croak "ExtDirect attribute 'strict' should be used with 'params' ".
          "for named Methods at file $file line $line"
        if exists $attr{strict} && !defined $attr{params};
    
    return {
        package => $package,
        method  => $symbol_name,
        %attr,
    };
}

### NON-EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Decode metadata sent by the client. This function changes
# the passed hashref in situ (so has side effects).
#

sub decode_metadata {
    # This is a bit hacky but will do
    my ($self, $keywords) = @_;

    my $meta_encoded = $keywords->{metadata};

    if ( defined $meta_encoded ) {
        # Whoever sends *multiple* metadata fields is going to regret it.
        my $meta_json = 'ARRAY' eq ref $meta_encoded ? pop @$meta_encoded
                      :                                $meta_encoded
                      ;

        local $@;
        $keywords->{metadata} = eval { JSON::from_json($meta_json) };

        if ( $@ ) {
            my $error = clean_error_message($@);
            $self->set_error("Invalid metadata: $error");
        }
    }
}

1;

