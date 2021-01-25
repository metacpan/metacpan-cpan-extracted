package Pod::Modifier;

use strict;
use warnings;
use Carp;

use Module::Util qw( module_fs_path );
use Pod::Select;
use File::Slurp qw(read_file);
use Pod::Perldoc::ToTerm;
use Pod::SectionToAdd;

use fields qw(_package _sections _optional_tags);

our $VERSION = 1.00;

sub new {
  my __PACKAGE__ $this = shift;

  my (%args) = @_;

  #----- create the class member variables -----#
  unless ( ref $this ) {
    $this = fields::new($this);
  }
  $this->{_package} = $args{PACKAGE};
  return $this;
}

sub addSection {
  my __PACKAGE__ $this = shift;
  my (%args) = @_;

  if ( ( defined $args{SECTION} ) && ( defined $args{SECTION_INDEX} ) ) {
    my $section = Pod::SectionToAdd->new(
      SECTION       => $args{SECTION},
      SECTION_INDEX => $args{SECTION_INDEX},
      BASE          => $args{BASE}
    );
    %{ $this->{_sections} } = () unless ( defined $this->{_sections} );
    $this->{_sections}{ $args{SECTION_INDEX} } = $section;
    if ( ( defined $args{OPTIONAL} ) && ( $args{OPTIONAL} == 1 ) ) {
      %{ $this->{_optional_tags} } = () unless ( defined $this->{_optional_tags} );
      $this->{_optional_tags}{ $args{SECTION} } = $args{OPTIONAL};
    }
    if ( defined $args{ALIAS} ) {
      $section->setAlias( $args{ALIAS} );
    }
  }
  return;
}

sub _getPodSections {
  my __PACKAGE__ $this = shift;
  my $package = shift;
  my $pod_string;
  $pod_string = read_file($package);
  my @sections = ( $pod_string =~ /=head1\s+(.+)/g );
  return \@sections;

}

sub _processOptionalTags {
  my __PACKAGE__ $this = shift;
  my $pod_string = shift;
  return $pod_string unless ( defined $this->{_optional_tags} );
  my $updated_pod = '';
  foreach ( split( /\n/, $pod_string ) ) {
    my $key = "$_";
    $key =~ s/^=head1\s+//;
    if ( exists $this->{_optional_tags}{"$key"} ) {
      $updated_pod .= $_ . "  (optional) \n";
    }
    else {
      $updated_pod .= $_ . "\n";
    }
  }
  return $updated_pod;
}

sub _parseCommonSectionFromFiles {
  my __PACKAGE__ $this = shift;
  my $section_obj = shift;

  my $section     = $section_obj->getSectionName;
  my @files_array = @{ $section_obj->getBaseFile };
  my $parser      = Pod::Select->new();

  open my ($str_fh), '>', \my $pod_output;

  foreach my $base (@files_array) {
    next unless ( defined $base );
    $parser->select("$section");
    $parser->parse_from_file( $base, $str_fh );
  }
  close $str_fh;

  my $alias = $section;
  if ( defined( $section_obj->getAlias ) ) {
    $alias = $section_obj->getAlias;
  }
  $pod_output =~ s/.*=head1.*$section.*//g;
  $pod_output = "=head1 $alias" . $pod_output;
  return $pod_output;
}

sub updatePod {
  my __PACKAGE__ $this = shift;
  my (%args) = @_;
  my $page = $args{'PAGE'};

  my $package  = $this->{_package};
  my @sections = @{ $this->_getPodSections($package) };
  my $parser   = Pod::Select->new();

  open my ($str_fh), '>', \my $full_pod;
  for my $iter ( 0 .. scalar(@sections) - 1 ) {
    if ( ( defined $this->{_sections} ) && ( exists $this->{_sections}{$iter} ) ) {
      my $base_pod = $this->{_sections}{$iter}->getBaseFile;
      warn("Cannot find required module for additional section in INC") unless ( defined $base_pod );
      if ( ref($base_pod) eq "ARRAY" ) {
        my $combined_pod = $this->_parseCommonSectionFromFiles( $this->{_sections}{$iter} );
        print $str_fh $combined_pod;
      }
      else {
        $parser->select( $this->{_sections}{$iter}->getSectionName );
        $parser->parse_from_file( $base_pod, $str_fh );
      }
    }
    my $section = $sections[$iter];
    $parser->select("$section");
    $parser->parse_from_file( $package, $str_fh );
  }
  close $str_fh;
  
  unless ($page) {
    close $full_pod;
    print $full_pod;
    return $full_pod;
  }

  open my $read_fh, '<', \$full_pod;

  my $newParser = Pod::Perldoc::ToTerm->new();
  open my $output_fh, '>', \my $formatted_pod;
  $newParser->parse_from_file( $read_fh, $output_fh );
  close $read_fh;

  $this->_page($formatted_pod);
  close $output_fh;

  return;
}

sub _page {
  my __PACKAGE__ $this = shift;
  my $formatted_pod = shift;

  my $pager = 'less';
  open( my $less, '|-', $pager, "-R" ) || warn("Cannot pipe to $pager: $!");
  print $less $formatted_pod;
  close($less);

  return;
}

