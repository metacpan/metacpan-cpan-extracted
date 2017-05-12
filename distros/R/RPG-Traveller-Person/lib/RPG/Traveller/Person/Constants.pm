package RPG::Traveller::Person::Constants;
use strict;
require Exporter;
our @ISA     = qw(Exporter);
our $VERSION = "1.011";

# ABSTRACT:  this module defines a host of constants used for character generation
#

# Branch of "service" contants

use constant ARMY       => 1;
use constant BARBARIAN  => 2;
use constant BELTER     => 3;
use constant BUREAUCRAT => 4;
use constant DIPLOMAT   => 5;
use constant DOCTOR     => 6;
use constant FLYER      => 7;
use constant HUNTER     => 8;
use constant MARINE     => 9;
use constant MERCHANT   => 10;
use constant NAVY       => 11;
use constant NOBLE      => 12;
use constant OTHER      => 13;
use constant PIRATE     => 14;
use constant ROGUE      => 15;
use constant SAILOR     => 16;
use constant SCIENTIST  => 17;
use constant SCOUT      => 18;

my @career_strings = qw/  undef
  Army Barbarian Belter Bureaucrat Diplomat Doctor Flyer Hunter Marine
  Merchant Navy Noble Other Pirate Rogue Sailor Scientist Scout
  /;

