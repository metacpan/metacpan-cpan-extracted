package Rapi::Blog::Template::Dispatcher;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;
use Module::Runtime;

use Moo;
use Types::Standard ':all';


has 'AccessStore',  is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Template::AccessStore'];
has 'path',         is => 'ro', required => 1, isa => Str;
has 'ctx',          is => 'ro', required => 1;

has 'Scaffold',     is => 'ro', isa => Maybe[InstanceOf['Rapi::Blog::Scaffold']], default => sub { undef };


has 'parent', is => 'ro', default => sub { undef };

has 'type', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my ($pfx,$type) = split('Rapi::Blog::Template::Dispatcher::',(ref $self),2);
  $type
};

sub is_type {
  my ($self, $type) = @_;
  $type && $self->type && $type eq $self->type
}

sub find_parent_type {
  my ($self, $type) = @_;
  return undef unless ($self->parent);
  $self->parent->is_type($type) ? $self->parent : $self->parent->find_parent_type($type)
}


has 'claimed', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->parent ? 1 : 0
}, isa => Bool;


has 'exists',  is => 'ro', lazy => 1, isa => Bool,       default => sub { 0 };
has 'mtime',   is => 'ro', lazy => 1, isa => Maybe[Str], default => sub { undef };
has 'content', is => 'ro', lazy => 1, isa => Maybe[Str], default => sub { undef };

has 'restrict',  is => 'ro', lazy => 1, isa => Bool, default => sub { 0 };

has 'template_vars', is => 'ro', lazy => 1, isa => HashRef, default => sub {{}};


has 'is_static', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->_is_static_path($self->path)
}, isa => Bool;

has 'is_private', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->_is_private_path($self->path)
}, isa => Bool;

has 'valid_not_found_tpl', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $tpl = $self->Scaffold->not_found_template or return undef;
  $self->Scaffold->resolve_file($tpl) ? $tpl : undef
}, isa => Maybe[Str];


sub rank { 0 }

sub resolved { (shift) }

sub _factory_for {
  my ($self,$type,@args) = @_;
  
  my $class = join('::',__PACKAGE__,$type);
  Module::Runtime::require_module($class);
  
  my %opts = $self->_get_factory_opts(@args);
  
  $class->_factory_class(%opts)
}


sub _get_factory_opts {
  my $self = shift;
  my %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  my @attrs = qw(AccessStore path ctx Scaffold);
  exists $opts{$_} or $opts{$_} = $self->$_ for (@attrs);
  
  $opts{parent} = $self if ($self->Scaffold);

  %opts
}

sub _factory {
  my $self = shift;
  my ($class, %opts);
  
  if(ref($self)) {
    %opts = $self->_get_factory_opts(@_);
    $class = ref($self)
  }
  else {
    %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
    $class = $self
  }
  
  $class->_factory_class(%opts)
}


sub _factory_class {
  my $class = shift;
  $class->new(@_)->resolved
}


sub us_or_better {
  my ($this,$that) = @_;
  $that && $that->rank > $this->rank ? $that : $this
}


sub _resolve_best_scaffold {
  my $self = shift;
  
  my @scaffolds = $self->AccessStore->ScaffoldSet->all;
  scalar(@scaffolds) > 0 or die "Fatal error -- no Scaffolds detected. At least one Scaffold must be loaded.";
  
  if (my $uuid = $self->ctx->stash->{rapi_blog_only_scaffold_uuid}) {
    @scaffolds = grep { $_->uuid eq $uuid } @scaffolds;
    scalar(@scaffolds) > 0 or die join('',
      "Fatal error -- rapi_blog_only_scaffold_uuid is set ('$uuid') but there ",
      "is no Scaffold with that uuid"
    );
  }
  
  my $Best = undef;
  for (@scaffolds) {
    my $Next = $self->_factory( Scaffold => $_ )->resolve;
    $Best = $Best ? $Best->us_or_better($Next) : $Next;
  }
  
  $Best
}


sub resolve {
  my $self = shift;
  
  $self->Scaffold or return $self->_resolve_best_scaffold;
  
  my $FileDispatch = $self->_factory_for('ScaffoldFile');
  
  ($FileDispatch && $FileDispatch->exists ? $FileDispatch : undef) ||
  $self->_resolve_DirectPost   ||
  $self->_resolve_ViewWrapper  ||
  $FileDispatch ||
  $self->_factory_for('Unclaimed')
}




sub _resolve_DirectPost {
  my $self = shift;
  my ($pfx,$name) = split($self->Scaffold->unique_int_post_path,$self->path,2);
  ($name && $pfx eq '') 
    ? $self->_factory_for('Post', name => $name, direct => 1)
    : undef
}



sub _resolve_ViewWrapper {
  my $self = shift;
  my ($VW, $path) = $self->Scaffold->resolve_ViewWrapper($self->path);
  $VW ? $self->_factory_for('ViewWrapper', ViewWrapper => $VW, subpath => $path) : undef
}




has 'maybe_psgi_response', is => 'ro', init_arg => undef, lazy => 1, default => sub { undef };


1;