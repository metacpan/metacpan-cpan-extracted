
use strict;
use warnings;

our $VERSION = v1.0.0;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

local $\ = "\n";

######################################################################

use Getopt::Long;
use Pod::Usage;

use SQL::Admin;

######################################################################

my %action_map = (
    dump    => \&action_dump,
    compare => \&action_compare,
);

######################################################################

main ();

sub main {                               # ;
    my $action = shift @ARGV;
    my $factory = SQL::Admin->new;

    my $key_alias = {
        source      => [qw[ src s ]],
        destination => [qw[ dst dest d ]],
        output      => [qw[ out o ]],
    };

    Getopt::Long::Configure ('pass_through');
    GetOptions (
        my $params = {},

        'source|src|s=s',
        'destination|dest|dst|d=s',
        'output|out|o=s',
        'schema_only|schema-only|schema=s@',
    );

    my @def = ();
    for my $key (grep $params->{$_}, keys %$key_alias) {
        for my $option ($factory->get_driver ($params->{$key})->options) {
            my ($names, $def) = split /(?=[=])/, $option, 2;

            my @names;
            for my $name (split /\|/, $names) {
                for my $alias ($key, @{ $key_alias->{$key} }) {
                    push @names, map $alias . $_ . $name, '_', '-', '';
                }
            }
            push @def, join ('|', @names) . $def;
        }
    }

    Getopt::Long::Configure ('nopass_through');
    GetOptions ($params, @def) || pod2usage;

    $action_map{$action}->($factory, $params)
      if exists $action_map{$action};
}


######################################################################
######################################################################
sub _extract_params {                    # ;
    my ($type, $params) = @_;
    my $retval = {};
    my $regex = qr/^ $type (?: _ (.*?) )? $/x;

    while (my ($key, $value) = each %$params) {
        $retval->{$1 || $key} = $value
          if $key =~ $regex;
    }

    $retval;
}


######################################################################
######################################################################
sub action_dump {                        # ;
    my ($factory, $params) = @_;

    my $source = _extract_params (source => $params);
    my $output = _extract_params (output => $params);

    $factory
      ->get_catalog
      ->load (
          $factory->get_driver (delete $source->{source}, %$source),
          (map { split /\s*,\s*/ } @{ $params->{schema_only} || [] }),
      )
      ->save (
          $factory->get_driver (delete $output->{output}, %$output),
      )
    ;
}


######################################################################
######################################################################
sub action_compare {                     # ;
    my ($factory, $params) = @_;

    my $source      = _extract_params (source => $params);
    my $destination = _extract_params (destination => $params);
    my $output      = _extract_params (output => $params);

    ##################################################################

    my $cat_source = $factory->get_catalog;
    $cat_source->load (
        $factory->get_driver (delete $source->{source}, %$source),
        (map { split /\s*,\s*/ } @{ $params->{schema_only} || [] }),
    );

    my $cat_destination = $factory->get_catalog;
    $cat_destination->load (
        $factory->get_driver (delete $destination->{destination}, %$destination),
        (map { split /\s*,\s*/ } @{ $params->{schema_only} || [] }),
    );

    my $diff = $factory->get_catalog_diff;
    $diff->compare ($cat_source, $cat_destination);

    $diff->is_difference
      ? $diff->save ($factory->get_driver (delete $output->{output}, %$output))
      : print "Schema is up-to-date"
      ;

    ##################################################################

    $diff->is_difference;
}


######################################################################
######################################################################

__END__

=pod

=head1 NAME

sql-admin.pl

=head1 SYNOPSIS

   sql-admin <action> --source <source driver> <source driver parameters>
                      --destination <destination driver> <destination driver parameters>
                      --output <output driver> <output driver parameters>
