package Rapi::Blog::PreAuth::Actor::Error;
use strict;
use warnings;

# ABSTRACT: Base error class for preauth Actors

use Moo;
extends 'Rapi::Blog::PreAuth::Actor';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use Scalar::Util 'blessed';

# just to override:
has 'PreauthAction', is => 'ro', init_arg => undef, default => sub {undef};
has 'ctx', is => 'ro', required => 0;

has 'title',    is => 'ro', isa => Maybe[Str], default => sub{undef};
has 'subtitle', is => 'ro', isa => Maybe[Str], default => sub{undef};

sub class_name {
  my $self = shift;
  blessed $self || $self;
}

sub BUILD {
  my $self = shift;
  $self->info or $self->info( $self->_default_error_info )
}

use overload '""' => 'stringify';

sub stringify {
  my $self = shift;
  $self->info || $self->_default_error_info
}

sub _default_error_info {
  my $self = shift;
  my $type = $self->error_type || $self->class_name;
  "Actor: unspecified '$type' error\n"
}


sub is_error { 1 }

sub error_type {
  my $self = shift;
  my $class = $self->class_name;
  (split(/Rapi::Blog::PreAuth::Actor::Error::/,$class,2))[1];
}

sub throw {
  my ($self,@args) = @_;
  
  # first argument can be a scalar/string (used as default 'info' option):
  my $msg = (defined $args[0] && ! ref($args[0])) ? (shift @args) : undef;
  
  # and still allow additional arguments as key/vals:
  my %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  $opts{info} ||= $msg || $self->_default_error_info;
  
  die $self->new(\%opts)
}


sub execute      { die (shift) }
sub call_execute { die (shift) }


1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Action::Error - Base action error class


=head1 DESCRIPTION

This is an internal class and is not intended to be used directly. 

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
