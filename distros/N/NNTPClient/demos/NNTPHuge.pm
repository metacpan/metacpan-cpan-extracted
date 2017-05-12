package News::NNTPHuge;

# I didn't write this.  Someone sent it to me and I've decided to
# include it for your amusement.
#
# -- Rodger Anderson, 1999-06-11

# This module provides replacements for ihave and squirt to handle the
# sending of very large files.

require 5.000;

use Carp;
use News::NNTPClient;

@ISA = qw(News::NNTPClient);

$VERSION = '@(#) $Revision: 0.2 $';

# Transfer an article.
sub ihave {
  my $me = shift;
  my $firstArgRef = (@_ > 0) ? ref $_[0] : undef;
  my $msgid;
    
  unless (defined $firstArgRef) {
    # first arg is a scalar (or not there), so assume it's the
    # original style call where the message id & article lines
    # are all packed into an array

    $msgid = shift || "";
    $me->command("IHAVE $msgid") or return;
    $me->squirt(@_);
  } elsif ($firstArgRef eq 'HASH') {
    my $header = shift;
    my ($msgIdKey) = grep /^message-id$/i, keys %$header;

    defined $msgIdKey or return;
    $msgid = $header->{$msgIdKey};

    $me->command ("IHAVE $msgid") or return;
    $me->squirt ($header, @_);
  } else {
    croak "bad argument to ihave (got a $firstArgRef)\n";
  }
}

sub squirt {
  my $me = shift;
  my $firstArgRef = (@_ >= 0) ? ref $_[0] : undef;
  local $\ = "";             # Guarantee that no other EOL is in use

  my $SOCK = $me->{SOCK};

  1 < $me->{DBUG} and warn "$SOCK sending ${\scalar @_} lines\n";

  unless (defined $firstArgRef) {
    # everything's in an array

    local ($_);		# moved out of for loop

    foreach (@_) {
      # Print each line, possibly prepending a dot for lines
      # starting with a dot and trimming any trailing \n.
      s/^\./../;
      s/\n$//;
      print $SOCK "$_\015\012";
    }
  } elsif ($firstArgRef eq 'HASH') {
    my $header = shift;
    my $body = shift;
    my ($key, $val);

    while (($key, $val) = each %$header) {
      print $SOCK "$key: $val\015\012";
    }

    print $SOCK "\015\012";

    if (ref $body eq 'ARRAY') {
      local $_;
      foreach (@$body) {
	s/^\./../;
	s/\n$//;
	print $SOCK "$_\015\012";
      }
    } elsif (ref $body eq 'SCALAR') {
      my ($fh) = $$body;

      # This is a complete kludge!  How do I fully qualify an indirect
      # filehandle properly...  This just looks for the caller's
      # package

      unless ($fh =~ /::/ || $fh =~ /'/) {
	my ($depth, $pack);

	$depth = 0;
	while (($pack) = caller ($depth)) {
	  last unless $pack eq 'News::NNTPClient';
	  $depth++;
	}

	$fh = join '::', $pack, $fh if defined $pack;
      }

      while (<$fh>) {
	s/^\./../;
	s/\n$//;
	print $SOCK "$_\015\012";
      }
    } else {
      croak "bad second argument to squirt\n";
    }
  } else {
    croak "bad first argument to squirt (got a $firstArgRef)\n";
  }

  print $SOCK ".\015\012";	# Terminate message.

  1 < $me->{DBUG} and warn "$SOCK done sending\n";

  $me->response;
}

1;
