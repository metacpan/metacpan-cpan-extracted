# -*- perl -*-

use Test::More tests => 20;
use warnings;
use strict;
use Log::Log4perl;

BEGIN {
  use_ok("Test::AutoBuild::Archive");
}

Log::Log4perl::init("t/log4perl.conf");


SIMPLE: {
    my $now = time;
    my $arc = MyArchive->new(key => 1,
			     created => $now);
    isa_ok($arc, "MyArchive");

    is($arc->key, 1, "key is 1");
    is($arc->created, $now, "creation time is $now");

    $arc->save_data("myobject","mybucket",{ foo => "bar" });
    ok(defined $arc->{metadata}->{"myobject.mybucket.DATA"}, "bucket is defined");
    is_deeply($arc->{metadata}->{"myobject.mybucket.DATA"}, { foo => "bar" }, "data is foo => bar");
    is_deeply($arc->get_data("myobject", "mybucket"), { foo => "bar"}, "data is foo => bar");

    $arc->save_data("myobject","nextbucket",{ foo => "bar" });
    ok(defined $arc->{metadata}->{"myobject.nextbucket.DATA"}, "bucket is defined");
    is_deeply($arc->{metadata}->{"myobject.nextbucket.DATA"}, { foo => "bar" }, "data is foo => bar");
    is_deeply($arc->get_data("myobject", "mybucket"), { foo => "bar"}, "data is foo => bar");

    $arc->save_files("myobject","mybucket", { "/tmp" => ["/tmp"] });
    ok(defined $arc->{files}->{"myobject.mybucket"}, "files are defined");
    is_deeply($arc->{files}->{"myobject.mybucket"}, [{ "tmp" => ["/tmp"]}, { link => 0, move => 0, base => "/"}], "files are copied");
    is_deeply($arc->get_files("myobject", "mybucket"), { "tmp" => ["/tmp"]}, "files are /tmp => /tmp");
    ok(defined $arc->{metadata}->{"myobject.mybucket.FILES"}, "bucket is defined");
    is_deeply($arc->{metadata}->{"myobject.mybucket.FILES"}, { "tmp" => ["/tmp"] }, "data is /tmp => /tmp");

    $arc->save_files("myobject","nextbucket", { "/var" => ["/var"] }, { link => 1 });
    ok(defined $arc->{files}->{"myobject.nextbucket"}, "files are defined");
    is_deeply($arc->{files}->{"myobject.nextbucket"}, [{ "var" => ["/var"]}, { link => 1, move => 0, base => "/"}], "files are copied");
    is_deeply($arc->get_files("myobject", "nextbucket"), { "var" => ["/var"]}, "files are /var => /var");
    ok(defined $arc->{metadata}->{"myobject.nextbucket.FILES"}, "bucket is defined");
    is_deeply($arc->{metadata}->{"myobject.nextbucket.FILES"}, { "var" => ["/var"] }, "data is /var => /var");
}

package MyArchive;

use base qw(Test::AutoBuild::Archive);


sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->{metadata} = {};
    $self->{files} = {};
}

sub _has_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    return exists $self->{metadata}->{"$object.$bucket.$type"};
}

sub _save_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;
    my $data = shift;

    $self->{metadata}->{"$object.$bucket.$type"} = $data;
}

sub _persist_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $files = shift;
    my $options = shift;

    $self->{files}->{"$object.$bucket"} = [$files,$options];
}

sub _get_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    return $self->{metadata}->{"$object.$bucket.$type"};
}
