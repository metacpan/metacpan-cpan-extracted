use strict;
use warnings;

package Perl::Build::Git;
BEGIN {
  $Perl::Build::Git::AUTHORITY = 'cpan:KENTNL';
}
{
  $Perl::Build::Git::VERSION = '0.001000';
}

# ABSTRACT: Convenience extensions for Perl::Build for bulk git work

use Perl::Build 0.17;
use Perl::Build::Built;
use parent 'Perl::Build';
use Path::Tiny qw( path );
use Carp qw( croak );


sub _perl_git_src_uri { return 'git://perl5.git.perl.org/perl.git' }

sub _extract_config {
  my ( $class, $args ) = @_;

  croak('cache_root required') unless exists $args->{cache_root};
  croak('git_root required')   unless exists $args->{git_root};

  my ($config) = {
    cache_root => path( delete $args->{cache_root} )->absolute,
    git_root   => path( delete $args->{git_root} )->absolute,
    persistent => ( exists $args->{persistent} ? !!delete $args->{persistent} : undef ),
    preclean   => ( exists $args->{preclean} ? !!delete $args->{preclean} : 1 ),
    quiet      => ( exists $args->{quiet} ? !!delete $args->{quiet} : undef ),
    log_output => ( exists $args->{log_output} ? delete $args->{log_output} : \*STDERR ),
    log        => ( exists $args->{log} ? delete $args->{log} : undef ),
  };

  if ( not $config->{log} ) {
    if ( !$config->{quiet} ) {
      require Term::ANSIColor;
      $config->{log} = sub {
        my ( $color, @message ) = @_;
        $config->{log_output}->print( Term::ANSIColor::colored( $color, "@message\n" ) );
      };
    }
    else {
      $config->{log} = sub { };
    }
  }
  {
    require Git::Wrapper;
    $config->{git} = Git::Wrapper->new( $config->{git_root} );
  }

  # Define <describe>
  {
    require Git::Wrapper;
    $config->{describe} = [ $config->{git}->describe ]->[0];
    $config->{log}->( ['red'], 'Building ' . $config->{describe} );
  }

  # Define <dst_dir> and <tmp_dir>
  if ( $config->{persistent} ) {
    $config->{dst_dir} = $config->{cache_root}->child( $config->{describe} )->absolute;
  }
  else {
    $config->{tmp_dir} = File::Temp->newdir(
      $config->{describe} . '-XXXX',
      DIR     => $config->{cache_root}->stringify,
      CLEANUP => 1,
    );
    $config->{dst_dir} = path( $config->{tmp_dir}->dirname )->absolute;
  }
  $config->{log}->( ['red'], 'Building in ' . $config->{dst_dir} );

  # Define <success_file>
  $config->{success_file} = $config->{dst_dir}->child('.success');

  return ( $config, $args );
}


sub install_git {
  my ( $class, %args ) = @_;

  my ( $config, $user_args ) = $class->_extract_config( \%args );

  my $computed_args = {
    src_path => $config->{git_root}->stringify,
    dst_path => $config->{dst_dir}->stringify,
  };

  if ( $config->{success_file}->is_file ) {

    # Existing success!, don't build.
    $config->{log}->( ['green'], 'This version already built' );
    return Perl::Build::Built->new(
      {
        installed_path => $computed_args->{dst_path}
      }
    );
  }

  if ( $config->{preclean} ) {
    $config->{log}->( ['red'], 'Executing preclean' );
    for my $line ( $config->{git}->checkout( q[--], q[.] ) ) {
      $config->{log}->( ['green'], "checkout:$line" );
    }
    for my $line ( $config->{git}->reset(q[--hard]) ) {
      $config->{log}->( ['green'], "reset:$line" );
    }
    for my $line ( $config->{git}->clean(q[-fxd]) ) {
      $config->{log}->( ['green'], "clean:$line" );
    }
  }

  my $build = $class->install( %{$computed_args}, %{$user_args} );

  $config->{log}->( ['green'], 'Build Success, marking successful' );
  $config->{success_file}->touch;

  return $build;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Build::Git - Convenience extensions for Perl::Build for bulk git work

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This is something that might be useful to call in a git bisect runner

    use Perl::Build::Git;
    my $man         = [qw( man1dir man3dir siteman1dir siteman3dir  )];
    my $no_man_opts = [ map { '-D' . $_ . '=none' } @{$man} ];
    my $install = Perl::Build::Git->install_git(
            persistent => 1,
            preclean   => 1,
            cache_root => '/tmp/perls/',
            git_root   => '/path/to/git/checkout',
            configure_options => [
                '-de',               # quiet automatic
                '-Dusedevel',        # "yes, ok, its a development version"
                @{$no_man_opts},     # man pages are ugly
                '-U versiononly',    # use bin/perl, not bin/perl5.17.1
            ],
    );
    $install->run_env(sub{
            # Test Case Here
            exit 255 if $failed;
    });
    exit 0;

C<persistent = 1>  is intended to give each build its own unique directory, such as

    /tmp/perls/v5.17.10-44-g97927b0/

So that if you do multiple bisects, ( for the purpose of testing which incarnation of C<perl> some module fails in ), testing against a C<perl> that was previously tested against in a previous bisect should return a cached result, greatly speeding up the bisect ( at the expense of disk space ).

=head1 METHODS

=head2 install_git

    Perl::Build::Git->install_git(
        cache_root => '/some/path',
        git_root   => '/some/path/to/perl/git',
        persistent => bool,
        preclean   => bool,
        quiet      => bool,
        log_output => filehandle,
        log        => coderef,
    );

=over 4

=item * C<cache_root>

B<path>. This should be a path to an existent base working directory to install multiple C<perl> installs to

Perl builds will either be in the form of

    <cacheroot>/<tag>-g<sha1abbrev>

or

    <cacheroot>/<tag>-g<sha1abbrev>-<SUFFIX>

depending on C<persistent>

=item * C<git_root>

B<path>.

This should be a path to an existing C<perl> C<git> checkout.

=item * C<persistent>

B<< C<bool> >>.

Whether to make the build directory persistent or not. Persistent directories can be optimistically re-used, while non-persistent ones can not.

Non Persistent directories also have a random component added to their path, and implied cleanup on exit.

Default is B<NOT PERSISTENT>

=item * C<preclean>

B<< C<bool> >>.

Whether to execute a pre-build cleanup of the git working directory.

This at present executes a mash of C<git checkout>, C<git reset> and C<git clean>.

Default is B<PRE-CLEAN GIT TREE>

=item * C<quiet>

B<< C<bool> >>.

If specified, the default method for C<log> is a no-op.

The default is B<NOT QUIET>

=item * C<log_output>

B<< C<filehandle> >>.

Destination to write log messages to.

Default is B<< C<*STDERR> >>

=item * C<log>

B<< C<coderef> >>. Handles dispatch from logging mechanisms, in the form

    $logger->( $color_spec , @message );

where color_spec is anything that L<C<Term::ANSIColor::colored>|Term::ANSIColor::colored> understands.

    $logger->( ['red'], "this", "is", "a" , "test" );

Default implementation writes to C<log_output> formatting C<@message> via C<Term::ANSIColor>.

=back

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
