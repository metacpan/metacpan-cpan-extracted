package MooseX::Extended::Core;

# ABSTRACT: Internal module for MooseX::Extended

use v5.20.0;
use warnings;
use parent 'Exporter';
use Moose::Util qw(
  add_method_modifier
  throw_exception
);
use MooseX::Extended::Types qw(
  ArrayRef
  Bool
  Dict
  Enum
  NonEmptyStr
  Optional
  Str
  Undef
  compile_named
);
use Module::Load 'load';
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Storable 'dclone';
use Ref::Util qw(
  is_plain_arrayref
  is_coderef
);
use Carp 'croak';
#

our $VERSION = '0.35';

our @EXPORT_OK = qw(
  _assert_import_list_is_valid
  _debug
  _disabled_warnings
  _enabled_features
  _our_import
  _our_init_meta
  field
  param
);

# Core's use feature 'try' only supports 'finally' since 5.35.8
use constant HAVE_FEATURE_TRY => $] >= 5.035008;

sub _enabled_features  {qw/signatures postderef postderef_qq :5.20/}             # internal use only
sub _disabled_warnings {qw/experimental::signatures experimental::postderef/}    # internal use only

warnings::register_categories(
    'MooseX::Extended::naked_fields',
);

# Should this be in the metaclass? It feels like it should, but
# the MOP really doesn't support these edge cases.
my %CONFIG_FOR;

sub _config_for ($package) {
    return $CONFIG_FOR{$package};
}

sub _our_import {

    # don't use signatures for this import because we need @_ later. @_ is
    # intended to be removed for subs with signature
    my ( $class, $import, $target_class ) = @_;

    # Moose::Exporter uses Sub::Exporter to handle exporting, so it accepts an
    # { into =>> $target_class } to say where we're exporting this to. This is
    # used by our ::Custom modules to let people define their own versions
    @_ = ( $class, { into => $target_class } );    # anything else and $import blows up
    goto $import;
}

# asserts the import list is valid, rewrites the excludes and includes from
# arrays to hashes (if ( $args{excludes}{$feature} ) ...) and returns the
# target package that this code will be applied to. Yeah, it does too much.
sub _assert_import_list_is_valid {
    my ( $class, $args ) = @_;

    foreach my $features (qw/types excludes/) {
        if ( exists $args->{$features} && !ref $args->{$features} ) {
            $args->{$features} = [ $args->{$features} ];
        }
    }
    if ( my $includes = $args->{includes} ) {
        if ( !ref $includes ) {
            $args->{includes} = { $includes => undef };
        }
        elsif ( is_plain_arrayref($includes) ) {
            $args->{includes} = { map { $_ => undef } $includes->@* };
        }
        else {
            # let anything else just fail in type checking
        }
    }

    $args->{call_level} //= 0;
    my ( $package, $filename, $line ) = caller( $args->{call_level} + 1 );
    my $target_class = $args->{for_class} // $package;

    state $check = {
        class => compile_named( _default_import_list(), _class_excludes() ),
        role  => compile_named( _default_import_list(), _role_excludes() )
    };
    eval {
        $check->{ $args->{_import_type} }->( $args->%* );
        1;
    } or do {

        # Not sure what's happening, but if we don't use the eval to trap the
        # error, it gets swallowed and we simply get:
        #
        # BEGIN failed--compilation aborted at ...
        #
        # Also, don't use $target_class here because if it's different from
        # $package, the filename and line number won't match
        my $error = $@;
        Carp::carp(<<"END");
Error:    Invalid import list to $class.
Package:  $package
Filename: $filename
Line:     $line
Details:  $error
END
        throw_exception(
            'InvalidImportList',
            class_name           => $package,
            moosex_extended_type => __PACKAGE__,
            line_number          => $line,
            messsage             => $error,
        );
    };

    # remap the array to a hash for easy lookup
    foreach my $features (qw/excludes/) {
        $args->{$features} = { map { $_ => 1 } $args->{$features}->@* };
    }

    $CONFIG_FOR{$target_class} = $args;
    return $target_class;
}

