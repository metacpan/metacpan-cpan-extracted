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
  compile_named
  ArrayRef
  Bool
  Enum
  NonEmptyStr
  Optional
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

our $VERSION = '0.21';

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

sub _enabled_features  {qw/signatures postderef postderef_qq :5.20/}             # internal use only
sub _disabled_warnings {qw/experimental::signatures experimental::postderef/}    # internal use only

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

    # remap the arrays to hashes for easy lookup
    foreach my $features (qw/includes excludes/) {
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

    foreach my $feature (qw/includes excludes/) {
        if ( exists $config->{$feature} ) {
            foreach my $category ( sort keys $config->{$feature}->%* ) {
                _debug("$for_class $feature '$category'");
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
        includes     => Optional [
            ArrayRef [
                Enum [
                    qw/
                      multi
                      async
                      /
                ]
            ]
        ]
    );
}

sub _apply_optional_features ( $config, $for_class ) {
    if ( $config->{includes}{multi} ) {
        if ( $^V && $^V lt v5.26.0 ) {
            croak("multi subs not supported in Perl version less than v5.26.0. You have $^V");
        }

        # don't trap the error. Let it bubble up.
        load Syntax::Keyword::MultiSub;
        Syntax::Keyword::MultiSub->import::into($for_class);
    }
    if ( $config->{includes}{async} ) {
        if ( $^V && $^V lt v5.26.0 ) {
            croak("async subs not supported in Perl version less than v5.26.0. You have $^V");
        }

        # don't trap the error. Let it bubble up.
        load Future::AsyncAwait;
        Future::AsyncAwait->import::into($for_class);
    }
}

sub param ( $meta, $name, %opt_for ) {
    $opt_for{is}       //= 'ro';
    $opt_for{required} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        unless ( $options{init_arg} ) {
            $attr =~ s/^\+//;      # in case they're overriding a parent class attribute
            $options{init_arg} //= $attr;
        }
        _add_attribute( 'param', $meta, $attr, %options );
    }
}

sub field ( $meta, $name, %opt_for ) {
    $opt_for{is} //= 'ro';

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        if ( defined( my $init_arg = $options{init_arg} ) ) {
            throw_exception(
                'InvalidAttributeDefinition',
                attribute_name => $name,
                class_name     => $meta->name,
                messsage       => "The 'field.init_arg' must be absent or undef, not '$init_arg'",
            );
        }
        $options{init_arg} = undef;
        $options{lazy} //= 1;

        _add_attribute( 'field', $meta, $attr, %options );
    }
}

sub _add_attribute ( $attr_type, $meta, $name, %opt_for ) {
    _debug("Finalizing options for '$attr_type $name'");

    unless ( _is_valid_method_name($name) ) {
        throw_exception(
            'InvalidAttributeDefinition',
            attribute_name => $name,
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
                attribute_name => $name,
                class_name     => $meta->name,
                messsage       => "Attribute '$name' has an invalid option name, $option => '$opt_for{$option}'",
            );
        }
    }

    if ( exists $opt_for{writer} && defined $opt_for{writer} ) {
        $opt_for{is} = 'rw';
    }

    %opt_for = _maybe_add_cloning_method( $meta, $name, %opt_for );

    _debug( "Setting $attr_type, '$name'", \%opt_for );
    $meta->add_attribute( $name, %opt_for );
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

sub _debug ( $message, @data ) {
    $MooseX::Extended::Debug //= $ENV{MOOSEX_EXTENDED_DEBUG};    # suppress "once" warnings
    return unless $MooseX::Extended::Debug;
    if (@data) {                                                 # yup, still want multidispatch
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

version 0.21

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
