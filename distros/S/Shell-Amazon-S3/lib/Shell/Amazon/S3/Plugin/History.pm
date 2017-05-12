package Shell::Amazon::S3::Plugin::History;

use Moose::Role;
use namespace::clean -except => ['meta'];

has 'history' => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { [] }
);

sub push_history {
    my ( $self, $line ) = @_;
    push( @{ $self->history }, $line );
}

around 'read' => sub {
    my $orig = shift;
    my ( $self, @args ) = @_;
    my $line = $self->$orig(@args);
    if ( defined $line ) {
        if ( $line =~ m/^!(.*)$/ ) {
            my $call = $1;
            $line = $self->history_call($call);
            if ( defined $line ) {
                $self->print( $line . "\n" );
            }
            else {
                return "'Unable to find ${call} in history'";
            }
        }
        if ( $line =~ m/\S/ ) {
            $self->push_history($line);
        }
    }
    return $line;
};

sub history_call {
    my ( $self, $call ) = @_;
    if ( $call =~ m/^(-?\d+)$/ ) {    # handle !1 or !-1
        my $idx = $1;
        $idx-- if ( $idx > 0 );       # !1 gets history element 0
        my $line = $self->history->[$idx];
        return $line;
    }
    my $re = qr/^\Q${call}\E/;
    foreach my $line ( reverse @{ $self->history } ) {
        return $line if ( $line =~ $re );
    }
    return;
}

1;
