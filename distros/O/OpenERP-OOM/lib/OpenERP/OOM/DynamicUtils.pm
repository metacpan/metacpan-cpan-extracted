package OpenERP::OOM::DynamicUtils;


use Class::Inspector;
use Moose::Role;
use Carp ();

my $invalid_class = qr/(?: \b:\b | \:{3,} | \:\:$ )/x;

sub ensure_class_loaded
{
    my $self = shift;
    my $class = shift;
    return if Class::Inspector->loaded($class);

    my $file = Class::Inspector->filename($class);
    Carp::croak "Unable to find class $class" unless $file;
    # code stolen from Class::C3::Componentised ensure_class_loaded
    eval { local $_; require($file) } or do {

        $@ = "Invalid class name '$class'" if $class =~ $invalid_class;

        if ($self->can('throw_exception')) {
            $self->throw_exception($@);
        } else {
            Carp::croak $@;
        }
    };

    return;
}

sub prepare_attribute_for_send
{
    my $self = shift;
    my $type = shift;
    my $value = shift;

    return RPC::XML::string->new($value) if $type =~ /Str/i && defined $value;
    return RPC::XML::boolean->new($value) if $type =~ /Str/i; # return null in effect
    return $value->ymd if $type =~ qr'DateTime'i && $value && ref $value && $value->can('ymd');
    
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::DynamicUtils

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    with 'OpenERP::OOM::DynamicUtils';

    ...

        $self->ensure_class_loaded($class);

        ...

        $object_data->{$attribute->name} = $self->prepare_attribute_for_send($attribute->type_constraint, $object_data->{$attribute->name});

=head1 DESCRIPTION

This role provides a couple of common methods for our OpenERP base classes.
It's name is a bit of a misnomer because it just contains a couple of 
useful functions, rather than a clear separation of concerns.

=head1 NAME

OpenERP::OOM::DynamicUtils

=head1 METHODS

=head2 ensure_class_loaded

This method is designed to ensure we have effectively 'use'd 
the class while ensuring we don't keep reloading it.  It is effectively 
based on code seen in DBIx::Class and various other projects.

=head2 prepare_attribute_for_send

This converts dates to strings for sending and wraps up strings in RPC::XML::string
objects to prevent numbers from being transmitted as the wrong type.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
