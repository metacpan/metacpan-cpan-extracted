package MooseX::Configuration::Trait::Attribute;
BEGIN {
  $MooseX::Configuration::Trait::Attribute::VERSION = '0.02';
}

use Moose::Role;

use namespace::autoclean;

around interpolate_class => sub  {
    my $orig = shift;
    my ( $class, $options ) = @_;

    if ( exists $options->{section} || exists $options->{key} ) {
        $options->{traits} ||= [];
        push @{ $options->{traits} }, 'MooseX::Configuration::Trait::Attribute::ConfigKey';
    }

    return $class->$orig($options);
};

1;
