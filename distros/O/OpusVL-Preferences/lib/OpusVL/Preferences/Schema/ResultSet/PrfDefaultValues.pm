package OpusVL::Preferences::Schema::ResultSet::PrfDefaultValues;

use Moose;
extends 'DBIx::Class::ResultSet';

sub sorted
{
    my $self = shift;
    return $self->search(undef, { order_by => ['display_order', 'value'] });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::Schema::ResultSet::PrfDefaultValues

=head1 VERSION

version 0.26

=head1 DESCRIPTION

=head1 METHODS

=head2 sorted

=head1 ATTRIBUTES

=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
