use 5.006;
# vim: ft=perl
use inc::Module::Install;

name          ('PHP-Strings');
version_from  ('Strings.pm');
abstract      ("Implement some of PHP's functions");
author        ('Petras Kudaras (kudarasp@cpan.org)');

requires( 'Params::Validate' => '0.70' );
requires( 'Scalar::Util'     => '1.13' );

for my $mod (qw( Test::More File::Slurp Test::Differences ))
{
    include_deps( $mod, 5.006 );
}


features (
     "Function `str_shuffle'" => [
        'List::Util' => '1.13',
     ],
     "Function `strip_tags'" => [
        'HTML::Entities' => '1.27',
        'HTML::Scrubber' => '0.06',
     ],
);
features (
    "PHP::Strings Development" => [
        -default => 0,
        'YAML'        => '0.35',
        'Template'    => '2.10',
        'B::Keywords' => '0.06',
    ],
);

auto_install();
&Meta->write;
&Makefile->write;

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'PHP::Strings',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
