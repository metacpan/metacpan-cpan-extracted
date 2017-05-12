package TAP::DOM::Waivers;
BEGIN {
  $TAP::DOM::Waivers::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Patching TAP::DOM, usually for test waivers
$TAP::DOM::Waivers::VERSION = '0.002';
use 5.008;
use strict;
use warnings;

use Data::Dumper;
use Data::DPath 'dpathr';
use Clone "clone";
use Sub::Exporter -setup => {
                             exports => [ 'waive' ],
                             groups  => { all   => [ 'waive' ] },
                            };

sub waive {
        my ($dom, $waivers, $options) = @_;

        my $new_dom_ref;
        if ($options->{no_clone}) {
                $new_dom_ref = \$dom;
        } else {
                $new_dom_ref = \ (clone($dom));
        }
        foreach my $waiver (@$waivers) {
                # apply on matching dpath
                if (my @paths = @{$waiver->{match_dpath} || []}) {
                        _patch_dom_dpath( $new_dom_ref, $waiver, $_ ) foreach @paths;
                }
                elsif (my @descriptions = @{$waiver->{match_description} || []}) {
                        my @paths = map { _description_to_dpath($_) } @descriptions;
                        _patch_dom_dpath( $new_dom_ref, $waiver, $_ ) foreach @paths;
                }
        }
        return $$new_dom_ref;
}

sub _description_to_dpath {
        my ($description) = @_;

        # the '#' as delimiter is not expected in a description
        # because it has TAP semantics, however, we escape to be sure
        $description =~ s/\#/\\\#/g;

        return "//lines//description[value =~ qr#$description#]/..";
}

sub _meta_patch {
        my ($metapatch) = @_;

        my $patch;
        my $explanation;
        if ($explanation = $metapatch->{TODO}) {
                $patch = {
                          is_ok        => 1,
                          has_todo     => 1,
                          is_actual_ok => 0,
                          directive    => 'TODO',
                          explanation  => $explanation,
                         };
        } elsif ($explanation = $metapatch->{SKIP}) {
                $patch = {
                          is_ok        => 1,
                          has_skip     => 1,
                          is_actual_ok => 0,
                          directive    => 'SKIP',
                          explanation  => $explanation,
                         };
        }
        return $patch;
}

sub _patch_dom_dpath {
        my ($dom_ref, $waiver, $path) = @_;

        my $patch;
        if (exists $waiver->{metapatch}) {
                $patch = _meta_patch($waiver->{metapatch});
        } else {
                $patch = $waiver->{patch};
        }
        my $comment  = $waiver->{comment};
        my @points   = dpathr($path)->match($$dom_ref);
        foreach my $p (@points) {
                $$p->{$_} = $patch->{$_} foreach keys %$patch;
        }
}

1;

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Waivers - Patching TAP::DOM, usually for test waivers

=head1 SYNOPSIS

 use TAP::DOM;
 use TAP::DOM::Waivers 'waiver';
 
 # get TAP
 my $dom = TAP::DOM->new( tap => "somefile.tap" );
 
 # ,--------------------------------------------------------------------.
 # | Define exceptions and how to modify test results.
 # |
 # | (1) Most powerful but most complex way:
 # |     - use DPath matching and finegrained patching
 # |

 $waivers = [
             {
               # a description of what the waiver is trying to achieve
               comment     => "Force all IPv6 stuff to true",
                  
               # a DPath that matches the records to patch:
               match_dpath => [ "//lines//description[value =~ 'IPv6']/.." ],

               # apply changes to the matched records,
               # here a TODO with an explanation:
               patch       => {
                               is_ok        => 1,
                               has_todo     => 1,
                               is_actual_ok => 0,
                               explanation  => 'waiver for context xyz',
                               directive    => 'TODO',
                              },
             },
            ];
 
 # |
 # | (2) Simpler approach: 
 # |
 # |     - instead of the "patch" key above you can use "metapatches" 
 # |       for Common use-cases, like #TODO or #SKIP
 # |

 $waivers = [
             {
               comment     => "Force all IPv6 stuff to true",
               match_dpath => [ "//lines//description[value =~ 'IPv6']/.." ],
               metapatch   => { TODO => 'waiver for context xyz' },
             },
            ];

 # |
 # | (3) Even simpler:
 # |     - also provide the description as regex
 # |

 $waivers = [
             {
               comment           => "Force all IPv6 stuff to true",
               match_description => [ "IPv6" ],
               metapatch         => { TODO => 'waiver for context xyz' },
             },
            ];
 #
 # |
 # `--------------------------------------------------------------------'

 # the actual DOM patching
 my $patched_tap_dom = waiver($dom, $waivers);
 
 # do something with patched DOM
 use Data::Dumper;
 print Dumper($patched_tap_dom);
 
 # the original DOM can also be patched directly without cloning
 waiver($dom, $waivers, { no_clone => 1 });
 print Dumper($dom);
 
 # convert back to TAP from patched DOM
 print $patched_tap_dom->to_tap;
 print $dom->to_tap;

=head1 NAME

TAP::DOM::Waivers - Exceptions (waivers) for TAP::DOM-like data

=head1 ABOUT

=head2 Achieve?

Test I<waivers> are exemptions to actual test results.

This module lets you ignore known issues you don't want to care about,
usually by grouping them for a certain context.

=head2 Example:

A software project might not run with IPv6 enabled but you want to see
a big SUCCESS or NO SUCCESS in an IPv4-only context, without being
disturbed by irrelevant IPv6 tests, for now.

Statically marking the problematic tests with C<#TODO> would require
to change that back and forth everytime. Dynamically marking those
tests depending on the runtime environment does not help when another
engineer actually works on fixing those IPV6 problems in the same
environment.

The solution is to create a I<waiver> which patches the IPv6 issues
away in the results B<after> you actually ran the tests, for later
evaluation.

=head2 Prove plugin

See also L<App::Prove::Plugin::Waivers|App::Prove::Plugin::Waivers>
for a way to utilze this module with B<prove> (not yet working?).

=head1 Waiver specification

=head2 How to match what to patch

This module can patch TAP-DOMs (and similar data structures, see
below) by certain criteria. The primary and most powerful way is via
Data::DPath paths, as it allows to match fuzzily against continuously
changing TAP from evolving test suites.

I use this with a big TAP database where I activate waivers as a layer
on top of TAP::DOM based evaluation. There the TAP-DOMs are just part
of a even bigger data structure, but the DPath matching still applies
there.

=head3 B<match_dpath> => [ @array_of_dpaths ]

This provides a set of dpaths that are each tried to match. The DPaths
should point to a single entry in TAP-DOM - that's why the examples
above go down into an entry to match conditions (like the
description), and then go up one level to point to the whole entry.

=head3 B<match_description> => [ @array_of_regexes ]

This is a high level frontend to I<match_dpath>. The regexes are
internally embedded in dpaths which are then used to match. The
converted internal dpaths will match fuzzy for a typical TAP-DOM
structure, in particular:

 "//lines//description[value =~ qr/$description/]/..";

Please note that this doesn't allow to specify complex conditions like
the combination of a description and a particular test success
(e.g. only the "not ok" tests with a particular description, see
examples in I<t/waivers.t>).

In combination with the also just canonically working I<metapatch>
(see below) it might create a slightly different TAP-DOM than you
expect, e.g. when you match and modify tests as '#TODO' that did not
even fail, but the metapatch marks them as 'not ok #TODO'. So the
original actual success is lost.

It might be still "quite ok" and worth the less complexity but
consider using I<match_dpath> for better control.

=head2 Patch specs

=head3 B<patch> => { %patch_spec }

A hash entry key B<patch> contains single keys that overwrite
respective fields of a TAP-DOM entry.

This allows finegrained control but it's somewhat difficult if you are
not familiar with the details of how a TAP situation looks like in a
TAP-DOM.

Therefore you can describe more abstract use-cases with
I<metapatches>.

=head3 B<metapatch> => { %patch_spec }

A key B<metapatch> declares a common use-case. Inside a metapatch the
key describes the use case (like 'TODO'), and the value is the most
significant thingie (eg. the explanation).

Currently these metapatches are supported:

=over 4

=item * B<TODO> => I<explanation>

=item * B<SKIP> => I<explanation>

=back

When such a metapatch is found it is converted internally into an
equivalent detailed patch, as described above.

=head2 Comments

The key B<comment> is not strictly needed. It will help once there is
some logging.

=head1 Back from DOM to TAP

Usually you regenerate a semantically comparable TAP document from the
DOM via L<TAP::DOM::to_tap|TAP::DOM/to_tap>.

=head1 API

=head2 waive ($dom, $waivers, $options)

This applies a set of waivers to a TAP-DOM.

The C<TAP-DOM> is usually a real L<TAP::DOM|TAP::DOM> but don't have
to. It is explicitely allowed to provide similar data structures,
e.g., bigger structures that only contain TAP-DOMs in sub
structures. It's your responsibility to provide something meaningful.

If you match with C<match_dpath> you have control whether to use the
surrounding data structures to match or not.

If a waiver does not match, nothing happens.

=head1 AUTHOR

Steffen Schwigon, C<< <ss5 at renormalist.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tap-dom-waivers at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-DOM-Waivers>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAP::DOM::Waivers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TAP-DOM-Waivers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAP-DOM-Waivers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAP-DOM-Waivers>

=item * Search CPAN

L<http://search.cpan.org/dist/TAP-DOM-Waivers/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Steffen Schwigon.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# Idea brain dump

# Other match criteria, eg. by line:

#  my $waivers = [
#                 {
#                   match_lines => [ 7, 9, 15 ],
#                   patch       => { ... },
#                 }
#                ];

# By number:

#  my $waivers = [
#                 {
#                   match_numbers => [ 5, 7, 12 ],
#                   patch         => { ... },
#                 }
#                ];

# By descriptions:

#  my $waivers = [
#                 {
#                   match_descriptions => [ 'IPv6' ],
#                   patch              => { ... },
#                 }
#                ];
