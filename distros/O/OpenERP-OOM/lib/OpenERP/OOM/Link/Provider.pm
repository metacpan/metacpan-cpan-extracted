package OpenERP::OOM::Link::Provider;

use Moose::Role;

requires 'provide_link';
with 'OpenERP::OOM::DynamicUtils';

sub close_connections
{
}

=head1 NAME

OpenERP::OOM::Link::Provider

=head1 DESCRIPTION

This is the role for a link provider that provides a way to link another dataset,
normally a DBIC dataset.

=head1 SYNOPSIS

    package MyLinkProvider;

    use Moose;
    with 'OpenERP::OOM::Link::Provider';

    sub provide_link 
    {
        my ($self, $class) = @_;
        
        my $package = ($class =~ /^\+/) ? $class : "OpenERP::OOM::Link::$class";

        eval "use $package";
        $self->ensure_class_loaded($package);
        
        return $package->new(
            schema => $self,
            config => $self->link_config->{$class},
        );
    }

    1;

=head1 METHODS

=head2 close_connections

This method should close any open database connections held by the link provider.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