sub _our_init_meta ( $class, $apply_default_features, %params ) {
    my $for_class = $params{for_class};
    my $config    = $CONFIG_FOR{$for_class};

    if ( $config->{debug} ) {
        $MooseX::Extended::Debug = $config->{debug};
    }

    if ( _should_debug() ) {
        foreach my $feature (qw/includes excludes/) {
            if ( exists $config->{$feature} ) {
                foreach my $category ( sort keys $config->{$feature}->%* ) {
                    _debug("$for_class $feature '$category'");
                }
            }
        }
    }

    $apply_default_features->( $config, $for_class, \%params );
    _apply_optional_features( $config, $for_class );
}

sub _class_setup_import_methods () {
    return (
        with_meta => [ 'field', 'param' ],
        install   => [qw/unimport/],
        also      => ['Moose'],
    );
}

sub _role_setup_import_methods () {
    return (
        with_meta => [ 'field', 'param' ],
    );
}

sub _role_excludes () {
    return (
        excludes => Optional [
            ArrayRef [
                Enum [
                    qw/
                      WarnOnConflict
                      autoclean
                      carp
                      true
                      field
                      param
                      /
                ]
            ]
        ]
    );
}

sub _class_excludes () {
    return (
        excludes => Optional [
            ArrayRef [
                Enum [
                    qw/
                      StrictConstructor
                      autoclean
                      c3
                      carp
                      immutable
                      true
                      field
                      param
                      /
                ]
            ]
        ]
    );
}

sub _default_import_list () {
    return (
        call_level   => Optional [ Enum [ 1, 0 ] ],
        debug        => Optional [Bool],
        for_class    => Optional [NonEmptyStr],
        types        => Optional [ ArrayRef [NonEmptyStr] ],
        _import_type => Enum [qw/class role/],
        _caller_eval => Bool,                                  # https://github.com/Ovid/moosex-extended/pull/34
        includes     => Optional [ Dict [ map { $_ => Optional [ Undef | ArrayRef ] } qw/ multi async try method / ] ],
    );
}

sub _with_imports ( $requested, $defaults ) {
    if ($requested) {
        return $requested->@*;
    }
    elsif ($defaults) {
        return $defaults->@*;
    }
    return;
}

sub _apply_optional_features ( $config, $for_class ) {
    my $includes = $config->{includes} or return;

    state $requirements_for = {
        multi => {
            version => v5.26.0,
            import  => undef,
            module  => 'Syntax::Keyword::MultiSub',
        },
        async => {
            version => v5.26.0,
            import  => undef,
            module  => 'Future::AsyncAwait',
        },
        method => {
            version => v5.0.0,
            import  => ['method'],
            module  => 'Function::Parameters',
        },
        try => {
            version => v5.24.0,
            import  => undef,
            module  => 'Syntax::Keyword::Try',
            skip    => sub ($for_class) {
                if (HAVE_FEATURE_TRY) {
                    feature->import::into( $for_class, 'try' );
                    warnings->unimport('experimental::try');
                    return 1;
                }
                return;
            },
        }
    };
    FEATURE: foreach my $feature ( keys $includes->%* ) {
        my $required = $requirements_for->{$feature} or croak("PANIC: we have requested a non-existent feature: $feature");
        if ( $^V && $^V lt $required->{version} ) {
            croak("Feature '$feature' not supported in Perl version less than $required->{version}. You have $^V");
        }

        # don't trap the error. Let it bubble up.
        if ( my $skip = $required->{skip} ) {
            next FEATURE if $skip->($for_class);
        }
        load $required->{module};
        $required->{module}->import::into( $for_class, _with_imports( $includes->{$feature}, $required->{import} ) );
    }
}

sub param ( $meta, $name, %opt_for ) {
    $opt_for{is}          //= 'ro';
    $opt_for{required}    //= 1;
    $opt_for{_call_level} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        $options{init_arg} //= $attr;

        # in case they're inheriting an attribute
        $options{init_arg} =~ s/\A\+//;
        _add_attribute( 'param', $meta, $attr, %options );
    }
}

