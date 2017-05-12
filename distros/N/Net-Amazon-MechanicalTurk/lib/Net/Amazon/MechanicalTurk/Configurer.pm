package Net::Amazon::MechanicalTurk::Configurer;
use strict;
use warnings;
use Exporter;
use File::Spec;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::Constants ':ALL';
use Net::Amazon::MechanicalTurk::OSUtil;
use Net::Amazon::MechanicalTurk::Properties;

our $VERSION = '1.00';

our @ISA = qw{ Exporter };
our @EXPORT = qw { configure };

my $CONFIG_SETTINGS = [
    {   setting => 'AccessKeyId',
        prompt  => "\nEnter your AWS Access Key Id: ",
        aliases => [qw{ accessKey }]
    },
    {   setting => 'SecretAccessKey',
        prompt  => "\nEnter your AWS Secret Access Key: ",
        aliases => [qw{ secretKey }]
    },
#   {   setting => 'service_url',
#       prompt =>
#         "\nMechanicalTurk URL\n" .
#         "  Test URL:\n".
#         "    $SANDBOX_URL\n\n".
#         "  Production URL:\n".
#         "    $PRODUCTION_URL\n\n".
#         "  (defaults to sandbox url)\n".
#         "Enter url: ",
#        aliases => [qw{ serviceUrl }],
#        default => $SANDBOX_URL,
#        validate => qr/^https?:\/\//
#    },
#    {   setting => 'service_version',
#        prompt =>
#            "\nMechanicalTurk Web Service Version\n" .
#            "  (defaults to $DEFAULT_SERVICE_VERSION)\n".
#            "Enter version: ",
#        aliases => [qw{ serviceVersion }],
#        default => $DEFAULT_SERVICE_VERSION,
#        validate => qr/^\d{4}-\d{2}-\d{2}$/
#    }
];

sub configure {
    my $homedir = Net::Amazon::MechanicalTurk::OSUtil->homeDirectory;
    my $propertyDir =  "$homedir/$PROP_GLOBAL_DIR";
    my $propertyFile = File::Spec->catfile( $propertyDir, $PROP_GLOBAL_AUTH );

    my $message = "Do you want to reconfigure your settings?\n[yes/no] ";
    my $properties;
    if (-f $propertyFile) {
        $properties = Net::Amazon::MechanicalTurk::Properties->read($propertyFile);
        print "\nMechanical Turk Configuration Properties:\n";
        print "\nLocation: $propertyFile\n";
        displaySettings("\nSettings:\n", $properties);
    }
    else {
        $message = "MechanicalTurk has not been configured. Would you like to perform setup?\n[yes/no] ";
    }
    
    my $answer = lc(prompt($message, qr/^(yes|no)$/i));
    if ($answer eq "no") {
        return;
    }
    
    my $newSettings = getNewSettings();
        if ($newSettings) {
          if (!-d "$propertyDir") {
            eval { mkdir( $propertyDir ); };
          }
        Net::Amazon::MechanicalTurk::Properties->write(
            $newSettings,
            $propertyFile  #,
#            "---------------------------------\n" .
#            "MechanicalTurk config generated on " . scalar localtime() . ".\n" .
#            "---------------------------------"
        );
        # This file should not be readable or writable to anyone else.
        eval { chmod(0600, $propertyFile); };
    }
}

sub displaySettings {
    my ($header, $properties) = @_;
    print $header;
    foreach my $key (sort keys %$properties) {
        printf "  %-18s %s\n", $key . ":", $properties->{$key};
    }
    print "\n";
}

sub getNewSettings {
    while (1) {
        my $settings = promptNewSettings();
        displaySettings("\nNew Settings:\n", $settings);
        my $ans = lc(prompt("Do you want to keep these settings?\n[yes/no] ", qr/^(yes|no)$/));
        if ($ans eq "yes") {
            return $settings;
        }
        else {
            $ans = lc(prompt("Do you want to reconfigure again?\n[yes/no] ", qr/^(yes|no)$/));
            if ($ans eq "no") {
                return undef;
            }
        }
    }
}

sub promptNewSettings {
    $|=1;
    my $newSettings = {};
    foreach my $settingInfo (@{$CONFIG_SETTINGS}) {
        while (1) {
            print $settingInfo->{prompt};
            my $answer = <STDIN>;
            chomp($answer);
            $answer =~ s/^\s+//;
            $answer =~ s/\s+$//;
            if ($answer eq "") {
                if (exists $settingInfo->{default}) {
                    $newSettings->{$settingInfo->{setting}} = $settingInfo->{default};
                    last;
                }
            }
            elsif (exists $settingInfo->{validate}) {
                if ($answer !~ $settingInfo->{validate}) {
                    printf "Invalid value for %s.", $settingInfo->{setting};
                }
                else {
                    $newSettings->{$settingInfo->{setting}} = $answer;
                    last;
                }
            }
            else {
                $newSettings->{$settingInfo->{setting}} = $answer;
                last;
            }
        }
    }
    return $newSettings;
}

sub prompt {
    my ($prompt, $validator) = @_;
    $|=1;
    while (1) {
        print $prompt;
        my $answer = <STDIN>;
        chomp($answer);
        if (UNIVERSAL::isa($validator, "CODE")) {
            if ($validator->($answer)) {
                return $answer;
            }
        }
        elsif ($answer =~ $validator) {
            return $answer;
        }
    }
}

return 1;
