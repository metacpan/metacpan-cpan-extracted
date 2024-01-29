package Password::Policy::Exception;
$Password::Policy::Exception::VERSION = '0.06';
use strict;
use warnings;

use overload 
    '""' => sub { shift->error },
    'cmp'   => \&_three_way_compare;


sub new { bless {} => shift; }
sub error { return "An unspecified exception was thrown."; }
sub throw { die shift->new; }

sub _three_way_compare {
    my $self = shift;
    my $other = shift || '';
    return $self->error cmp "$other";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Exception

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