sub field ( $meta, $name, %opt_for ) {
    $opt_for{is}          //= 'ro';
    $opt_for{_call_level} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        if ( defined( my $init_arg = $options{init_arg} ) ) {
            $init_arg =~ /\A_/ or throw_exception(
                'InvalidAttributeDefinition',
                attribute_name => $name,
                class_name     => $meta->name,
                messsage       => "A defined 'field.init_arg' must begin with an underscore: '$init_arg'",
            );
        }

        $options{init_arg} //= undef;
        if ( $options{builder} || $options{default} ) {
            $options{lazy} //= 1;
        }

        _add_attribute( 'field', $meta, $attr, %options );
    }
}

sub _add_attribute ( $attr_type, $meta, $name, %opt_for ) {
    _debug("Finalizing options for '$attr_type $name'");

    # we use the $name to generate the other methods names. However,
    # $orig_name is used to set the actual field name. This is because
    # Moose allows `has '+x' => ( writer => 'set_x' );` to inherit an
    # attribute from a parent class and only change the desired attribute
    # options.
    my $orig_name = $name;
    $name =~ s/\A\+//;
    unless ( _is_valid_method_name($name) ) {
        throw_exception(
            'InvalidAttributeDefinition',
            attribute_name => $orig_name,
            class_name     => $meta->name,
            messsage       => "Illegal attribute name, '$name'",
        );
    }

    state $shortcut_for = {
        predicate => sub ($value) {"has_$value"},
        clearer   => sub ($value) {"clear_$value"},
        builder   => sub ($value) {"_build_$value"},
        writer    => sub ($value) {"set_$value"},
        reader    => sub ($value) {"get_$value"},
    };

    if ( is_coderef( $opt_for{builder} ) ) {
        my $builder_code = $opt_for{builder};
        my $builder_name = $shortcut_for->{builder}->($name);
        if ( _is_valid_method_name($builder_name) ) {
            $meta->add_method( $builder_name => $builder_code );
            $opt_for{builder} = $builder_name;
        }
    }

    OPTION: foreach my $option ( keys $shortcut_for->%* ) {
        next unless exists $opt_for{$option};
        no warnings 'numeric';    ## no critic (TestingAndDebugging::ProhibitNoWarning)
        if ( 1 == length( $opt_for{$option} ) && 1 == $opt_for{$option} ) {
            my $option_name = $shortcut_for->{$option}->($name);
            $opt_for{$option} = $option_name;
        }
        unless ( _is_valid_method_name( $opt_for{$option} ) ) {
            throw_exception(
                'InvalidAttributeDefinition',
                attribute_name => $orig_name,
                class_name     => $meta->name,
                messsage       => "Attribute '$orig_name' has an invalid option name, $option => '$opt_for{$option}'",
            );
        }
    }

    if ( 'rwp' eq $opt_for{is} ) {
        $opt_for{writer} = "_set_$name";
    }

    if ( exists $opt_for{writer} && defined $opt_for{writer} ) {
        $opt_for{is} = 'rw';
    }

    %opt_for = _maybe_add_cloning_method( $meta, $name, %opt_for );

    if (    not exists $opt_for{accessor}
        and not exists $opt_for{writer}
        and not exists $opt_for{default}
        and not exists $opt_for{builder}
        and not defined $opt_for{init_arg}
        and $opt_for{is} eq 'ro' )
    {

        my $call_level = 1 + $opt_for{_call_level};
        my ( undef, $filename, $line ) = caller($call_level);
        Carp::carp("$attr_type '$name' is read-only and has no init_arg or default, defined at $filename line $line\n")
          if $] ge '5.028'
          and warnings::enabled_at_level( 'MooseX::Extended::naked_fields', $call_level );
    }

    delete $opt_for{_call_level};
    _debug( "Setting $attr_type, '$orig_name'", \%opt_for );
    $meta->add_attribute( $orig_name, %opt_for );
}

sub _is_valid_method_name ($name) {
    return if ref $name;
    return $name =~ qr/\A[a-z_]\w*\z/ai;
}

