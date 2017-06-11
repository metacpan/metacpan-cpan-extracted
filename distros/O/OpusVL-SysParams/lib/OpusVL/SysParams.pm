package OpusVL::SysParams;

use warnings;
use strict;
use JSON;
use Data::Munge qw/elem/;

use Moose;

has 'schema' => (isa => 'DBIx::Class::Schema', is => 'ro', required => 1,
    default => sub
    {
        # this means we only load Config::JFDI and create our schema if they
        # don't specify their own schema.
        require Config::JFDI;
        require OpusVL::SysParams::Schema;
        my $config = Config::JFDI->new(name => __PACKAGE__);
        my $config_hash = $config->get;
        my $schema = OpusVL::SysParams::Schema->connect( @{$config_hash->{'Model::SysParams'}->{connect_info}} );
        return $schema;
    }
); 

# ABSTRACT: Module to handle system wide parameters


our $VERSION = '0.20';



sub get {
    my $self = shift;
    my $schema = $self->schema;
    return $schema->resultset('SysInfo')->get(@_);
}


sub get_or_set {
    my ($self, $name, $default_sub, $type) = @_;
    if (elem $name, [$self->key_names]) {
        return $self->get($name);
    }
    else {
        my $value = $default_sub->($self);
        $self->set($name, $value, $type);
        return $value;
    }
}


sub del {
    my $self = shift;
    my $schema = $self->schema;
    return $schema->resultset('SysInfo')->del(@_);
}


sub key_names {
    my $self = shift;
    my $schema = $self->schema;
    return $schema->resultset('SysInfo')->key_names(@_);
}


sub set {
    my $self = shift;
    my $schema = $self->schema;
    return $schema->resultset('SysInfo')->set(@_);
}


sub set_json {
    my $self = shift;
    my $name = shift;
    my $val = shift;
    my $schema = $self->schema;
    my $obj = JSON->new->allow_nonref->decode($val);
    return $schema->resultset('SysInfo')->set($name, $obj);
}


sub get_json {
    my $self = shift;
    my $schema = $self->schema;

    my $val = $schema->resultset('SysInfo')->get(@_);
    return if !$val;
    return JSON->new->allow_nonref->encode($val);
}


1; # End of OpusVL::SysParams

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::SysParams - Module to handle system wide parameters

=head1 VERSION

version 0.20

=head1 SYNOPSIS

This module handles system wide parameters.

    use OpusVL::SysParams;

    my $sys_param = OpusVL::SysParams->new();

    # or 

    my $sys_param = OpusVL::SysParams->new({ schema => $schema});

    my $val = $sys_param->get('login.failures');
    $sys_param->set('login.failures', 3);
    ...

=head1 METHODS

=head2 new

If the constructor is called without a schema specified it will attempt to load up a schema based
on a config file in the catalyst style for the name 'OpusVL::SysParams'.  This config file should
have a Model::SysParams section containing the config.

    <Model::SysParams>
        connect_info dbi:Pg:dbname=test1
        connect_info user
        connect_info password
    </Model::SysParams>

Note that you must specify at least 2 connect_info parameters even if you are using SQLite otherwise
the code will crash.

=head2 get

Get a system parameter.  The key name is simply a string.  It's suggested you use some 
kind of schema like 'system.key' to prevent name clashes with other unoriginal programmers.

=head2 get_or_set

Get a system parameter, setting it to a default if it doesn't already exist.

    $params->get_or_set($name, $default_sub);

C<$name> - the name of the system parameter

C<$default_sub> - A CODEREF returning the default value.  C<$params> (your instance of L<OpusVL::SysParams>) is passed as the first argument.

C<$type> - We will try to determine the type from your C<$default_sub>, but if it's unclear, you may wish to be explicit here.

Example:

   $params->get_or_set('partner.titles', sub { 'Mr|Mrs|Miss|Mx' });

=head2 del

Delete a system parameter.  The key name is simply a string.  

=head2 key_names

Returns the keys of the system parameters.

=head2 set

Set a system parameter.  The key name is simply a string.  It's suggested you use some 
kind of schema like 'system.key' to prevent name clashes with other unoriginal programmers.

The value can be any data structure so long as it doesn't contain code.  

=head2 set_json

Set a system parameter.  This allows you to pass the object encoded as JSON in order to make it simpler
for web interfaces to talk to the settings.

=head2 get_json

Returns the value encoded in json.  Primarily for talking with web interfaces.

=head1 SUPPORT

If you require assistance, support, or further development of this software, please contact OpusVL using the details below:

=over 4

=item *

Telephone: +44 (0)1788 298 410

=item *

Email: community@opusvl.com

=item *

Web: L<http://opusvl.com>

=back

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2016 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
