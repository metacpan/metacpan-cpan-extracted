#!/bin/false
package SVN::Web::X;

use strict;
use warnings;

our $VERSION = 0.54;

use Exception::Class ( 'SVN::Web::X' => { fields => ['vars'], }, );

1;

__END__

=head1 NAME

SVN::Web::X - exceptions for SVN::Web

=head1 SYNOPSIS

  use SVN::Web::X;

  ...

  SVN::Web::X->throw(error => '(error message %1)',
                     vars => [$var_to_interpolate]);

=head1 DESCRIPTION

SVN::Web::X implements exceptions for SVN::Web.  Derived from
Exception::Class, It provides a simple mechanism for throwing
exceptions, catching them, and ensuring that friendly, localised error
messages are generated and sent to the user's browser.

=head1 USAGE IN SVN::Web ACTIONS

If an SVN::Web action that you are writing needs to stop processing
and raise an error, throw an SVN::Web::X exception.

C<throw()> takes a hash with two mandatory keys.

=over 4

=item C<error>

A string describing the error.  This string should be short, and key
to a longer internationalised message.

This string may contain placeholders; %1, %2, %3, and so on.  These
will be replaced by the values of the variables passed in the C<vars>
key.

By convention this string should be enclosed in parentheses, C<(> and
C<)>.  This helps make them stand out in the interface, if localised
versions of the error message have not yet been written.

=item C<vars>

An array reference.  The first entry in the array will replace the C<%1>
placeholder in C<error>, the second entry will replace the C<%2> placeholder,
and so on.

If there are no placeholders then pass a reference to an empty array.

=back

=head1 EXAMPLES

=head2 A simple exception, with no placeholders.

In the action:

  sub run {
      ...
      if(! frob_repo()) {
	  SVN::Web::X->throw(error => '(frob failed)',
                             vars  => []);
      }
      ...
  }

In the F<en.po> file for the localised text.

  msgid "(frob failed)"
  msgstr "There was a problem trying to frob the repository.  This "
  "probably indicates a permissions problem."

=head2 An exception with placeholders

In the action:

  sub run {
      ...
      # $path is a repo path, $rev is a repo revision
      my $root = $fs->revision_root($rev);
      my $kind = $root->check_path($path);

      if($kind == $SVN::Node::none) {
	  SVN::Web::X->throw(error => '(path %1 does not exist in rev %2)',
                             vars  => [$path, $rev]);
      }
  }

In the F<en.po> file for the localised text.

  msgid "(path %1 does not exist in rev %2)"
  msgstr "The path <tt>%1</tt> could not be found in the repository "
  "at revision %2.  This may be a typo in the path or the revision "
  "number.  SVN::Web should never normally generate a link like this. "
  "If you followed a link from SVN::Web (rather than from an e-mail,
  "or similar) please report this as a bug."

As you can see, the localised text can be much friendlier and more
informative to the user than the error message.

=head1 COPYRIGHT

Copyright 2003-2004 by Chia-liang Kao C<< <clkao@clkao.org> >>.

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

Copyright 2012 by Dean Hamstead C<< <dean@fragfest.com.au> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
