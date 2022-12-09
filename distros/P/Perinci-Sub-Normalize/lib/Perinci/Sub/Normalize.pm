package Perinci::Sub::Normalize;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-09'; # DATE
our $DIST = 'Perinci-Sub-Normalize'; # DIST
our $VERSION = '0.204'; # VERSION

our @EXPORT_OK = qw(
                       normalize_function_metadata
               );

sub _check {
    my $meta = shift; # must be normalized

  CHECK_ARGS: {
        my $argspecs = $meta->{args};
      CHECK_ARGS_POS: {
            my @pos;
            my $slurpy_pos;
            for my $argname (keys %$argspecs) {
                my $argspec = $argspecs->{$argname};
                if (defined $argspec->{pos}) {
                    return "Argument $argname: Negative pos" if $argspec->{pos} < 0;
                    return "Duplicate position $argspec->{pos}" if defined $pos[ $argspec->{pos} ];
                    $pos[ $argspec->{pos} ] = $argname;
                }
                if ($argspec->{slurpy} || $argspec->{greedy}) { # greedy is deprecated, but we should keep observing to make us properly strict
                    return "Argument $argname: slurpy=1 without setting pos"
                        unless defined $argspec->{pos};
                    return "Multiple args with slurpy=1" if defined $slurpy_pos;
                }
            }
            if (defined $slurpy_pos && $slurpy_pos < @pos) {
                return "Clash of argument positions: slurpy=1 defined for pos >= $slurpy_pos but there is another argument with pos > $slurpy_pos";
            }
            # we have holes
            return "There needs to be more arguments that define pos"
                if grep { !defined } @pos;
            if ($meta->{args_as} && $meta->{args_as} =~ /\Aarray(ref)?\z/) {
                return "Function accepts array/arrayref but there are arguments with no pos defined"
                    if scalar(keys %$argspecs) > @pos;
            }
        }
    }

    undef;
}

sub _normalize {
    my ($meta, $ver, $opts, $proplist, $nmeta, $prefix, $modprefix) = @_;

    my $opt_aup = $opts->{allow_unknown_properties};
    my $opt_nss = $opts->{normalize_sah_schemas};
    my $opt_rip = $opts->{remove_internal_properties};

    if (defined $ver) {
        defined($meta->{v}) && $meta->{v} eq $ver
            or die "$prefix: Metadata version must be $ver";
    }

  KEY:
    for my $k (keys %$meta) {
        die "Invalid prop/attr syntax '$k', must be word/dotted-word only"
            unless $k =~ /\A(\w+)(?:\.(\w+(?:\.\w+)*))?(?:\((\w+)\))?\z/;

        my ($prop, $attr);
        if (defined $3) {
            $prop = $1;
            $attr = defined($2) ? "$2.alt.lang.$3" : "alt.lang.$3";
        } else {
            $prop = $1;
            $attr = $2;
        }

        my $nk = "$prop" . (defined($attr) ? ".$attr" : "");

        # strip property/attr started with _
        if ($prop =~ /\A_/ || defined($attr) && $attr =~ /\A_|\._/) {
            unless ($opt_rip) {
                $nmeta->{$nk} = $meta->{$k};
            }
            next KEY;
        }

        my $prop_proplist = $proplist->{$prop};

        # try to load module that declare new props first
        if (!$opt_aup && !$prop_proplist) {
            $modprefix //= $prefix;
            my $mod = "Perinci/Sub/Property$modprefix/$prop.pm";
            eval { require $mod };
            # hide technical error message from require()
            if ($@) {
                die "Unknown property '$prefix/$prop' (and couldn't ".
                    "load property module '$mod'): $@" if $@;
            }
            $prop_proplist = $proplist->{$prop};
        }
        die "Unknown property '$prefix/$prop'"
            unless $opt_aup || $prop_proplist;

        if ($prop_proplist && $prop_proplist->{_prop}) {
            die "Property '$prefix/$prop' must be a hash"
                unless ref($meta->{$k}) eq 'HASH';
            $nmeta->{$nk} = {};
            _normalize(
                $meta->{$k},
                $prop_proplist->{_ver},
                $opts,
                $prop_proplist->{_prop},
                $nmeta->{$nk},
                "$prefix/$prop",
            );
        } elsif ($prop_proplist && $prop_proplist->{_elem_prop}) {
            die "Property '$prefix/$prop' must be an array"
                unless ref($meta->{$k}) eq 'ARRAY';
            $nmeta->{$nk} = [];
            my $i = 0;
            for (@{ $meta->{$k} }) {
                my $href = {};
                if (ref($_) eq 'HASH') {
                    _normalize(
                        $_,
                        $prop_proplist->{_ver},
                        $opts,
                        $prop_proplist->{_elem_prop},
                        $href,
                        "$prefix/$prop/$i",
                    );
                    push @{ $nmeta->{$nk} }, $href;
                } else {
                    push @{ $nmeta->{$nk} }, $_;
                }
                $i++;
            }
        } elsif ($prop_proplist && $prop_proplist->{_value_prop}) {
            die "Property '$prefix/$prop' must be a hash"
                unless ref($meta->{$k}) eq 'HASH';
            $nmeta->{$nk} = {};
            for (keys %{ $meta->{$k} }) {
                $nmeta->{$nk}{$_} = {};
                die "Property '$prefix/$prop/$_' must be a hash"
                    unless ref($meta->{$k}{$_}) eq 'HASH';
                _normalize(
                    $meta->{$k}{$_},
                    $prop_proplist->{_ver},
                    $opts,
                    $prop_proplist->{_value_prop},
                    $nmeta->{$nk}{$_},
                    "$prefix/$prop/$_",
                    ($prop eq 'args' ? "$prefix/arg" : undef),
                );
            }
        } else {
            if ($k eq 'schema' && $opt_nss) { # XXX currently hardcoded
                require Data::Sah::Normalize;
                $nmeta->{$nk} = Data::Sah::Normalize::normalize_schema(
                    $meta->{$k});
            } else {
                $nmeta->{$nk} = $meta->{$k};
            }
        }
    } # for each key
    $nmeta;
}

