#! /usr/bin/env perl
use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Cwd 'abs_path';
use Fcntl 'S_IFREG';
use Sys::Export::Linux;

package Sys::Export::MockDst {
   sub new($class)        { bless { files => {} }, $class }
   sub files($self)       { $self->{files} }
   sub add($self, $attrs) { $self->{files}{$attrs->{name}}= $attrs; }
   sub finish($self)      {}
}

my $tmp= File::Temp->newdir;
my $dst= Sys::Export::MockDst->new();
my $exporter= Sys::Export::Linux->new(src => "/", dst => $dst);

skip_all "strace not supported in this environment"
   unless $exporter->_can_trace_deps;

# The exporter is most likely to detect /usr/bin/perl as the interpreter for
# this script, which might not be the interpreter we're currently using to
# run the tests.  So the script needs to depend only on things that would
# exist for *every* perl interpreter.

$exporter->add(abs_path(__FILE__) =~ s{[^/]+\z}{data/simple-perl-script.pl}r);

note "dep: $_" for keys $dst->files->%*;

ok( scalar(grep m{strict.pm\z}, keys $dst->files->%*), 'Saw dep strict.pm' );
ok( scalar(grep m{warnings.pm\z}, keys $dst->files->%*), 'Saw dep warnings.pm' );

done_testing;
