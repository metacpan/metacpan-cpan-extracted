package Test::Dependencies;

use warnings;
use strict;

use Carp;
use Module::CoreList;
use Pod::Strip;

use parent 'Test::Builder::Module';

=head1 NAME

Test::Dependencies - Ensure that the dependency listing is complete

=head1 VERSION

Version 0.29

=cut

our $VERSION = '0.29';

=head1 SYNOPSIS

In your t/00-dependencies.t:

    use CPAN::Meta;  # or CPAN::Meta::cpanfile
    use File::Find::Rule::Perl;

    use Test::More;
    use Test::Dependencies '0.28' forward_compatible => 1;

    my $meta = CPAN::Meta->load_file('META.json'); # or META.yml
    plan skip_all => 'No META.json' if ! $meta;

    my @files = File::Find::Rule::Perl->perl_files->in('./lib', './bin');
    ok_dependencies($meta, \@files, [qw/runtime configure build test/],
                    undef, # all features in the cpanfile
                    ignores => [ qw/ Your::Namespace Some::Other::Namespace / ]
    );

    done_testing;

=head1 DESCRIPTION

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.

=head1 OPTIONS

B<DEPRECATED> You can pass options to the module via the 'use' line.
These options will be moved to the ok_dependencies() function.
The available options are:

=over 4

=item forward_compatible

When specified and true, stops the module from outputting a plan, which
is the default mode of operation when the module becomes 1.0.

=item exclude

Specifies the list of namespaces for which it is ok not to have
specified dependencies.

=item style

B<DEPRECATED>

There used to be the option of specifying a style; the heavy style
depended on B::PerlReq. This module stopped working somewhere around
Perl 5.20. Specifying a style no longer has any effect.

=back

=cut

our @EXPORT = qw/ok_dependencies/;

our $exclude_re;

sub import {
  my $package = shift;
  my %args = @_;
  my $callerpack = caller;
  my $tb = __PACKAGE__->builder;
  $tb->exported_to($callerpack);

  unless ($args{forward_compatible}) {
      $tb->no_plan;

      if (defined $args{exclude}) {
          foreach my $namespace (@{$args{exclude}}) {
              croak "$namespace is not a valid namespace"
                  unless $namespace =~ m/^(?:(?:\w+::)|)+\w+$/;
          }
          $exclude_re = join '|', map { "^$_(\$|::)" } @{$args{exclude}};
      }
      else {
          $exclude_re = qr/^$/;
      }
  }

  $package->export_to_level(1, '', qw/ok_dependencies/);
}