# Skill related constants
use constant ACEDEMIC                  => 1;
use constant ADAVNCED_COMBAT_RIFLE     => 2;
use constant ADMINISTRATON             => 3;
use constant AIRCRAFT                  => 4;
use constant ANIMAL_HANDLING           => 5;
use constant ARCHAIC_WEAPONS           => 6;
use constant ARTISAN                   => 7;
use constant ASSUAL_RIFLE              => 8;
use constant AUTOCANNON                => 9;
use constant AXE                       => 10;
use constant BATTLE_AXE                => 11;
use constant BATTLE_DRESS              => 12;
use constant BAYONET                   => 13;
use constant BIOLOGY                   => 14;
use constant BLADE                     => 15;
use constant BLADE_COMBAT              => 16;
use constant BLOWGUN                   => 17;
use constant BODY_PISTOL               => 18;
use constant BOLA                      => 19;
use constant BOOMERANG                 => 20;
use constant BOW                       => 21;
use constant BRAWLING                  => 22;
use constant BRIBERY                   => 23;
use constant BROADSWORD                => 24;
use constant BROKER                    => 25;
use constant CARBINE                   => 26;
use constant CAROUSING                 => 27;
use constant CHEMISTRY                 => 28;
use constant COMBAT_ENGINEERING        => 29;
use constant COMMUNICATIONS            => 30;
use constant COMPUTER                  => 31;
use constant CROSSBOW                  => 32;
use constant CUDGEL                    => 33;
use constant CUTLASS                   => 34;
use constant DAGGER                    => 35;
use constant DEMOLITION                => 36;
use constant DEMOLITIONS               => 37;
use constant DISGUISE                  => 38;
use constant EARLY_FIREARMS            => 39;
use constant ECONOMIC                  => 40;
use constant ELECTRONICS               => 41;
use constant ENERGY_WEAPONS            => 42;
use constant ENGINEERING               => 43;
use constant ENVIRONMENTAL             => 44;
use constant EQUESTRIAN                => 45;
use constant EXPLORATION               => 46;
use constant FIELD_ARTILLERY_GUNNERY   => 47;
use constant FOIL                      => 48;
use constant FORENSIC                  => 49;
use constant FORWARD_OBSERVER          => 50;
use constant FUSION_GUN                => 51;
use constant GAMBLING                  => 52;
use constant GAUSS_RIFLE               => 53;
use constant GENETICS                  => 54;
use constant GRAV_BELT                 => 55;
use constant GRAV_VEHICLE              => 56;
use constant GRAVITICS                 => 57;
use constant GRENADE_LAUNCHER          => 58;
use constant GUARD_HUNTING_BEASTS      => 59;
use constant GUN_COMBAT                => 60;
use constant GUNNERY                   => 61;
use constant HALBERD                   => 62;
use constant HAND_AXE                  => 63;
use constant HAND_COMBAT               => 64;
use constant HANDGUN                   => 65;
use constant HEAVY_WEAPONS             => 66;
use constant HELICOPTER                => 67;
use constant HERDING                   => 68;
use constant HIGH_ENERGY_WEAPONS       => 69;
use constant HIGH_GRAVITY_ENVIRONMENT  => 70;
use constant HISTORY                   => 71;
use constant HOVERCRAFT                => 72;
use constant HUNTING                   => 73;
use constant INBORN                    => 74;
use constant INSTRUCTION               => 75;
use constant INTERPERSONAL             => 76;
use constant INTERROGATION             => 77;
use constant INTERVIEW                 => 78;
use constant JACK_OF_ALL_TRADES        => 79;
use constant JET_PROPELLED_AIRCRAFT    => 80;
use constant LARGE_BLADE               => 81;
use constant LARGE_WATERCRAFT          => 82;
use constant LASER_PISTOL              => 83;
use constant LASER_RIFLE               => 84;
use constant LEADER                    => 85;
use constant LEGAL                     => 86;
use constant LIAISON                   => 87;
use constant LIGHT_ASSAULT_GUN         => 88;
use constant LIGHTER_THAN_AIRCRAFT     => 89;
use constant LINGUISTICS               => 90;
use constant MACHINE_GUN               => 91;
use constant MASS_DRIVERS              => 92;
use constant MECHANICAL                => 93;
use constant MEDICAL                   => 94;
use constant MENTAL                    => 95;
use constant MESON_GUNS                => 96;
use constant MORTARS_AND_HOWITZERS     => 97;
use constant NAVAL_ARCHITECT           => 98;
use constant NAVIGATION                => 99;
use constant NEURAL_PISTOL             => 100;
use constant NEURAL_RIFLE              => 101;
use constant NEURAL_WEAPONS            => 102;
use constant PERSUASION                => 103;
use constant PHYSICAL                  => 104;
use constant PHYSICS                   => 105;
use constant PIKE                      => 106;
use constant PILOT                     => 107;
use constant PISTOL                    => 108;
use constant PLASMA_GUN                => 109;
use constant POLEARM                   => 110;
use constant PROPELLER_DRIVEN_AIRCRAFT => 111;
use constant PROSPECTING               => 112;
use constant RECON                     => 113;
use constant RECRUITING                => 114;
use constant REVOLVER                  => 115;
use constant RIFLE                     => 116;
use constant ROBOT_OPERATIONS          => 117;
use constant ROBOTICS                  => 118;
use constant SCIENCE                   => 119;
use constant SCREENS                   => 120;
use constant SENSOR_OPERATIONS         => 121;
use constant SHIPS_BOAT                => 122;
use constant SHIPS_TACTICS             => 123;
use constant SLING                     => 124;
use constant SMALL_BLADE               => 125;
use constant SMALL_WATERCRAFT          => 126;
use constant SNUB_PISTOL               => 127;
use constant SPACE                     => 128;
use constant SPACE_COMBAT              => 129;
use constant SPEAR                     => 130;
use constant SPECIAL_COMBAT            => 131;
use constant SPECIAL_TECHNOLOGY        => 132;
use constant SPINAL_MOUNTS             => 133;
use constant STEALTH                   => 134;
use constant STEWARD                   => 135;
use constant STREETWISE                => 136;
use constant SUBMACHINEGUN             => 137;
use constant SURVEY                    => 138;
use constant SURVIVAL                  => 139;
use constant SWORD                     => 140;
use constant TACTICS                   => 141;
use constant TECHNICAL                 => 142;
use constant TRACKED_VEHICLE           => 143;
use constant TRADER                    => 144;
use constant TURRET_WEAPONS            => 145;
use constant VRF_GAUSE_GUN             => 146;
use constant VACCUM_SUIT               => 147;
use constant VEHICLE                   => 148;
use constant VICE                      => 149;
use constant ZERO_G_ENVIRONMENT        => 150;
use constant LAST_SKILL                => 150;

# Conversion of integers to alpha
use constant GAPPEDALPHA => qw/
  0 1 2 3 4 5 6 7 8 9
  A B C D E F G H  J
  K L M N  P Q R S T
  U V W X Y Z /;

