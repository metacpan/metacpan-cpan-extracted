package Net::IMAP::Simple::Gmail;
use Text::ParseWords;
use strict;

use vars qw[$VERSION];
$VERSION = (qw$Revision: 0.21 $)[1];

use base qw[Net::IMAP::Simple::SSL];


sub run_search {
    my ( $self, $search_terms ) = @_;
    my @hits;

    return $self->_process_cmd(
        cmd => [ SEARCH => qq[X-GM-RAW "$search_terms"] ],
	final => sub { 
	    return \@hits;
	},
        process => sub {
	    if ( $_[0] =~ /^\* SEARCH (.*)\s*$/ ) {
		@hits = split / /, $1;
	    }
	},
	);
}



sub get_msgids {
    my ( $self, $number ) = @_;
    return $self->_get_gminfo( $number, 'X-GM-MSGID' );
}

sub get_threadids {
    my ( $self, $number ) = @_;
    return $self->_get_gminfo( $number, 'X-GM-THRID' );
}


sub _get_gminfo {
    my ( $self, $number, $gm_identifier ) = @_;
    my %threadid;

    return $self->_process_cmd(
        cmd => [ FETCH => qq[$number ($gm_identifier)] ],
	final => sub { 
	    # if range, return hashref, else scalar
	    return ($number =~ /:/) ? \%threadid : $threadid{$number};
	},
        process => sub {
	    foreach (@_) {
		if ( $_ =~ /^\* (\d+) FETCH \($gm_identifier (\d+)\)\s*$/ ) {
		    my ($num, $label) = ($1, $2);
		    $threadid{$1} = $2;
		}
	    }
	},
	);
}

sub get_labels {
    my ( $self, $number ) = @_;
    my %labels;

    return $self->_process_cmd(
        cmd => [ FETCH => qq[$number (X-GM-LABELS)] ],
	final => sub { 
	    # if range, return hashref else arrayrg
	    return ($number =~ /:/) ? \%labels : $labels{$number};
	},
        process => sub {
	    foreach (@_) {
		if ( $_ =~ /^\* (\d+) FETCH \(X-GM-LABELS \((.+)\)\)\s*$/ ) {
		    my ($num, $label) = ($1, $2);
		    my @labels = Text::ParseWords::parse_line(' ', 0, $label);
		    $labels{$num} = \@labels;
		}
	    }
	},
	);
}


sub add_labels {
    my ( $self, $number, @labels ) = @_;
    return $self->_label_manip( $number, '+X-GM-LABELS', @labels );
}

sub remove_labels {
    my ( $self, $number, @labels ) = @_;
    return $self->_label_manip( $number, '-X-GM-LABELS', @labels );
}


sub _label_manip {
    my ( $self, $number, $op, @labels ) = @_;
    return unless @labels;

    # quote labels with spaces
    @labels = map { / / ? '"' . $_ . '"' : $_ } @labels;
    my $label_line = join ' ', @labels;

    return $self->_process_cmd(
        cmd     => [ STORE => qq[$number $op ($label_line)] ],
        final   => sub { },
        process => sub { },
    );

}

1;

__END__

=head1 NAME

Net::IMAP::Simple::Gmail - Gmail specific support for Net::IMAP::Simple

=head1 SYNOPSIS

  use Net::IMAP::Simple::Gmail;
  my $server = 'imap.gmail.com';
  my $imap = Net::IMAP::Simple::Gmail->new($server);
  
  $imap->login($user => $pass);
  
  my $nm = $imap->select('INBOX');

  for(my $i = 1; $i <= $nm; $i++) {
    # Get labels on message
    my $labels = $imap->get_labels($msg);
  }

=head1 DESCRIPTION

This module is a subclass of L<Net::IMAP::Simple::SSL|Net::IMAP::Simple::SSL> that
includes specific support for Gmail IMAP Extensions. Besides the gmail specific
methods the interface is identical.

=head1 METHODS

=over 4

=item get_labels

my $labels = $imap->get_labels($msgid);
my $labels = $imap->get_labels('1:4');

If $msgid specifies one message (eg $msgid = 1), returns an arrayref of all labels on the message.

If $msgid is a range of messages (eg $msgid eq '1:4'), returns a hashref of all msgids => arrayref of labels. 

=item add_labels

$imap->add_labels($msgid, qw{accounts job});

Adds the labels to the selected message (labels must already exist).

=item remove_labels

$imap->remove_labels($msgid, qw{job});

Removes the labels from the selected message.

=item get_threadids

my $threadid = $imap->get_threadids($msgid);
my $threadids = $imap->get_threadids('1:10');

If $msgid specifies one message (eg $msgid = 1), returns a string containing the Gmail threadid.

If $msgid is a range of messages (eg $msgid eq '1:4'), returns a hashref of all msgids => threadids;

=item run_search

my $run_search = $imap->run_search('Perl');

Returns an array of msgids matching the search terms.

=back

=head1 SEE ALSO

L<Net::IMAP::Simple>,
L<perl>.

=head1 AUTHOR

James Powell

=head1 COPYRIGHT

  Copyright (c) 2013 James Powell.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
