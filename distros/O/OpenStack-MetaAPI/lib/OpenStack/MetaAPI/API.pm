package OpenStack::MetaAPI::API;

use strict;
use warnings;

#use Moo::Role;
#use Moo;

sub get_service {
    my (%opts) = @_;

    my $name = $opts{name}      or die "name required";
    my $auth = ref($opts{auth}) or die "auth required";

    my $pkg = ucfirst $name;
    $pkg = __PACKAGE__ . "::$pkg";

    eval qq{ require $pkg; 1 } or die "Failed to load $pkg: $@";

    delete $opts{name};

    return $pkg->new(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API

=head1 VERSION

version 0.003

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
