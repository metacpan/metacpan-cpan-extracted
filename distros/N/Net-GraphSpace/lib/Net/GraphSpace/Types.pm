package Net::GraphSpace::Types;
use Moose::Util::TypeConstraints;

subtype 'LabelFontWeight'
    => as 'Str'
    => where { $_ ~~ [qw(normal bold)] }
    => message { "$_ is not a valid LabelFontWeight ('bold', 'normal')" };

class_type 'HTTP::Response';

1;

__END__
=pod

=head1 NAME

Net::GraphSpace::Types

=head1 VERSION

version 0.0009

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

