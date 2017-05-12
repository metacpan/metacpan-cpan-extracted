#!/usr/bin/perl

use strict;
use Getopt::Long;
use Pod::Usage;

use Rapi::Fs;
use Plack::Runner;

use RapidApp::Util qw(:all);

$| = 1;

sub _cleanup_exit { 
  exit 
}
END { &_cleanup_exit };
$SIG{$_} = \&_cleanup_exit for qw(INT KILL TERM HUP QUIT ABRT);

my $help      = 0;
my $debug     = 0;
my $name      = 'Rapi::Fs::Web';
my $port      = 3500;
my $includes  = [];

# From 'prove': Allow cuddling the paths with -I, -M and -e
@ARGV = map { /^(-[IMe])(.+)/ ? ($1,$2) : $_ } @ARGV;

GetOptions(
  'help+'      => \$help,
  'debug+'     => \$debug,
  'port=i'     => \$port,
  'I=s@'       => $includes,
);


pod2usage(1) if ($help || scalar(@ARGV) == 0);

print STDERR "rapi-fs.pl (Rapi::Fs v$Rapi::Fs::VERSION) -- Loading app...\n";

if (@$includes) {
  require lib;
  lib->import(@$includes);
}

{

  my $cnf = {
    base_appname  => $name,
    mounts        => \@ARGV,
    debug         => $debug
  };
  
  my $App = Rapi::Fs->new( $cnf );

  my $psgi = $App->to_app;

  my $runner = Plack::Runner->new;
  $runner->parse_options('--port',$port);

  $runner->run($psgi);

}

1;

__END__

=head1 NAME

rapi-fs.pl - Instant file browser webapp

=head1 SYNOPSIS

 rapi-fs.pl [OPTIONS] PATHS

 Options:
   --help   Display this help screen and exit
   --debug  Enable debug mode
   --port   Local TCP port to use for the test server (defaults to 3500)
   
   -I  Specifies Perl library include paths, like "perl"'s -I option. You
       may add multiple paths by using this option multiple times.

 Examples:
   rapi-fs.pl /some/path
   rapi-fs.pl Some-Name:/some/path
   rapi-fs.pl /some/path /some/other/dir ~/foo

=head1 DESCRIPTION

C<rapi-fs.pl> is a simple wrapper around L<Rapi::Fs>, which is a L<Plack>-compatable application
written with L<RapidApp>. It accepts a list of directory paths and lauches a web interface to browse 
them.


=head1 SEE ALSO

L<RapidApp>, L<Rapi::Fs>, L<Plack::Component>, L<RapidApp::Builder>

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
