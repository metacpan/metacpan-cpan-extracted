package Socialtext::WikiObject::Factory;
use strict;
use warnings;
use Carp qw/croak/;

=head1 NAME

Socialtext::WikiObject::Factory - Create an approprate WikiObject from Magic Tags

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  # Set a magic tag to define WikiObject subclass
  $rester->put_page($page_name, $page_text);
  $rester->put_pagetag($page_name, '.wikiobject=YAML');

  # Use the factory to create the appropriate class
  my $wo = Socialtext::WikiObject::Factory->new(
               rester => $rester,
               page => $page_name,
           );
  isa_ok $wo, 'Socialtext::WikiObject::YAML';

=head1 DESCRIPTION

Socialtext::WikiObject::Factory reads magic tags on a page, and then
creates a WikiObject of the appropriate class, as defined in the magic tag.

=head1 FUNCTIONS

=head2 new( %opts )

Create a new wiki object.  Options:

=over 4

=item rester

Users must provide a Socialtext::Resting object setup to use the desired 
workspace and server.

=item page

The page to load.  Mandatory.

=back

=cut

sub new {
   my (undef, %opts) = @_;
   croak "rester is mandatory!" unless $opts{rester};
   croak "page is mandatory!" unless $opts{page};

   my $class = 'Socialtext::WikiObject';

   my $rester = $opts{rester};
   my @tags = $rester->get_pagetags($opts{page});
   for my $t (@tags) {
       if ($t =~ m/^\.wikiobject=(.+)$/) {
           $class .= '::' . ucfirst($1);
           last;
       }
   }

   eval "require $class";
   die if $@;
   return $class->new(%opts);
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
