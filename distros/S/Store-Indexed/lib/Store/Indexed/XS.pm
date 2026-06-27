package Store::Indexed::XS;
use strict;
use warnings;
use XSLoader;

our $VERSION = '0.1';
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, @keys) = @_;
    my %offset;
    my $i = 0;
    $offset{$_} = $i++ for @keys;

    # _new returns the blessed scalar reference
    my $self = Store::Indexed::XS::_new($class, scalar @keys);

    # Method injection
    no strict 'refs';
    for my $key (@keys) {
        my $col = $offset{$key};
        *{"${class}::get_$key"} = sub {$_[0]->_get($_[1], $col)};
        *{"${class}::set_$key"} = sub {$_[0]->_set($_[1], $col, $_[2])};
        *{"${class}::exists_$key"} = sub {$_[0]->_exists($_[1], $col)};
        *{"${class}::delete_$key"} = sub {$_[0]->_delete($_[1], $col)};
    }
    return $self;
}
1;
