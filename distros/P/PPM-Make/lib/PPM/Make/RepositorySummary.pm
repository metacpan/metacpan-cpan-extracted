package PPM::Make::RepositorySummary;

use strict;
use warnings;
use PPM::Make::Util qw(parse_ppd ppd2cpan_version encode_non_ascii_chars);
use File::Copy;
use XML::Writer;

our $VERSION = '0.9904';

sub new {
  my $class = shift;
  my %args = @_;
  my $rep = $args{rep};
  die qq{Please supply the path to a repository of ppd files}
    unless $rep;
  die qq{The given repository directory "$rep" does not exist}
    unless -d $rep;
  opendir(my $dir, $rep) or die "Cannot opendir $rep: $!";
  my @ppds = sort {lc $a cmp lc $b} grep {$_ =~ /\.ppd$/} readdir $dir;
  closedir($dir);
  die qq{The repository directory "$rep" contains no ppd files}
    unless (scalar @ppds > 0);

  my $no_ppm4 = $args{no_ppm4};
  my $fhs = {
             summary => {file => 'summary.ppm',
                         softpkg => \&summary_softpkg,
                        },
             searchsummary => {file => 'searchsummary.ppm',
                               softpkg => \&searchsummary_softpkg,
                        },
             package_lst => {file => 'package.lst',
                             softpkg => \&package_lst_softpkg,
                            },
            };
  unless ($no_ppm4) {
    $fhs->{package_xml} = {file => 'package.xml',
                           softpkg => \&package_xml_softpkg,
                          };
  };
  my $self = {rep => $rep,
              ppds => \@ppds,
              no_ppm4 => $no_ppm4,
              arch => $args{arch},
              fhs => $fhs,
             };
  bless $self, $class;
}

sub summary {
  my $self = shift;
  my $rep = $self->{rep};
  my $fhs = $self->{fhs};
  chdir($rep) or die qq{Cannot chdir to $rep: $!};

  my $arch = $self->{arch};
  foreach my $key (keys %$fhs) {
    my $tmp = $fhs->{$key}->{file} . '.TMP';
    open(my $fh, '>', $tmp) or die qq{Cannot open $tmp: $!};
    my $writer = XML::Writer->new(OUTPUT => $fh, DATA_INDENT => 2);
    $fhs->{$key}->{fh} = $fh;
    $fhs->{$key}->{writer} = $writer;
    my %attr;
    $attr{ARCHITECTURE} = $arch if $arch && $key eq 'package_xml';
    $writer->xmlDecl('UTF-8');
    $writer->startTag('REPOSITORYSUMMARY', %attr);
    $writer->setDataMode(1);
  }

  my $ppds = $self->{ppds};
  foreach my $ppd(@$ppds) {
    my $data;
    eval {$data = parse_ppd($ppd);};
    if ($@) {
      warn qq{Error in parsing $ppd: $@};
      next;
    }
    unless ($data and (ref($data) eq 'HASH')) {
      warn qq{No valid ppd data available in $ppd};
      next;
    }
    foreach my $key (keys %$fhs) {
      $fhs->{$key}->{softpkg}->($fhs->{$key}->{writer}, $data);
    }
  }

  foreach my $key (keys %$fhs) {
    my $writer = delete $fhs->{$key}->{writer};
    $writer->endTag('REPOSITORYSUMMARY');
    $writer->end;
    close($fhs->{$key}->{fh});
    my $real = $fhs->{$key}->{file};
    my $tmp =  $real . '.TMP';
    move($tmp, $real) or warn qq{Cannot rename $tmp to $real: $!};
  }
  return 1;
}

sub summary_softpkg {
  my ($writer, $d) = @_;
  $writer->startTag('SOFTPKG' => NAME => $d->{SOFTPKG}->{NAME}, VERSION => $d->{SOFTPKG}->{VERSION});
  for (qw/TITLE ABSTRACT AUTHOR/) {
    $writer->dataElement($_ => encode_non_ascii_chars($d->{$_}));
  }
  $writer->endTag('SOFTPKG');
  return 1;
}

sub searchsummary_softpkg {
  my ($writer, $d) = @_;
  $writer->startTag('SOFTPKG' => NAME => $d->{SOFTPKG}->{NAME}, VERSION => $d->{SOFTPKG}->{VERSION});
  for (qw/TITLE ABSTRACT AUTHOR/) {
    $writer->dataElement($_ => encode_non_ascii_chars($d->{$_}));
  }
  my $imp = $d->{IMPLEMENTATION};
  foreach my $item(@$imp) {
    $writer->startTag('IMPLEMENTATION');
    $writer->emptyTag('ARCHITECTURE' => NAME => $item->{ARCHITECTURE}->{NAME});
    $writer->endTag('IMPLEMENTATION');
  }
  $writer->endTag('SOFTPKG');
  return 1;
}

