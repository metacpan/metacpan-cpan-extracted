#!/usr/bin/env perl
use Net::Docker;
use Data::Dumper;

my $api = Net::Docker->new;

if ($ARGV[0] eq 'ps') {
    my %args;
    if ($ARGV[1] eq '-a') {
        $args{all}=1;
    }
    print "ID                  IMAGE               COMMAND                CREATED             STATUS              PORTS\n";
    for my $row (@{ $api->ps(%args) }) {
        my $id = substr $_->{Id}, 0, 12;
        for (qw/Id Image Command Created Status Ports/) {
            my $len = $_ eq 'Command' ? 23 : 20;
            my $printlen = $_ eq 'Id' ? 12 : 19;
            my $val = substr $row->{$_}, 0, $printlen;
            printf("%-${len}s", $val);
        }
        print "\n";
    }
}
elsif ($ARGV[0] eq 'run') {
    my ($cmd, $image, @client_cmd) = @ARGV;

    my $id = $api->create(Image => $image, Cmd => \@client_cmd, AttachStdin => \1, OpenStdin => \1);
    $api->start($id);

    my $cv = $api->streaming_logs($id,
        stream => 1, 
        logs   => 1,
        stdin  => 1, stderr => 1, stdout => 1,
        in_fh  => \*STDIN,
        out_fh => \*STDOUT
    );
    $cv->recv;
}
elsif ($ARGV[0] eq 'attach') {
    my ($cmd, $id) = @ARGV;
    my $cv = $api->streaming_logs($id,
        stream => 1, 
        logs   => 1,
        stdin  => 1, stderr => 1, stdout => 1,
        in_fh  => \*STDIN,
        out_fh => \*STDOUT
    );
    $cv->recv;
}