sub _maybe_add_cloning_method ( $meta, $name, %opt_for ) {
    return %opt_for unless my $clone = delete $opt_for{clone};

    no warnings 'numeric';    ## no critic (TestingAndDebugging::ProhibitNoWarning)

    my ( $use_dclone, $use_coderef, $use_method );
    if ( 1 == length($clone) && 1 == $clone ) {
        $use_dclone = 1;
    }
    elsif ( _is_valid_method_name($clone) ) {
        $use_method = 1;
    }
    elsif ( is_coderef($clone) ) {
        $use_coderef = 1;
    }
    else {
        throw_exception(
            'InvalidAttributeDefinition',
            attribute_name => $name,
            class_name     => $meta->name,
            messsage       => "Attribute '$name' has an invalid option value, clone => '$clone'",
        );
    }

    # here be dragons ...
    _debug("Adding cloning for $name");
    my $reader = delete( $opt_for{reader} ) // $name;
    my $writer = delete( $opt_for{writer} ) // $reader;
    my $is     = $opt_for{is};
    $opt_for{is} = 'bare';

    my $reader_method = sub ($self) {
        _debug("Calling reader method for $name");
        my $attr  = $meta->get_attribute($name);
        my $value = $attr->get_value($self);
        return $value unless ref $value;
        return
            $use_dclone                 ? dclone($value)
          : $use_method || $use_coderef ? $self->$clone( $name, $value )
          :                               croak("PANIC: this should never happen. Do not know how to clone '$name'");
    };

    my $writer_method = sub ( $self, $new_value ) {
        _debug("Calling writer method for $name");
        my $attr = $meta->get_attribute($name);
        $new_value
          = !ref $new_value             ? $new_value
          : $use_dclone                 ? dclone($new_value)
          : $use_method || $use_coderef ? $self->$clone( $name, $new_value )
          :                               croak("PANIC: this should never happen. Do not know how to clone '$name'");
        $new_value = ref $new_value ? dclone($new_value) : $new_value;
        $attr->set_value( $self, $new_value );
        return $new_value;
    };

    # this fixes a bug where we could set the value in the constructor
    # but it would remain a reference to the original data, so we could do
    # this:
    #
    #     my $date = DateTime->now;
    #     my $object = Some::Classs->new( created => $date );
    #
    # Any subsequent code calling $object->created was getting a reference to
    # $date, so any changes to $date would be propagated to all instances
    $meta->add_before_method_modifier(
        BUILD => sub ( $self, @ ) {
            my $attr = $meta->get_attribute($name);

            # before BUILD is even called, let's make sure we fetch a cloned
            # value and set it.
            $attr->set_value( $self, $self->$reader_method );
        }
    );

    if ( $is eq 'ro' ) {
        _debug("Adding read-only reader for $name");
        $meta->add_method( $reader => $reader_method );
    }
    elsif ( $reader ne $writer ) {
        _debug("Adding separate readers and writers for $name");
        $meta->add_method( $reader => $reader_method );
        $meta->add_method( $writer => $writer_method );
    }
    else {
        _debug("Adding overloaded reader/writer for $name");
        $meta->add_method(
            $reader => sub ( $self, @value ) {
                _debug( "Args for overloaded reader/writer for $name", [ $self, @value ] );
                return @value == 0
                  ? $self->$reader_method
                  : $self->$writer_method(@value);
            }
        );
    }
    return %opt_for;
}

sub _should_debug () {
    return $MooseX::Extended::Debug // $ENV{MOOSEX_EXTENDED_DEBUG};    # suppress "once" warnings
}

sub _debug ( $message, @data ) {
    return unless _should_debug();
    if (@data) {                                                       # yup, still want multidispatch
        require Data::Printer;
        my $data = Data::Printer::np(@data);
        $message = "$message: $data";
    }
    say STDERR $message;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Extended::Core - Internal module for MooseX::Extended

=head1 VERSION

version 0.35

=head1 DESCRIPTION

This is not for public consumption. Provides the C<field> and C<param>
functions to L<MooseX::Extended> and L<MooseX::Extended::Role>.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
