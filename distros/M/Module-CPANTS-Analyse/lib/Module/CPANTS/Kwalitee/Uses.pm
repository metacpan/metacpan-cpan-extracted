package Module::CPANTS::Kwalitee::Uses;
use warnings;
use strict;
use File::Spec::Functions qw(catfile);
use Module::ExtractUse 0.33;
use Set::Scalar qw();
use version;

our $VERSION = '0.96';
$VERSION = eval $VERSION; ## no critic

# These equivalents should be reasonably well-known and, preferably,
# well-documented. Don't add obscure modules used by only one person
# or a few people, to keep the list relatively small and to encourage
# people to use a better equivalent.
# "use_(strict|warnings)" should fail if someone feels the need
# to add "use $1;" in the modules.
our @STRICT_EQUIV = qw( strict );
our @WARNINGS_EQUIV = qw( warnings warnings::compat );
our @STRICT_WARNINGS_EQUIV = qw(
  common::sense
  Any::Moose
  Catmandu::Sane Coat
  Dancer
  Mo
  Modern::Perl
  Moo Moo::Role
  Moose Moose::Role Moose::Exporter
  MooseX::Declare MooseX::Role::Parameterized MooseX::Types
  Mouse Mouse::Role
  perl5 perl5i::1 perl5i::2 perl5i::latest
  Role::Tiny
  strictures
);
# These modules require a flag to enforce strictness.
push @STRICT_WARNINGS_EQUIV, qw(
  Mojo::Base
  Spiffy
);

sub order { 100 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $me=shift;
    
    my $distdir=$me->distdir;
    my $modules=$me->d->{modules};
    my $files=$me->d->{files_hash};

    # NOTE: all files in xt/ should be ignored because they are
    # for authors only and their dependencies may not be (and
    # often are not) listed in meta files.
    my @tests=grep {m|^t\b.*\.t|} sort keys %$files;
    $me->d->{test_files} = \@tests;

    my @test_modules = map {
        my $m = $_;
        $m =~ s|\.pm$||;
        $m =~ s|^t/(?:lib/)?||;
        $m =~ s|/|::|g;
        $m;
    } grep {m|^t\b.*\.pm$|} keys %$files;
    my %test_modules = map {$_ => 1} @test_modules;

    my %skip=map {$_->{module}=>1 } @$modules;
    my %uses;

    # used in modules
    foreach my $module (@$modules) {
        my $combined = $class->_extract_use($me, $module->{file});
        for my $key (keys %$combined) {
            for my $mod (keys %{$combined->{$key}}) {
                next if $skip{$mod};
                $uses{$key.'_in_code'}{$mod} += $combined->{$key}{$mod};
            }
        }
    }
    
    # used in tests
    foreach my $tf (@tests) {
        my $combined = $class->_extract_use($me, $tf);
        for my $key (keys %$combined) {
            for my $mod (keys %{$combined->{$key}}) {
                next if $mod =~ /^t::/;
                next if $skip{$mod};
                next if $test_modules{$mod};
                $uses{$key.'_in_tests'}{$mod} += $combined->{$key}{$mod};
            }
        }
    }

    # used in Makefile.PL/Build.PL
    foreach my $f (grep /\b(?:Makefile|Build)\.PL$/, @{$me->d->{files_array} || []}) {
        my $combined = $class->_extract_use($me, $f);
        for my $key (keys %$combined) {
            for my $mod (keys %{$combined->{$key}}) {
                next if $skip{$mod};
                $uses{$key.'_in_config'}{$mod} += $combined->{$key}{$mod};
            }
        }
    }

    $me->d->{uses}=\%uses;
    return;
}

sub _extract_use {
    my ($class, $me, $path) = @_;
    my $file = catfile($me->distdir, $path);
    $file =~ s|\\|/|g;
    return unless -f $file;

    my $p = Module::ExtractUse->new;
    $p->extract_use($file);

    # used actually contains required/noed
    my %used = %{ $p->used || {} };
    my %required = %{ $p->required || {} };
    my %noed = %{ $p->noed || {} };

    my %combined;
    for my $mod (keys %used) {
        next if $mod =~ /::$/; # see RT#35092
        next unless $mod =~ /^(?:v?5\.[0-9.]+|[A-za-z0-9:_]+)$/;
        $combined{used}{$mod} += $used{$mod};
        if (my $used_in_eval = $p->used_in_eval($mod)) {
            $combined{used_in_eval}{$mod} += $used_in_eval;
            $combined{used}{$mod} -= $used_in_eval;
        }
        if ($required{$mod}) {
            $combined{used}{$mod} -= $required{$mod};
            $combined{required}{$mod} += $required{$mod};
            if (my $required_in_eval = $p->required_in_eval($mod)) {
                $combined{used}{$mod} += $required_in_eval;
                $combined{used_in_eval}{$mod} -= $required_in_eval;
                $combined{required}{$mod} -= $required_in_eval;
                $combined{required_in_eval}{$mod} += $required_in_eval;
            }
        }
        if ($noed{$mod}) {
            $combined{used}{$mod} -= $noed{$mod};
            $combined{noed}{$mod} += $noed{$mod};
            if (my $noed_in_eval = $p->noed_in_eval($mod)) {
                $combined{used}{$mod} += $noed_in_eval;
                $combined{used_in_eval}{$mod} -= $noed_in_eval;
                $combined{noed}{$mod} -= $noed_in_eval;
                $combined{noed_in_eval}{$mod} += $noed_in_eval;
            }
        }
        for (qw/used used_in_eval required noed/) {
            delete $combined{$_}{$mod} unless $combined{$_}{$mod};
        }
    }

    for my $key (keys %combined) {
        next unless %{$combined{$key}};
        $me->d->{files_hash}{$path}{$key} = [sort keys %{$combined{$key}}];
    }
    return \%combined;
}

