package Sweet::File::CSV;
use latest;
use Moose;
use namespace::autoclean;

extends 'Sweet::File::DSV';

sub _build_separator { ',' }

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Sweet::File::CSV

=head1 SYNOPSIS

    my $csv = Sweet::File::CSV->new(
      path => '/path/to/file.csv'
    );

=head1 INHERITANCE

Inherits from C<Sweet::File::DSV>.

=head1 ATTRIBUTES

=head2 separator

Separator defaults to C<,>.

=cut

