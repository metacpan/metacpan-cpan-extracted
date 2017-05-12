# $File: //depot/libOurNet/lib/Bundle/OurNet.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 2112 $ $DateTime: 2001/10/17 05:42:55 $

package Bundle::OurNet;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::OurNet - OurNet::* and prerequisites

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::OurNet'>

=head1 CONTENTS

# Below is a bunch of helpful dependency diagrams.

ExtUtils::AutoInstall # does not belong anywhere

Bundle::ebx
Bundle::Query

OurNet # the endpoint

=head1 DESCRIPTION

This bundle includes all that's needed to run the OurNet::* suite.

=head1 AUTHORS

Chia-Liang Kao <clkao@clkao.org>,
Autrijus Tang <autrijus@autrijus.org>.

=head1 COPYRIGHT

Copyright 2001 by Chia-Liang Kao <clkao@clkao.org>,
                  Autrijus Tang <autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
