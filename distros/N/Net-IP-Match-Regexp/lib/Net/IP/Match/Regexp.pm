package Net::IP::Match::Regexp;

use 5.006;
use strict;
use warnings;
use English qw(-no_match_vars);

use base 'Exporter';
our @EXPORT_OK = qw( create_iprange_regexp create_iprange_regexp_depthfirst match_ip );
our $VERSION   = '1.01';

=head1 NAME

Net::IP::Match::Regexp - Efficiently match IP addresses against ranges

=head1 LICENSE

Copyright 2005-2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

Copyright 2007-2008 Chris Dolan, <cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Net::IP::Match::Regexp qw( create_iprange_regexp match_ip );
    
    my $regexp = create_iprange_regexp(
       qw( 10.0.0.0/8 87.134.66.128 87.134.87.0/24 145.97.0.0/16 )
    );
    if (match_ip('209.249.163.62', $regexp)) {
       ...
    }

=head1 DESCRIPTION

This module allows you to check an IP address against one or more IP
ranges.  It employs Perl's highly optimized regular expression engine
to do the hard work, so it is very fast.  It is optimized for speed by
doing the match against a regexp which implicitly checks the broadest
IP ranges first.  An advantage is that the regexp can be computed and
stored in advance (in source code, in a database table, etc) and
reused, saving much time if the IP ranges don't change too often.  The
match can optionally report a value (e.g. a network name) instead of
just a boolean, which makes module useful for mapping IP ranges to
names or codes or anything else.

=head1 LIMITATIONS

This module does not yet support IPv6 addresses, although that feature
should not be hard to implement as long as the regexps start with a 4
vs. 6 flag.  Patches welcome.  :-)

This module only accepts IP ranges in C<a.b.c.d/x> (aka CIDR)
notation.  To work around that limitation, I recommend
Net::CIDR::Lite to conveniently convert collections of IP address
ranges into CIDR format.

This module makes no effort to validate the IP addresses or ranges
passed as arguments.  If you pass address ranges like
C<1000.0.0.0/300>, you will probably get weird regexps out.

=head1 FUNCTIONS

=over

=cut

=item create_iprange_regexp($iprange | $hashref | $arrayref, ...)

This function digests IP ranges into a regular expression that can
subsequently be used to efficiently test single IP addresses.  It
returns a regular expression string that can be passed to match_ip().

The simple way to use this is to pass a list of IP ranges as
C<aaa.bbb.ccc.ddd/n>.  When used this way, the return value of the
match_ip() function will be simply C<1> or C<undef>.

The more complex way is to pass a hash reference of IP range => return
value pairs.  When used this way, the return value of the match_ip()
function will be the specified return value or C<undef> for no match.

For example:

    my $re1 = create_iprange_regexp('209.249.163.0/25', '127.0.0.1/32');
    print match_ip('209.249.163.62', $re1); # prints '1'
    
    my $re2 = create_iprange_regexp({'209.249.163.0/25' => 'clotho.com',
                                     '127.0.0.1/32' => 'localhost'});
    print match_ip('209.249.163.62', $re2); # prints 'clotho.com'

