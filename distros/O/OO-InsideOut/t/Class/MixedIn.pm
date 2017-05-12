package t::Class::MixedIn;

use OO::InsideOut qw(id register);

our $Register = register \my %Middlename;

sub middlename { 
    my $id = id shift;

    scalar @_
        and $Middlename{ $id } = shift;

    return $Middleame{ $id };
}

1;
