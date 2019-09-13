package Rapi::Blog::PreAuth::Actor;
use strict;
use warnings;

# ABSTRACT: Base class for preauth Actors

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;

# Catalyst context:
has 'ctx', is => 'ro', required => 1;

has 'PreauthAction',
  is       => 'ro',
  required => 1,
  isa => InstanceOf['Rapi::Blog::DB::Result::PreauthAction'];

has 'info',      is => 'rw', default => sub { '' } , isa => Str; 

# If and what template the controller should render after execution
has 'render_template', is => 'rw', default => sub { undef } , isa => Maybe[Str];

# Where the controller should redirect the user to after execution
#  This takes priority over 'render_template' so child Actors should override
#  the base setiing which is to just redirect the user to the site root
has 'redirect_url',    is => 'rw', default => sub { '/' } ,   isa => Maybe[Str];

sub req_params { (shift)->ctx->request->params }

sub is_error   { 0 }
sub error_type { '' }

sub execute { ... }


sub call_execute {
  my $self = shift;
  
  my $ret = 0;
  try {
    $ret = $self->execute
  }
  catch {
    my $err = shift;
    $ret = 0;
    $self->info( "$err" )
  };
  
  $self->post_execute;

  $ret
}


sub post_execute {
  my $self = shift;
  $self->PreauthAction->_record_executed( $self->info )
}




1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Actor - Base class for preauth Actors


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

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
