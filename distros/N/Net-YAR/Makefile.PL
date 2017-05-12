use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2007 - Paul Seamons                                     #
#  Distributed under the same terms as Perl itself                   #
###----------------------------------------------------------------###

### lookup posible installed libraries
my $serialize;
foreach my $pkg (qw(JSON YAML::Syck YAML XML::Simple Data::URIEncode)) {
    (my $file = "$pkg.pm") =~ s|::|/|g;
    next if ! eval { require $file };
    $serialize = $pkg;
    last;
}
$serialize = 'Data::URIEncode' if ! $serialize; # need to install at least one


WriteMakefile(
              NAME          => "Net::YAR",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/Net/YAR.pm",
              VERSION_FROM  => "lib/Net/YAR.pm",
              INSTALLDIRS   => 'site',
              dist          => {
                DIST_DEFAULT => 'all tardist',
                COMPRESS     => 'gzip -vf',
                SUFFIX       => '.gz',
              },
              clean          => {
                FILES        => '*~',
              },
              realclean         => {
                FILES        => '*~',
              },
              PREREQ_PM  => {
                $serialize       => 0,
                'LWP::UserAgent' => 0,
                'HTTP::Request'  => 0,
                'HTTP::Headers'  => 0,
              },
              );

package MY;

sub postamble {
  return qq^
    
pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}

1;
