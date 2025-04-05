#!/bin/sh
#
# A "make dist" equivalent for systems on which "perl Makefile.PL" can't
# work because RT isn't installed.

PACKAGE='RT-Extension-TOTPMFA'
VERSION="$(awk -F = '/^(our|my)?[[:space:]]*\$VERSION[[:space:]]=/{print $2}' lib/RT/Extension/TOTPMFA.pm  | tr -dc '0-9.')"

cat > META.yml <<EOF
---
abstract: 'Multi-factor authentication with time-based one-time passcodes'
author:
  - 'Andrew Wood.'
build_requires:
  ExtUtils::MakeMaker: 6.59
configure_requires:
  ExtUtils::MakeMaker: 6.59
distribution_type: module
dynamic_config: 1
generated_by: 'Module::Install version 1.19'
license: gpl_3
meta-spec:
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
  version: 1.4
name: ${PACKAGE}
no_index:
  directory:
    - html
    - inc
requires:
  perl: 5.10.1
resources:
  license: http://opensource.org/licenses/gpl-license.php
  repository: https://codeberg.org/ivarch/rt-extension-totpmfa
version: '${VERSION}'
x_module_install_rtx_version: '0.44'
x_requires_rt: 5.0.0
x_rt_too_new: 5.2.0
EOF

set -e
rm -rf ${PACKAGE}-${VERSION}
perl -Iinc -MExtUtils::Manifest=manicopy,maniread -e "manicopy(maniread(),'${PACKAGE}-${VERSION}', 'best');"
cd ${PACKAGE}-${VERSION}
perl -Iinc -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
  -e '    or die "Could not add META.yml to MANIFEST: ${'\''@'\''}"'
perl -Iinc -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
  -e '    or die "Could not add META.json to MANIFEST: ${'\''@'\''}"'
perl -Iinc -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
  -e '    or die "Could not add SIGNATURE to MANIFEST: ${'\''@'\''}"'
touch SIGNATURE
cpansign -s
cd ..
perl -Iinc -I. -MModule::Install::Admin -e "dist_preop(q(${PACKAGE}-${VERSION}))"
tar cvf ${PACKAGE}-${VERSION}.tar ${PACKAGE}-${VERSION}
rm -rf ${PACKAGE}-${VERSION}
gzip --best ${PACKAGE}-${VERSION}.tar
echo "Created ${PACKAGE}-${VERSION}.tar.gz"
perl -Iinc -l -e 'print '\''Warning: Makefile possibly out of date with lib/RT/Extension/TOTPMFA.pm'\''' \
  -e '    if -e '\''lib/RT/Extension/TOTPMFA.pm'\'' and -M '\''lib/RT/Extension/TOTPMFA.pm'\'' < -M '\''Makefile'\'';'
