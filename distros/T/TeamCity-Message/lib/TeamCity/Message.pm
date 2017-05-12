package TeamCity::Message;

use strict;
use warnings;

our $VERSION = '0.01';

use Time::HiRes qw( time );

use Exporter qw( import );

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw( tc_message );
## use critic

sub tc_message {
    my %args = @_;

    my $type = delete $args{type} || 'message';
    my $content = delete $args{content}
        or die 'You must provide a content argument to tc_message()';

    my $msg = "##teamcity[$type";

    if ( ref $content ) {
        for my $name ( sort keys %{$content} ) {
            my $value = $content->{$name};
            $msg .= qq{ $name='} . _escape($value) . q{'};
        }

        $msg .= _timestamp()
            unless $content->{timestamp};
    }
    else {
        $msg .= q{ '} . _escape($content) . q{'} or die $!;
    }

    $msg .= "]\n";

    return $msg;
}

sub _timestamp {
    my $now = time;

    my ( $s, $mi, $h, $d, $mo, $y ) = ( gmtime($now) )[ 0 .. 5 ];

    my $float = ( $now - int($now) );
    return sprintf(
        q{ timestamp='%4d-%02d-%02dT%02d:%02d:%02d.%03d'},
        $y + 1900, $mo + 1, $d,
        $h, $mi, $s,

        # We only need 3 places of precision so if we multiply it be 1,000 we
        # can just treat it as an integer.
        $float * 1000,
    );
}

sub _escape {
    my $str = shift;

    ( my $esc = $str ) =~ s{(['|\]])}{|$1}g;
    $esc =~ s{\n}{|n}g;
    $esc =~ s{\r}{|r}g;

    return $esc;
}

1;

# ABSTRACT: Generate TeamCity build messages

__END__

=pod

=head1 NAME

TeamCity::Message - Generate TeamCity build messages

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use TeamCity::Message;

  print STDOUT tc_message(
      type    => 'message',
      content => { text => 'This is a build message.' },
  );

  print STDOUT tc_message(
      type    => 'message',
      content => {
          text   => 'This is a serious build message.',
          status => 'ERROR',
      },
  );

  print STDOUT tc_message(
      type    => 'progressMessage',
      content => 'This is a progress message',
  );

=head1 DESCRIPTION

This module generates TeamCity build messages.

See
https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog
for more details on TeamCity build messages.

=head1 API

This module provides a single subroutine exported by default, C<tc_message>,
which can be used to generate properly formatted and escaped TeamCity build
messages.

=head2 tc_message(...)

This subroutine accepts the following arguments:

=over 4

=item * type

This is the message type, such as "message", "testStarted", "testFinished",
etc.

This is required.

=item * content

This can be either a string or a hash reference of key/value pairs. This will
be turned into the content of the message.

This is required.

=back

When the C<content> parameter is a hash reference, this subroutine will always
add a "timestamp" to the message matching the current time. You can provide an
explicit C<timestamp> value in the C<content> if you want to set this
yourself.

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/TeamCity-Message/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTOR

=for stopwords Dave Rolsky

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
