package Parse::FixedRecord::Meta::Role::Class;
BEGIN {
  $Parse::FixedRecord::Meta::Role::Class::AUTHORITY = 'cpan:OSFAMERON';
}
{
  $Parse::FixedRecord::Meta::Role::Class::VERSION = '0.06';
}
use Moose::Role;
use Moose::Util::TypeConstraints;
# ABSTRACT: metaclass trait for FixedRecord parsers

use List::Util 'sum';

subtype 'My::MMA' =>
    as class_type('Moose::Meta::Attribute');

has fields => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str|My::MMA]',
    default => sub { [] },
    handles => {
        add_field => 'push',
    },
);

sub total_length {
    my $self = shift;
    return sum map { ref($_) ? $_->width : length($_) } @{ $self->fields };
}

no Moose::Role;
no Moose::Util::TypeConstraints;


1;

__END__
=pod

=head1 NAME

Parse::FixedRecord::Meta::Role::Class - metaclass trait for FixedRecord parsers

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Stores metadata about the parser. 

=head1 METHODS

=head2 total_length

Returns the total length of the string that will be parsed.

=head1 AUTHOR

osfameron <osfameron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by osfameron.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

