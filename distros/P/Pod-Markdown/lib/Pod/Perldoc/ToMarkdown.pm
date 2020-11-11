#
# This file is part of Pod-Markdown
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Pod::Perldoc::ToMarkdown;
our $AUTHORITY = 'cpan:RWSTAUNER';
$Pod::Perldoc::ToMarkdown::VERSION = '3.300';
# ABSTRACT: Enable `perldoc -o Markdown`

use parent qw(Pod::Markdown);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(
    # Pod::Perldoc does not pass any options by default
    # but will call setters if attributes are passed on command line.
    # I don't know what encoding it expects, but it needs one, so default to UTF-8.
    output_encoding => 'UTF-8',
    @_,
  );
  return $self;
}

sub parse_from_file {
  my $self = shift;
  # Instantiate if called as a class method.
  $self = $self->new if !ref $self;

  # Skip over SUPER's override and go up to grandpa's method.
  $self->Pod::Simple::parse_from_file(@_);
}

# There are several other methods that we could implement that Pod::Perldoc
# finds interesting:
# * output_is_binary
# * name
# * output_extension

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Marcel Gruenauer Victor Moral Ryan C. Thompson <rct at thompsonclan d0t
org> Aristotle Pagaltzis Randy Stauner ACKNOWLEDGEMENTS

=head1 NAME

Pod::Perldoc::ToMarkdown - Enable `perldoc -o Markdown`

=head1 VERSION

version 3.300

=for test_synopsis 1;
__END__

=head1 SYNOPSIS

  perldoc -o Markdown Some::Module

=head1 DESCRIPTION

Pod::Perldoc expects a Pod::Parser compatible module,
however Pod::Markdown did not historically provide an entirely Pod::Parser
compatible interface.

This module bridges the gap.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Victor Moral <victor@taquiones.net>

=item *

Ryan C. Thompson <rct at thompsonclan d0t org>

=item *

Aristotle Pagaltzis <pagaltzis@gmx.de>

=item *

Randy Stauner <rwstauner@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