sub package_lst_softpkg {
  my ($writer, $d) = @_;
  $writer->startTag('SOFTPKG' => NAME => $d->{SOFTPKG}->{NAME}, VERSION => $d->{SOFTPKG}->{VERSION});
  for (qw/TITLE ABSTRACT AUTHOR/) {
    $writer->dataElement($_ => encode_non_ascii_chars($d->{$_}));
  }
  my $imp = $d->{IMPLEMENTATION};
  foreach my $item(@$imp) {
    $writer->startTag('IMPLEMENTATION');
    my $deps = $item->{DEPENDENCY};
    if (defined $deps and (ref($deps) eq 'ARRAY')) {
      foreach my $dep (@$deps) {
        $writer->emptyTag('DEPENDENCY' => NAME => $dep->{NAME}, VERSION => $dep->{VERSION});
      }
    }

    foreach (qw(OS ARCHITECTURE)) {
      next unless $item->{$_}->{NAME};
      $writer->emptyTag($_ => NAME => $item->{$_}->{NAME});
    }

    if (my $script = $item->{INSTALL}->{SCRIPT}) {
      my %attr;
      for (qw/EXEC HREF/) {
        next unless $item->{INSTALL}->{$_};
        $attr{$_} = $item->{INSTALL}->{$_};
      }
      $writer->dataElement('INSTALL' => $script, %attr);
    }
    $writer->emptyTag('CODEBASE' => HREF => $item->{CODEBASE}->{HREF});
    $writer->endTag('IMPLEMENTATION');
  }
  $writer->endTag('SOFTPKG');
  return 1;
}

sub package_xml_softpkg {
  my ($writer, $d) = @_;
  my $s_version = ppd2cpan_version($d->{SOFTPKG}->{VERSION});
  $writer->startTag('SOFTPKG' => NAME => $d->{SOFTPKG}->{NAME}, VERSION => $s_version);
  for (qw/ABSTRACT AUTHOR/) {
    $writer->dataElement($_ => encode_non_ascii_chars($d->{$_}));
  }
  my $imp = $d->{IMPLEMENTATION};
  my $size = scalar @$imp;
  foreach my $item (@$imp) {
    $writer->startTag('IMPLEMENTATION');

    if (my $arch = $item->{ARCHITECTURE}->{NAME}) {
      $writer->emptyTag('ARCHITECTURE' => NAME => $arch);
    }

    if (my $script = $item->{INSTALL}->{SCRIPT}) {
      my %attr;
      for (qw/EXEC HREF/) {
        next unless $item->{INSTALL}->{$_};
        $attr{$_} = $item->{INSTALL}->{$_};
      }
      $writer->dataElement('INSTALL' => $script, %attr);
    }
    $writer->emptyTag('CODEBASE' => HREF => $item->{CODEBASE}->{HREF});
    if ($size == 1) {
      $writer->endTag('IMPLEMENTATION');
    }
    my $provide = $item->{PROVIDE};
    if ($provide and (ref($provide) eq 'ARRAY')) {
      foreach my $mod(@$provide) {
        my %attr;
        if ($mod->{VERSION}) {
          $attr{VERSION} = $mod->{VERSION};
        }
        $writer->emptyTag('PROVIDE' => NAME => $mod->{NAME}, %attr);
      }
    }

    my $deps = $item->{DEPENDENCY};
    if ($deps and (ref($deps) eq 'ARRAY')) {
      foreach my $dep (@$deps) {
#  ppm4 819 doesn't seem to like version numbers
#      my $p_version = ppd2cpan_version($dep->{VERSION});
#      $writer->emptyTag('REQUIRE' => NAME => $dep->{NAME}, VERSION => $p_version);
        $writer->emptyTag('REQUIRE' => NAME => $dep->{NAME});
      }
    }
    if ($size > 1) {
      $writer->endTag('IMPLEMENTATION');
    }
  }

  $writer->endTag('SOFTPKG');
  return 1;
}

1;

__END__


=head1 NAME

PPM::Make::RepositorySummary - generate summary files for a ppm repository

=head1 SYNOPSIS

   use PPM::Make::RepositorySummary;
   my $rep = '/path/to/ppms';
   my $obj = PPM::Make::RepositorySummary->new(rep => $rep);
   $obj->summary();

=head1 DESCRIPTION

