package Mite::Role::HasDefault;

use feature ':5.10';
use Mouse::Role;
use Method::Signatures;

# Get/set the default for a class
my %Defaults;
method default($class:) {
    return $Defaults{$class} ||= $class->new;
}

method set_default($class: $new_default) {
    $Defaults{$class} = $new_default;
    return;
}

1;
