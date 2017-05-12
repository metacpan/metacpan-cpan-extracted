package TSQL::Common::Regexp;

use 5.010;
use strict;
use warnings;

=head1 NAME

TSQL::Common::Regexp - Contains regexps common across TSQL::AST and TSQL::SplitStatement

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


sub qr_id               { return q{(?:[#_\w$@][#$:_.\w]*)} ; } ;
sub qr_label            { return q{(?:[#_\w$@][#$:_.\w]*[:])} ; } ;

sub qr_begintoken       { return q{(?xi:\A \s* (?:\b begin \b) \s* \z ) }                    ; } ;
sub qr_endtoken         { return q{(?xi:\A \s* (?:\b end \b) \s* \z ) }                      ; } ;
sub qr_begintrytoken    { return q{(?xi:\A \s* (?:\b begin \b \s+ \b try \b ) \s* \z ) }     ; } ;
sub qr_endtrytoken      { return q{(?xi:\A \s* (?:\b end \b \s+ \b try \b ) \s*  \z ) }      ; } ;
sub qr_begincatchtoken  { return q{(?xi:\A \s* (?:\b begin \b  \s+ \b catch \b) \s*  \z ) }  ; } ;
sub qr_endcatchtoken    { return q{(?xi:\A \s* (?:\b end \b  \s+ \b catch \b) \s*  \z ) }    ; } ;
sub qr_iftoken          { return q{(?xi:\A \s* (?:\b if \b) ) }                              ; } ;
sub qr_elsetoken        { return q{(?xi:\A \s* (?:\b else \b) ) }                            ; } ;
sub qr_GOtoken          { return q{(?xi:\A \s* (?:\b go \b) ) }                              ; } ;
sub qr_whiletoken       { return q{(?xi:\A \s* (?:\b while \b) ) }                           ; } ;


sub qr_createproceduretoken     { return q{(?xi:\A \s* (?: \b create \s+ proc (?:edure)? \b) ) }   ; } ;
sub qr_alterproceduretoken      { return q{(?xi:\A \s* (?: \b alter  \s+ proc (?:edure)? \b) ) }   ; } ;

sub qr_createtriggertoken       { return q{(?xi:\A \s* (?: \b create \s+ trigger \b) ) }           ; } ;
sub qr_altertriggertoken        { return q{(?xi:\A \s* (?: \b alter  \s+ trigger \b) ) }           ; } ;


sub qr_createviewtoken          { return q{(?xi:\A \s* (?: \b create \s+ view \b) ) }                ; } ;
sub qr_alterviewtoken           { return q{(?xi:\A \s* (?: \b alter  \s+ view \b) ) }                ; } ;


sub qr_createfunctiontoken      { return q{(?xi:\A \s* (?: \b create \s+ function \b) ) }          ; } ;
sub qr_alterfunctiontoken       { return q{(?xi:\A \s* (?: \b alter  \s+ function \b) ) }          ; } ;

1;

__DATA__


=head1 SYNOPSIS

This is a simple module supporting TSQL::SplitStatement and TSQL::AST.

=head1 DESCRIPTION

Contains common regular expressions.

=head1 DEPENDENCIES

=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tsql-common-regexp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TSQL::Common::Regexp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 METHODS

=head2 C<qr_label>

=over 4

=item * C<< TSQL::Common::Regexp->qr_label() >>

=back

This returns a regexp to match a TSQL label token.

=head2 C<qr_id>

=over 4

=item * C<< TSQL::Common::Regexp->qr_id() >>

=back

This returns a regexp to match a TSQL id token.

=head2 C<qr_begintoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_begintoken() >>

=back

This returns a regexp to match a TSQL BEGIN token.


=head2 C<qr_endtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_endtoken() >>

=back

This returns a regexp to match a TSQL END token.


=head2 C<qr_begintrytoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_begintrytoken() >>

=back

This returns a regexp to match a TSQL BEGIN TRY token.


=head2 C<qr_endtrytoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_endtrytoken() >>

=back

This returns a regexp to match a TSQL END TRY token.


=head2 C<qr_begincatchtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_begincatchtoken() >>

=back

This returns a regexp to match a TSQL BEGIN CATCH token.


=head2 C<qr_endcatchtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_endcatchtoken() >>

=back

This returns a regexp to match a TSQL END CATCH token.


=head2 C<qr_iftoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_iftoken() >>

=back

This returns a regexp to match a TSQL IF token.


=head2 C<qr_elsetoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_elsetoken() >>

=back

This returns a regexp to match a TSQL ELSE token.


=head2 C<qr_GOtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_GOtoken() >>

=back

This returns a regexp to match a TSQL GO token.


=head2 C<qr_whiletoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_whiletoken() >>

=back

This returns a regexp to match a TSQL WHILE token.





=head2 C<qr_createproceduretoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_createproceduretoken() >>

=back

This returns a regexp to match the start of a TSQL CREATE PROCEDURE statement.

=head2 C<qr_alterproceduretoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_alterproceduretoken() >>

=back

This returns a regexp to match the start of a TSQL ALTER PROCEDURE statement.

=head2 C<qr_createtriggertoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_createtriggertoken() >>

=back

This returns a regexp to match the start of a TSQL CREATE TRIGGER statement.

=head2 C<qr_altertriggertoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_altertriggertoken() >>

=back

This returns a regexp to match the start of a TSQL ALTER TRIGGER statement.

=head2 C<qr_createviewtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_createviewtoken() >>

=back

This returns a regexp to match the start of a TSQL CREATE VIEW statement.

=head2 C<qr_alterviewtoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_alterviewtoken() >>

=back

This returns a regexp to match the start of a TSQL ALTER VIEW statement.

=head2 C<qr_createfunctiontoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_createfunctiontoken() >>

=back

This returns a regexp to match the start of a TSQL CREATE FUNCTION statement.

=head2 C<qr_alterfunctiontoken>

=over 4

=item * C<< TSQL::Common::Regexp->qr_alterfunctiontoken() >>

=back

This returns a regexp to match the start of a TSQL ALTER FUNCTION statement.




=head1 LIMITATIONS

No limitations are currently known.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::Common::Regexp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TSQL::Common::Regexp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TSQL::Common::Regexp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TSQL::Common::Regexp>

=item * Search CPAN

L<http://search.cpan.org/dist/TSQL::Common::Regexp/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

None yet.

=back


=head1 SEE ALSO

=over 4

=item * L<TSQL::AST>

=item * L<TSQL::SplitStatement>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TSQL::Common::Regexp



