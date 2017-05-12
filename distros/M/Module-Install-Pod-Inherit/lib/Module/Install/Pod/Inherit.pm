package Module::Install::Pod::Inherit;
# I haven't tested this code this far back, but I know of know reason that it shouldn't work.
# It won't work on anything older, because I use 'our'.
use 5.008_000;
use warnings;
use strict;
use Pod::Inherit;
use base 'Module::Install::Base';
our $VERSION = '0.01';


sub PodInherit {
  my ($self) = @_;
  
  # Note to self: Careful of your \t vs '    '
  $self->postamble(<<"EOPOST");
# Can't do this, because there's nothing in the "make dist" chain that's a double-colon rule.
# In make, you need extendable rules to be *explicitly* extendable.
# distdir :: podinherit_lib

pure_all :: podinherit_blib

# Originally we depended on pure_all here, but that makes it run *after* manifypods, which is Not Good.
podinherit_blib : pm_to_blib
	\$(PERLRUN) -I\$(INST_LIB) -MPod::Inherit -e'Pod::Inherit->new({input_files=>"blib/", force_permissions=>1})->write_pod'

EOPOST
}


=head1 NAME

Module::Install::Pod::Inherit - Make your distribution's POD link to where inherited methods come from, the easy way (if you use M::I).

=head1 SYNOPSIS

  use Module::Install::Pod::Inherit
  
  PodInherit();

  WriteAll;

=head1 DESCRIPTION

One problem with modern perl code with fairly deep, or complex,
inheritence trees is that users don't know where to look for
documentation; they think they have a Foo::Bar object, and don't know
to look fo the docs in
Foo::Bar::Role::Server::Cute::Uniform::Red::Hair.  L<Pod::Inherit> was
written to fix that.  This module is a small wrapper around
L<Pod::Inherit> to make it easy to use, at least for distributions
based around L<Module::Install>.  It also forces the author of
Module::Install::Pod::Inherit to worry about how to make it work best,
rather then you, who just wants to have docs that are easy to understand.

=head1 BUGS

Should run across lib during "make dist" time, but I can't figure out how to do that.

Probably more lurking.

=head2 LICENSE

Copyright 2009, James Mastros, AKA theorbtwo.  Released under the same
terms as Perl itself.  It is based upon
Module-Install-DBICx-AutoDoc-0.03, copyright 2008, Jason M. Mills
(under the same license).
