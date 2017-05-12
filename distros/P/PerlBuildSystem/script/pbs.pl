#!/usr/bin/perl5.8.8 

eval 'exec /usr/bin/perl5.8.8  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

package PerlBuildSystem ;

use strict ;
use warnings ;

#use Devel::Loaded;
 
#~ use PBS::Debug ;
use PBS::Output ;

use vars qw ($VERSION) ;
$VERSION = '0.28' ;

use PBS::FrontEnd ;

#-------------------------------------------------------------------------------

my ($success, $message) = PBS::FrontEnd::Pbs(COMMAND_LINE_ARGUMENTS => [@ARGV]) ;

if($success)
	{
	}
else
	{
	PrintError($message) ;
	exit(! $success) ;
	}

#-------------------------------------------------------------------------------

__END__
=head1 NAME

PerlBuildSystem - Make replacement with rules written in perl.

=head1 SYNOPSIS

perl pbs.pl all
perl pbs.pl -c -a a.h -f all

=head1 DESCRIPTION

'pbs.pl' is an utility script used to kick start PBS through its FrontEnd module.

PBS functionality is available through the standard module mechanism which allows you to integrate
a build system in your scripts.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

Parts of the development was funded by B<C-Technologies AB, Ideon Research Center, Lund, Sweden>.

=head1 SEE ALSO

PBS::PBS.

=head1 BUGS

Please report any bugs or feature requests to
C<PerlBuildSystem at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PerlBuildSystem>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PBS

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PerlBuildSystem>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PerlBuildSystem>

=item * Search CPAN

L<http://search.cpan.org/dist/PerlBuildSystem>

=back

=cut
