package Siesta::Plugin::MessageFooter;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Siesta;

use Sys::Hostname;


sub description {
    'Add a message footer';
}



sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    # get the raw footer or return
    my $rawfooter = $self->pref('footer') || return 0;


    # from 
    # http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/mailman/mailman/Mailman/Handlers/Decorate.py
    my %vars = (  'real_name'      => $list->name,
                  'list_name'      => $list->name,
                  # For backwards compatibility
                  '_internal_name' => $list->name,
                  'host_name'      => $self->pref('host_name'),
                  'web_page_url'   => $self->pref('web_page_url'),
                  'description'    => $self->pref('description'),
                  'info'           => $self->pref('info'),
                  'cgiext'         => $self->pref('cgiext'),
                  'list'           => $list,

            );
    

    # bake it
    my $footer    = Siesta->bake(\$rawfooter, %vars);
    
    # and add it to the end of the mail
    $mail->body_set($mail->body()."\n$footer");

    # and bug out
    return 0;
}

sub options {
    +{
      'footer'
      => {
          'description' =>
          'a footer to add to the end of every mail. See Siesta::Plugin::MessageFooter for more details',
          'type'    => 'text',
          'default' => '',
          'widget'  => 'textbox',
         },
      'host_name'
      => {
          'description' => 
           'the hostname (default is the hostname worked out by Sys::Hostname)',
          'type'    => 'text',
          'default' => hostname,
          'widget'  => 'textbox',
         },
      'web_page_url'
      => {
          'description' =>
          'the url of of the list web page',
          'type'    => 'text',
          'default' => '',
          'widget'  => 'textbox',
         },
      'cgiext'
      => {
          'description' =>
          'cgi extension',
          'type'    => 'text',
          'default' => '',
          'widget'  => 'textbox',
         },

      'description'
      => {
          'description' =>
          'a short description of the list',
          'type'    => 'text',
          'default' => '',
          'widget'  => 'textbox',
         },
      'info'
      => {
          'description' =>
          'a longer description of the list',
          'type'    => 'text',
          'default' => '',
          'widget'  => 'textbox',
         },
     };
}

1;

=pod
              
=head1 NAME

Siesta::Plugin::MessageFooter - add a configurable footer to the end of every mail.
    
=head1 SYNOPSIS
    
    The   [% real_name %] list :
    Web   [% web_page_url %]
    Owner [% list.owner.email %]
      
=head1 DESCRIPTION

This allows you to put configurable footers at the end of every mail.

The variables passed to the I<Template::Toolkit> style footer are listed below.

Most are provided for Mailman backwards compatability.

=over 4

=item real_name 

The name of the list

=item list_name

ditto

=item _internal_name

erm, ditto again

=item host_name

The 'host_name' preference or the system's hostname as worked out 
by I<Sys::Hostname>.

The hostname preference can be set using the web interface or by using 

    % nacho modify-plugin MessageFooter <list name> host_name <insert your hostname here>

=item web_page_url

The 'web_page_url' preference.

=item description

The 'description' preference.

=item list

A copy of the list object that this plugin is being called from.

=back
          
=head1 COPYRIGHT
          
(c)opyright 2003 - The Siesta Dev Team
          
=cut

