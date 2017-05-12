package Resque::Plugin::Retry;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Resque::Plugin;

add_to job    => 'Retry::Job';


1;
__END__

=encoding utf-8

=for html <a href="https://travis-ci.org/meru-akimbo/resque-retry-perl"><img src="https://travis-ci.org/meru-akimbo/resque-retry-perl.svg?branch=master"></a>

=head1 NAME

Resque::Plugin::Retry - Retry the fail job

=head1 SYNOPSIS

    use Resque;

    my $resque = Resque->new(redis => $redis_server, plugins => ['Retry']);
    $resque->push('test-job' => +{
            class => 'Hoge',
            args  => [+{ cat => 'nyaaaa' }, +{ dog => 'bow' }],
            max_retry => 3,
        }
    );

=head1 DESCRIPTION

Retry when the job fails

=head1 LICENSE

Copyright (C) meru_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

meru_akimbo E<lt>merukatoruayu0@gmail.comE<gt>

=cut

