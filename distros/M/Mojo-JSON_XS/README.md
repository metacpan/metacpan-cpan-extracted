# Mojo::JSON_XS

If your Mojolicious code makes very heavy use of JSON, you might want to try out
a binary drop-in replacement for the pure-perl module Mojo::JSON when you come
to the optimisation stages of your project.  Thanks to Marc Lehmann and Reini
Urban we can use Cpanel::JSON::XS which is a fork of JSON::XS (implemented in C)
with public bug tracking.  Sebastian Riedel has provided ([1][], [2][]) the
patch-in code for swapping-in the XS code, and I have simply bundled that up
into this module.

  [1]: https://groups.google.com/d/msg/mojolicious/a4jDdz-gTH0/Exs0-E1NgQEJ
  [2]: http://irclog.perlgeek.de/mojo/2014-11-25#i_9718125

Nic Sandfield
