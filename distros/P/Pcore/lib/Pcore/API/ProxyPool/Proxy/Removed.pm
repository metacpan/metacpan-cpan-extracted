package Pcore::API::ProxyPool::Proxy::Removed;

use Pcore;

sub removed {
    return 1;
}

sub connect_error {
    return 1;
}

sub AUTOLOAD {    ## no critic qw[ClassHierarchies::ProhibitAutoloading]
    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Proxy::Removed

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
