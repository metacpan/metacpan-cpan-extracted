#*
#* Name: Params::Dry::Declare (some magic for Params::Dry :)
#* Info: Extension to Params::Dry, which make possible declaration of the parameters
#* Author: Pawel Guspiel (neo77) <neo@cpan.org>
#* Details:
#*      The module allow parameters declaration in following form:
#*
#*          sub new (
#*              ! name:;                                    --- name of the user
#*              ? second_name   : name      = 'unknown';    --- second name
#*              ? details       : String    = 'yakusa';     --- details
#*          ) {
#*
#*      instead of using:
#*
#*          sub table {
#*              my $self = __@_;
#*
#*              my $p_name          = rq 'name', DEFAULT_TYPE;               # name of the user
#*              my $p_second_name   = op 'second_name', 'name', 'unknown';   # second name
#*              ...
#*
#*      As a consequence of using this module you can use parameters in the function body as follows:
#*          print "name: ".p_name;
#*
#*      I'm suggesting you to use coloring in your text editor for p_\w+ to see function parameters everywhere

use Params::Dry qw(:short);    # required to take care of parameters (and because is the best of course ;)
                               # for multi types 1.20 or higher is required

package Params::Dry::Declare;
{
    use strict;
    use warnings;

    # --- version ---
    our $VERSION = 0.9907;

    #=------------------------------------------------------------------------ { use, constants }

    use Filter::Simple;        # extends subroutine definition

    #=------------------------------------------------------------------------ { module magic }

    FILTER_ONLY code_no_comments => sub {
        while ( my ( $orig_sub, $sub_name, $sub_declared_vars ) = $_ =~ /(sub\s+(\w+)\s*\(\s*(?:(.+?)\s*)?\)\s*{)/s ) {

            # --- clean
            $sub_declared_vars //= '';
            $sub_declared_vars =~ s/\n//;

            # --- prepare variables string
            my $variables_string = 'my $self = __@_;';

            # --- parse variables
            for my $param ( split /\s*;\s*/, $sub_declared_vars ) {

                #+ remove comments
                $param =~ s/---.+?([?!]|$)/$1/s;

                next unless $param;

                #+ parse
                $param =~ /^(?<is_rq>[!?]) \s* (?<param_name>\w+) \s* : \s* (?<param_type>\w+ (?:\[.+?\])? (?:\|\w+ (?:\[.+?\])?)* )? \s* (?:= \s* (?<default>.+))? (?:[#].*)?$/x;

                my ( $is_rq, $param_name, $param_type, $default ) = ( '' ) x 4;

                $is_rq = $+{ 'is_rq' } eq '!';
                ( $param_name, $param_type, $default ) = ( $+{ 'param_name' }, $+{ 'param_type' }, $+{ 'default' } );
                $param_type ||= $param_name;

                $variables_string .= "my \$p_$param_name = " . ( ( $is_rq ) ? 'rq' : 'op' ) . " '$param_name'";
                $variables_string .= ", '$param_type'" if $param_type;
                $variables_string .= ", $default"      if $default;
                $variables_string .= '; ';
            } #+ end of: for my $param ( split /\s*;\s*/...)

            # --- for errors in correct lines
            my $new_lines = "\n" x ( $orig_sub =~ s/\n/\n/gs );
            s/\Q$orig_sub/sub $sub_name { $new_lines $variables_string no_more;/;

        } #+ end of: while ( my ( $orig_sub, $sub_name...))
        $_;
    };
};
0115 && 0x4d;

#+ End of Params::Declare magic :)
# ABSTRACT: Declare extension for Params::Dry - Simple Global Params Management System which helps you to keep the DRY rule everywhere

#+ End of Params::Dry
__END__
=head1 NAME

Params::Dry::Declare - Declare extension for Params::Dry - Simple Global Params Management System which helps you to keep the DRY rule everywhere

=head1 VERSION

version 0.9907 (beta)

=head1 SYNOPSIS

Params::Dry::Declare (some magic for Params::Dry :)
Extension to Params::Dry, which make possible declaration of the parameters, keeping comments declarations and all this things near.

=head1 DESCRIPTION

=head2 Fast start!

=over 4

=item * B<typedef> - defines global types for variables (from Params::Dry)

=item * B<!> - required parameter

=item * B<?> - optional parameter

=item * B<---> - comment

=item * B<no_more> - not needed any more :)

=item * B<__@_> - not needed any more :)

=back

=head2 Example:

    # The module allow parameters declaration in following form:

          sub new (
              ! name:;                                    --- name of the user
              ? second_name   : name      = 'unknown';    --- second name
              ? details       : String|Int    = 'yakusa';     --- details
          ) {

          ...

    # instead of using:

          sub table {
              my $self = __@_;

              my $p_name          = rq 'name', DEFAULT_TYPE;               # name of the user
              my $p_second_name   = op 'second_name', 'name', 'unknown';   # second name

              ...

    # as it was in Params::Dry

    #  As a consequence of using this module you can use parameters in the function body as follows:
          print "name: ".$p_name;

    # IMPORTANT - to mark declaration of no params function please use empty params list (;)

        sub get_no_params(;) {

        }

=head2 Grammar:

You are declaring in-variable using following schema:

C<required/optional> C<variable name>  : [ C<type name> ] [ = C<default value> ] [ --- C<comment> ]

where:

=over 4

=item * B<!> - required parameter

=item * B<?> - optional parameter

=item * B<variable name> - any perl variable name

=item * B<type name> - type defined by typedef or ad-hoc type (alternative types can be added after pipe(|) sign ex. String[3]|Int[2])

=item * B<default value> - default value for the parameter

=item * B<comment> - just a comment to remember what this variable is doing

=back

Because all parameters are available as $p_C<variable name> I'm suggesting you to use coloring in your text editor for $p_\w+ to see function parameters everywhere

=head2 Important!

To mark declaration of no params function please use empty params list (;)

        sub get_no_params(;) {

        }


=head2 Understand main concepts

First. If you can use any function as in natural languague - you will use and understand it even after few months.

Second. Your lazy life will be easy, and you will reduce a lot of errors if you will have guarancy that your parameter
in whole project means the same ( ex. when you see 'client' you know that it is always String[32] ).

Third. You want to set the type in one and only in one place.

Yes, DRY principle in its pure form!

So all your dreams you can now find in this module.

And even more, every parameter is declared in the function header and no where more. So it helps keeping your code clean!

B<That's all. Easy to use. Easy to manage. Easy to understand.>

=head1 AUTHOR

Pawel Guspiel (neo77), C<< <neo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-params at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Dry-Declare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Dry::Declare
    perldoc Params::Dry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Dry-Declare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Params-Dry-Declare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Params-Dry-Declare>

=item * Search CPAN

L<http://search.cpan.org/dist/Params-Dry-Declare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pawel Guspiel (neo77).

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



