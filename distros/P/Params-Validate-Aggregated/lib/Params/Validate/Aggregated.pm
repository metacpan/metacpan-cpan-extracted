# --8<--8<--8<--8<--
#
# Copyright (C) 2011 Smithsonian Astrophysical Observatory
#
# This file is part of Params::Validate::Aggregated
#
# Params::Validate::Aggregated is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version
# 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Params::Validate::Aggregated;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw[ pv_disagg ];
our @EXPORT_TAGS = ( all => \@EXPORT_OK );

use Params::Validate qw[ :all ];
use Data::Alias;

use Carp;

## no critic (ProhibitAccessOfPrivateData)

our $VERSION = '0.05';

sub DESTROY {}

our $AUTOLOAD;
sub AUTOLOAD {

    (my $set = $AUTOLOAD)  =~ s/.*:://;

    my $self = shift;

    croak( "unknown specification set: $set\n" )
      unless defined $self->{$set};

    return wantarray ? %{ $self->{$set} } : $self->{$set};
}

sub pv_disagg {

    my %args = validate_with( params => \@_,
                              spec => {
                                       params => { type => ARRAYREF,
                                                   optional => 0,
                                                 },
                                       spec   => { type => HASHREF,
                                                   default => {},
                                                 },
                                       with   => { type => HASHREF,
                                                   default => {},
                                                 },
                                       normalize_keys => { type => CODEREF,
                                                           optional => 1,
                                                         },
                                       allow_extra => { type => SCALAR,
                                                        optional => 1,
                                                      },
                                      },
                              allow_extra => 1
                            );

    alias my (%upar) = @{$args{params}};

    # remove the known named parameters.  the extra ones are passed
    # on to Params::Validate;
    my ( $params, $spec, $with ) = delete @args{ qw[ params spec with ] };

    # transform the "spec" parameter specifications to "with" parameter
    # specifications, adding the extra parameters
    my %with = %{$with};
    $with{$_} = { spec => $spec->{$_}, %args } for keys %$spec;

    # keep track of which input parameters were used
    my @params = keys %upar;
    my %nparams = map { $_ => $_ } @params;
    my %used   = map { $_ => 0 } @params;

    # the lists of parameter for each input spec
    my %oargs;

    # whether any input spec had the allow_extra flag set.
    my $allow_extra = 0;

    # memoize normalize_keys functions & results for the input
    # parameter set.
    my %norm;

    # for each input Params::Validate::validate_with argument list,
    #  1) track which parameters in the input parameter set are used
    #  2) create a parameter set containing only those parameters of interest

    while ( my ( $fid, $wspec ) = each %with )
    {
        my %fargs;

        my $normf = exists $wspec->{normalize_keys}
                    ? $wspec->{normalize_keys}
                    : undef;

        # normalize input parameter set keys
        my $npars;
        if ( defined $normf )
        {
            if (exists $norm{$normf} )
            {
                $npars = $norm{$normf};
            }
            else
            {
                $npars = { map { $normf->($_) => $_ } @params };
                $norm{$normf} = $npars;
            }
        }
        else
        {
            $npars = \%nparams;
        }

        my $specs = $wspec->{spec} or croak( "no specs for set $fid\n" );

        # if allow_extra is set, the entire input parameter set is legit
        if ( exists $wspec->{allow_extra} && $wspec->{allow_extra} )
        {
            $allow_extra++;

            alias +(%fargs) = (%upar);
            while ( my ( $par, $spec ) = each %$specs )
            {
                my $npar = $normf ? $normf->($par) : $par;
                $used{$npars->{$npar}}++ if exists $npars->{$npar};
            }
        }
        else
        {
            while ( my ( $par, $spec ) = each %$specs )
            {
                my $npar = $normf ? $normf->($par) : $par;
                if ( exists $npars->{$npar} )
                {
                    my $ppar = $npars->{$npar};
                    $used{$ppar}++ ;
                    alias $fargs{$ppar} = $upar{$ppar};
                }
            }
        }

        $oargs{$fid} = \%fargs;
    }

    return \%oargs, {} if $allow_extra;

    delete @upar{ grep { $used{$_} } keys %used };

    return bless(\%oargs, __PACKAGE__), \%upar;
}

