#!perl -T

# Copyright (c) 2005-2008 George Nistorica
# All rights reserved.
# This program is part of POE::Component::Client::SMTP
# POE::Componen::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 00-load.t,v 1.3 2008/05/09 14:19:39 UltraDM Exp $	

use Test::More tests => 1;

BEGIN {
    use_ok(q{POE::Component::Client::SMTP});
}

diag(
qq{Testing POE::Component::Client::SMTP $POE::Component::Client::SMTP::VERSION, Perl $], $^X}
);
