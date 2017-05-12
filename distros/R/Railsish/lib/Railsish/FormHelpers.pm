package Railsish::FormHelpers;
our $VERSION = '0.21';

# ABSTRACT: Using for generate tags related to form in application view

use strict;
use warnings;

sub form_tag ($;@&) {
  my $code = ( ref($_[-1]) eq "CODE" ? pop(@_) : undef );
  my ($target, %options) = @_;

  my $result = "<form action=\"$target\">" ;

  for (keys %options) {
    $result =~ s/>$/ $_=\"$options{$_}\"\>/
  }

  $result .= $code->() if defined($code);
  $result .= '</form>';
  $result;
}

sub submit_tag {
  return "<input type=\"submit\" value=\"submit\" />"
}


1;

__END__
=head1 NAME

Railsish::FormHelpers - Using for generate tags related to form in application view

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

