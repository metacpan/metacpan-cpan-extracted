package Software::License::PublicDomain;
{
  $Software::License::PublicDomain::VERSION = '0.1';
}
use strict;
use warnings;
use parent 'Software::License';

# ABSTRACT: A Public Domain "License"
 
sub name      { q(Public Domain) }
sub url       { q{http://en.wikipedia.org/wiki/Public_domain} }
 
sub meta_name  { 'unrestricted' }
sub meta2_name { 'unrestricted' }
 
1;

=pod

=encoding UTF-8

=head1 NAME

Software::License::PublicDomain - A Public Domain "License"

=head1 VERSION

version 0.1

=head1 NAME

Software::License::PublicDomain - A Public Domain "License"

=head1 WARNING

B<You should really think hard before using any other license.>

This "license" is provided for those who want to place their software into the
public domain.  This is the natural result of publishing something to the
world.  Any true license (of which Public Domain is not) is an endorsement of
monopolies and the use of force and coercion to control what other people do
with published information.

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE

This work is in the public domain and is not subject to restriction or control
via any copyright system.  It is available as-is and comes with no guarantee
whatsoever.

=cut

__DATA__
__NOTICE__
This work is in the public domain and is not subject to restriction or control
via any copyright system.  It is available as-is and comes with no guarantee
whatsoever.

__LICENSE__
Do what you want.  This is in the Public Domain.
