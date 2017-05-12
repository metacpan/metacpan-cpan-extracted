package Module::Build::Bundle;

use 5.008;    #$^V
use strict;
use warnings;
use Carp qw(croak);
use Cwd qw(getcwd);
use Tie::IxHash;
use English qw( -no_match_vars );
use File::Slurp;    #read_file
use base qw(Module::Build::Base);
use utf8;

use constant EXTENDED_POD_LINK_VERSION => 5.12.0;

our $VERSION = '0.17';

#HACK: we need a writable copy for testing purposes
## no critic qw(Variables::ProhibitPackageVars Variables::ProhibitPunctuationVars)
our $myPERL_VERSION = $^V;

sub ACTION_build {
    my $self = shift;

    if ( !$self->{'_completed_actions'}{'contents'} ) {
        $self->ACTION_contents();
    }

    return Module::Build::Base::ACTION_build($self);
}

sub ACTION_contents {
    my $self = shift;

    #Fetching requirements from Build.PL
    my @list = %{ $self->requires() };

    my $section_header = $self->notes('section_header') || 'CONTENTS';

    my $sorted = 'Tie::IxHash'->new(@list);
    $sorted->SortByKey();

    my $pod = "=head1 $section_header\n\n=over\n\n";
    foreach ( $sorted->Keys ) {
        my ( $module, $version ) = $sorted->Shift();

        my $dist = $module;
        $dist =~ s/::/\-/g;

        my $module_path = $module;
        $module_path =~ s[::][/]g;
        $module_path .= '.pm';

        if ( $myPERL_VERSION ge EXTENDED_POD_LINK_VERSION ) {
            if ($version) {
                $pod .= "=item * L<$module|$module>, "
                    . "L<$version|http://search.cpan.org/dist/$dist-$version/lib/$module_path>\n\n";
            } else {
                $pod .= "=item * L<$module|$module>\n\n";
            }
        } else {
            if ($version) {
                $pod .= "=item * L<$module|$module>, $version\n\n";
            } else {
                $pod .= "=item * L<$module|$module>\n\n";
            }
        }
    }
    $pod .= "=back\n\n=head1";

    my $cwd = getcwd();

    my @path = split /::/, $self->{properties}->{module_name}
        || $self->{properties}->{module_name};

    #HACK: induced from test suite
    my $dir = $self->notes('temp_wd') ? $self->notes('temp_wd') : $cwd .'/t/';

    ## no critic qw(ValuesAndExpressions::ProhibitNoisyQuotes)
    my $file = ( join '/', ( $dir, @path ) ) . '.pm';

    my $contents = read_file($file) or croak "Unable to read file: $file - $!";

    my $rv = $contents =~ s/=head1\s*$section_header\s*.*=head1/$pod/s;

    if ( !$rv ) {
        croak "No $section_header section replaced";
    }

    open my $fout, '>', $file
        or croak "Unable to open file: $file - $!";

    print $fout $contents;

    close $fout or croak "Unable to close file: $file - $!";

    return 1;
}

#Lifted from Module::Build::Base
sub do_create_metafile {
  my $self = shift;
  return if $self->{wrote_metadata};
  my $p = $self->{properties};

  unless ($p->{license}) {
    $self->log_warn("No license specified, setting license = 'unknown'\n");
    $p->{license} = 'unknown';
  }

  my @metafiles = ( $self->metafile, $self->metafile2 );
  # If we're in the distdir, the metafile may exist and be non-writable.
  $self->delete_filetree($_) for @metafiles;

  # Since we're building ourself, we have to do some special stuff
  # here: the ConfigData module is found in blib/lib.
  local @INC = @INC;
  if (($self->module_name || '') eq 'Module::Build') {
    $self->depends_on('config_data');
    push @INC, File::Spec->catdir($self->blib, 'lib');
  }

  my $meta_obj = $self->_get_meta_object(
    quiet => 0, fatal => 1, auto => 1
  );

  #JONASBN: Changed file parameter
  my @created = $self->_write_meta_files( $meta_obj, $self->metafile );

  if ( @created ) {
    $self->{wrote_metadata} = 1;
    $self->_add_to_manifest('MANIFEST', $_) for @created;
  }
  return 1;
}

