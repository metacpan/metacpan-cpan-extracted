#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Bundle - Bundle Perl Libraries

=head1 DESCRIPTION

Rex::Bundle is a Rex module to install needed perl modules into a private folder separated from the system librarys.

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Wiki: L<https://github.com/krimdomu/rex-bundle/wiki>

=item * Bug Tracker: L<https://github.com/krimdomu/rex-bundle/issues>

=back

=head1 USAGE

Create a I<Rexfile> in your project directory and add the following content to it:

 install_to 'vendor/perl'
    
 desc "Check and install dependencies";
 task "deps", sub {
    mod "Mod1", url => "git://...";
    mod "Foo::Bar";
    # ...
 };

Now you can check if all dependencies are met (and if not, it will install the needed modules) with I<rex deps>.

After you've installed the dependencies you can use them by appending the I<install_to> directory to @INC.

 use lib "vendor/perl";

=cut

package Rex::Bundle;

use strict;
use warnings;
use version;

our $VERSION = '0.5.0';

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT $install_dir $rex_file_dir);
use Cwd qw(getcwd);
use File::Basename qw(basename);
use YAML;
use Data::Dumper;

use Rex -base;

my $has_lwp  = 0;
my $has_curl = 0;
my $has_wget = 0;

system("which wget >/dev/null 2>&1");
$has_wget = !$?;

system("which curl >/dev/null 2>&1");
$has_curl = !$?;

eval {
   require LWP::Simple;
   $has_lwp = 1;
};

@EXPORT = qw(mod install_to perl);

# currently only supports $name
sub mod {
   my $name = shift;
   return if $name eq "perl";
   my $opts = { @_ };
   
   $rex_file_dir = getcwd;

   if(!$install_dir) {
      print STDERR "You have to define install_to in your Rexfile\n";
      exit 1;
   }

   unless(exists $opts->{'force'}) {

      eval { my $m = $name; $m =~ s{::}{/}g; require "$m.pm"; }; 

      unless ($@) {

         my $installed_version = $name->VERSION;

         if(exists $opts->{"version"}) {

            if( version->parse($installed_version) >= version->parse($opts->{"version"}) && ! $@) {
               print STDERR "$name is already installed.\n";
               return;
            }

         } elsif(! $@) {

            print STDERR "$name is already installed.\n";
            return;

         }

      }

   }

   my $rnd = _gen_rnd();

   my($file_name, $dir_name, $new_dir);
   if(defined $opts->{'url'}) {
      $new_dir = $name;
      $new_dir =~ s{::}{-}g;
      $new_dir .= "-$rnd";
      _clone_repo($opts->{'url'}, $new_dir);
   } else {
      my $version_to_check = $opts->{"version"};
      my $mod_url;
      for (1..2) {
         $mod_url = _lookup_module_url($name, $opts->{"version"});
         if(_download($mod_url)) {
            last;
         }
         $version_to_check = 0;
      }

      ($file_name) = $mod_url =~ m{/CPAN/authors/id/.*/(.*?\.(?:tar\.gz|tgz|tar\.bz2|zip))};
      ($dir_name) = $mod_url =~ m{/CPAN/authors/id/.*/(.*?)\.(?:tar\.gz|tgz|tar\.bz2|zip)};
      $new_dir = $dir_name . "-" . $rnd;

      _extract_file($file_name);
      if(! -d _work_dir() . "/" . $dir_name) {
         my $dir_wout_version = $dir_name;
         $dir_wout_version =~ s/\-[\d\.]+$//;
         if(-d _work_dir() . "/" . $dir_wout_version) {
            $dir_name = $dir_wout_version;
         }
      }
      _rename_dir($dir_name, $new_dir);
   }

   _install_deps($new_dir);
   _configure($new_dir);
   _install_deps($new_dir);
   _configure($new_dir);

   _make($new_dir);
   unless(exists $opts->{'notest'}) {
      _test($new_dir);
   }
   _install($new_dir);
}

sub _install_deps {
   my ($new_dir) = @_;
   for my $mod_info (_get_deps($new_dir)) {
      for my $mod (keys %$mod_info) {
         unless ($mod_info->{$mod}) {
            mod($mod);
         }
         else {
            mod($mod, version => $mod_info->{$mod});
         }
      }
   }


}

