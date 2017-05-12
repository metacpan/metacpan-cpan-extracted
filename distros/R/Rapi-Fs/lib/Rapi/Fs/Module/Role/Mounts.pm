package Rapi::Fs::Module::Role::Mounts;

use strict;
use warnings;

# ABSTRACT: Role for modules which use "Mounts"

use Moose::Role;
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);
use Module::Runtime;

# From RapidApp::Module
has 'accept_subargs',   is => 'rw', isa => Bool, default => sub {1};

has 'mounts' => (
  is  => 'ro', required => 1,
  isa => (ArrayRef[ConsumerOf['Rapi::Fs::Role::Driver']])->plus_coercions(
    ArrayRef, \&_coerce_mounts
  ), 
  coerce => 1
);

sub _coerce_mounts {
  ref $_[0] && ref($_[0]) eq 'ARRAY'
    ? [ map { &_coerce_mount($_) } @{$_[0]} ]
    : $_[0]
}

sub _coerce_mount {
  my $mnt = $_[0] or return $_[0];
  
  unless(ref $mnt) {
    my $holder = '---double-colon---';
    $mnt =~ s/\:\:/${holder}/g;
    my @parts = 
      reverse
      map { $_ =~ s/${holder}/::/g; $_ } 
      split(/\:/,$mnt,3);
      
    my ($args,$driver,$name) = scalar(@parts) == 2
      ? ($parts[0],undef,$parts[1])
      : @parts;
    
    $mnt = {
      driver => $driver || 'Filesystem',
      args   => $args
    };
    
    $mnt->{name} = $name if ($name); 
  }
  
  if(ref $mnt) {
    if(ref($mnt) eq 'HASH') {
      my $driver = $mnt->{driver} ? delete $mnt->{driver} : 'Filesystem';
      if($driver =~ /^\+/) {
        $driver =~ s/^\+//;
      }
      else {
        $driver = join('::','Rapi::Fs::Driver',$driver);
      }
      Module::Runtime::require_module($driver);
      $mnt = $driver->new($mnt);
    }
  }

  $mnt
}

has '_mounts_ndx', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  return { map { $_->name => $_ } @{$self->mounts} }
}, isa => HashRef;


sub get_mount {
  my ($self, $mount) = @_;
  $self->_mounts_ndx->{$mount} or die "No such mount '$mount'";
}

sub BUILD {}
after 'BUILD' => sub {
  my $self = shift;
  
  my @mounts = @{ $self->mounts };
  die "Must supply at least one Rapi::Fs::Driver mount in mounts!" if (@mounts == 0);
  
  my %seen = ();
  for(@mounts) {
    $seen{$_->name}++ and die join('',"Duplicate mount name '",$_->name,"'");
    $_->name =~ /^\s*$/ and die join('',"Bad mount name '",$_->name,"' - cannot be blank or empty");
    $_->name =~ /^[a-z0-9\-\_\(\)\]\[]+$/i or die join('',"Bad mount name '",$_->name,"' - only alpha chars allowed");
  }

  $self->_mounts_ndx; #init
};


## ----
## Our own, modified base64 encode/decode using '-' instead of '/'
#use MIME::Base64;
#
#sub b64_encode {
#  my $self = shift;
#  my $str = MIME::Base64::encode($_[0]);
#  $str =~ s/\//\-/g;
#  $str =~ s/\r?\n//g;
#  $str
#}
#
#sub b64_decode {
#  my $self = shift;
#  my $str = shift;
#  $str =~ s/\-/\//g;
#  MIME::Base64::decode($str)
#}
## ----

# ^^ Special base64 encoding not really needed at this point, 
#    turn off w/ raw passthrough:
#sub b64_encode { $_[1] }
#sub b64_decode { $_[1] }

use URI::Escape;

sub b64_encode { $_[1] }
sub b64_decode { uri_unescape($_[1]) }


sub Node_from_local_args {
  my $self = shift;
  
  my @largs = $self->local_args;
  
  unless (@largs > 0) {
    # Allow optional override using query-string param, useful when using an embedded call
    # for an iframe which is not navable
    my $qs_path = $self->c->req->params->{path} or return undef;
    @largs = split(/\//,$qs_path);
  }
  
  return undef unless (@largs > 0);
  
  my $mount = shift @largs;
  my $path  = scalar(@largs > 0) ? $self->b64_decode( join('/',@largs) ) : '/';
  
  try{ $self->get_mount($mount)->get_node($path) } or do {
    my $c = $self->c;
    $c->stash->{template} = 'rapidapp/http-404.html';
    $c->stash->{current_view} = 'RapidApp::Template';
    $c->res->status(404);
    $c->detach
  }
}


1;

__END__

=head1 NAME

Rapi::Fs::Module::Role::Mounts - Role for modules which use "Mounts"

=head1 DESCRIPTION

This role is used internally by L<Rapi::Fs::Module::FileTree> and should not need to be 
called directly.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Fs>

=item * 

L<RapidApp>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