1;


__END__

=head1 NAME

Params::Validate::Aggregated - separate aggregated parameters for functions


=head1 SYNOPSIS

  use Params::Validate qw[ :all ];
  use Params::Validate::Aggregated qw[ pv_disagg ];

  my %spec;

  $spec{func1} = { foo => { type => ARRAYREF },
                   bar => { type => SCALAR } };
  sub func1 { my %args = validate( @_, $spec{func1}  };

  $spec{func2} = { goo => { type => ARRAYREF, optional => 1 },
                   loo => { type => SCALAR } };
  sub func2 { my %args = validate( @_, $spec{func2}  };

  $spec{func} = { snack => 1, bar => 1 };
  sub func {

      my ( $agg, $xtra ) = pv_disagg( params => \@_, spec => \%spec);
      die( "extra arguments passed to func\n" ) if %$xtra;

      # the @{[]} ugliness is because validate is prototyped to require
      # an array as the first argument.
      my %aggs = validate(@{[$aggs->func]}, $spec{func} );

      func1( $agg->func1 );
      func2( $agg->func2 );
  }
  func( foo => 'f', bar => 'b', snack => 's', goo => 'g', loo => 'l' );


=head1 DESCRIPTION

When a function passes named parameters through to other functions, it can
be tedious work to separate out parameters specific to each function.

B<Params::Validate::Aggregated::pv_disagg> simplifies this, separating
out parameter sets from an input list of parameters, using
B<Params::Validate> named parameter specifications to identify the
sets. It takes into account any key normalization routines, and uses
L<Data::Alias> to ensure that there is no duplication of the input
data.  It can also handle the more complex situations were
B<validate_with> is used.

=head1 INTERFACE

=over

=item pv_disagg

   ( $agg, $xtra ) = pv_disagg( params => \@params,
                                spec   => \%specs,
                                with   => \%with,
                                \%opts );

Separate aggregated parameters into sets based upon
B<Params::Validate> specifications for named parameters.

The input parameters are passed in C<@params>, which has the same
structure as the parameter list passed to
C<Params::Validate::validate()> and
C<Params::Validate::validate_with()>.

The sets of L<Params::Validate> specifications are passed via C<%spec>
and C<%with>, whose keys are used to label the output parameter
sets. C<%spec>'s values are hashes as would be passed to
B<Params::Validate::validate()>; C<%with>'s values are those that
would be passed to B<Params::Validate::validate_with()>.  Internally
the sets specified with C<%spec> are merged with those specified by
C<%with>.  The C<%opts> parameter may contain L<Params::Validate>
options which will be added to the specification sets passed in
C<%spec>.

An output hash is created for each specification set and contains only
the input parameters specific to the set. Parameter names are
normalized before being compared if specifications use
C<normalize_keys>. The keys used in the output hash are the original
keys in the input list.

The output hashes are returned in C<$agg>, which is a hash keyed off of the
set names.  The parameter values are aliased (via L<Data::Alias>) to
the values in C<@params> to avoid copying.

If the C<allow_extra> option was not true for any of the specification
sets, then any input parameters in C<@params> which did I<not> appear
in a specification set are returned in the C<$xtra> hash.  If
C<allow_extra> was true for any of the sets, then C<$xtra> will be
empty.

C<$agg> is blessed into the B<Params::Validate::Aggregated> class and
provides accessors for each set.  When called in a list context,
the accessors return the hash directly; when called in scalar context
they return a hash reference:

    %hash = $agg->func1;
    $hashref = $agg->func2;

=back

=head1 DIAGNOSTICS

=over

=item C<< no specs for set %s >>

There were no specifications provided for the named set.

=back


=head1 CONFIGURATION AND ENVIRONMENT

L<Params::Validate::Aggregated> requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Params::Validate>, L<Data::Alias>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-params-validate-aggregate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Aggregated>.

=head1 SEE ALSO

=for author to fill in:
    Any other resources (e.g., modules or files) that are related.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 The Smithsonian Astrophysical Observatory

L<Params::Validate::Aggregated> is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>
