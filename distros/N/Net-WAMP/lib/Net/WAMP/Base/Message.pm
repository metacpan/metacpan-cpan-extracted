package Net::WAMP::Base::Message;

use strict;
use warnings;

use Net::WAMP::Messages ();

use constant NUMERIC => ();

use constant HAS_AUXILIARY => 0;

sub new {
    my ($class, @args) = @_;

    my @parts = $class->PARTS();

    my $self = { map { ( "_$parts[$_]" => $args[$_] ) } 0 .. $#args };

    $self->{'_Auxiliary'} ||= {} if $class->HAS_AUXILIARY();

    return bless $self, $class;
}

sub get {
    my ($self, $key) = @_;

    if (grep { $_ eq $key } $self->PARTS()) {
        return $self->{"_$key"};
    }
    elsif ( $key eq 'Options' or $key eq 'Details' ) {
        return $self->{'_Auxiliary'};
    }

    my $name = $self->get_type();
    die "Unrecognized attribute of “$name” message: “$key”";
}

sub get_type {
    my ($self) = @_;

    ref($self) =~ m<.+::(.+)> or die "module name ($self)??";

    return $1;
}

#Leaving this undocumented since there’s no good reason to want to
#use it from an application. (Right?)
sub to_unblessed {
    my ($self) = @_;

    #So that our serializer will send these correctly.
    #Other languages actually care about the difference...:-/
    for my $num_label ( $self->NUMERIC() ) {
        $self->{"_$num_label"} += 0;
    }

    my @msg = (
        Net::WAMP::Messages::get_type_number( $self->get_type() ),
        ( map { exists($self->{"_$_"}) ? $self->{"_$_"} : () } $self->PARTS() ),
    );

    return \@msg;
}

1;
