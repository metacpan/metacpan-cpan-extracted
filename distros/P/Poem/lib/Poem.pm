#
# $Id: Poem.pm,v 0.1 2006/03/25 10:43:27 dankogai Exp dankogai $
#
package Poem;
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;

use Filter::Util::Call;
my %opt = ();
sub import{
    my $class = shift;
    %opt = map { $_ => 1 } @_;
    filter_add(\&read_poem);
}
sub unimport{
    my $class = shift;
    filter_del();
    %opt = ();
}
sub read_poem{
    my $pkg = __PACKAGE__; 
    my ($status, $no_seen, @poem);
    while ($status = filter_read()) {
	if (/^\s*no\s+$pkg\s*;\s*?$/) {
	    $no_seen=1;
	    last;
	}
	push @poem, $_;
	$_ = q();
    }
    if ($opt{-review}){
	# eval does not work in filter.  So we ask via pipe
	print "# Your Poem:\n";
	print @poem;
	my $perlopt = 
	    $opt{-deparse} ? "-MO=Deparse" :
	    $opt{-act} ? '-T' : '-Twc';
	print "# Review by $^X $perlopt\n";
	open my $perl, "| $^X $perlopt 2>&1" or die "$!";
	$opt{-strict} and print $perl "use strict;\n";
	$opt{-utf8}   and print $perl "use utf8;\n";
	print $perl @poem;
	close $perl;
    }else{
	print @poem unless $opt{-quiet};
    }
    if ($no_seen){
	$_ .= "no $pkg;\n";
	return 1;
    }else{
	return 0;
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Poem - Don't let Perl stand in poets' way!

=head1 SYNOPSIS

  use Poem;
  Just Another Perl Poet
  no Poem; # get back to work

=head1 DESCRIPTION

This module practically make perl accept any poem in any language.
Yes, I mean any language.  It even accepts poems in Unicode!

=head2 Options

Without import options, it prints your poem.

  use Poem;
  There are more than one way to Do it. -- Larry Wall
  no Poem;

=over 2

=item -review

But you can let perl review your poem via  C<-review>.

  use Poem qw/-review/;
  There are more than one way to Do it. -- Larry Wall
  no Poem;

=item -strict

With this option stricture will apply.

  # this works
  use Poem qw/-review/;
  $Perl = "Practical Extractaction and Report Language";
  no Poem;

  # but not under stricture
  use Poem qw/-review -strict/;
  $Perl = "Pathologically Eclectic Rubbish Lister";
  no Poem;

=item -deparse

If you don't grok your own poem, let perl deparse it.

  # Let perl deparse it
  use Poem qw/-review -deparse/;
  Just Another Perl Poet
  no Poem;

=item -act

If you are an activist rather an a poet, this optin is for you.

  # Who said talk is cheap?
  use Poem qw/-review -act/;
  Just Another Perl Poet
  no Poem;

=item -utf8

Even if your poem is written in non-ascii, Poem works.  But if you
want perl to review it, you probably need this option as well.
See t/unicode.pl to find out what I mean.

=item -quiet

This is a no-op.  Consider that a poet's way of saying C<=pod> - C<=cut>

  use Poem -quiet;
  Just Another Perl Poet
  no Poem;

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Filter::Util::Call>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
