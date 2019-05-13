package Syntax::Feature::RawQuote;
use strict;
use warnings;
use Syntax::Keyword::RawQuote ();

BEGIN {
  our $VERSION = '0.04';
  our $AUTHORITY = 'cpan:ARODLAND';
}

sub install {
  my ($class, %args) = @_;
  Syntax::Keyword::RawQuote->import(%{ $args{"options"} || {}})
}

sub uninstall {
  Syntax::Keyword::RawQuote->unimport();
}

1;

__END__

=head1 NAME

Syntax::Feature::RawQuote - A raw quote operator for Perl ('use syntax' flavor)

=head1 SYNOPSIS

    use syntax 'raw_quote';
    say r`I keep all of my files in \\yourserver\private`;

    use syntax raw_quote => { -as => "qraw" };
    say qraw[Maybe the `r` keyword is too risky?];

=head1 DESCRIPTION

This library provides an interface to L<Syntax::Keyword::RawQuote> for the
L<syntax> module. You may also see L<Syntax::Keyword::RawQuote> directly. See
that module for more information.

=head1 WARNING

This is beta software that mucks about with the perl internals. Do not use
it for anything too important.

=head1 METHODS

=head2 install

Called by L<syntax> to enable the module when you do C<use syntax 'raw_quote'>.

=head2 uninstall

Called by L<syntax> to disable the module when you do C<no syntax 'raw_quote'>.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 LICENSE

Copyright (c) Andrew Rodland.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