This module may be used to generate various summary files as used by
ActiveState's ppm system. It searches a given directory for I<ppd>
files, which are of the form

  <?xml version="1.0" encoding="UTF-8"?>
  <SOFTPKG NAME="Archive-Tar" VERSION="1,29,0,0">
    <TITLE>Archive-Tar</TITLE>
    <ABSTRACT>Manipulates TAR archives</ABSTRACT>
    <AUTHOR>Jos Boumans &lt;kane[at]cpan.org&gt;</AUTHOR>
    <IMPLEMENTATION>
      <DEPENDENCY NAME="IO-Zlib" VERSION="1,01,0,0" />
      <OS NAME="MSWin32" />
      <ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.8" />
      <CODEBASE HREF="Archive-Tar.tar.gz" />
    </IMPLEMENTATION>
  </SOFTPKG>

and generates four types of files summarizing the information
found in all I<ppd> files found:

=over

=item summary.ppm

  <?xml version="1.0" encoding="UTF-8"?>
  <REPOSITORYSUMMARY>
    <SOFTPKG NAME="Archive-Tar" VERSION="1,29,0,0">
      <TITLE>Archive-Tar</TITLE>
      <ABSTRACT>Manipulates TAR archives</ABSTRACT>
      <AUTHOR>Jos Boumans &lt;kane[at]cpan.org&gt;</AUTHOR>
    </SOFTPKG>
    ...
  </REPOSITORYSUMMARY>

=item searchsummary.ppm

  <?xml version="1.0" encoding="UTF-8"?>
  <REPOSITORYSUMMARY>
    <SOFTPKG NAME="Archive-Tar" VERSION="1,29,0,0">
      <TITLE>Archive-Tar</TITLE>
      <ABSTRACT>Manipulates TAR archives</ABSTRACT>
      <AUTHOR>Jos Boumans &lt;kane[at]cpan.org&gt;</AUTHOR>
      <IMPLEMENTATION>
        <ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.8" />
      </IMPLEMENTATION>
    </SOFTPKG>
    ...
  </REPOSITORYSUMMARY>

=item package.lst

  <?xml version="1.0" encoding="UTF-8"?>
  <REPOSITORYSUMMARY>
    <SOFTPKG NAME="Archive-Tar" VERSION="1,29,0,0">
      <TITLE>Archive-Tar</TITLE>
      <ABSTRACT>Manipulates TAR archives</ABSTRACT>
      <AUTHOR>Jos Boumans &lt;kane[at]cpan.org&gt;</AUTHOR>
      <IMPLEMENTATION>
        <DEPENDENCY NAME="IO-Zlib" VERSION="1,01,0,0" />
        <OS NAME="MSWin32" />
        <ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.8" />
        <CODEBASE HREF="Archive-Tar.tar.gz" />
      </IMPLEMENTATION>
    </SOFTPKG>
    ...
  </REPOSITORYSUMMARY>

=item package.xml

  <?xml version="1.0" encoding="UTF-8"?>
  <REPOSITORYSUMMARY ARCHITECTURE="MSWin32-x86-multi-thread-5.8">
    <SOFTPKG NAME="Archive-Tar" VERSION="1.29">
      <ABSTRACT>Manipulates TAR archives</ABSTRACT>
      <AUTHOR>Jos Boumans &lt;kane[at]cpan.org&gt;</AUTHOR>
      <IMPLEMENTATION>
        <ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.8" />
        <CODEBASE HREF="Archive-Tar.tar.gz" />
      </IMPLEMENTATION>
      <REQUIRE NAME="IO-Zlib" VERSION="1.01" />
      <PROVIDE NAME="Archive::Tar" VERSION="1.29" />
      <PROVIDE NAME="Archive::Tar::File" VERSION="1.21" />
    </SOFTPKG>
    ...
  </REPOSITORYSUMMARY>

=back

If multiple E<lt>IMPLEMETATIONE<gt> sections are present
in the ppd file, all will be included in the corresponding
summary files.

Options accepted by the I<new> constructor include

=over

=item rep =E<gt> '/path/to/ppds'

This option, which is required, specifies the path to where
the I<ppd> files are found. The summary files will be written
in this directory.

=item no_ppm4 =E<gt> 1

If this option is specified, the F<package.xml> file (which
contains some extensions used by ppm4) will not be generated.

=item arch =E<gt> 'MSWin32-x86-multi-thread-5.8'

If this option is given, it will be used as the
I<ARCHITECTURE> attribute of the I<REPOSITORYSUMMARY>
element of F<package.xml>.

=back

=head1 COPYRIGHT

This program is copyright, 2006, by Randy Kobes E<lt>r.kobes.uwinnipeg.caE<gt>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM> and L<PPM::Make>

=cut

