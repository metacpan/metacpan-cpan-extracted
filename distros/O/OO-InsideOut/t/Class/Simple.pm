package t::Class::Simple;

use OO::InsideOut qw(id register);

our $Register = register \my %Name;
our $Name     = \%Name;

sub new {
    my $class = shift;

    return bless \(my $o), ref $class || $class;
}

sub name { 
    my $id = id shift;

    scalar @_
        and $Name{ $id } = shift;

    return $Name{ $id };
}

1;
