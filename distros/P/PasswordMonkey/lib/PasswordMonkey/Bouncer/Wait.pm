###########################################
package PasswordMonkey::Bouncer::Wait;
###########################################
use strict;
use warnings;
use base qw(PasswordMonkey::Bouncer);
use Log::Log4perl qw(:easy);
use Data::Dumper;

PasswordMonkey::make_accessor( __PACKAGE__, $_ ) for qw(
seconds
);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->{name} = "Wait For Unexpected Input";
}

###########################################
sub check {
###########################################
    my($self) = @_;

    $self->{got_output} = 0;

    DEBUG "Waiting $self->{seconds} seconds for unexpected output";

    $self->{expect}->expect( 
        $self->{seconds},
        [ qr/./ => sub {
                       $self->{got_output} = 1;
                         # We got undesired input, abort without exp_continue
                   }
          
        ]
    );

    if( $self->{got_output} ) {
        LOGWARN "Whoa, ", __PACKAGE__, " received unexpected output ",
        " ('", $self->{expect}->match(), "') within ",
        "$self->{seconds} secs moratorium. Won't send anything over.";
        return 0;
    } else {
        DEBUG "No output within $self->{seconds} seconds. We're good.";
    }

    return 1;
}

1;

__END__

=head1 NAME

PasswordMonkey::Bouncer::Wait - Bouncer waiting n secs verifying inactiviy

=head1 SYNOPSIS

    use PasswordMonkey::Bouncer::Wait;

    my $waiter = PasswordMonkey::Bouncer::Wait->new( seconds => 2 );

=head1 DESCRIPTION

Waits the specified number of seconds and ensures that no other
input is received within that time frae.

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

