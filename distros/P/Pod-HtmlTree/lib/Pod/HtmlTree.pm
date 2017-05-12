############################################################
package Pod::HtmlTree;
############################################################
use strict;
use warnings;

use Exporter;
use Pod::Html;
use Text::Wrap;
use File::Find;
use File::Spec;
use File::Basename;
use File::Path;
use Pod::Html;
use Cwd;
use File::Temp qw(tempfile);

our $VERSION     = '0.97';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} }, 
                     qw(pms modules
                        pod2htmltree banner
                       ) );
our @EXPORT      = qw( );

my $HTML_DIR      = "docs/html";
my $BASE          = cwd();
my @SEARCH_DIRS   = qw(. lib);
my $SEARCH_DIRS_PATTERN = join('|', map { "^" . quotemeta($_) } @SEARCH_DIRS);

############################################################
# Get a list of all *.pm files in the specified directory
# and recursively in its subdirectories. Prune the find
# tree in the given dirs.
############################################################
sub pms {
############################################################
    my($start_dir, $prune_dirs) = @_;

        # Default if no prune_dirs are given
    $prune_dirs ||= ['blib', 'docs'];

    my @pms = ();

    File::Find::find( sub {

        if(-d $_) {
            for my $dir (@$prune_dirs) {
                if($_ eq $dir) {
                    $File::Find::prune = 1;
                    return;
                }
            }
        }
                    
        return if ! -f or ! (/\.pm$/ || /\.pod$/);

        (my $path = $File::Find::name) =~ s#^./##;

        push @pms, $path;
    }, $start_dir );

    return @pms;
}

############################################################
# Get a list of all modules (pm files) in the tree.
############################################################
sub modules {
############################################################
    my($start_dir, $prune_dirs) = @_;

    my @pms = paths_to_modules(pms($start_dir, $prune_dirs));

    return @pms;
}

############################################################
# Format something in form of a banner
############################################################
sub banner {
############################################################

    my $TOTAL_LEN = 50;

    my $out = "*" x $TOTAL_LEN;
    $out .= "\n";
    $Text::Wrap::columns = $TOTAL_LEN - 2;
    for my $line (split /\n/, Text::Wrap::fill('* ','* ', @_)) {
        chomp $line;
        if(length($line) < $TOTAL_LEN - 2) {
            $line .= (" " x ($TOTAL_LEN - 2 - length($line))) . " *\n";
        }
        $out .= $line;
    }
    $out .= "*" x $TOTAL_LEN;
    $out .= "\n";

    return $out;
}

############################################################
sub paths_to_modules {
############################################################
    my(@paths) = @_;

    my @modules = map { s#$SEARCH_DIRS_PATTERN##o;
                        s#^/##;
                        s#/#::#g; 
                        s#\.pm##; 
                        s#\.pod##;
                        $_; 
                      } @paths;

    # Remove double entries (e.g. If a module consists of a .pm 
    # and a .pod file)
    @modules = do { my %myhash; @myhash{@modules} = (); keys %myhash};

    return @modules;
}