use constant NONGAPPEDALPHA => qw/
  0 1 2 3 4 5 6 7 8 9
  A B C D E F G H I J
  K L M N O P Q R S T
  U V W X Y Z /;

our %EXPORT_TAGS = (
    'all' => [
        qw(
          ACEDEMIC ADAVNCED_COMBAT_RIFLE ADMINISTRATON AIRCRAFT ANIMAL_HANDLING
          ARCHAIC_WEAPONS ARTISAN ASSUAL_RIFLE AUTOCANNON AXE BATTLE_AXE
          BATTLE_DRESS BAYONET BIOLOGY BLADE BLADE_COMBAT BLOWGUN BODY_PISTOL
          BOLA BOOMERANG BOW BRAWLING BRIBERY BROADSWORD BROKER CARBINE
          CAROUSING CHEMISTRY COMBAT_ENGINEERING COMMUNICATIONS COMPUTER
          CROSSBOW CUDGEL CUTLASS DAGGER DEMOLITION DEMOLITIONS DISGUISE
          EARLY_FIREARMS ECONOMIC ELECTRONICS ENERGY_WEAPONS ENGINEERING
          ENVIRONMENTAL EQUESTRIAN EXPLORATION FIELD_ARTILLERY_GUNNERY FOIL
          FORENSIC FORWARD_OBSERVER FUSION_GUN GAMBLING GAUSS_RIFLE GENETICS
          GRAV_BELT GRAV_VEHICLE GRAVITICS GRENADE_LAUNCHER GUARD_HUNTING_BEASTS
          GUN_COMBAT GUNNERY HALBERD HAND_AXE HAND_COMBAT HANDGUN HEAVY_WEAPONS
          HELICOPTER HERDING HIGH_ENERGY_WEAPONS HIGH_GRAVITY_ENVIRONMENT
          HISTORY HOVERCRAFT HUNTING INBORN INSTRUCTION INTERPERSONAL
          INTERROGATION INTERVIEW JACK_OF_ALL_TRADES JET_PROPELLED_AIRCRAFT
          LARGE_BLADE LARGE_WATERCRAFT LASER_PISTOL LASER_RIFLE LEADER LEGAL
          LIAISON LIGHT_ASSAULT_GUN LIGHTER_THAN_AIRCRAFT LINGUISTICS
          MACHINE_GUN MASS_DRIVERS MECHANICAL MEDICAL MENTAL MESON_GUNS
          MORTARS_AND_HOWITZERS NAVAL_ARCHITECT NAVIGATION NEURAL_PISTOL
          NEURAL_RIFLE NEURAL_WEAPONS PERSUASION PHYSICAL PHYSICS PIKE PILOT
          PISTOL PLASMA_GUN POLEARM PROPELLER_DRIVEN_AIRCRAFT PROSPECTING RECON
          RECRUITING REVOLVER RIFLE ROBOT_OPERATIONS ROBOTICS SCIENCE SCREENS
          SENSOR_OPERATIONS SHIPS_BOAT SHIPS_TACTICS SLING SMALL_BLADE
          SMALL_WATERCRAFT SNUB_PISTOL SPACE SPACE_COMBAT SPEAR SPECIAL_COMBAT
          SPECIAL_TECHNOLOGY SPINAL_MOUNTS STEALTH STEWARD STREETWISE
          SUBMACHINEGUN SURVEY SURVIVAL SWORD TACTICS TECHNICAL TRACKED_VEHICLE
          TRADER TURRET_WEAPONS VRF_GAUSE_GUN VACCUM_SUIT VEHICLE VICE
          ZERO_G_ENVIRONMENT LAST_SKILL int2skill
          ARMY BARBARIAN BELTER BUREAUCRAT DIPLOMAT DOCTOR FLYER HUNTER MARINE
          MERCHANT NAVY NOBLE OTHER PIRATE ROGUE SAILOR SCIENTIST SCOUT
          int2career GAPPEDALPHA NONGAPPEDALPHA int2alpha int2galpha
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

my @skill_strings = (
    undef,                      "Acedemic",
    "Adavnced Combat Rifle",    "Administraton",
    "Aircraft",                 "Animal Handling",
    "Archaic Weapons",          "Artisan",
    "Assual Rifle",             "Autocannon",
    "Axe",                      "Battle Axe",
    "Battle Dress",             "Bayonet",
    "Biology",                  "Blade",
    "Blade Combat",             "Blowgun",
    "Body Pistol",              "Bola",
    "Boomerang",                "Bow",
    "Brawling",                 "Bribery",
    "Broadsword",               "Broker",
    "Carbine",                  "Carousing",
    "Chemistry",                "Combat Engineering",
    "Communications",           "Computer",
    "Crossbow",                 "Cudgel",
    "Cutlass",                  "Dagger",
    "Demolition",               "Demolitions",
    "Disguise",                 "Early Firearms",
    "Economic",                 "Electronics",
    "Energy Weapons",           "Engineering",
    "Environmental",            "Equestrian",
    "Exploration",              "Field Artillery Gunnery",
    "Foil",                     "Forensic",
    "Forward Observer",         "Fusion Gun",
    "Gambling",                 "Gauss Rifle",
    "Genetics",                 "Grav Belt",
    "Grav Vehicle",             "Gravitics",
    "Grenade Launcher",         "Guard Hunting Beasts",
    "Gun Combat",               "Gunnery",
    "Halberd",                  "Hand Axe",
    "Hand Combat",              "Handgun",
    "Heavy Weapons",            "Helicopter",
    "Herding",                  "High Energy Weapons",
    "High Gravity Environment", "History",
    "Hovercraft",               "Hunting",
    "Inborn",                   "Instruction",
    "Interpersonal",            "Interrogation",
    "Interview",                "Jack Of All Trades",
    "Jet Propelled Aircraft",   "Large Blade",
    "Large Watercraft",         "Laser Pistol",
    "Laser Rifle",              "Leader",
    "Legal",                    "Liaison",
    "Light Assault Gun",        "Lighter Than Aircraft",
    "Linguistics",              "Machine Gun",
    "Mass Drivers",             "Mechanical",
    "Medical",                  "Mental",
    "Meson Guns",               "Mortars and Howitzers",
    "Naval Architect",          "Navigation",
    "Neural Pistol",            "Neural Rifle",
    "Neural Weapons",           "Persuasion",
    "Physical",                 "Physics",
    "Pike",                     "Pilot",
    "Pistol",                   "Plasma Gun",
    "Polearm",                  "Propeller Driven Aircraft",
    "Prospecting",              "Recon",
    "Recruiting",               "Revolver",
    "Rifle",                    "Robot Operations",
    "Robotics",                 "Science",
    "Screens",                  "Sensor Operations",
    "Ship's Boat",              "Ship's Tactics",
    "Sling",                    "Small Blade",
    "Small Watercraft",         "Snub Pistol",
    "Space",                    "Space Combat",
    "Spear",                    "Special Combat",
    "Special Technology",       "Spinal Mounts",
    "Stealth",                  "Steward",
    "Streetwise",               "Submachinegun",
    "Survey",                   "Survival",
    "Sword",                    "Tactics",
    "Technical",                "Tracked Vehicle",
    "Trader",                   "Turret Weapons",
    "VRF Gause Gun",            "Vaccum Suit",
    "Vehicle",                  "Vice",
    "Zero-G Environment",
);

sub int2skill {
    return $skill_strings[ $_[0] ];
}

sub int2career {
    return $career_strings[ $_[0] ];
}

sub int2alpha {
    return (NONGAPPEDALPHA)[ $_[0] ];
}

sub int2galpha {
    return (GAPPEDALPHA)[ $_[0] ];
}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Person::Constants - this module defines a host of constants used for character generation

=head1 VERSION

version 1.020

=head1 METHODS

=head2 int2skill

returns a string based on the value of the integer passed to it.

        int2skill(PILOT); # returns "Pilot"

=head2 int2career

returns a string based on the value of the integer passwd to it

        int2career(MARINE);  # returns "Marine"

=head2 int2alpha

returns 0-9 or A-Z with no gaps for I or O depending on the integer passed to it

    int2alpha(15); # returns "F"
    int2alpha(35); # returns "Z"

=head2 int2galpha

same as int2alpha but leaves a gap for the letters I and O

=head1 SEE ALSO

=over 4

*L<Moose>
*L<perl>

=back

=head1 AUTHOR

Peter L. Berghold <cpan@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
