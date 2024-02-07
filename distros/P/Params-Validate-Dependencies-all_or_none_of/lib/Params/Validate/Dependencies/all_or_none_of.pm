package Params::Validate::Dependencies::all_or_none_of;

use strict;
use warnings;

use base qw(Exporter Params::Validate::Dependencies::Documenter);

use vars qw($VERSION @EXPORT @EXPORT_OK);

$VERSION = '1.02';
@EXPORT_OK = @EXPORT = ('all_or_none_of');

=head1 NAME

Params::Validate::Dependencies::all_or_none_of - validate that either all or none of a list of params are present

=head1 SYNOPSIS

In this example, the 'foo' function takes named arguments, of which
the 'day', 'month', and 'year' args must either all be present or
none of them be present.

  use Params::Validate::Dependencies qw(:all);
  use Params::Validate::Dependencies::all_or_none_of;

  sub foo {
    validate(@_,
      { ... normal Params::Validate stuff ...},
      all_or_none_of(qw(day month year))
    );
  }

=head1 SUBROUTINES and EXPORTS

=head2 all_or_none_of

This is exported by default.  It takes a list of scalars and code-refs
and returns a code-ref which checks that the hashref it receives matches
either all or none of the options given.

=cut

sub all_or_none_of {
  my @options = @_;
  return bless sub {
    my $hashref = shift;
    if($Params::Validate::Dependencies::DOC) {
      return $Params::Validate::Dependencies::DOC->_doc_me(list => \@options);
    }
    my $count = 0;
    foreach my $option (@options) {
      $count++ if(
        (!ref($option) && exists($hashref->{$option})) ||
        (ref($option) && $option->($hashref))
      );
    }
    return ($count == 0 || $count == $#options + 1);
  }, __PACKAGE__;
}

sub join_with { return 'and'; }
sub name      { return 'all_or_none_of'; }

=head1 LIES

Some of the above is incorrect.  If you really want to know what's
going on, look at L<Params::Validate::Dependencies::Extending>.

=head1 BUGS, LIMITATIONS, and FEEDBACK

I like to know who's using my code.  All comments, including constructive
criticism, are welcome.

Please report any bugs either by email
or at L<https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies/issues>.

Bug reports should contain enough detail that I can replicate the
problem and write a test.  The best bug reports have those details
in the form of a .t file.  If you also include a patch I will love
you for ever.

=head1 SEE ALSO

L<Params::Validate::Dependencies>

L<Data::Domain::Dependencies>

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Params-Validate-Dependencies-all_or_none_of.git>

L<https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies-all_or_none_of/>

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason.

=cut

1;
