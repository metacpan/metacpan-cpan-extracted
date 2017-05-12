package Parse::FixedRecord::Column;
BEGIN {
  $Parse::FixedRecord::Column::AUTHORITY = 'cpan:OSFAMERON';
}
{
  $Parse::FixedRecord::Column::VERSION = '0.06';
}
use Moose::Role;
use Moose::Util::TypeConstraints;
# ABSTRACT: trait for FixedRecord columns

has width => (
    is        => 'ro',
    isa       => 'Int',
    );

sub Moose::Meta::Attribute::Custom::Trait::Column::register_implementation { 
    'Parse::FixedRecord::Column' 
};


1;

__END__
=pod

=head1 NAME

Parse::FixedRecord::Column - trait for FixedRecord columns

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Responsible for declaring the C<width> column.

=head3 C<register_implementation>

Declares the trait alias C<Column>.

=head1 AUTHOR

osfameron <osfameron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by osfameron.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

