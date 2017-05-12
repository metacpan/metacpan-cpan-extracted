package Data::Domain::Dependencies;

use strict;
use warnings;

use Params::Validate::Dependencies qw(:_of exclusively);
use Scalar::Util qw(blessed);
use Exporter qw(import);

use base qw(Data::Domain);

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '1.30';

@EXPORT = ();
@EXPORT_OK = (
  @{$Params::Validate::Dependencies::EXPORT_TAGS{_of}},
  qw(exclusively Dependencies)
);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Data::Domain::Dependencies

=head1 DESCRIPTION

A sub-class of Data::Domain which provides functions and objects
to let Data::Domain use the same
functions as Params::Validate::Dependencies.

NB this probably only works on perl versions 5.10 to 5.22 as modern
versions of Data::Domain don't cleanly install that range.

=head1 SYNOPSIS

This creates a domain which, when passed a hashref to inspect, will
check that it contains at least one of an 'alpha' or 'beta' key, or
both of 'foo' and 'bar'.

  use Data::Domain::Dependencies qw(:all);

  my $domain = Dependencies(
    any_of(
      qw(alpha beta),
      all_of(qw(foo bar))
    )
  );

  my $errors = $domain->inspect(\%somehash);

=head1 SUBROUTINES and EXPORTS

Nothing is exported by default, but you can export any of the *_of
functions of Params::Validate::Dependencies, and the 'Dependencies'
and 'exclusively' functions. They are all available under the 'all' tag.

=head2 Dependencies

This takes a code-ref argument as returned by the *_of functions.

It returns an object which is a sub-class of Data::Domain::Dependencies
and so has an 'inspect' method that you can use to check for errors
when passing it a hash-ref.

=cut

sub Dependencies {
  my $sub = shift;
  __PACKAGE__->new($sub);
}

=head2 new

'Dependencies' above is really just a thin wrapper around this
constructor.  You are encouraged to not call this directly.

=cut

sub new {
  my($class, $sub) = @_;
  die("$class constructor must be passed a Params::Validate::Dependencies object or a code-ref\n")
    unless(ref($sub) =~ /CODE/ || (blessed($sub) && $sub->isa('Params::Validate::Dependencies::Documenter')));
  if(blessed($sub)) {
    my $target_class = "${class}::".$sub->name();
    no strict 'refs';
    unless(@{"${target_class}::ISA"}) {
      # multiple inheritance so we can get at Data::Domain->inspect()
      # and Params::Validate::Dependencies::Documenter->_document()
      @{"${target_class}::ISA"} = (
        'Data::Domain::Dependencies',
        blessed($sub)
      );
    }
    return bless sub { $sub->(@_) }, $target_class;
  } else {
    return bless sub { $sub->(@_) }, $class;
  }
}

=head2 generate_documentation

This is an additional method, not found in Data::Domain, which
generates vaguely readable
documentation for the domain.  Broadly speaking, it spits out the
source code.

=cut

sub generate_documentation {
  my $self = shift;
  $self->_document();
}

# this is where the magic happens ...
sub inspect {
  my $sub = shift;
  my $data = shift;
  return __PACKAGE__." can only inspect hashrefs\n"
    unless(ref($data) =~ /HASH/i);

  return $sub->($data) ? () : __PACKAGE__.": validation failed";
}

=head1 LIES

Some of the above is incorrect.  If you really want to know what's
going on, look at L<Params::Validate::Dependencies::Extending>.

=head1 BUGS, LIMITATIONS, and FEEDBACK

I like to know who's using my code.  All comments, including constructive
criticism, are welcome.

Please report any bugs either by email or using L<http://rt.cpan.org/>
or at L<https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies/issues>.

Bug reports should contain enough detail that I can replicate the
problem and write a test.  The best bug reports have those details
in the form of a .t file.  If you also include a patch I will love
you for ever.

=head1 SEE ALSO

L<Params::Validate::Dependencies>

L<Data::Domain>

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Params-Validate-Dependencies.git>

L<https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies/>

=head1 COPYRIGHT and LICENCE

Copyright 2011 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason.

=cut

1;
