package Net::Launchpad::Role::Common;
BEGIN {
  $Net::Launchpad::Role::Common::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Common::VERSION = '2.101';
# ABSTRACT: Common query roles usually associated with most API results

use Moose::Role;
use Function::Parameters;


method resource ($name) {
    my $link = $name . "_link";
    my $ret  = $self->lpc->get($self->result->{$link});
    return $ret;
}


method collection ($name) {
    my $link = $name . "_collection_link";
    my $ret  = $self->lpc->get($self->result->{$link});
    return $ret->{entries};
}


method owner {
    return $self->resource('owner');
}


method project {
    return $self->resource('project');
}



method recipes {
    return $self->collection('recipes');
}



method bugs {
    return $self->collection('bugs');
}



method registrant {
    return $self->resource('registrant');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Common - Common query roles usually associated with most API results

=head1 VERSION

version 2.101

=head1 METHODS

=head2 resource

Returns resource of C<name>

=head2 collection

Returns entires from collection C<name>

=head2 owner

Owner of collection

=head2 project

Project this collection belongs too

=head2 recipes

Recipes associated with collection

=head2 bugs

Bugs associated with object

=head2 registrant

User that registered this branch

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
