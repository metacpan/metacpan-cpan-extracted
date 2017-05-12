###########################################
package PasswordMonkey::Filler;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);

PasswordMonkey::make_accessor( __PACKAGE__, $_ ) for qw(
name
password
dealbreakers
);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        password => undef,
        bouncers => [],
        name => $class,
        dealbreakers => [],
        %options,
    };

    bless $self, $class;
}

###########################################
sub prompt {
###########################################
    my($self) = @_;

    die "'prompt' needs to be overridden by the plugin class";
}

###########################################
sub bouncer_add {
###########################################
    my($self, $bouncer) = @_;

    push @{ $self->{bouncers} }, $bouncer;
}

###########################################
sub bouncers {
###########################################
    my($self) = @_;

    return @{ $self->{ bouncers } };
}

###########################################
sub fill {
###########################################
    my($self, $exp, $monkey) = @_;

    DEBUG "$self->{name}: Sending password to '", $exp->match, "' prompt";

    my $password = $self->password();
    
    if( ref($password) eq "CODE" ) {
          # We also accept a coderef which we evaluate here.
        $password = $password->();
    }

      # To be sure the password doesn't end up in the output if 
      # the collecting program forgot to turn echoing off (or we fell
      # for something that looked like a password prompt but the 
      # driven program isn't collecting at all), check first and if 
      # echo is on, turn it off on the pty slave manually.
    my $stty_settings = $exp->slave->stty("-a");
    DEBUG "stty_settings are $stty_settings";

    my $echo_is_on = 1;
    if( $stty_settings =~ /-echo\b/ ) {
        $echo_is_on = 0;
    }

    if( $echo_is_on ) {
        ERROR "Whoa there! Echo on pty slave is on. ",
              "Turning it off before sending password.";
        $exp->slave->stty(qw(-echo));
    }

    DEBUG "Sending password over to slave pty";
    $exp->send( $password, "\n" );


    if( $echo_is_on ) {
        ERROR "Restoring echo on slave pty.";

          # Just sending over 'echo' here seems to be too early to suppress
          # echoing the password we just sent. 
          # 
          # Worse, there doesn't seem to be a reliabe way to wait until the
          # Pty slave won't echo the password we just sent if we turn on
          # its echo. I've tried sending another '-echo', sending a '-a'
          # to retrieve status, but none of them makes sure the Pty slave
          # will have flushed the data and they're failing in unpredictable
          # ways based on race conditions.
          # 
          # This is horrible, but I got best results by sleeping a second 
          # before turning the echo back on, so that's what we're stuck
          # with right now. What a mess.
        sleep 1;

        $exp->slave->stty(qw(echo));
    }

    1;
}

###########################################
sub pre_fill {
###########################################
    my($self, $exp, $monkey) = @_;

    DEBUG "$self->{name}: Prefill callback (base)";
}

###########################################
sub post_fill {
###########################################
    my($self, $exp, $monkey) = @_;

    DEBUG "$self->{name}: Postfill callback (base)";
}

###########################################
sub init {
###########################################
    my($self) = @_;
}

1;

__END__

=head1 NAME

PasswordMonkey::Filler - Filler Base Class

=head1 SYNOPSIS

    use PasswordMonkey::Filler;

=head1 DESCRIPTION

PasswordMonkey filler plugin base class. Don't use directly, but let your
plugins inherit from it.

Plugins need to define the following methods:

=over 4

=item C<prompt>

Returns the prompt (as a regular expression) the plugin is waiting
for.

=back

The following methods are optional:

=over 4

=item C<pre_fill>

Gets called before the password is sent. Can be used for diagnostics or
user notification via $monkey->expect->send_user().

=item C<post_fill>

Gets called after the password has been sent.

=item C<fill>

Defaults to a base class method sending the password via Expect. If you
roll your own, make sure to take a look at what the base class method does, 
as you need to replicate it.

=back

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

