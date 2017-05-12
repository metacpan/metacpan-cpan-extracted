package Module::Starter::TOSHIOITO;
use 5.10.0;
use strict;
use warnings;
use base "Module::Starter::Simple";
use Carp;
use File::Spec;
use ExtUtils::Command qw(mkpath);

our $VERSION = '0.09';

sub create_distro {
    my $either = shift;
    $either = $either->new(@_) if !ref($either);
    my $self = $either;
    $self->{ignores_type} = [qw(git manifest)] if !$self->{ignores_type} || !@{$self->{ignores_type}};
    $self->{verbose} //= 1;
    $self->{license} //= "perl";
    if(!$self->{github_user_name}) {
        croak "github_user_name config parameter is mandatory";
    }
    return $self->SUPER::create_distro();
}

sub _github_repo_name {
    my ($self) = @_;
    my $prefix = $self->{github_repo_prefix} || "";
    my $postfix = $self->{github_repo_postfix} || "";
    return "$prefix$self->{distro}$postfix";
}

sub Build_PL_guts {
    my ($self, $main_module, $main_pm_file) = @_;
    my $author = "$self->{author} <$self->{email}>";
 
    my $slname = $self->{license};
    my $reponame = $self->_github_repo_name;
     
    return <<"HERE";
use $self->{minperl};
use strict;
use warnings;
use Module::Build;
use Module::Build::Prereqs::FromCPANfile;
 
Module::Build->new(
    module_name         => '$main_module',
    license             => '$slname',
    dist_author         => q{$author},
    dist_version_from   => '$main_pm_file',
    release_status      => 'stable',
    add_to_cleanup     => [ '$self->{distro}-*' ],
    recursive_test_files => 1,
    dynamic_config => 1,
    (-d "share") ? (share_dir => "share") : (),
    
    mb_prereqs_from_cpanfile(),
    
    no_index => {
        directory => ["t", "xt", "eg", "inc", "share"],
        file => ['README.pod', 'README.md'],
    },
    meta_add => {
        'meta-spec' => {
            version => 2,
            url => 'https://metacpan.org/pod/CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/$self->{github_user_name}/$reponame/issues',
            },
            repository => {
                url => 'git://github.com/$self->{github_user_name}/$reponame.git',
                web => 'https://github.com/$self->{github_user_name}/$reponame',
            },
        }
    }
)->create_build_script();
HERE
}

