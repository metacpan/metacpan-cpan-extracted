# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

package Perl::RunEND;

use 5.006;
use strict;
use warnings FATAL => 'all';
#use criticism 'brutal'; # use critic with a ~/.perlcriticrc
use Carp qw/croak/;
use File::Temp qw/ tempfile tempdir tmpnam /;
use File::Basename;
use Getopt::Long;
use Config;

=head1 NAME

Perl::RunEND - Use __END__ for working code examples, self testing, executing
code, etc.

A common best-practice under Python is to include a self-test at the end every
module - especially if the module is largely standalone.  In Python this is 
done via: if __name__ == '__main__':

In Perl, we have an __END__ available where we often put test code or notes 
or comments, etc. Currently there is no way to actually execute this code, 
execpt by using the DATA filehandle. It would be handy if we could put 
actual test examples in the __END__ block which would would be executed 
if the module is run as 'self'. Or to just test a script or code snippets,
by running the same file you are editing. 


=head1 VERSION

Version 0.01

=cut

#our $VERSION = '0.01';
#major-version.minor-revision.bugfix
use version; our $VERSION = qv('0.1.0');


=head1 SYNOPSIS

If module is called as 'self' run the code beneath __END__.


    perl-run-end /opt/Module/Whatever/YourModule.pm
    # displays
    FOOfunction1 called

    Where the contents of ModuleWhatever/YourModule.pm

    package YourModule;
    use strict;
    sub new {
        my $class = shift;
        my $self = bless {}, $class;
        $self->{foo} = 'FOO';
        return $self;
    }
    sub function1 {
      return 'function1 called';
    }
    1; # End of Perl::RunEND
    
    __END__
    use strict;
    use warnings;
    use YourModule;
    my $ym = YourModule->new();
    warn $ym->{foo};
    warn $ym->function1;

    # you may have to add the module path to your @INC
    perl-run-end -i /opt/Module/Whatever/Mod  /opt/Module/Whatever/Mod/YourModule.pm

=head1 DESCRIPTION

Some people like to create their POD below the __END__ literal in the modules

This module could be useful for proving your synopsis and POD examples are working code.

Consider the following POD:

  =head1 SYNOPSIS
  
    use My::MyModulePod;
    my $mm = My::MyModulePod->new();
    print $mm->function1,"\n";
  
  =cut
  
  # perdoc does not parse this code but perl-run-end does execute it
  use My::MyModulePod;
  my $mm = My::MyModulePod->new();
  print "test synopsis\n";
  print $mm->function1,"\n";

  =head2 function1
  
   provides useful funtion type access
  
   $mm->function1;
  
  =cut
  
  print "test method definition\n";
  print $mm->function1,"\n";


=head1 SUBROUTINES/METHODS

 This module is not meant to be called directly, it does the work for the

 command line tool: perl-run-end

=cut

sub _get_inc_if_set {
    my $inc = q{};
    GetOptions('i=s' => \$inc);
    return $inc if $inc;
}

sub run {
    my $inc = _get_inc_if_set();

    open my $opm, '<', $ARGV[0] or croak "cant open Script/Module $!";
    my ($pm, $lines, $flines);
    while (my $line = <$opm>) {
      $lines++;
      $pm .= $line;
      $flines = $lines if $line =~ m/^__END__$/;
    }
    close $opm;
    # XXX do we want to support ^D - perldata.html#Special-Literals
    $pm =~ s/.*__END__//sxg;
    $lines = $flines;

    my ($fh, $filename) = tempfile();
    my $cmd_out = tmpnam();
    print $fh $pm;
    close $fh;
    #print qx/cat $filename/;

    # get path to systems perl
    my $perl = $Config{perlpath};
    $perl .= $Config{_exe} if $^O ne 'VMS' and $perl !~ /$Config{_exe}$/i;

    # if self testing module, include in path
    my $use_lib = dirname($ARGV[0]);
    #warn  qq{$perl -I $use_lib $filename 2>&1 > $cmd_out};
    my $add_inc = q{};
    $add_inc = " -I $inc " if $inc;
    #warn qq{$perl -I $use_lib $add_inc $filename 2>&1 > $cmd_out};
    my $excd = qx{$perl -I $use_lib $add_inc $filename 2>&1 > $cmd_out};
    #warn  $excd;
    $excd =~ s/line\s(\d+)/line @{[$1+$lines]}/g;
    print $excd;
    open my $co, '<', $cmd_out or croak "cant open outfile $!";
    { local $/; print <$co>; }
    close $co;
}

=head1 AUTHOR

David Wright, C<< <dvwright at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perl-run-end at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-RunEND>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DIAGNOSTICS

If you run a module:
perl-run-end  /Users/dwright/perl/Perl-RunEND/t/data/My/MyModulePod.pm

and recieve an error such as: Can't locate My/MyModulePod.pm in @INC (@INC contains: 

You need to include the needed module in the @INC path, for instance:

perl-run-end -i /Users/dwright/perl/Perl-RunEND/t/data /Users/dwright/perl/Perl-RunEND/t/data/My/MyModulePod.pm

Additionally, (depending on your platform?) adjusting the PERL5LIB path, like this should work:

PERL5LIB=$PERL5LIB:/Users/dwright/perl/Perl-RunEND/t/data perl-run-end /Users/dwright/perl/Perl-RunEND/t/data/My/MyModulePod.pm


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::RunEND

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-RunEND>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-RunEND>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-RunEND>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-RunEND/>

=back


=head1 ACKNOWLEDGEMENTS

this module was created with module-starter
module-starter --module=Perl::RunEND --author="David Wright" --mb --email=dvwright@cpan.org


=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Wright.

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


=cut

1; # End of Perl::RunEND
