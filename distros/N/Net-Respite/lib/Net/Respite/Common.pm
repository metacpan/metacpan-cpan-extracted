package Net::Respite::Common;

=pod

=head1 NAME

  Net::Respite::Common - Common methods used internally

=head1 SYNOPSIS

    package CustomModule;
    use base 'Net::Respite::Common';

    sub xkey1 { return shift->_configs->{xxx_key} || "unknown" }

    sub parse1 { return shift->json->decode(shift) }

=cut

use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    return bless {%{$args || {}}}, $class;
}

our $js;
sub json { $js ||= eval { require JSON; JSON->new->utf8->allow_unknown->allow_nonref->convert_blessed->canonical } || die "Could not load JSON: $@" }
our $jp;
sub jsop { $jp ||= eval { require JSON; JSON->new->utf8->allow_unknown->allow_nonref->convert_blessed->canonical->pretty } || die "Could not load JSON: $@" }

our $config;
sub _configs {
    return $config ||= do {
        my $c = undef;
        eval {
            require config;
            eval { $c = config->load };
            $c ||= defined($config::config) && "HASH" eq ref $config::config && $config::config;
            $c ||= %config::config ? \%config::config : undef;
        };
        "HASH" eq ref $c or $c = { failed_load => ($@ || "missing config::config hash") };
        $c;
    };
}

1;
