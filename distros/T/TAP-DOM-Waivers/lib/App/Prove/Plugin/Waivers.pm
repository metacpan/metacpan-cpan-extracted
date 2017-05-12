package App::Prove::Plugin::Waivers;
BEGIN {
  $App::Prove::Plugin::Waivers::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: (incomplete) 'prove' plugin support for TAP::DOM::Waivers
$App::Prove::Plugin::Waivers::VERSION = '0.002';
use strict;
use warnings;

use YAML::Any;
use TAP::DOM;
use TAP::DOM::Waivers 'waive';

use Data::Dumper;
use Test::More;

# sub _slurp {
#         my ($filename) = @_;

#         local $/;
#         open (my $F, "<", $filename) or die "Cannot read $filename";
#         return <$F>;
# }

sub load {
    my ($class, $p) = @_;
    my @args = @{ $p->{args} };
    my $app  = $p->{app_prove};

    diag "******************** Waivers.load() ********************";
    diag "******************** formatter: ". ($app->formatter || 'NONE');

    #diag Dumper($p);
    
    # parse the args
    my %TFW_args;
    foreach my $arg (@args) {
        my ($key, $val) = split(/:/, $arg, 2);
        if (grep {$key eq $_} qw(FOO BAR)) { # allow repeated keys: FOO -> FOOs, BAR -> BARs
            push @{ $TFW_args{$key . 's'}}, $val;
        } else {
            $TFW_args{$key} = $val;
        }
    }

    while (my ($key, $val) = each %TFW_args) {
        $val = join( ':', @$val ) if (ref($val) eq 'ARRAY');
        $ENV{"TAP_FORMATTER_WAIVERS_".uc($key)} = $val;
    }

    #WEITER: das hier in Session rein;
    # my $waiverfile     = $TFW_args{waiver};
    # my $tapfile        = "t/failed_IPv6.tap";
    # my $waivers        = YAML::Any::Load(_slurp($waiverfile));
    # my $tapdom         = TAP::DOM->new(tap => _slurp($tapfile));
    # my $patched_tapdom = waive($tapdom, $waivers);

    # set the formatter to use
    $app->formatter( 'TAP::DOM::Waivers::Formatter' );

    # diag ",---------------------------------------------------------.";
    # diag "PATCHED TAP-DOM:";
    # diag "";
    # diag $patched_tapdom->to_tap;
    # diag "`---------------------------------------------------------'";

    # we're done
    return $class;
}

# development on plugin:
#   perl -Ilib `which prove` -Ilib -vl -e cat -P Waivers=waiver:t/metawaiverdesc.yml t/failed_IPv6.tap
# normally activate plugin:
#                     prove  -Ilib -vl -e cat -P Waivers=waiver:t/metawaiverdesc.yml t/failed_IPv6.tap

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::Waivers - (incomplete) 'prove' plugin support for TAP::DOM::Waivers

=head1 SYNOPSIS

Command-line usage:

 # generally
 prove -P Waivers=waiverspec.yml [...]

 # example
 prove -e cat -P Waivers=waiver.yml t/failed_IPv6.tap

=head1 DESCRIPTION

This plugin allows modifying TAP via
L<TAP::DOM::Waivers|TAP::DOM::Waivers>. Read there for the motivation.

It loads a spec (I<waiver>) file, loads the original TAP, converts it
into an intermediate TAP-DOM, applies the waivers to that TAP-DOM,
converts the patched TAP-DOM back to TAP and provides that to the
TAP::Parser instead of the original TAP.

=head2 Example waiver config

A C<waiver.yml> contains a specification like this:

  ---
  - comment: Force all failed IPv6 stuff to true
    match_dpath:
      - "//lines//description[value =~ /IPv6/]/../is_ok[value eq 0]/.."
    patch:
      is_ok:        1
      has_todo:     1
      is_actual_ok: 0
      explanation:  ignore failing IPv6 related tests
      directive:    TODO

This specifies to modify (patch) every B<not ok> tests where the
description matches the regex C</IPv6/>. They are fixed by declaring
them to be a I<#TODO> test with the explanation.

See L<TAP::DOM::Waivers|TAP::DOM::Waivers> for description of the
backend behind this prove plugin.

See L<TAP::DOM|TAP::DOM> for description of the TAP-DOM data structure
that is modified.

See L<Data::DPath|Data::DPath> for description of the xpath-like query
language used to find the tests. It provides the power for fuzzy
tracking of tests in ever changing test suites.

=head2 Waiver specification

A waiver file is a YAML representation of a waiver spec as described
in L<TAP::DOM::Waivers|TAP::DOM::Waivers>. Please read there for the
data structure and adapt it into YAML as shown in the SYNOPSIS.

=head2 METHODS

=head3 load

=head1 ACKNOWLEDGEMENTS

The prove plugin code is shamelessly stolen from Steve Purkis'
L<App::Prove::Plugin::HTML|App::Prove::Plugin::HTML>.

=head1 SEE ALSO

L<prove>, L<App::Prove>

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
