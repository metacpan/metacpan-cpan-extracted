package Module::Collect;
use 5.006_002;
use strict;
use warnings;
our $VERSION = '0.06';

use Text::Glob qw(glob_to_regex);

use Carp;
use File::Find;
use File::Spec;
use Module::Collect::Package;

sub new {
    my($class, %args) = @_;

    $args{modules}   = [];
    $args{pattern} ||= '*.pm';

    if($args{prefix}){
        $args{prefix} .= '::';
    }
    else{
        $args{prefix} = '';
    }

    my $self = bless { %args }, $class;
    $self->_find_modules;

    $self;
}

sub _find_modules {
    my $self = shift;

    my $path = $self->{path} || return;

    my $pattern = glob_to_regex($self->{pattern});

    my @modules;

    my $wanted  = sub{
        return unless -f;
        return unless /$pattern/;
        push @modules, File::Spec->canonpath($File::Find::name);
    };

    for my $dir(ref($path) eq 'ARRAY' ? @{$path} : $path){
        next unless -d $dir;
        find($wanted, $dir);
    }

    for my $modulefile(@modules){
        $self->_add_module($modulefile);
    }
}

sub _add_module {
    my($self, $modulefile) = @_;
    my @packages = $self->_extract_package($modulefile);
    return unless @packages;
    for (@packages) {
        push @{ $self->{modules} }, Module::Collect::Package->new(
            package => $_,
            path    => $modulefile,
        );
    }
}

sub _extract_package {
    my($self, $modulefile) = @_;

    open my $fh, '<', $modulefile or croak "$modulefile: $!";
    my $prefix = $self->{prefix};

    my $multiple = $self->{multiple};
    my @packages;

    while (<$fh>) {
        next if /\A =\w/xms .. /\A =cut \b/xms; # skip pod sections

        if(/\A \s* package \s+ ($prefix \S*) \s* ;/xms){
            push @packages, $1;

            last unless $multiple;
        }
    }
    return @packages;
}


sub modules {
    my $self = shift;
    $self->{modules};
}

1;
__END__

=encoding utf8

=head1 NAME

Module::Collect - Collect sub-modules in directories

=head1 SYNOPSIS

  use Module::Collect;
  my $collect = Module::Collect->new(
      path     => '/foo/bar/plugins',
      prefix   => 'MyApp::Plugin', # optional
      pattern  => '*.pm',          # optional
      multiple => 1,               # optional, see t/06_multiple.t
  );

  my @modules = @{ $collect->modules };
  for my $module (@modules) {
      print $module->path;    # package fuke oatg
      print $module->package; # package name
      $module->require;       # require package
      my $obj = $module->new; # aliae for $module->package->new
  }

=head1 DESCRIPTION

Module::Collect finds sub-modules, or plugins in directories.

The following directory composition

  $ ls -R t/plugins
  t/plugins:
  empty.pm  foo  foo.pm  pod.pm  withcomment.pm  withpod.pm

  t/plugins/foo:
  bar.pm  baz.plugin

The following code is executed

  use strict;
  use warnings;
  use Module::Collect;
  use Perl6::Say;

  my $c = Module::Collect->new( path => 't/plugins' );
  for my $module (@{ $c->modules }) {
      say $module->package . ', ', $module->path;
      $module->require;
  }

results

  MyApp::Foo, t/plugins/foo.pm
  With::Comment, t/plugins/withcomment.pm
  With::Pod, t/plugins/withpod.pm
  MyApp::Foo::Bar, t/plugins/foo/bar.pm

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

lopnor

gfx

mattn

=head1 INSPIRED BY

L<Plagger>, L<Module::Pluggable>

=head1 SEE ALSO

L<Module::Collect::Package>

=head1 REPOSITORY

  git clone git://github.com/yappo/p5-Module-Collect.git

Module::Collect is git repository is hosted at L<http://github.com/yappo/p5-Module-Collect>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