############################################################
# Set up the doc tree
############################################################
sub pod2htmltree {
############################################################
    my($htmlroot_to_module, $htmldocdir) = @_;

    $htmldocdir = $HTML_DIR unless defined $htmldocdir;

    my ($fh,$tmpfile) = tempfile();
    close $fh;

    my @dirs    = pms(".");
    my @modules = modules(".");

    my $see_also = "=head1 SEE ALSO\n\n";
    $see_also .= join ', ', map( { "L<$_|$_>" } @modules );
    $see_also .= "\n\n";
    $see_also .= "B<Source Code:> _SRC_HERE_\n\n";

    mkpath $htmldocdir unless -d $htmldocdir;

    for my $pm (@dirs) {
        (my $module) = paths_to_modules($pm);
        (my $relpath = $pm) =~ s#$SEARCH_DIRS_PATTERN##o;
        my $htmlfile = File::Spec->catfile($htmldocdir, $relpath); 
        $htmlfile =~ s/\.pm$/\.html/;
        $htmlfile =~ s/\.pod$/\.html/;

        my $dir     = dirname($htmlfile);

        mkpath($dir) unless -d $dir;

        open FILE, "<$pm" or die "Cannot open $pm";
        my $data = join '', <FILE>;
        close FILE;

        $data =~ s/^=head1 SEE ALSO.*?(?=^=)/$see_also/ms;

        open FILE, ">$tmpfile" or die "Cannot open $tmpfile";
        print FILE $data;
        close FILE;

        my $podroot = (-d "lib" ? "lib" : ".");

        pod2html("--infile=$tmpfile",
                 "--outfile=$htmlfile",
                 "--podroot=$podroot",
                 "--podpath=.",
                 '--recurse',
                 "--htmlroot=$htmlroot_to_module/$htmldocdir",
                 "--css=$htmlroot_to_module/$htmldocdir/default.css",
        );

        # Patch src link
        open FILE, "<$htmlfile" or die "Cannot open $htmlfile";
        $data = join '', <FILE>;
        close FILE;
        open FILE, ">$htmlfile" or die "Cannot open $htmlfile";
            # If it's a separate pod, link to the .pm
        $pm =~ s/\.pod$/.pm/;
        if(-f $pm) {
          $data =~ s#_SRC_HERE_#<A HREF=$htmlroot_to_module/$pm>$module</A>#g;
        } else {
          $data =~ s#_SRC_HERE_##g;
        }
        print FILE $data;
        close FILE;
    }

    #unlink $tmpfile;
    stylesheet_write(File::Spec->catfile($htmldocdir, "default.css"));
}

############################################################
sub stylesheet_write {
############################################################
    my($dstfile, $csstext) = @_;

    $csstext = stylesheet_default() unless defined $csstext;

    open FILE, ">$dstfile" or die "Cannot open $dstfile";
    print FILE $csstext;
    close FILE;
}

############################################################
# Default style sheet
############################################################
sub stylesheet_default {
############################################################
    return <<EOT;
body {
    background:  #FFFFFF;
    font-family: Arial;
}	
input {
    font-size: 12px;
}
select {
    font-size: 12px;
}
tt {
    font-family: Lucida Console;
    font-size: 10px;
}
pre {
    font-family: Lucida Console;
    font-size: 12px;
}
code {
    font-family: Lucida Console;
    font-size: 12px;
}
p {
    color: #000000;
    font-size: 12px;
    font-family: Arial;
    }
blockquote {
    color: #000000;
    font-size: 12px;
    font-family: Arial;
    font-weight: normal;
}
b {
    font-weight: bold;
}

h1 { 
    font-family: Arial;
    font-size: 16px;
    font-weight: bold;
    color: #B82831;
}
h2 { 
    font-family: Arial;
    font-size: 14px;
    font-weight: bold;
    color: #B82831;
}
a:link { 
	color: #B82831;
        text-decoration: underline;
}
a:visited { 
	color: #80933F;
        text-decoration: underline;
}
EOT
}

1;

__END__

=head1 NAME

Pod::HtmlTree - Create a hierarchy of HTML documents from your module's PMs.

=head1 SYNOPSIS

  use Pod::HtmlTree qw(pod2htmltree);
  pod2htmltree($httproot);

=head1 DESCRIPTION

So you've just created a great new Perl module distribution including
several *.pm files?
You've added nice POD documentation to each of them and now you'd like
to view it nicely formatted in a web browser? And you'd also
like to navigate between all those manual pages in your distribution
and even view their source code? Read on, C<Pod::HtmlTree> is what you need.

It traverses your module's distribution directory (which you've probably 
created using C<h2xs>), finds all *.pm files recursivly and calls C<pod2html()>
on them, hereby resolving all POD links (LE<lt>...E<gt> style).

=head2 Patching SEE ALSO and WHERE'S THE SOURCE?

It then saves the nicely formatted HTML files under C<docs/html> and 
updates each's C<SEE ALSO> section to contain links to every other *.pm file
in you're module's distribution. So, if you want that, please
make sure your documentation contains a C<SEE ALSO> section.

Also, at the end of the C<SEE ALSO> section, it'll add a link to the
source code of the current *.pm file, 
just in case a user wants to browse it because
there's issues which aren't clear from the documentation.

It also adds a stylesheet to C<docs/html>, which is referenced by every HTML 
file.

So, in order to obtain HTML documentation for all your distribution's files, 
just call the script (which comes with the distribution of this module)

    pod2htmltree httproot

