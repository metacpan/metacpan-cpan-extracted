package POE::Filter::Slim::CLI;

#
# $Id: CLI.pm 26 2007-09-07 04:32:54Z andy $
#
# Filter lines according to SlimServer's CLI spec:
# Any combination of CR, LF, and \0 is accepted, and
# the same line-ending must be used for the response
#
# This filter also splits and unescapes any CLI commands

use strict;
use base 'POE::Filter::Line';

use Carp qw(carp croak);
use Clone qw(clone);
use URI::Escape qw(uri_escape);

sub DEBUG () { 0 }

sub FRAMING_BUFFER   () { 0 }
sub INPUT_REGEXP     () { 1 }
sub OUTPUT_LITERAL   () { 2 }

if ( DEBUG ) {
    require Data::Dump;
}

our $VERSION = '0.02';

sub new {
    my $type = shift;
    
    my $input_regexp = qr/[\x0D|\x0A|\x00]+/;
    
    my $self = $type->SUPER::new(
        InputRegexp => $input_regexp,
    );
    
    return $self;
}

sub get_one {
    my $self = shift;
    
    LINE:
    while (1) {
        last LINE 
            unless $self->[FRAMING_BUFFER] =~ s/^(.*?)($self->[INPUT_REGEXP])//s;
        
        DEBUG && warn "using line ending: << ", unpack('H*', $2), " >>\n";
        
        # Save line-ending used in the request, it will be sent in the response
        $self->[OUTPUT_LITERAL] = $2;
        
        # Split and unescape CLI command
        my @elements = split / /, $1;
        s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg for @elements;
        
        return [ \@elements ];
    }
    
    return [];
}

sub put {
    my ( $self, $lines ) = @_;
    
    $lines = clone($lines);
    
    my @raw;
    foreach my $line ( @{$lines} ) {
        if ( ref $line eq 'ARRAY' ) {
            # Send an array of CLI commands
            my @output;
            for my $item ( @{$line} ) {
                $item = uri_escape($item);
                push @output, $item;
            }
            push @raw, join( ' ', @output ) . $self->[OUTPUT_LITERAL];
        }
        else {
            push @raw, $line . $self->[OUTPUT_LITERAL];
        }
    }
    
    DEBUG && warn "CLI Filter sent: " . Data::Dump::dump(\@raw) . "\n";
    
    return \@raw;
}

1;
__END__

=head1 NAME

POE::Filter::Slim::CLI - A POE filter for talking with SlimServer over CLI

=head1 SYNOPSIS

    use POE::Filter::Slim::CLI;
    
    my $filter    = POE::Filter::Slim::CLI->new();
    my $arrayref  = $filter->get( [ $line ] );
    my $arrayref2 = $filter->put( $arrayref );

=head1 DESCRIPTION

POE::Filter::Slim::CLI handles all the details of SlimServer's CLI protocol.
It unescapes and returns results as an arrayref.  Requests sent as arrayrefs
are translated into the correct escaped format.

It is a subclass of L<POE::Filter::Line>.

=head1 METHODS

=over

=item new

Creates a new POE::Filter::Slim::CLI object.  Accepts no arguments.

=item get_one

Parses CLI lines into arrays.

=item put

Writes array(s) of CLI requests into escaped strings.

=back

=head1 AUTHOR

Andy Grundman <andy@slimdevices.com>

=head1 SEE ALSO

L<POE>

L<POE::Filter::Line>

=cut