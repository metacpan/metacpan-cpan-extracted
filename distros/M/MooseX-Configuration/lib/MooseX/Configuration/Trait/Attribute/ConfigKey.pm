package MooseX::Configuration::Trait::Attribute::ConfigKey;
BEGIN {
  $MooseX::Configuration::Trait::Attribute::ConfigKey::VERSION = '0.02';
}

use Moose::Role;

use namespace::autoclean;

use MooseX::Types::Moose qw( Str );

has config_section => (
    is      => 'ro',
    isa     => Str,
    default => q{_},
);

has config_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has original_default => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_original_default',
);

around _process_options => sub {
    my $orig = shift;
    my ( $class, $name, $options ) = @_;

    $class->throw_error(
        'Cannot define a configuration attribute unless you specify a config key name',
        data => $options
    ) unless defined $options->{key} && length $options->{key};

    $class->$orig( $name, $options );

    $class->_process_default_or_builder_option($options);

    $options->{config_section} = delete $options->{section}
        if exists $options->{section};
    $options->{config_key} = delete $options->{key};
};

sub _process_default_or_builder_option {
    my $class   = shift;
    my $options = shift;

    $options->{lazy} = 1;

    my $section = defined $options->{section} ? $options->{section} : q{_};
    my $key = $options->{key};

    if ( exists $options->{default} ) {
        my $def = $options->{default};

        if ( ref $options->{default} ) {
            $options->{default} = sub {
                my $val = $_[0]->_from_config( $section, $key );
                return $val if defined $val;
                return $def->( $_[0] );
            };
        }
        else {
            $options->{default} = sub {
                my $val = $_[0]->_from_config( $section, $key );
                return $val if defined $val;
                return $def;
            };
            $options->{original_default} = $def;
        }
    }
    elsif ( $options->{builder} ) {
        my $builder = delete $options->{builder};

        $options->{default} = sub {
            my $val = $_[0]->_from_config( $section, $key );
            return $val if defined $val;
            return $_[0]->$builder();
        };
    }
    else {
        $options->{default} = sub {
            return $_[0]->_from_config( $section, $key );
        };
    }
}

1;
