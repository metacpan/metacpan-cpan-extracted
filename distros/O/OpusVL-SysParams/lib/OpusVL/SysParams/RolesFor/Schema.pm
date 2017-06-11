package OpusVL::SysParams::RolesFor::Schema;

use Moose::Role;
use OpusVL::SysParams;

requires 'load_namespaces';


has sys_params => (isa => 'OpusVL::SysParams', is => 'rw', lazy_build => 1);

sub _build_sys_params
{
    my $self = shift;
    return OpusVL::SysParams->new({ schema => $self });
}


# FIXME: point it to our schema stuff.
sub setup_sysparams
{
    my $class = shift;
    my $package = shift;
    $package->load_namespaces(
        result_namespace => '+OpusVL::SysParams::Schema::Result',
        resultset_namespace => '+OpusVL::SysParams::Schema::ResultSet',
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::SysParams::RolesFor::Schema

=head1 VERSION

version 0.20

=head1 SYNOPSIS

This allows for our logging to be inserted into an existing schema and make use of the existing
connection details.  The class actually injects our schema objects into the existing schema and 
adds a 'sys_params' object to the schema.

    # in your schema class.
    with 'OpusVL::SysParams::RolesFor::Schema';
    OpusVL::SysParams::RolesFor::Schema->setup_sysparams(__PACKAGE__);

    # now anywhere that has access to the schema can access the 
    # sys_params object.
    $schema->sys_params->get('param.name'); 

=head1 METHODS

=head2 sys_params

The OpusVL::SysParams object connected via your schema.

=head2 setup_sysparams

This method injects the result/resultset objects needed by the SysParams object into a the schema
this role has been applied to.  If this isn't called as suggested in the synopsis you will need to
have these results already loaded in your schema somehow.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2016 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