#lifted from Module::Build::Base, sets generated_by 
sub get_metadata {
  my ($self, %args) = @_;

  my $fatal = $args{fatal} || 0;
  my $p = $self->{properties};

  $self->auto_config_requires if $args{auto};

  # validate required fields
  foreach my $f (qw(dist_name dist_version dist_author dist_abstract license)) {
    my $field = $self->$f();
    unless ( defined $field and length $field ) {
      my $err = "ERROR: Missing required field '$f' for metafile\n";
      if ( $fatal ) {
        die $err;
      }
      else {
        $self->log_warn($err);
      }
    }
  }

  my %metadata = (
    name => $self->dist_name,
    version => $self->normalize_version($self->dist_version),
    author => $self->dist_author,
    abstract => $self->dist_abstract,
    #JONASBN changed the generated_by
    generated_by => "Module::Build::Bundle version $Module::Build::Bundle::VERSION",
    'meta-spec' => {
      version => '2',
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    dynamic_config => exists $p->{dynamic_config} ? $p->{dynamic_config} : 1,
    release_status => $self->release_status,
  );

  my ($meta_license, $meta_license_url) = $self->_get_license;
  $metadata{license} = [ $meta_license ];
  $metadata{resources}{license} = [ $meta_license_url ] if defined $meta_license_url;

  $metadata{prereqs} = $self->_normalize_prereqs;

  if (exists $p->{no_index}) {
    $metadata{no_index} = $p->{no_index};
  } elsif (my $pkgs = eval { $self->find_dist_packages }) {
    $metadata{provides} = $pkgs if %$pkgs;
  } else {
    $self->log_warn("$@\nWARNING: Possible missing or corrupt 'MANIFEST' file.\n" .
                    "Nothing to enter for 'provides' field in metafile.\n");
  }

  if (my $add = $self->meta_add) {
    if (not exists $add->{'meta-spec'} or $add->{'meta-spec'}{version} != 2) {
      require CPAN::Meta::Converter;
      if (CPAN::Meta::Converter->VERSION('2.141170')) {
        $add = CPAN::Meta::Converter->new($add)->upgrade_fragment;
        delete $add->{prereqs}; # XXX this would now overwrite all prereqs
      }
      else {
        $self->log_warn("Can't meta_add without CPAN::Meta 2.141170");
      }
    }

    while (my($k, $v) = each %{$add}) {
      $metadata{$k} = $v;
    }
  }

  if (my $merge = $self->meta_merge) {
    if (eval { require CPAN::Meta::Merge }) {
      %metadata = %{ CPAN::Meta::Merge->new(default_version => '1.4')->merge(\%metadata, $merge) };
    }
    else {
      $self->log_warn("Can't merge without CPAN::Meta::Merge");
    }
  }

  return \%metadata;
}

#lifted from Module::Build::Base, added package and version resolution and 
# addition to configure requires
sub prepare_metadata {
  my ($self, $node, $keys) = @_;
  my $p = $self->{properties};

  #JONASBN: Added package resolution
  my $package = ref $self;
  my $version = $package::VERSION;

  # A little helper sub
  my $add_node = sub {
    my ($name, $val) = @_;
    $node->{$name} = $val;
    push @$keys, $name if $keys;
  };

  foreach (qw(dist_name dist_version dist_author dist_abstract license)) {
    (my $name = $_) =~ s/^dist_//;
    $add_node->($name, $self->$_());
    die "ERROR: Missing required field '$_' for META.yml\n"
      unless defined($node->{$name}) && length($node->{$name});
  }
  $node->{version} = $self->normalize_version($node->{version}); 

  if (defined( my $l = $self->license )) {
    die "Unknown license string '$l'"
      unless exists $self->valid_licenses->{ $l };

    if (my $key = $self->valid_licenses->{ $l }) {
      my $class = "Software::License::$key";
      if (eval "use $class; 1") {
        # S::L requires a 'holder' key
        $node->{resources}{license} = $class->new({holder=>"nobody"})->url;
      }
      else {
        $node->{resources}{license} = $self->_license_url($l);
      }
    }
    # XXX we are silently omitting the url for any unknown license
  }

  # copy prereq data structures so we can modify them before writing to META
  my %prereq_types;
  for my $type ( 'configure_requires', @{$self->prereq_action_types} ) {
    if (exists $p->{$type}) {  
      for my $mod ( keys %{ $p->{$type} } ) {
        $prereq_types{$type}{$mod} = 
          $self->normalize_version($p->{$type}{$mod});
      }
    }
  }

  # add current Module::Build to configure_requires if there 
  # isn't one already specified (but not ourself, so we're not circular)
  if ( $self->dist_name ne 'Module-Build' 
    && $self->auto_configure_requires
    && ! exists $prereq_types{'configure_requires'}{'Module::Build'}
  ) {
    $prereq_types{configure_requires}{'Module::Build'} = $VERSION;
    #JONASBN added configure requires
    $prereq_types{configure_requires}{$package} = $version;
  }

  for my $t ( keys %prereq_types ) {
      $add_node->($t, $prereq_types{$t});
  }

  if (exists $p->{dynamic_config}) {
    $add_node->('dynamic_config', $p->{dynamic_config});
  }
  my $pkgs = eval { $self->find_dist_packages };
  if ($@) {
    $self->log_warn("$@\nWARNING: Possible missing or corrupt 'MANIFEST' file.\n" .
        "Nothing to enter for 'provides' field in META.yml\n");
  } else {
    $node->{provides} = $pkgs if %$pkgs;
  }
;
  if (exists $p->{no_index}) {
    $add_node->('no_index', $p->{no_index});
  }

  $add_node->('generated_by', "$package version $version");

  $add_node->('meta-spec', 
        {version => '1.4',
         url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
        });

  while (my($k, $v) = each %{$self->meta_add}) {
    $add_node->($k, $v);
  }

  while (my($k, $v) = each %{$self->meta_merge}) {
    $self->_hash_merge($node, $k, $v);
  }

  return $node;
}

sub is_windowsish {
  return 0;
}

1;

__END__

=pod

=encoding utf8

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Module-Build-Bundle.svg)](http://badge.fury.io/pl/Module-Build-Bundle)
[![Build Status](https://travis-ci.org/jonasbn/mbb.svg?branch=master)](https://travis-ci.org/jonasbn/mbb)
[![Coverage Status](https://coveralls.io/repos/jonasbn/mbb/badge.png)](https://coveralls.io/r/jonasbn/mbb)

=end markdown

=head1 NAME

Module::Build::Bundle - subclass for supporting Tasks and Bundles

=head1 VERSION

This documentation describes version 0.17

=head1 SYNOPSIS

    #In your Build.PL
    use Module::Build::Bundle;

    #Example lifted from: Perl::Critic::logicLAB
    my $build = Module::Build::Bundle->new(
        dist_author   => 'Jonas B. Nielsen (jonasbn), <jonasbn@cpan.org>',
        module_name   => 'Perl::Critic::logicLAB',
        license       => 'artistic',
        create_readme => 1,
        requires      => {
            'Perl::Critic::Policy::logicLAB::ProhibitUseLib' => '0',
            'Perl::Critic::Policy::logicLAB::RequireVersionFormat' => '0',
        },
    );

    $build->create_build_script();


    #In your shell
    % ./Build contents

    #Or implicitly executing contents action
    % ./Build

=head1 DESCRIPTION

=head2 FEATURES

=over

=item * Autogeneration of POD for Bundle and Task distributions via a build action

=item * Links to required/listed distributions, with or without versions

=item * Links to specific versions of distributions for perl 5.12.0 or newer if a
version is specified

=item * Inserts a POD section named CONTENTS or something specified by the
caller

=back

This module adds a very basic action for propagating a requirements list from
a F<Build.PL> file's requires section to the a POD section in a designated
distribution.

=head1 SUBROUTINES/METHODS

=head2 ACTION_contents

This is the build action parsing the requirements specified in the F<Build.PL>
file. It creates a POD section (see also L</FEATURES> above).

By default it overwrites the CONTENTS section with a POD link listing. You can
specify a note indicating if what section you want to overwrite using the
section_header note.

    #Example lifted from: Perl::Critic::logicLAB
    my $build = Module::Build::Bundle->new(
        dist_author   => 'Jonas B. Nielsen (jonasbn), <jonasbn@cpan.org>',
        module_name   => 'Perl::Critic::logicLAB',
        license       => 'artistic',
        create_readme => 1,
        requires      => {
            'Perl::Critic::Policy::logicLAB::ProhibitUseLib' => '0',
            'Perl::Critic::Policy::logicLAB::RequireVersionFormat' => '0',
        },
    );

    $build->notes('section_header' => 'POLICIES');

    $build->create_build_script();

The section of course has to be present.

Based on your version of perl and your F<Build.PL> requirements, the links will
be rendered in the following formats:

Basic:

    #Build.PL
    requires => {
        'Some::Package' => '0',
    }

    #POD, perl all
    =item * L<Some::Package|Some::Package>

With version:

    #Build.PL
    requires => {
        'Some::Package' => '1.99',
    }

    #POD, perl < 5.12.0
    =item * L<Some::Package|Some::Package>, 1.99

    #POD, perl >= 5.12.0
    =item * L<Some::Package|Some::Package>, L<1\.99\|http://search.cpan.org/dist/Some-Package-1.99/lib/Some/Package.pm>

=head2 ACTION_build

This is a simple wrapper around the standard action: L<Module::Build|Module::Build>
build action. It checks whether L</ACTION_contents> have been executed, if not
it executes it.

=head2 get_metadata

This method has been lifted from L<Module::Build::Base|Module::Build::Base> and
altered.

It sets:

=over

=item * 'generated by <package> version <package version>' string in F<META.yml>

=back

For Module::Build::Bundle:

    #Example META.yml
    configure_requires:
        Module::Build::Bundle: 0.01
    generated_by: 'Module::Build::Bundle version 0.01'

=head2 prepare_metadata

This method has been lifted from L<Module::Build::Base|Module::Build::Base> and
altered.

It sets:

=over

=item * configure_requires: <package>: <version>

=back

=head2 do_create_metafile

This method has been lifted from L<Module::Build::Base|Module::Build::Base> and
altered.

The method was overwritten to be more testable. The method created the relevant
META file.

It passes a more general file parameter for testing instead of a hard-coded filename.

=head2 is_windowsish

Required overwritten by Module::Build, when subclassing.

Ref: https://metacpan.org/pod/distribution/Module-Build/lib/Module/Build/API.pod

=head1 DIAGNOSTICS

=over

=item * No <section> section to be replaced

If the POD to be updated does not contain a placeholder section the action
will die with the above message.

The default minimal section should look something like:

    =head1 CONTENTS

    =head1

Or if you provide your own section_header

    =head1 <section header>

    =head1

=back

=head1 CONFIGURATION AND ENVIRONMENT

The only special configuration necessary is described in the section below.

=head2 CONTENTS SECTION

The module does per default look for the section named: CONTENTS.

This is the section used in Bundles, this can be overwritten using the section
parameter.

For example L<Perl::Critic::logicLAB|Perl::Critic::logicLAB> uses a section
named POLICIES and L<Task::BeLike::JONASBN> uses DEPENDENCIES as section header.

The problem is that the section has to be present or else the contents action
will throw an error.

Module::Build::Bundle is primarily aimed at Bundle distributions. Their use is
however no longer recommended and L<Task> provides a better way.

=head1 DEPENDENCIES

=over

=item * perl 5.8.0

=item * L<Module::Build::Base|Module::Build::Base>, part of the L<Module::Build>
distribution

=back

=head1 INCOMPATIBILITIES

The distribution requires perl version from 5.8.0 and up, earlier versions of perl
are not supported.

=head1 BUGS AND LIMITATIONS

Currently Module::Build::Bundle is not able to handle root based distributions
meaning distributions with a single Perl module located in the root directory
instead of the lib structure.

Apart from that there are no known special limitations or bugs at this time,
but I am certain there are plenty of scenarios is distribution packaging the
module is not currently handling.

The module only supports Bundle/Task distributions based on L<Module::Build>.
The implementation is based on a subclass of L<Module::Build>, which can replace
L<Module::Build> in your F<Build.PL> (See: L</SYNOPSIS>).

As described previously in the documentation a section of documentation can only
replaced. A section with the generated contents cannot be added with out a
placeholder in the form of designated section title. This might be changed in the
future.

Before version 0.11 the designated module was worked on in F<lib/>, I am still
unsure as to what the right place to do this is. Perhaps I<hooking> into the
build phase is not a good idea at all.

=head1 BUG REPORTING

Please report any bugs or feature requests via:

=over

=item * Github issues: L<https://github.com/jonasbn/mbb/issues>

=item * email: bug−module-build-bundle at rt.cpan.org

=item * RT: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-Bundle>

=back

=head1 TEST AND QUALITY

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    lib/Module/Build/Bundle.pm     44.5   18.3   23.0   70.5  100.0  100.0   39.6
    Total                          44.5   18.3   23.0   70.5  100.0  100.0   39.6
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

The above coverage report is based on release 0.13

=head1 QUALITY AND CODING STANDARD

The code passes L<Perl::Critic> tests a severity: 1 (brutal)

The following policies have been disabled:

      L<Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint>

L<Perl::Critic> resource file, can be located in the F<t/> directory of the
distribution see F <t/perlcriticrc>

L<Perl::Tidy> resource file, can be obtained from the following URL:

=over

=item * L<https://logiclab.jira.com/wiki/display/OPEN/Perl-Tidy>

=back

=head1 DEVELOPMENT

The Module::Build::Bundle repository is public available on Github, pull requests most
welcome.

=head1 TODO

=over

=item * Exchange the fragile POD handling with Pod::Weaver

=item * Methods lifted from L<Module::Build::Base>, could be backported to L<Module::Build::Base>, 
as patches if these can be implemented in a acceptable state.

=back

Please see: L<https://logiclab.jira.com/browse/MBB#selectedTab=com.atlassian.jira.plugin.system.project%3Aroadmap-panel>

=head1 SEE ALSO

=over

=item * L<Task|Task>

=item * L<TaskBeLike::JONASBN|TaskBeLike::JONASBN>

=item * L<Perl::Critic::logicLAB|Perl::Critic::logicLAB>

=item * L<CPAN|CPAN>

=item * L<CPAN::Bundle|http://cpansearch.perl.org/src/ANDK/CPAN-1.9402/lib/CPAN/Bundle.pm>

=item * L<https://logiclab.jira.com/wiki/display/OPEN/Module-Build-Bundle>

=back

=head1 MOTIVATION

The motivation for development of this module was driven by two things.

=over

=item * The joy of fooling around with L<Module::Build|Module::Build>

=item * The need for automating the documentation generation

=back

I have a few perks and one of them is that I never get to automate stuff until
very late and I always regret that. So when I released
L<Bundle::JONASBN|Bundle::JONASBN>, now L<Task::BeLike::JONASBN|Task::BeLike::JONASBN>
I thought I might aswell get it automated right away.

This module lived for a long time as a part of L<Bundle::JONASBN|Bundle::JONASBN>
but then I needed it for some other distributions, so I decided to separate it out.

=head1 ACKNOWLEDGEMENTS

=over

=item * Adam Kennedy (ADAMK) author of L<Task>, a very basic and simple solution

=item * The L<Module::Build> developers

=item * Lars Dɪᴇᴄᴋᴏᴡ (DAXIM) for reporting RT:83754, resulting in release 0.11

=item * Andreas J. König (ANDK) for reporting RT:82128, included in release 0.10

=item * Slaven Rezić for reporting issue #2

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen (jonasbn) C<< <jonasbn@cpan.org> >>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 jonasbn, all rights reserved.

Module::Build::Bundle is released under the Artistic License 2.0

=cut
