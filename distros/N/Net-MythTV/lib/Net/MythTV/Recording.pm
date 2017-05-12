package Net::MythTV::Recording;
use Moose;
use MooseX::StrictConstructor;

has 'title' => (
    is  => 'rw',
    isa => 'Str',
);

has 'channel' => (
    is  => 'rw',
    isa => 'Str',
);

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'size' => (
    is  => 'rw',
    isa => 'Int',
);

has 'start' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'stop' => (
    is  => 'rw',
    isa => 'DateTime',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::MythTV::Recording - A MythTV recording

=head1 SEE ALSO

L<Net::MythTV>, L<Net::MythTV::Connection>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

