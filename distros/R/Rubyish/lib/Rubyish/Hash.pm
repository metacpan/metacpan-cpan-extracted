=head1 NAME

Rubyish::Hash - Hash (class)

=cut

package Rubyish::Hash;

use base qw(Rubyish::Object); # inherit parent
use Rubyish::Syntax::def;

=head1 FUNCTIONS

=head2 new

constructor

=cut

sub new {
    my $self = ref($_[1]) eq "HASH" ? $_[1] : {};
    bless $self, $_[0];
}

=head2 inspect      #=> perl_string

in

=cut

def inspect() {
    my $result;
    while ( my ($key, $value) = each %{$self} ) {
        $result .= "$key => $value, ";
    }
    $result =~ s/, $/ /g;
    "{ " . $result . "}";
}

=head2 fetch

=head2 {}

Retrieves the value Element corresponding to the key.

    $hash = Hash({ hello => "world" });
    $hash->fetch("hello")   #=> world
    $hash->{hello}          #=> world

=cut

def fetch($key) {
    $self->{$key}
};

=head2 each

=head2 map

    $hash = Hash({ blah~ });
    $hash->each( sub {
        my ($key, $value) = @_;  # specify your iterator
        print "$key => $value\n";
    });

=cut

def each($sub) {
    %result = %{$self};
    while ( my ($key, $value) = each %result ) { 
        $sub->($key,$value);
    }
    $self;
};
{ no strict; *map = *each; }

1;
