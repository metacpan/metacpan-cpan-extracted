package Mite::Role::HasDefault;
use Mite::MyMoo -Role;

# Get/set the default for a class
my %Defaults;
sub default {
    my $class = shift;
    return $Defaults{$class} ||= $class->new;
}

sub set_default {
    my ( $class, $new_default ) = ( shift, @_ );
    $Defaults{$class} = $new_default;
    return;
}

1;