##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
    return [
        {
            name=>'use_strict',
            error=>q{This distribution does not 'use strict;' (or its equivalents) in all of its modules. Note that this is not about the actual strictness of the modules. It's bad if nobody can tell whether the modules are strictly written or not, without reading the source code of your favorite clever module that actually enforces strictness. In other words, it's bad if someone feels the need to add 'use strict' to your modules.},
            remedy=>q{Add 'use strict' (or its equivalents) to all modules, or convince us that your favorite module is well-known enough and people can easily see the modules are strictly written.},
            ignorable => 1,
            code=>sub {
                my $d       = shift;
                my $files = $d->{files_hash} || {};

                # There are lots of acceptable strict alternatives
                my $strict_equivalents = Set::Scalar->new->insert(@STRICT_EQUIV, @STRICT_WARNINGS_EQUIV);

                my $perl_version_with_implicit_stricture = version->new('5.011')->numify;
                my @no_strict;

                for my $file (keys %$files) {
                    next unless exists $files->{$file}{module};
                    next if $files->{$file}{unreadable};
                    next if $file =~ /\.pod$/;
                    my $module = $files->{$file}{module};
                    my %used;
                    for my $key (qw/used required/) {
                        next unless exists $files->{$file}{$key};
                        $used{$_} = 1 for @{$files->{$file}{$key} || []};
                    }
                    next if grep {/^v?5\./ && version->parse($_)->numify >= $perl_version_with_implicit_stricture} keys %used;

                    push @no_strict, $module if $strict_equivalents
                        ->intersection(Set::Scalar->new(keys %used))
                        ->is_empty;
                }
                if (@no_strict) {
                    $d->{error}{use_strict} = join ", ", @no_strict;
                    return 0;
                }
                return 1;
            },
            details=>sub {
                my $d = shift;
                return "The following modules don't use strict (or equivalents): " . $d->{error}{use_strict};
            },
        },
        {
            name=>'use_warnings',
            error=>q{This distribution does not 'use warnings;' (or its equivalents) in all of its modules. Note that this is not about that your modules actually warn when something bad happens. It's bad if nobody can tell if a module warns or not, without reading the source code of your favorite module that actually enforces warnings. In other words, it's bad if someone feels the need to add 'use warnings' to your modules.},
            is_extra=>1,
            ignorable => 1,
            remedy=>q{Add 'use warnings' (or its equivalents) to all modules (this will require perl > 5.6), or convince us that your favorite module is well-known enough and people can easily see the modules warn when something bad happens.},
            code=>sub {
                my $d = shift;
                my $files = $d->{files_hash} || {};

                my $warnings_equivalents = Set::Scalar->new->insert(@WARNINGS_EQUIV, @STRICT_WARNINGS_EQUIV);

                my @no_warnings;
                for my $file (keys %$files) {
                    next unless exists $files->{$file}{module};
                    next if $files->{$file}{unreadable};
                    next if $file =~ /\.pod$/;
                    my $module = $files->{$file}{module};
                    my %used;
                    for my $key (qw/used required/) {
                        next unless exists $files->{$file}{$key};
                        $used{$_} = 1 for @{$files->{$file}{$key} || []};
                    }
                    push @no_warnings, $module if $warnings_equivalents
                        ->intersection(Set::Scalar->new(keys %used))
                        ->is_empty;
                }
                if (@no_warnings) {
                    $d->{error}{use_warnings} = join ", ", @no_warnings;
                    return 0;
                }
                return 1;
            },
            details=>sub {
                my $d = shift;
                return "The following modules don't use warnings (or equivalents): " . $d->{error}{use_warnings};
            },
        },
    ];
}


q{Favourite record of the moment:
  Fat Freddys Drop: Based on a true story};

__END__

=encoding UTF-8

=head1 NAME

Module::CPANTS::Kwalitee::Uses - Checks which modules are used

=head1 SYNOPSIS

Check which modules are actually used in the code.

=head1 DESCRIPTION

=head2 Methods

=head3 order

Defines the order in which Kwalitee tests should be run.

Returns C<100>.

=head3 analyse

C<MCK::Uses> uses C<Module::ExtractUse> to find all C<use> statements in code (actual code and tests).

=head3 kwalitee_indicators

Returns the Kwalitee Indicators datastructure.

=over

=item * use_strict

=item * use_warnings

=back

=head1 SEE ALSO

L<Module::CPANTS::Analyse>

=head1 AUTHOR

L<Thomas Klausner|https://metacpan.org/author/domm>

=head1 COPYRIGHT AND LICENSE

Copyright © 2003–2006, 2009 L<Thomas Klausner|https://metacpan.org/author/domm>

You may use and distribute this module according to the same terms
that Perl is distributed under.