sub normalize_function_metadata($;$) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my ($meta, $opts) = @_;

    $opts //= {};

    $opts->{allow_unknown_properties}    //= 0;
    $opts->{normalize_sah_schemas}       //= 1;
    $opts->{remove_internal_properties}  //= 0;

    require Sah::Schema::rinci::function_meta;
    my $sch = $Sah::Schema::rinci::function_meta::schema;
    my $sch_proplist = $sch->[1]{_prop}
        or die "BUG: Rinci schema structure changed (1a)";

    my $nmeta = _normalize($meta, 1.1, $opts, $sch_proplist, {}, '');

    my $err = _check($meta);
    die $err if $err;

    $nmeta;
}

1;
# ABSTRACT: Normalize Rinci function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Normalize - Normalize Rinci function metadata

=head1 VERSION

This document describes version 0.204 of Perinci::Sub::Normalize (from Perl distribution Perinci-Sub-Normalize), released on 2022-12-09.

=head1 SYNOPSIS

 use Perinci::Sub::Normalize qw(normalize_function_metadata);

 my $nmeta = normalize_function_metadata($meta);

=head1 FUNCTIONS

=head2 normalize_function_metadata($meta[ , \%opts ]) => HASH

Normalize and check L<Rinci> function metadata C<$meta>. Return normalized
metadata, which is a shallow copy of C<$meta>. Die on error.

Available options:

=over

=item * allow_unknown_properties => BOOL (default: 0)

If set to true, will die if there are unknown properties.

=item * normalize_sah_schemas => BOOL (default: 1)

By default, L<Sah> schemas e.g. in C<result/schema> or C<args/*/schema> property
is normalized using L<Data::Sah>'s C<normalize_schema>. Set this to 0 if you
don't want this.

=item * remove_internal_properties => BOOL (default: 0)

If set to 1, all properties and attributes starting with underscore (C<_>) with
will be stripped. According to L<DefHash> specification, they are ignored and
usually contain notes/comments/extra information.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Normalize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Normalize>.

=head1 SEE ALSO

L<Rinci::function>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Normalize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
