#!/usr/bin/perl -w
#
# Copyright (c) 2012 Jasper Lievisse Adriaanse <jasper@mtier.org>
# Copyright (c) 2012 M:tier Ltd.
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Automatic Puppet Style
# Helper script to apply Puppet Style Guide DOs and DONTs to your Puppet files
# (http://docs.puppetlabs.com/guides/style_guide.html).
# Currently only a small subset of directives are implemented, but enough to
# save you a lot of time while cleaning up Puppet Lint warnings.
package main;

use strict;
use Puppet::Tidy;

# No need to pass anything, @ARGV is global and we don't need any special
# parameters unless you're directly using the module.
Puppet::Tidy::puppettidy();

__END__
