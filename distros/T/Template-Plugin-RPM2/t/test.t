use Test::More tests => 1;

use Template;

my $t = <<'END';
[% USE pkg = RPM2(file) -%]
Name:     [% pkg.name %]
Version:  [% pkg.version %]
Release:  [% pkg.release %]
Group:    [% pkg.group %]
Packager: [% pkg.packager %]
END

my $out = <<'END';
Name:     perl-AudioFile-Info-MP3-ID3Lib
Version:  1.07
Release:  1.fc11
Group:    Development/Libraries
Packager: Dave Cross <dave@mag-sol.com>
END

my $tt = Template->new;
my $result;
$tt->process(\$t, { file => 't/test.rpm' }, \$result)
  or die $tt->error;
is($result, $out);
