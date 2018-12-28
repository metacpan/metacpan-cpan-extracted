package PkgConfig::LibPkgConf::Fragment;

use strict;
use warnings;
use overload '""' => sub { shift->to_string };

our $VERSION = '0.10';

=head1 NAME

PkgConfig::LibPkgConf::Fragment - Single compiler or linker flag

=head1 SYNOPSIS

 use PkgConfig::LibPkgConf::Client;
 
 my $client = PkgConfig::LibPkgConf::Client->new;
 $client->scan_all(sub {
   my($client, $package) = @_;
   # $package isa PkgConfig::LibPkgConf::Package
   foreach my $frag ($package->list_libs)
   {
     # $frag isa PkgConfig::LibPkgConf::Fragment
     if($frag->type eq 'L')
     {
       say "Library directory: ", $frag->data;
     }
     elsif($frag->type eq 'l')
     {
       say "Library name: ", $frag->data;
     }
   }
 });
 
=head1 DESCRIPTION

TODO

=head1 ATTRIBUTES

=head2 type

 my $type = $frag->type;

The type of the flag.  This may be C<undef> if there is no type.

=cut

sub type { shift->{type} }

=head2 data

 my $data = $frag->data;

The data for the fragment.

=cut

sub data { shift->{data} }

=head2 to_string

 my $string = $frag->to_string;
 my $string = "$frag";

The string representation of the fragment.  You may also interpolate the
fragment object inside a string to convert it into a string.

=cut

sub to_string
{
  my($self) = @_;
  my($type, $data) = ($self->type, $self->data);
  $data =~ s/\\(\s)/$1/g;
  $type ? "-$type$data" : $data;
}

=head1 SUPPORT

IRC #native on irc.perl.org

Project GitHub tracker:

L<https://github.com/plicease/PkgConfig-LibPkgConf/issues>

If you want to contribute, please open a pull request on GitHub:

L<https://github.com/plicease/PkgConfig-LibPkgConf/pulls>

=head1 SEE ALSO

For additional related modules, see L<PkgConfig::LibPkgConf>

=head1 AUTHOR

Graham Ollis

For additional contributors see L<PkgConfig::LibPkgConf>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
