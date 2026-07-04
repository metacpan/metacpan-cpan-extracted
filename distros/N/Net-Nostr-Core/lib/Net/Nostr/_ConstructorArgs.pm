package Net::Nostr::_ConstructorArgs;

use strictures 2;

use Carp qw(croak);

sub normalize {
    my (@args) = @_;
    return () if !@args;
    return %{$args[0]} if @args == 1 && ref($args[0]) eq 'HASH';
    croak "constructor arguments must be a hash or hash reference" if @args % 2;
    return @args;
}

1;
