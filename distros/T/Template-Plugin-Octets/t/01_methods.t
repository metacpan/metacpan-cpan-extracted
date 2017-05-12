use strict;
use warnings;
use Template::Test;
use Template::Plugin::Octets;

test_expect(\*DATA);

__DATA__
# first, please
-- test --
-- name: Empty value --
[% USE Octets -%]
Xmit [% Octets.kio('') -%] Kio
-- expect --
Xmit ~0 Kio

# next, please
-- test --
-- name: Kibioctets (normal) --
[% USE Octets -%]
Xmit [% Octets.kio(100500) -%] Kio
-- expect --
Xmit 98.1 Kio

# next, please
-- test --
-- name: Kibioctets (around zero) --
[% USE Octets -%]
IN [% Octets.kio(10) -%] Kio
-- expect --
IN ~0 Kio

# next, please
-- test --
-- name: Mebioctets (normal) --
[% USE Octets -%]
Recv [% Octets.mio(900500999) -%] Mio
-- expect --
Recv 858.8 Mio

# next, please
-- test --
-- name: Mebioctets (around zero) --
[% USE Octets -%]
Recv [% Octets.mio(9005) -%] Mio
-- expect --
Recv ~0 Mio

# next, please
-- test --
-- name: Gibioctets (normal) --
[% USE Octets -%]
Transreffed [% Octets.gio(200500999000) -%] Gio
-- expect --
Transreffed 186.7 Gio

# next, please
-- test --
-- name: Gibioctets (around zero) --
[% USE Octets -%]
Transreffed [% Octets.gio(100) -%] Gio
-- expect --
Transreffed ~0 Gio
