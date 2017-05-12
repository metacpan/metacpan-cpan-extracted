package Mock::Person::JP::Person;

use strict;
use warnings;
use Mock::Person::JP::Person::Name ();

sub new
{
    my ($class, $arg) = @_;

    return bless $arg, $class;
}

sub name { Mock::Person::JP::Person::Name->new(shift->{name}); }

1;

__END__

=encoding utf-8

=head1 NAME

Mock::Person::JP::Person - Get personal information

=head1 SYNOPSIS

See L<Mock::Person::JP>.

=head1 METHODS

=head2 name()

Returns a new L<Mock::Person::JP::Person::Name> instance.