sub create_Build_PL {
    my ($self, $main_module) = @_;
    my $result = $self->SUPER::create_Build_PL($main_module);
    $self->_create_file_relative("cpanfile", <<'HERE');

on 'test' => sub {
    requires 'Test::More' => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
HERE
    $self->_create_file_relative(".travis.yml", <<'HERE');
language: perl
perl:
  - "5.10"
  - "5.12"
  - "5.14"
  - "5.16"
  - "5.18"
  - "5.20"
before_install: "cpanm Module::Build::Prereqs::FromCPANfile"
HERE
    return $result;
}

sub module_guts {
    my ($self, $module, $rtname) = @_;
    my $reponame = $self->_github_repo_name;
    my $username = $self->{github_user_name};
    my $license = $self->_module_license($module, $rtname);
    my $bug_email = "bug-$self->{distro} at rt.cpan.org";
    return <<"HERE"
package $module;
use strict;
use warnings;

our \$VERSION = "0.01";

1;
__END__

\=pod

\=head1 NAME

$module - abstract

\=head1 SYNOPSIS

\=head1 DESCRIPTION

\=head1 SEE ALSO

\=head1 REPOSITORY

L<https://github.com/$username/$reponame>

\=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/$username/$reponame/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=$self->{distro}>.
Please send email to C<$bug_email> to report bugs
if you do not have CPAN RT account.


\=head1 AUTHOR
 
$self->{author}, C<< <$self->{email_obfuscated}> >>

$license

\=cut

HERE
}

sub _create_file_relative {
    my ($self, $paths_ref, @contents) = @_;
    $paths_ref = [$paths_ref] if not ref($paths_ref);
    my $path = File::Spec->catdir($self->{basedir}, @$paths_ref);
    $self->create_file($path, @contents);
    $self->progress("Created $path");
}

sub create_t {
    my ($self, @modules) = @_;

    my @created_files = ();
    foreach my $type ("t", "xt") {
        $self->_ensure_dir($type);
        my $method = "${type}_guts";
        my %t_files = $self->$method(@modules);
        foreach my $filename (keys %t_files) {
            my $content = $t_files{$filename};
            $self->_create_file_relative([$type, $filename], $content);
            push @created_files, "$type/$filename";
        }
    }

    return @created_files;
}

sub t_guts {
    my ($self, @modules) = @_;
    my %t_files = ();
    my $header = $self->_t_header;
    my $nmodules = @modules;
    my $main_module = $modules[0];
    my $use_lines = join(
        "\n", map { qq{    use_ok( '$_' ) || print "Bail out!\\n";} } @modules
    );
    $t_files{'00-load.t'} = $header.<<"HERE";
plan tests => $nmodules;
 
BEGIN {
$use_lines
}
 
diag( "Testing $main_module \$${main_module}::VERSION, Perl \$], \$^X" );
HERE

    return %t_files;
}

sub xt_guts {
    my ($self, @modules) = @_;
    my %t_files = ();
    my $header = $self->_t_header;
    $t_files{'pod.t'} = $header.<<'HERE';
use Test::Pod;
 
all_pod_files_ok();
done_testing;
HERE
 
    $t_files{'manifest.t'} = $header.<<'HERE';
use Test::CheckManifest;

unless($ENV{RELEASE_TESTING}) {
    plan(skip_all => "Set RELEASE_TESTING environment variable to test MANIFEST");
}
 
ok_manifest();
done_testing;
HERE

    return %t_files;
}

sub _t_header {
    my ($self) = @_;
    return <<"EOH";
use $self->{minperl};
use strict;
use warnings;
use Test::More;
 
EOH
}

sub _ensure_dir {
    my ($self, @dirpaths) = @_;
    my $dir = File::Spec->catdir($self->{basedir}, @dirpaths);
    if (not -d $dir) {
        local @ARGV = $dir;
        mkpath();
        $self->progress("Created $dir");
    }
}

sub ignores_guts {
    my ($self, $type) = @_;
    return $self->SUPER::ignores_guts($type) if $type ne "manifest";
    return <<'HERE'
^_
^\.
^MYMETA\.yml$
^MYMETA\.json$
^_build
^Build$
^blib
^MANIFEST\.
^README\.pod$

# Avoid version control files.
\bRCS\b
\bCVS\b
,v$
\B\.svn\b
\b_darcs\b
# (.git only in top-level, hence it's blocked above)
 
# Avoid temp and backup files.
~$
\.tmp$
\.old$
\.bak$
\..*?\.sw[po]$
\#$
\b\.#
 
# avoid OS X finder files
\.DS_Store$
 
# ditto for Windows
\bdesktop\.ini$
\b[Tt]humbs\.db$
 
# Avoid patch remnants
\.orig$
\.rej$
HERE
}

1;

__END__

=pod

=head1 NAME

Module::Starter::TOSHIOITO - create a module like TOSHIOITO does

=head1 SYNOPSIS

In your  ~/.module-starter/config
 
    author: YOUR NAME
    email: YOUR@EMAIL.ADDR
    plugins: Module::Starter::TOSHIOITO
    github_user_name: YOUR_GITHUB_USER_NAME

Then

    $ module-starter --mb --module Foo::Bar

=head1 DESCRIPTION

This is a simple L<Module::Starter> plugin that makes it create module templates that I like.

This is based on L<Module::Starter::Simple>, the default plugin for L<Module::Starter>.
The difference from the base is:

=over

=item *

It assumes the module is hosted on L<Github|https://github.com>.
Users are advised to report issues to Github's issue tracker.

=item *

C<github_user_name> config parameter is mandatory. It is your Github user name.

=item *

If the builder is L<Module::Build>, it uses L<Module::Build::Prereqs::FromCPANfile> and generates a template C<cpanfile>.

=item *

C<ignores_type> config parameter is "C<< git manifest >>" by default.

=item *

C<verbose> config parameter is true by default.

=item *

C<license> is C<perl> by default.

=item *

Module documentation is put at the end of module files.

=item *

It creates C<t> and C<xt> test directories.

=back

=head2 Caution

As the name suggests, this module is rather for myself than for other CPAN authors.
I will change behavior of this module drastically when I think I need it.

=head2 Config parameters

This module takes some config parameters from your ~/.module-starter/config

=over

=item C<github_user_name> (mandatory)

Username of your Github account.
In my case, it's L<debug-ito|https://github.com/debug-ito>.

=item C<github_repo_prefix>, C<github_repo_postfix> (optional)

Prefix and postfix for your module's Github repository based on the distribution name,
so the repository name is constructed as

    "${github_repo_prefix}${distribution_name}${github_repo_postfix}"

By default, both of these params are empty strings.

=back


=head1 SEE ALSO

L<Module::Starter>

=head1 REPOSITORY

L<https://github.com/debug-ito/Module-Starter-TOSHIOITO>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Module-Starter-TOSHIOITO/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Starter-TOSHIOITO>.
Please send email to C<bug-Module-Starter-TOSHIOITO at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
