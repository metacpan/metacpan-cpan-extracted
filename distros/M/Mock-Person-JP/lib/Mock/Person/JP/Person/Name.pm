package Mock::Person::JP::Person::Name;

use strict;
use warnings;

sub new
{
    my ($class, $name_hashref) = @_;

    return bless $name_hashref, $class;
}

sub first_name      { shift->{mei}; }
sub last_name       { shift->{sei}; }
sub sei             { shift->{sei}; }
sub mei             { shift->{mei}; }

sub first_name_yomi { shift->{mei_yomi}; }
sub last_name_yomi  { shift->{sei_yomi}; }
sub sei_yomi        { shift->{sei_yomi}; }
sub mei_yomi        { shift->{mei_yomi}; }

1;

__END__

=encoding utf-8

=head1 NAME

Mock::Person::JP::Person::Name - Get first name and last name

=head1 SYNOPSIS

See L<Mock::Person::JP>.

=head1 METHODS

=head2 fitst_name(), mei()

Returns the generated first name (名).

=head2 last_name(), sei()

Returns the generated last name (姓).

=head2 first_name_yomi(), last_name_yomi(), sei_yomi(), mei_yomi()

Returns the yomi (pronunciation).