sub install_to {
   $install_dir = shift;
   lib->import(getcwd . '/' . $install_dir);
   $ENV{'PATH'} = $install_dir . '/bin:' . $ENV{'PATH'};
   $ENV{'PERL5LIB'} = $install_dir . ':' . ( $ENV{'PERL5LIB'} || '' );
   $ENV{'PERLLIB'} = $install_dir . ':' . ( $ENV{'PERLLIB'} || '' );

   my @new_path = split(/:/, $ENV{PATH});

   Rex::Config->set_path(\@new_path);
}

sub perl {
   my $cmd = "";

   $cmd .= "PERL5LIB=$install_dir" . ':' . ( $ENV{'PERL5LIB'} || '' );
   $cmd .= "PERLLIB=$install_dir" . ':' . ( $ENV{'PERLLIB'} || '' );

   $cmd .= " " . join(" ", @_);

   Rex::Logger::debug("executing: $cmd");

   system $cmd;
}

# private functions
sub _lookup_module_url {
   my ($name, $version) = @_;
   my $url = 'http://search.cpan.org/perldoc?' . $name;
   my $html = _get_http($url);
   my ($dl_url) = $html =~ m{<a href="(/CPAN/authors/id/.*?\.(?:tar\.gz|tgz|tar\.bz2|zip))">};

   if($version) {
      my ($path, $format) = ($dl_url =~ m{(/CPAN/authors/id/./../[^/]+/).*?\.(tar\.gz|tgz|tar\.bz2|zip)$});
      my $file_name = $name;
      $file_name =~ s/::/-/g;
      my $tmp_dl_url = $path . $file_name . "-$version.$format";
   }

   if($dl_url) {
      return $dl_url;
   } else {
      die("module not found ($url).");
   }
}

