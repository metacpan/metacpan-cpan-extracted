package TAP::DOM::Waivers::Formatter;
BEGIN {
  $TAP::DOM::Waivers::Formatter::AUTHORITY = 'cpan:SCHWIGON';
} # better TAP::Formatter::DOM?
# ABSTRACT: (incomplete) 'prove' plugin support for TAP::DOM::Waivers
$TAP::DOM::Waivers::Formatter::VERSION = '0.002';
use strict;
use warnings;

use TAP::DOM::Waivers::Formatter::Session; # better TAP::Formatter::DOM::Session?
use Data::Dumper;

use base qw( TAP::Base );
use accessors qw(
                        verbosity
                        tests
                        session_class
                        escape_output
                        stdout
                        sessions
                        waiver
               );

our @TFW_ARGS = qw(
                          waiver
                          escape_output
                 );

# global variables
sub _initialize {
    my ($self, $args) = @_;

    $args ||= {};
    $self->SUPER::_initialize($args);

    my $stdout_fh = IO::File->new_from_fd( fileno(STDOUT), 'w' )
      or die "Error opening STDOUT for writing: $!";

    $self->verbosity( 0 )
          ->stdout( $stdout_fh )
          ->escape_output( 0 )
          ->session_class( "TAP::DOM::Waivers::Formatter::Session" )
          ->sessions( [] )
          ;

    # Laziness...
    # trust the user knows what they're doing with the args:
    foreach my $key (keys %$args) {
            $self->info( "INIT args.$key = ", $args->{$key}, "\n") if $self->can( $key );
            $self->$key( $args->{$key} ) if ($self->can( $key ));
    }
    $self->info( "KEY: $_ = ".$args->{$_} ) foreach keys %$args;

    $self->check_for_overrides_in_env;

    $self->info( "WAIVER FILE: ".$self->waiver );


    return $self;
}

sub check_for_overrides_in_env {
    my $self = shift;

    foreach my $arg (@TFW_ARGS) {
            my $val = $ENV{"TAP_FORMATTER_WAIVERS_".uc($arg)};
            $self->info( "arg: $arg = $val" ) if defined $val;
            $self->$arg( $val ) if defined $val;
    }

    return $self;
}

# Called by Test::Harness before any test output is generated.
sub prepare {
    my ($self, @tests) = @_;
    # warn ref($self) . "->prepare called with args:\n" . Dumper( \@tests );
    $self->info( 'PREPARE ', scalar @tests, ' tests' );
    $self->tests( [@tests] );
}

sub open_test {
    my ($self, $test, $parser) = @_;
    #warn ref($self) . "->open_test called with args: " . Dumper( [$test, $parser] );
    $self->info( 'OPEN_TEST');
    my $session = $self->session_class->new({ test => $test,
                                              parser => $parser,
                                              formatter => $self,
                                            });
    push @{ $self->sessions }, $session;
    return $session;
}

sub summary {
        my ($self, $aggregate) = @_;

        if (! $self->silent) {
                $self->info("SUMMARY");
        }

        # $self->info( "PARSER:   ", Dumper($self->sessions->[0]->parser) );
        # $self->info( "SESSIONS: ", Dumper($self->sessions) );

        return $self;
}

sub log {
    my $self = shift;
    push @_, "\n" unless grep {/\n/} @_;
    $self->_output( @_ );
    return $self;
}

sub info {
    my $self = shift;
    return unless $self->verbose;
    return $self->log( @_ );
}

sub log_test {
    my $self = shift;
    return if $self->really_quiet;
    return $self->log( @_ );
}

sub log_test_info {
    my $self = shift;
    return if $self->quiet;
    return $self->log( @_ );
}

sub _output {
    my $self = shift;
    return if $self->silent;
    if (ref($_[0]) && ref( $_[0]) eq 'SCALAR') {
        # DEPRECATED: printing HTML:
        print { $self->stdout } ${ $_[0] };
    } else {
        unshift @_, '# ' if $self->escape_output;
        print { $self->stdout } @_;
    }
}

sub verbose {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(1) }
    return $self->verbosity >= 1;
}

sub quiet {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-1) }
    return $self->verbosity <= -1;
}

sub really_quiet {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-2) }
    return $self->verbosity <= -2;
}

sub silent {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-3) }
    return $self->verbosity <= -3;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Waivers::Formatter - (incomplete) 'prove' plugin support for TAP::DOM::Waivers

=head2 METHODS

=head3 check_for_overrides_in_env

=head3 info

=head3 log

=head3 log_test

=head3 log_test_info

=head3 open_test

=head3 prepare

=head3 quiet

=head3 really_quiet

=head3 silent

=head3 summary

=head3 verbose

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
