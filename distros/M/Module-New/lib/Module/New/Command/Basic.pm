package Module::New::Command::Basic;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;

functions {

  set_distname => sub () { Module::New::Queue->register(sub {
    my ($self, $name) = @_;
    croak "distribution/main module name is required" unless $name;
    Module::New->context->distname( $name );
  })},

  guess_root => sub () { Module::New::Queue->register(sub {
    my $self = shift;
    my $context = Module::New->context;
    $context->path->guess_root( $context->config('root') );
  })},

  set_file => sub () { Module::New::Queue->register(sub {
    my ($self, $name) = @_;

    croak "filename is required" unless $name;

    my $context = Module::New->context;
    my $type = $context->config('type');

    unless ($type) {
      if ( $name =~ /::/ or $name =~ /\.pm$/ or $name =~ m{^lib/} ) {
        $type = 'Module';
      }
      elsif ( $name =~ /\.t$/ or $name =~ m{^t/} ) {
        $type = 'Test';
      }
      elsif ( $name =~ /\.pl/ or $name =~ m{^(?:bin|scripts?)/} ) {
        $type = 'Script';
      }
      elsif ( $name = /\./ ) {
        $type = 'Plain';
      }
    }
    $type ||= 'Module';
    $context->config( type => $type );

    if ( $type =~ /Module$/ ) {
      $context->module( $name );
    }
    else {
      $context->mainfile( $name );
    }
  })},

  create_distdir => sub () { Module::New::Queue->register(sub {
    my $self = shift;

    my $context = Module::New->context;

    $context->path->set_root;
    unless ( $context->config('no_dirs') ) {
      my $distname = $context->distname;
      my $distdir  = $context->path->dir($distname);
      if ( $distdir->exists ) {
        if ( $context->config('force') ) {
          $context->path->remove_dir( $distdir, 'absolute' );
        }
        elsif ( $context->config('grace') ) {
          # just skip and do nothing
        }
        else {
          croak "$distname already exists";
        }
      }
      $context->path->create_dir($distname);
      $context->path->change_dir($distname);
    }
    else {
      $context->path->change_dir(".");
    }
    $context->path->set_root;
  })},

  create_maketool => sub (;$) {
    my $type = shift;
    Module::New::Queue->register(sub {
      my $self = shift;

      my $context = Module::New->context;
      $type ||= $context->config('make') || 'MakeMakerCPANfile';
      $type = 'ModuleBuild'   if $type eq 'MB';
      $type = 'MakeMaker'     if $type eq 'EUMM';

      $context->files->add( $type );
    });
  },

  create_general_files => sub () { Module::New::Queue->register(sub {
    my $self = shift;

    Module::New->context->files->add(qw( Readme Changes ManifestSkip License ));
  })},

  create_tests => sub (;@) {
    my @files = @_;
    Module::New::Queue->register(sub {
      my $self = shift;

      my $context = Module::New->context;
      if ( ref $context->config('test') eq 'ARRAY' ) {
        $context->files->add( @{ Module::New->context->config('test') } );
      }
      elsif ( @files ) {
        $context->files->add( @files );
      }
      else {
        $context->files->add(qw( LoadTest PodTest PodCoverageTest ));
      }
    });
  },

  create_files => sub (;@) {
    my @files = @_;
    Module::New::Queue->register(sub {
      my $self = shift;

      my $context = Module::New->context;
         $context->files->add( @files );
      if ($context->config('xs')) {
        $context->files->add('XS');
        eval {
          require Devel::PPPort;
          Devel::PPPort::WriteFile();
          $context->log( info => "created ppport.h" );
        };
        $context->log( warn => $@ ) if $@;
      }
      while ( my $name = $context->files->next ) {
        if ( $name eq '{ANY_TYPE}' ) {
          $name = $context->config('type') || 'Module';
        }
        my $file = $context->loader->reload_class( File => $name );
        $context->path->create_file( $file->render );
      }
    });
  },

  create_manifest => sub () { Module::New::Queue->register(sub {
    my $self = shift;

    my $context = Module::New->context;
    $context->path->remove_file('MANIFEST') if $context->config('force');

    local $ENV{PERL_MM_MANIFEST_VERBOSE} = 0 if $context->config('silent');

    require ExtUtils::Manifest;
    ExtUtils::Manifest::mkmanifest();

    $context->log( info => 'updated manifest' );
  })},

  edit_mainfile => sub (;%) {
    my %options = @_;
    return if $ENV{HARNESS_ACTIVE} || $INC{'Test/Classy.pm'};
    Module::New::Queue->register(sub {
      my $self = shift;

      my $context = Module::New->context;
      return if $options{optional};

      my $editor = $context->config('editor') || $ENV{EDITOR};
      unless ( $editor ) { carp 'editor is not set'; return; }
      my $file = $options{file} || $context->mainfile;
      exec( _shell_quote($editor) => _shell_quote($file) );
    });
  },
};

sub _shell_quote {
  my $str = shift;
  return $str unless $str =~ /\s/;
  return ( $^O eq 'MSWin32' ) ? qq{"$str"} : qq{'$str'};
}

1;

__END__

=head1 NAME

Module::New::Command::Basic

=head1 FUNCTIONS

=head2 set_distname

=head2 guess_root

=head2 set_file

=head2 create_distdir

=head2 create_maketool

=head2 create_general_files

=head2 create_tests

=head2 create_files

=head2 create_manifest

=head2 edit_mainfile

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
