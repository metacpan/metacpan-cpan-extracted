package OpusVL::AppKit::Schema::AppKitAuthDB::ResultSet::Aclfeature;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub sorted
{
    my $self = shift;
    return $self->search(undef, { order_by => ['feature'] });
}

sub descriptions
{
    my $self = shift;
    my @all = $self->all;
    my %names;
    for my $f (@all)
    {
        my ($app, $feature) = $f->feature =~ m|^(.+)/(.*)$|;
        # auto vivification?
        $names{$app}->{$feature} = $f->feature_description;
    }
    return \%names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::ResultSet::Aclfeature

=head1 VERSION

version 6

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