while you're located in the top directory of your module's distribution.
What's in C<httproot> is explained below.

The script C<pod2htmltree> just calls

    use Pod::HtmlTree;
    Pod::HtmlTree::pod2htmltree($ARGV[0]);

internally, if you want to call it from within Perl, that's the way to go.

=head1 FUNCTIONS

=over 4

=item pod2htmltree( $httproot );

Make sure you've C<chdir()>ed to 
your module's top directory when calling this function.

Recursively finds all C<*.pm> files under the current directory,
transforms them to HTML and places the result files in a tree starting
at C<docs/html> from the current directory.

C<$httproot> is the URL (absolute like C<"http://..."> or relative like
C</mymodule>) to the top directory of your module, as seen from your web 
browser.

If you don't like the HTML documents to be created under C<docs/html>,
you can specify the relative (!) directory in the additional parameter
C<$htmldocdir>:

    pod2htmltree( $httproot, $htmldocdir );

If not specified, C<$htmldocdir> defaults to C<docs/html>, therefore the
one-parameter syntax shown above.

=item banner( $text );

Prints the passed text string nicely formatted as a screen warning. E. g., to notify
the user after running C<pod2htmltree> to C<"Make sure 
http://localhost/perldoc/Pod-HtmlTree points to /u/mschilli/DEV/Pod-HtmlTree">, 
just pass it to C<banner()> and print the return value:

    **************************************************
    * Make sure                                      *
    * http://localhost/perldoc/Pod-HtmlTree points   *
    * to /u/mschilli/DEV/Pod-HtmlTree                *
    **************************************************

=back

=head1 EXAMPLE

So, if your module is under

    /u/mschilli/MYPROJECTS/Spiffy-Module

and has the files

    Spiffy-Module
    Spiffy-Module/Changes
    Spiffy-Module/MANIFEST
    Spiffy-Module/Makefile.PL
    Spiffy-Module/README
    Spiffy-Module/lib
    Spiffy-Module/lib/Spiffy.pm
    Spiffy-Module/lib/Spiffy/Subspiffy.pm
    Spiffy-Module/lib/Spiffy/Subspiffy/Subsub.pm
    Spiffy-Module/t
    Spiffy-Module/t/1.t

a call to 

    cd Spiffy-Module
    pod2htmltree http://localhost/Spiffy

from within the shell or

    use Pod::HtmlTree;
    Pod::HtmlTree::pod2htmltree("http://localhost/Spiffy");

from within Perl will C<pod2html>-transform the files
C<Spiffy.pm>, C<Subspiffy.pm> and C<Subsub.pm> to HTML and put the result there:

    Spiffy-Module/docs/html/Spiffy.html
    Spiffy-Module/docs/html/Spiffy/Subspiffy.html
    Spiffy-Module/docs/html/Spiffy/Subspiffy/Subspiffy.html

Directories are created on the fly as necessary.
To view them on your web server via a browser, you need to create a symbolic link
from your web server's document root.

If the module's distribution is located under

    /u/mschilli/MYPROJECTS/Spiffy-Module

and your web server's doc root is C</opt/netscape/htdocs>, you need to create a symlink
like

    ln -s /u/mschilli/MYPROJECTS/Spiffy-Module /opt/netscape/htdocs/Spiffy

Then, if you point your browser to 

    http://localhost/Spiffy/docs/html/Spiffy.html

you'll see the documentation. If you've specified a (probably empty) 
C<SEE ALSO> section, it will be automatically populated with other modules
in your distribution and a link to the current module's source code.

=head2 Or, call it in Makefile.PL

If you want to give the user of your distribution the opportunity to
create their own browsable HTML-documentation of your module, just
include the following in the Makefil.PL of your distribution:

    use ExtUtils::MakeMaker;

    >>  # Generate documentation?
    >>  if (prompt("Generate HTML documentation?", "n") =~ /^y/) {
    >>      require Pod::HtmlTree;
    >>      Pod::HtmlTree::pod2htmltree("/mymodule");
    >>      print Pod::HtmlTree::banner(
    >>          "Make sure http://localhost/mymodule points to ", `pwd`);
    >>   }

    WriteMakefile(
        ...
    );

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>mschilli1@aol.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