1;

__END__

=head1 NAME

B<Pod::Modifier> - Add sections to an existing POD dynamically.

=head1 DESCRIPTION

B<Pod::Modifier> allows adding to a Perl Modules' POD, dynamically, sections from POD of other Perl Modules.
The alias (new 'head or header' to be given to) and index of appearance of these added sections can be changed
as per provided APIs. B<Pod::Modifier> by default would return a string of modified POD, which can then be 
parsed by a POD Parser of choice, optionally though, it can also act as a "POD to Usage", and it prints to
the terminal using 'less' pager.

=head1 SYNOPSYS

Some basic usage of this module is presented through an example below, please check APIs and Pod::SectionToAdd
for more advanced options.

Usage :

use Pod::Modifier;

# To get full path to current module

my $pkg = ref(__PACKAGE__);

$pkg =~ s/::/\//g;

$pkg .= ".pm";

my $pkg_fp = $INC{$pkg};

# Create modifier object

my $modifier = Pod::Modifier->new(PACKAGE=>"$pkg_fp");

# The following usage of addSection API will add a section 'OPTIONS' to the Pod of current file,

# and this new section is expected to be defined in list of files having their paths in array @bases.

# In the modified POD, this will be now at index '6', and aliased as 'GLOBAL OPTIONS'.

# That is, when the modified POD is printed, the section(s) 'OPTIONS' (combined if multiple files in @bases)

# will now show up as 6th section aliased as 'GLOBAL OPTIONS' in the new POD.

$modifier->addSection(SECTION=>"OPTIONS",SECTION_INDEX=>6,BASE=>\@bases,ALIAS=>"GLOBAL OPTIONS");

# To print the modified POD on pager as help, PAGE=>1 is used.

# The pager used is less, with -R option, Parser used is Pod::Perldoc::ToTerm

# To use own pod parser and pager, use without PAGE argument, or PAGE=>0, and process the returned Pod string.

$modifier->updatePod(PAGE=>1); # returns an undef with PAGE=>1
  
# To return it as string

my $pod_string = $modifier->updatePod();

=head2 APIs

=head3 B<new (PACKAGE=>"/path/to/CurrentPackage.pm")>

Class constructor.

=head3 B<addSection ( BASE => SCALAR|ARRAYREF
    SECTION  => SCALAR 
    SECTION_INDEX => SCALAR
    ALIAS => SCALAR (optional) )

Interface to add a section 'SECTION', defined in file(s) given by 'BASE', at index 'SECTION_INDEX',
renamed in current Pod as 'ALIAS'.

=head3 B<updatePod(PAGE => (0|1))>

Update and return the modified POD string, which can be parsed using Pod parser of choice.

=head2 ARGUMENTS

=head3 B<new>(PACKAGE=>'$package')

=over 4

=item C<PACKAGE =E<gt>> I<base>

SCALAR Path to the current file, to (the Pod of) which additinal sections are to be added.

=back

=head3 B<addSection>()

=over 4

=item C<BASE =E<gt>> I<base>

SCALAR The full path to perl module containing section to be added. Or,
ARRAYREF list of full paths of perl modules containing required section.

=item C<SECTION =E<gt>> I<section>

SCALAR Name of the head (1) section.

=item C<SECTION_INDEX =E<gt>> I<index>

SCALAR Attribute to set position of insertion for this section.

=item C<ALIAS =E<gt>> I<alias>

For multiple files, that is, where BASE is array reference, an alias can be used to rename the combined sections, using ALIAS.

=back

=head3 B<updatePod>(PAGE=>0|1)

=over 4

=item C<PAGE =E<gt>> I<0|1>

SCALAR Without an argument, or for PAGE=>0, the function will return the Pod as a string which can be parsed by
parser of choice. For PAGE=>1, '/bin/less' is used for paging and Pod::Perldoc::ToTerm for parsing. The output is, thus,
immediately paged to STDOUT in this case.

=back

=head1 CAVEATS

While paging directly using this module, it is assumed the pager 'less' is available in system, which is then
used with the -R option for constant repainting of terminal/ std output.
For proper cross platform compatibility it is advised not to use this module for paging.
Assumption is made that sections in modules would be starting as =head(n) and ending with =head(n)
of the next section, or EOF, whichever first.

=head1 SUPPORT

This module is managed in a GitHub repository,
L<https://github.com/codenho/PodModify> Feel free to fork and contribute, or
to clone and send patches!

Please use L<https://github.com/codenho/PodModify/issues/new> to file a bug
report.

More general questions or discussion about POD should be sent to the
C<pod-people@perl.org> mail list. Send an empty email to
C<pod-people-subscribe@perl.org> to subscribe.

=head1 AUTHOR

Udhav Verma E<lt>vermaudh@cpan.orgE<gt>

=head1 LICENSE

Pod::Modifier (the distribution) is licensed under the same terms as Perl5.

=head1 ACKNOWLEDGMENTS

Bincy Sarah Thomas, for feedback and help in writing this module.

=head1 SEE ALSO

L<Pod::Usage>, L<Pod::Perldoc>, L<Pod::Select>

=cut

