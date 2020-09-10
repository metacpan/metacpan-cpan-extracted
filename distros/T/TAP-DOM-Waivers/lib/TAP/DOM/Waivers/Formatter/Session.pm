package TAP::DOM::Waivers::Formatter::Session;
our $AUTHORITY = 'cpan:SCHWIGON'; # better TAP::Formatter::DOM::Session?
# ABSTRACT: (incomplete) 'prove' plugin support for TAP::DOM::Waivers
$TAP::DOM::Waivers::Formatter::Session::VERSION = '0.003';
use strict;
use warnings;

use base qw( TAP::Base );
use accessors qw( test formatter parser results html_id meta closed taplines );

use YAML::Any;
use TAP::DOM;
use TAP::DOM::Waivers 'waive';
use File::Temp 'tempfile';

sub _slurp {
        my ($filename) = @_;

        local $/;
        open (my $F, "<", $filename) or die "Cannot read $filename";
        return <$F>;
}

sub _initialize {
    my ($self, $args) = @_;

    $args ||= {};
    $self->SUPER::_initialize($args);

    $self
     ->results([])
     ->meta({})
     ->closed(0)
     ->taplines([])
      ;
    foreach my $arg (qw( test parser formatter )) {
            $self->$arg($args->{$arg}) if defined $args->{$arg};
    }

    $self->info( "INITIALIZE: " . $self->test . ':' );

    return $self;
}

sub result {
    my ($self, $result) = @_;

    push @{$self->taplines}, $result->raw;
}

# Called by TAP::?? to indicate there are no more test results coming
sub close_test {
    my ($self, @args) = @_;

    $self->info( "CLOSE" );

    $self->info( $_ ) foreach @{$self->taplines};

    my ($FH_tmptap, $tmptap) = tempfile();
    my $waiverfile     = $self->formatter->waiver;
    my $tapfile        = $self->test;
    my $waivers        = YAML::Any::Load(_slurp($waiverfile));
    my $tapdom         = TAP::DOM->new(tap => _slurp($tapfile));
    my $patched_tapdom = waive($tapdom, $waivers);
    $self->info( "*** PATCHED_TAP: ".$patched_tapdom->to_tap );

    $self->closed(1);
    return;
}

sub as_report {
    my ($self) = @_;
    my $p = $self->parser;
    my $r = {
        test => $self->test,
        results => $self->results,
        AFFE => "ZOMTEC",
    };

    $self->info( "AS_REPORT" );

    return $r;
}

sub log {
    my ($self, @args) = @_;
    $self->formatter->log_test(@args);
}

sub info {
    my ($self, @args) = @_;
    $self->formatter->log_test_info(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Waivers::Formatter::Session - (incomplete) 'prove' plugin support for TAP::DOM::Waivers

=head2 METHODS

=head3 as_report

=head3 close_test

=head3 info

=head3 log

=head3 result

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
