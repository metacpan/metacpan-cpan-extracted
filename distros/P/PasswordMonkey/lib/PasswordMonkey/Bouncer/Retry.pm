###########################################
package PasswordMonkey::Bouncer::Retry;
###########################################
use strict;
use warnings;
use PasswordMonkey;
use base qw(PasswordMonkey::Bouncer);
use Log::Log4perl qw(:easy);
use Data::Dumper;

PasswordMonkey::make_accessor( __PACKAGE__, $_ ) for qw(
timeout
);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->{name} = "Retry Bouncer";
}

###########################################
sub check {
###########################################
    my($self) = @_;

    my $prompt_match = $self->{expect}->match();
    my $prompt_comes_back = 0;

    DEBUG "Hitting Return and waiting $self->{timeout} seconds ",
          "to see if the prompt ($prompt_match) reappears";
    $self->{expect}->send( "\n" );
    DEBUG "Waiting for prompt to reappear";

    $self->{expect}->expect(
        $self->{timeout},
        [ qr/\Q$prompt_match\E/ => sub {
            DEBUG "Prompt ($prompt_match) came back";
            DEBUG "Match before: ", $self->{expect}->before();
            $prompt_comes_back = 1;
          }
        ]
    );

    if(! $prompt_comes_back) {
        LOGWARN "$self->{name}: Prompt didn't come back";
        return 0;
    }

    return 1;
}

1;

__END__

=head1 NAME

PasswordMonkey::Bouncer::Retry - Bouncer hits Enter and expects password prompt to come back

=head1 SYNOPSIS

    use PasswordMonkey::Bouncer::Retry;

    my $hitter = PasswordMonkey::Bouncer::Retry->new( timeout => 2 );

=head1 DESCRIPTION

To verify a password prompt, this bouncer hits return on the first
appearance, expecting to get another prompt. If this doesn't happen
within the specified time frame, the prompt is considered to be invalid.

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