sub _get_modules_used_in_file {
    my $file = shift;
    my ($fh, $code);
    my %used;

    local $/;
    open $fh, $file or return undef;
    my $data = <$fh>;
    close $fh;
    my $p = Pod::Strip->new;
    $p->output_string(\$code);
    $p->parse_string_document($data);
    $used{$2}++ while $code =~ /^\s*(use|with|extends)\s+['"]?([\w:]+)['"]?/gm;
    while ($code =~ m{^\s*use\s+base
                          \s+(?:qw.|(?:(?:['"]|q.|qq.)))([\w\s:]+)}gmx) {
        $used{$_}++ for split ' ', $1;
    }

    return [keys %used];
}

sub _get_modules_used {
    my ($files) = @_;
    my @modules;

    foreach my $file (sort @$files) {
        my $ret = _get_modules_used_in_file($file);
        if (! defined $ret) {
            die "Could not determine modules used in '$file'";
        }
        push @modules, @$ret;
    }
    return @modules;
}

sub _legacy_ok_dependencies {
    my ($missing_dep);
    my $tb = __PACKAGE__->builder;
    {
        local $@;

        eval {
            use CPAN::Meta;
        };
        eval {
            use File::Find::Rule::Perl;
        };

        $missing_dep = $@;
    }
    die $missing_dep if $missing_dep;

    my $meta;
    for my $file (qw/ META.json META.yml /) {
        if (-r $file) {
            $tb->ok(1, "$file is present and readable");
            $meta = CPAN::Meta->load_file($file);
            last;
        }
    }

    if (! $meta) {
        $tb->level(2);
        $tb->ok(0, "Missing META.{yml,json} file for dependency checking");
        $tb->diag("Use the non-legacy invocation to provide the info");
        return;
    }

    my @run = File::Find::Rule::Perl->perl_file->in(
        grep { -e $_ } ('./bin', './lib', './t'));

    ok_dependencies($meta, \@run, ignores => [ 'ExtUtils::MakeMaker']);
}


=head1 EXPORTED FUNCTIONS

=head2 ok_dependencies($meta, $files, $phases, $features, %options)

 $meta is a CPAN::Meta object
 $files is an arrayref with files to be scanned

=head3 %options keys

=over

=item phases

This is an arrayref holding one or more names of phases
as defined by L<CPAN::Meta::Spec>, or undef for all

=item features

This is an arrayref holding zero or more names of features, or undef for all

=item ignores

This is a arrayref listing the names of modules (and their sub-namespaces)
for which no errors are to be reported.

=back

=head2 ok_dependencies()

B<Deprecated.> Legacy invocation to be removed. In previous versions,
this function would scan the I<entire> bin/, lib/ and t/ subtrees, with the
exception of a few sub-directories known to be used by version control
systems.

This behaviour has been changed: as of 0.20, Find::File::Rule::Perl
is being used to find Perl files (*.pl, *.pm, *.t and those starting with
a shebang line referring to perl).

=cut

sub ok_dependencies {

    return _legacy_ok_dependencies
        unless @_;

    my ($meta, $files, %options) = @_;
    my $phases = $options{phases};
    my $features = $options{features};
    my $ignores_re = '^(?:' . join('|',
                                   # create regex for sub-namespaces
                                   map { "$_(?:::.*)?" }
                                   @{$options{ignores} // []})
                        . ')$';
    $ignores_re = qr/$ignores_re/;

    $features //= $meta->features;
    $features = [ $features ] unless ref $features;
    $phases //= [ 'runtime', 'configure', 'build', 'test', 'develop' ];
    $phases = [ $phases ] unless ref $phases;

    my $tb = __PACKAGE__->builder;
    my %used = map { $_ => 1 } _get_modules_used($files);

    my @meta_features = map { $_->identifier } $meta->features;
    my $prereqs = $meta->effective_prereqs(\@meta_features);
    my $reqs = [];

    push @$reqs, $prereqs->requirements_for($_, 'requires')
        for (@$phases);

    my $min_perl_ver;
    my $minimum_perl;
    for (map { $_->requirements_for_module('perl') } @$reqs) {
        next if ! defined $_;

        my $ver = version->parse($_)->numify;
        $minimum_perl = (defined $min_perl_ver and $min_perl_ver < $ver)
            ? $minimum_perl : $_;
        $min_perl_ver = (defined $min_perl_ver and $min_perl_ver < $ver)
            ? $min_perl_ver : $ver;
    }
    $minimum_perl //= "v5.0.0";
    $min_perl_ver //= 5.0;

    for my $req (@$reqs) {
        for my $mod (sort $req->required_modules) {
            next if ($mod eq 'perl'
                     or $mod =~ $ignores_re
                     or ($exclude_re and $mod =~ $exclude_re));

            # if the module is/was deprecated from CORE,
            # it makes sense to require it, if the dependency exists
            next if (Module::CoreList->deprecated_in($mod)
                     or Module::CoreList->removed_from($mod));

            my $req_version = $req->requirements_for_module($mod);
            my $first_in = Module::CoreList->first_release($mod, $req_version);
            my $verstr = ($req_version) ? '(' . $req_version . ')' : '';
            my $corestr = version->parse($first_in)->normal;
            $tb->ok($first_in > $min_perl_ver,
                    "Required module '$mod'$verstr "
                    . "in core (since $corestr) after minimum perl "
                    . $minimum_perl )
                if defined $first_in;
        }
    }

    my %required;
    for my $req (@$reqs) {
        $required{$_} = $req->requirements_for_module($_)
            for $req->required_modules;
    }
    delete $required{perl};

    foreach my $mod (sort keys %required) {
        $tb->ok(exists $used{$mod}, "Declared dependency $mod used")
            unless ($mod =~ $ignores_re
                    or ($exclude_re and $mod =~ $exclude_re));
    }

    foreach my $mod (sort keys %used) {
        next if ($mod =~ $ignores_re
                 or ($exclude_re and  $mod =~ $exclude_re));

        my $first_in = Module::CoreList->first_release($mod, $required{$mod});
        my $v;
        if ($v = Module::CoreList->removed_from($mod)) {
            $v = version->parse($v)->normal;
            $tb->ok(exists $required{$mod},
                    "Removed-from-CORE (in $v) module '$mod' "
                    . 'explicitly required');
        }
        elsif ($v = Module::CoreList->deprecated_in($mod)) {
            $v = version->parse($v)->normal;
            $tb->ok(exists $required{$mod},
                    "Deprecated-from-CORE (in $v) module '$mod' explicitly "
                    . 'required to anticipate removal');
        }
        elsif (defined $first_in) {
            $v = version->parse($first_in)->normal;
            $tb->ok($first_in <= $min_perl_ver or exists $required{$mod},
                    "Used CORE module '$mod' in core before "
                    . "Perl $minimum_perl (since $v) "
                    . "or explicitly required");
        }
        else {
            $tb->ok(exists $required{$mod},
                    "Used non-CORE module '$mod' in requirements listing");
        }
    }
}

=head1 AUTHORS

=over 4

=item * Jesse Vincent C<< <jesse at bestpractical.com> >>

=item * Alex Vandiver C<< <alexmv at bestpractical.com> >>

=item * Zev Benjamin C<< <zev at cpan.org> >>

=item * Erik Huelsmann C<< <ehuels at gmail.com> >>

=back

=head1 BUGS

=over 4

=item * Test::Dependencies does not track module version requirements.

=back

Please report your bugs on GitHub:

   L<https://github.com/ehuelsmann/perl-Test-Dependencies/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Dependencies

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Dependencies>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Dependencies>

=back

=head1 LICENCE AND COPYRIGHT

    Copyright (c) 2016-2020, Erik Huelsmann. All rights reserved.
    Copyright (c) 2007, Best Practical Solutions, LLC. All rights reserved.

    This module is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. See perlartistic.

    DISCLAIMER OF WARRANTY

    BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
    FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
    OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
    PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
    EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
    ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
    YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
    NECESSARY SERVICING, REPAIR, OR CORRECTION.

    IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
    WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
    REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
    TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
    SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
    RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
    FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
    SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
    DAMAGES.

=cut

1;
