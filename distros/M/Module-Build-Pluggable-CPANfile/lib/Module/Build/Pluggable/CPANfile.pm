package Module::Build::Pluggable::CPANfile;

use strict;
use warnings;
use 5.008005;
use parent qw/Module::Build::Pluggable::Base/;
use Module::CPANfile;
use version;
use List::Util;

our $VERSION = '0.05';

require Module::Build;
my $support_test_requries = 
    ( version->parse($Module::Build::VERSION) >= version->parse('0.4004') ) ? 1 : 0;

sub HOOK_prepare {
    my $self = shift;
    my $args = shift;

    my @phases = qw/configure build devel test runtime/;
    my %copy_prereqs = $support_test_requries ?
        (
            'configure_requires' => [qw/configure/],
            'build_requires'     => [qw/build/],
            'test_requires'      => [qw/test/],
            'requires'           => [qw/runtime/]
        ) : 
        (
            'configure_requires' => [qw/configure/],
            'build_requires'     => [qw/build test/],
            'requires'           => [qw/runtime/]
        );

    my $file = Module::CPANfile->load("cpanfile");
    my $prereq = $file->prereq_specs;

    if ( !$support_test_requries && exists $prereq->{test} ) {
        warn("[INFO] Module::Build < 0.4004 does not support test_requries. ",
             "prereqs for test will be merged into build_requires\n");
    }

    for my $args_key ( keys %copy_prereqs ) {
        my $requires = $args->{$args_key} || {};
        for my $cpanfile_key ( @{$copy_prereqs{$args_key}} ) {
            next if ! exists $prereq->{$cpanfile_key};
            $requires = {
                %$requires,
                $prereq->{$cpanfile_key}->{requires} ? %{$prereq->{$cpanfile_key}->{requires}} : ()
            };
            my $unsupport = List::Util::first { exists $prereq->{$cpanfile_key}->{$_} } 
                qw/recommends suggests conflicts/;
            if ( $cpanfile_key ne 'runtime' &&  $unsupport ) {
                warn("[WARN] Module::Build does not support '$unsupport' prereqs type on $cpanfile_key phase\n");
            }
            if ( $cpanfile_key eq 'runtime' && exists $prereq->{$cpanfile_key}->{suggests} ) {
                warn("[WARN] Module::Build does not support 'suggests' prereqs type on $cpanfile_key phase\n");
            }
            if ( $cpanfile_key eq 'runtime' ) {
                for my $prereq_type ( qw/recommends conflicts/ ) {
                    $args->{$prereq_type} ||= {};
                    $args->{$prereq_type} = {
                        %{$args->{$prereq_type}},
                        $prereq->{$cpanfile_key}->{$prereq_type} ? %{$prereq->{$cpanfile_key}->{$prereq_type}} : ()
                    };
                    delete $args->{$prereq_type} if ! keys %{$args->{$prereq_type}};
                }
            }
        }
        $args->{$args_key} = $requires if keys %$requires;
    }
}


1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Pluggable::CPANfile - Include cpanfile

=head1 SYNOPSIS

  # cpanfile
  requires 'Plack', 0.9;
  on test => sub {
      requires 'Test::Warn';
  };
  
  # Build.PL
  use Module::Build::Pluggable (
      'CPANfile'
  );
  
  my $builder = Module::Build::Pluggable->new(
        ... # normal M::B args. but not required prereqs
  );
  $builder->create_build_script();

=head1 DESCRIPTION

Module::Build::Pluggable::CPANfile is plugin for Module::Build::Pluggable to include dependencies from cpanfile into meta files. 
This modules is L<Module::Install::CPANfile> for Module::Build

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 SEE ALSO

L<Module::Install::CPANfile>, L<cpanfile>, L<Module::Build::Pluggable>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
