package Office365::EWS::Client::GAL;
use Moose;
with 'Office365::EWS::GAL::Role::Reader';
has client => (
    is => 'ro',
    isa => 'EWS::Client',
    required => 1,
    weak_ref => 1,
);
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Office365::EWS::Client::GAL

=head1 VERSION

version 1.142410

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
