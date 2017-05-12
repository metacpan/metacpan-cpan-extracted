#!perl
use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir','tempfile';
use File::Find;
use Test::Deep;
use Net::Stomp::MooseHelpers::ReadTrace;

my $has_working_permissions;
{
    my ($fh,$fn) = tempfile;

    my $pre_permissions = (stat $fn)[2];
    my $wanted_permissions = ($pre_permissions & 07777) ^ 0246;
    chmod $wanted_permissions,$fn;
    my $post_permissions = (stat $fn)[2];

    if ($pre_permissions != $post_permissions
            and ($post_permissions & 07777) == $wanted_permissions) {
        $has_working_permissions = 1;
    }
};

my $dir = tempdir(CLEANUP => ( $ENV{TEST_VERBOSE} ? 0 : 1 ));

sub get_dumped_files {
    my @files;
    find({
        wanted => sub {
            # we skip checking $dir because it was not created by TracerRole
            if (-d $_ and $_ ne $dir) {
                is(
                    (stat($_))[2]&07777,
                    0770&(~umask),
                    "correct directory permissions for $_"
                ) if $has_working_permissions;
            }
            elsif (-f $_) {
                is(
                    (stat($_))[2]&07777,
                    0664&(~umask),
                    "correct file permissions for $_"
                ) if $has_working_permissions;
                push @files,$_;
            }
        },
        no_chdir => 1,
    },$dir);
    return @files;
}

{package TestThing;
 use Moose;
 with 'Net::Stomp::MooseHelpers::CanConnect';
 with 'Net::Stomp::MooseHelpers::ReconnectOnFailure';
 with 'Net::Stomp::MooseHelpers::TraceOnly';

 has '+trace_basedir' => ( default => $dir );
 has '+trace_permissions' => ( default => '0664' );
 has '+trace_directory_permissions' => ( default => '0770' );
 has '+trace_types' => ( default => sub { +[] } ); # all of them
}

package main;
use Test::More;

my $obj = TestThing->new();
ok($obj->trace,'tracing is on by default with TraceOnly');

my $reader = Net::Stomp::MooseHelpers::ReadTrace->new({
    trace_basedir => $dir,
});

subtest 'sending' => sub {
    $obj->connect();
    $obj->connection->send({
        type => 'foo',
        destination => '/topic/test',
        body => 'argh',
    });

    my @files = get_dumped_files;
    is(scalar(@files),1,'only one frame dumped');

    my @frames = $reader->sorted_frames();
    is(scalar(@frames),1,'only one frame read back');

    cmp_deeply(\@frames,
               [
                   all(isa('Net::Stomp::Frame'),
                       methods(
                           command => 'SEND',
                           headers => {
                               type => 'foo',
                               destination => '/topic/test',
                           },
                           body => 'argh',
                       )),
               ],
               'correct contents');
};

subtest 'sending, transactional' => sub {
    $reader->clear_destination();

    $obj->connection->send_transactional({
        type => 'foo2',
        destination => '/topic/test2',
        body => 'argh2',
    });

    my @files = get_dumped_files;
    is(scalar(@files),3,'three frames dumped');
    my @frames = $reader->sorted_frames();
    is(scalar(@frames),3,'three frames read back');

    cmp_deeply(\@frames,
               [
                   all(isa('Net::Stomp::Frame'),
                       methods(
                           command => 'BEGIN',
                       )),
                   all(isa('Net::Stomp::Frame'),
                       methods(
                           command => 'SEND',
                           headers => {
                               type => 'foo2',
                               destination => '/topic/test2',
                               receipt => ignore(),
                               transaction => ignore(),
                           },
                           body => 'argh2',
                       )),
                   all(isa('Net::Stomp::Frame'),
                       methods(
                           command => 'COMMIT',
                       )),
               ],
               'correct contents');
};

subtest 'sending, transactional, filtered' => sub {
    $reader->clear_destination();
    $obj->trace_types(['SEND']);

    $obj->connection->send_transactional({
        type => 'foo2',
        destination => '/topic/test2',
        body => 'argh2',
    });

    my @files = get_dumped_files;
    is(scalar(@files),1,'one frames dumped');
    my @frames = $reader->sorted_frames();
    is(scalar(@frames),1,'one frames read back');

    cmp_deeply(\@frames,
               [
                   all(isa('Net::Stomp::Frame'),
                       methods(
                           command => 'SEND',
                           headers => {
                               type => 'foo2',
                               destination => '/topic/test2',
                               receipt => ignore(),
                               transaction => ignore(),
                           },
                           body => 'argh2',
                       )),
               ],
               'correct contents');
};

done_testing();
