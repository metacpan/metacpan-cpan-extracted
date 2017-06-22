package Rapi::Blog::Util::Rabl;
use strict;
use warnings;

# ABSTRACT: Base class for rabl.pl modules

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util ':all';
require Module::Runtime;
require Module::Locate;

use Pod::Usage;
use Pod::Find qw(pod_where);

# 'create' becomes 'Rapi::Blog::Util::Rabl::Create'
sub resolve_classname {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $name = shift;
  
  die "bad argument '$name'" unless ($name =~ /^\w/); # starts with a word char
  
  $name =~ s/_/-/g;
  my $subclass = join('',map { ucfirst(lc($_)) } split(/-/,$name)); 
  
  my $class = join('::',__PACKAGE__,$subclass);
  unless(scalar Module::Locate::locate($class)) {
    die "no such Rabl module '$name' ($class not found)\n";
  }
  
  Module::Runtime::require_module($class);

  $class
}

sub argv_call {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $module = shift @ARGV;
  my $class = &resolve_classname($module);
  return $class->usage if ($ARGV[0] && $ARGV[0] eq '--help');
  $class->call(@ARGV)
}

sub call { ... }


sub usage {
  my $class = shift;

  pod2usage( 
    $class ? (-input => pod_where({-inc => 1}, $class)) : (),
    -verbose  => 99,
    -sections => 'NAME|SYNOPSIS|DESCRIPTION'
  );
  exit;
}


1;


__END__

=head1 NAME

Rapi::Blog::Util::Rabl - Base class for rabl.pl modules


=head1 DESCRIPTION

This is an internal base class and is not intended to be used directly. See L<rabl.pl>

=head1 SEE ALSO

=over

=item * 

L<rabl.pl>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
