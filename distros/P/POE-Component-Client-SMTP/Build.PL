# Copyright (c) 2005 - 2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: Build.PL,v 1.9 2009/02/16 15:24:50 UltraDM Exp $

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    q{module_name}       => q{POE::Component::Client::SMTP},
    q{license}           => q{perl},
    q{dist_author}       => q{George Nistorica <ultadm@cpan.org>},
    q{dist_version_from} => q{lib/POE/Component/Client/SMTP.pm},
    q{requires}          => {
        q{perl}                           => 0,
        q{Test::More}                     => 0,
        q{Carp}                           => 0,
        q{Socket}                         => 0,
        q{Data::Dumper}                   => 0,
        q{POE}                            => q{0.26},
        q{POE::Wheel::SocketFactory}      => 0,
        q{POE::Wheel::ReadWrite}          => 0,
        q{POE::Filter::Line}              => 0,
        q{POE::Filter::Stream}            => 0,
        q{Symbol}                         => 0,
        q{POE::Filter::Transparent::SMTP} => q{0.2},
    },
    q{add_to_cleanup}     => [q{POE-Component-Client-SMTP-*}],
    q{create_makefile_pl} => q{traditional},
);

$builder->create_build_script();
