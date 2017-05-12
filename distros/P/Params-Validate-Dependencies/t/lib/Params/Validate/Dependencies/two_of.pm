package Params::Validate::Dependencies::two_of;
use strict;
use warnings;

use vars qw(@EXPORT @EXPORT_OK);

use base qw(Exporter Params::Validate::Dependencies::Documenter);

@EXPORT_OK = @EXPORT = qw(two_of);

sub join_with { return 'or'; }
sub name { return 'two_of'; }

sub two_of {
  my @options = @_;
  bless sub {
    if($Params::Validate::Dependencies::DOC) { return $Params::Validate::Dependencies::DOC->_doc_me(list => \@options); }
    my $hashref = shift;
    my $count = 0;
    foreach my $option (@options) {
      $count++ if(
        (!ref($option) && exists($hashref->{$option})) ||
        (ref($option) && $option->($hashref))
      );
    }
    return ($count == 2);
  }, __PACKAGE__;
}

1;
