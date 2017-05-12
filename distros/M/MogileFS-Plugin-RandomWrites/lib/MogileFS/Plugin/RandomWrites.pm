package MogileFS::Plugin::RandomWrites;

use strict;
use warnings;

our $VERSION = "0.05";

use MogileFS::Server;

use List::Util qw/ shuffle /;

sub load {
    MogileFS::register_global_hook("cmd_create_open_order_devices", \&cmd_create_open_order_devices) or die $!;
    MogileFS::register_worker_command("list_available_devices", \&list_available_devices) or die $!;
    return;
}

sub cmd_create_open_order_devices {
    my ($all_devices, $return_list) = @_;

    @{ $return_list } = shuffle(grep { $_->should_get_new_files; } @{ $all_devices });
    return 1;
}

sub list_available_devices {
    my MogileFS::Worker::Query $worker = shift;

    my $i=0;
    my $res;
    foreach my $d (grep { $_->should_get_new_files; } Mgd::device_factory()->get_all()) {
        $res->{"device_$i"} = $d->id;
        $res->{"mb_free_$i"} = $d->mb_free;
        $i++;
    }

    return $worker->ok_line($res);
}

1;
__END__

=head1 NAME

MogileFS::Plugin::RandomWrites - Mogile plugin to distribute files evenly

=head1 SYNOPSIS

In mogilefsd.conf

    plugins = RandomWrites

    mogadm --trackers=$MOGILE_TRACKER class modify <domain> <class> --replpolicy=MultipleHostsRandom\(2\)

=head1 DESCRIPTION

This plugin cause MogileFS to distribute writes to a random device, rather than
concentrating on devices with the most space free.

=head1 SEE ALSO

L<MogileFS::Server>

=head1 AUTHOR

Dave Lambley, E<lt>davel@state51.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dave Lambley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