sub _get_http {
   my ($url) = @_;

   my $html;
   if($has_curl) {
      $html = qx{curl -# -L '$url' 2>/dev/null};
   }
   elsif($has_wget) {
      $html = qx{wget -O - '$url' 2>/dev/null};
   }
   elsif($has_lwp) {
      $html = LWP::Simple::get($url);
   }
   else {
      die("No tool found to download something. (curl, wget, LWP::Simple)");
   }

   return $html;
}

sub _download {
   my ($url) = @_;

   my $cwd = getcwd;
   chdir(_work_dir());
   if($has_wget) {
      _call("wget http://search.cpan.org$url >/dev/null 2>&1");
      unless($? == 0) {
         print "Failed downloading http://search.cpan.org$url\n";
         return 0;
      }
   }
   elsif($has_curl) {
      _call("curl -L -O -# http://search.cpan.org$url >/dev/null 2>&1");
      unless($? == 0) {
         print "Failed downloading http://search.cpan.org$url\n";
         return 0;
      }
   }
   elsif($has_lwp) {
      my $data = LWP::Simple::get("http://search.cpan.org$url");
      unless($data) {
         print "Failed downloading http://search.cpan.org$url\n";
         return 0;
      }
      open(my $fh, '>', basename($url)) or die($!);
      binmode $fh;
      print $fh $data;
      close($fh);
   }
   else {
      die("No tool found to download something. (curl, wget, LWP::Simple)");
   }
   chdir($cwd);

   return 1;
}

sub _extract_file {
   my($file) = @_;

   my $cwd = getcwd;
   chdir(_work_dir());

   my $cmd;
   if($file =~ m/\.tar\.gz$/) {
      $cmd = 'tar -xvzf %s';
   } elsif($file =~ m/\.tar\.bz2/) {
      $cmd = 'tar -xjvf %s';
   }

   _call(sprintf($cmd, $file));
   chdir($cwd);
}

sub _rename_dir {
   my($old, $new) = @_;
   
   my $cwd = getcwd;
   chdir(_work_dir());

   rename($old, $new);

   chdir($cwd);
}

sub _configure {
   my($dir) = @_;

   my $cwd = getcwd;
   chdir(_work_dir() . '/' . $dir);

   my $cmd;
   if(-f "Build.PL") {
      $cmd = 'yes "" | perl Build.PL';
   } elsif(-f "Makefile.PL") {
      $cmd = "yes '' | perl Makefile.PL PREFIX=$cwd/$install_dir INSTALLSITEARCH=$cwd/$install_dir INSTALLPRIVLIB=$cwd/$install_dir INSTALLSITELIB=$cwd/$install_dir INSTALLARCHLIB=$cwd/$install_dir INSTALLVENDORARCH=$cwd/$install_dir";
   } else {
      die("not supported");
   }

   _call($cmd);
   die("Error $cmd") if($? != 0);
   chdir($cwd);
}

sub _make {
   my($dir) = @_;
   
   my $cwd = getcwd;
   chdir(_work_dir() . '/' . $dir);

   my $cmd;
   if(-f "Build") {
      $cmd = './Build';
   } elsif(-f "Makefile") {
      $cmd = "make";
   } else {
      die("not supported");
   }

   _call($cmd);
   die("Error $cmd") if($? != 0);
   chdir($cwd);
}

sub _test {
   my($dir) = @_;
   
   my $cwd = getcwd;
   chdir(_work_dir() . '/' . $dir);

   my $cmd;
   if(-f "Build") {
      $cmd = "./Build test";
   } elsif(-f "Makefile") {
      $cmd = "make test";
   } else {
      die("not supported");
   }

   _call($cmd);
   die("Error $cmd") if($? != 0);
   chdir($cwd);
}

sub _install {
   my($dir) = @_;
   
   my $cwd = getcwd;
   chdir(_work_dir() . '/' . $dir);

   my $cmd;
   if(-f "Build") {
      $cmd = "./Build install --install_path lib=$cwd/$install_dir --install_path arch=$cwd/$install_dir --install_path script=$cwd/$install_dir/bin --install_path bin=$cwd/$install_dir/bin --install_path bindoc=$cwd/$install_dir/man --install_path libdoc=$cwd/$install_dir/man --install_path libhtml=$cwd/$install_dir/html --install_path binhtml=$cwd/$install_dir/html";
   } elsif(-f "Makefile") {
      $cmd = "make install";
   } else {
      die("not supported");
   }

   _call($cmd);
   die("Error $cmd") if($? != 0);
   chdir($cwd);
}

sub _gen_rnd {
   my @chars = qw(a b c d e f g h i j k l m n o p u q s t u v w x y z 0 1 2 3 4 5 6 7 8 9);
   my $ret = '';

   for (0..4) {
      $ret .= $chars[int(rand(scalar(@chars)))];
   }

   $ret;
}

sub _work_dir {
   return $ENV{'HOME'} . '/.rexbundle';
}

sub _get_deps {
   my ($dir) = @_;

   
   my $cwd = getcwd;
   chdir(_work_dir() . '/' . $dir);
   my @ret;

   my $found=0;

   my $meta_file = "META.yml";
   if(-f "MYMETA.yml") { $meta_file = "MYMETA.yml"; }

   if(-f $meta_file) {
      my $yaml = eval { local(@ARGV, $/) = ($meta_file); $_=<>; $_; };
      eval {
         my $struct = Load($yaml);
         push(@ret, $struct->{'configure_requires'});
         push(@ret, $struct->{'build_requires'});
         push(@ret, $struct->{'requires'});
         $found=1;
      };

      if($@) {
         print STDERR "Error parseing META.yml :(\n";
         # fallback and try Makefile.PL
      }
   } else {
      # no meta.yml found :(
      print STDERR "No META.yml found :(\n";
      @ret = ();
   }

   if(!$found) {
      if(-f "Makefile.PL") {
         no strict;
         no warnings 'all';
         my $makefile = eval { local(@ARGV, $/) = ("Makefile.PL"); <>; };
         my ($hash_string) = ($makefile =~ m/WriteMakefile\((.*?)\);/ms);
         my $make_hash = eval "{$hash_string}";
         if(exists $make_hash->{"PREREQ_PM"}) {
            push @ret, $make_hash->{"PREREQ_PM"};
         }
         use strict;
         use warnings;
      }
   }

   chdir($cwd);

   my @needed = grep { ! /^perl$/ } grep { ! eval { my $m = $_; $m =~ s{::}{/}g; require "$m.pm"; 1;} } @ret;
   print "Found following dependencies: \n";
   print Dumper(\@needed);

   @needed;
}

sub _clone_repo {
   my($repo, $path) = @_;

   my $cmd = "%s %s %s %s";
   my @p = ();

   if($repo =~ m/^git/) {
      @p = qw(git clone);
      push @p, $repo, $path;
   } elsif($repo =~ m/^svn/) {
      @p = qw(svn export);
      push @p, $repo, $path;
   } else {
      die("Repositoryformat not supported: $repo");
   }

   my $cwd = getcwd;
   chdir(_work_dir());

   _call(sprintf($cmd, @p));

   chdir($cwd);
}

sub _call {
   my ($cmd) = @_;

   $ENV{'PERL5LIB'} .= ":$rex_file_dir/$install_dir";
   $ENV{'PERLLIB'} .= ":$rex_file_dir/$install_dir";
   system($cmd);
}

if( ! -d _work_dir() ) {
   mkdir (_work_dir(), 0755);
}

srand;

1;
