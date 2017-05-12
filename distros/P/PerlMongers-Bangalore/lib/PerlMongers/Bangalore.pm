package PerlMongers::Bangalore;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use warnings;
use strict;
require Exporter;

#======================================================================
@ISA       = qw(Exporter);
@EXPORT_OK = qw(Perl_Mongers);

#======================================================================
# PODNAME: PerlMongers::Bangalore
# ABSTRACT: We are the Bangalore Perl Mongers
#
# This file is part of PerlMongers-Bangalore
#
# This software is copyright (c) 2013 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.07'; # VERSION

# Dependencies
use 5.010000;


sub info {
    system( 'perldoc', __PACKAGE__ );
}

#======================================================================
1;    # End of Bangalore.pm

__END__

=pod

=head1 NAME

PerlMongers::Bangalore - We are the Bangalore Perl Mongers

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use PerlMongers::Bangalore qw(info);
        
    info();

=head2 WEBSITE

http://www.bangalore.pm.org

=head2 MEETUPS

http://bangalore.pm.org/meetups.html

=head2 DISCUSSION BOARD

http://bangalore.pm.org/forum.html

=head2 IRC Channel

irc.perl.org #bangalore.pm

=head2 MAILING LIST (SUBSCRIBE HERE)

http://mail.pm.org/mailman/listinfo/bangalore-pm

=head2 MAIL ARCHIVES

http://mail.pm.org/pipermail/bangalore-pm/

C<Perl>

=head1 METHODS

=head2 info

Returns information about the Bangalore Perl Mongers. At this time it returns the perl pod of this module

=head1 NAME

PerlMongers::Bangalore - We are the Bangalore Perl Mongers, find us at all the 
places listed below! If you are in or around Bangalore near the first week of a 
month, do drop by for our meetups listed at bangalore.pm.org. Discuss this 
module at L<Bangalore.pm discussion page for this module|http://bangalore.pm.org/forum/6-module-plugins-frameworks-and-downloads/52-perlmongersbangalore.html>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perlmongers-bangalore/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perlmongers-bangalore>

  git clone git://github.com/shantanubhadoria/perlmongers-bangalore.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTORS

=over 4

=item *

Shantanu <shantanu@cpan.org>

=item *

Shantanu Bhadoria <shantanu.bhadoria@gmail.com>

=item *

Shantanu Bhadoria <shantanu@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