Be aware that the value string will be wrapped in single quotes in the
regexp.  Therefore, you must double-escape any single quotes in that
value.  For example:

    create_iprange_regexp({'208.201.239.36/31' => 'O\\'Reilly publishing'});

Note that the scalar and hash styles can be mixed (a rarely used
feature).  These two examples are equivalent:

    create_iprange_regexp('127.0.0.1/32',
                          {'209.249.163.0/25' => 'clotho.com'},
                          '10.0.0.0/8',
                          {'192.168.0.0/16' => 'LAN'});
    
    create_iprange_regexp({'127.0.0.1/32' => 1,
                           '209.249.163.0/25' => 'clotho.com',
                           '10.0.0.0/8' => 1,
                           '192.168.0.0/16' => 'LAN'});

If any of the IP ranges are overlapping, the broadest one is used.  If
they are equivalent, then the first one passed is used.  If you have
some data that might be ambiguous, you pass an arrayref instead of a
hashref, but it's better to clean up your data instead!  For example:

    my $re = create_iprange_regexp(['1.1.1.0/31' => 'zero', '1.1.1.1/31' => 'one']);
    print match_ip('1.1.1.1', $re));   # prints 'zero', since both match

WARNING: This function does no checking for validity of IP ranges.  It
happily accepts C<1000.0.0.0/-38> and makes a garbage regexp.
Hopefully a future version will validate the ranges, perhaps via
Net::CIDR or Net::IP.

=cut

sub create_iprange_regexp {   ##no critic (ArgUnpacking)
   return _build_regexp(0, \@_);
}

=item create_iprange_regexp_depthfirst($iprange | $hashref | $arrayref, ...)

Returns a regexp in matches the most specific IP range instead of the
broadest range.  Example:

    my $re = create_iprange_regexp_depthfirst({'192.168.0.0/16' => 'LAN',
                                               '192.168.0.1' => 'router'});
    match_ip('192.168.0.1', $re);

returns 'router' instead of 'LAN'.

=cut

sub create_iprange_regexp_depthfirst {   ##no critic (ArgUnpacking)
   return _build_regexp(1, \@_);
}
sub _build_regexp {
   my ($depthfirst, $ipranges) = @_;

   # If an argument is a hash or array ref, flatten it
   # If an argument is a scalar, make it a key and give it a value of 1
   my @map
       = map {   ! ref $_            ? ( $_ => 1 )
               :   ref $_ eq 'ARRAY' ? @{$_}
               :                       %{$_}         } @{$ipranges};

   # The tree is a temporary construct.  It has three possible
   # properties: 0, 1, and code.  The code is the return value for a
   # match.
   my %tree;

IPRANGE:
   for ( my $i = 0; $i < @map; $i += 2 ) {
      my $range = $map[ $i ];
      my $match = $map[ $i + 1 ];

      my ( $ip, $mask ) = split m/\//xms, $range;
      if (! defined $mask) {
         $mask = 32;          ## no critic(MagicNumbers)
      }

      my $tree = \%tree;
      my @bits = split m//xms, unpack 'B32', pack 'C4', split m/[.]/xms, $ip;

      for my $bit ( @bits[ 0 .. $mask - 1 ] ) {

         # If this case is hit, it means that our IP range is a subset
         # of some other range, and thus ignorable
         next IPRANGE if !$depthfirst && $tree->{code};

         $tree->{$bit} ||= {};    # Turn a leaf into a branch, if needed
         $tree = $tree->{$bit};   # Follow one branch
      }

      # Our $tree is now a leaf node of %tree.  Set its value
      # If the code is already set, it's a non-fatal error (redundant data)
      $tree->{code} ||= $match;

      # Ignore case where $tree->{0} or $tree->{1} are set (i.e. if
      # the current range encompasses any earlier-processed ranges).
      # Those branches will be ignored in _tree2re()
   }

   # Recurse into the tree making it into a regexp
   my $re = join q{}, '^4', $depthfirst ? _tree2re_depthfirst( \%tree ) : _tree2re( \%tree );

   ## Performance optimization:

   # If we are going to use the pattern repeatedly, it's more
   # effiecient if it's already a regexp instead of a string.
   # Otherwise, it needs to be compiled in each invocation of
   # match_ip().  If the regexp is merely stored and not used then
   # this is wasted effort.

   use re 'eval';    # needed because we're interpolating into a regexp
   $re = qr/$re/xms;

   return $re;
}

=item match_ip($ipaddr, $regexp)

Given a single IP address as a string of the form C<aaa.bbb.ccc.ddd>
and a regular expression string (typically the output of
create_iprange_regexp()), this function returns a specified value
(typically C<1>) if the IP is in one of the ranges, or C<undef> if no
ranges match.

See create_ipranges_regexp() for more details about the return value
of this function.

WARNING: This function does no checking for validity of the IP address.

=cut

sub match_ip {
   my ( $ip, $re ) = @_;

   return if !$ip;
   return if !$re;

   local $LAST_REGEXP_CODE_RESULT = undef;
   use re 'eval';
   ( '4' . unpack 'B32', pack 'C4', split m/[.]/xms, $ip ) =~ m/$re/xms;
   return $LAST_REGEXP_CODE_RESULT;
}

# Helper function.  This recurses to build the regular expression
# string from a tree of IP ranges constructed by
# create_iprange_regexp().

sub _tree2re {
   my ( $tree ) = @_;

   return
       defined $tree->{code}       ? ( "(?{'$tree->{code}'})"            )  # Match
       : $tree->{0} && $tree->{1}  ? ( '(?>0', _tree2re($tree->{0}),
                                         '|1', _tree2re($tree->{1}), ')' )  # Choice
       : $tree->{0}                ? (    '0', _tree2re($tree->{0})      )  # Literal, no choice
       : $tree->{1}                ? (    '1', _tree2re($tree->{1})      )  # Literal, no choice
       : die 'Internal error: failed to create a regexp from the supplied IP ranges'
       ;
}

sub _tree2re_depthfirst {
   my ( $tree ) = @_;

   if (defined $tree->{code}) {
      return '(?>',
         $tree->{0} && $tree->{1}  ? ( '(?>0', _tree2re_depthfirst($tree->{0}),
                                         '|1', _tree2re_depthfirst($tree->{1}), ')|' )
       : $tree->{0}                ? (    '0', _tree2re_depthfirst($tree->{0}), q{|} )
       : $tree->{1}                ? (    '1', _tree2re_depthfirst($tree->{1}), q{|} )
       : (),
       "(?{'$tree->{code}'}))";
   } else {
      return
         $tree->{0} && $tree->{1}  ? ( '(?>0', _tree2re_depthfirst($tree->{0}),
                                         '|1', _tree2re_depthfirst($tree->{1}), ')' )  # Choice
       : $tree->{0}                ? (    '0', _tree2re_depthfirst($tree->{0})      )  # Literal, no choice
       : $tree->{1}                ? (    '1', _tree2re_depthfirst($tree->{1})      )  # Literal, no choice
       : die 'Internal error: failed to create a regexp from the supplied IP ranges'
       ;
   }
}

1;

__END__

=back

=head1 SEE ALSO

There are several other CPAN modules that perform a similar function.
This one is comparable to or faster than the other ones that I've
found and tried.  Here is a synopsis of those others:

=head2 L<Net::IP::Match>

Optimized for speed by taking a "source filter" approach.  That is, it
modifies your source code at run time, kind of like a C preprocessor.
A huge limitation is that the IP ranges must be hard-coded into your
program.

=head2 L<Net::IP::Match::XS>

(Also released as Net::IP::CMatch)

Optimized for speed by doing the match in C instead of in Perl.  This
module loses efficiency, however, because the IP ranges must be
re-parsed every invocation.

=head2 L<Net::IP::Resolver>

Uses Net::IP::Match::XS to implement a range-to-name map.

=head1 PERFORMANCE

I ran a series of test on a Mac G5 with Perl 5.8.6 to compare this
module to Net::IP::Match::XS.  The tests are intended to be a
realistic net filter case: 100,000 random IP addresses tested against
a number of semi-random IP ranges.  Times are in seconds.

    Networks: 1, IPs: 100000
    Test name              | Setup time | Run time | Total time 
    -----------------------+------------+----------+------------
    Net::IP::Match::XS     |    0.000   |  0.415   |    0.415   
    Net::IP::Match::Regexp |    0.001   |  1.141   |    1.141   
    
    Networks: 10, IPs: 100000
    Test name              | Setup time | Run time | Total time 
    -----------------------+------------+----------+------------
    Net::IP::Match::XS     |    0.000   |  0.613   |    0.613   
    Net::IP::Match::Regexp |    0.003   |  1.312   |    1.316   
    
    Networks: 100, IPs: 100000
    Test name              | Setup time | Run time | Total time 
    -----------------------+------------+----------+------------
    Net::IP::Match::XS     |    0.000   |  2.621   |    2.622   
    Net::IP::Match::Regexp |    0.024   |  1.381   |    1.405   
    
    Networks: 1000, IPs: 100000
    Test name              | Setup time | Run time | Total time 
    -----------------------+------------+----------+------------
    Net::IP::Match::XS     |    0.003   | 20.910   |   20.912   
    Net::IP::Match::Regexp |    0.203   |  1.514   |    1.717   

This test indicates that ::Regexp is faster than ::XS when you have
more than about 50 IP ranges to test.  The relative run time does not
vary significantly with the number of singe IP to match, but with a
small number of IP addresses to match, the setup time begins to
dominate, so ::Regexp loses in that scenario.

To reproduce the above benchmarks, run the following command in the
distribution directory:

   perl benchmark/speedtest.pl -s -n 1,10,100,1000 -i 100000

=head1 IMPLEMENTATION

The speed of this module comes from the short-circuit nature of
regular expressions.  The setup function turns all of the IP ranges
into binary strings, and mixes them into a regexp with C<|> choices
between ones and zeros.  This regexp can then be passed to the match
function.  When an unambiguous match is found, the regexp sets a
variable (via the regexp $LAST_REGEXP_CODE_RESULT, aka $^R, feature)
and terminates.  That variable becomes the return value for the match,
typically a true value.

Here's an example of the regexp for a single range, that of the
Clotho.com subnet:

    print create_iprange_regexp('209.249.163.0/25')'
    # ^41101000111111001101000110(?{'1'})

If we add another range, say a NAT LAN, we get:

    print create_iprange_regexp('209.249.163.0/25', '192.168.0.0/16')'
    # ^4110(?>0000010101000(?{'1'})|1000111111001101000110(?{'1'}))

Note that for a 192.168.x.x address, the regexp checks at most the
first 16 bits (1100000010101000) whereas for a 209.249.163.x address,
it goes out to 25 bits (1101000111111001101000110).  The cool part is
that for an IP address that starts in the lower half (say 127.0.0.1)
only needs to check the first bit (0) to see that the regexp won't
match.

If mapped return values are specified for the ranges, they get embedded
into the regexp like so:

    print create_iprange_regexp({'209.249.163.0/25' => 'clotho.com',
                                 '192.168.0.0/16' => 'localhost'})'
    # ^4110(?>0000010101000(?{'localhost'})|1000111111001101000110(?{'clotho.com'}))

This could be implemented in C to be even faster.  In C, it would
probably be better to use a binary tree instead of a regexp.  However,
a goal of this module is to create a serializable representation of
the range data, and the regexp is perfect for that.  So, I'll
probably never do a C version.

=head1 COMPATIBILITY

Because this module relies on the C<(?{ code })> feature of regexps,
it won't work on old Perl versions.  I've successfully tested this
module on Perl 5.6.0, 5.8.1 and 5.8.6.  In theory, the code regexp
feature should work in 5.005, but I've used C<our> and the like, so it
won't work there.  I don't have a 5.005 to test anyway...

Update from Oct 2008: I no longer keep a 5.6.0 around, so I rely on
cpantesters.org to tell me when this breaks for older Perls.

=head1 CODING

This module has 100% code coverage in its regression tests, as
reported by L<Devel::Cover> via C<perl Build testcover>.

This module passes Perl Best Practices guidelines, as enforced by
L<Perl::Critic> v1.093.

=head1 AUTHOR

Chris Dolan

I originally developed this module at Clotho Advanced Media Inc.  Now
I maintain it in my spare time.

=head1 ACKNOWLEDGMENTS

TeachingBooks.net inspired and subsidized development of the original
version of this module.

Chris Snyder contributed a valuable and well-written bug report about
handling missing mask values.

Michael Aronsen of cohaesio.com suggested the depth-first matching
feature.

=cut
