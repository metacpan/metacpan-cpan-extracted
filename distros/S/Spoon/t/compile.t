use lib 't', 'lib';
use strict;
use warnings;
use Test::More 'no_plan'; 
use IO::All;
use File::Spec;

for (grep {! /CVS/ && ! /(?:~|\.swp)$/ && ! /.svn/} io('lib')->All_Files) {
    my $name = $_->name;
    my ($vol, $path, $file) = File::Spec->splitpath($name);
    my @dirs = File::Spec->splitdir($path);
    shift @dirs if $dirs[0] eq 'lib';
    pop @dirs while @dirs and (not defined $dirs[-1] or $dirs[-1] =~ /^\s*$/);
    $file =~ s/\.pm$//;
    push @dirs, $file;
    $name = join('::', @dirs);
    eval "require $name; 1";
    is($@, '', "Compile $name");
}

