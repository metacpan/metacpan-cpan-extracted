#
# Regexp/Fields/tie.pm
#
# $Author: grazz $
# $Date: 2003/10/19 18:16:34 $
#

package Regexp::Fields::tie;

our $VERSION = "0.01";

sub TIEHASH {
    my $class = shift;
    bless {}, $class;
}

sub FETCH {
    my $key = pop;
    my $cur = curpm_map();
    $cur->{$key};
}

sub EXISTS {
    my $key = pop;
    my $cur = curpm_map();
    exists $cur->{$key};
}

sub FIRSTKEY {
    my $cur = curpm_map();
    scalar keys %$cur;
    each %$cur;
}

sub NEXTKEY {
    my $cur = curpm_map();
    each %$cur;
}

*UNTIE = *STORE = *CLEAR = *DELETE = sub {
    require Carp;
    Carp::croak("Modification of a read-only value attempted")
};

tie %{&}, __PACKAGE__;
