package MooseX::Extended::Core;

# ABSTRACT: Internal module for MooseX::Extended

use v5.20.0;
use warnings;
use parent 'Exporter';
use Moose::Util qw(
  add_method_modifier
  throw_exception
);
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Storable 'dclone';
use Ref::Util qw(
  is_plain_arrayref
  is_coderef
);
use Carp 'croak';

our $VERSION = '0.07';

our @EXPORT_OK = qw(
  field
  param
  _debug
  _enabled_features
  _disabled_warnings
);

sub _enabled_features  {qw/signatures postderef postderef_qq :5.20/}             # internal use only
sub _disabled_warnings {qw/experimental::signatures experimental::postderef/}    # internal use only

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
            croak("The 'field.init_arg' must be absent or undef, not '$init_arg'");
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
    # $date, so any changes to date would be propagated.
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
            $reader => sub ( $self, $value = undef ) {
                _debug( "Args for overloaded reader/writer for $name", \@_ );
                return @_ == 1
                  ? $self->$reader_method
                  : $self->$writer_method($value);
            }
        );
    }
    return %opt_for;
}

sub _debug ( $message, $data = undef ) {
    $MooseX::Extended::Debug //= $ENV{MOOSEX_EXTENDED_DEBUG};    # suppress "once" warnings
    return unless $MooseX::Extended::Debug;
    if ( 2 == @_ ) {                                             # yup, still want multidispatch
        require Data::Printer;
        $data    = Data::Printer::np($data);
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

version 0.07

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
