package Spoon::DataObject;
use Spoon::Base -Base;

stub 'class_id';
field 'id';

sub name {
    $self->{name} = shift if @_;
    return $self->{name} if defined $self->name;
    $self->{name} = $self->uri_unescape($self->id);
}

__DATA__

=head1 NAME

Spoon::DataObject - Spoon Data Object Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
