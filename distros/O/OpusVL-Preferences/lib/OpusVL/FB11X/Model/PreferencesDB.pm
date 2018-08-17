package OpusVL::FB11X::Model::PreferencesDB;

# ABSTRACT: FB11 model for preferences DB

use Moose;
use Switch::Plain;

BEGIN {
    extends 'Catalyst::Model::DBIC::Schema';
}

__PACKAGE__->config(
    schema_class => 'OpusVL::Preferences::Schema',
    traits => 'SchemaProxy',
);

has short_name => (
    is => "rw",
    lazy => 1,
    default => "preferences"
);

sub hats {
    (
        preferences => {
            class =>  '+OpusVL::Preferences::Hat::preferences'
        },
        dbic_schema => {
            class => 'dbic_schema::is_brain'
        },
    )
}

with "OpusVL::FB11::Role::Brain";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::FB11X::Model::PreferencesDB - FB11 model for preferences DB

=head1 VERSION

version 0.33

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
