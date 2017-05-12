package Rapi::Demo::Chinook;

use strict;
use warnings;

# ABSTRACT: PSGI version of the RapidApp "Chinook" demo

use RapidApp 1.0303;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;
use Path::Class qw(file dir);
use Module::Runtime;

our $VERSION = '1.03';

has '+base_appname', default => sub { 'Rapi::Demo::Chinook::App' };
has '+debug',        default => sub {1};

sub _build_plugins {[ 'RapidApp::RapidDbic' ]}

has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $ENV{RAPI_DEMO_CHINOOK_SHARE_DIR} || (
    try{dist_dir('Rapi-Demo-Chinook')} || (
      -d "$FindBin::Bin/share" ? "$FindBin::Bin/share" : "$FindBin::Bin/../share" 
    )
  )
};

has '_init_chinook_db', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  file( $self->share_dir, '_init_chinook.db' )->stringify
}, init_arg => undef;

has 'chinook_db', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  # Default to the cwd
  file( 'chinook.db' )->stringify
};


has '+inject_components', default => sub {
  my $self = shift;
  my $model = 'Rapi::Demo::Chinook::Model::DB';
  
  my $db = file( $self->chinook_db );
  
  $self->init_db unless (-f $db);
  
  # Make sure the path is valid/exists:
  $db->resolve;
  
  Module::Runtime::require_module($model);
  $model->config->{connect_info}{dsn} = "dbi:SQLite:$db";

  return [
    [ $model => 'Model::DB' ]
  ]
};


sub init_db {
  my ($self, $ovr) = @_;
  
  my ($src,$dst) = (file($self->_init_chinook_db),file($self->chinook_db));
  
  die "init_db(): ERROR: init db file '$src' not found!" unless (-f $src);

  if(-e $dst) {
    if($ovr) {
      $dst->remove;
    }
    else {
      die "init_db(): Destination file '$dst' already exists -- call with true arg to overwrite.";
    }
  }
  
  print STDERR "Initializing $dst\n" if ($self->debug);
  #$src->copy_to( $dst );
  # Create as new file instead of copying to avoid perm issues in a cross-platform manner:
  # (also not bothering to do this in chunks because the file is smaller than 1M)
  $dst->spew( scalar $src->slurp );
}

1;


__END__

=head1 NAME

Rapi::Demo::Chinook - PSGI version of the RapidApp "Chinook" demo

=head1 SYNOPSIS

 use Rapi::Demo::Chinook;
 my $app = Rapi::Demo::Chinook->new;

 # Plack/PSGI app:
 $app->to_app

Or, from the command-line:

 plackup -MRapi::Demo::Chinook -e 'Rapi::Demo::Chinook->new->to_app'


=head1 DESCRIPTION

This module is a simple L<Plack>/PSGI version of the L<RapidApp>/L<RapidDbic|Catalyst::Plugin::RapidApp::RapidDbic> 
"Chinook" demo at L<http://www.rapidapp.info/demos/chinook>. This module was written to allow CPAN 
distribution of the demo for easy access and portability within PSGI-based setups.

=head1 CONFIGURATION

C<Rapi::Demo::Chinook> extends L<RapidApp::Builder> and supports all of its options, as well as the 
following params specific to this module:

=head2 chinook_db

Path to the SQLite database file, which may or may not already exist. If the file does not already
exist, it is created as a copy from the default database, which is the state of the DB at the end
of "Part 2" of the Chinook demo at L<http://www.rapidapp.info/demos/chinook>.

Defaults to C<'chinook.db'> in the current working directory.

=head1 METHODS

=head2 init_db

Copies the default database to the path specified by C<chinook_db>. Pass a true value as the first
argument to overwrite the target file if it already exists.

This method is called automatically the first time the module is loaded, or if the C<chinook_db> file
doesn't exist.

=head1 SEE ALSO

=over

=item * 

L<RapidApp>

=item * 

L<RapidApp::Builder>

=item * 

L<http://www.rapidapp.info/demos/chinook>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



