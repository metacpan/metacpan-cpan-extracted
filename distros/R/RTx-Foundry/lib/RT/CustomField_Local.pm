# $File: //depot/RT/rt/lib/RT/CustomField_Local.pm $ $Author: autrijus $
# $Revision: #10 $ $Change: 5491 $ $DateTime: 2003/04/28 09:06:47 $

use strict;
no warnings qw(redefine);

use vars qw(@TYPES %TYPES);

# Enumerate all valid types for this custom field
push @TYPES, (
    'SelectResolution',	# loc
    'SelectVersion',	# loc
);

# Populate a hash of types of easier validation
for (@TYPES) { $TYPES{$_} = 1};

sub IsReservedName {
    my ($self, $name) = @_;
    return scalar grep { lc($name) eq lc($_) } qw(
Architecture Attachments ContactInfo Email IntendedAudience Intro
License Maturity Name Password PasswordCheck PersonalHomepage Platform
ProgrammingLanguage ProjectName PublicDescription Rationale RealName
Resolution Severity Subcomponent Subject TargetVersion Type UnixName
    );
}

1;
