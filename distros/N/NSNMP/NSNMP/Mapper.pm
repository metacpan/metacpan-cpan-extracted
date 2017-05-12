package NSNMP::Mapper;
# Copyright (c) 2003-2004 AirWave Wireless, Inc.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

#    1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
#    2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#    3. The name of the author may not be used to endorse or
#    promote products derived from this software without specific
#    prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# On optimizing:
# I tried encoding the OIDs in BER before comparing them, so as to
# avoid the (?:\.|\z) thingy and the various leading-dot crap, and
# also to look at less bytes.  Got it working pretty soon, but the
# time test (matching 500 OIDs against a mapper with 100 similar OIDs
# in it, getting a hit every time) slowed from 35 ms to 47 ms, even
# though the OID lookups were cached.  Might be worthwhile if the OIDs
# were already in that format, e.g. for sorting or because they just
# came across the wire (or are about to go back), but I'll cross that
# bridge when I come to it.

sub new {
  my ($class, %args) = @_;
  my $self = bless { table => {} }, $class;
  while (my ($key, $value) = each %args) {
    $key =~ s/\A\.//;
    $self->{table}{$key} = $value;
  }
  my $bigre = '\A(' . (join '|', map { "\Q$_\E" } keys %{$self->{table}}) . ')(?:\.|\z)(.*)';
  $self->{bigre} = qr/$bigre/;
  return $self;
}

# XXX note this interface is really bug-prone in scalar context

sub map {
  my ($self, $oid) = @_;
  $oid =~ s/\A\.//;
  if ($oid =~ $self->{bigre}) {
    my ($key, $instance) = ($1, $2);
    return ($self->{table}{$key}, ($instance eq '' ? undef : $instance));
  }
  return (undef, undef);
}

1;
