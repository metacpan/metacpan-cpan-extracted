
package Tao::DBI::st_deep;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA    = qw(Tao::DBI::st);
our @EXPORT = qw();

our $VERSION = '0.012';

use Tao::DBI::st;
use Carp;

# instance variables:
#   META

# initiates a Tao::DBI::st_deep object
# { dbh => , sql => , meta => , }
sub initialize {
    my ( $self, $args ) = @_;
    $self->SUPER::initialize($args);
    $self->{META} = $args->{meta};
    return $self;
}

###############

sub to_perl {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper(shift);
}

sub to_yaml {
    require YAML;
    return YAML::Dump(shift);
}

sub to_json {
    require JSON;
    return JSON::encode_json(shift)
}

sub from_perl {
    no strict 'vars';
    my $data = eval shift;    # oops! that's DANGEROUS!
    die $@ if $@;
    return $data;
}

sub from_yaml {
    require YAML;
    return YAML::Load(shift);
}

sub from_json {
    require JSON;
    return JSON::decode_json(shift);
}

my %tr_functions = (
    ddumper => \&to_perl,
    yaml    => \&to_yaml,
    json    => \&to_json,
);

my %i_tr_functions = (
    ddumper => \&from_perl,
    yaml    => \&from_yaml,
    json    => \&from_json,
);

# $g = tr_hash($h, $ctl) converts hashrefs to hashrefs
# $g = tr_hash($h, $ctl, 1) does the reverse convertion
#
# requires:
#  $ctl is an array ref with an even number of elements
sub tr_hash {
    my $h = shift;
    return undef unless defined $h;

    my $ctl = shift;
    my $inv = shift;

    my %h = %$h;
    my %g;    # the result
    my %m;    # the visited keys
    my @ctl = @$ctl;

    while (@ctl) {
        my ( $k, $fk ) = split ':', shift @ctl;
        my ( $v, $fv ) = split ':', shift @ctl;

        if ($inv) {
            ( $k,  $v )  = ( $v,  $k );
            ( $fk, $fv ) = ( $fv, $fk );
        }

        if ( $k eq '*' ) {    # h{*} -> g{$k}
            while ( my ( $a, $b ) = each %h ) {
                $g{$v}{$a} = $b, $m{$a}++ unless $m{$a};
            }
            if ($fv) {
                $g{$v} = &{ $tr_functions{$fv} }( $g{$v} );
            }
        }
        elsif ( $v eq '*' ) {    # h{$k} -> g{*}
            if ($fk) {
                $h{$k} = &{ $i_tr_functions{$fk} }( $h{$k} );
            }
            croak "val at '$k' (", ( ref $h{$k} || 'non-ref scalar' ),
              ") should be hashref"
              unless ref $h{$k} eq 'HASH';    # FIXME:
            while ( my ( $a, $b ) = each %{ $h{$k} } ) {
                $g{$a} = $b;
            }
            $m{$k}++;
        }
        else {
            $g{$v} = $h{$k};
            $m{$k}++;
        }

    }

    return \%g;
}

# sub comp_map_h {
# }
# returns a sub which does the same map_h

###############

sub trace {
    my $self = shift;
    return 0;    # FIXME: $self->{TRACE} || $self->{DBH}->{TRACE}
}

sub fetchrow_hashref {
    my $self = shift;
    my $raw  = $self->SUPER::fetchrow_hashref(@_);
    return undef unless defined $raw;
    if ( $self->trace ) { require YAML; warn YAML::Dump( { RAW => $raw } ) }
    my $row = tr_hash( $raw, $self->{META}, 1 );
}

sub execute {
    my $self        = shift;
    my $bind_values = shift;
    if ( ref $bind_values ) {
        my $raw = {};
        $raw = tr_hash( $bind_values, $self->{META} ) if $bind_values;
        return $self->SUPER::execute( $raw, @_ );
    }
    else {    # single non-ref arg - we don't try transformations
        return $self->SUPER::execute( $bind_values, @_ );
    }
}

__END__

=head1 NAME

Tao::DBI::st_deep - Tao statements for reading/writing nested Perl data in relational databases

=head1 SYNOPSIS

  use Tao::DBI qw(dbi_connect);

  $stmt = $dbh->prepare($sql, { type => 'deep', meta => $meta });
  $stmt->execute($bind_values);
  my $row = $stmt->fetchrow_hashref();

=head1 DESCRIPTION


