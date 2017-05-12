# pp2latex tags

package PerlPoint::Tags::LaTeX;

$VERSION = sprintf("%d.%02d", q/$Revision: 1.1 $/ =~ /(\d+)\.(\d+)/);

use base qw(PerlPoint::Tags);
use strict;

use PerlPoint::Constants qw(:tags);
use vars qw(%tags %sets);

%tags = (

            MBOX => {
                   'options' => TAGS_OPTIONAL,
                   'body'    => TAGS_MANDATORY,
               },


  
);

1;

__END__

=head1 NAME

B<PerlPoint::Tags::LaTeX> - PerlPoint tag set used by pp2latex

=head1 SYNOPSYS

 # declare tags used by pp2latex
 use PerlPoint::Tags::LaTeX;

=head1 DESCRIPTION

This module declares PerlPoint tags used by C<pp2latex>. Tag
declarations are used by the parser to determine if a used
tag is valid, if it needs options, if it needs a body and
so on. Please see B<PerlPoint::Tags> for a detailed
description of tag declaration.

Every PerlPoint translator willing to handle the tags of
this module can declare this by using the module in the
scope where it built the parser object.

 # declare basic tags
 use PerlPoint::Tags::LaTeX

 # load parser module
 use PerlPoint::Parser;

 ...

 # build parser
 my $parser=new PerlPoint::Parser(...);

 ...

=head1 TAGS

=over 4

=item B<\MBOX><text in mbox>

Tag for creating an \mbox{ ... } environment.

=back

=head1 TAG SETS

No sets are currently defined.

=head1 SEE ALSO

=over 4

=item B<PerlPoint::Tags>

The tag declaration base "class".

=item B<PerlPoint::Tags::Basic>

Basic Tags imported by C<pp2latex>.

=back

=head1 AUTHOR

Lorenz Domke <logenz.domke@gmx.de>


=cut

$Log: LaTeX.pm,v $
Revision 1.1  2001/11/30 00:46:30  lorenz
new cvs version

Revision 1.1  2001/06/14 12:00:56  lorenz
Initial revision

