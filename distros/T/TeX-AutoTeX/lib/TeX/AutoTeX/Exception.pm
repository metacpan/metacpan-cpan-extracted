package TeX::AutoTeX::Exception;

#
# $Id: Exception.pm,v 1.7.2.7 2011/01/27 18:42:27 thorstens Exp $
# $Revision: 1.7.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Exception.pm,v $
#
# $Date: 2011/01/27 18:42:27 $
# $Author: thorstens $
#

use strict;
### use warnings;

our ($VERSION) = '$Revision: 1.7.2.7 $' =~ m{ \$Revision: \s+ (\S+) }x;

use parent qw(Error);
use overload (q{""} => 'stringify');

sub new {
  my $self = shift;
  my $text = shift() . "\n";
  my @args = ();

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $self->SUPER::new(-text => $text, @args);
}
1;

package TeX::AutoTeX::FatalException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::FormatException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::InvNameException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::MissfontException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::TexChrException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::TexMFCnfException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::TypeException;
use parent qw(TeX::AutoTeX::Exception);
1;
package TeX::AutoTeX::WorkdirException;
use parent qw(TeX::AutoTeX::Exception);
1;

=for stopwords arxiv.org arXiv.org Schwander perlartistic www-admin

=head1 NAME

TeX::AutoTeX::Exception - framework for exception handling in TeX::AutoTeX

=head1 DESCRIPTION

This is the base class for exception handling. The idea is to subclass this
for specific error conditions. Each of the Exception classes (stubs) above
can be customized individually to meet specific needs. More types can be
easily added if necessary.

=head1 METHODS

=head2 new

Instantiate an Exception object with customization of the textual
representation of the error message.

=head1 BUGS AND LIMITATIONS

Using the C<Error> module is no longer recommended. Exception handling should be
migrated to something like C<Try::Tiny> or C<Error::TryCatch>.

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

Thorsten Schwander for L<arXiv.org|http://arXiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2010 arxiv.org L<http://arXiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
