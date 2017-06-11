package Plack::Middleware::Memento::Handler;

our $VERSION = '0.0102';

use strict;
use warnings;
use Role::Tiny;
use namespace::clean;

requires 'get_all_mementos';

sub wrap_original_resource_request {
    return;
}

sub wrap_memento_request {
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Memento - Enable the Memento protocol

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::App::Catmandu::Bag;

    builder {
        enable 'Memento', handler => 'Catmandu::Bag', store => 'authority', bag => 'person';
        Plack::App::Catmandu::Bag->new(
            store => 'authority',
            bag => 'person',
        )->to_app;
    };

=head1 DESCRIPTION

This is an early minimal release, documentation and tests are lacking.

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=head1 COPYRIGHT

Copyright 2017- Nicolas Steenlant

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
