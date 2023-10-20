use strict;
use warnings;

use ExtUtils::MakeMaker qw(WriteMakefile);

my (%MAKEFILE);

%MAKEFILE = (
  'NAME'          => 'Net::validMX',
  'DISTNAME'      => 'Net-validMX',
  'VERSION_FROM'  => 'lib/Net/validMX.pm',
  'PREREQ_PM'     => {
		       'Test::More' =>0,
                       'Net::DNS' => 0.53
                     },
  'dist'          => {
                       COMPRESS=>'gzip -9f', 
                       SUFFIX => 'gz', 
                       PREOP => "cd \$(DISTVNAME) && pod2text lib/Net/validMX.pm > README && \$(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{README} => q{Module README created from pod2text}}) } '"
                     },
  'LICENSE'       => 'Artistic',
  'AUTHOR'        => 'The McGrail Foundation & Kevin A. McGrail <kevin.mcgrail-netvalidmx@mcgrail.com>',
  'ABSTRACT'      => 'Perl DNS mail exchange & email format validation module',
  'PMLIBDIRS' => [ 'lib' ],
  'EXE_FILES' => [ 'example/check_email_and_mx.pl' ],
  'INSTALLDIRS' => 'perl',
  'META_MERGE' => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/The-McGrail-Foundation/Net-validMX.git',
                 web  => 'https://github.com/The-McGrail-Foundation/Net-validMX',
             },
             bugtracker => {
                 web => 'https://github.com/The-McGrail-Foundation/Net-validMX/issues'
             },
         },
    },
);

WriteMakefile(%MAKEFILE);

print "\nvalidMX\n\n'make install' to install the module and program.\n";

#Thanks to Net::DNS for the trick on how to add the license to the META.yml file!
package MY;

sub metafile {
  my $self    = shift;
  my $meta    = $self->SUPER::metafile_target(@_);

  my ($echo, $extra);

  ($echo) = $self->echo('abstract: '.$MAKEFILE{'ABSTRACT'}, '$(DISTVNAME)/META.yml', 1);
  $extra .= "\t$echo\n";

  ($echo) = $self->echo('author: '.$MAKEFILE{'AUTHOR'}, '$(DISTVNAME)/META.yml', 1);
  $extra .= "\t$echo\n";

  return $meta.$extra;
}
