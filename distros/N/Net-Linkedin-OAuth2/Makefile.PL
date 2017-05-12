
use strict;
use warnings;
use CPAN;

use 5.008008;

use ExtUtils::MakeMaker 6.30;

# ExtUtils::AutoInstall Bootstrap Code, version 7.
    BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.45;$p->VERSION||0>=$v
    or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
    (!defined($e)||$e!~m/--(?:default|skip|testonly)/and-t STDIN or
    eval"use ExtUtils::MakeMaker;WriteMakefile(PREREQ_PM=>{'$p',$v}
    );1"and exit)and print"==> $p $v required. Install it from CP".
    "AN? [Y/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and
    do{if (eval '$>' and lc(`sudo -V`) =~ /version/){system('sudo',
    $^X,"-MCPANPLUS","-e","CPANPLUS::install $p");eval"use $p $v;1"
    ||system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")}eval{
    require CPANPLUS;CPANPLUS::install$p};eval"use $p $v;1"or eval{
    require CPAN;CPAN::install$p};eval"use $p $v;1"||die"*** Please
    manually install $p $v from cpan.org first...\n"}}};
    
use ExtUtils::AutoInstall (
        -core           => [            # mandatory modules
		    'XML::Hash' => 0,
		    'JSON::Any'	=>	0,
		    'Digest::MD5'	=>	0,
		    'LWP::UserAgent'	=>	0,
		    'Carp'	=>	0
        ]        
    );
    
my %WriteMakefileArgs = (
  "ABSTRACT" => "An easy way to authenticate users via LinkedIn",
  "AUTHOR" => "Asaf Klibansky <discobeta\@gmail.com>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.42",
    #"Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.42"
  },
  "DISTNAME" => "Net-Linkedin-OAuth2",
  "LICENSE" => "perl",
  "NAME" => "Net::Linkedin::OAuth2",
  "PREREQ_PM" => {
    'XML::Hash' => 0,
    'JSON::Any'	=>	0,
    'Digest::MD5'	=>	0,
    'LWP::UserAgent'	=>	0,
    'Carp'	=>	0,
  },
  'VERSION_FROM' => 'lib/Net/Linkedin/OAuth2.pm',
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);





