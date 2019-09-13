package Rapi::Blog::Model::Mailer;

use Moose;
extends 'Catalyst::Model';

use strict;
use warnings;

# ABSTRACT: Common interface for sending E-Mails

use RapidApp::Util qw(:all);

require Module::Runtime;

use Rapi::Blog::Util::Mailer;

use Email::MIME::CreateHTML;

before 'COMPONENT' => sub {
  my $class = shift;
  my $app_class = ref $_[0] || $_[0];
  
  my $cust_cnf = try{$app_class->config->{'Model::Mailer'}} || {};
 
  $class->config(
    # Allow user-defined config overrides:
    %$cust_cnf
 );
  
};




sub send_mail {
  my $self = shift;
  my %opt = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref

  if(blessed($opt{to}) and $opt{to}->can('email')) {
    my $User = $opt{to};
    
    my $email = $User->email or die "This user does not have an E-Mail address on file.";
    $opt{to} = $User->full_name 
      ? join('','"',$User->full_name,'" <',$User->email,'>')
      : $User->email;
  }
  
  
  %opt = (%{$self->config},%opt);
  
  Rapi::Blog::Util::Mailer->send(\%opt)
}




__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Rapi::Blog::Model::Mailer - Common interface for sending E-Mails

=head1 SYNOPSIS

See L<Rapi::Blog>

=head1 DESCRIPTION

This model provides the interface used to generate all E-Mails from the system


=head1 CONFIGURATION

TBD

=head1 METHODS

TBD

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



