#!/usr/bin/perl -w
use strict;
use warnings;
use PAR::WebStart;
use PAR::WebStart::Util;
use constant WIN32 => PAR::WebStart::Util::WIN32;

if (WIN32()) {
  require Win32;
  import Win32 qw(MB_ICONSTOP MB_ICONEXCLAMATION);
}

my $file = shift;
my $ws = PAR::WebStart->new(file => $file);
$ws->fetch_pars() or ws_exit("Error: $ws->{ERROR}");

my $title = $ws->{cfg}->{title}->{value} || 'PAR::WebStart application';

my $tmpdir = $ws->{tmpdir};
chdir($tmpdir) or ws_exit(qq{Cannot chdir to "$tmpdir": $!});

my @args = @{$ws->run_command()};
ws_exit(qq{Failed to get WebStart args: $ws->{ERROR}}) unless (@args);

my $msg = ws_confirm($ws->{cfg});

if (WIN32) {
  $msg .= "\nPress OK to continue, or Cancel to quit.";
  my $rc = Win32::MsgBox($msg, 1 | MB_ICONEXCLAMATION(), $title);
  exit(1) unless ($rc == 1);
  system(@args) == 0 or ws_exit(qq{Execution of system(@args) failed: $?});
}

else {
  my $exec = join ' ', @args;
  my $cmd = qq{xterm -T "$title" -e "cat<<END\n${msg}\nEND\nread -p 'press \'y\' to continue, or any other key to exit: ' -n1 reply; if test \\\"\\\$reply\\\" = \\\"y\\\"; then echo \\\"\\\n\\\" && $exec;fi"};
  my $rc = qx{$cmd};
  ws_exit(qq{Execution of $cmd failed: $rc}) if $rc;
}

if ($ENV{PAR_CLEAN}) {
  my ($md5, $parfile);
  foreach $parfile(@{$ws->{pars}}) {
    $md5 = $parfile . '.md5';
    next unless (-f $md5 and -f $parfile);
    unlink($parfile, $md5);
  }
}

exit(0);

sub ws_exit {
  my $string = shift;
  my $msg = << "END";
An error was encoutered in running the application:
  $string
Execution will be terminated.
END
  if (WIN32()) {
    Win32::MsgBox($msg, 0 | MB_ICONSTOP(), $title);
  }
  else {
    my $cmd = qq{xterm -T "$title" -e "cat<<END\n${msg}\nEND\nread -p 'press any key to continue...' -n1"};
    my $rc = qx{$cmd};
  }
  exit(1);
}

sub ws_confirm {
  my $cfg = shift;

  my $check_msg = '';
  if ($cfg->{'allow-unsigned-pars'} && $cfg->{'allow-unsigned-pars'}->{seen}) {
    $check_msg = <<"END";
An md5 checksum of the par archives was performed; however,
the provider of the application has disabled checking of
the digital signature. You should be very careful in
running programs from sources you are unsure of.
END
  }
  else {
    $check_msg = <<"END";
Although the md5 checksum and the digital signature of the
associated par archives have been verified, you should be very
careful in running programs from sources you are unsure of.
END

  }

  my $argument = $cfg->{argument};
  my $args = '';
  if ($argument and ref($argument) eq 'ARRAY') {
    $args = join ' ', (map {$_->{value}} @$argument);
  }
  $args = "with arguments to the main script of:\n  $args\n" if $args;

  my $name = $cfg->{title}->{value} || '(no title specified)';
  my $desc = $cfg->{description}->[0]->{value} || '(no description specified)';
  my $vendor = $cfg->{vendor}->{value} || '(no vendor specified)';
  my $home = $cfg->{homepage}->{href} || '(no homepage specified)';
  my $msg = <<"END";
You about to run the program:
    $name
$args
The application is described as:
    $desc
and is supplied by:
    $vendor
whose homepage is found at:
    $home

$check_msg
END

  return $msg;
}

__END__

=head1 NAME

perlws - application associated with PNLP files

=head1 SYNOPSIS

    perlws.pl hello.pnlp

=head1 DESCRIPTION

This script should be registered to open C<PNLP> files
from the browser (how to do that is described later).
When this is done, the script will read the information
contained within the file, fetch the required C<par> files
that are specified, and then form and run the command
to execute the specified main script.

=head1 File Associations

Associating an application with a file extension in a
browser environment depends on the browser and platform.
With some browsers, an option in one of the browser
menus allows one to do this directly. In this case,
one should open files with a C<.pnlp> extension
with C<perlws.pl> (probably specifying the complete path).
If needed, the C<Content-Type> of the file should be
specified as C<application/x-perl-pnlp-file>.

=head2 Windows

On Windows, this association can be done, after installation,
by running the included F<pnlp_registry.pl> script in this
distribution, which will add the appropriate Registry
settings. If this script fails, or you'd prefer to do this
this manually, carry out the following steps.

=over 4

=item *

Open up C<My Computer>, and find the C<File Types>
tab under C<Folder Options> of C<Tools> (the exact
location may vary, depending on the flavour of Windows
used). 

=item *

Create a new file type C<PNLP File>, 
with extension C<.pnlp>. 

=item *

Using the C<Change> and
C<Advanced> buttons, arrange to associate with this
file type an C<action> of C<open>, with the associated
application being

    C:\Path\to\Perl\bin\perlws.bat "%1"

=item *

The content-type associated
with C<.pnlp> files can be done through the Windows Registry
by adding a new C<Content-Type> key to the C<.pnlp> file
extension registry entry, with a value of
C<application/x-perl-pnlp-file>.

=back

=head2 Linux

For linux, with
KDE, for example, one can add a file association by

=over 4

=item *

open the C<File Associations> menu item
under C<Control Center -E<gt> KDE Components>

=item *

add a new C<application> entry of name C<x-perl-pnlp-file>,
with filename pattern C<*.pnlp>. The application to handle this
should be associated with the F<perlws.pl> command.

=back

An alternative route to this procedure is to
right-click an existing C<.pnlp> file within the file explorer window
and choose the C<Edit File Type> menu item.

=head1 Server Configuration

On the server side, it's probably
a good idea to also associate the content-type of
C<application/x-perl-pnlp-file> with C<.pnlp> file
extensions. On Apache, this
can be done within the F<httpd.conf> file by
adding the directive

  Addtype application/x-perl-pnlp-file .pnlp

Special consideration must be given when generating the
C<PNLP> dynamically, as in, for example, a CGI script,
as in this case there likely would not be a C<.pnlp>
file extension present. One way to do this is through
a C<Content-Disposition> header, as in the following
example of a CGI script:

    #!/usr/bin/perl
    print qq{Content-Disposition: filename="test.pnlp"\n};
    print "Content-type: application/x-perl-pnlp-file\n\n";
    print <<"END";
 <?xml version="1.0" encoding="utf-8"?>
 <pnlp spec="0.1"
       codebase="http://www.perl.com"
       href="hello.pnlp">
  etc.
  etc.
 </pnlp>
 END

=head1 Environment Variables

The following environment variables, if set, will be used.

=over 4

=item PAR_TEMP

If set, this will be the location where the downloaded par
files will be stored. If not set, a subdirectory C<par>
beneath the temporary directory specified by
C<File::Spec-E<gt>tmpdir> will be used.

=item PAR_CLEAN

If set, the downloaded par files will be removed after use. The
default is to not remove such files, so as to provide a cache
for later use (the md5 checksum of the cached file will be
checked against that on the server to decide if an update to
the cached file is available).

=back

=head1 SEE ALSO

L<PAR::WebStart>.

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut
